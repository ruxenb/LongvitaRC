# PR #26 — CodeRabbit review, 09/11/2026

PR: https://github.com/ruxenb/LongvitaRC/pull/26

| Finding | Source | Decision | Resolution |
|---|---|---|---|
| PR26-CR-01 | Review5825382625 / inline4512353769 on dc836f0, Minor | Modified: defect accepted, proposed precision cap strengthened | One shared formatter preserves double round-trip text for display/editor, trims only the integer .0 suffix, uses comma decimal. No fixed decimal limit. |

## Why the implementation differs from the suggestion

The old one-decimal prefill turned2.25 into2.3 and0.04 into0.0; submitting unchanged could alter/reject the original amount. The suggested two-decimal cap still truncates2.345 and can turn0.004 intozero. Neither the model nor validation limits accepted values to two decimals. Double.toString gives the shortest round-trip representation; replacing the decimal separator and trimming only the integer .0 suffix leaves a parseable equivalent value. Very small/large numbers may retain scientific notation rather than be rounded away.

## Regression proof

Six widget cases use actual Ingredients UI, open the real edit dialog and submit Lưu without editing. They assert display/prefill, dialog dismissal, original ViewModel amount and persisted fake-repository amount for2.25,0.04,2.345,0.004,1e-7 and10.0. On dc836f0:5fail/1controlpass. Afterfix:6/6pass. Expected values/fakes were not relaxed.

Full post-fix suite473/473; analyzerlib/test clean. Final APK result/hash is recorded in verification.json. Raw review/comment JSON retained beside this file; raw command logs and generated test images remain ignored/local.

Native Vietnamese UI/menu and real checklist observations remain the prior dc836f0/780b175 runs. No new native run, rules deployment, production write or dependency changes were made for this formatting fix. Amount-preservation edge cases are controlled widget/ViewModel tests. Earlier467/465 results and screenshots are historical evidence, not post-fix native claims.
