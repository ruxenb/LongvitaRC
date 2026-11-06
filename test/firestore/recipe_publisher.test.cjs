'use strict';
const assert = require('node:assert/strict');
const { test } = require('node:test');
const path = require('node:path');
const { encodeFields, decodeFields, publicationGuard, createOnly, main } =
  require('../../scripts/publish-approved-recipes.cjs');
const { fingerprint } = require('../../scripts/validate-recipe-intake.cjs');

const staged = require(path.join(__dirname, '../../docs/hoang-staged-usda-recipes-20261106.json'));
const stagedPath = path.join(__dirname, '../../docs/hoang-staged-usda-recipes-20261106.json');

test('nested Firestore values roundtrip including arrays, booleans and null', () => {
  const data = { name: 'Món thử', calories: 22.5, ok: false,
    imageUrl: null, ingredients: [{ id: 'i', amount: 5, purchased: false }] };
  assert.deepEqual(decodeFields(encodeFields(data)), data);
});

test('dryrun never performs a network request, even without credentials', async () => {
  const result = await main(['--file', stagedPath], {}, () => {
    throw new Error('NETWORK_REQUEST_NOT_ALLOWED');
  });
  assert.equal(result.dryRun, true);
});

test('current staged data is blocked from publication even with a supplied token', async () => {
  const sha = fingerprint(staged.recipes);
  await assert.rejects(() => main([
    '--file', stagedPath, '--apply', '--project', 'longvita-8da7e',
    '--sha', sha, '--ack-live', 'PUBLISH_APPROVED_RECIPES_TO_SHARED_FIRESTORE',
  ], { FIRESTORE_ACCESS_TOKEN: 'test-only-token' }, () => {
    throw new Error('NETWORK_REQUEST_NOT_ALLOWED');
  }), /publicationAuthorized=false/);
});

test('a wrong project or sha is always rejected', () => {
  const catalog = { ...staged, publicationAuthorized: true };
  assert.throws(() => publicationGuard(catalog, 'WRONG', {
    project: 'other-project', ack: 'PUBLISH_APPROVED_RECIPES_TO_SHARED_FIRESTORE',
  }), /project/);
  assert.throws(() => publicationGuard(catalog, 'WRONG', {
    project: 'longvita-8da7e', ack: 'PUBLISH_APPROVED_RECIPES_TO_SHARED_FIRESTORE',
  }), /sha/);
});

test('create-only importer never overwrites an existing document', async () => {
  const calls = [];
  const mocked = async (url, opts) => {
    calls.push({ url, method: opts.method });
    return { status: 200, ok: true, json: async () => ({ name: 'existing' }) };
  };
  await assert.rejects(() => createOnly({ recipes: [staged.recipes[0]] }, 'fake', mocked),
    /already exists/);
  assert.deepEqual(calls.map(x => x.method), ['GET']);
});

test('create-only importer reads back each newly created document', async () => {
  const row = staged.recipes[0];
  let count = 0;
  const mock = async (url, options) => {
    count++;
    if (count === 1) {
      assert.equal(options.method, 'GET');
      return { status: 404, ok: false };
    }
    if (count === 2) {
      assert.equal(options.method, 'POST');
      assert.match(url, /documentId=/);
      return { status: 200, ok: true, json: async () => ({
        name: 'projects/longvita-8da7e/databases/(default)/documents/recipes/' + row.id,
      }) };
    }
    assert.equal(options.method, 'GET');
    return { status: 200, ok: true, json: async () => ({
      fields: encodeFields(Object.fromEntries(Object.entries(row.firestore).reverse())),
    }) };
  };
  const created = await createOnly({ recipes: [row] }, 'test-token', mock);
  assert.deepEqual(created, [row.id]);
  assert.equal(count, 3);
});
