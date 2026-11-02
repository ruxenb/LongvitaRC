# Điều phối Assignment Longvita / Lab 3

Cập nhật 02/11/2026 theo xác nhận người dùng: **Lab 3 chính là Assignment**, kế thừa thiết kế Lab 2 đã duyệt. Guide v5 nhấn mạnh công nghệ Firebase nhưng vẫn yêu cầu UI/flows và evidence.

## PM review mới nhất — 02/11/2026

Xem [xác nhận đóng PM-FCM-01, mục 7](PM_REREVIEW_914508c.md#7-xác-nhận-bản-sửa-pm-fcm-01--2d547c7--head-f1f397e), [review cũ](PM_REVIEW_CHARLIE_20261102.md) và [progress Dev](dev-reports/CHARLIE-PROGRESS-20261102.md). Fix `2d547c7` đã push cùng báo cáo tại `f1f397e`; PM chạy lại analyzer/133 tests và reproduction gốc đều pass: **PM-FCM-01 Closed — verified**. Hai findings session trước giữ Closed. Nhánh Charlie đã tích hợp main `614e731`, chưa merge ngược vào main. S4-10/S4-12 vẫn partial: chưa nghiệm thu export/push thật. Các audit/trạng thái trước đọc theo lịch sử.

## Phối hợp Codex PM / Claude Code Dev

Người dùng xác nhận Codex phụ trách phân tích/giao task/review/preview; Claude Code phụ trách triển khai. Xem [working agreement](WORKING_AGREEMENT.md), [contract UI trong code](FIGMA_IMPLEMENTATION_CONTRACT.md) và [gói UI đầu tiên](CLAUDE_FIRST_TASK.md). Root `AGENTS.md`/`CLAUDE.md` lưu quy tắc lâu dài; các task IDs/owners của leader được giữ nguyên. UI/Auth/Firebase đã có commit/push và Dev evidence Android; trạng thái PM cụ thể ở mục mới nhất bên trên. Không coi mọi task tự đánh Verified là đã Accepted.

**Chốt UI ngày 02/11/2026:** Figma là mẫu tham chiếu đóng băng; từ đây cải thiện UI trực tiếp trong code, ghi khác biệt/lý do/evidence trong repo, không sửa hoặc đồng bộ ngược Figma và không bắt audit live lại mỗi thay đổi. Code/runtime được PM/user chấp nhận là baseline hiện hành; giữ flows/nghiệp vụ và ownership.

## Ba tài liệu chuẩn

1. [Phân tích nguồn, phạm vi và repo](LONGVITA_LAB3_FINAL_ANALYSIS.md)
2. [Kế hoạch triển khai theo task leader](LONGVITA_LAB3_IMPLEMENTATION_PLAN.md)
3. [QA và bằng chứng](LONGVITA_LAB3_QA_AND_EVIDENCE_PLAN.md)

[Kết quả kiểm tra local](verification-20261102.md) tách riêng khỏi kế hoạch và E2E/cloud evidence.

## Vai trò Charlie đã được người dùng xác nhận

[Hướng dẫn đọc task và triển khai Charlie](CHARLIE_TASK_GUIDE.md) giải thích đủ 29 task, trách nhiệm của bốn người, dependencies, API bàn giao, hiện trạng source và thứ tự làm. Giữ nguyên task IDs/owners của leader; master của Thái An có 29 task nhưng file cá nhân hiện thiếu S0-2, đã ghi để đối chiếu.

112 task IDs tại [bảng task leader](../tasks/danh-sach-task-full.md) được giữ nguyên; bốn owner Thái An/Charlie/Hoàng/Thắng không bị tự phân công lại. Bộ tài liệu điều phối bổ sung technical acceptance, current gaps và scope SYS của cùng Assignment.

`docs/coordination/` là nguồn chuẩn trong Git để team có thể review. Ba file cùng tên tại thư mục cha `Assignment/` chỉ là bản đồng bộ đọc thuận tiện trên máy người dùng. Khi sửa, sửa bản trong repo rồi đồng bộ ba bản cha, kiểm tra SHA-256 giống nhau. Không cập nhật các bản cũ ở workspace Restored.

Các file `docs/test-plan.md` và `docs/code-review.md` là tài liệu làm việc/khung chi tiết; ô kết quả chưa có raw evidence phải giữ Planned/template. Không chạy `DummyArtemisClient` để tạo pass rate.

## Những quyết định cần chốt

- DEC-01: Guide/Handout yêu cầu Storage upload nhưng Final loại Storage; billing/Blaze và policy local/share/upload.
- DEC-02: Một bộ bài nộp, rubric và khoảng report/video áp dụng; không tự yêu cầu hai bài riêng.
- DEC-03: Application ID, tên repo nộp, SDK/lockfile và full ARTEMIS commit.
- DEC-04: Owner/tiến độ SYS-01..06 cho web/cross-role/AI/security trong cùng Assignment.

Đây là bản hợp nhất phân tích và kế hoạch để review, không phải tuyên bố giảng viên/leader đã duyệt mọi thay đổi hoặc công nghệ đã chạy thật. Không có code feature/rules hoặc cấu hình cloud bị sửa trong lượt cập nhật Markdown này.
