#!/usr/bin/env node
'use strict';

/**
 * Seeder script for 29 Dr. Valter Longo Book Recipes (Two-Week Longevity Diet Meal Plan).
 * 
 * Usage:
 *   1. Dry run (no writes, validates payload):
 *      node scripts/seed-book-recipes.cjs --dry-run
 * 
 *   2. Live publish using Firestore Access Token:
 *      $env:FIRESTORE_ACCESS_TOKEN = (gcloud auth print-access-token)
 *      node scripts/seed-book-recipes.cjs --apply
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PROJECT = 'longvita-8da7e';
const COLLECTION = 'recipes';
const ORIGIN = 'https://firestore.googleapis.com/v1';

// A Firestore access token is NOT sufficient to publish book/nutrition claims.
function validateCatalog(recipes) {
  if (!Array.isArray(recipes) || recipes.length !== 29) {
    throw new Error('Catalog must contain exactly 29 recipes.');
  }
  const ids = new Set();
  for (const recipe of recipes) {
    if (typeof recipe.id !== 'string' ||
        !/^lv-book-[a-z0-9-]+$/.test(recipe.id) || ids.has(recipe.id)) {
      throw new Error('Invalid or duplicate recipe ID.');
    }
    ids.add(recipe.id);
    for (const key of ['name', 'description', 'category', 'sourceNote']) {
      if (typeof recipe[key] !== 'string' || !recipe[key].trim()) {
        throw new Error('Recipe ' + recipe.id + ' has invalid ' + key);
      }
    }
    if (!recipe.sourceNote.startsWith('[book]')) {
      throw new Error('Recipe ' + recipe.id + ' must have book provenance.');
    }
    if (!Number.isFinite(recipe.calories) || recipe.calories <= 0 ||
        !Number.isFinite(recipe.proteinGrams) || recipe.proteinGrams <= 0) {
      throw new Error('Recipe ' + recipe.id + ' has invalid nutrition.');
    }
    if (!Array.isArray(recipe.ingredients) || recipe.ingredients.length === 0 ||
        !recipe.ingredients.every(item => item && typeof item.id === 'string' &&
          typeof item.name === 'string' && item.name.trim() &&
          Number.isFinite(item.amount) && item.amount > 0 &&
          typeof item.unit === 'string' && item.unit.trim())) {
      throw new Error('Recipe ' + recipe.id + ' has invalid ingredients.');
    }
    if (!Array.isArray(recipe.instructions) || recipe.instructions.length === 0 ||
        !recipe.instructions.every(step => typeof step === 'string' && step.trim())) {
      throw new Error('Recipe ' + recipe.id + ' has invalid instructions.');
    }
    if (!recipe._bookProvenance ||
        recipe._bookProvenance.kcal !== recipe.calories ||
        recipe._bookProvenance.proteinGrams !== recipe.proteinGrams ||
        ![1, 2].includes(recipe._bookProvenance.week) ||
        !Number.isInteger(recipe._bookProvenance.day) ||
        recipe._bookProvenance.day < 1 || recipe._bookProvenance.day > 7) {
      throw new Error('Recipe ' + recipe.id + ' has inconsistent provenance.');
    }
  }
  return ids;
}

function verifyPublicationReview(review, expectedHash, recipeIds) {
  if (!review || review.approved !== true ||
      review.projectId !== PROJECT || review.collection !== COLLECTION ||
      review.catalogSha256 !== expectedHash) {
    throw new Error('BLOCKED: project, collection or exact catalog SHA256 mismatch.');
  }
  if (!Array.isArray(review.recipeReviews) ||
      review.recipeReviews.length !== recipeIds.size) {
    throw new Error('BLOCKED: all 29 recipes need individual source and nutrient sign-off.');
  }
  const reviewed = new Set();
  for (const item of review.recipeReviews) {
    if (!item || !recipeIds.has(item.id) || reviewed.has(item.id) ||
        item.approved !== true ||
        typeof item.sourceReviewedBy !== 'string' || !item.sourceReviewedBy.trim() ||
        typeof item.nutritionReviewedBy !== 'string' || !item.nutritionReviewedBy.trim() ||
        typeof item.bookSourceEvidence !== 'string' || item.bookSourceEvidence.trim().length < 8 ||
        typeof item.nutrientEvidence !== 'string' || item.nutrientEvidence.trim().length < 8) {
      throw new Error('BLOCKED: a recipe is missing traceable source or nutrient review.');
    }
    reviewed.add(item.id);
  }
  return true;
}

function readArgs(args) {
  let apply = false;
  let approvalFile = null;
  let confirmedProject = null;
  for (let i = 0; i < args.length; i++) {
    const flag = args[i];
    if (flag === '--apply') {
      apply = true;
    } else if (flag === '--dry-run') {
      // Harmless unless combined with --apply, checked below.
    } else if (flag === '--approval-file' || flag === '--confirm-project') {
      const val = args[++i];
      if (!val || val.startsWith('--')) throw new Error('Missing value for ' + flag);
      if (flag === '--approval-file') approvalFile = val;
      else confirmedProject = val;
    } else {
      throw new Error('Unexpected flag: ' + flag);
    }
  }
  if (apply && args.includes('--dry-run')) {
    throw new Error('Do not combine --apply and --dry-run.');
  }
  return { apply, approvalFile, confirmedProject };
}


function encodeValue(value) {
  if (value === null) return { nullValue: null };
  if (typeof value === 'string') return { stringValue: value };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number' && Number.isFinite(value)) return { doubleValue: value };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(encodeValue) } };
  if (value && typeof value === 'object' && Object.getPrototypeOf(value) === Object.prototype) {
    return { mapValue: { fields: encodeFields(value) } };
  }
  throw new Error('Unsupported Firestore field type: ' + typeof value);
}

function encodeFields(obj) {
  return Object.fromEntries(
    Object.entries(obj)
      .filter(([key]) => !key.startsWith('_')) // Exclude internal metadata
      .map(([key, value]) => [key, encodeValue(value)])
  );
}

async function request(url, method, body, token) {
  const response = await fetch(url, {
    method,
    headers: {
      Authorization: 'Bearer ' + token,
      'Content-Type': 'application/json',
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
    signal: AbortSignal.timeout(15000),
  });
  if (response.status === 404) return { missing: true };
  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Firestore HTTP ${response.status}: ${errorText}`);
  }
  return { data: await response.json() };
}

async function main() {
  const args = readArgs(process.argv.slice(2));
  const isApply = args.apply;
  const catalogPath = path.resolve(__dirname, '../docs/recipes-valter-longo-book-29.json');

  if (!fs.existsSync(catalogPath)) {
    console.error(`Error: Catalog not found at ${catalogPath}`);
    process.exit(1);
  }

  const rawCatalog = fs.readFileSync(catalogPath);
  const recipes = JSON.parse(rawCatalog.toString('utf8'));
  const recipeIds = validateCatalog(recipes);
  const catalogSha256 = crypto.createHash('sha256').update(rawCatalog).digest('hex');
  console.log('Loaded ' + recipes.length + ' structurally valid recipes.');
  console.log('Exact catalog SHA256: ' + catalogSha256);

  if (!isApply) {
    console.log('\n[DRY RUN MODE] No changes will be made to Firestore.');
    console.log('To write live, run: node scripts/seed-book-recipes.cjs --apply\n');
    recipes.forEach((r, idx) => {
      console.log(`[${idx + 1}/${recipes.length}] ${r.id}: ${r.name} (${r.category}) - ${r.calories} kcal, ${r.proteinGrams}g đạm`);
    });
    console.log('\nSTRUCTURAL CHECK ONLY. NOT APPROVED FOR PUBLICATION. Obtain source and nutrient sign-off for every recipe.');
    return;
  }

  if (args.confirmedProject !== PROJECT) {
    throw new Error('BLOCKED: --apply requires --confirm-project ' + PROJECT);
  }
  if (!args.approvalFile) {
    throw new Error('BLOCKED: --apply requires --approval-file for the exact catalog batch.');
  }
  const approvalPath = path.resolve(args.approvalFile);
  if (!fs.existsSync(approvalPath)) {
    throw new Error('BLOCKED: reviewer approval file not found.');
  }
  verifyPublicationReview(
    JSON.parse(fs.readFileSync(approvalPath, 'utf8')), catalogSha256, recipeIds,
  );
  console.log('Verified 29 individual approval records against exact catalog SHA256.');

  const token = process.env.FIRESTORE_ACCESS_TOKEN;
  if (!token) {
    console.error('Error: FIRESTORE_ACCESS_TOKEN environment variable is required for --apply.');
    console.error('Get one via: $env:FIRESTORE_ACCESS_TOKEN = (gcloud auth print-access-token)');
    process.exit(1);
  }

  const parent = `${ORIGIN}/projects/${PROJECT}/databases/(default)/documents/`;
  console.log(`Targeting Firestore: ${parent}${COLLECTION}`);

  let successCount = 0;
  for (const recipe of recipes) {
    const docId = recipe.id;
    const docUrl = `${parent}${COLLECTION}/${encodeURIComponent(docId)}`;

    // Check if document already exists
    const checkRes = await request(docUrl, 'GET', null, token);
    if (!checkRes.missing) {
      console.log(`[EXISTS] ${docId} already exists in Firestore. Skipping.`);
      continue;
    }

    // Prepare fields without private internal fields
    const firestoreData = {
      name: recipe.name,
      description: recipe.description,
      category: recipe.category,
      proteinGrams: recipe.proteinGrams,
      calories: recipe.calories,
      ingredients: recipe.ingredients,
      instructions: recipe.instructions,
      imageUrl: recipe.imageUrl,
      sourceNote: recipe.sourceNote,
      isArchived: recipe.isArchived,
    };

    const createUrl = `${parent}${COLLECTION}?documentId=${encodeURIComponent(docId)}`;
    await request(createUrl, 'POST', { fields: encodeFields(firestoreData) }, token);
    console.log(`[CREATED] ${docId} -> ${recipe.name}`);
    successCount++;
  }

  console.log(`\nPublication complete! Successfully created ${successCount} new recipes.`);
}

if (require.main === module) {
  main().catch(err => {
    console.error('Seeder execution error:', err.message);
    process.exitCode = 1;
  });
} else {
  module.exports = { validateCatalog, verifyPublicationReview, readArgs };
}
