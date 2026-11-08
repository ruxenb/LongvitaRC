# S8-9 — Nội dung slide do Thắng phụ trách

> Mỗi mục dưới đây tương ứng một thông điệp; người ghép deck có thể gộp hoặc
> chia để giữ tổng deck 12–15 slide.
> Nội dung được đối chiếu lại với `main` ngày 08/11/2026. Việc dàn trang và xuất
> PDF thuộc S8-10; S8-9 chỉ bàn giao nội dung, nguồn và gợi ý hình minh họa.

## Slide 1 — Longvita

- Ứng dụng Android hỗ trợ chuyển kiến thức dinh dưỡng trường thọ thành kế hoạch
  ăn bảy ngày.
- Lab 3 kế thừa trực tiếp persona, flow và design system của Lab 2.
- Nguồn: `README.md`, `docs/design-traceability.md`.
- Hình đề xuất: ảnh Dashboard hoặc sơ đồ ba flow, không dùng ảnh có email/UID.

## Slide 2 — Người dùng và tiêu chí thành công

- Đối tượng cần luồng rõ, chữ dễ đọc và hành động có thể phục hồi.
- Ba mục tiêu: tạo/lưu kế hoạch, chuẩn bị danh sách mua sắm, tra cứu/thay món.
- Auth/Home/Profile và các flow S02–S10 đã có implementation/evidence ở các mức
  khác nhau; phần flow/dữ liệu của Hoàng vẫn chờ nghiệm thu chính thức.
- Nguồn: `docs/tasks/task-hoang.md`, `docs/design-traceability.md`.
- Hình đề xuất: ghép một ảnh flow với một trạng thái loading/empty/error.

## Slide 3 — MVVM và dependency một chiều

- View → ViewModel → Service → Firebase.
- Provider đăng ký dependency; ViewModel nhận service qua constructor.
- Không gọi Firebase SDK trực tiếp từ widget.
- Dẫn chiếu: `docs/architecture.md`.
- Hình đề xuất: render Mermaid layer diagram từ tài liệu kiến trúc.

## Slide 4 — Design system trong code

- Token màu, typography, spacing và radius kế thừa Figma.
- Reusable widgets cho button, form, card, dialog và explicit states.
- Semantics, touch target và responsive/text-scale được test tự động.
- Nguồn: `lib/theme/`, `lib/widgets/`, `evidence/a11y/`.
- Hình đề xuất: một màn hình app kèm ba callout token/component/Semantics.

## Slide 5 — Một finding review có tác động thật

- PR6-01: ảnh evidence làm lộ tên/email người dùng thật.
- Quyết định: Accepted; xóa ảnh khỏi repo, giữ mô tả không định danh.
- Mở rộng: khử username khỏi 18 evidence logs.
- Fix commit: `55bdf3e`; cleanup commit: `1d42e90`.
- Nguồn: `docs/code-review.md`, `evidence/review/PR-6-THANG-20261103/`.
- Hình đề xuất: bảng Before → Finding → Decision → Fix; không phục hồi ảnh PII đã xóa.

## Slide 6 — Bài học và giới hạn

- Evidence phải được kiểm privacy và traceability như code.
- Fake/widget/emulator/cloud là bốn mức bằng chứng khác nhau.
- Không đánh dấu pass khi mới có test giả lập hoặc khi cloud dependency bị chặn.
- ARTEMIS đã có một batch 7/7 pass và TC-11 của Thắng chạy lại thành công; vẫn
  thiếu chiến dịch chính thức tối thiểu ba lượt/test, pass-rate và phân tích flaky.
- Việc còn lại: feature freeze, nghiệm thu chéo, report/slide/video cuối và kiểm
  tra trước nộp; Storage production vẫn bị giới hạn bởi project Spark.
- Nguồn: `evidence/artemis/README.md`, `docs/tasks/danh-sach-task-full.md`.
- Hình đề xuất: bảng ngắn “đã chứng minh / còn thiếu”, không dùng tỷ lệ 100%.

## AI disclosure cho phần slide của Thắng

- Codex hỗ trợ đối chiếu source/evidence, phát hiện nội dung cũ và biên tập bản
  Markdown ngày 08/11/2026.
- Thắng chịu trách nhiệm kiểm tra claim, chọn hình không lộ PII và duyệt nội dung
  trước khi ghép vào deck chung.
- Không dùng AI để tạo kết quả test, ảnh Firebase Console hoặc bằng chứng runtime.
