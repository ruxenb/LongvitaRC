# LongvitaRC — Field-level recipe crosswalk from Valter Longo to USDA (2026-11-06)

**Prepared by:** Hoàng's data implementation workflow. **STATUS:** technically checked, **NOT approved for shared Firestore**. Project `longvita-8da7e`, collection `recipes`.

## Evidence and copyright boundaries

- Vietnamese book identity: Valter Longo, *Chế độ ăn trường thọ*, translated by Nguyễn Khánh Chi, Appendix A begins Vietnamese p.238 per library catalog: https://thuvienmcbc.org/index.php/thuvien/catalog_product/view/id/5771/ .
- The two **modeled main meals** below are based on the **official 2020-04-20 Foundation sample menus**, **not exact recipes transcribed from the Vietnamese Appendix A**: https://www.fondazionevalterlongo.org/en/sample-longevity-diets/ .
- The third candidate is on the author's officially published **Recipes of Longevity** webpage, **not confirmed in Appendix A**: https://valterlongo.com/recipes-of-longevity/ .
- Calculations use **USDA FoodData Central SR Legacy (April 2018), nutrient IDs 1008 (kcal) and 1003 (protein)**. Read directly from the USDA JSON API at `https://api.nal.usda.gov/fdc/v1/food/{id}?api_key=DEMO_KEY` on 2026-11-06. USDA terms: https://fdc.nal.usda.gov/api-guide/ .
- Public USDA data are CC0; this **does not** authorize reproducing copyrighted book pages, original cooking directions or web photographs. Cooking steps in the staged file are short independent instructions, not pasted text; team permission/rights review is still necessary.

## Draft A — Farro/spelt, lentils, sesame, olive oil

Source: lunch for a **70-year-old person prone to losing lean mass** (not a universal diet); the Foundation specifies **70 g farro/spelt, 9 g extra-virgin olive oil, 50 g dry lentils, 15 g sesame** and **a 200 g fennel-and-salad side**. Since the latter is not separated by ingredient weight, the staged recipe represents **only the four-ingredient main component**, NOT the whole lunch.

| Ingredient | Model g | Source USDA FDC | Energy kcal/100g | Protein g/100g | kcal contribution | Protein contribution (g) |
|---|---:|---|---:|---:|---:|---:|
| Spelt **assumed dry** | 70 | `169745` Spelt, uncooked | 338 | 14.57 | 236.60 | 10.1990 |
| Lentils **dry** | 50 | `172420` Lentils, raw | 352 | 24.63 | 176.00 | 12.3150 |
| Sesame, whole dried | 15 | `170150` Sesame seeds, whole dried | 573 | 17.73 | 85.95 | 2.6595 |
| Olive oil | 9 | `171413` Olive oil, salad/cooking | 884 | 0 | 79.56 | 0 |
| **Modeled one-serving subtotal** | **144** | | | | **578.11** | **25.1735** |

**Classification:** current `RecipeModel.category='ngu_coc'` (primary ingredient spelt). **Source type:** `[web]`; `imageUrl=null`. Each `IngredientModel` has `id,name,amount,unit,category,isPurchased=false`. **Open blockers:** farro weighed raw/dry is not explicit in Foundation text; side salad excluded; nut/seed and gluten allergy considerations; no reproduction rights and team sign-off yet. Do not represent this as the **full diet lunch** or laboratory-accurate cooked nutrition.

## Draft B — Salmon, whole-wheat bread, cauliflower, olive oil

Source: adult man with obesity, Foundation sample dinner **150 g fresh salmon, 5 g olive oil after cooking, 70 g whole-wheat bread, 200 g cauliflower**. That meal **also includes seasonal fruit 150 g and 10 g nuts/dried fruit**, neither specified as an exact variety; excluded from the model subtotal.

| Ingredient | Model g | Source USDA FDC | Energy kcal/100g | Protein g/100g | kcal contribution | Protein contribution (g) |
|---|---:|---|---:|---:|---:|---:|
| Salmon, **assumed raw farmed Atlantic** | 150 | `175167` Salmon, Atlantic, farmed, raw | 208 | 20.42 | 312.00 | 30.6300 |
| Whole-wheat commercial bread | 70 | `172688` Bread, whole-wheat | 252 | 12.45 | 176.40 | 8.7150 |
| Cauliflower, **assumed weighed raw** | 200 | `169986` Cauliflower, raw | 25 | 1.92 | 50.00 | 3.8400 |
| Olive oil | 5 | `171413` Olive oil | 884 | 0 | 44.20 | 0 |
| **Modeled one-serving subtotal** | **425** | | | | **582.60** | **43.1850** |

**Classification:** `category='ca'`, `sourceNote` explicitly prefixed `[web]`. **Open blockers:** Foundation says generic *fresh salmon* (not Atlantic-farmed); raw/steamed cauliflower weights differ, cooking loss not evaluated, bread brand variation; excluded dessert; fish/wheat allergen review and team sign-off required.

## Third candidate — Chocolate Almond Delights (NOT importable with current category enum)

The author's site specifies **500 g shelled almonds, 500 g dark chocolate, 20 portions**. USDA FDC `170567` almonds: 579 kcal/21.15 g protein per 100g; USDA FDC `170273` chocolate **70–85% cacao**: 598 kcal/7.79 g protein per 100g. Under the **explicit 70–85% cacao assumption**, one 50g portion has **294.25 kcal and 7.235 g protein**. This is *the exact arithmetic output for the selected database records*, NOT a measurement or authoritative nutrient claim for the unspecified chocolate in the author recipe. Chocolate variety, actual roasting yield, and reuse rights remain unresolved; category enum `ca/dau/rau_cu/ngu_coc` does not allow an honest dessert classification. **Not a `recipes/{id}` payload.**

## Actual deliverable and validation

The local source-controlled file `docs/hoang-staged-usda-recipes-20261106.json` contains:
- Two **complete, syntactically shaped** draft Firestore records with field-level provenance outside `firestore` and all source URLs.
- The two draft records' `reviewBlockers` arrays identifying assumptions, omissions and team/legal signoffs.
- One other candidate without a `firestore` object due to category/source ambiguity.
- Explicit `approval: null` and `publicationAuthorized: false`.

```powershell
node scripts/validate-recipe-intake.cjs --review docs/hoang-staged-usda-recipes-20261106.json
# PASS: arithmetic and model checks only
node scripts/validate-recipe-intake.cjs --verify docs/hoang-staged-usda-recipes-20261106.json
# EXPECTED FAIL: review blockers unresolved + no team approval
node --test test/firestore/recipe_intake.test.cjs test/firestore/recipe_research_ledger.test.cjs test/firestore/recipe_staged_usda.test.cjs
```

**Source integrity correction:** Existing `lib/screens/recipe_flow_screens.dart` treated **every nonempty sourceNote as a book citation**. The current PR changes analytics to flag only explicit `[book] `-prefixed verified citations. Website citations use `[web]`; unknown older notes are not automatically attributed to the book. This is an interim convention within the current string schema, **not external proof** that a purported book reference is authentic.

## Publication decision — independent team authority required

As of the latest read of https://github.com/ruxenb/LongvitaRC/issues/16 , **no reply from the project owner or authorized teammate granting permission to publish any batch** was present; the existing comments were the data researcher's own research updates. Project membership and registered Firebase SHA fingerprints are **technical access, not content approval**.

For client Flutter writes, current `firebase/firestore.rules` specifies `users/{uid}.role in ['staff','admin']` to write `recipes` (assuming those rules are actually deployed). IAM-authenticated server writes are a **different channel**, governed by Google Cloud IAM and capable of bypassing mobile/web Security Rules: https://firebase.google.com/docs/firestore/solutions/role-based-access . Never infer permission from the console invite alone.

No Firebase production query, insert, update, delete, rules deployment, or service-account impersonation was performed. Before an import, obtain: (1) nutrition reviewer confirmation on state/assumptions and full meal vs component, (2) legal/provenance approval for independently written text, (3) authorized team owner's explicit approval of the exact batch SHA and writer/role/rollback plan, (4) an emulator or staging rehearsal with a readback and no collisions.
