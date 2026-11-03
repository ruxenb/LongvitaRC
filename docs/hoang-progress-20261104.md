# Hoàng: 26-task implementation and acceptance matrix

Updated 2026-11-04. Branch feature/hoang-flows-data-a11y-20261104.
This is a technical evidence matrix, NOT the formal Accepted status in the team-owned master task tracker. Main task IDs and owners remain unchanged.

| ID | Evidence/status | Outstanding acceptance |
|---|---|---|
| S0-3-HD | Flutter/Dart, FlutterFire, ADB and Android CLI installed D: | Local Debug SHA-1/256 obtained; checked-in Android OAuth SHA-1 mismatch (see docs/hoang-android-sha.md); Android SDK licences, Firebase registration and native device still pending |
| S1-2 | docs/hoang-firestore-schema.md; Firestore service and new checklist schema | Schema approval, reviewed Firestore data, rules deployment |
| S1-5 | Sign-in/Profile screens exist in Charlie's scope; Figma baseline mapped | Editing Figma frozen per team decision 02/11, no proof of page update |
| S4-1 | DataService, IDataService, DataFailure, existing models | Firestore Emulator 22/22 passed in test/firestore/hoang_rules.test.cjs; live Firebase/rules deployment still pending |
| S4-2 | MealPlanViewModel, IngredientViewModel, ViewState variants | Real-device acceptance and reviewer approval |
| S4-3 | MealPlanViewModel.reportablePlan exposes immutable model | Charlie PDF flow integration acceptance |
| S4-4 | S01-S04/S10 screens, save and retry states | ARTEMIS TC02-TC04 live |
| S4-5 | S07/S08, edit >0, Undo, checklist persistence | Real Firestore and Android persistence |
| S4-6 | S05/S06/S09, substitutions and non-destructive failed save | Real E2E including actual alternatives |
| S4-7 | FlowStateView, DataFailure, Home stream error/empty | Offline Android test and UX sign-off |
| S4-8 | Labels and action names in new widgets/screens | TalkBack native traversal |
| S4-9 | Fake-backed ViewModel unit tests + isolation regression | Full suite 305/305 passed after PR10 CodeRabbit fixes |
| S4-16 | 360/412dp x 1x/2x widget tests pass | Contrast and 14sp measurement; native screenshots |
| S4-17 | docs/hoang-accessibility-audit.md, mapping & deviations | Page 03/06 metadata audited in docs/hoang-figma-deviation-audit.md; native screenshot comparison and team acceptance still required |
| S5-3 | Search/details/replace/shopping/generated events in UI/VM | Firebase DebugView verified event parameters, no PII |
| S6-5 | e2e_test/test_flows.py, test_search.py written | Run with ARTEMIS daemon and signed-in device |
| S6-6 | e2e_test/test_detail.py written | Run with ARTEMIS and native evidence |
| S6-13 | HOANG-F01 and HOANG-F02 implementation fixes | Further ARTEMIS-discovered issues pending |
| S7-1-HD | Branch + commits 0dc6253, d078f89 | PR #10 opened, CodeRabbit returned 4 actionable findings; 4 fixes implemented, follow-up review pending |
| S7-2-HD | Two manual code findings documented | Three manual findings F01/F02/F03 plus 4 real CodeRabbit comments documented; follow-up review pending |
| S7-3-HD | HOANG-F02 and HOANG-F03 have separate fix commits d078f89 and 3c80cb2 | Reviewer acceptance and PR link |
| S8-2 | report/hoang-implementation-report.md | Real screenshots for submission |
| S8-6 | slides/Longvita_Hoang_4_Slides_20261104.pptx | Slide visual review, native screenshots |
| S8-11 | Planned demo storyboard | Android video, actually record 3 flows/error branches |
| S8-17-HD | docs/worklog-hoang.md | Include PR, external review and final evidence |
| S9-5-HD | Viva checklist to be prepared | Live test, Remote Config edit, oral defence session |

## Do not overclaim
- Flutter widget/unit tests are not ARTEMIS device tests.
- Scripts are not successful ARTEMIS runs.
- A source file containing Firestore rules is not a deployed Firestore rule set.
- A screen implementation is not proof of Figma visual fidelity.
- No APK or signed-in demo video was produced at the first checkpoint.
- No other team member's statuses should be changed without their approval.

## Work references
Base main revision 96c9f573bc29c2bbd4c9c07e6c2d98a777c29d14.
Feature code checkpoint 0dc6253; targeted session fix d078f89.
See docs/worklog-hoang.md, docs/hoang-firestore-schema.md and docs/hoang-accessibility-audit.md.
