"""Check CM-00/02 boundaries and client config without Firebase/network access."""
import argparse
import json
from pathlib import Path
import re


_DART_TOKEN = re.compile(
    r"//[^\n]*|/\*|r?(?:\"\"\"[\s\S]*?\"\"\"|'''[\s\S]*?'''|"
    r"\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*')|[A-Za-z_]\w*|[^\s]"
)


def dart_imports(content: str) -> list[str]:
    """Read import/export URIs, skipping strings and nested Dart comments."""
    uris = []
    cursor = 0
    expects_uri = False
    while match := _DART_TOKEN.search(content, cursor):
        token = match[0]
        cursor = match.end()
        if token.startswith('//'):
            continue
        if token == '/*':
            depth = 1
            while depth:
                delimiter = re.search(r'/\*|\*/', content[cursor:])
                if delimiter is None:
                    return uris
                depth += 1 if delimiter[0] == '/*' else -1
                cursor += delimiter.end()
            continue
        if token in {'import', 'export'}:
            expects_uri = True
            continue
        if expects_uri and token.startswith(("'", '"')):
            uris.append(token[1:-1])
        expects_uri = False
    return uris


def validate(root: Path) -> list[str]:
    """Return actionable errors for a concrete workspace, without changing it."""
    errors = []

    def check(condition, message):
        """Accumulate all failures so one run gives the complete picture."""
        if not condition:
            errors.append(message)

    for member in ['mobile', 'web', 'packages/core']:
        manifest = root / member / 'pubspec.yaml'
        check(manifest.is_file(), f'Missing member manifest: {member}')
        if manifest.is_file():
            check('resolution: workspace' in manifest.read_text(encoding='utf-8'),
                  f'{member} must use workspace resolution')
        check(not (root/member/'pubspec.lock').exists(),
              f'{member} has a stray lockfile; run pub get from the workspace')

    native_packages = {'firebase_storage', 'firebase_messaging', 'firebase_crashlytics',
                       'google_sign_in', 'path_provider', 'printing', 'pdf'}
    for member, forbidden_clients in [('packages/core', {'longvita', 'longvita_admin'}),
                                      ('web', {'longvita'})]:
        imports_core = False
        for path in sorted((root/member/'lib').rglob('*.dart')):
            content = path.read_text(encoding='utf-8')
            for uri in dart_imports(content):
                if uri.startswith('package:'):
                    package = uri[8:].split('/')[0]
                    imports_core |= package == 'longvita_core'
                    check(package not in forbidden_clients | native_packages,
                          f'{path.relative_to(root)}: forbidden dependency {package}')
                elif uri.startswith('dart:'):
                    check(uri != 'dart:io', f'{path.relative_to(root)}: dart:io is client-native')
                else:
                    resolved = (path.parent/uri).resolve()
                    check(resolved.is_relative_to((root/member/'lib').resolve()),
                          f'{path.relative_to(root)}: import escapes its package: {uri}')
            if member == 'packages/core':
                check('Firebase.initializeApp(' not in content,
                      f'{path.relative_to(root)}: Firebase bootstrap belongs to clients')
        if member == 'web':
            check(imports_core, 'Web must consume the real shared Core package')
    mobile_uris = [uri for p in (root/'mobile/lib').rglob('*.dart')
                   for uri in dart_imports(p.read_text(encoding='utf-8'))]
    check(any(uri.startswith('package:longvita_core/') for uri in mobile_uris),
          'Mobile must consume Core')
    check(not list((root/'lib').rglob('*.dart')), 'Root still has a duplicate Dart implementation')

    config = json.loads((root/'firebase.json').read_text(encoding='utf-8'))
    check(config['hosting']['public'] == 'web/build/web', 'Hosting output must be web/build/web')
    check(config['firestore']['rules'] == 'firebase/firestore.rules', 'Canonical rules path changed')
    android = config['flutter']['platforms']['android']['default']
    check(android['fileOutput'] == 'mobile/android/app/google-services.json',
          'Android generated-config path must point into Mobile')
    native = json.loads((root/android['fileOutput']).read_text(encoding='utf-8'))
    clients = native['client']
    android_ids = {c['client_info']['mobilesdk_app_id'] for c in clients}
    check(android['appId'] in android_ids, 'Android App ID does not match google-services.json')
    gradle = (root/'mobile/android/app/build.gradle.kts').read_text(encoding='utf-8')
    package_names = {c['client_info']['android_client_info']['package_name'] for c in clients}
    check(any(f'applicationId = "{name}"' in gradle for name in package_names),
          'Android package name differs from native Firebase registration')
    dart_configs = config['flutter']['platforms']['dart']
    check(set(dart_configs) == {'mobile/lib/firebase_options.dart', 'web/lib/firebase_options.dart'},
          'Each Firebase Dart configuration must belong to its client')
    for path, settings in dart_configs.items():
        text = (root/path).read_text(encoding='utf-8')
        for platform, app_id in settings['configurations'].items():
            check(f"appId: '{app_id}'" in text, f'{path}: {platform} App ID mismatch')
        check(f"projectId: '{settings['projectId']}'" in text, f'{path}: project mismatch')
    for family in ['Quicksand', 'Newsreader', 'Fraunces']:
        for suffix in ['Variable.ttf', 'OFL.txt']:
            check((root/f'packages/core/assets/fonts/{family}-{suffix}').is_file(),
                  f'Missing shared font/license: {family}-{suffix}')
    for category in ['auth', 'rules', 'web', 'cross_role', 'ai']:
        check((root/'evidence'/category).is_dir(), f'Missing canonical evidence/{category}')
    return errors


def main() -> int:
    """Allow a fixture root for negative checks; default to this repository."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    options = parser.parse_args()
    failures = validate(options.root.resolve())
    for failure in failures:
        print('ERROR:', failure)
    if failures:
        return 1
    print('PASS: Mobile -> Core <- Web; client config and canonical paths are consistent.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
