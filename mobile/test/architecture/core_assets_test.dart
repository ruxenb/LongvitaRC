import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita_core/longvita_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Mobile bundles the shared UI fonts and their licences', () async {
    expect(
      AppTypography.headingM.fontFamily,
      'packages/longvita_core/Newsreader',
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
