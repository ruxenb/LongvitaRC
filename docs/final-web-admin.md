# Longvita Web Admin — TV-00 to TV-03

## Run locally

```powershell
flutter run -d chrome -t lib/admin_main.dart
```

Only Firebase users whose `users/{uid}.role` is `staff` or `admin` can enter
the console. Other signed-in users see an explicit access-denied state.

## Build and deploy

```powershell
flutter build web --target lib/admin_main.dart --release
firebase deploy --only firestore:rules,hosting --project longvita-8da7e
```

The Hosting SPA serves `build/web` and rewrites application routes to
`index.html`.

## Delivered scope

- **TV-00:** Flutter Web target, Firebase Web app configuration, Hosting SPA.
- **TV-01:** recipe search, create, edit, soft archive/restore, and explicit
  loading/empty/error states.
- **TV-02:** real-time `submitted` meal-plan queue with approve/reject actions;
  rejection requires a reason.
- **TV-03:** three Firestore aggregation metrics and a responsive bar view.
- **TV-03B:** Web Remote Config flag `web_show_review_guidance`; successful
  approve/reject Analytics events, plus the `publish_announcement` hook for the
  CM-07 form. No identifiers or free-text content are sent as parameters.

The existing mobile status value `submitted` is presented as “Chờ duyệt”; it
is intentionally not renamed to `pending`, because the model, security rules,
and stored documents already use the audited `submitted` transition.

## Data compatibility

`recipes.isArchived` is optional and defaults to `false` in the model and
security rules. Existing recipe documents remain active without a migration.
The dashboard counts all recipes and subtracts explicitly archived documents.

## Verification — 09/11/2026

- `flutter analyze`: no issues.
- `flutter test test/admin/admin_web_test.dart`: 5/5 passed, covering the role
  gate, recipe create/edit/archive, approve/reject, and dashboard states.
- `flutter test`: 483/483 passed.
- `flutter build web --target lib/admin_main.dart`: succeeded; output is
  `build/web`.
- `firebase.json` explicitly maps Firestore rules to
  `firebase/firestore.rules`; deployment was not performed by this verification.

Detailed evidence and review decisions are recorded in
`evidence/web/TV-00-TV-03-20261109/`.

The 10/11 authentication, Rules and ARTEMIS follow-up is recorded in
`evidence/review/PR25-followup-20261110/README.md`.

TV-03B implementation evidence is recorded in
`evidence/web/TV-03B-20261110/README.md`.

## Browser regression command

Pass each test file separately. On the pinned Flutter toolchain, passing the
directory `test/admin` to the Chrome runner can generate an invalid joined path.

```powershell
flutter precache --web
flutter test --platform chrome test/admin/admin_web_test.dart
flutter test --platform chrome test/admin/pr25_integration_test.dart
```
