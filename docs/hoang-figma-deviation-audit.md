# Hoàng — Read-only Figma-to-Flutter deviation audit (04/11/2026)

Figma source: https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=1-3
Read-only inspection: Page 03 Final UI (1:3) and Page 06 Prototype (1:6). All listed reference frames are 360x800.
The 02/11 team decision freezes Figma as the baseline. No Figma edit was performed.

This audit identifies actual screen/layout differences by source node ID; it is **not** a pixel-perfect visual comparison or an Android screenshot.

| Screen | Figma page 03 node | Actual Figma structure | Current Flutter deviation / acceptance risk |
|---|---|---|---|
| S01 | 103:5 | Profile label, featured meal card, 2 quick link tiles (Saved Plans/Shopping), nav | HomeScreen uses welcome card, buttons and announcements; no featured recipe image/card matching Figma |
| S02 | 103:83 | Under-65 / 65+ choice cards, 2 or 3 meals/day options, calculated target notice | PreferencesScreen uses numeric age/weight TextFormFields, 2–5 meals and a dropdown eating window; functional inputs but substantial visual/content differences |
| S03 | 103:125 | Standard 7-day / 3 meals / Plant-rich selections, protein and fish notes, Review & generate | CreatePlanScreen shows a compact summary + Generate. Original choice cards and explanation notes absent |
| S04 | 103:160 | Horizontal day selector, meal hero card, dinner row and daily note | WeeklyPlanScreen uses seven ExpansionTiles rather than the selected-day layout; visually and structurally different |
| S10 | 103:269 | Three styled saved-plan rows and empty guidance | SavedPlansScreen uses generic FlowItemCards fetched from Firestore (data correct but not Figma style) |
| S07 | 106:189 | Custom ingredient rows, each 48dp edit target, summary panel | IngredientSummaryScreen uses Material ListTiles with Edit and Delete icons; Undo works but visual placement differs |
| S08 | 106:235 | Custom shopping-row components | ShoppingListScreen uses default CheckboxListTile styling; persistence is data-backed |
| S05 | 108:244 | 328x126 recipe hero image, provenance row, ingredient cards and step-number badges | RecipeDetailsScreen is primarily text/list; recipe imageUrl exists in model but is not rendered; provenance shown as sourceNote |
| S06 | 108:285 | Alternative meal cards with source badges and visible 48dp selection target | MealAlternativesScreen uses RadioGroup/RadioListTiles, without Figma option-card image/metadata arrangement |
| S09 | 108:332 | Four knowledge principle cards (plant/protein/fats/fish) and Citation | BookKnowledgeScreen only shows recipe source metadata and disclaimer; the four content cards are not implemented |

## Error and recovery variants in Figma
- Page 03 Required States section 108:360 and Page 06 prototype explicitly include S03 Loading (108:363), S03 Generation Error (108:396), S04 Save Error (108:445), S06 No Alternatives (108:488), and S06 Update Error (108:532).
- Flutter has explicit equivalent state logic, but presentation is not pixel-identical. S03 Error offers Retry/Back rather than Figma Cancel-to-Home action.
- Page 06 prototype includes native navigation targets and user-route hotspots, including Home/Plan/Nutrition/Profile. Flutter's Home navigation uses AppNavigationBar; nested screens currently rely on Navigator back.

## Impact and recommendation
1. Data and recovery rules may qualify for the rubric's functional requirements; **visual fidelity cannot be claimed** until Flutter is aligned against Page 03/06 on actual rendered Android screenshots.
2. Highest fidelity gaps: S02 option cards, S03 selectable plan template, S04 day selector/meal hero, S05 recipe image, S09 principles.
3. Before modifying the frozen Figma source or changing design contracts, request team review of deviations. Prefer changing Flutter to match the baseline where practical; keep data-driven input and accessibility requirements.
4. No native screenshot, visual regression comparison or design approval was produced in this audit.

Source of evidence: Figma get_metadata read-only inspection on 2026-11-04, pages 1:3 and 1:6; code in lib/screens and docs/design-traceability.md.
