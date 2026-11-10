import 'package:longvita/config/pdf_export_mode.dart';
import 'package:longvita_core/services/i_report_metadata_repository.dart';
import 'package:longvita_core/services/firestore_report_metadata_repository.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services & Interfaces
import 'package:longvita_core/services/i_auth_service.dart';
import 'package:longvita/services/auth_service.dart';
import 'package:longvita_core/services/i_data_service.dart';
import 'package:longvita_core/services/data_service.dart';
import 'package:longvita_core/services/i_report_service.dart';
import 'package:longvita/services/report_service.dart';
import 'package:longvita/services/local_report_store.dart';
import 'package:longvita/services/report_viewer.dart';
import 'package:longvita_core/services/i_gemini_ai_service.dart';
import 'package:longvita/services/gemini_ai_service.dart';

// Firebase Helpers
import 'package:longvita/firebase/firebase_bootstrap.dart';
import 'package:longvita_core/firebase/analytics_service.dart';
import 'package:longvita/firebase/crashlytics_service.dart';
import 'package:longvita_core/firebase/remote_config_service.dart';
import 'package:longvita/firebase/storage_service.dart';
import 'package:longvita/firebase/notification_service.dart';

// ViewModels
import 'package:longvita/viewmodels/auth_viewmodel.dart';
import 'package:longvita/viewmodels/meal_plan_viewmodel.dart';
import 'package:longvita/viewmodels/ingredient_viewmodel.dart';
import 'package:longvita/viewmodels/profile_viewmodel.dart';

// Theme & Screens
import 'package:longvita_core/theme/app_theme.dart';
import 'package:longvita_core/theme/app_typography.dart';
import 'package:longvita/screens/auth_gate.dart';
import 'package:longvita/screens/profile_screen.dart';
import 'package:longvita/screens/startup_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppTypography.registerFontLicenses();

  final bootstrap = FirebaseBootstrap();
  runApp(
    StartupGate(initialize: bootstrap.initialize, buildReadyApp: buildAppScope),
  );
}

/// Creates services and ViewModels. Only called after Firebase started
/// successfully, because the services wrap SDK singletons.
Future<Widget> buildAppScope() async {
  // Create Firebase singletons
  final analytics = AnalyticsService();
  final crashlytics = CrashlyticsService();
  final remoteConfig = RemoteConfigService();
  final exportMode = resolvePdfExportMode();
  final storage = exportMode == PdfExportMode.storageEmulatorDemo
      ? StorageService(emulatorHost: storageEmulatorHost)
      : null;
  final metadataRepository = FirestoreReportMetadataRepository();
  final notification = NotificationService();

  // Remote Config falls back to in-app defaults internally. FCM permission
  // is requested after sign-in (ProfileViewModel.onSessionStarted).
  await remoteConfig.initialize();

  // Create Service instances
  final IAuthService authService = AuthService();
  final IDataService dataService = DataService();
  final IReportService reportService = ReportService();
  final IGeminiAiService geminiAiService = GeminiAiService(
    remoteConfig: remoteConfig,
    analytics: analytics,
  );

  // ViewModels holding per-user data are created up front so AuthViewModel
  // can clear them when a session ends.
  final mealPlanViewModel = MealPlanViewModel(
    dataService: dataService,
    analytics: analytics,
    crashlytics: crashlytics,
    remoteConfig: remoteConfig,
  );
  final ingredientViewModel = IngredientViewModel(
    dataService: dataService,
    analytics: analytics,
    crashlytics: crashlytics,
  );
  final profileViewModel = ProfileViewModel(
    authService: authService,
    storageService: storage,
    exportMode: exportMode,
    metadataRepository: metadataRepository,
    notificationService: notification,
    reportService: reportService,
    reportStore: LocalReportStore(),
    reportViewer: PrintingReportViewer(),
    remoteConfigService: remoteConfig,
    crashlyticsService: crashlytics,
    analyticsService: analytics,
  );
  final authViewModel = AuthViewModel(
    authService: authService,
    analytics: analytics,
    crashlytics: crashlytics,
    sessionScoped: [mealPlanViewModel, ingredientViewModel, profileViewModel],
  );

  return MultiProvider(
    providers: [
      // Service Dependencies (Injected via Interface)
      Provider<IAuthService>.value(value: authService),
      Provider<IDataService>.value(value: dataService),
      Provider<IReportService>.value(value: reportService),
      Provider<IGeminiAiService>.value(value: geminiAiService),

      // Firebase Service Singletons
      Provider<AnalyticsService>.value(value: analytics),
      Provider<CrashlyticsService>.value(value: crashlytics),
      Provider<RemoteConfigService>.value(value: remoteConfig),
      Provider<IReportMetadataRepository>.value(value: metadataRepository),
      if (storage != null) Provider<StorageService>.value(value: storage),
      Provider<NotificationService>.value(value: notification),

      // MVVM ViewModels
      ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
      ChangeNotifierProvider<MealPlanViewModel>.value(value: mealPlanViewModel),
      ChangeNotifierProvider<IngredientViewModel>.value(
        value: ingredientViewModel,
      ),
      ChangeNotifierProvider<ProfileViewModel>.value(value: profileViewModel),
    ],
    child: const LongvitaApp(),
  );
}

class LongvitaApp extends StatelessWidget {
  const LongvitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Longvita — Dinh dưỡng trường thọ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
      routes: {ProfileScreen.routeName: (_) => const ProfileScreen()},
    );
  }
}
