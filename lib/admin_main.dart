import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin/admin_app.dart';
import 'admin/admin_auth.dart';
import 'admin/admin_instrumentation.dart';
import 'admin/admin_service.dart';
import 'admin/admin_viewmodels.dart';
import 'firebase_options.dart';
import 'firebase/analytics_service.dart';
import 'firebase/remote_config_service.dart';
import 'theme/app_typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppTypography.registerFontLicenses();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final service = AdminService();
  final instrumentation = AdminWebInstrumentation(
    analytics: AnalyticsService(),
    remoteConfig: RemoteConfigService(),
  );
  await instrumentation.initialize();
  runApp(
    MultiProvider(
      providers: [
        Provider<IAdminService>.value(value: service),
        ChangeNotifierProvider.value(value: instrumentation),
        ChangeNotifierProvider(create: (_) => RecipeAdminViewModel(service)),
        ChangeNotifierProvider(
          create: (_) => ReviewQueueViewModel(
            service,
            trackSuccessfulReview: instrumentation.logPlanReview,
          ),
        ),
        ChangeNotifierProvider(create: (_) => DashboardViewModel(service)),
      ],
      child: LongvitaAdminApp(auth: FirebaseAdminAuthGateway()),
    ),
  );
}
