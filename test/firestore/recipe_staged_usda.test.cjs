'use strict';

const assert = require('node:assert/strict');
const { test } = require('node:test');
const path = require('node:path');
const { validate } = require('../../scripts/validate-recipe-intake.cjs');
const staged = require(path.join(__dirname, '../../docs/hoang-staged-usda-recipes-20261106.json'));

test('two primary-source meal components pass structural and arithmetic review', () => {
  assert.equal(staged.recipes.length, 2);
  assert.deepEqual(validate(staged, false), []);
});

test('neither staged meal is certified for shared-Firebase publication', () => {
  assert.equal(staged.publicationAuthorized, false);
  assert.equal(staged.approval, null);
  for (const entry of staged.recipes) {
    assert.ok(entry.reviewBlockers.length > 0);
  }
  assert.match(validate(staged, true).join('\n'), /reviewBlockers/);
  assert.match(validate(staged, true).join('\n'), /approval/);
});

test('the exact mathematical model is traceable to primary USDA food records', () => {
  for (const item of staged.recipes) {
    const nutrition = item.provenance.nutrition;
    const calculated = nutrition.entries.reduce((sum, value) => ({
      calories: sum.calories + value.edibleGrams * value.kcalPer100g / 100,
      protein: sum.protein + value.edibleGrams * value.proteinPer100g / 100,
    }), { calories: 0, protein: 0 });
    assert.equal(nutrition.servings, 1);
    assert.ok(Math.abs(calculated.calories - item.firestore.calories) < 0.001);
    assert.ok(Math.abs(calculated.protein - item.firestore.proteinGrams) < 0.001);
    for (const entry of nutrition.entries) {
      assert.match(entry.foodCode, /^FDC:\d+$/);
      assert.match(entry.sourceUrl, /^https:\/\/api\.nal\.usda\.gov\/fdc\/v1\/food\/\d+/);
    }
  }
});

test('book and web provenance are distinguished, and no dessert is miscategorized', () => {
  for (const item of staged.recipes) {
    assert.match(item.firestore.sourceNote, /^\[web\]/);
    assert.doesNotMatch(item.firestore.sourceNote, /^\[book\]/);
  }
  assert.equal(staged.unmappedCandidates.length, 1);
  assert.equal(staged.unmappedCandidates[0].firestore, null);
  assert.ok(staged.unmappedCandidates[0].importBlockers.some(x => x.includes('categories')));
});

test('source assumptions and exclusions are explicitly visible', () => {
  const grain = staged.recipes.find(x => x.id.includes('spelt'));
  const fish = staged.recipes.find(x => x.id.includes('salmon'));
  assert.ok(grain.reviewBlockers.some(x => x.includes('70 g')));
  assert.ok(fish.reviewBlockers.some(x => x.includes('Atlantic')));
  assert.ok(fish.reviewBlockers.some(x => x.includes('tráng miệng')));
});
