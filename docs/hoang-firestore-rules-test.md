# Hoàng — Firestore Security Rules Emulator Evidence

Verified: 2026-11-04, Windows ASUS, Firebase Emulator CLI 15.34.2 + @firebase/rules-unit-testing 6.0.0 + firebase 13.2.0 + JDK 21.

## Real local run
- Source rules: firebase/firestore.rules (NOT deployed).
- Config: firebase.emulator.json points only to emulator host 127.0.0.1:8185.
- Project ID: demo-longvita. This is a synthetic Firebase project namespace; do not use the real longvita-8da7e project in unit tests.
- Test: test/firestore/hoang_rules.test.cjs.
- Result: **22/22 PASS, 0 FAIL**, exit code 0. All PERMISSION_DENIED logs correspond to intentionally rejected requests. Emulator stopped after the run.
- Cases: owner and other UID, anonymous denial, valid shopping checklist create/update/delete, forbidden cross-user writes, UID/planId tampering, missing list data, >500 list rows, draft plan creation/submission, staff approval, forbidden self-approval.
- This is local emulator-side evidence. It does not prove production rules are deployed or that actual Firebase auth works on Android.

## Reproduce on Windows from repository root
Install Node.js 24 and JDK 21 (Java available via PATH or JAVA_HOME). Then run in PowerShell:

    npm install --prefix test\firestore --no-audit --no-fund
    npm --prefix test\firestore test

The script invokes Firebase CLI using --project demo-longvita and ../../firebase.emulator.json; rule tests only touch the local emulator. Do not use the production Firebase project or run firebase deploy without team approval.

## Technical constraints and next decisions
- Firestore Rules enforce shopping_lists/{uid}/plans/{planId} owner identity, top-level schema and items list size <=500. They cannot validate every nested map inside an arbitrary-length list: Firestore Security Rules have no general-purpose loop or element-wise type checker. The client checks positive finite amounts, but a malicious authenticated client could insert a malformed nested element into its own shopping-list document.
- For strict server-side ingredient validation, migrate to one ingredient per document, e.g. shopping_lists/{uid}/plans/{planId}/items/{itemId}, with per-document validation. This requires team review, coordinated service/model changes, migration and native E2E tests. Do not silently change the existing schema.
- Rules allow meal_plans.days as a list without checking seven entries on the server; DataService enforces seven at client level. Strict server-side validation would likewise require coordinated contract changes.
- Emulator evidence does not replace native Android/Google Sign-In tests or Firebase deployment audit.

Official reference: https://firebase.google.com/docs/firestore/security/rules-fields — list entries may be inspected individually, but generic element-wise validation is unavailable.
