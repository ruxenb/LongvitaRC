# Hoàng — Accessibility, Responsive and Design Audit

Date: 2026-11-04 | Tasks: S4-8, S4-16, S4-17

## Follow-up — 2026-11-08 (Hoàng S4-8/S4-16/S4-17)

- On main `4f3fd07` (including PR #19), the full Flutter baseline had zero analyzer issues and 388/388 passing tests. The new Hoàng accessibility/hero-image changes passed 390/390 tests with zero analyzer issues before the additional HTTPS-only regression assertion.
- `FlowFrame` now gives its screen title Android heading level 1; `FlowSection` gives section titles level 2. The regression checks actual semantics data rather than relying on a widget type alone. Flutter's empty route wrapper can still carry an unlevelled header; it is not the labelled screen title.
- All loading messages in Hoàng's MealPlan/Ingredient ViewModels and the reusable loading fallback use the single Unicode ellipsis `…` so TalkBack is not asked to speak three ASCII periods.
- S05 renders only the Firestore-provided HTTPS image URL in a responsive 328:126 hero area; absent, invalid or failed images show a text placeholder. No stock photo, unlicensed asset or fabricated source is added.
- 360dp/412dp, 1x/2x Flutter widget tests cover the S05 placeholder, basic responsive screens, and quantity validation. Android native TalkBack traversal, real Firestore images, visual pixel fidelity, contrast and font-size measurements still require on-device evidence and team acceptance.

## Automated verification
- Flutter analyze passed after implementation checkpoint.
- Widget test file test/flows/hoang_a11y_widgets_test.dart: six tests passed.
- Width 360dp and 412dp, text scales 1x and 2x: S04/S07/S08/S05 rendered with no layout overflow exception.
- S02 rejected missing age and weight; S07 dialog rejected -50 and accepted 150.
- FlowFrame provides SafeArea, scrollable column and max-width layout. AppButton has 52dp minimum; list items aim at least 56dp.

## Not yet verified on device
- Real TalkBack focus order, heading levels, voice announcements, keyboard traversal.
- WCAG-AA contrast for all text and focus controls, including disabled/secondary states.
- Every label >=14sp; typography and bottom-navigation labels still need audit.
- Real emulator screenshots, landscape and heavy text scaling.
- Verification against actual Figma Page 03 and 06.

The team decision recorded in docs/design-traceability.md on 2026-11-02 freezes Lab 2 Figma and asks for code-side improvements and deviation logs. Therefore no Figma file was edited without team approval. A read-only Page 03/06 structural audit is recorded in docs/hoang-figma-deviation-audit.md, with source node IDs and outstanding fidelity gaps.

## Traceability
| Screen | Implemented Flutter screen | User-flow and deviation notes |
|---|---|---|
| S01 | HomeScreen | Four-tab navigation, entry to preferences, saved plans, recipe search; no hardcoded generate action |
| S02 | PreferencesScreen | Enter actual age, weight, meals/day, eating window; validation |
| S03 | CreatePlanScreen | Explicit Loading/Empty/Error and Retry/Back |
| S04 | WeeklyPlanScreen | Seven-day accordion, saving and saved-plans navigation |
| S05 | RecipeDetailsScreen | Nutrition, ingredients, steps and Firestore sourceNote |
| S06 | MealAlternativesScreen | Data-backed selection and error recovery; no alternative routes to S02 |
| S07 | IngredientSummaryScreen | Edit overlay, positive validation, delete/Undo, empty state |
| S08 | ShoppingListScreen | Firestore shopping checkbox persistence per user and saved plan |
| S09 | BookKnowledgeScreen | Stored source metadata only; never fabricate page numbers |
| S10 | SavedPlansScreen | Live Firestore plans, loading, error, retry, open existing |
| AUTH/PROF | SignInScreen/ProfileScreen | Scope belongs to Charlie; not redesigned here |

## Manual QA checklist for team
- [ ] Screenshots at 360dp and 412dp for all S01–S10 with actual signed-in data
- [ ] Measure contrast >=4.5:1 for body text, >=3:1 for large text
- [ ] Verify tap targets >=48dp and labels >=14sp where rubric requires
- [ ] Check real TalkBack announcements, focus order and action labels
- [ ] Check lost network/retry and session switch on real Android
- [ ] Compare screenshots with frozen Figma source and approve recorded deviations

No screenshots or manual TalkBack runs are claimed at this checkpoint.
