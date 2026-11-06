'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const research = require(path.join(__dirname, '../../docs/hoang-recipe-research-ledger-20261106.json'));

test('research file explicitly blocks import to live Firebase', () => {
  assert.equal(research.status, 'RESEARCH_ONLY__PROHIBIT_IMPORT');
  assert.equal(research.firebaseProject, 'longvita-8da7e');
  assert.equal(research.collection, 'recipes');
  assert.equal(research.exclusions.includes('No recipe.firestore object'), true);
});

test('research source groups are explicitly separated', () => {
  assert.equal(research.candidates.length, 17);
  assert.equal(research.candidates.filter(c => c.type === 'book_appendix_candidate').length, 13);
  assert.equal(research.candidates.filter(c => c.source.tier.includes('PRIMARY')).length, 4);
});

test('no research candidate silently contains import-ready recipe fields', () => {
  for (const candidate of research.candidates) {
    assert.equal(Object.hasOwn(candidate, 'firestore'), false, candidate.id);
    assert.equal(Object.hasOwn(candidate, 'calories'), false, candidate.id);
    assert.equal(Object.hasOwn(candidate, 'proteinGrams'), false, candidate.id);
    assert.equal(candidate.completeness.nutritionPerServingVerified, false, candidate.id);
    assert.equal(candidate.completeness.usageRightsApproved, false, candidate.id);
    assert.equal(candidate.completeness.teamApproved, false, candidate.id);
  }
});

test('nonofficial book source cannot claim exact pages or primary verification', () => {
  for (const candidate of research.candidates.filter(c => c.type === 'book_appendix_candidate')) {
    assert.equal(candidate.source.tier, 'UNOFFICIAL_AI_TRANSLATED_COPY');
    assert.equal(candidate.source.pageVi, null);
    assert.equal(candidate.source.pageEn, null);
    assert.equal(candidate.completeness.verifiedOfficialRecipeText, false);
  }
});

test('brown rice cannot be silently converted to wild rice', () => {
  const rice = research.candidates.find(c => c.id === 'BOOK-W1D2-L');
  assert.ok(rice);
  assert.match(rice.originalCandidate, /brown rice/i);
  assert.match(rice.titleVi, /gạo lứt/i);
  assert.doesNotMatch(rice.titleVi, /gạo hoang/i);
});

test('IDs and source links are unique and well-formed', () => {
  const ids = research.candidates.map(c => c.id);
  assert.equal(new Set(ids).size, ids.length);
  for (const candidate of research.candidates) {
    assert.match(candidate.source.url, /^https:\/\//);
    assert.equal(typeof candidate.evidenceStatus, 'string');
  }
});
