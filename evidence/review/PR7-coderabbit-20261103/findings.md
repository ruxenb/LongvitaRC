# CodeRabbit trên PR #7 — output đã lược bỏ HTML

Nguyên văn ở `inline-comments.json`, `reviews.json`, `summary-comments.json` (lấy bằng GitHub API ngày 03/11/2026).

## PR7-CR-01 · Minor · Security & Privacy

- Vị trí: `docs/report-drafts/s8-12-clip-script.md:9` (commit `cdf90e5`)
- Link: https://github.com/ruxenb/LongvitaRC/pull/7#discussion_r4453664849

** Minor** · **Security & Privacy** · ** Detected with Advanced Tier** · **Quick win**
**Sensitive Data Exposure**
**Reachability:** External  
**Exploitability:** Trivial  
**CWE:** [CWE-359](https://cwe.mitre.org/data/definitions/359.html)
**Make blurring of email and UID mandatory in the clip script.**
Line 9 makes masking optional: "nếu nhóm muốn che thông tin cá nhân thì làm mờ khi dựng." The planned Console footage and the existing screenshots contain real identifiers. Scene 1 records the Authentication → Users view, which shows the signed-in account's email and UID. `s8-3-firebase-auth.md` and `s8-7-slides.md` both state that existing images show Charlie's real email and UID. Require blurring those fields before the clip or any image from it is shared.

## PR7-CR-02 · Minor · Functional Correctness

- Vị trí: `docs/report-drafts/s8-12-clip-script.md:25` (commit `cdf90e5`)
- Link: https://github.com/ruxenb/LongvitaRC/pull/7#discussion_r4453664891

** Minor** · **Functional Correctness** · **Quick win**
**Correct the campaign count.**
Scenes 2, 3, and 4 require three Console campaigns, not four. The current instruction can cause the recording setup to prepare an unused campaign.

## PR7-CR-03 · Minor · Maintainability & Code Quality

- Vị trí: `docs/report-drafts/s8-7-slides.md:31` (commit `cdf90e5`)
- Link: https://github.com/ruxenb/LongvitaRC/pull/7#discussion_r4453664908

** Minor** · **Maintainability & Code Quality** · ** Detected with Advanced Tier** · **Quick win**
**Qualify the “đúng người” claim.**
`NotificationInbox.receive` rejects a different `recipient_uid`, but accepts a missing value. The project notes state that such messages can appear for the next signed-in user, and this contract remains unresolved. The slide does not qualify this case. This is a documentation-accuracy issue, not an established external information-disclosure finding.

## PR7-CR-04 · Minor · Maintainability & Code Quality

- Vị trí: `docs/report-drafts/s9-5-viva-charlie.md:3` (commit `cdf90e5`)
- Link: https://github.com/ruxenb/LongvitaRC/pull/7#discussion_r4453664915

** Minor** · **Maintainability & Code Quality** · **Quick win**
**Pin the guide to the revision whose behavior it describes.**
The guide cites `main` at `30ca6e3`, but its Remote Config explanation depends on the comparison added in the reviewed head. At `30ca6e3155a76be9e8256d9c41a0507a5adf1c35`, `refreshRemoteConfig()` returns the SDK result directly, so an unchanged fetch can still report success.

## PR7-CR-05 · Major · Security & Privacy

- Vị trí: `docs/tasks/charlie-progress.md:81` (commit `cdf90e5`)
- Link: https://github.com/ruxenb/LongvitaRC/pull/7#discussion_r4453664931

** Major** · **Security & Privacy** · ** Detected with Advanced Tier** · **Heavy lift**
**Sensitive Data Exposure**
**Reachability:** External  
**Exploitability:** Trivial  
**CWE:** [CWE-359](https://cwe.mitre.org/data/definitions/359.html)
**Redact personal identifiers from the committed ARTEMIS evidence.**
This handoff links readers to `evidence/artemis/README.md`, which points to `raw/runs.jsonl`. The run data contains Charlie’s real email and Firebase UID. A public repository viewer can read these identifiers. ([github.com](https://github.com/ruxenb/LongvitaRC/blob/cdf90e54d6c91be253e343c848ecfe23f69fd9cf/evidence/artemis/README.md))
Replace the identifiers with redacted values. Remove the unredacted history before publishing the evidence.

## PR7-CR-06 · Minor · Data Integrity & Integration

- Vị trí: `docs/tasks/danh-sach-task-full.md:70` (commit `cdf90e5`)
- Link: https://github.com/ruxenb/LongvitaRC/pull/7#discussion_r4453664937

** Minor** · **Data Integrity & Integration** · **Quick win**
**Synchronize the master progress count.**
The header at `docs/tasks/danh-sach-task-full.md:6` still reports `17 đang thực hiện/PR + 6 chưa bắt đầu`, while the linked trackers report `21 đang thực hiện/PR + 2 chưa bắt đầu`. Update the counts or derive them from the task table. Keep the date unchanged unless a separate update-date requirement applies.

## PR7-CR-07 · Minor · Maintainability & Code Quality

- Vị trí: `docs/tasks/task-charlie.md:5` (commit `cdf90e5`)
- Link: https://github.com/ruxenb/LongvitaRC/pull/7#discussion_r4453664950

** Minor** · **Maintainability & Code Quality** · **Quick win**
**Update the progress snapshot date.**
This header still says `Cập nhật tiến độ 02/11/2026`, while the changed entries include the 03/11 ARTEMIS and handoff results. Change the date to `03/11/2026` so readers do not treat the new status as an older snapshot. ([github.com](https://github.com/ruxenb/LongvitaRC/blob/cdf90e54d6c91be253e343c848ecfe23f69fd9cf/docs/tasks/task-charlie.md))

## PR7-CR-08 · Major · Functional Correctness

- Vị trí: `e2e_test/conftest.py:82` (commit `cdf90e5`)
- Link: https://github.com/ruxenb/LongvitaRC/pull/7#discussion_r4453664959

** Major** · **Functional Correctness** · **Heavy lift**
**Keep assertions tied to the relevant observation.**
The fallback returns summaries from every step as one string. Earlier screens can therefore satisfy assertions for actions that failed later. For example, TC-08b checks for `LONGVITA`, which appears before the PDF viewer opens in `evidence/artemis/raw/runs.jsonl` Line 21. A completed task could pass without opening the viewer.
Preserve step boundaries and assert each expected result against the observation after its corresponding action.

## PR7-CR-09 · Major · Functional Correctness

- Vị trí: `e2e_test/test_auth.py:50` (commit `cdf90e5`)
- Link: https://github.com/ruxenb/LongvitaRC/pull/7#discussion_r4453664983

** Major** · **Functional Correctness** · **Quick win**
**Distinguish the launcher from the app home screen.**
A final observation such as “the Longvita home screen appeared” passes these checks even if Back returned to the authenticated dashboard. Conversely, “the launcher appeared” fails despite being an allowed result in the prompt.
Check for the Android launcher or the sign-in screen explicitly, and reject the app home screen.

## PR7-CR-10 · Major · Functional Correctness

- Vị trí: `e2e_test/test_export.py:20` (commit `cdf90e5`)
- Link: https://github.com/ruxenb/LongvitaRC/pull/7#discussion_r4453664990

** Major** · **Functional Correctness** · **Heavy lift**
**Validate the download URL, not only `reports`.**
A truncated or invalid URL passes this test. The recorded output in `evidence/artemis/raw/runs.jsonl` Line 12 ends the URL at `reports...`, which satisfies the assertion without identifying a file or user folder. The separate emulator check covers one run, not future regressions.
Capture the URL from the UI and validate its `reports/{uid}/...` path and PDF target, as required by TC-08 in `docs/test-plan.md`. ([raw.githubusercontent.com](https://raw.githubusercontent.com/ruxenb/LongvitaRC/cdf90e54d6c91be253e343c848ecfe23f69fd9cf/docs/test-plan.md))

## PR7-CR-11 · Major · Functional Correctness

- Vị trí: `e2e_test/test_profile.py:19` (commit `cdf90e5`)
- Link: https://github.com/ruxenb/LongvitaRC/pull/7#discussion_r4453665004

** Major** · **Functional Correctness** · **Heavy lift**
**Keep a changed-value check for TC-09.**
These assertions accept a failed fetch because the same message also says the values may not have loaded. They also reject a successful refresh that applies a changed value. TC-09 requires a successful fetch and an observable configuration change, not only the unchanged case. ([raw.githubusercontent.com](https://raw.githubusercontent.com/ruxenb/LongvitaRC/cdf90e54d6c91be253e343c848ecfe23f69fd9cf/docs/test-plan.md))
Keep this unchanged-value case separately, and add a case that sets a known remote value and checks the value and behavior after refresh.
