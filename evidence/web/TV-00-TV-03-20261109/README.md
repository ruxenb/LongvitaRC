# TV-00–TV-03 Web Admin verification — 09/11/2026

Scope: PR #25, branch `Web`, after synchronizing `main` at `3297ed6`.

## Verified results

- Flutter analyzer: 0 issues.
- Web Admin tests: 5/5 passed.
- Full Flutter suite: 483/483 passed.
- Web build: passed with `lib/admin_main.dart`; Wasm dry run also succeeded.
- Hosting output: `build/web`.
- Firestore deployment mapping: `firebase/firestore.rules` in `firebase.json`.

No Firebase deploy or production data write was made during this verification.
A live Hosting URL and incognito check remain separate TV-00 deployment evidence.

## Test coverage added

- Role gate: loading, denied, staff-authorized.
- Recipe management: create/save, metadata-preserving edit, archive.
- Review queue: approve and reject with a required reason.
- Dashboard: loading, empty, error and populated data.

## CodeRabbit decisions

- Accepted: preserve ingredient amount/unit/category/id and `imageUrl` on edit.
- Accepted: catch and display archive/restore and approve/reject failures.
- Accepted: remove invented meal/date/time/source/protein UI values and route
  Shopping to the ingredient flow.
- Modified: archived recipes remain visible in Web Admin so staff can restore
  them. Mobile filtering is already enforced by `DataService` from PR #27.
- Accepted: stale English widget-test assertion changed to the Vietnamese UI.
- Accepted: make the recipe table scroll vertically and horizontally, and pass
  its edit callback explicitly instead of searching for ancestor state.
- Accepted: select today's meal by Monday-based `dayIndex`, align weekly dates
  to the containing Monday, and connect Saved Plans/Shopping to their intended
  destinations.
- Accepted: carry the selected age group through plan creation and remove the
  invented numeric age from saved-plan titles.

## Commands

```powershell
flutter analyze
flutter test test/admin/admin_web_test.dart
flutter test
flutter build web --target lib/admin_main.dart
```
