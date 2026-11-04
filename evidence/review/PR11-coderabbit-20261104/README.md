# PR #11 — CodeRabbit review on d3487ea, 04/11/2026

- **PR:** https://github.com/ruxenb/LongvitaRC/pull/11 (`feature/charlie-session-02` → `main`, S3-5).
- **Review:** https://github.com/ruxenb/LongvitaRC/pull/11#pullrequestreview-5763405072. CodeRabbit, state `COMMENTED`, on commit `d3487ea`. This is not a human approval.
- **Contents:** 1 actionable inline comment (Minor) and 1 nitpick inside the review body. That is one inline thread, not two.
- **Raw JSON** (fetched with the GitHub API): [`review-5763405072.json`](review-5763405072.json), [`inline-comment-4463734663.json`](inline-comment-4463734663.json).
- **Handling:** each finding was checked against the code before deciding. The bot's suggested commands and autofix were not used.

## Decisions

| ID | Source | Finding | Decision | Fix |
|---|---|---|---|---|
| PR11-CR-01 | Minor, inline, [discussion_r4463734663](https://github.com/ruxenb/LongvitaRC/pull/11#discussion_r4463734663), `test/report/session_cleanup_test.dart:113–114` | `release.complete()` only releases the folder lookup. The fixed 10 ms wait does not wait for `deleteAll` to finish, so slow I/O could fail the test even though cleanup works | **Accepted**. Confirmed: with a 300 ms slow removal, the old test fails (`Expected: false, Actual: true`) | `f76289c`: the fixture exposes `store`. After the release, the test awaits a same-uid `find`, which the store queues after the removal, then checks the file and the folder |
| PR11-CR-02 | Nitpick in the review body, lines 89–91 | 10 ms does not prove the new export reached `save` before the removal was released, so a broken queue could pass this test | **Accepted** | `f76289c`: `_SignalingReportStore` signals each save as it is requested, before joining the queue. The test waits for that signal, then releases the removal. The signal is set only for the export under test |

## Also found while checking (not raised by CodeRabbit)

The first full-suite run after the change failed once in the same file: `Null check operator used on a null value` at `profile.lastExport!` of the first export. Cause: `setUp` waited a fixed 10 ms for the restored session of A, so under load the profile was not loaded and the export had no user. Fix in `f76289c`: `setUp` waits for `session.currentUser` through a listener. The two remaining `settle()` calls came after fully awaited steps; one became an assertion that A is signed in, the other was removed. The file has no fixed delays left.

## Checks on f76289c

- **Production code:** unchanged. The diff is only `test/report/session_cleanup_test.dart`.
- **Slow I/O** (300 ms added to the held removal's lookup): the old version of the test fails; the new one passes.
- **Without the per-uid queue** (`local_report_store.dart` from `96c9f57`, put back afterwards): the new "late removal" test still fails, so it keeps guarding PM-S3-5-04.
- **The test file run 5 times on its own:** 2/2 each time.
- **Full suite:** `flutter test --no-pub` 334/334, three runs in a row. `flutter analyze --no-pub`: no issues. `git diff --check`: clean.
- **No native rerun:** only a test changed, and the production code is the same as the APK PM built from `d3487ea`.
