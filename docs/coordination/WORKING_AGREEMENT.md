# Longvita - cách phối hợp Codex, Claude Code và Charlie

Ngày xác nhận: **02/11/2026**. Lab 3 = Assignment; user là **Charlie**; giữ phân công leader/team.

## 1. Vai trò và quyết định

| Bên | Chịu trách nhiệm |
|---|---|
| **Codex - PM/BA/reviewer** | Cập nhật bối cảnh từ repo/nguồn mới; phân tích nghiệp vụ; bóc task và acceptance; quản lý dependency/risk/decision log; đọc diff/test/screenshots; giao feedback cụ thể; preview cùng user |
| **Claude Code - Dev owner** | Đọc task/nguồn; đề xuất cách triển khai trong scope; code/integrate/debug/test; cập nhật technical delivery; tự sửa lỗi trước khi bàn giao |
| **Charlie - người dùng** | Cung cấp quyết định/thông tin team; chốt ưu tiên/phạm vi phần mình; xem preview và quyết định chấp nhận sản phẩm cùng Codex |
| **Leader/team** | Phân công chính thức 112 tasks, contracts liên thành viên, scope/rubric/cloud access và các quyết định dùng chung |

Claude được chủ động thực hiện các quyết định kỹ thuật thông thường trong task được giao. “Dev owner” không tự chuyển toàn bộ S01-S10 của Hoàng hoặc routing của Thắng sang Charlie. Codex giao gói triển khai trong phạm vi đã có và ghi dependency; không thay vai trò leader.

Codex mặc định sửa tài liệu và kiểm tra/review; source production/fix thuộc Claude. Nếu user thay phân công ở lượt sau thì ghi thay đổi rõ ràng.

**Quyết định UI 02/11/2026:** Figma là bản tham chiếu đóng băng; mọi cải thiện UI thực hiện trực tiếp trong code, không sửa/đồng bộ ngược Figma và không bắt audit live lại mỗi task. Ghi khác biệt có ý nghĩa, lý do và screenshots trong repo; code/runtime đã được PM/user chấp nhận là baseline hiện hành. Giữ flows/nghiệp vụ và ownership. Quyết định này thay hướng dẫn điều phối cũ yêu cầu cập nhật Figma, không tuyên bố giảng viên đổi rubric.

## 2. Vòng giao việc

1. **Refresh:** Codex kiểm tra branch/commit/diff, tài liệu leader, code/evidence mới. Snapshot cũ là lịch sử, không phải trạng thái hiện tại.
2. **Task packet:** Ghi task IDs, mục tiêu, files/scope, nguồn Figma/data/API, dependencies, acceptance/checks và evidence cần giao.
3. **Development:** Claude xác nhận đã đọc nguồn, kiểm tra đủ context và triển khai. Gặp gap thì nêu đúng phần thiếu; tiếp tục phần độc lập thay vì đoán hoặc dừng toàn bộ không cần thiết.
4. **Self-check:** Claude kiểm tra logic/state/tests, chạy UI, đối chiếu reference đã lưu và các quyết định code hiện hành; sửa lỗi, ghi cải tiến có chủ đích trước bàn giao, không sửa Figma.
5. **PM review:** Codex đọc diff và evidence, kiểm chứng phù hợp, phản hồi bằng defect cụ thể: actual, expected, source, reproduction, priority.
6. **Fix/review:** Claude sửa và cung cấp evidence mới cho phần bị ảnh hưởng.
7. **Preview/accept:** Codex và Charlie xem bản chạy/ảnh; chỉ đánh Accepted khi acceptance có bằng chứng. Leader/team vẫn giữ quyền nghiệm thu tích hợp theo phân công.

Không có background monitor/automation được tạo bởi thỏa thuận này. Mỗi lần user gửi cập nhật/báo bàn giao hoặc yêu cầu kiểm tra, Codex sẽ refresh và tiếp tục vòng điều phối.

## 3. Trạng thái không gây hiểu nhầm

`Planned -> In progress -> Implemented -> Ready for PM review -> Changes requested / Accepted`

- Implemented: đã có code; chưa đồng nghĩa đã kiểm chứng cloud hoặc nhìn giống Figma.
- Ready for PM review: Claude đã tự kiểm tra, có evidence và giới hạn.
- Accepted: PM/user đã review được acceptance trong phạm vi đó. Không dùng một AppButton test pass để chấp nhận toàn Assignment.
- Blocked: ghi dependency cụ thể, owner cần cung cấp và phần vẫn tiếp tục được. Không điền % completion chỉ từ số file/task.

## 4. Nội dung một gói giao việc

```text
Task IDs / mục tiêu:
Scope / files / ngoài phạm vi:
Nguồn chuẩn: Figma node URLs, design version/date, API/data contract:
Đầu vào đã có / dependency còn thiếu / owner:
Acceptance: chức năng, error/recovery, UI, accessibility:
Checks và screenshots/evidence cần bàn giao:
Kỳ vọng báo cáo và các quyết định còn mở:
```

Mỗi gói nên tạo ra một đầu ra có thể review: theme/widgets, Auth flow, PDF/upload hoặc FCM/Profile. Không giao “làm toàn bộ app cho giống Figma” mà thiếu screen/state/source.

## 5. Báo cáo Claude bàn giao

Lưu `docs/coordination/dev-reports/<task-or-batch-id>.md` khi thực sự thực hiện, chưa tạo báo cáo giả ở bước giao việc.

```text
Task IDs và trạng thái đề nghị:
Baseline commit/branch; phần diff có sẵn đã bảo toàn:
Nguồn đã đọc: Figma nodes/version, docs/API:
Files thay đổi và cách tích hợp:
Checks: command, kết quả thực, log path:
UI: reference + actual screenshots, logical viewport/DPR/textScale,
    fixture/content/font/assets, state, khác biệt còn lại:
Nghiệp vụ/error paths đã thử và chưa thử:
Deviation/decision cần PM-user/team xử lý:
Blockers và bước tiếp theo:
```

## 6. Gói đầu tiên đề xuất

**CHARLIE-UI-01: S2-3 + S2-4, theme và common widgets.** Packet ở [CLAUDE_FIRST_TASK.md](CLAUDE_FIRST_TASK.md), [báo cáo Dev](dev-reports/CHARLIE-UI-01.md). UI commit `6dfddf9` và các commit Auth/Firebase sau đó đã push trên `feature/charlie-auth-01` tại `d17383c`. [PM review 02/11](PM_REVIEW_CHARLIE_20261102.md) xác nhận analyzer/69 tests/41 rules tests pass, phát hiện hai ca callback muộn qua đổi phiên: **S3-5 Changes requested**, chưa Accepted. Auth có ảnh Android/cloud Dev bàn giao; chưa nghiệm thu visual toàn UI hay toàn bộ Firebase.

Nguồn UI theo [FIGMA_IMPLEMENTATION_CONTRACT.md](FIGMA_IMPLEMENTATION_CONTRACT.md). Đây là bước nền để Hoàng lắp screens, không tự nhận code mười màn chính thay Hoàng.
