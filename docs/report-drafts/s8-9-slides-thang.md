# S8-9 — Nội dung slide do Thắng phụ trách

> Mỗi mục dưới đây tương ứng một thông điệp; người ghép deck có thể gộp hoặc
> chia để giữ tổng deck 12–15 slide.

## Slide 1 — Longvita

- Ứng dụng Android hỗ trợ chuyển kiến thức dinh dưỡng trường thọ thành kế hoạch
  ăn bảy ngày.
- Lab 3 kế thừa trực tiếp persona, flow và design system của Lab 2.

## Slide 2 — Người dùng và tiêu chí thành công

- Đối tượng cần luồng rõ, chữ dễ đọc và hành động có thể phục hồi.
- Ba mục tiêu: tạo/lưu kế hoạch, chuẩn bị danh sách mua sắm, tra cứu/thay món.
- Trạng thái thực tế: Auth/Home/Profile đã có evidence; S02–S10 còn chờ tích hợp.

## Slide 3 — MVVM và dependency một chiều

- View → ViewModel → Service → Firebase.
- Provider đăng ký dependency; ViewModel nhận service qua constructor.
- Không gọi Firebase SDK trực tiếp từ widget.
- Dẫn chiếu: `docs/architecture.md`.

## Slide 4 — Design system trong code

- Token màu, typography, spacing và radius kế thừa Figma.
- Reusable widgets cho button, form, card, dialog và explicit states.
- Semantics, touch target và responsive/text-scale được test tự động.

## Slide 5 — Một finding review có tác động thật

- PR6-01: ảnh evidence làm lộ tên/email người dùng thật.
- Quyết định: Accepted; xóa ảnh khỏi repo, giữ mô tả không định danh.
- Mở rộng: khử username khỏi 18 evidence logs.
- Fix commit: `55bdf3e`; cleanup commit: `1d42e90`.

## Slide 6 — Bài học và giới hạn

- Evidence phải được kiểm privacy và traceability như code.
- Fake/widget/emulator/cloud là bốn mức bằng chứng khác nhau.
- Không đánh dấu pass khi mới có test giả lập hoặc khi cloud dependency bị chặn.
- Việc còn lại: routes S02–S10, SHA runtime, cloud failure tests và ARTEMIS.
