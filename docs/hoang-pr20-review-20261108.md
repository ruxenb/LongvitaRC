# PR #20 — Hoàng: CodeRabbit review responses (2026-11-08)

PR: https://github.com/ruxenb/LongvitaRC/pull/20
Initial reviewed head: `33bec2d`. Follow-up branch: `fix/hoang-a11y-20261108`.

| Finding | Decision | Technical response | Verification |
|---|---|---|---|
| PR20-CR-01 (Minor, documentation) | Accept | Android reports header as a boolean; Flutter headingLevel=1/2 is internal semantics, not a hierarchy demonstrated by TalkBack. Corrected `docs/hoang-accessibility-audit.md`. | Existing `test/flows/hoang_heading_semantics_test.dart` checks only Flutter semantics. No native TalkBack claim. |
| PR20-CR-02 (Major, cleartext redirect) | Accept | Replaced `Image.network` with bounded `http.Client.send` where `Request.followRedirects=false`; reject non-200 and redirects, require HTTPS and image Content-Type; max 5 MiB; no production image network writes. BrowserClient uses fetch redirect=error, IOClient passes followRedirects=false. | `test/flows/secure_recipe_image_test.dart` tests one 302 redirect to HTTP without a second request, direct HTTP refusal, content types, size bound and success. |
| PR20-CR-03 (Minor, image decode memory) | Accept | Render byte-bounded image with `Image.memory(cacheWidth: ...)` sized from hero layout width × device pixel ratio and clamped to 64–2048 pixels. Image placeholder remains. | Flutter analyzer and responsive/widget regressions. |
| PR20-CR-04 (Minor, misleading pending state) | Accept | While the HTTPS recipe image fetch is waiting, show a progress indicator and neutral Vietnamese loading label with live-region semantics. Keep the verified-image-unavailable message only for missing URLs and fetch/decode failures. Use a horizontal responsive layout to avoid overflow at 360px / 2× text scaling. | Four responsive widget checks added to `test/flows/hoang_a11y_widgets_test.dart`. Full Flutter suite: 395/395 passed, analyzer clean, diff check clean. |

## Evidence limits and scope
- All recipes/images still originate in Firestore; no placeholder is presented as an actual recipe picture.
- In-memory image byte limits do not assert the exact decoded memory budget across every image format or device. No native memory-profiling run occurred.
- This PR does not alter authentication, Firebase rules, permissions, recipe nutrition source validation or team-owned UI evidence.
- Android SDK platforms and a connected device remain unavailable, so end-to-end ARTEMIS, native TalkBack and 3-flow video remain outstanding.
- Do not mark 26/26 tasks accepted based on these software-only checks.
