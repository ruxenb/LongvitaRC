# TV-03B — Web Analytics and Remote Config, 10/11/2026

## Delivered code

- Added Remote Config boolean `web_show_review_guidance` to both SDK in-app
  defaults and `firebase/remote-config-defaults.json`.
- Web startup initializes/fetches Remote Config. Review Queue visibly renders
  the guidance card when the flag is true and can fetch/activate again from the
  sync action without a rebuild.
- Successful approve/reject writes emit `approve_plan` or `reject_plan` with
  only `surface = web_admin`. A failed write emits neither success event.
- Added `publish_announcement` to the shared Analytics service and
  `AdminWebInstrumentation`. The CM-07 announcement form must invoke it only
  after its Firestore write succeeds; no form or fake publish was added here.
- Sign-out continues through the Admin auth gateway, clearing the role cache.

## Local verification

- `flutter analyze lib test`: no issues.
- `flutter test test/admin test/analytics/analytics_service_test.dart`: 23/23
  passed.
- Tests assert the exact three Web event names, the non-PII parameter map, the
  visible Remote Config UI, successful review tracking, and no event after a
  failed review.

## Acceptance still requiring Firebase Console

- Publish `web_show_review_guidance` in Remote Config, toggle true/false and
  capture before/after screenshots on the deployed Web app.
- Trigger approve/reject against an authorized test project and capture the
  three Analytics names in DebugView. `publish_announcement` can only be
  captured after CM-07 supplies the real successful form action.
- No production Firestore write, Remote Config publish, Hosting deploy or
  DebugView claim was made by this local verification.
