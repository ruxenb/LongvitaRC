# Biên bản xử lý xung đột PR #40 và PR #41 — 11/11/2026

## Tình trạng Git thực tế

- Nhánh `main` tại lần fetch: `53d7fc5`, trùng `origin/main`, **không có file tracked bị unmerged** hoặc chỉnh sửa chưa commit. Các thư mục `evidence/ui/CHARLIE-UI-01` chưa được theo dõi được giữ nguyên, **không phải merge conflict**.
- PR #40: `feature/hoang-a15-localization-20261111` (Hoàng); PR #41: `fix/app-ux-and-meal-card-refinement` (đồng đội).
- Lượt ghép thử trước commit `e507feb` trên nhánh Hoàng đã sạch. **Sau commit cập nhật các script ARTEMIS**, phép thử mới `git merge-tree --write-tree PR40 PR41` trả exit **1** với **hai xung đột thực sự**:
  1. `e2e_test/test_detail.py`
  2. `e2e_test/test_flows.py`
- Đây là xung đột **giữa hai nhánh chưa merge**, không phải file `<<<<<<<` tồn tại sẵn trên `main`.

## Cách giải quyết đã chuẩn bị, không thay đổi main

Tạo worktree riêng `D:\PRM393\LongvitaRC-PR40-PR41-Resolve-20261111`, nhánh `audit/resolve-pr40-pr41-20261111`. Git merge đầy đủ PR #41 vào PR #40, đọc nội dung ba phía (merge-base / ours / theirs), sau đó giải quyết hai file xung đột bằng cách:

- Giữ bản kịch bản Hoàng đã được cập nhật theo **nhãn thực tế trên APK tiếng Việt**: `Tạo thực đơn tuần`, `Thực đơn tuần`, `Kiến thức sách`, `Món thay thế`, `Tra cứu công thức`, `Thực đơn đã lưu`.
- Giữ assertions dựa trên **nội dung quan sát đúng thời điểm**, không dùng nhãn English cũ `Plan`, `Nutrition`, `Book knowledge` để tạo pass giả.
- Tích hợp nhắc nhở **bật/tắt Airplane mode** và khôi phục mạng từ PR #41 vào bài kiểm tra luồng mất kết nối.
- Giữ các cập nhật khác của PR #41 như tài liệu rubric, UI thẻ món, tùy chỉnh Gradle, ARTEMIS history, không xóa thay đổi của đồng đội.
- Hai script Python sau giải quyết đã chạy `python -m compileall -q e2e_test` **thành công**.
- Commit hợp nhất trên nhánh kiểm toán riêng: `1df3e0d`. **Không merge hoặc force-push vào `main` hay hai nhánh của nhóm**.

## Lộ trình tích hợp an toàn

1. Người phụ trách PR #41 review và merge PR #41 trước nếu phù hợp.
2. Cập nhật PR #40 theo `origin/main` mới, tái áp dụng logic hợp nhất hai file như trên.
3. Chạy lại `flutter analyze` + unit/widget tests Mobile/Core/Web, Python syntax, và ARTEMIS live nếu môi trường đã có daemon/tài khoản test.
4. Chỉ merge PR #40 sau khi checks và review được duyệt; không force push/overwrite các file ngoài phạm vi.

**Giới hạn:** Không có merge conflict không đồng nghĩa đã xác minh 100% chức năng, dữ liệu dinh dưỡng hoặc hai vai trò Firebase. Nhánh kiểm toán là bằng chứng giải quyết xung đột, không phải phiên bản production được phê duyệt.


## Kết quả test sau khi giải quyết conflict

- Mobile Flutter Analyze: **0 vấn đề**, Mobile Flutter Test: **485/485 đạt**.
- Shared Core Analyze: **0 vấn đề**, Core Flutter Test: **20/20 đạt**.
- Web Admin Analyze: **0 vấn đề**, Web Flutter Test: **69/69 đạt**.
- **Tổng 574/574 bài Flutter test đạt** trên bản ghép mới, 6 lệnh analyze/test trả exit **0**.
- Python compileall toàn bộ e2e_test/: **đạt**. Đây chỉ là kiểm tra cú pháp, không chứng minh ARTEMIS daemon chạy thật.
- Logs tại D:\PRM393\hoang_resolved_prs_mobile_*, hoang_resolved_prs_core_* và hoang_resolved_prs_web_*.
- Đã push nhánh kiểm toán (KHÔNG phải merge vào main): https://github.com/ruxenb/LongvitaRC/tree/audit/resolve-pr40-pr41-20261111 ; commit 1df3e0d.
- Sau khi PR #41 được review và merge, cần cập nhật PR #40 rồi đối chiếu hai file xung đột theo bản kiểm toán. Không merge nhánh audit như production.


## APK S06 tiếng Việt và Samsung A15

- Sau chỉnh 5 nhãn S06, Flutter Analyze **0 vấn đề**, Flutter Mobile Test **485/485 đạt**.
- Android debug APK PR #40 build thành công, kiểm tra nội dung kernel_blob.bin có đủ **4 chuỗi tiếng Việt then chốt của S06**; không lấy bản APK cache cũ để khẳng định.
- Cài APK cập nhật lên Samsung Galaxy A15 qua adb install -r: **Success**, PID sau mở **22838**, smoke logcat gần nhất 0 dòng khớp FATAL EXCEPTION/E/flutter/FlutterError. Không xóa app data.
- Màn hình điện thoại ở trạng thái khóa/sạc lúc chụp sau cài đặt; **chưa có ảnh S06 thực tế** từ lần cài này. Widget test S06 và APK byte inspection là bằng chứng nhãn, không thay thế việc đi đủ luồng S04→S05→S06 trên điện thoại.
- Ảnh khóa/sạc và log gốc chỉ lưu cục bộ tại D:\PRM393\Longvita_phone_evidence\20261111_s06_reinstall, không đưa lên Git.
