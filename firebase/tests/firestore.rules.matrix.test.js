// Appendix B rules matrix (CM-04): one allowed and one denied case per role
// per collection. Each case ID matches the table in docs/data-model.md.
// The detailed edge cases live in firestore.rules.test.js.
// Runs on the local emulator only, in its own demo project so it never races
// the other suite: npm run test:rules
const { readFileSync, writeFileSync, mkdirSync } = require('node:fs');
const { resolve, dirname } = require('node:path');
const { after, before, beforeEach, describe, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const RULES_FILE = process.env.RULES_FILE ?? resolve(__dirname, '../firestore.rules');
// Optional: write the case results as JSON for evidence/rules/.
const RESULT_FILE = process.env.RULES_MATRIX_OUT;
const CREATED_AT = '2026-11-09T14:00:00.000';
const EXPORT_ID = 'pdf_20261109T140000Z_0123456789abcdef';

let env;
const results = [];

const userDoc = (role) => ({
  email: `${role}@example.test`,
  displayName: `Test ${role}`,
  photoUrl: null,
  role,
  createdAt: CREATED_AT,
});

const recipe = (overrides = {}) => ({
  name: 'Canh đậu hũ rong biển',
  description: 'Món test',
  category: 'dau',
  proteinGrams: 18,
  calories: 210,
  ingredients: [],
  instructions: ['Bước 1'],
  imageUrl: null,
  sourceNote: 'Nguồn test',
  ...overrides,
});

const mealPlan = (overrides = {}) => ({
  uid: 'user1',
  title: 'Thực đơn 7 ngày',
  targetCalories: 1800,
  targetProteinGrams: 60,
  status: 'draft',
  reviewerReason: null,
  days: [],
  createdAt: CREATED_AT,
  ...overrides,
});

const shoppingList = (uid, planId) => ({
  uid,
  planId,
  updatedAt: CREATED_AT,
  items: [],
});

const exportMeta = (planId) => ({
  exportId: EXPORT_ID,
  planId,
  createdAt: '2026-11-09T14:00:00.000Z',
  fileName: `${EXPORT_ID}.pdf`,
  sizeBytes: 20000,
  schemaVersion: 1,
});

const announcement = (authorRole, overrides = {}) => ({
  title: 'Lịch tư vấn dinh dưỡng',
  content: 'Nội dung',
  authorRole,
  createdAt: CREATED_AT,
  ...overrides,
});

const as = (uid) =>
  (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const ACTORS = { anonymous: null, user: 'user1', staff: 'staff1', admin: 'admin1' };

const seed = (path, data) =>
  env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc(path).set(data));

// The Appendix B table. op receives the Firestore client of the role.
const CASES = [
  // users/{uid}
  ['R-01', 'users', 'anonymous', 'read a profile', 'Denied', (db) => db.doc('users/user1').get()],
  ['R-02', 'users', 'user', 'first sign-in creates own profile with role = user', 'Allowed',
    () => as('newuser').doc('users/newuser').set(userDoc('user'))],
  ['R-03', 'users', 'user', 'update own role to admin', 'Denied',
    (db) => db.doc('users/user1').update({ role: 'admin' })],
  ['R-04', 'users', 'staff', 'read own profile (role gate)', 'Allowed',
    (db) => db.doc('users/staff1').get()],
  ['R-05', 'users', 'staff', 'read another user profile', 'Denied',
    (db) => db.doc('users/user1').get()],
  ['R-06', 'users', 'admin', 'change another user role to staff', 'Allowed',
    (db) => db.doc('users/user1').update({ role: 'staff' })],
  ['R-07', 'users', 'admin', 'change own role', 'Denied',
    (db) => db.doc('users/admin1').update({ role: 'user' })],

  // recipes/{id}
  ['R-08', 'recipes', 'anonymous', 'read a recipe', 'Denied', (db) => db.doc('recipes/r1').get()],
  ['R-09', 'recipes', 'user', 'read a recipe', 'Allowed', (db) => db.doc('recipes/r1').get()],
  ['R-10', 'recipes', 'user', 'create a recipe', 'Denied',
    (db) => db.doc('recipes/r2').set(recipe())],
  ['R-11', 'recipes', 'staff', 'archive a recipe (isArchived = true)', 'Allowed',
    (db) => db.doc('recipes/r1').update({ isArchived: true })],
  ['R-12', 'recipes', 'staff', 'hard delete a recipe', 'Denied',
    (db) => db.doc('recipes/r1').delete()],
  ['R-13', 'recipes', 'admin', 'create a valid recipe', 'Allowed',
    (db) => db.doc('recipes/r3').set(recipe())],
  ['R-14', 'recipes', 'admin', 'create a recipe with name over 120 chars', 'Denied',
    (db) => db.doc('recipes/r4').set(recipe({ name: 'x'.repeat(121) }))],

  // meal_plans/{id}
  ['R-15', 'meal_plans', 'anonymous', 'read a plan', 'Denied',
    (db) => db.doc('meal_plans/draft1').get()],
  ['R-16', 'meal_plans', 'user', 'owner submits draft (draft → submitted)', 'Allowed',
    (db) => db.doc('meal_plans/draft1').update({ status: 'submitted' })],
  ['R-17', 'meal_plans', 'user', 'owner self-approves (submitted → approved)', 'Denied',
    (db) => db.doc('meal_plans/sub1').update({ status: 'approved' })],
  ['R-18', 'meal_plans', 'staff', 'approve a plan (submitted → approved)', 'Allowed',
    (db) => db.doc('meal_plans/sub1').update({ status: 'approved' })],
  ['R-19', 'meal_plans', 'staff', 'reject a plan without a reason', 'Denied',
    (db) => db.doc('meal_plans/sub1').update({ status: 'rejected' })],
  ['R-20', 'meal_plans', 'admin', 'reject a plan with a reason', 'Allowed',
    (db) => db.doc('meal_plans/sub1').update({ status: 'rejected', reviewerReason: 'Thiếu đạm' })],
  ['R-21', 'meal_plans', 'admin', 'review an already approved plan (approved → rejected)', 'Denied',
    (db) => db.doc('meal_plans/app1').update({ status: 'rejected', reviewerReason: 'Đổi ý' })],

  // shopping_lists/{uid}/plans/{planId}
  ['R-22', 'shopping_lists', 'anonymous', 'read a shopping list', 'Denied',
    (db) => db.doc('shopping_lists/user1/plans/draft1').get()],
  ['R-23', 'shopping_lists', 'user', 'owner saves own checklist', 'Allowed',
    (db) => db.doc('shopping_lists/user1/plans/draft1').set(shoppingList('user1', 'draft1'))],
  ['R-24', 'shopping_lists', 'user', 'write another user checklist', 'Denied',
    (db) => db.doc('shopping_lists/user2/plans/p2').set(shoppingList('user2', 'p2'))],
  ['R-25', 'shopping_lists', 'staff', 'save own checklist', 'Allowed',
    (db) => db.doc('shopping_lists/staff1/plans/p3').set(shoppingList('staff1', 'p3'))],
  ['R-26', 'shopping_lists', 'staff', 'read a user checklist', 'Denied',
    (db) => db.doc('shopping_lists/user1/plans/draft1').get()],
  ['R-27', 'shopping_lists', 'admin', 'save own checklist', 'Allowed',
    (db) => db.doc('shopping_lists/admin1/plans/p4').set(shoppingList('admin1', 'p4'))],
  ['R-28', 'shopping_lists', 'admin', 'read a user checklist', 'Denied',
    (db) => db.doc('shopping_lists/user1/plans/draft1').get()],

  // users/{uid}/report_exports/{exportId}
  ['R-29', 'report_exports', 'anonymous', 'read export metadata', 'Denied',
    (db) => db.doc(`users/user1/report_exports/${EXPORT_ID}`).get()],
  ['R-30', 'report_exports', 'user', 'owner records PDF metadata of own plan', 'Allowed',
    (db) => db.doc(`users/user1/report_exports/${EXPORT_ID}`).set(exportMeta('draft1'))],
  ['R-31', 'report_exports', 'user', 'owner deletes export history', 'Denied',
    (db) => db.doc(`users/user1/report_exports/${EXPORT_ID}`).delete()],
  ['R-32', 'report_exports', 'staff', 'record metadata of an unsaved plan (planId = null)', 'Allowed',
    (db) => db.doc(`users/staff1/report_exports/${EXPORT_ID}`).set(exportMeta(null))],
  ['R-33', 'report_exports', 'staff', 'read a user export history', 'Denied',
    (db) => db.collection('users/user1/report_exports').get()],
  ['R-34', 'report_exports', 'admin', 'record metadata of an unsaved plan (planId = null)', 'Allowed',
    (db) => db.doc(`users/admin1/report_exports/${EXPORT_ID}`).set(exportMeta(null))],
  ['R-35', 'report_exports', 'admin', 'read a user export metadata', 'Denied',
    (db) => db.doc(`users/user1/report_exports/${EXPORT_ID}`).get()],

  // announcements/{id}
  ['R-36', 'announcements', 'anonymous', 'read announcements', 'Denied',
    (db) => db.collection('announcements').get()],
  ['R-37', 'announcements', 'user', 'stream newest announcements (Inbox)', 'Allowed',
    (db) => db.collection('announcements').orderBy('createdAt', 'desc').limit(20).get()],
  ['R-38', 'announcements', 'user', 'publish an announcement', 'Denied',
    (db) => db.doc('announcements/a2').set(announcement('user'))],
  ['R-39', 'announcements', 'staff', 'publish an announcement as staff', 'Allowed',
    (db) => db.doc('announcements/a3').set(announcement('staff'))],
  ['R-40', 'announcements', 'staff', 'publish posing as admin', 'Denied',
    (db) => db.doc('announcements/a4').set(announcement('admin'))],
  ['R-41', 'announcements', 'admin', 'publish an announcement as admin', 'Allowed',
    (db) => db.doc('announcements/a5').set(announcement('admin'))],
  ['R-42', 'announcements', 'admin', 'publish with content over 2000 chars', 'Denied',
    (db) => db.doc('announcements/a6').set(announcement('admin', { content: 'x'.repeat(2001) }))],
];

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-longvita-matrix',
    firestore: { rules: readFileSync(RULES_FILE, 'utf8') },
  });
});

after(async () => {
  if (RESULT_FILE) {
    mkdirSync(dirname(RESULT_FILE), { recursive: true });
    writeFileSync(RESULT_FILE, `${JSON.stringify(results, null, 2)}\n`);
  }
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed('users/user1', userDoc('user'));
  await seed('users/user2', userDoc('user'));
  await seed('users/staff1', userDoc('staff'));
  await seed('users/admin1', userDoc('admin'));
  await seed('recipes/r1', recipe());
  await seed('meal_plans/draft1', mealPlan());
  await seed('meal_plans/sub1', mealPlan({ status: 'submitted' }));
  await seed('meal_plans/app1', mealPlan({ status: 'approved' }));
  await seed('shopping_lists/user1/plans/draft1', shoppingList('user1', 'draft1'));
  await seed(`users/user1/report_exports/${EXPORT_ID}`, exportMeta('draft1'));
  await seed('announcements/a1', announcement('staff'));
});

describe('Appendix B rules matrix', () => {
  test('every role has an allowed and a denied case on every collection', () => {
    const collections = new Set(CASES.map((c) => c[1]));
    for (const collection of collections) {
      for (const role of ['user', 'staff', 'admin']) {
        const expected = CASES.filter((c) => c[1] === collection && c[2] === role).map((c) => c[4]);
        if (!expected.includes('Allowed') || !expected.includes('Denied')) {
          throw new Error(`${collection}/${role} needs an allowed and a denied case`);
        }
      }
      if (!CASES.some((c) => c[1] === collection && c[2] === 'anonymous' && c[4] === 'Denied')) {
        throw new Error(`${collection}/anonymous needs a denied case`);
      }
    }
  });

  for (const [id, collection, role, operation, expected, op] of CASES) {
    test(`${id} ${collection} ${role}: ${operation} → ${expected}`, async () => {
      const db = as(ACTORS[role]);
      if (role === 'user' && id === 'R-30') {
        // Owner exports a fresh ID; the seeded one already exists.
        await env.withSecurityRulesDisabled((ctx) =>
          ctx.firestore().doc(`users/user1/report_exports/${EXPORT_ID}`).delete(),
        );
      }
      if (expected === 'Allowed') await assertSucceeds(op(db));
      else await assertFails(op(db));
      results.push({ id, collection, role, operation, expected, result: 'Pass' });
    });
  }
});
