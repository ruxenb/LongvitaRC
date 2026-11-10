import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:longvita_admin/admin/admin_app.dart';
import 'package:longvita_admin/admin/admin_auth.dart';
import 'package:longvita_admin/admin/admin_instrumentation.dart';
import 'package:longvita_core/services/admin_service.dart';
import 'package:longvita_core/services/i_announcement_publisher.dart';
import 'package:longvita_core/services/firestore_announcement_publisher.dart';

import 'firebase_options.dart';

import 'package:longvita_core/firebase/analytics_service.dart';
import 'package:longvita_core/firebase/remote_config_service.dart';
import 'package:longvita_core/theme/app_typography.dart';

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
        Provider<IAnnouncementPublisher>(
          create: (_) => FirestoreAnnouncementPublisher(
            currentUid: () => FirebaseAuth.instance.currentUser?.uid,
          ),
        ),
        ChangeNotifierProvider.value(value: instrumentation),
      ],
      child: LongvitaAdminApp(auth: FirebaseAdminAuthGateway()),
    ),
  );
}
