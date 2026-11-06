// QA host for S3-1: the real StartupGate whose first start is an injected
// failure, so the error view and retry can be seen on a device without
// breaking the Firebase config. "Thử lại" then runs the real
// FirebaseBootstrap and buildAppScope, i.e. the normal app.
//
//   flutter build apk --debug -t test/qa/startup_recovery_host.dart
//
// Installing it over the app keeps the app's data (and its session); put the
// normal build back afterwards.
import 'package:flutter/material.dart';
import 'package:longvita/firebase/firebase_bootstrap.dart';
import 'package:longvita/main.dart' show buildAppScope;
import 'package:longvita/screens/startup_gate.dart';
import 'package:longvita/theme/app_typography.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppTypography.registerFontLicenses();

  final bootstrap = FirebaseBootstrap();
  var attempts = 0;
  runApp(StartupGate(
    initialize: () async {
      if (++attempts == 1) {
        // Long enough to see the loading state first.
        await Future<void>.delayed(const Duration(seconds: 2));
        return BootstrapFailed(
            'qa-injected', StateError('QA: injected start-up failure'));
      }
      return bootstrap.initialize();
    },
    buildReadyApp: buildAppScope,
  ));
}
