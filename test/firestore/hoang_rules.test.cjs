'use strict';

// Local Firestore Security Rules integration test.
// Run ONLY against the demo-longvita emulator. No production Firebase writes.
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, updateDoc, deleteDoc} = require('firebase/firestore');

const root = path.resolve(__dirname, '..', '..');
const rules = fs.readFileSync(path.join(root, 'firebase', 'firestore.rules'), 'utf8');
const projectId = 'demo-longvita';
let pass = 0, fail = 0;

async function check(name, action, shouldPass = true) {
  try {
    await (shouldPass ? assertSucceeds(action()) : assertFails(action()));
    pass++;
    console.log('PASS ' + name);
  } catch (error) {
    fail++;
    console.error('FAIL ' + name + ': ' + (error && error.message || error));
  }
}

async function main() {
  const env = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8185,
      rules,
    },
  });
  try {
    await env.clearFirestore();
    const user = env.authenticatedContext('alice').firestore();
    const other = env.authenticatedContext('bob').firestore();
    const staff = env.authenticatedContext('staff').firestore();
    const unauth = env.unauthenticatedContext().firestore();

    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users', 'staff'), {
        displayName: 'Test Staff', email: 'staff@example.invalid',
        role: 'staff', createdAt: '2026-11-04T00:00:00.000Z',
      });
    });
    const validList = {
      uid: 'alice', planId: 'p1',
      updatedAt: '2026-11-04T00:00:00.000Z',
      items: [{id: 'carrot', name: 'Cà rốt', amount: 150,
               unit: 'g', category: 'rau_cu', isPurchased: false}],
    };
    const ownList = doc(user, 'shopping_lists', 'alice', 'plans', 'p1');
    const foreignList = doc(other, 'shopping_lists', 'alice', 'plans', 'p1');
    const anonymousList = doc(unauth, 'shopping_lists', 'alice', 'plans', 'p1');

    await check('owner creates shopping list', () => setDoc(ownList, validList));
    await check('owner reads shopping list', () => getDoc(ownList));
    await check('other account cannot read shopping list', () => getDoc(foreignList), false);
    await check('anonymous account cannot read shopping list', () => getDoc(anonymousList), false);
    await check('other account cannot alter shopping list',
      () => setDoc(foreignList, {...validList, items: []}), false);
    await check('owner cannot spoof path uid',
      () => setDoc(ownList, {...validList, uid: 'bob'}), false);
    await check('owner cannot spoof path plan id',
      () => setDoc(ownList, {...validList, planId: 'wrong'}), false);
    await check('owner cannot omit items',
      () => setDoc(ownList, {uid: 'alice', planId: 'p1', updatedAt: '2026-11-04T00:00:00.000Z'}), false);
    await check('owner cannot exceed 500 shopping rows',
      () => setDoc(ownList, {...validList, items: Array.from({length: 501}, (_, i) => ({id: String(i)}))}), false);
    await check('owner updates valid shopping list',
      () => updateDoc(ownList, {items: []}));
    await check('other account cannot delete shopping list',
      () => deleteDoc(foreignList), false);
    await check('owner deletes shopping list',
      () => deleteDoc(ownList));

    const planData = {
      uid: 'alice', title: 'Test plan', targetCalories: 1800,
      targetProteinGrams: 50, status: 'draft',
      reviewerReason: null, days: [],
      createdAt: '2026-11-04T00:00:00.000Z',
    };
    const ownPlan = doc(user, 'meal_plans', 'p1');
    const foreignPlan = doc(other, 'meal_plans', 'p1');
    await check('owner creates draft', () => setDoc(ownPlan, planData));
    await check('owner reads own meal plan', () => getDoc(ownPlan));
    await check('other account cannot read meal plan', () => getDoc(foreignPlan), false);
    await check('staff reads plan when staff role exists',
      () => getDoc(doc(staff,'meal_plans','p1')));
    await check('owner cannot create already approved plan',
      () => setDoc(doc(user, 'meal_plans', 'p2'), {...planData,status:'approved'}), false);
    await check('owner cannot rewrite uid',
      () => updateDoc(ownPlan, {uid:'bob'}), false);
    await check('owner can submit draft',
      () => updateDoc(ownPlan, {status:'submitted'}));
    await check('owner cannot approve own submitted plan',
      () => updateDoc(ownPlan, {status:'approved'}), false);
    await check('staff can approve submitted plan',
      () => updateDoc(doc(staff,'meal_plans','p1'), {status:'approved'}));
    await check('owner cannot delete approved plan',
      () => deleteDoc(ownPlan), false);

    console.log('Firestore rules: ' + pass + ' pass, ' + fail + ' fail');
    if (fail) process.exitCode = 1;
  } finally {
    await env.cleanup();
  }
}
main().catch((e) => {
  console.error('SETUP/EMULATOR FAILURE: ' + (e && e.stack || e));
  process.exitCode = 1;
});
