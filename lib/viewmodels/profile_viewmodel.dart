import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/meal_plan_model.dart';
import '../models/report_export.dart';
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
  });

  UserModel? get user => authService.currentUser;
  double get uploadProgress => _uploadProgress;
  String? get lastUploadedUrl => _lastUploadedUrl;

  /// The PDF saved on this device in this session, if any.
  ReportExport? get lastExport => _lastExport;
  ViewState<String> get exportState => _exportState;
  List<RemoteMessage> get notifications => notificationService.messages;

  /// Notification permission is requested after sign-in, not at app start,
  /// so the first screen a new user (and ARTEMIS TC-01) sees is Sign-in
  /// rather than the Android 13 permission dialog.
  @override
  void onSessionStarted(UserModel user) {
    notificationService.bindUser(user.uid);
    notificationService.initialize();
  }

  @override
  void clearSession() {
    _epoch.advance();
    _uploadProgress = 0.0;
    _lastUploadedUrl = null;
    _lastExport = null;
    _exportState = const ViewStateIdle();
    notificationService.clearHistory();
    notifyListeners();
  }

  // Remote config properties for UI display
  int get maxRecommendations => remoteConfigService.maxRecommendations;
  bool get enableScore => remoteConfigService.enableLongevityScore;
  String get bannerText => remoteConfigService.bannerAnnouncement;

  Future<void> exportAndUploadPdf(MealPlanModel plan) async {
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      _exportState = const ViewStateError('Vui lòng đăng nhập để xuất báo cáo');
      notifyListeners();
      return;
    }

    final epoch = _epoch.current;
    _exportState = const ViewStateLoading('Đang khởi tạo tài liệu PDF...');
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      // 1. Generate PDF on local device
      final Uint8List pdfBytes =
          await reportService.generateMealPlanPdf(plan);
      if (_epoch.isStale(epoch)) return;

      // 2. Keep it on the device first, so a failed upload loses nothing.
      final exportId = _newExportId(plan);
      final file = await reportStore.save(
        uid: currentUser.uid,
        exportId: exportId,
        bytes: pdfBytes,
      );
      if (_epoch.isStale(epoch)) return;
      final export = ReportExport(
        exportId: exportId,
        planId: plan.id,
        filePath: file.path,
      );
      _lastExport = export;
      _lastUploadedUrl = null;

      // 3. Upload to Cloud Storage under reports/{uid}/...
      await _upload(currentUser.uid, export, pdfBytes, epoch);
    } catch (e, s) {
      // A failure of the previous session must not be reported under the
      // user id of the current one.
      if (_epoch.isStale(epoch)) return;
      _exportState = ViewStateError('Lỗi trong quá trình xuất PDF', e);
      notifyListeners();
      await crashlyticsService.recordError(e, s,
          reason: 'Failed to export and upload PDF');
    }
  }

  /// Uploads the saved PDF again under the same export id.
  Future<void> retryUpload() async {
    final export = _lastExport;
    final currentUser = authService.currentUser;
    if (export == null || currentUser == null) return;

    final epoch = _epoch.current;
    _exportState = const ViewStateLoading('Đang tải lại PDF lên Cloud Storage...');
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      final bytes = await reportStore.read(
          uid: currentUser.uid, exportId: export.exportId);
      if (_epoch.isStale(epoch)) return;
      if (bytes == null) {
        _lastExport = null;
        _exportState =
            const ViewStateError('Không còn file PDF trên máy. Vui lòng xuất lại.');
        notifyListeners();
        return;
      }
      await _upload(currentUser.uid, export, bytes, epoch);
    } catch (e, s) {
      if (_epoch.isStale(epoch)) return;
      _exportState = ViewStateError(_uploadFailedMessage, e);
      notifyListeners();
      await crashlyticsService.recordError(e, s,
          reason: 'Failed to retry the PDF upload');
    }
  }

  /// Opens the saved PDF. Returns false when it could not be opened.
  Future<bool> previewLastExport() => _openLastExport(reportViewer.preview);

  /// Shares the saved PDF. Returns false when it could not be shared.
  Future<bool> shareLastExport() => _openLastExport(reportViewer.share);

  static const _uploadFailedMessage =
      'PDF đã lưu trên máy nhưng chưa tải lên được. Vui lòng thử lại.';

  Future<void> _upload(
    String uid,
    ReportExport export,
    Uint8List bytes,
    int epoch,
  ) async {
    _exportState = const ViewStateLoading('Đang tải PDF lên Cloud Storage...');
    notifyListeners();

    try {
      final downloadUrl = await storageService.uploadReportPdf(
        uid: uid,
        fileName: export.fileName,
        bytes: bytes,
        onProgress: (progress) {
          if (_epoch.isStale(epoch)) return;
          _uploadProgress = progress;
          notifyListeners();
        },
      );
      if (_epoch.isStale(epoch)) return;

      if (downloadUrl != null) {
        _lastUploadedUrl = downloadUrl;
        _exportState = ViewStateSuccess(downloadUrl);
        notifyListeners();
        await analyticsService.logExportReport(
          fileSizeKb: (bytes.length / 1024).ceil(),
          // ReportService does not include a shopping list section yet.
          hasShoppingList: 0,
        );
      } else {
        _exportState = const ViewStateError(_uploadFailedMessage);
        notifyListeners();
      }
    } catch (e, s) {
      if (_epoch.isStale(epoch)) return;
      _exportState = ViewStateError(_uploadFailedMessage, e);
      notifyListeners();
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
}
