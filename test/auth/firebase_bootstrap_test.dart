import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/firebase/firebase_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<BootstrapResult> run(Object error) => FirebaseBootstrap(
        initializeApp: () async => throw error,
      ).initialize();

  test('Android missing google-services (as seen in logcat) is not-configured',
      () async {
    final result = await run(PlatformException(
      code: 'java.lang.Exception: Failed to load FirebaseOptions from '
          'resource. Check that you have defined values.xml correctly.',
      message: 'Exception',
    ));
    expect(result, isA<BootstrapFailed>());
    expect((result as BootstrapFailed).isConfigurationMissing, isTrue);
  });

  test('other Firebase failures keep their code and allow retry', () async {
    final result = await run(
        FirebaseException(plugin: 'core', code: 'unavailable', message: 'x'));
    expect((result as BootstrapFailed).code, 'unavailable');
    expect(result.isConfigurationMissing, isFalse);
  });
}
