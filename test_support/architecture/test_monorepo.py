"""Offline boundary-checker regressions; no Flutter, Firebase or device access."""
import importlib.util
import os
from pathlib import Path
import shutil
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]
CHECKER = Path(os.environ.get('MONOREPO_CHECKER_PATH', REPO/'scripts/check-monorepo.py'))
SPEC = importlib.util.spec_from_file_location('monorepo_checker', CHECKER)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class CoreConsumptionTest(unittest.TestCase):
    """Exercise validate itself so a comment cannot masquerade as consumption."""

    def setUp(self):
        """Build an isolated minimal filesystem with real client config values."""
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        paths = [
            'firebase.json', 'mobile/pubspec.yaml', 'web/pubspec.yaml',
            'packages/core/pubspec.yaml', 'mobile/lib/firebase_options.dart',
            'web/lib/firebase_options.dart',
            'mobile/android/app/google-services.json',
            'mobile/android/app/build.gradle.kts',
        ]
        for relative in paths:
            destination = self.root/relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(REPO/relative, destination)
        for category in ['auth', 'rules', 'web', 'cross_role', 'ai']:
            (self.root/'evidence'/category).mkdir(parents=True)
        for family in ['Quicksand', 'Newsreader', 'Fraunces']:
            for suffix in ['Variable.ttf', 'OFL.txt']:
                file = self.root/f'packages/core/assets/fonts/{family}-{suffix}'
                file.parent.mkdir(parents=True, exist_ok=True)
                file.touch()
        for member in ['mobile', 'web']:
            (self.root/member/'lib/consumer.dart').write_text(
                "import 'package:longvita_core/longvita_core.dart';\n",
                encoding='utf-8',
            )

    def errors(self):
        """Normalize only diagnostic path separators across Windows and Linux."""
        return [error.replace('\\', '/') for error in MODULE.validate(self.root)]

    def expect_rejected(self, source, member='mobile'):
        """Require the real consumer error for a source that imports no Core."""
        (self.root/member/'lib/consumer.dart').write_text(source, encoding='utf-8')
        expected = 'Mobile must consume Core' if member == 'mobile' else 'Web must consume the real shared Core package'
        self.assertIn(expected, self.errors())

    def test_real_barrel_import_is_accepted(self):
        """Both clients may import the shared facade."""
        self.assertEqual([], self.errors())

    def test_public_module_import_is_accepted(self):
        """Documented public module imports remain supported."""
        (self.root/'mobile/lib/consumer.dart').write_text(
            "import 'package:longvita_core/models/user_model.dart';\n",
            encoding='utf-8',
        )
        self.assertEqual([], self.errors())

    def test_mobile_line_comment_is_not_consumption(self):
        """A commented example is not an actual import."""
        self.expect_rejected("// import 'package:longvita_core/longvita_core.dart';")

    def test_mobile_string_is_not_consumption(self):
        """A URI in an ordinary string is not a dependency."""
        self.expect_rejected("const example = 'package:longvita_core/models/user_model.dart';")

    def test_mobile_block_comment_is_not_consumption(self):
        """An import inside a block comment is ignored."""
        self.expect_rejected("/*\nimport 'package:longvita_core/longvita_core.dart';\n*/")

    def test_web_block_comment_is_not_consumption(self):
        """Web has the same real-import check as Mobile."""
        self.expect_rejected("/*\nimport 'package:longvita_core/longvita_core.dart';\n*/", 'web')

    def test_nested_comment_is_not_consumption(self):
        """Dart allows nested block comments; the outer comment still applies."""
        self.expect_rejected("/* /* nested */\nimport 'package:longvita_core/longvita_core.dart';\n*/")

    def test_multiline_string_is_not_consumption(self):
        """A code example inside a multiline string must not pass the check."""
        self.expect_rejected('const example = """\nimport \'package:longvita_core/longvita_core.dart\';\n""";')

    def test_web_forbidden_imports_are_rejected(self):
        """Keep Core consumption valid while checking each forbidden dependency."""
        for uri, expected in [
            ('dart:io', 'web/lib/forbidden.dart: dart:io is client-native'),
            ('package:longvita/main.dart', 'web/lib/forbidden.dart: forbidden dependency longvita'),
        ]:
            with self.subTest(uri=uri):
                (self.root/'web/lib/forbidden.dart').write_text(
                    f"import '{uri}';\n", encoding='utf-8',
                )
                self.assertIn(expected, self.errors())

    def test_web_conditional_import_is_rejected(self):
        """The selected platform URI must be checked as well as the stub."""
        (self.root/'web/lib/conditional.dart').write_text(
            "import 'stub.dart' if (dart.library.io) 'dart:io';\n",
            encoding='utf-8',
        )
        self.assertIn('web/lib/conditional.dart: dart:io is client-native',
                      self.errors())

    def test_core_conditional_export_is_rejected(self):
        """Native SDKs cannot hide in a Core conditional export."""
        file = self.root/'packages/core/lib/conditional.dart'
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text("export 'stub.dart' if (dart.library.io) "
                        "'package:firebase_storage/firebase_storage.dart';\n",
                        encoding='utf-8')
        self.assertIn('packages/core/lib/conditional.dart: forbidden dependency firebase_storage',
                      self.errors())

    def test_core_in_conditional_import_is_consumption(self):
        """A valid Core dependency in the platform branch must be recognized."""
        (self.root/'mobile/lib/consumer.dart').write_text(
            "import 'stub.dart' if (dart.library.ui) 'package:longvita_core/longvita_core.dart';\n",
            encoding='utf-8',
        )
        self.assertEqual([], self.errors())

    def test_directive_ends_at_semicolon(self):
        """A following call/string is not part of the preceding directive."""
        self.expect_rejected("import 'stub.dart';\n"
                             "void demo() { call(); 'package:longvita_core/longvita_core.dart'; }")

    def test_raw_core_uri_is_consumption(self):
        """Valid raw URI literals are accepted for either client."""
        for member in ['mobile', 'web']:
            (self.root/member/'lib/consumer.dart').write_text(
                "import r'package:longvita_core/longvita_core.dart';\n",
                encoding='utf-8',
            )
        self.assertEqual([], self.errors())

    def test_multiline_delimiter_uri_is_checked(self):
        """Triple-quoted URI delimiters do not hide forbidden imports."""
        (self.root/'web/lib/forbidden.dart').write_text(
            "import '''dart:io''';\n", encoding='utf-8',
        )
        self.assertIn('web/lib/forbidden.dart: dart:io is client-native',
                      self.errors())


if __name__ == '__main__':
    unittest.main()
