#!/usr/bin/env node
'use strict';

// Read-only gate for team-reviewed recipe data. NEVER uploads to Firebase.
const fs = require('node:fs');
const crypto = require('node:crypto');

const RECIPE_KEYS = [
  'name', 'description', 'category', 'proteinGrams', 'calories',
  'ingredients', 'instructions', 'imageUrl', 'sourceNote',
];
const INGREDIENT_KEYS = ['id', 'name', 'amount', 'unit', 'category', 'isPurchased'];
const CATEGORIES = new Set(['ca', 'dau', 'rau_cu', 'ngu_coc']);
const has = (o, key) => Object.prototype.hasOwnProperty.call(o, key);
const object = (v) => v !== null && typeof v === 'object' && !Array.isArray(v);
const str = (v) => typeof v === 'string' && v.trim().length > 0;
// Reject values copied from the documented JSON template, not just empty strings.
const verifiedText = (v) => str(v) && !/^<[^>]+>$/.test(v.trim()) &&
  !/^(?:TBD|TODO|pending|not[ -]approved|not[ -]verified)$/i.test(v.trim());
const nonnegative = (v) => typeof v === 'number' && Number.isFinite(v) && v >= 0;
const positive = (v) => nonnegative(v) && v > 0;
const https = (v) => str(v) && /^https:\/\/[^\s/]+(?:\/[^\s]*)?$/i.test(v);
const isoDate = (v) => str(v) && !Number.isNaN(Date.parse(v)) &&
  /^\d{4}-\d{2}-\d{2}T/.test(v);
const fingerprint = (recipes) =>
  crypto.createHash('sha256').update(JSON.stringify(recipes), 'utf8').digest('hex');

function validate(catalog, requireApproval = true) {
  const errors = [];
  const fail = (at, message) => errors.push(`${at}: ${message}`);
  if (!object(catalog)) return ['root: expected JSON object'];
  if (catalog.projectId !== 'longvita-8da7e') fail('projectId', 'expected longvita-8da7e');
  if (catalog.collection !== 'recipes') fail('collection', 'expected recipes');
  if (!Array.isArray(catalog.recipes) || catalog.recipes.length === 0) {
    fail('recipes', 'must contain a non-empty reviewed batch');
    return errors;
  }
  const ids = new Set();
  const recipeNames = new Set();
  for (const [index, entry] of catalog.recipes.entries()) {
    const at = `recipes[${index}]`;
    if (!object(entry)) { fail(at, 'expected object'); continue; }
    if (!str(entry.id) || !/^[A-Za-z0-9_-]{1,120}$/.test(entry.id)) {
      fail(at + '.id', 'safe nonempty Firestore document ID required');
    } else if (ids.has(entry.id)) {
      fail(at + '.id', 'duplicate ID');
    } else ids.add(entry.id);
    const data = entry.firestore;
    if (!object(data)) { fail(at + '.firestore', 'expected object'); continue; }
    for (const key of RECIPE_KEYS) {
      if (!has(data, key)) fail(at + '.firestore.' + key, 'missing field');
    }
    for (const key of Object.keys(data)) {
      if (!RECIPE_KEYS.includes(key)) fail(at + '.firestore.' + key, 'not allowed by current Firestore rules');
    }
    for (const key of ['name', 'description', 'sourceNote']) {
      if (!str(data[key])) fail(at + '.firestore.' + key, 'nonempty string required');
    }
    if (str(data.name)) {
      const normalized = data.name.trim().toLocaleLowerCase('vi');
      if (recipeNames.has(normalized)) fail(at + '.firestore.name', 'duplicate name in batch');
      recipeNames.add(normalized);
    }
    if (!CATEGORIES.has(data.category)) fail(at + '.firestore.category', 'unknown category');
    if (!positive(data.calories)) fail(at + '.firestore.calories', 'positive kcal per serving required');
    if (!nonnegative(data.proteinGrams)) fail(at + '.firestore.proteinGrams', 'nonnegative grams per serving required');
    if (data.imageUrl !== null && data.imageUrl !== undefined && !https(data.imageUrl)) {
      fail(at + '.firestore.imageUrl', 'HTTPS URL or null required');
    }
    if (!Array.isArray(data.instructions) || data.instructions.length === 0 ||
        !data.instructions.every(str)) {
      fail(at + '.firestore.instructions', 'nonempty string steps required');
    }
    if (!Array.isArray(data.ingredients) || data.ingredients.length === 0) {
      fail(at + '.firestore.ingredients', 'nonempty ingredients required');
    }
    const ingredientIds = new Set();
    for (const [j, ingredient] of (Array.isArray(data.ingredients) ? data.ingredients : []).entries()) {
      const p = `${at}.firestore.ingredients[${j}]`;
      if (!object(ingredient)) { fail(p, 'expected object'); continue; }
      for (const key of INGREDIENT_KEYS) if (!has(ingredient, key)) fail(p + '.' + key, 'missing field');
      for (const key of Object.keys(ingredient)) if (!INGREDIENT_KEYS.includes(key)) {
        fail(p + '.' + key, 'unexpected ingredient field');
      }
      for (const key of ['id', 'name', 'unit', 'category']) if (!str(ingredient[key])) {
        fail(p + '.' + key, 'nonempty string required');
      }
      if (str(ingredient.id) && ingredientIds.has(ingredient.id)) fail(p + '.id', 'duplicate ingredient ID');
      if (str(ingredient.id)) ingredientIds.add(ingredient.id);
      if (!positive(ingredient.amount)) fail(p + '.amount', 'positive quantity required');
      if (ingredient.isPurchased !== false) fail(p + '.isPurchased', 'recipe templates must start unchecked');
    }
    const provenance = entry.provenance;
    if (!object(provenance)) { fail(at + '.provenance', 'required'); continue; }
    const source = provenance.recipeSource;
    if (!object(source) || !['book', 'official-recipe', 'team-original', 'licensed'].includes(source.type) ||
        !verifiedText(source.title) || !verifiedText(source.locator) || !verifiedText(source.rightsEvidence)) {
      fail(at + '.provenance.recipeSource', 'verified type, title, locator and rightsEvidence required');
    }
    if (source && has(source, 'url') && source.url !== null && !https(source.url)) {
      fail(at + '.provenance.recipeSource.url', 'must be an HTTPS URL');
    }
    const nutrition = provenance.nutrition;
    if (!object(nutrition) || !Number.isInteger(nutrition.servings) || nutrition.servings < 1 ||
        !Array.isArray(nutrition.entries)) {
      fail(at + '.provenance.nutrition', 'positive integer servings and entries required');
      continue;
    }
    const nutritionIds = new Set();
    let totalCalories = 0;
    let totalProtein = 0;
    for (const [j, item] of nutrition.entries.entries()) {
      const p = `${at}.provenance.nutrition.entries[${j}]`;
      if (!object(item)) { fail(p, 'expected object'); continue; }
      if (!str(item.ingredientId) || !ingredientIds.has(item.ingredientId)) {
        fail(p + '.ingredientId', 'must reference one recipe ingredient');
      } else if (nutritionIds.has(item.ingredientId)) fail(p + '.ingredientId', 'duplicate reference');
      else nutritionIds.add(item.ingredientId);
      for (const key of ['foodCode', 'sourceName', 'preparationState']) if (!str(item[key])) {
        fail(p + '.' + key, 'required for traceable nutrition');
      }
      if (!https(item.sourceUrl)) fail(p + '.sourceUrl', 'HTTPS nutrition source URL required');
      if (!positive(item.edibleGrams)) fail(p + '.edibleGrams', 'edible mass in grams required');
      if (!nonnegative(item.kcalPer100g) || !nonnegative(item.proteinPer100g)) {
        fail(p, 'finite nonnegative nutrients per 100g required');
      }
      const ingredient = Array.isArray(data.ingredients)
        ? data.ingredients.find((v) => object(v) && v.id === item.ingredientId) : null;
      if (ingredient && ingredient.unit !== 'g' && !verifiedText(item.conversionNote)) {
        fail(p + '.conversionNote', 'conversion to edible grams required for non-g units');
      }
      if (ingredient && ingredient.unit === 'g' && positive(item.edibleGrams) &&
          positive(ingredient.amount) &&
          Math.abs(item.edibleGrams - ingredient.amount) > 0.5 &&
          !verifiedText(item.conversionNote)) {
        fail(p + '.conversionNote', 'document trimming/cooking loss when edible grams differ from recorded grams');
      }
      if (ingredient && ingredient.unit === 'g' && positive(item.edibleGrams) &&
          positive(ingredient.amount) &&
          Math.abs(item.edibleGrams - ingredient.amount) > 0.5 &&
          !https(item.manualReviewEvidenceUrl)) {
        fail(p + '.manualReviewEvidenceUrl', 'a differing gram mass requires linked manual review');
      }
      if (positive(item.edibleGrams) && nonnegative(item.kcalPer100g) && nonnegative(item.proteinPer100g)) {
        totalCalories += item.edibleGrams * item.kcalPer100g / 100;
        totalProtein += item.edibleGrams * item.proteinPer100g / 100;
      }
    }
    for (const id of ingredientIds) if (!nutritionIds.has(id)) {
      fail(at + '.provenance.nutrition', 'missing nutrition reference for ingredient ' + id);
    }
    const perServingCalories = totalCalories / nutrition.servings;
    const perServingProtein = totalProtein / nutrition.servings;
    if (positive(data.calories) && Math.abs(data.calories - perServingCalories) > 2) {
      fail(at + '.firestore.calories', `expected ~${perServingCalories.toFixed(2)} kcal/serving from cited inputs`);
    }
    if (nonnegative(data.proteinGrams) && Math.abs(data.proteinGrams - perServingProtein) > 0.2) {
      fail(at + '.firestore.proteinGrams', `expected ~${perServingProtein.toFixed(3)} g/serving from cited inputs`);
    }
  }
  if (requireApproval) {
    for (const [index, entry] of catalog.recipes.entries()) {
      if (!Array.isArray(entry.reviewBlockers) || entry.reviewBlockers.length !== 0) {
        fail(`recipes[${index}].reviewBlockers`, 'manual blockers must be explicitly resolved before publication');
      }
    }
    const approval = catalog.approval;
    if (!object(approval) || approval.decision !== 'approved' ||
        !verifiedText(approval.approvedBy) || !isoDate(approval.approvedAt) || !https(approval.evidenceUrl)) {
      fail('approval', 'explicit batch approval, reviewer, timestamp and evidence URL required');
    }
    if (!object(approval) || approval.recipesSha256 !== fingerprint(catalog.recipes)) {
      fail('approval.recipesSha256', 'approval fingerprint does not match this exact batch');
    }
  }
  return errors;
}

if (require.main === module) {
  const [, , mode, file] = process.argv;
  if (!['--review', '--verify'].includes(mode) || !file) {
    console.error('Usage: node scripts/validate-recipe-intake.cjs --review|--verify <intake.json>');
    process.exit(2);
  }
  try {
    const catalog = JSON.parse(fs.readFileSync(file, 'utf8'));
    const errors = validate(catalog, mode === '--verify');
    for (const error of errors) console.error('FAIL ' + error);
    if (errors.length) {
      console.error(`BLOCKED: ${errors.length} catalog issue(s); no Firebase writes were attempted.`);
      process.exit(1);
    }
    console.log('PASS: offline schema/provenance/nutrition checks.');
    console.log('REVIEW SHA256 (recipes): ' + fingerprint(catalog.recipes));
    if (mode === '--review') {
      console.log('NOT APPROVED: obtain a reviewer decision for this hash before --verify.');
    } else {
      console.log('APPROVAL GATE PASSED (evidence authenticity still requires manual review).');
    }
    console.log('No Firebase writes were attempted.');
  } catch (error) {
    console.error('BLOCKED: unable to read recipe intake: ' + error.message);
    process.exit(1);
  }
}

module.exports = { validate, fingerprint };
