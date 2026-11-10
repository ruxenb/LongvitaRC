# Yêu cầu Thái An xác nhận S6-1 và S7-4 — 10/11/2026

> **Người nhận:** Thái An (`ruxenb`) — Team Leader & QA Lead
> **Người đề nghị:** Thắng VLQ — Technical Architect & Co-Lead
> **Phạm vi:** Lab 3, không bao gồm việc nghiệm thu Web Admin/Final Assignment
> **Mục tiêu:** chốt quyết định leader cho feature freeze S6-1 và hoàn tất hồ sơ
> AI review toàn nhóm S7-4 trước khi đóng gói report, slide và video.

## 1. Quyết định cần Thái An phản hồi

### S6-1 — Feature freeze và tag `v1.0-rc`

Vui lòng chọn một trong hai kết luận:

1. **Đồng ý feature freeze:** xác nhận commit `main` được chọn làm release
   candidate, cho phép tạo/push tag `v1.0-rc`, và từ thời điểm đó chỉ nhận bug
   fix/evidence/deliverable; hoặc
2. **Chưa đồng ý:** liệt kê chính xác blocker còn lại, người phụ trách và điều
   kiện cần đạt trước khi tag.

Leader cần xác nhận thêm:

- commit SHA dùng làm release candidate;
- kết quả kiểm thử tối thiểu phải chạy lại trên đúng SHA đó;
- các thay đổi nào vẫn được phép sau feature freeze;
- có yêu cầu ARTEMIS đủ ba lượt/test trước khi tag hay được ghi thành giới hạn
  còn lại của bản nộp.

Không tạo tag hoặc ghi S6-1 hoàn thành trước khi có phản hồi rõ ràng của leader.

## 2. Căn cứ hiện có cho S6-1

- S5-10 của Thắng đã hoàn thành với failure cases cho sáu dịch vụ; Storage chỉ
  được xác nhận bằng Emulator vì project Spark, không được ghi là production.
- Main hiện có các thay đổi tích hợp mới đến `3297ed6`; cần leader chọn lại SHA
  cuối thay vì dùng snapshot cũ trong tracker.
- ARTEMIS đã có các lượt chạy thật và TC-11 của Thắng pass, nhưng hồ sơ hiện
  chưa chứng minh tiêu chí formal ba lượt cho mọi test.
- Report PDF, slide PDF và video public chưa hoàn tất; đây là deliverable sau
  freeze, không nên bị hiểu thành tính năng ứng dụng còn thiếu.

## 3. Quyết định cần Thái An phản hồi cho S7-4

S7-4 hiện đã có hồ sơ thật của ba thành viên:

- **Thắng:** PR #6, Bugbot + Security Review, 5 findings, fix `55bdf3e`, merge
  `90d9fd0`;
- **Charlie:** PR #7/#8, CodeRabbit, findings và fix commits đã ghi trong
  `docs/code-review.md`;
- **Hoàng:** PR #10 và evidence review liên quan đã được tổng hợp.

Để đóng S7-4, đề nghị Thái An:

1. cung cấp PR/phạm vi phần việc cá nhân được AI review;
2. lưu output thật của CodeRabbit/Copilot/SonarCloud vào `evidence/review/`;
3. ghi ít nhất 1–2 findings với `file:dòng`, loại lỗi và tóm tắt;
4. quyết định **Accept/Modify/Reject** kèm lý do kỹ thuật;
5. liên kết ít nhất một fix commit cho finding được chấp nhận, nếu có finding
   hợp lệ cần sửa;
6. ghi disclosure công cụ AI đã thực sự dùng;
7. xác nhận bản tổng hợp cuối trong `docs/code-review.md` thay mặt leader.

Không chuyển các dòng placeholder `CR-01..05` thành finding thật nếu không có
link/output nguồn. Nếu AI review không có finding hợp lệ, cần lưu output sạch và
ghi rõ quyết định của leader về cách đáp ứng phần cá nhân S7-1-TA/S7-2-TA/S7-3-TA.

## 4. Điều kiện đóng task

### S6-1 chỉ chuyển sang Đã hoàn thành khi

- leader xác nhận feature freeze bằng phản hồi có thể truy vết;
- có SHA release candidate cụ thể;
- tag `v1.0-rc` tồn tại trên remote;
- kết quả kiểm thử trên SHA/tag được dẫn nguồn;
- các giới hạn còn lại được ghi rõ, không nâng claim từ Emulator lên production.

### S7-4 chỉ chuyển sang Đã hoàn thành khi

- hồ sơ review của Thái An có nguồn thật và disclosure;
- bảng tổng hợp đạt ngưỡng findings/types/decisions/fix links theo rubric;
- leader xác nhận đã đọc và nghiệm thu bản tổng hợp cuối;
- placeholder không được tính vào tổng số finding.

## 5. Mẫu phản hồi đề nghị

```text
S6-1: Đồng ý / Chưa đồng ý
Release candidate SHA:
Kiểm thử phải chạy lại:
Blocker hoặc giới hạn còn lại:
Cho phép tạo và push tag v1.0-rc: Có / Không

S7-4: Đã đủ / Chưa đủ
PR và AI review của Thái An:
Evidence/output:
Finding + quyết định + fix commit:
Disclosure AI:
Xác nhận nghiệm thu docs/code-review.md: Có / Không
```

## 6. Trạng thái trong tracker

- S6-1: **Chờ leader xác nhận**, chưa tạo tag.
- S7-4: **Đang làm**, chờ hồ sơ review/disclosure của Thái An và xác nhận tổng
  hợp cuối.
- S7-1-VLQ của Thắng đã được hiệu chỉnh thành hoàn thành theo PR #6; việc này
  không được dùng để suy ra S6-1 hoặc S7-4 đã hoàn tất.
