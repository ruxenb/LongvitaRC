// QA-only helpers for CHARLIE-UI-01. Not part of the app build.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Find canonical evidence/assets from any workspace member's test cwd.
Directory workspaceRoot() {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/firebase/firestore.rules').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Run QA inside the Longvita workspace.');
    }
    directory = parent;
  }
  return directory;
}

/// Loads the bundled Longvita fonts and the SDK MaterialIcons font so
/// screenshots use real glyphs instead of the test placeholder font.
Future<void> loadQaFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  for (final family in ['Quicksand', 'Newsreader', 'Fraunces']) {
    await load('packages/longvita_core/$family', [
      '${workspaceRoot().path}/packages/core/assets/fonts/$family-Variable.ttf',
    ]);
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null) {
    throw StateError('FLUTTER_ROOT is not set; run through `flutter test`.');
  }
  await load('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  ]);
}

/// Output folder for this run, e.g. `evidence/ui/CHARLIE-UI-01/<run-id>/actual`.
final String qaRunId =
    Platform.environment['QA_RUN_ID'] ??
    DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .substring(0, 19);

/// Evidence folder per task packet; set `QA_TASK` (default CHARLIE-UI-01).
final String qaTask = Platform.environment['QA_TASK'] ?? 'CHARLIE-UI-01';

Directory qaRunDir() => Directory(
  '${Platform.environment['QA_OUTPUT_ROOT'] ?? '${workspaceRoot().path}/evidence/ui'}/$qaTask/$qaRunId',
)..createSync(recursive: true);

/// QA fixture image (Figma "Meal photo / Stitch source", node 56:38).
final MemoryImage qaMealPhoto = MemoryImage(
  File(
    '${workspaceRoot().path}/mobile/test/qa/fixtures/meal_photo_stitch_source.jpg',
  ).readAsBytesSync(),
);

/// Pumps [child] inside the app theme at a logical [size] and text scale.
Future<void> pumpQa(
  WidgetTester tester,
  Widget child, {
  required Size size,
  required ThemeData theme,
  double textScale = 1.0,
  GlobalKey? boundaryKey,
  bool realShadows = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  // flutter_test draws hard-edged shadows by default; screenshots need the
  // real Elevation/1 and Elevation/2 blur. [captureQa] restores the flag
  // because the test binding checks it before tear-downs run.
  if (realShadows) debugDisableShadows = false;

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: RepaintBoundary(key: boundaryKey, child: child),
      ),
    ),
  );
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold).first);
    await precacheImage(qaMealPhoto, context);
  });
  await tester.pump();
}

/// Writes the boundary as PNG at [pixelRatio] and returns its path.
Future<String> captureQa(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String name, {
  double pixelRatio = 2.0,
  Map<String, Object?> metadata = const {},
}) async {
  final dir = Directory('${qaRunDir().path}/actual')..createSync();
  final file = File('${dir.path}/$name.png');
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    file.writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
  debugDisableShadows = true;
  final meta = File('${dir.path}/$name.json');
  meta.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'logicalSize': {
        'width': boundary.size.width,
        'height': boundary.size.height,
      },
      'pixelRatio': pixelRatio,
      ...metadata,
    }),
  );
  return file.path;
}
