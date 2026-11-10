# PR #33 — CodeRabbit review

Reviewed head: `ba92671`. PR: https://github.com/ruxenb/LongvitaRC/pull/33

## Round 1

| ID | Source | Decision | Resolution |
| --- | --- | --- | --- |
| PR33-CR-01 | [Inline comment 4524418132](https://github.com/ruxenb/LongvitaRC/pull/33#discussion_r4524418132), Minor | Accepted | Set `prompt: select_account` on the actual Google provider passed to `signInWithPopup`. Firebase sign-out does not clear the browser's Google session; the next login should offer account selection. |

Checked against the installed `firebase_auth_platform_interface 7.7.3` provider API and the official [Flutter Firebase Auth guide](https://firebase.google.com/docs/auth/flutter/federated-auth) / [Google OpenID Connect parameters](https://developers.google.com/identity/openid-connect/openid-connect#authenticationuriparameters).

The change is confined to provider parameters. No roles, rules, permissions, dependencies or auth-session logic change. Existing tests are retained; no additional fake/Emulator campaign is introduced for this configuration change. The preceding manual admin/reload/logout results apply to the pre-review build; no new browser run is claimed for this account-chooser setting.

After the fix: Web analyzer (`lib`/`test`) clean, **60/60 Web tests pass**, release Web build successful in **47.6 s**, Wasm dry run successful, format and diff checks clean. Raw review/inline JSON and the sanitized final test/build logs are included beside this file. Waiting for re-review of the fix before integration.
