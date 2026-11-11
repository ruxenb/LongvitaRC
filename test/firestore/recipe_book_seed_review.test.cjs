'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const cp = require('node:child_process');
const seederPath = path.resolve(__dirname, '../../scripts/seed-book-recipes.cjs');
const catalogPath = path.resolve(__dirname, '../../docs/recipes-valter-longo-book-29.json');
const { validateCatalog, verifyPublicationReview, readArgs } = require(seederPath);
const rawCatalog = fs.readFileSync(catalogPath);
const recipes = JSON.parse(rawCatalog.toString('utf8'));
const actualHash = crypto.createHash('sha256').update(rawCatalog).digest('hex');
const idList = validateCatalog(recipes);
const run = (...args) => cp.spawnSync(process.execPath, [seederPath, ...args], {
  encoding: 'utf8',
  timeout: 15000,
  env: { ...process.env, FIRESTORE_ACCESS_TOKEN: 'TEST_INVALID_TOKEN_MUST_NOT_BE_USED' },
});
function reviewFixture() {
  return {
    approved: true,
    projectId: 'longvita-8da7e',
    collection: 'recipes',
    catalogSha256: actualHash,
    recipeReviews: recipes.map(r => ({
      id: r.id,
      approved: true,
      sourceReviewedBy: 'UNIT_TEST_REVIEWER_SOURCE',
      nutritionReviewedBy: 'UNIT_TEST_REVIEWER_NUTRITION',
      bookSourceEvidence: 'UNIT_TEST_ONLY_DO_NOT_PUBLISH',
      nutrientEvidence: 'UNIT_TEST_ONLY_DO_NOT_PUBLISH',
    })),
  };
}
test('all 29 catalog entries are present and structurally sound', () => {
  assert.equal(idList.size, 29);
  assert.equal(actualHash.length, 64);
});
test('detect duplicate book recipe IDs', () => {
  const a = structuredClone(recipes);
  a[1].id = a[0].id;
  assert.throws(() => validateCatalog(a), /duplicate/);
});
test('reject ingredients with nonpositive quantities', () => {
  const a = structuredClone(recipes);
  a[0].ingredients[0].amount = 0;
  assert.throws(() => validateCatalog(a), /invalid ingredients/);
});
test('reject unverified or inconsistent book provenance', () => {
  const a = structuredClone(recipes);
  a[0]._bookProvenance.kcal = 999999;
  assert.throws(() => validateCatalog(a), /inconsistent provenance/);
  const b = structuredClone(recipes);
  b[0].sourceNote = 'unlabelled book claim';
  assert.throws(() => validateCatalog(b), /book provenance/);
});
test('dry-run remains offline and explicitly says not approved', () => {
  const out = run('--dry-run');
  assert.equal(out.status, 0, out.stderr);
  assert.match(out.stdout, /STRUCTURAL CHECK ONLY/);
  assert.match(out.stdout, /NOT APPROVED FOR PUBLICATION/);
  assert.doesNotMatch(out.stdout, /all 29 recipes ready for publication/i);
  assert.doesNotMatch(out.stdout, /Targeting Firestore/);
});
test('apply requires explicit project and per-recipe approval even with token', () => {
  const missingProject = run('--apply');
  assert.equal(missingProject.status, 1);
  assert.match(missingProject.stderr, /confirm-project/);
  const missingReview = run('--apply', '--confirm-project', 'longvita-8da7e');
  assert.equal(missingReview.status, 1);
  assert.match(missingReview.stderr, /approval-file/);
  assert.doesNotMatch(missingReview.stdout, /Targeting Firestore/);
});
test('reject unknown flags and conflicting CLI modes', () => {
  assert.throws(() => readArgs(['--unsafe']), /Unexpected flag/);
  assert.throws(() => readArgs(['--apply', '--dry-run']), /combine/);
  assert.throws(() => readArgs(['--dry-run', '--apply']), /combine/);
  assert.throws(() => readArgs(['--apply', '--approval-file']), /Missing value/);
});
test('matching 29 individual review attestations are recognized purely in memory', () => {
  assert.equal(verifyPublicationReview(reviewFixture(), actualHash, idList), true);
});
test('reject wrong project, target and exact batch hash', () => {
  for (const mutation of [
    x => { x.projectId = 'other-project'; },
    x => { x.collection = 'users'; },
    x => { x.catalogSha256 = '0'.repeat(64); },
    x => { x.approved = false; },
  ]) {
    const a = reviewFixture();
    mutation(a);
    assert.throws(() => verifyPublicationReview(a, actualHash, idList), /BLOCKED/);
  }
});
test('reject missing, duplicate and unreviewed recipe attestations', () => {
  const missing = reviewFixture();
  missing.recipeReviews.pop();
  assert.throws(() => verifyPublicationReview(missing, actualHash, idList), /29 recipes/);
  const dup = reviewFixture();
  dup.recipeReviews[1].id = dup.recipeReviews[0].id;
  assert.throws(() => verifyPublicationReview(dup, actualHash, idList), /missing traceable/);
  const noEvidence = reviewFixture();
  noEvidence.recipeReviews[0].nutrientEvidence = '';
  assert.throws(() => verifyPublicationReview(noEvidence, actualHash, idList), /missing traceable/);
  const denied = reviewFixture();
  denied.recipeReviews[0].approved = false;
  assert.throws(() => verifyPublicationReview(denied, actualHash, idList), /missing traceable/);
});
