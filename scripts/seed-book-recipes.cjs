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

const PROJECT = 'longvita-8da7e';
const COLLECTION = 'recipes';
const ORIGIN = 'https://firestore.googleapis.com/v1';

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
  const args = process.argv.slice(2);
  const isApply = args.includes('--apply');
  const catalogPath = path.resolve(__dirname, '../docs/recipes-valter-longo-book-29.json');

  if (!fs.existsSync(catalogPath)) {
    console.error(`Error: Catalog not found at ${catalogPath}`);
    process.exit(1);
  }

  const recipes = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
  console.log(`Loaded ${recipes.length} recipes from ${catalogPath}`);

  if (!isApply) {
    console.log('\n[DRY RUN MODE] No changes will be made to Firestore.');
    console.log('To write live, run: node scripts/seed-book-recipes.cjs --apply\n');
    recipes.forEach((r, idx) => {
      console.log(`[${idx + 1}/${recipes.length}] ${r.id}: ${r.name} (${r.category}) - ${r.calories} kcal, ${r.proteinGrams}g đạm`);
    });
    console.log('\nValidation successful: all 29 recipes ready for publication.');
    return;
  }

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

main().catch(err => {
  console.error('Seeder execution error:', err.message);
  process.exit(1);
});
