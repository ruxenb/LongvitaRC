# Flow 2 — Ingredients and Shopping Final UI (09/11/2026)

Baseline: main `8d52a6e` (after NC-01…05 / PR #24). Local branch: `feature/charlie-flow2-final-ui`.

**Current status, native follow-up 09/11:** Charlie approved the visual direction and requested implementation in the actual app. Both production screens have now been exercised on Android with real Firestore plan data. Full suite465/465, analyzer clean, Final APK built. This supersedes the original widget-only snapshot at78efa5d. Not pushed or merged yet.

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

- Initial targeted Flow 2 + existing Hoang UI/ViewModel tests: **31/31 pass**; native follow-up adds one category-alias case included in the final full suite.
- Entire Flutter suite: **465/465 pass** (453 baseline + 12 new tests).
- Analyzer lib/test: clean. Default Final debug APK: built. Dependency lockfile unchanged.
- New tests cover both screens at 360/412 dp × text1/2; real bundled fonts; heading levels; edit identity and checked semantics; hit areas; edit → create → tick → Back; delete/Undo; read failure/empty; save failure/inline retry; long Vietnamese text/unknown categories; Nutrition/Profile navigation.
- Existing Hoang UI test updates only use visible Final titles in place of S07/S08 debug titles; layout/error assertions are retained. No hidden test-only labels were added.

`final/actual/` was refreshed from the final full-suite run and contains eight actual Flutter widget renders and their viewport metadata. These use real application screens/theme and fake test data/services. They are **not Android screenshots, actual Google sign-in or new production Firestore sync evidence**. Visual inspection compared both 360×800 normal-font renders with the Figma screenshots, and checked expanded text at both widths. No automated pixel-difference score is claimed.

The first test iterations caught harness issues (a floating snackbar covering a target, an undisposed Semantics handle, and tester.pageBack expecting a stock BackButton). The tests now dismiss the snackbar with a gesture, dispose the handle, and tap the real custom Back action. An invalid const on Semantics was also corrected before the final checks. Original local logs are kept in ignored QA storage; final checks have no missed-tap warnings.

## Initial scope boundaries (before native follow-up)

No changes to Auth, FCM, PDF/metadata flow, Firebase rules, billing, production recipes/plans or SDK versions. No new native/device/TalkBack/production Firestore run in this UI package; backend deployment and the prior NC-05 note about live shopping-list rules remain separate from this visual review. APK retains the known plugin Kotlin/Java deprecation warnings; it built successfully.

Initial status at78efa5d was Ready for Charlie visual review. Charlie then approved the direction and requested real-app integration; see native follow-up below. Internal task/progress documents remain local.


## Native follow-up — real app / Firestore (09/11)

Actual path: Home → Plan → open an existing saved plan → Tổng hợp nguyên liệu → Ingredients → Create Shopping List → Shopping list. The implementation modifies production screens, not a preview/QA-only route.

### Existing deployment gap found and resolved

On the real APK, loading Ingredients initially failed with permission-denied. A read-only comparison showed the live Firestore ruleset lacked shopping_lists, while the canonical repo already contained that owner-only block. Prepared a candidate by adding only that existing block to the fresh live source; removing the addition reproduces the original live source exactly. Candidate matches canonical repo; report_exports and all other permissions remained unchanged.

Exact candidate passed64/64 Firebase rules tests (50Firestore +14Storage) and22/22 Hoang rules checks, including foreign/anonymous access denial. CLI script exited0. Storage Emulator logged a tooling NPE during shutdown after completed tests; this is retained in private raw logs and is not counted as a test failure or hidden.

Fresh release/source and candidate-hash guards ran immediately before deploy. Deployed only firestore:rules to longvita-8da7e, then independently read the release source and matched the tested candidate. New ruleset d808e252-7484-459b-b504-81ff052f64e9; previous a6f43839-e28e-410c-bb62-0f2e64137cee and rollback source retained privately. No billing, Storage bucket/rules, IAM, Auth or unrelated collection deployment. The publicly recorded deployed source is in deployed-firestore.rules.

### Final UI refinements from real data

Added display aliases for actual categories rau/dầu/phô mai → Vegetables/Nuts and oils/Dairy. Existing source category strings are not rewritten. Name and quantity in each Ingredient row now share one Semantics label, while Edit retains its ingredient-specific button label. A regression checks real-data category aliases and preservation of raw values; a Semantics assertion checks the combined name/quantity.

### Native observations

AVD LocalMate_API_35, Android15,320×640; normal Final APK with existing real Firebase/Google session and an existing QA saved plan. Seven actual aggregated ingredients (not the six design fixtures) rendered correctly. Opened/canceled Edit on native Android, navigated to Shopping, checked an item and independently read true on the Firestore server. Installed final APK over the app without clearing data; the checked state survived. Then restored the original unchecked state, independently read false on the same document, and checked Back to Ingredients and Home. The app created/retained one owner-scoped QA checklist; no recipe/meal_plan/PDF data was changed or deleted.

Native files in native/: permission-denied baseline01, final Ingredients05, Edit06, Shopping checked07, restored08, Back09. Images contain no user email, UID, plan ID or tokens. Raw UI XML, server document readback and command logs remain ignored/private. The first collection-group read with ordering required an index; a read-only bounded query without ordering and local sorting was used instead. No index was created.

Current source matches the final APK/source hashes in verification.json. Final full suite465/465, analyzer lib/test clean, APK debug built. Earlier UI/widget checks and native observations are distinguished by source/stage. No new physical-device or TalkBack speech test is claimed; quantity-save/delete/Undo failure cases remain widget/ViewModel tests. Owned AVD and rules emulators stopped after returning Home; session preserved.
