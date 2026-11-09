import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin/admin_app.dart';
import 'admin/admin_auth.dart';
import 'admin/admin_service.dart';
import 'admin/admin_viewmodels.dart';
import 'firebase_options.dart';
import 'theme/app_typography.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppTypography.registerFontLicenses();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final service = AdminService();
  runApp(
    MultiProvider(
      providers: [
        Provider<IAdminService>.value(value: service),
        ChangeNotifierProvider(create: (_) => RecipeAdminViewModel(service)),
        ChangeNotifierProvider(create: (_) => ReviewQueueViewModel(service)),
        ChangeNotifierProvider(create: (_) => DashboardViewModel(service)),
      ],
      child: LongvitaAdminApp(auth: FirebaseAdminAuthGateway()),
    ),
  );
}
