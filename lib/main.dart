import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services & Interfaces
import 'services/i_auth_service.dart';
import 'services/auth_service.dart';
import 'services/i_data_service.dart';
import 'services/data_service.dart';
import 'services/i_report_service.dart';
import 'services/report_service.dart';

// Firebase Helpers
import 'firebase/firebase_bootstrap.dart';
import 'firebase/analytics_service.dart';
import 'firebase/crashlytics_service.dart';
import 'firebase/remote_config_service.dart';
import 'firebase/storage_service.dart';
import 'firebase/notification_service.dart';

// ViewModels
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/meal_plan_viewmodel.dart';
import 'viewmodels/ingredient_viewmodel.dart';
import 'viewmodels/profile_viewmodel.dart';

// Theme & Screens
import 'theme/app_theme.dart';
import 'theme/app_typography.dart';
import 'screens/auth_gate.dart';
import 'screens/startup_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppTypography.registerFontLicenses();

  final bootstrap = FirebaseBootstrap();
  runApp(StartupGate(
    initialize: bootstrap.initialize,
    buildReadyApp: buildAppScope,
  ));
}

/// Creates services and ViewModels. Only called after Firebase started
/// successfully, because the services wrap SDK singletons.
Future<Widget> buildAppScope() async {
  // Create Firebase singletons
  final analytics = AnalyticsService();
  final crashlytics = CrashlyticsService();
  final remoteConfig = RemoteConfigService();
  final storage = StorageService();
  final notification = NotificationService();

  // Remote Config falls back to in-app defaults internally. FCM permission
  // is requested after sign-in (ProfileViewModel.onSessionStarted).
  await remoteConfig.initialize();

  // Create Service instances
  final IAuthService authService = AuthService();
  final IDataService dataService = DataService();
  final IReportService reportService = ReportService();

  // ViewModels holding per-user data are created up front so AuthViewModel
  // can clear them when a session ends.
  final mealPlanViewModel = MealPlanViewModel(
    dataService: dataService,
    analytics: analytics,
    crashlytics: crashlytics,
    remoteConfig: remoteConfig,
  );
  final ingredientViewModel = IngredientViewModel(
    analytics: analytics,
    crashlytics: crashlytics,
  );
  final profileViewModel = ProfileViewModel(
    authService: authService,
    storageService: storage,
    notificationService: notification,
    reportService: reportService,
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

      // Firebase Service Singletons
      Provider<AnalyticsService>.value(value: analytics),
      Provider<CrashlyticsService>.value(value: crashlytics),
      Provider<RemoteConfigService>.value(value: remoteConfig),
      Provider<StorageService>.value(value: storage),
      Provider<NotificationService>.value(value: notification),

      // MVVM ViewModels
      ChangeNotifierProvider<AuthViewModel>.value(value: authViewModel),
      ChangeNotifierProvider<MealPlanViewModel>.value(value: mealPlanViewModel),
      ChangeNotifierProvider<IngredientViewModel>.value(
          value: ingredientViewModel),
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
      title: 'Longvita — Longevity Nutrition',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}
