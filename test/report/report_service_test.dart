// S4-10 preparation: Vietnamese PDF and local file handling, using a fixture
// plan. The fixture is not real catalog data and does not prove the export of
// the plan a user is viewing, which waits for S4-3.
//
// Set QA_PDF_OUT to a file path to keep the generated PDF for visual checks.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:longvita/models/meal_plan_model.dart';
import 'package:longvita/models/recipe_model.dart';
import 'package:longvita/services/local_report_store.dart';
import 'package:longvita/services/report_service.dart';
import 'package:pdf/pdf.dart';

const vietnameseLetters =
    'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ'
    'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';

Future<ByteData> loadFromDisk(String asset) async =>
    ByteData.sublistView(await File(asset).readAsBytes());

RecipeModel meal(String id, String name, String category) => RecipeModel(
      id: id,
      name: name,
      description: 'Dữ liệu mẫu cho test',
      category: category,
      proteinGrams: 18.5,
      calories: 320,
      ingredients: const [],
      instructions: const ['Bước mẫu'],
    );

MealPlanModel fixturePlan() => MealPlanModel(
      id: 'fixture',
      uid: 'uid-a',
      title: 'Thực đơn mẫu để kiểm tra phông chữ (fixture, không phải dữ liệu thật)',
      targetCalories: 1800,
      targetProteinGrams: 49.6,
      createdAt: DateTime(2026, 11, 2),
      days: [
        for (final day in const [
          'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật',
        ])
          DailyMeal(dayIndex: 0, dayName: day, meals: [
            meal('a', 'Súp đậu gà hầm cà chua và hương thảo', 'dau'),
            meal('b', 'Cá hồi áp chảo dầu ô liu với rau bina', 'ca'),
            meal('c', 'Gỏi rau củ, hạt óc chó và dưa leo trộn nước sốt ổi', 'rau_cu'),
          ]),
      ],
    );

void main() {
  group('PDF fonts', () {
    for (final asset in [pdfRegularFontAsset, pdfBoldFontAsset]) {
      test('$asset has every Vietnamese letter', () async {
        final parser = TtfParser(await loadFromDisk(asset));

        final missing = vietnameseLetters.runes
            .where((rune) => !parser.charToGlyphIndexMap.containsKey(rune))
            .map(String.fromCharCode)
            .toList();

        expect(missing, isEmpty);
      });
    }
  });

  group('ReportService', () {
    test('generates a PDF with the fonts embedded', () async {
      final bytes = await ReportService(loadAsset: loadFromDisk)
          .generateMealPlanPdf(fixturePlan());

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      final raw = String.fromCharCodes(bytes);
      expect(raw, contains('Roboto'), reason: 'font must be embedded by name');

      final out = Platform.environment['QA_PDF_OUT'];
      if (out != null) {
        await File(out).parent.create(recursive: true);
        await File(out).writeAsBytes(bytes);
      }
    });

    Future<int> pageCount(MealPlanModel plan) async {
      final doc =
          await ReportService(loadAsset: loadFromDisk).buildDocument(plan);
      await doc.save();
      return doc.document.pdfPageList.pages.length;
    }

    test('days that fill a page leave no page holding only the note', () async {
      final plan = fixturePlan();
      final shorter = plan.copyWith(days: [
        for (final day in plan.days)
          DailyMeal(
              dayIndex: day.dayIndex,
              dayName: day.dayName,
              meals: day.meals.take(2).toList()),
      ]);

      expect(await pageCount(shorter), 1);
    });

    test('a longer week continues on the next page', () async {
      expect(await pageCount(fixturePlan()), 2);
    });

    test('a missing font is an error, not a PDF with blank text', () async {
      final service = ReportService(
          loadAsset: (asset) async => throw Exception('missing $asset'));

      await expectLater(
          service.generateMealPlanPdf(fixturePlan()), throwsException);
    });

    test('a plan with no days still generates', () async {
      final plan = MealPlanModel(
        id: 'empty',
        uid: 'uid-a',
        title: 'Không có ngày',
        targetCalories: 1800,
        targetProteinGrams: 50,
        createdAt: DateTime(2026, 11, 2),
        days: const [],
      );

      final bytes =
          await ReportService(loadAsset: loadFromDisk).generateMealPlanPdf(plan);

      expect(bytes, isNotEmpty);
    });
  });

  group('LocalReportStore', () {
    late Directory dir;
    late LocalReportStore store;
    final bytes = Uint8List.fromList([1, 2, 3]);

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('longvita_reports');
      store = LocalReportStore(baseDirectory: () async => dir);
    });

    tearDown(() => dir.delete(recursive: true));

    test('saves under the owner folder and finds it again', () async {
      final file = await store.save(uid: 'uid-a', exportId: 'e1', bytes: bytes);

      expect(file.path.replaceAll(r'\', '/'), endsWith('reports/uid-a/e1.pdf'));
      expect(await file.readAsBytes(), bytes);
      expect((await store.find(uid: 'uid-a', exportId: 'e1'))?.path, file.path);
    });

    test('leaves no temporary file behind', () async {
      await store.save(uid: 'uid-a', exportId: 'e1', bytes: bytes);

      final names = Directory('${dir.path}/reports/uid-a')
          .listSync()
          .map((e) => e.uri.pathSegments.last);
      expect(names, ['e1.pdf']);
    });

    test('saving the same export id replaces the file', () async {
      await store.save(uid: 'uid-a', exportId: 'e1', bytes: bytes);
      final file = await store.save(
          uid: 'uid-a', exportId: 'e1', bytes: Uint8List.fromList([9]));

      expect(await file.readAsBytes(), [9]);
    });

    test('another user does not find the file', () async {
      await store.save(uid: 'uid-a', exportId: 'e1', bytes: bytes);

      expect(await store.find(uid: 'uid-b', exportId: 'e1'), isNull);
    });

    test('delete removes one file, and a missing file is fine', () async {
      await store.save(uid: 'uid-a', exportId: 'e1', bytes: bytes);
      await store.save(uid: 'uid-a', exportId: 'e2', bytes: bytes);

      await store.delete(uid: 'uid-a', exportId: 'e1');
      await store.delete(uid: 'uid-a', exportId: 'gone');

      expect(await store.find(uid: 'uid-a', exportId: 'e1'), isNull);
      expect(await store.find(uid: 'uid-a', exportId: 'e2'), isNotNull);
    });

    test('deleteAll removes only the files of that user', () async {
      await store.save(uid: 'uid-a', exportId: 'e1', bytes: bytes);
      await store.save(uid: 'uid-b', exportId: 'e1', bytes: bytes);

      await store.deleteAll(uid: 'uid-a');
      await store.deleteAll(uid: 'uid-c');

      expect(await store.find(uid: 'uid-a', exportId: 'e1'), isNull);
      expect(await store.find(uid: 'uid-b', exportId: 'e1'), isNotNull);
    });

    // PM-S3-5-04: sign-out removes a user's files without waiting. The same
    // user signing back in must not lose a PDF saved after that removal.
    group('operations of one user run in call order', () {
      late Completer<void> hold;
      late LocalReportStore gated;

      setUp(() {
        hold = Completer<void>();
        var first = true;
        // Holds the first lookup, which belongs to the removal under test.
        gated = LocalReportStore(baseDirectory: () async {
          if (first) {
            first = false;
            await hold.future;
          }
          return dir;
        });
      });

      test('a removal still running does not delete a later save', () async {
        await store.save(uid: 'uid-a', exportId: 'old', bytes: bytes);

        final removal = gated.deleteAll(uid: 'uid-a');
        var saved = false;
        final save = gated
            .save(uid: 'uid-a', exportId: 'new', bytes: bytes)
            .then((file) => saved = true);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(saved, isFalse, reason: 'the save waits for the removal');

        hold.complete();
        await removal;
        await save;

        expect(await gated.find(uid: 'uid-a', exportId: 'old'), isNull);
        expect(await gated.read(uid: 'uid-a', exportId: 'new'), bytes);
      });

      test('a save queued before the removal is removed with it', () async {
        final save = gated.save(uid: 'uid-a', exportId: 'e1', bytes: bytes);
        final removal = gated.deleteAll(uid: 'uid-a');

        hold.complete();
        await save;
        await removal;

        expect(await gated.find(uid: 'uid-a', exportId: 'e1'), isNull);
      });

      test('another user does not wait for the removal', () async {
        final removal = gated.deleteAll(uid: 'uid-a');

        await gated.save(uid: 'uid-b', exportId: 'e1', bytes: bytes);
        expect(await gated.find(uid: 'uid-b', exportId: 'e1'), isNotNull);

        hold.complete();
        await removal;
      });

      test('a failed operation does not block the next one', () async {
        await expectLater(
            gated.save(uid: 'uid-a', exportId: '../x', bytes: bytes),
            throwsArgumentError);
        hold.complete();

        await gated.save(uid: 'uid-a', exportId: 'e1', bytes: bytes);
        expect(await gated.find(uid: 'uid-a', exportId: 'e1'), isNotNull);
      });
    });

    test('deleteAll rejects an id that could leave the folder', () async {
      await expectLater(
          store.deleteAll(uid: '../uid-a'), throwsArgumentError);
    });

    test('rejects ids that could leave the folder', () async {
      await expectLater(
          store.save(uid: '../uid-b', exportId: 'e1', bytes: bytes),
          throwsArgumentError);
      await expectLater(store.find(uid: 'uid-a', exportId: '../../secret'),
          throwsArgumentError);
    });
  });
}
