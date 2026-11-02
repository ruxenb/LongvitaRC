// Storage Security Rules tests: each user reads and writes only reports/{uid}/.
// Run from firebase/: npm ci && npm run test:rules
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const { after, before, beforeEach, describe, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  deleteObject,
  getBytes,
  ref,
  uploadBytes,
} = require('firebase/storage');

const RULES_FILE = process.env.STORAGE_RULES_FILE ?? resolve(__dirname, '../storage.rules');
const PDF = new Uint8Array([0x25, 0x50, 0x44, 0x46]);
const METADATA = { contentType: 'application/pdf' };

let env;

const storageOf = (uid) =>
  uid ? env.authenticatedContext(uid).storage() : env.unauthenticatedContext().storage();

const put = (uid, path) => uploadBytes(ref(storageOf(uid), path), PDF, METADATA);
const read = (uid, path) => getBytes(ref(storageOf(uid), path));
const remove = (uid, path) => deleteObject(ref(storageOf(uid), path));

/** Puts a file in place without going through the rules. */
const seed = (path) =>
  env.withSecurityRulesDisabled((context) =>
    uploadBytes(ref(context.storage(), path), PDF, METADATA),
  );

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-longvita',
    storage: { rules: readFileSync(RULES_FILE, 'utf8') },
  });
});

beforeEach(() => env.clearStorage());
after(() => env.cleanup());

describe('reports/{uid}', () => {
  test('A writes a report into their own folder', () =>
    assertSucceeds(put('uid-a', 'reports/uid-a/e1.pdf')));

  test('A reads their own report', async () => {
    await seed('reports/uid-a/e1.pdf');
    await assertSucceeds(read('uid-a', 'reports/uid-a/e1.pdf'));
  });

  test('A overwrites their own report, as a retry does', async () => {
    await seed('reports/uid-a/e1.pdf');
    await assertSucceeds(put('uid-a', 'reports/uid-a/e1.pdf'));
  });

  test('A deletes their own report', async () => {
    await seed('reports/uid-a/e1.pdf');
    await assertSucceeds(remove('uid-a', 'reports/uid-a/e1.pdf'));
  });

  test('A writes into a nested folder of their own', () =>
    assertSucceeds(put('uid-a', 'reports/uid-a/2026/e1.pdf')));

  test('B cannot read the report of A', async () => {
    await seed('reports/uid-a/e1.pdf');
    await assertFails(read('uid-b', 'reports/uid-a/e1.pdf'));
  });

  test('B cannot write into the folder of A', () =>
    assertFails(put('uid-b', 'reports/uid-a/e1.pdf')));

  test('B cannot delete the report of A', async () => {
    await seed('reports/uid-a/e1.pdf');
    await assertFails(remove('uid-b', 'reports/uid-a/e1.pdf'));
  });

  test('signed out cannot read a report', async () => {
    await seed('reports/uid-a/e1.pdf');
    await assertFails(read(null, 'reports/uid-a/e1.pdf'));
  });

  test('signed out cannot write a report', () =>
    assertFails(put(null, 'reports/uid-a/e1.pdf')));
});

describe('everything else', () => {
  test('a signed-in user cannot write at the root', () =>
    assertFails(put('uid-a', 'e1.pdf')));

  test('a signed-in user cannot write directly under reports', () =>
    assertFails(put('uid-a', 'reports/e1.pdf')));

  test('a signed-in user cannot read another top folder', async () => {
    await seed('private/e1.pdf');
    await assertFails(read('uid-a', 'private/e1.pdf'));
  });

  test('a uid that only starts with the same text gets no access', () =>
    assertFails(put('uid-a', 'reports/uid-a2/e1.pdf')));
});
