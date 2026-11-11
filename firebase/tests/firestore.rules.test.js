// Security Rules tests: allowed and denied cases per role per collection.
// Run from firebase/: npm ci && npm run test:rules
// Payloads mirror toMap() of the models in lib/models/.
const { readFileSync } = require('node:fs');
const { resolve } = require('node:path');
const { after, before, beforeEach, describe, test } = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');

const RULES_FILE = process.env.RULES_FILE ?? resolve(__dirname, '../firestore.rules');
const CREATED_AT = '2026-11-02T14:12:07.034514';

let env;

const userDoc = (role = 'user', overrides = {}) => ({
  email: `${role}@example.test`,
  displayName: `Test ${role}`,
  photoUrl: null,
  role,
  createdAt: CREATED_AT,
  ...overrides,
});

const recipe = (overrides = {}) => ({
  name: 'Cá hồi áp chảo',
  description: 'Món test',
  category: 'ca',
  proteinGrams: 25,
  calories: 320.5,
  ingredients: [],
  instructions: ['Bước 1'],
  imageUrl: null,
  sourceNote: 'Nguồn test',
  ...overrides,
});

const SEVEN_DAYS = Array.from({ length: 7 }, (_, dayIndex) => ({ dayIndex }));

const mealPlan = (overrides = {}) => ({
  uid: 'alice',
  title: 'Thực đơn 7 ngày',
  targetCalories: 1800,
  targetProteinGrams: 55.5,
  status: 'draft',
  reviewerReason: null,
  days: SEVEN_DAYS,
  createdAt: CREATED_AT,
  ...overrides,
});

const announcement = (authorRole = 'staff', overrides = {}) => ({
  title: 'Thông báo',
  content: 'Nội dung',
  authorRole,
  targetRoles: ['admin', 'staff', 'user'],
  createdAt: CREATED_AT,
  ...overrides,
});

const db = (uid) =>
  (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();
const anon = () => db(null);
const alice = () => db('alice'); // role: user, owner of the seeded plans
const bob = () => db('bob'); // role: user, not the owner
const staff = () => db('staff1');
const admin = () => db('admin1');

// Writes test data directly, bypassing the rules.
const seed = (path, data) =>
  env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc(path).set(data));

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-longvita',
    firestore: { rules: readFileSync(RULES_FILE, 'utf8') },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await seed('users/alice', userDoc('user'));
  await seed('users/bob', userDoc('user'));
  await seed('users/staff1', userDoc('staff'));
  await seed('users/admin1', userDoc('admin'));
});

describe('default deny', () => {
  test('unknown collection is denied for every role', async () => {
    await seed('secrets/one', { value: 1 });
    await assertFails(anon().doc('secrets/one').get());
    await assertFails(alice().doc('secrets/one').get());
    await assertFails(admin().doc('secrets/one').get());
    await assertFails(admin().doc('secrets/two').set({ value: 2 }));
  });
});

describe('users', () => {
  describe('anonymous', () => {
    test('denied: read and create', async () => {
      await assertFails(anon().doc('users/alice').get());
      await assertFails(anon().doc('users/nobody').set(userDoc('user')));
    });
  });

  describe('user', () => {
    test('allowed: first sign-in creates own profile exactly as AuthService writes it', async () => {
      await assertSucceeds(db('carol').doc('users/carol').set(userDoc('user'), { merge: true }));
      await assertSucceeds(
        db('dave').doc('users/dave').set(userDoc('user', { photoUrl: 'https://example.test/a.png' })),
      );
    });

    test('denied: creating a profile with an elevated role or for someone else', async () => {
      await assertFails(db('carol').doc('users/carol').set(userDoc('admin')));
      await assertFails(db('carol').doc('users/carol').set(userDoc('staff')));
      await assertFails(db('carol').doc('users/dave').set(userDoc('user')));
    });

    test('denied: creating a profile with a bad shape', async () => {
      await assertFails(db('carol').doc('users/carol').set(userDoc('user', { isVip: true })));
      await assertFails(db('carol').doc('users/carol').set(userDoc('user', { displayName: '' })));
      await assertFails(db('carol').doc('users/carol').set(userDoc('user', { createdAt: 123 })));
    });

    test('allowed: read and edit own display fields', async () => {
      await assertSucceeds(alice().doc('users/alice').get());
      await assertSucceeds(alice().doc('users/alice').update({ displayName: 'Alice mới' }));
      await assertSucceeds(alice().doc('users/alice').update({ photoUrl: 'https://example.test/b.png' }));
    });

    test('denied: changing own role, email or createdAt', async () => {
      await assertFails(alice().doc('users/alice').update({ role: 'admin' }));
      await assertFails(alice().doc('users/alice').update({ email: 'x@example.test' }));
      await assertFails(alice().doc('users/alice').update({ createdAt: 'later' }));
    });

    test('denied: reading, editing or deleting another user', async () => {
      await assertFails(alice().doc('users/bob').get());
      await assertFails(alice().doc('users/bob').update({ displayName: 'Hacked' }));
      await assertFails(alice().doc('users/bob').delete());
      await assertFails(alice().doc('users/alice').delete());
    });
  });

  describe('staff', () => {
    test('allowed: read own profile for the role gate', async () => {
      await assertSucceeds(staff().doc('users/staff1').get());
    });

    test('denied: reading or listing other users (Appendix A: Self; admin)', async () => {
      await assertFails(staff().doc('users/alice').get());
      await assertFails(staff().collection('users').get());
    });

    test('denied: changing roles, own or others', async () => {
      await assertFails(staff().doc('users/alice').update({ role: 'staff' }));
      await assertFails(staff().doc('users/staff1').update({ role: 'admin' }));
      await assertFails(staff().doc('users/alice').delete());
    });
  });

  describe('admin', () => {
    test('allowed: read and list users, change another user role', async () => {
      await assertSucceeds(admin().doc('users/alice').get());
      await assertSucceeds(admin().collection('users').get());
      await assertSucceeds(admin().doc('users/alice').update({ role: 'staff' }));
    });

    test('denied: deleting a profile (Appendix A: no delete)', async () => {
      await assertFails(admin().doc('users/bob').delete());
      await assertFails(admin().doc('users/admin1').delete());
    });

    test('denied: changing own role (AUD-11)', async () => {
      await assertFails(admin().doc('users/admin1').update({ role: 'user' }));
    });

    test('denied: invalid role or editing other fields of another user', async () => {
      await assertFails(admin().doc('users/alice').update({ role: 'superadmin' }));
      await assertFails(admin().doc('users/alice').update({ email: 'x@example.test' }));
      await assertFails(admin().doc('users/alice').update({ role: 'staff', displayName: 'X' }));
    });
  });
});

describe('recipes', () => {
  beforeEach(async () => {
    await seed('recipes/r1', recipe());
  });

  test('anonymous denied: read and write', async () => {
    await assertFails(anon().doc('recipes/r1').get());
    await assertFails(anon().doc('recipes/r2').set(recipe()));
  });

  test('user allowed: read and query', async () => {
    await assertSucceeds(alice().doc('recipes/r1').get());
    await assertSucceeds(alice().collection('recipes').where('category', '==', 'ca').get());
  });

  test('user denied: create, update, delete', async () => {
    await assertFails(alice().doc('recipes/r2').set(recipe()));
    await assertFails(alice().doc('recipes/r1').update({ name: 'Đổi tên' }));
    await assertFails(alice().doc('recipes/r1').delete());
  });

  test('staff allowed: create, update, archive and restore', async () => {
    await assertSucceeds(staff().doc('recipes/r2').set(recipe()));
    await assertSucceeds(staff().doc('recipes/r1').update({ calories: 300 }));
    await assertSucceeds(staff().doc('recipes/r1').update({ isArchived: true }));
    await assertSucceeds(staff().doc('recipes/r1').update({ isArchived: false }));
    await assertSucceeds(staff().doc('recipes/r3').set(recipe({ isArchived: false })));
  });

  test('staff denied: hard delete (archive instead)', async () => {
    await assertFails(staff().doc('recipes/r1').delete());
  });

  test('staff denied: bad shape', async () => {
    await assertFails(staff().doc('recipes/r2').set(recipe({ calories: 'nhiều' })));
    await assertFails(staff().doc('recipes/r2').set(recipe({ extra: true })));
    await assertFails(staff().doc('recipes/r1').update({ name: '' }));
    await assertFails(staff().doc('recipes/r1').update({ isArchived: 'yes' }));
  });

  test('staff denied: oversized or negative values', async () => {
    await assertFails(staff().doc('recipes/r2').set(recipe({ name: 'x'.repeat(121) })));
    await assertFails(staff().doc('recipes/r2').set(recipe({ description: 'x'.repeat(2001) })));
    await assertFails(staff().doc('recipes/r2').set(recipe({ calories: -1 })));
    await assertFails(staff().doc('recipes/r2').set(recipe({ ingredients: Array(51).fill({}) })));
    await assertFails(staff().doc('recipes/r2').set(recipe({ instructions: Array(31).fill('b') })));
    await assertSucceeds(staff().doc('recipes/r2').set(recipe({ name: 'x'.repeat(120) })));
  });

  test('admin allowed: create and archive; denied: delete and bad shape', async () => {
    await assertSucceeds(admin().doc('recipes/r3').set(recipe()));
    await assertSucceeds(admin().doc('recipes/r3').update({ isArchived: true }));
    await assertFails(admin().doc('recipes/r3').delete());
    await assertFails(admin().doc('recipes/r4').set({ name: 'Thiếu trường' }));
  });
});

describe('meal_plans', () => {
  beforeEach(async () => {
    await seed('meal_plans/draft1', mealPlan());
    await seed('meal_plans/sub1', mealPlan({ status: 'submitted' }));
    await seed('meal_plans/app1', mealPlan({ status: 'approved' }));
  });

  describe('anonymous', () => {
    test('denied: read and create', async () => {
      await assertFails(anon().doc('meal_plans/draft1').get());
      await assertFails(anon().doc('meal_plans/new').set(mealPlan()));
    });
  });

  describe('owner', () => {
    test('allowed: create draft, read own, query own', async () => {
      await assertSucceeds(alice().collection('meal_plans').add(mealPlan()));
      await assertSucceeds(alice().doc('meal_plans/draft1').get());
      await assertSucceeds(alice().collection('meal_plans').where('uid', '==', 'alice').get());
    });

    test('allowed: saveMealPlan merge with the full payload while draft', async () => {
      await assertSucceeds(
        alice().doc('meal_plans/draft1').set(mealPlan({ title: 'Tên mới' }), { merge: true }),
      );
    });

    test('allowed: draft -> submitted, delete draft', async () => {
      await assertSucceeds(alice().doc('meal_plans/draft1').update({ status: 'submitted' }));
      await seed('meal_plans/draft2', mealPlan());
      await assertSucceeds(alice().doc('meal_plans/draft2').delete());
    });

    test('denied: create for someone else, as non-draft, or with a review', async () => {
      await assertFails(alice().doc('meal_plans/n1').set(mealPlan({ uid: 'bob' })));
      await assertFails(alice().doc('meal_plans/n2').set(mealPlan({ status: 'submitted' })));
      await assertFails(alice().doc('meal_plans/n3').set(mealPlan({ status: 'approved' })));
      await assertFails(alice().doc('meal_plans/n4').set(mealPlan({ reviewerReason: 'Tự duyệt' })));
    });

    test('denied: changing uid, createdAt or review on a draft (AUD-11)', async () => {
      await assertFails(alice().doc('meal_plans/draft1').update({ uid: 'bob' }));
      await assertFails(alice().doc('meal_plans/draft1').update({ createdAt: 'later' }));
      await assertFails(alice().doc('meal_plans/draft1').update({ reviewerReason: 'Tự duyệt' }));
    });

    test('denied: self-approving or skipping a status (AUD-11)', async () => {
      await assertFails(alice().doc('meal_plans/draft1').update({ status: 'approved' }));
      await assertFails(alice().doc('meal_plans/draft1').update({ status: 'rejected' }));
      await assertFails(alice().doc('meal_plans/draft1').update({ status: 'published' }));
    });

    test('denied: bad shape on update (AUD-11)', async () => {
      await assertFails(alice().doc('meal_plans/draft1').update({ isVip: true }));
      await assertFails(alice().doc('meal_plans/draft1').update({ targetCalories: 'nhiều' }));
      await assertFails(alice().doc('meal_plans/draft1').update({ title: '' }));
    });

    test('denied: oversized title, more than 7 days, negative targets', async () => {
      await assertFails(alice().doc('meal_plans/draft1').update({ title: 'x'.repeat(121) }));
      await assertFails(alice().doc('meal_plans/draft1').update({ days: Array(8).fill({}) }));
      await assertFails(alice().doc('meal_plans/draft1').update({ targetCalories: -5 }));
      await assertSucceeds(alice().doc('meal_plans/draft1').update({ days: Array(7).fill({}) }));
    });

    test('allowed: partial draft; denied: submitting fewer than 7 days', async () => {
      await assertSucceeds(alice().doc('meal_plans/partial').set(mealPlan({ days: [] })));
      await assertSucceeds(alice().doc('meal_plans/partial').update({ days: SEVEN_DAYS.slice(0, 3) }));
      await assertFails(alice().doc('meal_plans/partial').update({ status: 'submitted' }));
      await assertSucceeds(
        alice().doc('meal_plans/partial').update({ days: SEVEN_DAYS, status: 'submitted' }),
      );
    });

    test('denied: editing, resetting or deleting after submit', async () => {
      await assertFails(alice().doc('meal_plans/sub1').update({ title: 'Sửa sau khi gửi' }));
      await assertFails(alice().doc('meal_plans/sub1').update({ status: 'draft' }));
      await assertFails(alice().doc('meal_plans/sub1').update({ status: 'approved' }));
      await assertFails(alice().doc('meal_plans/sub1').delete());
    });
  });

  describe('other user', () => {
    test('denied: read, update, delete', async () => {
      await assertFails(bob().doc('meal_plans/draft1').get());
      await assertFails(bob().doc('meal_plans/draft1').update({ title: 'X' }));
      await assertFails(bob().doc('meal_plans/draft1').delete());
      await assertFails(bob().collection('meal_plans').where('uid', '==', 'alice').get());
    });
  });

  for (const [name, reviewer] of [['staff', staff], ['admin', admin]]) {
    describe(name, () => {
      test('allowed: read, approve and reject submitted plans', async () => {
        await assertSucceeds(reviewer().doc('meal_plans/sub1').get());
        await assertSucceeds(
          reviewer().doc('meal_plans/sub1').update({ status: 'approved', reviewerReason: 'Đạt' }),
        );
        await seed('meal_plans/sub2', mealPlan({ status: 'submitted' }));
        await assertSucceeds(reviewer().doc('meal_plans/sub2').update({ status: 'approved' }));
        await seed('meal_plans/sub3', mealPlan({ status: 'submitted' }));
        await assertSucceeds(
          reviewer().doc('meal_plans/sub3').update({ status: 'rejected', reviewerReason: 'Thiếu đạm' }),
        );
      });

      test('denied: rejecting without a reason or with a reason over 500 chars', async () => {
        await assertFails(reviewer().doc('meal_plans/sub1').update({ status: 'rejected' }));
        await assertFails(
          reviewer().doc('meal_plans/sub1').update({ status: 'rejected', reviewerReason: '' }),
        );
        await assertFails(
          reviewer()
            .doc('meal_plans/sub1')
            .update({ status: 'rejected', reviewerReason: 'x'.repeat(501) }),
        );
      });

      test('denied: approving a submitted plan with fewer than 7 days', async () => {
        await seed('meal_plans/short', mealPlan({ status: 'submitted', days: SEVEN_DAYS.slice(0, 6) }));
        await assertFails(reviewer().doc('meal_plans/short').update({ status: 'approved' }));
      });

      test('allowed: review queue query of submitted plans (Web TV-02)', async () => {
        await assertSucceeds(
          reviewer().collection('meal_plans').where('status', '==', 'submitted').get(),
        );
      });

      test('denied: reviewing a plan not in submitted, or changing the plan content', async () => {
        await assertFails(reviewer().doc('meal_plans/draft1').update({ status: 'approved' }));
        await assertFails(reviewer().doc('meal_plans/app1').update({ status: 'rejected', reviewerReason: 'Đổi ý' }));
        await assertFails(reviewer().doc('meal_plans/sub1').update({ status: 'approved', title: 'Sửa' }));
        await assertFails(reviewer().doc('meal_plans/sub1').update({ uid: 'bob' }));
        await assertFails(reviewer().doc('meal_plans/sub1').delete());
      });
    });
  }
});

describe('announcements', () => {
  beforeEach(async () => {
    await seed('announcements/a1', announcement());
  });

  test('anonymous denied: read and write', async () => {
    await assertFails(anon().doc('announcements/a1').get());
    await assertFails(anon().doc('announcements/a2').set(announcement()));
  });

  test('user allowed: read and stream', async () => {
    await assertSucceeds(alice().doc('announcements/a1').get());
    await assertSucceeds(alice().collection('announcements')
      .where('targetRoles', 'array-contains', 'user').get());
  });

  test('each account reads only announcements targeting its role', async () => {
    await seed('announcements/admin-only', announcement('admin', { targetRoles: ['admin'] }));
    await assertFails(alice().doc('announcements/admin-only').get());
    await assertFails(staff().doc('announcements/admin-only').get());
    await assertSucceeds(admin().doc('announcements/admin-only').get());
  });

  test('user denied: create, update, delete', async () => {
    await assertFails(alice().doc('announcements/a2').set(announcement('staff')));
    await assertFails(alice().doc('announcements/a1').update({ title: 'X' }));
    await assertFails(alice().doc('announcements/a1').delete());
  });

  test('staff allowed: create, edit text, delete', async () => {
    await assertSucceeds(staff().doc('announcements/a2').set(announcement('staff')));
    await assertSucceeds(staff().doc('announcements/a1').update({ title: 'Tiêu đề mới' }));
    await assertSucceeds(staff().doc('announcements/a1').delete());
  });

  test('staff denied: posing as admin, bad shape, changing author or date', async () => {
    await assertFails(staff().doc('announcements/a2').set(announcement('admin')));
    await assertFails(staff().doc('announcements/a2').set(announcement('staff', { title: '' })));
    await assertFails(staff().doc('announcements/a2').set(announcement('staff', { pinned: true })));
    await assertFails(staff().doc('announcements/a2').set(announcement('staff', { targetRoles: [] })));
    await assertFails(staff().doc('announcements/a2').set(announcement('staff', { targetRoles: ['owner'] })));
    await assertFails(staff().doc('announcements/a1').update({ createdAt: 'later' }));
    await assertFails(staff().doc('announcements/a2').set(announcement('staff', { title: 'x'.repeat(121) })));
    await assertFails(staff().doc('announcements/a2').set(announcement('staff', { content: 'x'.repeat(2001) })));
  });

  test('admin allowed: create; denied: posing as staff', async () => {
    await assertSucceeds(admin().doc('announcements/a3').set(announcement('admin')));
    await assertFails(admin().doc('announcements/a4').set(announcement('staff')));
  });
});


// NC-02: PDF metadata is independent of profile access and plan edit rights.
describe('report export metadata', () => {
  const id = 'pdf_20261109T040000Z_0123456789abcdef';
  const path = `users/alice/report_exports/${id}`;
  const payload = (overrides = {}) => ({
    exportId: id,
    planId: 'alice-plan',
    createdAt: '2026-11-09T04:00:00.000Z',
    fileName: `${id}.pdf`,
    sizeBytes: 20000,
    schemaVersion: 1,
    ...overrides,
  });

  beforeEach(async () => {
    await seed('meal_plans/alice-plan', mealPlan());
    await seed('meal_plans/bob-plan', mealPlan({uid: 'bob'}));
  });

  test('owner creates and reads saved-plan metadata and lists own exports', async () => {
    await assertSucceeds(alice().doc(path).set(payload()));
    const saved = await assertSucceeds(alice().doc(path).get());
    require('node:assert/strict').deepEqual(saved.data(), payload());
    await assertSucceeds(alice().collection('users/alice/report_exports').get());
  });

  test('unsaved plans use explicit null, including for an owner with no profile', async () => {
    await assertSucceeds(alice().doc(path).set(payload({planId: null})));
    await assertSucceeds(db('new-owner').doc(`users/new-owner/report_exports/${id}`)
      .set(payload({planId: null})));
  });

  test('anonymous and other roles cannot read, list, create, update or delete', async () => {
    await seed(path, payload());
    // Access to the parent profile is deliberately different from this subcollection.
    await assertSucceeds(admin().doc('users/alice').get());
    for (const context of [anon(), bob(), staff(), admin()]) {
      await assertFails(context.doc(path).get());
      await assertFails(context.collection('users/alice/report_exports').get());
      await assertFails(context.doc(path).set(payload()));
      await assertFails(context.doc(path).delete());
      await assertFails(context.doc('users/alice/report_exports/' + id.replace('abcdef', 'abcdee'))
        .set(payload({exportId: id.replace('abcdef', 'abcdee'),
          fileName: id.replace('abcdef', 'abcdee') + '.pdf'})));
    }
  });

  test('both size boundaries are accepted, outside values and wrong fields are denied', async () => {
    for (const sizeBytes of [1, 10485760]) {
      await env.clearFirestore();
      await assertSucceeds(alice().doc(path).set(payload({planId: null, sizeBytes})));
    }
    await env.clearFirestore();
    for (const change of [
      {sizeBytes: 0}, {sizeBytes: -1}, {sizeBytes: 10485761},
      {sizeBytes: '20000'}, {sizeBytes: 1.5},
      {schemaVersion: 2}, {schemaVersion: '1'}, {schemaVersion: true},
      {fileName: 'private-uid.pdf'}, {exportId: 'different-id'},
      {createdAt: null}, {createdAt: '2026-11-09T04:00:00+00:00'},
      {planId: ''}, {planId: 1}, {planId: 'parent/child'},
      {uid: 'alice'}, {email: 'not-allowed@example.test'},
      {filePath: '/device/private'}, {downloadUrl: 'https://example.test/token'},
    ]) {
      await assertFails(alice().doc(path).set(payload({planId: null, ...change})));
    }
    for (const key of Object.keys(payload())) {
      const missing = payload({planId: null});
      delete missing[key];
      await assertFails(alice().doc(path).set(missing));
    }
  });

  test('malformed document IDs and leaked UID-shaped names are denied', async () => {
    for (const wrong of ['alice_plan_123', 'pdf_20261109_0123456789abcdef',
      'pdf_20261109T040000Z_0123456789abcdeG']) {
      await assertFails(alice().doc(`users/alice/report_exports/${wrong}`)
        .set(payload({exportId: wrong, fileName: `${wrong}.pdf`, planId: null})));
    }
  });

  test('a missing or foreign plan cannot be referenced, regardless of plan status', async () => {
    for (const planId of ['missing-plan', 'bob-plan']) {
      await assertFails(alice().doc(path).set(payload({planId})));
    }
    for (const status of ['draft', 'submitted', 'approved', 'rejected']) {
      await env.withSecurityRulesDisabled(async (ctx) => {
        await ctx.firestore().doc(path).delete();
        await ctx.firestore().doc('meal_plans/alice-plan').set(mealPlan({status}));
      });
      await assertSucceeds(alice().doc(path).set(payload()));
    }
  });

  test('same payload is a no-op retry, but every attempted mutation is denied', async () => {
    await assertSucceeds(alice().doc(path).set(payload()));
    await assertSucceeds(alice().doc(path).set(payload()));
    for (const change of [
      {sizeBytes: 20001}, {createdAt: '2026-11-10T04:00:00.000Z'},
      {planId: null}, {planId: 'bob-plan'}, {fileName: 'another.pdf'},
      {schemaVersion: 2}, {uid: 'alice'},
    ]) {
      await assertFails(alice().doc(path).set(payload(change)));
    }
  });

  test('history and the identical retry survive deletion of the original plan', async () => {
    await assertSucceeds(alice().doc(path).set(payload()));
    await env.withSecurityRulesDisabled((ctx) =>
      ctx.firestore().doc('meal_plans/alice-plan').delete());
    await assertSucceeds(alice().doc(path).get());
    await assertSucceeds(alice().doc(path).set(payload()));
    const nextId = id.replace('abcdef', 'abcdee');
    await assertFails(alice().doc(`users/alice/report_exports/${nextId}`).set(
      payload({exportId: nextId, fileName: `${nextId}.pdf`})));
  });

  test('owner deletion and updates to malformed pre-existing metadata are denied', async () => {
    await seed(path, payload());
    await assertFails(alice().doc(path).delete());
    const broken = payload({schemaVersion: 2});
    await seed(path, broken);
    await assertFails(alice().doc(path).set(broken));
  });
});
