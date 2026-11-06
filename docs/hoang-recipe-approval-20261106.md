# Hoàng — Recipe data intake, evidence and approval gate (2026-11-06)

**Scope:** `ruxenb/LongvitaRC`, Firebase project `longvita-8da7e`, app `vn.edu.fpt.longvita`, collection `recipes`. Owner for implementation/data: Hoàng. This is **not** a dataset, approval, or permission to write production data.

## Current verified status

- Screenshot shared by the project collaborator on 2026-11-06 shows the **ASUS debug SHA-1 and SHA-256** already registered in Firebase Console, alongside other team certificates. Do not add duplicates or remove others. Whether `android/app/google-services.json` is refreshed and a signed-in app is tested is a separate check.
- An invitation to collaborate on Firebase does **not** constitute approval to alter a shared Firestore collection. The project/team owner must explicitly approve a particular recipe batch and its writer/role.
- No team-approved, source-audited recipe catalog or permission to publish one was found in the checked repository, earlier `ruxenb/longvita` UX repository, the local project directories, or the available related Drive/mail sources. **This is not evidence that production Firestore is empty** (no production collection read was performed).
- Existing app reads `recipes` from Firestore; it must show Empty/Error rather than silently substitute mock meals. `firebase/firestore.rules` allows authenticated reads, and writes only from a user whose `users/{uid}.role` is `staff` or `admin`, assuming those same rules are deployed. Project-console access is different from app Firestore role.
- The team-controlled formal 26-task tracker stays unchanged pending acceptance.

## Source hierarchy — candidate references, NOT approved recipes

| Purpose | Candidate authoritative source | How to record evidence |
|---|---|---|
| Recipe instructions | Official Valter Longo Foundation recipe index: https://www.fondazionevalterlongo.org/en/longevity-recipes/ | Exact recipe page URL; origin, author, portions, exact quantities; check reproduction/adaptation rights. A reference does not itself authorize copying full instructions. |
| Book concepts/attribution | Valter Longo author page: https://valterlongo.com/the-longevity-diet/ | Real bibliographic edition and **verified page** for a specific recipe; don't infer Appendix/page or say 'from book' merely because the diet is inspired by it. |
| Local food composition | National Institute of Nutrition Vietnam lookup: https://viendinhduong.vn/vi/cong-cu-va-tien-ich/gia-tri-dinh-duong-thuc-pham | Exact ingredient code, raw/cooked form, source, 100g edible portion, kcal and grams protein. |
| Supplemental food composition | USDA FoodData Central: https://fdc.nal.usda.gov/ and https://fdc.nal.usda.gov/api-guide/ | FDC ID, data type, dataset release, source URL, raw/cooked form, calories and protein per 100g. USDA data are CC0, but that does not license a separate recipe text/image. |

**No recipes, instructions, citations, nutrient figures or pictures are permitted to be invented, auto-generated as production content, or copied wholesale from restricted books.**

## Exact current Firestore payload (`lib/models/recipe_model.dart`)

| Field | Contract and review needed |
|---|---|
| Document ID | Stable unique string, safe path segment, chosen by data owner |
| `name` | Verified dish name, no speculative endorsement |
| `description` | Accurate independently written summary of the actual reviewed preparation |
| `category` | App-supported identifier `ca`, `dau`, `rau_cu` or `ngu_coc`; reviewer must decide appropriate category |
| `proteinGrams` | **g / one serving**, computed from traceable ingredient masses and nutrient sources |
| `calories` | **kcal / one serving**, same standardized portion as protein |
| `ingredients[]` | One row per ingredient: `id`, `name`, `amount` (>0), `unit`, `category`, `isPurchased: false`; match original recipe amounts and record gram conversions separately |
| `instructions[]` | Nonempty reviewed cooking steps with permission to reproduce/adapt |
| `imageUrl` | HTTPS image with explicit usage rights, or `null` |
| `sourceNote` | Accurate verifiable public-facing citation. Never silently claim a book, edition, appendix or page. |

Firestore rules currently accept only the nine payload fields above. **Provenance and approval evidence belong in the offline intake artifact, not inside `recipes/{id}` without a coordinated schema/rules change.**

## Deterministic nutrition review

1. Record the recipe's total number of **servings** and each raw/cooked **edible mass in grams**. For `ml`, `quả`, `thìa` etc., attach a conversion rationale; never assume grams equal millilitres.
2. For each ingredient, locate its unique food code, source URL, preparation state and kcal/protein **per 100g edible portion**. Avoid mixing raw and cooked reference entries unintentionally.
3. Calculate per-serving kcal = sum(`edibleGrams × kcalPer100g / 100`) / `servings`, and per-serving protein (g) identically using `proteinPer100g`. Record rounding and changes from cooking losses or nutrition methodology for manual review. This is an estimate from composition data, not a laboratory measurement of the finished dish.
4. Independently check the source text, measurements, scope, permission to reuse, potential allergens and ingredient suitability; the current Flutter model does not implement allergy filtering, so do **not** claim medical suitability.

## Offline intake and verification — no Firebase writes

Create a **private/staged** JSON file only from approved, evidence-backed recipes, not an invented demonstration catalog:

```json
{
  "projectId": "longvita-8da7e",
  "collection": "recipes",
  "recipes": [
    {
      "id": "<real-reviewed-document-id>",
      "firestore": {
        "name": "<reviewed-name>",
        "description": "<reviewed-description>",
        "category": "<ca|dau|rau_cu|ngu_coc>",
        "proteinGrams": null,
        "calories": null,
        "ingredients": [],
        "instructions": [],
        "imageUrl": null,
        "sourceNote": "<verified-citation>"
      },
      "provenance": {
        "recipeSource": {
          "type": "<book|official-recipe|team-original|licensed>",
          "title": "<exact-title>",
          "locator": "<page-or-section>",
          "rightsEvidence": "<rights-or-authorisation-reference>",
          "url": null
        },
        "nutrition": {
          "servings": null,
          "entries": [
            {
              "ingredientId": "<id-matching-ingredient>",
              "foodCode": "<national-table-or-FDC-id>",
              "sourceName": "<NIN-or-USDA-dataset>",
              "sourceUrl": "<full-source-URL>",
              "preparationState": "<raw-or-cooked>",
              "edibleGrams": null,
              "kcalPer100g": null,
              "proteinPer100g": null
            }
          ]
        }
      }
    }
  ],
  "approval": {
    "decision": "<not-yet-approved>",
    "approvedBy": "<team-reviewer>",
    "approvedAt": "<ISO-date-time>",
    "evidenceUrl": "<explicit-approval-comment-or-document-URL>",
    "recipesSha256": "<validator-output-after-review>"
  }
}
```

**All angle-bracket values and null nutrition values above are placeholders and MUST fail validation. They are not real meals and must never be imported.**

Run from repository root:

```powershell
node scripts/validate-recipe-intake.cjs --review D:\path\to\reviewed-catalog.json
# The reviewer approves the EXACT recipes SHA-256 shown by the command.
# Add the approval evidence + fingerprint to the manifest.
node scripts/validate-recipe-intake.cjs --verify D:\path\to\approved-catalog.json
node --test test/firestore/recipe_intake.test.cjs
```

The validator requires every current Firestore field, ingredient references, source metadata, nutrient quantity reconciliation, an approved batch and matching SHA fingerprint. It **does not** connect to, read or write Firestore, validate the truth of external sources, grant credentials, or confer publishing rights.

## Team approval request

Opened GitHub issue **#16** to request the verified recipe catalog, field-level sources, explicit rights/reuse confirmation and authorization to publish an exact batch to shared Firestore: https://github.com/ruxenb/LongvitaRC/issues/16 . **Issue creation is a request, not approval.**

## Required sign-offs before any shared Firebase change

| Gate | Reviewer evidence required | Current status |
|---|---|---|
| Recipe list/content | Exact signed-off IDs, names, quantities and instructions with permitted usage | **Not provided** |
| Provenance | Origin URL or real book edition/page, plus license/rights confirmation | **Not provided** |
| Nutrition | Ingredient food codes, edible weights, number of servings, 100g nutrient values and independent reviewer check | **Not provided** |
| Shared project write | Owner explicitly approves target project `longvita-8da7e`, `recipes` batch hash, writer account/role, permission scope and rollback plan | **Not provided** |
| Validation | Offline validator PASS, team review, staging/emulator test, production readback plan | **Pending actual recipes** |

**No production seed/import/deploy is authorized by this document.** Once all gates are signed off, prefer a reviewed, idempotent `recipes/{id}` import with preflight diff, backup and readback; refuse mismatched project IDs, modified hashes or unreviewed rows.
