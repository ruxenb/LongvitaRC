import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/app_notification.dart';
import '../models/meal_plan_model.dart';
import '../models/report_export.dart';
import '../models/upload_failure.dart';
import '../models/user_model.dart';
import '../models/view_state.dart';
import '../services/i_auth_service.dart';
import '../services/i_report_service.dart';
import '../services/local_report_store.dart';
import '../services/report_viewer.dart';
import '../firebase/storage_service.dart';
import '../firebase/notification_service.dart';
import '../firebase/remote_config_service.dart';
import '../firebase/crashlytics_service.dart';
import '../firebase/analytics_service.dart';
import 'base_viewmodel.dart';
import 'session_scoped.dart';

class ProfileViewModel extends BaseViewModel implements SessionScoped {
  final IAuthService authService;
  final StorageService storageService;
  final NotificationService notificationService;
  final IReportService reportService;
  final LocalReportStore reportStore;
  final IReportViewer reportViewer;
  final RemoteConfigService remoteConfigService;
  final CrashlyticsService crashlyticsService;
  final AnalyticsService analyticsService;

  double _uploadProgress = 0.0;
  String? _lastUploadedUrl;
  ReportExport? _lastExport;
  ViewState<String> _exportState = const ViewStateIdle();
  final SessionEpoch _epoch = SessionEpoch();

  /// Identifies the running export or retry. Results and progress apply only
  /// while their token is still this one; ending the session clears it.
  Object? _activeOperation;
  bool _uploading = false;
  bool _refreshingConfig = false;

  /// Owner of the PDFs on this device for the current session.
  String? _sessionUid;

  ProfileViewModel({
    required this.authService,
    required this.storageService,
    required this.notificationService,
    required this.reportService,
    required this.reportStore,
    required this.reportViewer,
    required this.remoteConfigService,
    required this.crashlyticsService,
    required this.analyticsService,
  }) {
    notificationService.onChanged = notifyListeners;
  }

  UserModel? get user => authService.currentUser;
  double get uploadProgress => _uploadProgress;
  String? get lastUploadedUrl => _lastUploadedUrl;

  /// The PDF saved on this device in this session, if any.
  ReportExport? get lastExport => _lastExport;
  ViewState<String> get exportState => _exportState;

  /// True while an export or a retry runs. Only one runs at a time, so the
  /// saved file, URL, progress and state always describe the same export.
  bool get isExporting => _activeOperation != null;

  /// True when the saved PDF has not reached Storage and nothing is running.
  bool get canRetryUpload =>
      !isExporting && _lastExport != null && _lastUploadedUrl == null;

  /// True while the PDF is on its way to Storage.
  bool get canCancelUpload => _uploading;
  List<RemoteMessage> get notifications => notificationService.messages;
  List<AppNotification> get inbox => notificationService.inbox;
  NotificationPermission get notificationPermission =>
      notificationService.permission;

  /// Notification permission is requested after sign-in, not at app start,
  /// so the first screen a new user (and ARTEMIS TC-01) sees is Sign-in
  /// rather than the Android 13 permission dialog.
  @override
  void onSessionStarted(UserModel user) {
    _sessionUid = user.uid;
    unawaited(notificationService.bindUser(user.uid));
    notificationService.initialize();
  }

  /// True once after a notification was tapped.
  bool takeNotificationOpenRequest() => notificationService.takeOpenRequest();

  /// A message received while the app was open, once, so a screen can show it.
  AppNotification? takeArrivedNotification() => notificationService.takeArrival();

  /// Identifies the current session. It changes on every sign-out and user
  /// change, so the same user signing back in gets a new value.
  int get sessionEpoch => _epoch.current;

  /// True when [epoch] belongs to a session that has ended.
  bool isSessionStale(int epoch) => _epoch.isStale(epoch);

  /// Picks up messages that arrived while the app was in the background.
  Future<void> refreshInbox() => notificationService.drainPending();

  /// Stops the running upload and removes this user's PDFs from the device, so
  /// the next person using it finds neither. Cloud copies stay.
  @override
  void clearSession() {
    _epoch.advance();
    _activeOperation = null;
    if (_uploading) unawaited(storageService.cancelActiveUpload());
    _uploading = false;
    _uploadProgress = 0.0;
    _lastUploadedUrl = null;
    _lastExport = null;
    _exportState = const ViewStateIdle();
    final uid = _sessionUid;
    _sessionUid = null;
    if (uid != null) unawaited(_deleteLocalReports(uid));
    notificationService.clearHistory();
    notifyListeners();
  }

  Future<void> _deleteLocalReports(String uid) async {
    try {
      await reportStore.deleteAll(uid: uid);
    } catch (e, s) {
      await crashlyticsService.recordError(e, s,
          reason: 'Failed to remove local reports at sign-out');
    }
  }

  // Remote config properties for UI display
  int get maxRecommendations => remoteConfigService.maxRecommendations;
  bool get enableScore => remoteConfigService.enableLongevityScore;
  String get bannerText => remoteConfigService.bannerAnnouncement;
  bool get isRefreshingConfig => _refreshingConfig;

  /// Returns true when a value actually changed. False means no change or a
  /// failed fetch, which the service does not tell apart; the current values
  /// stay in use either way.
  ///
  /// The SDK reports every newly fetched config as activated, even when its
  /// values are the same, so the values are compared here.
  Future<bool> refreshRemoteConfig() async {
    if (_refreshingConfig) return false;
    _refreshingConfig = true;
    notifyListeners();
    try {
      final before = _configValues();
      final activated = await remoteConfigService.forceFetchAndActivate();
      return activated && _configValues() != before;
    } finally {
      _refreshingConfig = false;
      notifyListeners();
    }
  }

  (int, bool, String, double) _configValues() => (
        remoteConfigService.maxRecommendations,
        remoteConfigService.enableLongevityScore,
        remoteConfigService.bannerAnnouncement,
        remoteConfigService.proteinTargetRatio,
      );

  /// Does nothing while another export or retry runs: check [isExporting].
  Future<void> exportAndUploadPdf(MealPlanModel plan) async {
    if (isExporting) return;
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      _exportState = const ViewStateError('Vui lòng đăng nhập để xuất báo cáo');
      notifyListeners();
      return;
    }

    final operation = _activeOperation = Object();
    _exportState = const ViewStateLoading('Đang khởi tạo tài liệu PDF…');
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      // 1. Generate PDF on local device
      final Uint8List pdfBytes =
          await reportService.generateMealPlanPdf(plan);
      if (!_isActive(operation)) return;

      // 2. Keep it on the device first, so a failed upload loses nothing.
      final exportId = _newExportId(plan);
      final file = await reportStore.save(
        uid: currentUser.uid,
        exportId: exportId,
        bytes: pdfBytes,
      );
      if (!_isActive(operation)) {
        // The session ended during the save, after its files were removed.
        await reportStore.delete(uid: currentUser.uid, exportId: exportId);
        return;
      }
      final export = ReportExport(
        exportId: exportId,
        planId: plan.id,
        filePath: file.path,
      );
      _lastExport = export;
      _lastUploadedUrl = null;

      // 3. Upload to Cloud Storage under reports/{uid}/...
      await _upload(currentUser.uid, export, pdfBytes, operation);
    } catch (e, s) {
      // A failure of the previous session must not be reported under the
      // user id of the current one.
      if (!_isActive(operation)) return;
      _finish(ViewStateError('Lỗi trong quá trình xuất PDF', e));
      await crashlyticsService.recordError(e, s,
          reason: 'Failed to export and upload PDF');
    }
  }

  /// Uploads the saved PDF again under the same export id. Does nothing unless
  /// [canRetryUpload] is true.
  Future<void> retryUpload() async {
    final export = _lastExport;
    final currentUser = authService.currentUser;
    if (!canRetryUpload || export == null || currentUser == null) return;

    final operation = _activeOperation = Object();
    _exportState = const ViewStateLoading('Đang tải lại PDF lên Cloud Storage…');
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      final bytes = await reportStore.read(
          uid: currentUser.uid, exportId: export.exportId);
      if (!_isActive(operation)) return;
      if (bytes == null) {
        _lastExport = null;
        _finish(const ViewStateError(
            'Không còn file PDF trên máy. Vui lòng xuất lại.'));
        return;
      }
      await _upload(currentUser.uid, export, bytes, operation);
    } catch (e, s) {
      if (!_isActive(operation)) return;
      _finish(ViewStateError(_uploadFailedMessage, e));
      await crashlyticsService.recordError(e, s,
          reason: 'Failed to retry the PDF upload');
    }
  }

  /// Stops the running upload. The PDF stays on the device and can be retried.
  ///
  /// Reports the cancel at once: offline, the SDK only stops at its next retry,
  /// which can take many seconds. A later outcome of that task is ignored, and
  /// a retry uploads to the same path.
  void cancelUpload() {
    if (!_uploading) return;
    unawaited(storageService.cancelActiveUpload());
    _finish(const ViewStateEmpty(message: _uploadCancelledMessage));
  }

  /// Opens the saved PDF. Returns false when it could not be opened.
  Future<bool> previewLastExport() => _openLastExport(reportViewer.preview);

  /// Shares the saved PDF. Returns false when it could not be shared.
  Future<bool> shareLastExport() => _openLastExport(reportViewer.share);

  static const _uploadFailedMessage =
      'PDF đã lưu trên máy nhưng chưa tải lên được. Vui lòng thử lại.';
  static const _uploadCancelledMessage =
      'Đã hủy tải lên. PDF vẫn còn trên máy.';

  static String _uploadFailureMessage(UploadFailureKind kind) => switch (kind) {
        UploadFailureKind.network =>
          'PDF đã lưu trên máy nhưng mất kết nối khi tải lên. '
              'Kiểm tra mạng rồi thử lại.',
        UploadFailureKind.denied =>
          'PDF đã lưu trên máy nhưng tài khoản chưa có quyền tải lên. '
              'Đăng nhập lại rồi thử lại.',
        UploadFailureKind.notConfigured =>
          'PDF đã lưu trên máy nhưng dịch vụ lưu trữ chưa sẵn sàng. '
              'Vui lòng thử lại sau.',
        UploadFailureKind.quota =>
          'PDF đã lưu trên máy nhưng dung lượng lưu trữ đã hết. '
              'Vui lòng thử lại sau.',
        UploadFailureKind.cancelled ||
        UploadFailureKind.unknown =>
          _uploadFailedMessage,
      };

  bool _isActive(Object operation) => identical(_activeOperation, operation);

  /// Publishes the final state of the running operation.
  void _finish(ViewState<String> state) {
    _exportState = state;
    _activeOperation = null;
    _uploading = false;
    notifyListeners();
  }

  Future<void> _upload(
    String uid,
    ReportExport export,
    Uint8List bytes,
    Object operation,
  ) async {
    _exportState = const ViewStateLoading('Đang tải PDF lên Cloud Storage…');
    _uploading = true;
    notifyListeners();

    try {
      final downloadUrl = await storageService.uploadReportPdf(
        uid: uid,
        fileName: export.fileName,
        bytes: bytes,
        onProgress: (progress) {
          if (!_isActive(operation)) return;
          _uploadProgress = progress;
          notifyListeners();
        },
      );
      if (!_isActive(operation)) return;

      _lastUploadedUrl = downloadUrl;
      _finish(ViewStateSuccess(downloadUrl));
      await analyticsService.logExportReport(
        fileSizeKb: (bytes.length / 1024).ceil(),
        // ReportService does not include a shopping list section yet.
        hasShoppingList: 0,
      );
    } on UploadFailure catch (failure, s) {
      if (!_isActive(operation)) return;
      if (failure.kind == UploadFailureKind.cancelled) {
        _finish(const ViewStateEmpty(message: _uploadCancelledMessage));
        return;
      }
      _finish(ViewStateError(_uploadFailureMessage(failure.kind), failure));
      // A lost connection is expected on a phone and is not an app defect.
      if (failure.kind != UploadFailureKind.network) {
        await crashlyticsService.recordError(failure, s,
            reason: 'Failed to upload the PDF (${failure.kind.name})');
      }
    } catch (e, s) {
      if (!_isActive(operation)) return;
      _finish(ViewStateError(_uploadFailedMessage, e));
      await crashlyticsService.recordError(e, s,
          reason: 'Failed to upload the PDF');
    }
  }

  Future<bool> _openLastExport(
    Future<bool> Function(Uint8List bytes, String fileName) open,
  ) async {
    final export = _lastExport;
    final currentUser = authService.currentUser;
    if (export == null || currentUser == null) return false;

    final epoch = _epoch.current;
    try {
      final bytes = await reportStore.read(
          uid: currentUser.uid, exportId: export.exportId);
      if (bytes == null || _epoch.isStale(epoch)) return false;
      return await open(bytes, export.fileName);
    } catch (e, s) {
      if (_epoch.isStale(epoch)) return false;
      await crashlyticsService.recordError(e, s,
          reason: 'Failed to open the exported PDF');
      return false;
    }
  }

  /// Plan ids can contain anything, while an export id becomes a file name.
  static String _newExportId(MealPlanModel plan) {
    final safePlanId = plan.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
    final prefix = safePlanId.isEmpty ? 'plan' : safePlanId;
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
  }

  void testCrashlytics() {
    crashlyticsService.triggerTestCrash();
  }

  @override
  void dispose() {
    notificationService.onChanged = null;
    super.dispose();
  }
}
