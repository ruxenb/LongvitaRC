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

    def expect_rejected(self, source, member='mobile'):
        """Require the real consumer error for a source that imports no Core."""
        (self.root/member/'lib/consumer.dart').write_text(source, encoding='utf-8')
        expected = 'Mobile must consume Core' if member == 'mobile' else 'Web must consume the real shared Core package'
        self.assertIn(expected, MODULE.validate(self.root))

    def test_real_barrel_import_is_accepted(self):
        """Both clients may import the shared facade."""
        self.assertEqual([], MODULE.validate(self.root))

    def test_public_module_import_is_accepted(self):
        """Documented public module imports remain supported."""
        (self.root/'mobile/lib/consumer.dart').write_text(
            "import 'package:longvita_core/models/user_model.dart';\n",
            encoding='utf-8',
        )
        self.assertEqual([], MODULE.validate(self.root))

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


if __name__ == '__main__':
    unittest.main()
