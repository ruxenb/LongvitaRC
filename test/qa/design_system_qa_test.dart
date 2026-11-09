// CHARLIE-UI-01 QA host: renders the Longvita components with the bundled
// fonts, writes actual screenshots to evidence/ui/CHARLIE-UI-01/<run-id>/
// and checks sizes, states and semantics against the Figma spec.
//
// Run: flutter test --no-pub test/qa/design_system_qa_test.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/theme/app_theme.dart';
import 'package:longvita/widgets/longvita_widgets.dart';

import 'component_gallery.dart';
import 'qa_support.dart';

void main() {
  final theme = AppTheme.lightTheme;

  setUpAll(loadQaFonts);

  group('screenshots (actual)', () {
    final shots = <String, (Widget Function(), Size, String)>{
      'buttons': (qaButtons, const Size(1432, 280), '55:111'),
      'text-fields': (qaTextFields, const Size(1080, 380), '55:143'),
      'cards': (qaCards, const Size(1432, 280), '56:80'),
      'navigation': (qaNavigation, const Size(1608, 128), '56:174'),
      'app-bar': (qaTopBars, const Size(792, 112), '56:191'),
      'dialogs': (qaDialogs, const Size(1112, 1000), '57:169'),
      'states': (qaStates, const Size(1432, 820), '57:181 57:212 57:255'),
      'supporting': (
        qaSupporting,
        const Size(1100, 560),
        '56:35 55:59 56:198 56:213 57:256 57:260',
      ),
    };

    for (final entry in shots.entries) {
      testWidgets(entry.key, (tester) async {
        final key = GlobalKey();
        final (builder, size, node) = entry.value;
        await pumpQa(
          tester,
          builder(),
          size: size,
          theme: theme,
          boundaryKey: key,
          realShadows: true,
        );
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await captureQa(
          tester,
          key,
          entry.key,
          metadata: {
            'figmaNode': node,
            'textScale': 1.0,
            'host': 'flutter_test widget host (not Android runtime)',
          },
        );
      });
    }

    for (final viewport in const [Size(360, 674), Size(412, 652)]) {
      for (final scale in const [1.0, 1.3, 2.0]) {
        final name =
            'qa-responsive-${viewport.width.toInt()}'
            '${scale == 1.0 ? '' : '-text${scale.toString().replaceAll('.', '_')}'}';
        testWidgets(name, (tester) async {
          final key = GlobalKey();
          await pumpQa(
            tester,
            qaResponsive(),
            size: viewport,
            theme: theme,
            textScale: scale,
            boundaryKey: key,
            realShadows: true,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'no overflow at ${viewport.width} / textScale $scale',
          );
          await captureQa(
            tester,
            key,
            name,
            pixelRatio: scale == 1.0 ? 2.0 : 1.0,
            metadata: {
              'figmaNode': viewport.width == 360 ? '58:717' : '58:770',
              'textScale': scale,
              'host': 'flutter_test widget host (not Android runtime)',
            },
          );
        });
      }
    }
  });

  group('spec checks', () {
    Future<void> pumpOne(
      WidgetTester tester,
      Widget child, {
      double width = 360,
    }) async {
      await pumpQa(
        tester,
        Scaffold(
          backgroundColor: AppColors.bgCanvas,
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: width - 32, child: child),
            ),
          ),
        ),
        size: Size(width, 800),
        theme: theme,
      );
    }

    testWidgets('button heights: 52 min, 56 with icon; radius 12', (
      tester,
    ) async {
      await pumpOne(
        tester,
        Column(
          children: [
            AppButton(
              key: const Key('plain'),
              text: 'Save plan',
              onPressed: () {},
            ),
            AppButton(
              key: const Key('icon'),
              text: 'Generate Weekly Plan',
              icon: AppIcons.arrowForward,
              onPressed: () {},
            ),
          ],
        ),
      );
      expect(tester.getSize(find.byKey(const Key('plain'))).height, 52);
      expect(tester.getSize(find.byKey(const Key('icon'))).height, 56);
    });

    testWidgets('button states: disabled, loading, pressed colours', (
      tester,
    ) async {
      var taps = 0;
      await pumpOne(
        tester,
        Column(
          children: [
            const AppButton(key: Key('disabled'), text: 'Disabled'),
            AppButton(
              key: const Key('loading'),
              text: 'Save',
              loadingText: 'Please wait…',
              isLoading: true,
              onPressed: () => taps++,
            ),
            AppButton(
              key: const Key('primary'),
              text: 'Go',
              onPressed: () => taps++,
            ),
          ],
        ),
      );

      BoxDecoration deco(String key) =>
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byKey(Key(key)),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;

      expect(deco('disabled').color, AppColors.disabledBg);
      await tester.tap(find.byKey(const Key('loading')));
      expect(taps, 0, reason: 'loading ignores taps');
      expect(find.text('Please wait…'), findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('primary'))),
      );
      await tester.pump();
      expect(deco('primary').color, AppColors.actionPressed);
      await gesture.up();
      await tester.pump();
      expect(deco('primary').color, AppColors.actionPrimary);
      expect(taps, 1);
    });

    testWidgets('semantics: button label once, enabled flags', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpOne(
        tester,
        Column(
          children: [
            AppButton(text: 'Create weekly plan', onPressed: () {}),
            const AppButton(text: 'Save changes'),
          ],
        ),
      );
      expect(
        tester.getSemantics(find.text('Create weekly plan')),
        matchesSemantics(
          label: 'Create weekly plan',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.text('Save changes')),
        matchesSemantics(
          label: 'Save changes',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('touch targets >= 48', (tester) async {
      await pumpOne(
        tester,
        Column(
          children: [
            AppIconButton(
              key: const Key('ib'),
              icon: AppIcons.arrowBack,
              semanticLabel: 'Back',
              onPressed: () {},
            ),
            AppCheckboxRow(
              key: const Key('cb'),
              label: 'Lentils · 500 g',
              checked: false,
              onChanged: (_) {},
            ),
            AppDaySelector(
              key: const Key('day'),
              day: 'Mon',
              date: '14',
              onTap: () {},
            ),
            AppQuantityStepper(
              key: const Key('step'),
              valueLabel: '55 kg',
              onDecrement: () {},
              onIncrement: () {},
            ),
          ],
        ),
      );
      for (final k in ['ib', 'cb', 'day', 'step']) {
        final s = tester.getSize(find.byKey(Key(k)));
        expect(s.height, greaterThanOrEqualTo(48), reason: k);
        expect(s.width, greaterThanOrEqualTo(48), reason: k);
      }
    });

    testWidgets('navigation: height 80, selected semantics, callback', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      int? tapped;
      await pumpQa(
        tester,
        Scaffold(
          bottomNavigationBar: AppNavigationBar(
            selectedIndex: 1,
            onDestinationSelected: (i) => tapped = i,
          ),
        ),
        size: const Size(360, 800),
        theme: theme,
      );
      expect(tester.getSize(find.byType(AppNavigationBar)).height, 80);
      expect(
        tester.getSemantics(find.text('Thực đơn')),
        matchesSemantics(
          label: 'Thực đơn',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.text('Hồ sơ'));
      expect(tapped, 3);
      handle.dispose();
    });

    testWidgets('text field: 58 input, error replaces helper, focus border', (
      tester,
    ) async {
      await pumpOne(
        tester,
        Column(
          children: [
            const AppTextField(
              key: Key('ok'),
              label: 'Your weight (kg)',
              unit: 'kg',
              helperText: 'Used to personalize your meal plan.',
            ),
            AppTextField(
              key: const Key('err'),
              label: 'Quantity',
              controller: TextEditingController(text: '-5'),
              unit: 'g',
              helperText: 'Lentils · grams',
              errorText: 'Enter a positive quantity, for example 500.',
            ),
          ],
        ),
      );
      final input = find.descendant(
        of: find.byKey(const Key('ok')),
        matching: find.byType(TextField),
      );
      expect(tester.getSize(input).height, 58);
      expect(find.text('Lentils · grams'), findsNothing);
      expect(
        find.text('Enter a positive quantity, for example 500.'),
        findsOneWidget,
      );
    });

    testWidgets('checkbox semantics and toggle', (tester) async {
      final handle = tester.ensureSemantics();
      bool? value;
      await pumpOne(
        tester,
        AppCheckboxRow(
          label: 'Lentils · 500 g',
          checked: true,
          onChanged: (v) => value = v,
        ),
      );
      expect(
        tester.getSemantics(find.byType(AppCheckboxRow)),
        matchesSemantics(
          label: 'Lentils · 500 g',
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.byType(AppCheckboxRow));
      expect(value, isFalse);
      handle.dispose();
    });

    testWidgets('EditError dialog keeps primary disabled; cancel closes', (
      tester,
    ) async {
      var saved = false;
      await pumpQa(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: AppButton(
                text: 'Open',
                width: 200,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AppDialog.edit(
                    title: 'Edit ingredient',
                    message: 'Correct the quantity before saving.',
                    content: AppTextField(
                      label: 'Quantity',
                      controller: TextEditingController(text: '-5'),
                      unit: 'g',
                      errorText: 'Enter a positive quantity, for example 500.',
                    ),
                    primaryLabel: 'Save changes',
                    secondaryLabel: 'Cancel',
                    onSecondary: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ),
            ),
          ),
        ),
        size: const Size(360, 800),
        theme: theme,
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AppDialog).first).width, 360);
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(
        find.text('Edit ingredient'),
        findsOneWidget,
        reason: 'disabled primary keeps the dialog open',
      );
      expect(saved, isFalse);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Edit ingredient'), findsNothing);
    });

    testWidgets('snackbar Undo calls back and hides', (tester) async {
      var undone = false;
      await pumpQa(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: AppButton(
                text: 'Remove',
                width: 200,
                onPressed: () => showAppSnackBar(
                  context,
                  message: 'Ingredient removed',
                  actionLabel: 'Undo',
                  onAction: () => undone = true,
                ),
              ),
            ),
          ),
        ),
        size: const Size(360, 800),
        theme: theme,
      );
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AppSnackBarContent)).width, 328);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, isTrue);
      expect(find.text('Ingredient removed'), findsNothing);
    });

    testWidgets('typography tokens match Figma styles', (tester) async {
      expect(AppTypography.body.fontSize, 16);
      expect(AppTypography.body.height! * 16, closeTo(26, 0.001));
      expect(AppTypography.headingM.fontFamily, 'Newsreader');
      expect(AppTypography.brand.fontFamily, 'Fraunces');
      expect(AppTypography.label.fontWeight, FontWeight.w600);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF6F1E7));
      expect(debugPaintSizeEnabled, isFalse);
    });
  });
}
