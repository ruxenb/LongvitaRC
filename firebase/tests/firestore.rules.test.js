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

const mealPlan = (overrides = {}) => ({
  uid: 'alice',
  title: 'Thực đơn 7 ngày',
  targetCalories: 1800,
  targetProteinGrams: 55.5,
  status: 'draft',
  reviewerReason: null,
  days: [],
  createdAt: CREATED_AT,
  ...overrides,
});

const announcement = (authorRole = 'staff', overrides = {}) => ({
  title: 'Thông báo',
  content: 'Nội dung',
  authorRole,
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
    test('allowed: read any user', async () => {
      await assertSucceeds(staff().doc('users/alice').get());
    });

    test('denied: changing roles, own or others', async () => {
      await assertFails(staff().doc('users/alice').update({ role: 'staff' }));
      await assertFails(staff().doc('users/staff1').update({ role: 'admin' }));
      await assertFails(staff().doc('users/alice').delete());
    });
  });

  describe('admin', () => {
    test('allowed: change another user role, read and delete', async () => {
      await assertSucceeds(admin().doc('users/alice').get());
      await assertSucceeds(admin().doc('users/alice').update({ role: 'staff' }));
      await assertSucceeds(admin().doc('users/bob').delete());
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

  test('staff allowed: create, update, delete', async () => {
    await assertSucceeds(staff().doc('recipes/r2').set(recipe()));
    await assertSucceeds(staff().doc('recipes/r1').update({ calories: 300 }));
    await assertSucceeds(staff().doc('recipes/r1').delete());
  });

  test('staff denied: bad shape', async () => {
    await assertFails(staff().doc('recipes/r2').set(recipe({ calories: 'nhiều' })));
    await assertFails(staff().doc('recipes/r2').set(recipe({ extra: true })));
    await assertFails(staff().doc('recipes/r1').update({ name: '' }));
  });

  test('admin allowed: create and delete; denied: bad shape', async () => {
    await assertSucceeds(admin().doc('recipes/r3').set(recipe()));
    await assertSucceeds(admin().doc('recipes/r3').delete());
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

      test('denied: rejecting without a reason', async () => {
        await assertFails(reviewer().doc('meal_plans/sub1').update({ status: 'rejected' }));
        await assertFails(
          reviewer().doc('meal_plans/sub1').update({ status: 'rejected', reviewerReason: '' }),
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
    await assertSucceeds(alice().collection('announcements').orderBy('createdAt', 'desc').limit(20).get());
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
    await assertFails(staff().doc('announcements/a1').update({ createdAt: 'later' }));
  });

  test('admin allowed: create; denied: posing as staff', async () => {
    await assertSucceeds(admin().doc('announcements/a3').set(announcement('admin')));
    await assertFails(admin().doc('announcements/a4').set(announcement('staff')));
  });
});
