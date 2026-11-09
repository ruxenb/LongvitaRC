# Flow 2 — Ingredients and Shopping Final UI (09/11/2026)

Baseline: main `8d52a6e` (after NC-01…05 / PR #24). Local branch: `feature/charlie-flow2-final-ui`.

## Reference and scope

- [S07 Ingredient Summary](https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=106-189)
- [S08 Shopping List](https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=106-235)
- Read both high-fidelity design contexts and screenshots on 09/11. Reference viewport 360×800. Code Connect returned no mappings.
- Charlie confirmed Figma is a sample: retain the visual language and main structure, with room for practical improvements in code. No Figma write or sync was performed.

## Implementation

Scoped to shopping_flow_screens.dart: canvas background, shared AppTopBar, Fraunces/Newsreader/Quicksand, 26/34 headings, flat category groups, 64-min ingredient rows, 48-min Edit actions, arrow CTA and shared AppCheckboxRow. S08 uses the Nutrition-selected AppNavigationBar; Home pops to root, Plan opens SavedPlans, Profile uses the existing named route, Nutrition does not stack itself.

Category aliases map existing Vietnamese/English category labels for display only. Unknown labels and actual names/quantities are preserved. No production sample ingredients, guessed food categories, model/schema or ViewModel changes. The sample six ingredients exist only in the test fixture.

Editing retains positive/finite validation and decimal-comma input. Delete moved into the edit dialog; Undo restores the original item/category/position. Checkbox taps use the whole row and retain persistence/analytics. Loading, empty, read error/retry, persistence error/retry and unsaved-plan guidance remain available. Quantity editing, deletion and checklist persistence still use the existing ViewModel APIs.

English headings/actions follow Final UI, while existing Vietnamese feedback and ingredient source text are retained. At large text scales, content wraps/grows and scrolls instead of clipping to the sample's fixed row heights.

## Verification

- Targeted Flow 2 + existing Hoang UI/ViewModel tests: **31/31 pass**.
- Entire Flutter suite: **464/464 pass** (453 baseline + 11 new tests).
- Analyzer lib/test: clean. Default Final debug APK: built. Dependency lockfile unchanged.
- New tests cover both screens at 360/412 dp × text1/2; real bundled fonts; heading levels; edit identity and checked semantics; hit areas; edit → create → tick → Back; delete/Undo; read failure/empty; save failure/inline retry; long Vietnamese text/unknown categories; Nutrition/Profile navigation.
- Existing Hoang UI test updates only use visible Final titles in place of S07/S08 debug titles; layout/error assertions are retained. No hidden test-only labels were added.

`final/actual/` contains eight actual Flutter widget renders and their viewport metadata. These use real application screens/theme and fake test data/services. They are **not Android screenshots, actual Google sign-in or new production Firestore sync evidence**. Visual inspection compared both 360×800 normal-font renders with the Figma screenshots, and checked expanded text at both widths. No automated pixel-difference score is claimed.

The first test iterations caught harness issues (a floating snackbar covering a target, an undisposed Semantics handle, and tester.pageBack expecting a stock BackButton). The tests now dismiss the snackbar with a gesture, dispose the handle, and tap the real custom Back action. An invalid const on Semantics was also corrected before the final checks. Original local logs are kept in ignored QA storage; final checks have no missed-tap warnings.

## Boundaries

No changes to Auth, FCM, PDF/metadata flow, Firebase rules, billing, production recipes/plans or SDK versions. No new native/device/TalkBack/production Firestore run in this UI package; backend deployment and the prior NC-05 note about live shopping-list rules remain separate from this visual review. APK retains the known plugin Kotlin/Java deprecation warnings; it built successfully.

Ready for Charlie visual review; not marked accepted/100%, not pushed or merged by this package. Internal task/progress documents remain local.
