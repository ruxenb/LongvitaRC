# S8-14 — Kịch bản clip của Thắng

> Trạng thái: kịch bản chuẩn bị, **chưa phải clip đã quay**. Thời lượng mục tiêu
> 60–90 giây; không đưa email, UID, API key hoặc đường dẫn máy vào khung hình.

## Cảnh 1 — Mở đầu (15–20 giây)

**Hình:** màn hình Dashboard hoặc trang đầu README, không hiển thị định danh tài
khoản.

**Nói:** “Longvita là ứng dụng Flutter hỗ trợ lập kế hoạch dinh dưỡng trường
thọ. Lab 3 kế thừa persona, ba flow và design system từ Lab 2, sau đó bổ sung
kiến trúc MVVM, Firebase, kiểm thử và hồ sơ review.”

## Cảnh 2 — Finding PR6-01 (20–30 giây)

**Hình:** mở dòng PR6-01 trong `docs/code-review.md`; không mở ảnh đã bị loại.

**Nói:** “Security Review phát hiện một ảnh evidence chứa tên và email thật.
Tôi chấp nhận finding vì evidence chạy đúng vẫn không được phép làm lộ dữ liệu
không cần thiết trong repository công khai.”

## Cảnh 3 — Cách sửa và kiểm chứng (25–35 giây)

**Hình:** commit `55bdf3e` và hồ sơ
`evidence/review/PR-6-THANG-20261103/README.md`.

**Nói:** “Commit `55bdf3e` loại ảnh chứa PII, thay traceback có username bằng
bản khử định danh, và bắt buộc che thông tin cá nhân trong video. Sau sửa,
analyzer sạch và 270 test tại thời điểm review đều pass. Kết quả hiện tại sau
merge là 334 test pass; ARTEMIS live và cloud evidence vẫn được ghi riêng, không
đánh đồng với widget test.”

## Checklist trước khi quay bản cuối

- Chờ S7-1-VLQ/S6-1 được nhóm xác nhận hoặc ghi rõ clip là bản chuẩn bị.
- Quay trên commit cuối; cập nhật số test nếu thay đổi.
- Che/cắt toàn bộ email, UID, tên đầy đủ và đường dẫn máy.
- Xuất clip riêng để ghép S8-15; không tự tuyên bố video tổng đã hoàn tất.
