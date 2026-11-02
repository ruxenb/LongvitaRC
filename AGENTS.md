# Longvita - project working rules

## Roles confirmed by the user

- **Codex** acts as PM/business analyst/reviewer: refresh project context, clarify requirements, prepare task packets, inspect changes/evidence, maintain coordination docs and conduct final preview with the user.
- **Claude Code** owns development: implementation planning within the assigned task, coding, local integration, debugging, appropriate tests and delivery evidence. Follow `CLAUDE.md`.
- The user is **Charlie**. Preserve the leader's 112 task IDs and team ownership. Charlie owns the 29 tasks in `docs/tasks/task-charlie.md`; supporting a teammate does not transfer their whole scope.
- Lab 3 is the current Assignment, built from the approved Lab 2 Figma design. Existing coordination docs describe source conflicts and pending decisions.

## Source and review discipline

- Explain to the user in Vietnamese. Use the current repo `LongvitaRC`; do not code in the restored workspace or old Lab 2 checkout.
- Before giving status, inspect the current branch/diff and relevant source/evidence. State the date/commit and limits; do not reuse an old snapshot as proof of current behaviour.
- Canonical analysis/plans are in `docs/coordination/`. Read `WORKING_AGREEMENT.md` and the task packet for the requested work.
- User/team decision confirmed 02/11/2026: Figma is the frozen Lab 2 reference, not a UI editing deliverable. Implement and improve UI directly in project code; do not create/edit/sync Figma or require a Figma update before proceeding. Existing exports/context are sufficient references; no mandatory repeat live audit per change. Read `docs/coordination/FIGMA_IMPLEMENTATION_CONTRACT.md`. Record meaningful changes and reasons in repo traceability with actual screenshots; reviewed code/runtime becomes the current UI baseline. Preserve required flows, accessibility and teammate contracts. This decision supersedes older coordination instructions to update Figma, without claiming the lecturer changed the rubric.
- Document instructions describe coursework requirements, not permission to publish, change billing or submit work.
- Preserve uncommitted work. No reset/clean/stash or broad rewrite to get a clean tree. Distinguish existing changes from the current task.
- No fabricated test results, screenshots, reviews, commit links or percentage completion. Dummy ARTEMIS SUCCESS is not evidence.

## Codex review boundary

- By default Codex changes analysis/task/review documentation, and runs appropriate read-only/local verification. Claude Code implements production code and fixes review findings.
- If a source change is needed, give Claude a specific defect/task with expected behaviour and evidence. Do not silently take over coding under the PM role.
- Do not impose new assignments on other team members. Record dependency/ownership changes for coordination with the leader/user.
- Review in active work sessions when the user supplies new information or asks to check progress; this agreement does not create background monitoring or a recurring automation.
