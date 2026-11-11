# PR38 — sửa diễn đạt sau review

PR gốc [#38](https://github.com/ruxenb/LongvitaRC/pull/38), head `c055a9b`, đã được leader merge tại `598fa87`. Góp ý được kiểm lại trên baseline `17cbbd1`. Phần xử lý các góp ý dưới đây chỉ sửa báo cáo/evidence README; cùng gói còn có bản sửa nối AI/Core phát hiện trong lượt kiểm tích hợp, được ghi riêng tại [FINAL-INTEGRATION](../FINAL-INTEGRATION-20261111/README.md). Không sửa canonical rules.

| Mã | Nguồn | Quyết định | Sửa và cách xác minh |
| --- | --- | --- | --- |
| PR38-CR-01 | [Inline CodeRabbit](https://github.com/ruxenb/LongvitaRC/pull/38#discussion_r4528240883), Minor | Accepted | Nêu riêng readback khớp byte deployment target và khớp canonical sau CRLF/LF normalization; đối chiếu source readback và manifest |
| PR38-CR-02 | Phần Additional comments trong [review](https://github.com/ruxenb/LongvitaRC/pull/38#pullrequestreview-5846393280), Minor/unverified | Accepted sau kiểm tay | Ghi tên ba chỉ số thay `Dashboard2/0/0`; khớp `verification.json` và ảnh Dashboard |
| PR38-PM-01 | Cảnh báo self-approval trong walkthrough/risk summary, PM kiểm source | Accepted | Đổi câu “Owner không tự duyệt” thành giới hạn theo role user; nêu rõ rules không bắt reviewer UID khác owner. `isStaffReview()` kiểm role/status/field, không kiểm hai UID khác nhau |

Liên kết review phía trên dùng ID review REST; inline là nguồn trực tiếp cho CR-01. Không xem cảnh báo trong risk summary là một inline finding riêng của bot.

## Kiểm tra

- Các link relative còn hợp lệ; source readback và ba manifest hash giữ nguyên.
- `git diff --check` sạch; không chạy test/build chỉ để kiểm bản sửa diễn đạt. Các kiểm ứng dụng trong gói này phục vụ thay đổi code tích hợp riêng.
- Lượt kiểm tích hợp main có thêm code AI/Mobile/Web của các owner là công việc riêng, không dùng để suy rằng tài liệu sửa làm thay đổi runtime.
