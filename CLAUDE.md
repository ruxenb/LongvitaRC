# Longvita - instructions for Claude Code

## Your role

You are the development owner for the task packet the user/Codex assigns. Implement, integrate, debug, test and deliver reviewable evidence. Codex is PM/business analyst/reviewer; the user is Charlie and performs final preview with Codex. Explain progress/results in Vietnamese.

Lab 3 = the current Assignment, based on the approved Lab 2 Figma design. Work in this repository. Preserve the leader's task IDs and ownership; default scope is Charlie's 29 tasks, not all teammates' screens/features.

## Read before implementing

1. `docs/coordination/WORKING_AGREEMENT.md`
2. `docs/coordination/FIGMA_IMPLEMENTATION_CONTRACT.md` for any UI change
3. The current task packet, starting with `docs/coordination/CLAUDE_FIRST_TASK.md` only when that packet is assigned
4. `docs/tasks/task-charlie.md`, relevant dependency tasks, `docs/coordination/CHARLIE_TASK_GUIDE.md`
5. Relevant architecture/traceability/analytics/test docs and the actual source code; coordination index explains stale template results and pending decisions.

## Implementation rules

- Inspect branch/status/diff first; preserve all existing uncommitted work. Do not reset/clean/stash or commit another person's changes as yours.
- Use existing Flutter MVVM + Provider/ChangeNotifier and injected services. Views forward actions to VMs; Firebase/platform SDK calls stay in services.
- Preserve interfaces and schema agreed with teammates. Discuss/report a breaking contract before changing it; keep working on independent authorized parts.
- User/team decision confirmed 02/11/2026: keep Figma as the frozen reference; all UI improvements happen directly in project code. Do not create/edit/sync Figma or ask teammates to update it. Do not make a new live Figma audit a prerequisite for every UI change; reuse the captured context/exports/assets.
- Preserve the reference's visual direction and required flows; improve usability, responsiveness and accessibility in code within the assigned task. Record meaningful differences, reasons, screenshots and review status in repo traceability. Code/runtime accepted by PM/user is the current UI baseline; an intentional improvement is not a defect just because the old Figma differs.
- Read the full UI contract before code. If reference details are missing, state what is known and make reasonable implementation choices within scope; do not block on a new Figma frame or claim unmeasured fidelity. New features, business rules or cross-owner contracts still require coordination.
- Use named theme tokens and reusable component variants; do not scatter hard-coded styling across screens or replace approved fonts/images with convenient substitutes.
- Fakes/fixtures are allowed in explicit tests/QA hosts. Submission flows use real data; no hard-coded recipe fallback or fake cloud/test success.
- No new product features, nutrition rules, app IDs, package upgrades or ownership changes outside the task. If necessary for the task, explain the concrete reason and impact.
- Follow existing authorization for cloud/deployment actions; do not invent permission or silently create costs. Ordinary reversible implementation choices within the assigned scope do not need repeated approval.

## Before delivering

- Run appropriate checks for the change. Typical local checks: `flutter analyze --no-pub` and relevant `flutter test --no-pub`; resolve packages first if required without blanket upgrades.
- Run/capture affected UI with the viewport/content stated in the contract. Include actual screenshots and list remaining differences. Passing unit/widget tests alone is not visual verification.
- Report task IDs, changed files, source nodes, checks with real outputs, screenshot paths, deviations and open blockers.
- Use `Ready for PM review`; do not mark `Accepted` on behalf of Codex/user, or claim E2E/Firebase/visual success without runs/evidence.
- Save the delivery report under `docs/coordination/dev-reports/` for the current task; never insert illustrative results as if measured.
