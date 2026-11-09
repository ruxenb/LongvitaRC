# NC-02 — PDF metadata model/repository and rules, 09/11/2026

Code: `8f2bf6a`, built on PM contract `61fcfdd` / main `92bac93`. This step does not wire the repository into Profile or change default PDF/Analytics behavior; those are NC-03/04.

## Implemented

- `ReportMetadata`: six immutable fields, owner-independent export name, UTC capture, stable retry payload, path/UTF-8/size/type checks. New-export random ID generation is injectable for testing; random IDs are not a mathematical no-collision guarantee.
- Separate metadata repository, full document set without merge, no timeout/retry loop; the original SDK Future is observed until acknowledgement or rejection. SDK failures use the existing typed DataFailure.
- New `users/{uid}/report_exports/{exportId}` rules: owner-only including against other staff/admin accounts; create validates shape and saved-plan ownership, identical retry validates shape/equality without rereading a deleted plan; mutations/deletion denied. Existing collection rules unchanged.
- No `main.dart`, Profile, Storage adapter, Analytics, pubspec or production configuration changes. The three partial files and rules left by Claude were preserved in a local handoff snapshot, reviewed and completed by Codex.

## Checks

See [test-summary.txt](test-summary.txt) and [verification.json](verification.json).

- 411 Flutter tests, 11 metadata tests, analyzer lib/test clean.
- 64 Firebase rules tests:50 Firestore (41 existing +9 new groups),14 unchanged Storage. The nine metadata groups cover multiple malformed payloads/roles and owner-only/read/list/create/update/delete paths.
- Hoang's unchanged rules script:22/22 using shared firebase/node_modules (Firebase JS13.1.0); its subproject declares13.2.0, which was not installed/upgraded for this run. This is explicitly the available client runtime, not a claim that its13.2.0 lockfile was exercised.
- With baseline rules61fcfdd,6/9 new metadata groups fail;3 deny-only groups naturally pass. Restoring current rules gives9/9. No production rules were deployed for this comparison.

## Android SDK probes S1/S2

[Portable QA entry point](../../../test/qa/report_metadata_sdk_probe.dart) runs in a separate minimal Android app, `vn.edu.fpt.longvita.qa.nc02_probe`, on AVD LocalMate_API_35 / Android15. Dependencies are firebase_core3.15.2, firebase_auth5.7.0, cloud_firestore5.6.12. Its source imports the actual checked-out metadata repository/model; the probe is not a JS SDK or fake gateway test. A formatted copy promoted into the tracked QA entry point was rebuilt and rerun successfully; [verification.json](verification.json) records the final APK/source hashes.

Targets: Auth127.0.0.1:9099 and Firestore127.0.0.1:8185 via Android10.0.2.2, demo-longvita only. The API key and app ID in the host are deliberately dummy emulator configuration. No production credentials, Google picker, or Firebase project writes are used.

Results in [sdk-observations.json](sdk-observations.json):

1. **S1 offline:** local document has pending writes; original save Future remains pending; independent server GET sees no document.
2. **S1 online:** the same Future confirms; client server-source read and independent REST read match; exactly one document.
3. **S2 A offline:** one original A write pending, absent from server.
4. **S2 B online:** B's own server-source read finds no record; the original A Future remains pending, and independent server GET finds neither A nor B record.
5. **S2 A returns:** the original A Future confirms and A server data matches; B record still absent; no replacement write was issued.

The administrative REST requests in this QA probe are GET-only, independent observations. Tested metadata writes all use the actual client repository/Firebase Auth; no admin write is substituted for rules verification. Two dummy Auth Emulator users are created per run. These observations apply to the pinned Android SDK combination, not all SDKs/platforms. UI epoch behavior is not implemented or claimed tested here; NC-03 still must guard callbacks.

## Reproduction

1. Start local demo-longvita Auth/Firestore emulators on9099/8185 with the checked-out firebase/firestore.rules. For the full legacy rules suite include Storage9199. Keep production services disconnected.
2. Run Firebase tests with FIRESTORE_EMULATOR_HOST=127.0.0.1:8185 and FIREBASE_STORAGE_EMULATOR_HOST=127.0.0.1:9199: `node --test firebase/tests/firestore.rules.test.js firebase/tests/storage.rules.test.js`. Hoang's script already targets8185; supply the intended node_modules runtime and record its version.
3. Create a disposable Flutter Android host under an ignored local QA directory using `flutter create --no-pub --platforms android --project-name nc02_probe --org vn.edu.fpt.longvita.qa <scratch>`. Keep its unique applicationId; do not install over vn.edu.fpt.longvita. Set its pubspec to Flutter plus the three exact FlutterFire versions above. No path dependency on the full production app is needed.
4. Set scratch/lib/main.dart to export the file URI of the actual `test/qa/report_metadata_sdk_probe.dart`. For example, Python `Path(probe_path).resolve().as_uri()` produces the correctly escaped host file URI. The documented relative lib imports are intentional so this minimal host compiles the checked-out source; two narrow lint suppressions apply only to this QA file.
5. In the scratch debug AndroidManifest allow INTERNET and cleartext to local emulator hosts. `flutter pub get --offline`, `flutter build apk --debug --no-pub`, install that isolated APK on an Android AVD and launch its MainActivity. Read the six `NC02` JSON checkpoints from logcat. A fresh unique dummy Auth identity is used each run; personal app/auth data is untouched.
6. Stop the isolated QA app/device and emulators after collecting results. Do not clear personal app data or deploy these test fixtures.

## Scope and privacy

Logs here are filtered summaries/checkpoints; raw logs, generated QA host, handoff snapshot and APK stay local ignored. No real UID/email/token is published. Existing UI test screenshots generated by this run are archived locally rather than deleted. Existing Longvita app/data and the user's six report-drafts deletions remain unchanged. Final app transition and production metadata deployment remain future steps; NC-02 is ready for PM review, not Final feature acceptance.
