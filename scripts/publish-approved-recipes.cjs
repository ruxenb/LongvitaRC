#!/usr/bin/env node
'use strict';

/**
 * CREATE-ONLY Firestore publisher. Defaults to local dry-run; --apply requires
 * an actually approved, blocker-free catalog and explicit target safeguards.
 * Never logs tokens, never uses update/patch/delete, and never modifies rules.
 */
const fs = require('node:fs');
const { validate, fingerprint } = require('./validate-recipe-intake.cjs');

const PROJECT = 'longvita-8da7e';
const COLLECTION = 'recipes';
const ORIGIN = 'https://firestore.googleapis.com/v1';

function assert(condition, message) {
  if (!condition) throw new Error(message);
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
  throw new Error('Unsupported Firestore field type');
}

function encodeFields(obj) {
  return Object.fromEntries(Object.entries(obj).map(([key, value]) => [key, encodeValue(value)]));
}

/**
 * Safe strict roundtrip for the current RecipeModel schema (double numbers).
 * A review mismatch aborts; it is never repaired by overwrite.
 */
function decodeValue(value) {
  if ('nullValue' in value) return null;
  if ('stringValue' in value) return value.stringValue;
  if ('booleanValue' in value) return value.booleanValue;
  if ('doubleValue' in value) return Number(value.doubleValue);
  if ('integerValue' in value) return Number(value.integerValue);
  if ('arrayValue' in value) return (value.arrayValue.values || []).map(decodeValue);
  if ('mapValue' in value) return decodeFields(value.mapValue.fields || {});
  throw new Error('Unexpected server value type');
}

function decodeFields(fields) {
  return Object.fromEntries(Object.entries(fields).map(([key, value]) => [key, decodeValue(value)]));
}

function canonical(value) {
  if (Array.isArray(value)) return value.map(canonical);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.keys(value).sort().map(key => [key, canonical(value[key])]));
  }
  return value;
}

function readManifest(path) {
  const catalog = JSON.parse(fs.readFileSync(path, 'utf8'));
  assert(catalog.projectId === PROJECT && catalog.collection === COLLECTION, 'Wrong project/collection');
  const reviewErrors = validate(catalog, false);
  assert(reviewErrors.length === 0, 'Structural/data review failed:\n' + reviewErrors.join('\n'));
  return catalog;
}

function publicationGuard(catalog, sha, opts) {
  assert(opts.project === PROJECT, 'Explicit --project longvita-8da7e required');
  assert(sha === fingerprint(catalog.recipes), 'Explicit --sha does not match reviewed recipes');
  assert(opts.ack === 'PUBLISH_APPROVED_RECIPES_TO_SHARED_FIRESTORE',
    'Explicit --ack-live PUBLISH_APPROVED_RECIPES_TO_SHARED_FIRESTORE required');
  assert(catalog.publicationAuthorized === true, 'Batch still marked publicationAuthorized=false');
  const errs = validate(catalog, true);
  assert(errs.length === 0, 'Publication gate failed:\n' + errs.join('\n'));
}

function parseArgs(args) {
  const out = { apply: false };
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === '--apply') out.apply = true;
    else if (['--file','--project','--sha','--ack-live'].includes(a)) {
      assert(i + 1 < args.length, 'Missing value for ' + a);
      out[a === '--ack-live' ? 'ack' : a.slice(2)] = args[++i];
    } else throw new Error('Unexpected flag: ' + a);
  }
  assert(out.file, 'Provide --file path/to/approved-catalog.json');
  return out;
}

async function request(url, method, body, token, fetchFn) {
  const response = await fetchFn(url, {
    method,
    headers: {
      Authorization: 'Bearer ' + token,
      'Content-Type': 'application/json',
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
    signal: AbortSignal.timeout(15000),
  });
  if (response.status === 404) return { missing: true };
  if (!response.ok) throw new Error('Firestore returned HTTP ' + response.status + ' for ' + method);
  return { data: await response.json() };
}

/**
 * Does not overwrite documents. A 409 during POST is an error, not a retry.
 * The preflight ensures no duplicate ID exists before the first write.
 */
async function createOnly(catalog, token, fetchFn = fetch) {
  const parent = ORIGIN + '/projects/' + PROJECT + '/databases/(default)/documents/';
  const docs = catalog.recipes.map(r => ({
    id: r.id, data: r.firestore,
    url: parent + COLLECTION + '/' + encodeURIComponent(r.id),
  }));
  for (const item of docs) {
    const res = await request(item.url, 'GET', null, token, fetchFn);
    assert(res.missing === true, 'Document ' + item.id + ' already exists. No overwrite allowed.');
  }
  const created = [];
  for (const item of docs) {
    const url = parent + COLLECTION + '?documentId=' + encodeURIComponent(item.id);
    const res = await request(url, 'POST', { fields: encodeFields(item.data) }, token, fetchFn);
    assert(res.data && res.data.name && res.data.name.endsWith('/' + item.id),
      'Create response did not match expected ID ' + item.id);
    created.push(item.id);
    const verified = await request(item.url, 'GET', null, token, fetchFn);
    assert(verified.data && JSON.stringify(canonical(decodeFields(verified.data.fields))) === JSON.stringify(canonical(item.data)),
      'Readback mismatch for ' + item.id + '. Manual reconciliation required.');
  }
  return created;
}

async function main(args, env = process.env, fetchFn = fetch) {
  const opts = parseArgs(args);
  const catalog = readManifest(opts.file);
  const sha = fingerprint(catalog.recipes);
  console.log('Project: ' + PROJECT + ' / collection: ' + COLLECTION);
  console.log('Candidate IDs: ' + catalog.recipes.map(r => r.id).join(', '));
  console.log('Exact batch SHA256: ' + sha);
  if (!opts.apply) {
    console.log('DRY-RUN ONLY. NO Firebase authentication or network request performed.');
    console.log('Publish blockers: ' + validate(catalog, true).length +
      '; publicationAuthorized=' + String(catalog.publicationAuthorized));
    return { dryRun: true, sha };
  }
  publicationGuard(catalog, opts.sha, opts);
  const token = env.FIRESTORE_ACCESS_TOKEN;
  assert(token && typeof token === 'string', 'No valid FIRESTORE_ACCESS_TOKEN provided by the authorized operator');
  const created = await createOnly(catalog, token, fetchFn);
  console.log('CREATE-ONLY SUCCESS: ' + created.length + ' documents verified by readback.');
  return { dryRun: false, created, sha };
}

if (require.main === module) {
  main(process.argv.slice(2)).catch(error => {
    console.error('BLOCKED: ' + error.message);
    process.exitCode = 1;
  });
}

module.exports = { encodeValue, encodeFields, decodeValue, decodeFields, parseArgs,
  publicationGuard, readManifest, createOnly, main };
