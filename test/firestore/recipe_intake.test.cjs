'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const { validate, fingerprint } = require('../../scripts/validate-recipe-intake.cjs');

// All records here are SYNTHETIC TEST FIXTURES, never authorized food data.
function fixture() {
  const result = {
    projectId: 'longvita-8da7e',
    collection: 'recipes',
    recipes: [{
      id: 'synthetic-test-01',
      firestore: {
        name: 'SYNTHETIC TEST RECIPE — DO NOT IMPORT',
        description: 'Test fixture, not a real meal.',
        category: 'dau',
        proteinGrams: 5,
        calories: 100,
        ingredients: [{
          id: 'test-ingredient-01',
          name: 'SYNTHETIC INGREDIENT',
          amount: 100,
          unit: 'g',
          category: 'đậu',
          isPurchased: false,
        }],
        instructions: ['TEST ONLY; never use as a recipe.'],
        imageUrl: null,
        sourceNote: 'SYNTHETIC TEST PROVENANCE — DO NOT USE',
      },
      provenance: {
        recipeSource: {
          type: 'team-original',
          title: 'SYNTHETIC TEST PROVENANCE — DO NOT USE',
          locator: 'test-only',
          rightsEvidence: 'Synthetic fixture only; not permission to publish.',
        },
        nutrition: {
          servings: 1,
          entries: [{
            ingredientId: 'test-ingredient-01',
            foodCode: 'TEST-ONLY',
            sourceName: 'Synthetic fixture',
            sourceUrl: 'https://example.com/test-not-real',
            preparationState: 'uncooked test placeholder',
            edibleGrams: 100,
            kcalPer100g: 100,
            proteinPer100g: 5,
          }],
        },
      },
    }],
  };
  result.approval = {
    decision: 'approved',
    approvedBy: 'SYNTHETIC TEST REVIEWER',
    approvedAt: '2026-11-06T00:00:00Z',
    evidenceUrl: 'https://example.com/test-approval-not-real',
    recipesSha256: fingerprint(result.recipes),
  };
  return result;
}

test('accept internally consistent shape and math for a synthetic test-only fixture', () => {
  assert.deepEqual(validate(fixture()), []);
});

test('reject missing human batch approval', () => {
  const batch = fixture();
  delete batch.approval;
  assert.match(validate(batch).join('\n'), /approval/);
  assert.deepEqual(validate(batch, false), []);
});

test('reject modified batch after fingerprint approval', () => {
  const batch = fixture();
  batch.recipes[0].firestore.name = 'Changed after review';
  assert.match(validate(batch).join('\n'), /fingerprint/);
});

test('reject wrong nutrient values and impossible ingredient amount', () => {
  const batch = fixture();
  batch.recipes[0].firestore.calories = 300;
  batch.recipes[0].firestore.ingredients[0].amount = -5;
  const errors = validate(batch, false).join('\n');
  assert.match(errors, /expected ~100\.00/);
  assert.match(errors, /positive quantity/);
});

test('reject unverified source, extra Firestore fields and invented category', () => {
  const batch = fixture();
  batch.recipes[0].firestore.sourceNote = '';
  batch.recipes[0].firestore.extraField = 'no';
  batch.recipes[0].firestore.category = 'other';
  const errors = validate(batch, false).join('\n');
  assert.match(errors, /sourceNote/);
  assert.match(errors, /extraField/);
  assert.match(errors, /unknown category/);
});

test('reject incomplete nutrient provenance and conversion for quantity unit', () => {
  const batch = fixture();
  batch.recipes[0].firestore.ingredients[0].unit = 'quả';
  batch.recipes[0].provenance.nutrition.entries[0].sourceUrl = '';
  const errors = validate(batch, false).join('\n');
  assert.match(errors, /sourceUrl/);
  assert.match(errors, /conversionNote/);
});

test('reject duplicate recipe IDs and names', () => {
  const batch = fixture();
  batch.recipes.push(JSON.parse(JSON.stringify(batch.recipes[0])));
  assert.match(validate(batch, false).join('\n'), /duplicate ID/);
  assert.match(validate(batch, false).join('\n'), /duplicate name/);
});
