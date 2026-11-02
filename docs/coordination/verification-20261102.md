# Kết quả kiểm tra local và phạm vi cập nhật - 02/11/2026

## Baseline và nguồn

- Repo `ruxenb/LongvitaRC`, local và remote `main` cùng `ae35f07e36cab9ad4843396a1c22d72c247853ea` tại lúc kiểm tra. Working tree sạch trước lượt này.
- Đã đọc 33 Dart files và các interfaces/VM/screens/theme/widgets, rules, Gradle, E2E harness và docs/tasks. Đã đếm 112 task IDs duy nhất: Thái An 29, Charlie 29, Hoàng 26, Thắng 28.
- Đã đọc toàn bộ Guide v5 25 trang, Handout Lab 3 18 trang và Final 9 trang; xem trực quan Guide tr.4/9/25 để đối chiếu sơ đồ MVVM, Storage và checklist nộp.
- Figma dùng baseline đã duyệt/kiểm tra ngày 30/10 từ cuộc trao đổi; chưa mở audit live ngày 02/11.

| PDF | Pages | SHA-256 |
|---|---:|---|
| Preparation Guide v5 | 25 | `9e019002d34c888e650f3e5991892cbce1a0ea5b3d741692fdc83aa1cfb6cb1e` |
| Lab 3 handout | 18 | `f09c673fdab44786f4e81eab45e10244b4b4f347b69f8201f5b066f078dc0bdd` |
| Final Assignment | 9 | `e25b968ea0b4ac01655f20eaa98f639a2062445d89e59b4fb03f59f3ce21dad3` |

## Các lệnh đã thực hiện và kết quả thực

Môi trường local Flutter 3.47.6 stable / Dart 3.13.5. Không nâng SDK hoặc package constraints.

| Lệnh | Kết quả | Giới hạn |
|---|---|---|
| `flutter pub get --offline` | Không resolve được google_fonts do package chưa có đủ trong local cache | Không phải bằng chứng pubspec không tương thích; không dùng kết quả này để kết luận lỗi dependency thật |
| `flutter pub get` | Thành công, tải dependencies theo constraints/lockfile | `pubspec.lock` giữ nguyên bytes so với trước; không chạy pub upgrade |
| `flutter analyze --no-pub` | Exit 0, No issues found, 39.5s | Static analyzer không phát hiện business/security/Figma gaps liệt kê ở AUD |
| `flutter test --no-pub` | Exit 0, 1 test passed: AppButton render/tap | Không khởi động main/Firebase, không E2E hoặc đo fidelity toàn bộ |

Không chạy pytest/ARTEMIS vì harness hiện có fallback Dummy SUCCESS và chưa có suite thật. Không dùng client giả tạo ra run evidence. Không gọi model API, không chạy test crash, không đăng nhập tài khoản, không upload hoặc deploy Firebase.

## Cập nhật Markdown trong lượt này

- Viết lại ba file điều phối trong `docs/coordination/`, giữ bản đồng bộ cùng tên tại thư mục cha `Assignment/`.
- Thêm index và file kết quả này để team đọc được trong Git.
- README root, tasks index và architecture có banner đối chiếu trạng thái/cách gọi Lab 3 = Assignment; sửa kỳ vọng “HEAD là pin” và cam kết migration % chưa được đo.
- `docs/test-plan.md`: ô kết quả điền sẵn chuyển Planned, phân biệt profile/model, không hứa RC refresh ngay bất kể cache.
- `docs/code-review.md`: các ví dụ/commit mẫu gắn nhãn template; không tính chúng là findings/fixes đã thực hiện; công cụ mẫu chưa được coi là disclosure thực tế.
- Không sửa 112 task IDs/ownership, Dart/Python/Gradle/rules hoặc file cấu hình cloud. Không commit/push.

Backup trước chỉnh và bản text PDF/source-line audit nằm tại `C:/Users/phamv/OneDrive/Desktop/PRM/Assignment/review_20261102/`. Nội dung backup là lịch sử để đối chiếu, không là nguồn chuẩn mới.

## Những việc chưa được chứng minh

Firebase Console/project/billing/SHA, Google Sign-In thật, ba trạng thái FCM, Storage/rules deployed, DebugView, Crashlytics reports, RC hành vi, S01-S10 runtime và Figma comparison, real ARTEMIS >=3 runs, PR review/fix commits, web/AI/cross-role/App Check. Vì vậy không gán phần trăm hoàn thành hoặc tuyên bố Assignment chạy end to end.

## Đối chiếu official docs

- Firebase Storage FAQ: https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024 - vẫn yêu cầu Blaze từ 03/02/2026; chưa inspect project nhóm hoặc đổi billing.
- ARTEMIS: https://github.com/google/artemis - SDK example dùng `artemis_client`, Flash/Pro profiles; setup thực phải pin full SHA/API và xác nhận account/model/device.
