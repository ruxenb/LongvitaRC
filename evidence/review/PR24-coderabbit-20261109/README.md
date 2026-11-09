# PR #24 — CodeRabbit và kiểm bản tích hợp

Gói NC-01..05 đã Charlie nghiệm thu và giao push/review/tích hợp main trước Final UI. [PR24](https://github.com/ruxenb/LongvitaRC/pull/24) từ feature/charlie-pdf-local-01, đã merge main134910d tại d3dd075 không conflict. Không có docs/coordination, AGENTS/CLAUDE, local tracking, raw APK/PDF/token/UID trong PR.

## Kiểm tích hợp main

Head đầu d3dd075 có448pass/4fail và2unused-import warnings, build APK được. Các lỗi nằm trong code mới của main134910d, ngoài phần No-Cost: hàng badge+protein S05 bị overflow, tests tìm hai label cũ trong Offstage. Commit0634c3e sửa nhỏ Row→Wrap; loại S05 Offstage test-only strings; tests assert đúng title, tên món và protein đang hiển thị. Bỏ2import không dùng ở recipe screen/previewS06. Không giảm test layout360/412/textScale2, không bắt đầu đợt Final UI hoặc đổi Figma.

Target6/6pass; khi đưa Row cũ trở lại trên chính expected mới thì test bắt overflow. Full sau integrationfix452/452, analyzer sạch, APKbuild được. Giữ raw trước/sau và negative ở QAignored; chỉ cập nhật test theo nội dung hiển thị thật, không dùng hidden widget để thỏa test.

## Round1 — CodeRabbit trên d3dd075

| ID | Nguồn | Quyết định | Sửa và kiểm |
|---|---|---|---|
| PR24-CR-01 | review5824261765, inline4511472335, Minor/Functional Correctness | Accepted | Cảnh báo đăng xuất giữ prefix “PDF đã lưu trên máy này sẽ bị xóa”, nói rõ app không lưu bản sao PDF trên cloud và thực đơn đã lưu vẫn còn |

Finding đúng: thông báo cũ “Bản đã tải lên ... vẫn còn” khiến user hiểu nhầm có backup cloud. Chỉ đổi copy, không đổi logout/retention hoặc nhận metadata là PDF. Một widget regression mới ở Final textScale2 kiểm đủ cảnh báo, không còn claim cũ, scroll tới Hủy và xác nhận dialog thật sự đóng/session còn. Test fail trên copy cũ, pass sau sửa. Lượt thử đầu có tap warning do Hủy ở ngoài viewport; harness đã ensureVisible và assert dialog đóng, không bỏ qua warning.

**Kiểm snapshot đã sửa:** full453/453 (thêm1regression), không missed-tap warning, analyzer lib/test sạch, APK Final debug build được, git diff --check sạch. Source hashes/APK trong verification.json; source sửa được commit cùng evidence này. Rules/package/lock không đổi sau NC-05 nên không chạy lại rules; không native lại chỉ cho copy/Wrap/imports. NativeNoCost vẫn thuộc5cab63b, phân biệt với bản APK mới vừa build.

Raw JSON của review và inline được giữ nguyên để đối chiếu; chưa tự gọi CodeRabbit đã review head sửa trước khi bot thực sự hoàn tất. PR tiếp tục chờ review head mới và mọi thread được xử lý trước merge. Không bật auto-merge.
