# Hoàng — Firestore Schema & Mapping (S1-2, S4-1)

Date: 2026-11-04 | Firebase project: longvita-8da7e | App: vn.edu.fpt.longvita

## Architecture
Flutter screens -> ViewModels -> IDataService -> DataService -> Cloud Firestore.
Loading, empty, error and data are explicit ViewState variants. Never replace missing Firestore recipes with hard-coded demo meals.

## Documents
| Path | Data | Permissions |
|---|---|---|
| users/{uid} | email, displayName, photoUrl?, role=user/staff/admin, createdAt ISO string | owner read and initial role=user; staff/admin protected |
| recipes/{id} | name, description, category, proteinGrams, calories, ingredients[], instructions[], imageUrl?, sourceNote | authenticated read; staff/admin write |
| meal_plans/{id} | uid, title, targetCalories, targetProteinGrams, status, reviewerReason?, days[7], createdAt ISO string | owner drafts/submission; staff/admin review |
| shopping_lists/{uid}/plans/{planId} | uid, planId, updatedAt ISO string, items[] | owner-only (new rule, not yet deployed) |
| announcements/{id} | title, content, authorRole, createdAt ISO string | authenticated read; staff/admin publish |

The model MealPlanModel defaults to status=draft. Saved plans contain seven DailyMeal entries (dayIndex 0-6, dayName, meals with recipe snapshots). IngredientModel contains id, name, amount (>0), unit, category and isPurchased.

## Service contract
- getRecipes(category?): Firestore query; a zero-row response is a real empty state, not a request to generate demo recipes.
- getRecipeById(id): null if absent; translate Firebase permission/offline/invalid errors using DataFailure.
- getUserMealPlans(uid), streamUserMealPlans(uid): always filter by uid; currently sort client-side by createdAt for the small lab dataset.
- saveMealPlan(plan): create draft or update existing plan; Firestore rules enforce owner/status transitions. Creates use a deterministic doc ID from UID + creation timestamp to avoid duplicate documents if a queued offline write later synchronizes. Write futures are bounded to 15 seconds, but timing out does not cancel Firestore's queued operation.
- getShoppingItems(uid,planId): null if document absent; an existing document with empty items returns an empty list. This prevents regenerating a deliberately emptied shopping list.
- saveShoppingItems(uid,planId,items): per-user, per-plan persistence with serialised ViewModel writes and retryable errors.
- Analytics: operations from user actions only; do not invent a target meal window or clinical results.

## Security notes
- firebase/firestore.rules includes owner-only access for shopping lists and a max item count of 500. It checks top-level document shape, not every individual nested ingredient field. This requires additional rule tests/review.
- Rules have NOT been deployed to the shared Firebase project. Deployment requires team review.
- Recipe records and citations must be reviewed before being loaded to Firestore; no production data was seeded in this work.
- Data timestamps are ISO-8601 strings in current rules and models; changing to server timestamps requires coordinated migration.
- Nutrition recommendations are illustrative estimates; they do not substitute professional medical advice.

## Evidence and remaining tasks
Code: lib/services/data_service.dart, i_data_service.dart, data_failure.dart, lib/models, lib/viewmodels.
Automated fakes: test/flows/hoang_viewmodels_test.dart. Needs additional live Firestore/Emulator checks and a valid signed-in test account.
