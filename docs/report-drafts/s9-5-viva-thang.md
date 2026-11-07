# S9-5-VLQ — Bài nói vấn đáp 5 phút của Thắng

> **Trạng thái:** hoàn thành ngày 07/11/2026. Bài nói bám theo source và
> evidence thật: Remote Config live ngày 06/11 và TC-11 ARTEMIS đạt ngày 07/11
> (`1 passed in 77.88s`, task `9a885faf-776a-457a-8cc4-2cdfb007b93d`).

## Chuẩn bị trước khi trình bày

Mở sẵn `docs/architecture.md`, `lib/viewmodels/auth_viewmodel.dart`, PR6-01
trong `docs/code-review.md` và phần TC-11 trong `evidence/artemis/README.md`.
Không mở email, UID, API key hoặc đường dẫn máy trong phần trình chiếu.

## 0:00–0:30 — Giới thiệu

> Em là Vũ Lương Quang Thắng. Trong dự án Longvita, em đảm nhiệm vai trò
> Technical Architect và Co-Lead. Phần em phụ trách chính là kiến trúc MVVM,
> dependency injection, Auth routing, kiểm thử failure cases, tổng hợp code
> review và chuẩn bị tài liệu báo cáo. Trong năm phút này, em sẽ trình bày kiến
> trúc, một ViewModel, một quyết định code review, Remote Config và một test
> ARTEMIS chạy thật.

## 0:30–1:25 — Kiến trúc MVVM

> Longvita tổ chức dependency theo một chiều: View gọi ViewModel, ViewModel gọi
> Service, và Service mới giao tiếp với Firebase. Widget không gọi Firebase SDK
> trực tiếp. Các dependency được đăng ký tập trung bằng Provider và truyền qua
> constructor. Nhờ vậy, giao diện chỉ hiển thị state, còn nghiệp vụ nằm trong
> ViewModel. Khi viết unit hoặc widget test, nhóm có thể thay Firebase service
> bằng fake service mà không cần kết nối cloud. Cách tách này cũng giúp dự án có
> thể đưa models, services, theme và widgets sang package core dùng chung trong
> Assignment sau này.

Thao tác: chỉ vào sơ đồ `View → ViewModel → Service → Firebase` và bảng
ViewModel–Service trong `docs/architecture.md`.

## 1:25–2:20 — AuthViewModel và bảo vệ phiên

> Ví dụ em chọn là AuthViewModel. ViewModel lắng nghe auth state và cung cấp
> trạng thái signed-in hoặc signed-out cho AuthGate. AuthGate dựa vào trạng thái
> đó để chọn Sign-in hoặc Home. Khi đăng xuất, navigation stack được dọn để nút
> Back không quay lại màn hình được bảo vệ. ViewModel còn dùng session epoch để
> nhận biết callback thuộc phiên nào. Nếu request của user A hoàn thành sau khi
> user B đã đăng nhập, epoch cũ khiến kết quả đó bị bỏ qua, tránh dữ liệu, lỗi
> hoặc snackbar của user A xuất hiện trong phiên user B. Đây là cách nhóm xử lý
> race condition khi các thao tác Firebase là bất đồng bộ.

Thao tác: chỉ vào auth state, session epoch và xử lý sign-out trong
`lib/viewmodels/auth_viewmodel.dart`.

## 2:20–3:10 — Quyết định code review PR6-01

> Finding em chọn là PR6-01. Security Review phát hiện một ảnh evidence chứa tên
> và email thật. Em quyết định Accepted vì ảnh có thể chứng minh chức năng chạy
> đúng nhưng không cần công khai dữ liệu định danh để chứng minh snackbar. Trong
> commit `55bdf3e`, nhóm loại ảnh khỏi repository và giữ lại mô tả evidence đã
> khử định danh. Sau đó audit tiếp tục thay đường dẫn máy cá nhân bằng
> `<user-home>`. Bài học là output của AI không được chấp nhận tự động; con người
> phải đối chiếu finding với source, phạm vi và rủi ro. Evidence cũng phải được
> review về privacy và traceability nghiêm túc như code.

Thao tác: mở đúng dòng PR6-01; không mở ảnh đã bị loại hoặc thông tin định danh.

## 3:10–4:00 — Remote Config live

> Ngày 06/11, trên Firebase project `longvita-8da7e`, em đã đổi hai tham số
> Remote Config live. Em ghi nhận giá trị trước, Publish giá trị mới trên
> Console, sau đó bấm cập nhật trong màn Profile. Ứng dụng fetch và activate giá
> trị mới mà không rebuild hoặc cài lại APK. Sau khi kiểm tra, em hoàn nguyên và
> Publish lại hai giá trị. Khi mất mạng hoặc không có giá trị mới, ứng dụng giữ
> giá trị hiện tại và không báo thành công giả. Em chỉ kết luận live update thành
> công khi UI hiển thị đúng giá trị đã Publish, không chỉ dựa vào kết quả trả về
> của Firebase SDK.

## 4:00–4:50 — ARTEMIS TC-11

> Em dùng TC-11 để kiểm tra đăng xuất và nút Back. Fixture mở lại ứng dụng, xác
> minh đúng trạng thái signed-in và đúng tài khoản trước khi agent chạy. ARTEMIS
> thực hiện sáu bước: mở app, thấy Dashboard, mở Hồ sơ, bấm Đăng xuất, xác nhận
> Đồng ý, thấy màn Sign-in rồi nhấn Android Back. Quan sát cuối là Android
> launcher, không phải Dashboard, nên protected route không thể truy cập lại.
> Lượt chạy ngày 07/11 đạt `1 passed in 77.88s` trên `emulator-5554`, model
> `gemini-3.5-flash-lite`, với sáu replay steps và không có error.

> Trước đó có một lượt fail vì model `gemini-3.8-flash` timeout 180 giây trước
> bước UI và có zero replay steps. Nhóm giữ failed record để phân biệt lỗi
> hạ tầng/model với lỗi ứng dụng, sau đó chạy lại bằng Flash-Lite mới kết luận
> TC-11 pass.

## 4:50–5:00 — Kết luận

> Qua các phần trên, em chứng minh kiến trúc tách lớp, bảo vệ phiên đăng nhập,
> xử lý finding có trách nhiệm và kiểm thử cả cấu hình cloud lẫn hành vi native.
> Em luôn phân biệt unit/widget test, emulator, Firebase Console và ARTEMIS để
> không đưa ra kết luận rộng hơn bằng chứng thực tế.

## Lệnh demo TC-11 khi được yêu cầu

```powershell
. .\scripts\project-env.ps1
.\scripts\start-emulator.ps1
cd e2e_test
uv run --python 3.12 pytest -v test_auth.py::test_tc11_sign_out_cannot_return_with_back
```

Trước khi chạy phải kiểm tra daemon health, `emulator-5554`, APK và tài khoản
signed-in. `pytest --collect-only` hoặc task không có replay steps không được
trình bày như E2E pass.

## Câu hỏi dự phòng

- **Vì sao UI không gọi Firebase trực tiếp?** Để tách nghiệp vụ, kiểm thử bằng
  fake service và tránh widget phụ thuộc SDK/cloud.
- **Session epoch giải quyết gì?** Loại callback bất đồng bộ của phiên cũ sau
  khi người dùng đã đăng xuất hoặc đổi tài khoản.
- **Vì sao không xóa failed ARTEMIS record?** Giữ audit trail và chứng minh nhóm
  phân tích đúng lỗi model timeout, không chọn lọc evidence để làm đẹp.
- **TC-11 chứng minh điều gì?** Sau sign-out, protected route bị loại; Back ra
  launcher thay vì quay lại Dashboard.
- **Storage đã chạy production chưa?** Chưa. Evidence Storage hiện dùng Firebase
  Storage Emulator vì project Spark chưa có Storage cloud.
