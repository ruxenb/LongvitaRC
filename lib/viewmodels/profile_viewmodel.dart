import 'dart:async';
import 'dart:math';

import '../config/pdf_export_mode.dart';
import '../models/report_metadata.dart';
import '../models/report_metadata_state.dart';
import '../services/i_report_metadata_repository.dart';

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
  final StorageService? storageService;
  final IReportMetadataRepository metadataRepository;
  final PdfExportMode exportMode;
  final Duration metadataPendingAfter;
  final DateTime Function() _now;
  final Random _random;
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
  ViewState<String> _uploadState = const ViewStateIdle();
  ReportMetadataState _metadataState = ReportMetadataState.idle;
  Object? _metadataError;
  Object? _metadataOperation;
  Timer? _metadataTimer;
  bool _disposed = false;
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
    this.storageService,
    required this.metadataRepository,
    this.exportMode = PdfExportMode.finalLocal,
    this.metadataPendingAfter = reportMetadataPendingAfter,
    DateTime Function()? now,
    Random? random,
    required this.notificationService,
    required this.reportService,
    required this.reportStore,
    required this.reportViewer,
    required this.remoteConfigService,
    required this.crashlyticsService,
    required this.analyticsService,
  }) : _now = now ?? DateTime.now,
       _random = random ?? Random.secure() {
    if (exportMode == PdfExportMode.storageEmulatorDemo &&
        storageService == null) {
      throw ArgumentError('Storage demo requires an emulator adapter');
    }
    if (metadataPendingAfter <= Duration.zero) {
      throw ArgumentError.value(metadataPendingAfter, 'metadataPendingAfter');
    }
    notificationService.onChanged = notifyListeners;
  }

  UserModel? get user => authService.currentUser;
  double get uploadProgress => _uploadProgress;
  String? get lastUploadedUrl => _lastUploadedUrl;

  /// The PDF saved on this device in this session, if any.
  ReportExport? get lastExport => _lastExport;
  ViewState<String> get exportState => _exportState;
  ViewState<String> get uploadState => _uploadState;
  ReportMetadataState get metadataState => _metadataState;
  Object? get metadataError => _metadataError;
  bool get isStorageDemo => exportMode == PdfExportMode.storageEmulatorDemo;
  bool get canRetryMetadata =>
      _metadataState == ReportMetadataState.error &&
      _lastExport != null &&
      _metadataOperation == null;

  /// True while an export or a retry runs. Only one runs at a time, so the
  /// demo upload belongs to the same saved file. Metadata has its own gate.
  bool get isExporting => _activeOperation != null;

  /// True when the saved PDF has not reached Storage and nothing is running.
  bool get canRetryUpload =>
      isStorageDemo &&
      !isExporting &&
      _lastExport != null &&
      _lastUploadedUrl == null;

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
  AppNotification? takeArrivedNotification() =>
      notificationService.takeArrival();

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
    _resetMetadata();
    _uploadState = const ViewStateIdle();
    _activeOperation = null;
    if (_uploading) unawaited(storageService!.cancelActiveUpload());
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
    final epoch = _epoch.current;
    try {
      await reportStore.deleteAll(uid: uid);
    } catch (e, s) {
      if (_sessionUid == null) {
        unawaited(
          _recordError(
            e,
            s,
            epoch,
            'Failed to remove local reports at sign-out',
          ),
        );
      }
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

  /// The default Final flow: save locally, then start one independent metadata
  /// write. SDK acknowledgement, Analytics and demo upload never gate the file.
  Future<void> exportPdf(MealPlanModel plan) async {
    if (isExporting || _disposed) return;
    final currentUser = authService.currentUser;
    if (currentUser == null || plan.uid != currentUser.uid) {
      _exportState = const ViewStateError(
        'Vui lòng chọn thực đơn của tài khoản hiện tại.',
      );
      notifyListeners();
      return;
    }

    final epoch = _epoch.current;
    final operation = _activeOperation = Object();
    final createdAt = _now().toUtc();
    _exportState = const ViewStateLoading('Đang khởi tạo tài liệu PDF…');
    notifyListeners();

    try {
      final bytes = await reportService.generateMealPlanPdf(plan);
      if (!_isActive(operation)) return;
      final metadata = ReportMetadata.forNewExport(
        createdAt: createdAt,
        planId: plan.id.isEmpty ? null : plan.id,
        sizeBytes: bytes.length,
        random: _random,
      );
      final file = await reportStore.save(
        uid: currentUser.uid,
        exportId: metadata.exportId,
        bytes: bytes,
      );
      if (!_isActive(operation)) {
        // This exact file was created by this operation, never an overwritten
        // collision. Queue cleanup after the late save, without touching B.
        await reportStore.delete(
          uid: currentUser.uid,
          exportId: metadata.exportId,
        );
        return;
      }
      final export = ReportExport(
        exportId: metadata.exportId,
        planId: metadata.planId,
        filePath: file.path,
        createdAt: metadata.createdAt,
        sizeBytes: bytes.length,
      );
      _lastExport = export;
      _lastUploadedUrl = null;
      _uploadProgress = 0;
      _uploadState = const ViewStateIdle();
      _resetMetadata();
      _exportState = ViewStateSuccess(export.fileName);
      // Final releases the local single-flight gate before any network wait.
      if (!isStorageDemo) _activeOperation = null;
      _startMetadata(currentUser.uid, export, epoch);
      unawaited(_logLocalExport(bytes.length, epoch));
      notifyListeners();
      if (isStorageDemo && _isActive(operation)) {
        await _upload(currentUser.uid, export, bytes, operation);
      }
    } catch (e, s) {
      if (!_isActive(operation)) return;
      _finish(ViewStateError('Lỗi trong quá trình xuất PDF', e));
      unawaited(_recordError(e, s, epoch, 'Failed to save PDF locally'));
    }
  }

  /// Compatibility for existing callers. Upload is opt-in, never the default.
  Future<void> exportAndUploadPdf(MealPlanModel plan) => exportPdf(plan);

  void _resetMetadata() {
    _metadataTimer?.cancel();
    _metadataTimer = null;
    _metadataOperation = null;
    _metadataState = ReportMetadataState.idle;
    _metadataError = null;
  }

  bool _ownsExport(ReportExport export, int epoch) =>
      !_disposed && !_epoch.isStale(epoch) && identical(_lastExport, export);

  void _startMetadata(String uid, ReportExport export, int epoch) {
    final operation = _metadataOperation = Object();
    _metadataState = ReportMetadataState.saving;
    _metadataError = null;
    bool active() =>
        _ownsExport(export, epoch) && identical(_metadataOperation, operation);
    _metadataTimer = Timer(metadataPendingAfter, () {
      if (!active()) return;
      _metadataState = ReportMetadataState.pending;
      notifyListeners();
    });
    // Keep the original SDK Future alive: pending is a display threshold,
    // never a timeout, cancellation, or permission to issue a second write.
    unawaited(() async {
      try {
        await metadataRepository.save(uid, export.metadata);
        if (!active()) return;
        _metadataState = ReportMetadataState.confirmed;
      } catch (error) {
        if (!active()) return;
        _metadataState = ReportMetadataState.error;
        _metadataError = error;
      } finally {
        if (active()) {
          _metadataTimer?.cancel();
          _metadataTimer = null;
          _metadataOperation = null;
          notifyListeners();
        }
      }
    }());
  }

  void retryMetadata() {
    final export = _lastExport;
    final currentUser = authService.currentUser;
    if (!canRetryMetadata || export == null || currentUser == null) return;
    _startMetadata(currentUser.uid, export, _epoch.current);
    notifyListeners();
  }

  Future<void> _logLocalExport(int size, int epoch) async {
    if (_disposed || _epoch.isStale(epoch)) return;
    try {
      await analyticsService.logExportReport(
        fileSizeKb: (size / 1024).ceil(),
        hasShoppingList: 0,
      );
    } catch (error, stack) {
      await _recordError(error, stack, epoch, 'Failed to log local PDF export');
    }
  }

  Future<void> _recordError(
    Object error,
    StackTrace stack,
    int epoch,
    String reason,
  ) async {
    if (_disposed || _epoch.isStale(epoch)) return;
    try {
      await crashlyticsService.recordError(error, stack, reason: reason);
    } catch (_) {
      // Diagnostics must never turn a successful save into a failed export.
    }
  }

  /// Uploads the saved PDF again under the same export id. Does nothing unless
  /// [canRetryUpload] is true.
  Future<void> retryUpload() async {
    final export = _lastExport;
    final currentUser = authService.currentUser;
    if (!canRetryUpload || export == null || currentUser == null) return;

    final epoch = _epoch.current;
    final operation = _activeOperation = Object();
    _uploadState = const ViewStateLoading(
      'Đang tải lại PDF lên Storage Emulator…',
    );
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      final bytes = await reportStore.read(
        uid: currentUser.uid,
        exportId: export.exportId,
      );
      if (!_isActive(operation)) return;
      if (bytes == null) {
        _lastExport = null;
        _finishUpload(
          const ViewStateError(
            'Không còn file PDF trên máy. Vui lòng xuất lại.',
          ),
        );
        return;
      }
      await _upload(currentUser.uid, export, bytes, operation);
    } catch (e, s) {
      if (!_isActive(operation)) return;
      _finishUpload(ViewStateError(_uploadFailedMessage, e));
      unawaited(_recordError(e, s, epoch, 'Failed to retry the PDF upload'));
    }
  }

  /// Stops the running upload. The PDF stays on the device and can be retried.
  ///
  /// Reports the cancel at once: offline, the SDK only stops at its next retry,
  /// which can take many seconds. A later outcome of that task is ignored, and
  /// a retry uploads to the same path.
  void cancelUpload() {
    if (!_uploading) return;
    unawaited(storageService!.cancelActiveUpload());
    _finishUpload(const ViewStateEmpty(message: _uploadCancelledMessage));
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
    UploadFailureKind.unknown => _uploadFailedMessage,
  };

  bool _isActive(Object operation) =>
      !_disposed && identical(_activeOperation, operation);

  /// Publishes the final state of the running operation.
  void _finish(ViewState<String> state) {
    _exportState = state;
    _activeOperation = null;
    _uploading = false;
    notifyListeners();
  }

  void _finishUpload(ViewState<String> state) {
    _uploadState = state;
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
    final epoch = _epoch.current;
    _uploadState = const ViewStateLoading('Đang tải PDF lên Storage Emulator…');
    _uploading = true;
    notifyListeners();

    try {
      final downloadUrl = await storageService!.uploadReportPdf(
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
      _finishUpload(ViewStateSuccess(downloadUrl));
    } on UploadFailure catch (failure, s) {
      if (!_isActive(operation)) return;
      if (failure.kind == UploadFailureKind.cancelled) {
        _finishUpload(const ViewStateEmpty(message: _uploadCancelledMessage));
        return;
      }
      _finishUpload(
        ViewStateError(_uploadFailureMessage(failure.kind), failure),
      );
      // A lost connection is expected on a phone and is not an app defect.
      if (failure.kind != UploadFailureKind.network) {
        unawaited(
          _recordError(
            failure,
            s,
            epoch,
            'Failed to upload the PDF (${failure.kind.name})',
          ),
        );
      }
    } catch (e, s) {
      if (!_isActive(operation)) return;
      _finishUpload(ViewStateError(_uploadFailedMessage, e));
      unawaited(_recordError(e, s, epoch, 'Failed to upload the PDF'));
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
        uid: currentUser.uid,
        exportId: export.exportId,
      );
      if (!_ownsExport(export, epoch)) return false;
      if (bytes == null) {
        _lastExport = null;
        _lastUploadedUrl = null;
        _resetMetadata();
        _exportState = const ViewStateError(
          'Không còn file PDF đã lưu trên máy. Vui lòng xuất lại.',
        );
        notifyListeners();
        return false;
      }
      return await open(bytes, export.externalFileName);
    } catch (e, s) {
      if (_epoch.isStale(epoch)) return false;
      unawaited(_recordError(e, s, epoch, 'Failed to open the exported PDF'));
      return false;
    }
  }

  void testCrashlytics() {
    crashlyticsService.triggerTestCrash();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch.advance();
    _resetMetadata();
    _activeOperation = null;
    notificationService.onChanged = null;
    super.dispose();
  }
}
