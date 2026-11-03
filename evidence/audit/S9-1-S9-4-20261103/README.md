# Audit sơ bộ S9-1 và S9-4 — 03/11/2026

> Đây là audit giữa kỳ trên nhánh `Thang`, không phải kiểm tra nộp bài cuối.
> Phải chạy lại sau feature freeze và trước S9-6.

## S9-1 — Secret và dữ liệu cục bộ

- Không có file tracked khớp `*.jks`, `*.keystore`, private key, `.env`,
  `service-account*.json`, `firebase-adminsdk*.json` hoặc `key.properties`.
- Không thấy private-key header, AWS access key, GitHub token, bearer token hoặc
  Google API-key pattern trong cây hiện tại khi loại file client config
  `android/app/google-services.json`.
- Quét mọi commit reachable từ `--all` với cùng nhóm pattern: 0 commit/file hit.
- `google-services.json` là client config được repo cho phép; không được suy ra
  security chỉ từ việc ẩn file này. Firestore/Storage Rules mới là lớp kiểm soát.
- Phát hiện 18 evidence text files chứa đường dẫn `C:/Users/phamv/...` hoặc dạng
  backslash. Đã thay riêng prefix định danh bằng `<user-home>/`, giữ nguyên output,
  assertions và kết quả test.
- PR #6 đã loại một ảnh chứa tên/email thật và thay traceback ARTEMIS chứa đường
  dẫn máy bằng bản tóm tắt khử PII tại commit `55bdf3e`.

**Kết luận giữa kỳ:** chưa thấy secret credential; machine-identifying paths đã
được xử lý trong cây hiện tại. S9-1 vẫn **Đang làm** vì commit/evidence mới có thể
xuất hiện trước submission.

## S9-4 — Phân bố và thứ tự Git

Snapshot trước commit audit này:

| Ngày | Số commit reachable |
|---|---:|
| 01/11/2026 | 2 |
| 02/11/2026 | 55 |
| 03/11/2026 | 14 |

| Tác giả Git | Số commit reachable |
|---|---:|
| CharlieMinh | 58 |
| Phạm Văn Minh (GitHub noreply) | 5 |
| Thai An | 5 |
| Thang | 3 |

- Commit đầu trong snapshot: `23ce8bc` — barebone/task breakdown, 01/11.
- MVVM architecture skeleton: `ae35f07`, 01/11.
- Firebase instrumentation: `6e27027`, 02/11.
- Design system/Auth feature đầu của Charlie: `6dfddf9`/`56b1896`, 02/11.
- Tài liệu architecture baseline của Thắng: `d9d0a90`, 02/11.
- Thứ tự chính nhìn chung hợp lý: planning/skeleton có trước feature integrations.
- Phân bố hiện dồn mạnh vào 02/11 và chưa có ngưỡng commit/ngày được giảng viên
  xác nhận; không thể kết luận đạt rubric chỉ từ số lượng trên.

**Kết luận giữa kỳ:** lịch sử có nhiều commit thực và chronology nền móng→feature,
nhưng S9-4 vẫn **Đang làm** cho đến khi S0-1 xác nhận ngưỡng và audit lại lịch sử
cuối cùng trước nộp.
