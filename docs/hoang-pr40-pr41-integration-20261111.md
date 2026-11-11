# Kiểm chứng tích hợp PR #40 + PR #41 — 11/11/2026

**Mục đích:** Kiểm tra liệu phần bổ sung của Hoàng gây merge conflict hoặc làm hỏng mã Mobile/Shared Core/Web khi kết hợp với phần tinh chỉnh của nhóm. Đây là **kiểm thử trên worktree độc lập**, không phải thao tác merge vào nhánh main hoặc nghiệm thu trên Firebase production.

## Snapshot được kiểm tra

- Main gốc: `53d7fc5`.
- PR #40: `feature/hoang-a15-localization-20261111`, commit bằng chứng trước khi tạo bản ghép `2dba5e5`.
- PR #41: `fix/app-ux-and-meal-card-refinement`, tại commit `b7f7561`.
- Worktree riêng: `D:\PRM393\LongvitaRC-PR40-PR41-Check-20261111`, nhánh `audit/pr40-pr41-20261111`, merge commit thử `f7b1090`. Nhánh kiểm tra **không được push và không thay main**.
- Git merge bằng chiến lược ort: **exit 0**, không có file ở trạng thái unmerged. Sau phép merge, Flutter Analyze và kiểm thử ba package được chạy thực tế.

## Kết quả kiểm thử chung

| Package | Lệnh | Kết quả |
| --- | --- | --- |
| Mobile | flutter analyze --no-pub | Không có vấn đề |
| Mobile | flutter test --no-pub --concurrency=1 | **483/483 đạt** |
| Shared Core | dart analyze | Không có vấn đề |
| Shared Core | flutter test --no-pub --concurrency=1 | **20/20 đạt** |
| Web Admin | flutter analyze --no-pub | Không có vấn đề |
| Web Admin | flutter test --no-pub --concurrency=1 | **69/69 đạt** |

Tổng: **572/572 Flutter tests đạt** trên bản ghép thử. Đã chạy sai lệnh `dart test` ban đầu ở Shared Core (package chỉ khai báo `flutter_test`, không có package `test`); dùng đúng `flutter test` đã đạt 20/20. Đây là lỗi chọn công cụ, **không phải lỗi build/mã**.

Log nằm trên máy: `D:\PRM393\integration_pr40_pr41_mobile_analyze.log`, `integration_pr40_pr41_mobile_tests.log`, `integration_pr40_pr41_core_analyze.log`, `integration_pr40_pr41_core_flutter_tests.log`, `integration_pr40_pr41_web_analyze.log`, `integration_pr40_pr41_web_tests.log`.

## Bằng chứng Android thật và ảnh an toàn

APK bản Hoàng đã clean build, cài thành công và mở trên Samsung Galaxy A15 Android 16. Đã kiểm tra tiêu đề **Tiện ích Firebase**, Vai trò: Người dùng và Cấu hình từ xa. Ảnh thật đã loại bỏ vùng danh tính: [ảnh Hồ sơ không chứa PII](../evidence/hoang/android-a15-20261111/profile-vietnamese-no-pii.png). **Ảnh trên chỉ xác minh bản Hoàng, chưa cài bản ghép PR41 lên điện thoại thật.**

## ARTEMIS — phân biệt lịch sử với nghiệm thu đủ 3 lượt

Nhánh PR #41 mang theo lịch sử `evidence/artemis/raw/runs.jsonl`: phân tích metadata trên bản ghép thử ghi nhận **45 record**, trong đó 39 ghi `completed` và 6 ghi `failed`. `completed` chỉ nói agent hoàn thành công việc, **không đồng nghĩa pytest assertion pass**.

Hai log `evidence/artemis/full-pass-batch1.txt` và `full-pass-batch2.txt` chứng minh một đợt **5/5 và 2/2 pytest pass** trên môi trường của thành viên Charlie. Tài liệu `evidence/artemis/README.md` nêu rõ **chưa đủ 3 lượt đạt cho mỗi test**; một số test khác còn thất bại và đã sửa script. Môi trường hiện tại trên máy Hoàng không có ARTEMIS daemon, Gemini API key và tài khoản test cấu hình, nên **không có thêm ARTEMIS live run** từ đợt này.

**Lưu ý bảo mật:** README của ARTEMIS ghi nhận raw logs có thể chứa email/UID thật của thành viên. Cần loại bỏ thông tin định danh trước khi phát hành công khai; báo cáo này không sao chép các giá trị đó.

## Vấn đề vẫn phải nghiệm thu trước khi nhận 100%

- Ít nhất ba lượt ARTEMIS cho từng ca được yêu cầu, có quan sát và assertion đối chiếu.
- Xác minh Firestore liên vai trò user → Web duyệt → user nhận trạng thái, kèm kiểm thử role gate và Announcement Inbox.
- Thực hiện xuất PDF từ thực đơn thật trên Samsung A15, đối chiếu metadata và Firebase Console.
- Đối chiếu thiết bị với Figma toàn bộ 10 màn S01–S10, video demo 3 luồng và bộ dữ liệu recipe được duyệt.
- Kiểm tra lại các thay đổi mới ngay trước khi merge PR, vì main và các PR vẫn có thể cập nhật.

**Kết luận:** Không phát hiện merge conflict hay lỗi Flutter unit/widget test khi ghép PR #40 với PR #41 ở snapshot được nêu. **Chưa đủ cơ sở xác nhận toàn bộ task Hoàng hoặc Final Assignment 100%.**


## Cập nhật phát hiện conflict mới 11/11

Kết quả không conflict ở phần trên đúng tại snapshot cũ của PR #40. Sau commit mới cập nhật kịch bản ARTEMIS trên nhánh Hoàng, kiểm tra ghép PR #40 và #41 phát hiện **hai xung đột thực** ở e2e_test/test_detail.py và e2e_test/test_flows.py. Main gốc vẫn sạch. Đây là conflict giữa hai PR nếu ghép mà không xử lý.

Đã giải quyết ở nhánh audit/resolve-pr40-pr41-20261111, commit 1df3e0d, trên worktree riêng, Mobile 485/485 + Core 20/20 + Web 69/69 = **574/574 tests đạt, Analyze 0 vấn đề**. Xem docs/hoang-pr40-pr41-conflict-resolution-20261111.md. Không merge nhánh audit trực tiếp thay cho review và nghiệm thu của cả hai PR.
