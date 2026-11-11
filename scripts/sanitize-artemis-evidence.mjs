import fs from 'node:fs';

const target = process.argv[2];
if (!target) {
  throw new Error('Usage: node scripts/sanitize-artemis-evidence.mjs <jsonl>');
}

const original = fs.readFileSync(target, 'utf8');
const sanitized = original
  .replace(/([?&]token=)[^&"\\\s`]+/gi, '$1<redacted-storage-token>')
  .replace(/reports%2F[^%"\\\s`]+%2F/gi, 'reports%2F<redacted-uid>%2F')
  .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, '<redacted-email>')
  .replace(/Pham Van Minh(?: \(K18 HCM\))?/g, '<redacted-user>');

if (sanitized === original) {
  console.log('No matching sensitive values found.');
  process.exit(0);
}

fs.writeFileSync(target, sanitized, 'utf8');
console.log(`Sanitized ${target}.`);
