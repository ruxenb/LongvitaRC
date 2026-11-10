import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_core/longvita_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Web bundles Core fonts without depending on Mobile assets', () async {
    expect(
      AppTheme.lightTheme.textTheme.bodyMedium!.fontFamily,
      'packages/longvita_core/Quicksand',
    );
    for (final family in ['Quicksand', 'Newsreader', 'Fraunces']) {
      final font = await rootBundle.load(
        'packages/longvita_core/assets/fonts/$family-Variable.ttf',
      );
      expect(font.lengthInBytes, greaterThan(1000));
      final licence = await rootBundle.loadString(
        'packages/longvita_core/assets/fonts/$family-OFL.txt',
      );
      expect(licence.toUpperCase(), contains('SIL OPEN FONT LICENSE'));
    }
  });
}
