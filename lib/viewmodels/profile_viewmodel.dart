import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/meal_plan_model.dart';
import '../models/user_model.dart';
import '../models/view_state.dart';
import '../services/i_auth_service.dart';
import '../services/i_report_service.dart';
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
  final RemoteConfigService remoteConfigService;
  final CrashlyticsService crashlyticsService;
  final AnalyticsService analyticsService;

  double _uploadProgress = 0.0;
  String? _lastUploadedUrl;
  ViewState<String> _exportState = const ViewStateIdle();
  final SessionEpoch _epoch = SessionEpoch();

  ProfileViewModel({
    required this.authService,
    required this.storageService,
    required this.notificationService,
    required this.reportService,
    required this.remoteConfigService,
    required this.crashlyticsService,
    required this.analyticsService,
  });

  UserModel? get user => authService.currentUser;
  double get uploadProgress => _uploadProgress;
  String? get lastUploadedUrl => _lastUploadedUrl;
  ViewState<String> get exportState => _exportState;
  List<RemoteMessage> get notifications => notificationService.messages;

  /// Notification permission is requested after sign-in, not at app start,
  /// so the first screen a new user (and ARTEMIS TC-01) sees is Sign-in
  /// rather than the Android 13 permission dialog.
  @override
  void onSessionStarted(UserModel user) {
    notificationService.initialize();
  }

  @override
  void clearSession() {
    _epoch.advance();
    _uploadProgress = 0.0;
    _lastUploadedUrl = null;
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

      _exportState = const ViewStateLoading('Đang tải PDF lên Cloud Storage...');
      notifyListeners();

      // 2. Upload to Cloud Storage under reports/{uid}/...
      final fileName = 'meal_plan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final downloadUrl = await storageService.uploadReportPdf(
        uid: currentUser.uid,
        fileName: fileName,
        bytes: pdfBytes,
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
        await analyticsService.logExportReport(format: 'pdf');
      } else {
        _exportState = const ViewStateError('Tải lên thất bại. Vui lòng thử lại.');
        notifyListeners();
      }
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

  void testCrashlytics() {
    crashlyticsService.triggerTestCrash();
  }
}
