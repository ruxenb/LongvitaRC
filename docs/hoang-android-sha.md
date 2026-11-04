# LongvitaRC — Android Debug SHA fingerprints on laptop ASUS

Verified 2026-11-04 with Java 21 keytool on this laptop. These fingerprints refer to the **local Android Debug certificate**, not to a release APK or Google Play App Signing key.

## Certificate and command
- Keystore: C:\Users\ASUS\.android\debug.keystore
- Alias: androiddebugkey
- Owner: CN=Android Debug, O=Android, C=US
- Valid: 2026-11-04 through 2054-03-22 (local Java output)
- JDK: D:\Tools\Java21\jdk-21.0.13+9

PowerShell to verify (standard debug-keystore password):

    & 'D:\Tools\Java21\jdk-21.0.13+9\bin\keytool.exe' -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -storepass android -alias androiddebugkey

**SHA-1**
D3:BE:85:D5:84:A9:92:9D:46:23:D2:5F:AD:6C:10:71:18:77:7E:62

**SHA-256**
2F:BA:C1:BE:7E:38:64:DD:FC:E2:1D:31:61:4D:3A:44:F9:D4:F3:0A:DA:D9:6E:DB:7E:57:09:B4:09:CC:12:83

## Existing Android OAuth certificate hash DOES NOT MATCH
- Firebase project in checked-in android/app/google-services.json: longvita-8da7e
- Android package: vn.edu.fpt.longvita
- Registered Android OAuth SHA-1 in that config (normalised): 2B:AA:67:BC:4F:6B:FD:1D:AB:3E:BF:C5:E5:57:A9:BB:1E:D0:35:EC
- Current ASUS local SHA-1: D3:BE:85:D5:84:A9:92:9D:46:23:D2:5F:AD:6C:10:71:18:77:7E:62

This mismatch can prevent Google Sign-In from working in local Android builds. The checked-in config may be stale; validate in Firebase Console before declaring that the certificate is missing server-side.

## Required team-approved Firebase action
1. Open Firebase Console for project longvita-8da7e, Project settings > General > Your apps > Android vn.edu.fpt.longvita.
2. Add BOTH local Debug SHA-1 and SHA-256 above. **Keep existing fingerprints** belonging to other teammates/build machines. Do not delete or replace them.
3. Re-download the latest google-services.json for the same Android app and review it with the team before updating android/app/google-services.json.
4. Build and launch a real Android debug APK and test Google Account Picker + signed-in Home / sign out. Verify release signing separately.

## Critical signing note
The current android/app/build.gradle.kts release configuration uses signingConfigs.getByName("debug") with a TODO. That is acceptable only as a temporary lab/debug setup; a distributable production release needs a dedicated release signing arrangement and may have different SHA fingerprints. Do not assume the Debug SHA fingerprints cover release/Play App Signing.

## Current status
- The keystore was **read only**; it was not regenerated, deleted or overwritten.
- No Firebase Console fingerprint registration or production write was made.
- No Android SDK licenses were accepted for the user and no native APK build succeeded in this checkpoint; the Google Sign-In check remains pending.
