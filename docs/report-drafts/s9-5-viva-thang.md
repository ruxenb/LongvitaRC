# S9-5-VLQ — Kịch bản ôn vấn đáp 5 phút của Thắng

> Đây là kịch bản luyện tập. Task chỉ hoàn thành sau khi chạy được ARTEMIS và
> đổi Remote Config live trên đúng Firebase project.

> **Cập nhật 04/11/2026:** phần kiến trúc, ViewModel và quyết định review đã có
> source/evidence để luyện. Remote Config offline đã chạy thật, nhưng không thay
> thế thao tác đổi giá trị live trên Console; ARTEMIS daemon vẫn chưa được xác minh.

## 0:00–1:00 — Kiến trúc

Mở `docs/architecture.md`, giải thích dependency một chiều View → ViewModel →
Service. Nêu lý do constructor injection giúp thay Firebase service bằng fake
trong unit/widget tests và ngăn widget chứa business logic.

## 1:00–2:00 — Một ViewModel

Mở `lib/viewmodels/auth_viewmodel.dart`. Trình bày auth state, Google Sign-In,
session epoch và việc AuthGate phản ứng với signed-in/signed-out. Minh họa rằng
sign-out phải loại protected routes và callback của session A không được rò sang
session B.

## 2:00–3:00 — Quyết định code review

Mở PR6-01 trong `docs/code-review.md`. Finding được accept vì ảnh chạy thật vẫn
làm lộ PII không cần thiết. Fix xóa ảnh, giữ mô tả/evidence phù hợp; audit tiếp
tục thay đường dẫn máy bằng `<user-home>`. Nhấn mạnh con người chịu trách nhiệm
quyết định, không sửa chỉ vì AI đề xuất.

## 3:00–4:00 — Remote Config live

1. Mở Profile và ghi giá trị hiện tại.
2. Đổi đúng parameter trên Firebase Console project `longvita-8da7e`, Publish.
3. Bấm refresh trong app mà không rebuild.
4. Chỉ kết luận thành công nếu UI hiện giá trị mới; lưu ảnh trước/sau.

## 4:00–5:00 — ARTEMIS

```powershell
. .\scripts\project-env.ps1
.\scripts\start-emulator.ps1
cd e2e_test
uv run --python 3.12 pytest -v test_auth.py::test_tc11_sign_out_cannot_return_with_back
```

Trước khi chạy cần ARTEMIS daemon health OK, AVD/device serial đúng và app đã
cài. Nếu daemon không hoạt động thì test phải fail ở fixture; không được trình
bày `pytest --collect-only` như một lần chạy E2E thành công.

## Checklist tự đánh giá trước vấn đáp

- Có thể chỉ đúng dependency `View → ViewModel → Service` trong source.
- Có thể giải thích session epoch và vì sao callback của user A không được cập
  nhật UI của user B.
- Có thể nêu PR6-01, lý do Accepted và commit `55bdf3e` mà không mở dữ liệu PII.
- Có thể phân biệt Remote Config offline pass ngày 04/11 với Remote Config live
  trước/sau Console còn thiếu.
- Chỉ demo ARTEMIS khi daemon health, thiết bị và model key đều hoạt động thật.
