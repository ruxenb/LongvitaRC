# Tiến độ Charlie — đối chiếu CHARLIE_TASK_GUIDE, 02/11/2026

Đối chiếu từng task với [CHARLIE_TASK_GUIDE.md](../CHARLIE_TASK_GUIDE.md) và source tại `4e4bffd`, nhánh `feature/charlie-auth-01`. Đã commit local, **chưa push**.

Đây là đánh dấu tiến độ của Dev để PM và Charlie review, **không phải Done hay Accepted**. Guide và `docs/tasks/task-charlie.md` không bị sửa.

**Ký hiệu** theo guide mục 3.4: ✅ verified · 🟡 implemented một phần · 🧱 mới có skeleton · ⬜ chưa có.

## Tóm tắt

| Trạng thái | Số task | Tasks |
|---|---:|---|
| ✅ Verified, chờ nghiệm thu | 7 | S0-3-CM, S2-3, S2-4, S3-3, S3-4, S3-5, S3-9 |
| 🟡 Implemented một phần | 4 | S0-4, S3-1, S3-2, S4-14 |
| 🧱 Skeleton | 5 | S3-7, S4-10, S4-11, S4-12, S5-4 |
| ⬜ Chưa có | 13 | S4-13, S4-15, S6-4, S6-7, S6-14, S7-1-CM, S7-2-CM, S7-3-CM, S8-3, S8-7, S8-12, S8-17-CM, S9-5-CM |
| **Tổng** | **29** | |

**Kiểm tra tại `4e4bffd`:** `flutter analyze` không có lỗi · `flutter test` 69/69 pass · test rules trên emulator 41/41 pass · `flutter doctor` không có lỗi.

## Theo đợt triển khai (guide mục 9)

| Đợt | Tình trạng | Còn thiếu |
|---|---|---|
| C0 Khóa đầu vào | 🟡 | Mời thành viên, ghi project ID vào README, DEC-01 |
| C1 Nền UI | ✅ | Codex/Charlie nghiệm thu, Hoàng review cách dùng |
| C2 Auth end to end | 🟡 | SHA của ba thành viên, S3-7 |
| C3 PDF/Storage | 🧱 | Chờ S4-3 của Hoàng và DEC-01 |
| C4 FCM/Profile | 🧱 | Chưa bắt đầu |
| C5 Kiểm thử/review | ⬜ | Chờ harness S6-2 của Thái An và PR |
| C6 Bàn giao cuối | ⬜ | Chưa bắt đầu |

## Đánh dấu 29 task

| | Task | Note ngắn |
|---|---|---|
| ✅ | **S0-3-CM** Toolchain | Flutter 3.47.6, FlutterFire 1.4.1, ADB 1.0.41, emulator. `flutterfire` và `adb` chưa có trong PATH; Firebase CLI chỉ có trong `firebase/node_modules` |
| 🟡 | **S0-4** Firebase project | Đã tạo `longvita-8da7e`, gói Spark. **Thiếu:** mời 3 bạn, ghi ID vào README, chốt DEC-01 |
| ✅ | **S2-3** Theme | Token, typography, font đã có, kèm QA test và ảnh. Commit `6dfddf9` |
| ✅ | **S2-4** 9 widget | Đủ 9 nhóm và widget phụ, kèm QA test. Chờ Hoàng review cách dùng |
| 🟡 | **S3-1** Bootstrap | Plugin `google-services` 4.5.0 build được trên AGP 9.1, Firebase init thành công trên emulator. **Thiếu:** plugin Crashlytics (cùng Thái An). Chưa chạy `flutterfire configure` vì đã cấu hình qua Console, nên chưa có `firebase_options.dart` |
| 🟡 | **S3-2** SHA | Mới có SHA của máy Charlie. **Thiếu:** SHA của Thắng, Hoàng, Thái An |
| ✅ | **S3-3** AuthService | Đăng nhập, hủy thật đạt; tạo `users/{uid}` với `role: user`. Lỗi mạng và lỗi profile mới test bằng fake |
| ✅ | **S3-4** Sign-in | Chạy trên Android, đủ các trạng thái, không overflow khi text scale 2.0 ở 360dp. Chờ Hoàng chốt thiết kế (A5) |
| ✅ | **S3-5** Logout | Về Sign-in thật. Back và tách dữ liệu A/B mới test bằng widget test. Chờ Hoàng duyệt `clearSession()` (A3) |
| 🧱 | **S3-7** Storage rules | File rules đã có từ skeleton, **chưa deploy, chưa test A/B**. Storage cần Blaze: chờ DEC-01 |
| ✅ | **S3-9** Bằng chứng Auth | `evidence/auth/S3-9-20261102/`. Ảnh độ phân giải thấp, có email thật |
| 🧱 | **S4-10** PDF | `ReportService` có sẵn nhưng chưa nhúng font tiếng Việt, chưa lưu local. Chờ S4-3 của Hoàng |
| 🧱 | **S4-11** Upload | Có `uploadReportPdf`; thiếu lỗi typed, cancel, retry ID. Chờ S4-10, S3-7, DEC-01 |
| 🧱 | **S4-12** FCM | Có `requestPermission`, `onMessage`, `onMessageOpenedApp`. **Thiếu:** background, `getInitialMessage`, history, dedup, route |
| ⬜ | **S4-13** Profile + Demo | Chưa có màn Profile. Export và inbox vẫn ở `home_screen.dart`; cần thống nhất với Hoàng |
| 🟡 | **S4-14** Semantics | Mới có Sign-in. Profile, export, notification chưa có. Chưa bật TalkBack thật |
| ⬜ | **S4-15** Bằng chứng Storage/FCM | Chờ S4-11, S4-12 |
| 🧱 | **S5-4** Events | Đã gọi login/logout/export. **Phải sửa theo API mới của Thái An:** `logLogout()`, `logExportReport(fileSizeKb, hasShoppingList)`. Chưa kiểm DebugView |
| ⬜ | **S6-4** test_auth.py | `e2e_test/` mới có `conftest.py` với Dummy client. Chờ S6-2 của Thái An |
| ⬜ | **S6-7** test_export/profile | Chờ S6-2, S4-11, S4-12 |
| ⬜ | **S6-14** Sửa lỗi theo ARTEMIS | Chờ S6-9 |
| ⬜ | **S7-1-CM** PR + AI review | Chưa push, chưa có PR |
| ⬜ | **S7-2-CM** Findings | Chờ S7-1-CM |
| ⬜ | **S7-3-CM** Fix finding | Chờ S7-2-CM |
| ⬜ | **S8-3** Report | Phần Auth đã có evidence để viết; Storage, FCM chưa |
| ⬜ | **S8-7** Slides | Chờ S8-3 |
| ⬜ | **S8-12** Video | Chờ build ổn định |
| ⬜ | **S8-17-CM** Worklog | Chưa có `docs/worklog-charlie.md`; nên bắt đầu sớm |
| ⬜ | **S9-5-CM** Vấn đáp | Chuẩn bị cuối kỳ |

## Task hỗ trợ đã có đóng góp

Các task hỗ trợ khác trong 18 task chưa bắt đầu.

| Task | Owner | Đã đóng góp | Cần owner |
|---|---|---|---|
| S1-5 | Hoàng | Sign-in dựng trong code | Duyệt Sign-in (A5); chốt yêu cầu Profile |
| S2-1 | Thắng | Đề xuất `IAuthService` mới | Duyệt (A1) |
| S3-6 | Thắng | Auth stream, `AuthGate` có `popUntil` khi rời phiên | Duyệt (A2) |
| S9-2 | Thắng | Ảnh project ID khớp `google-services.json` | Đối chiếu khi tổng hợp |
| **AUD-11** | Hoàng/Thắng | Đã sửa rules, 41 test, publish theo duyệt của Charlie | Review, chốt B1–B5 |

## Vướng mắc cần xử lý

| # | Vấn đề | Tác động | Ai xử lý |
|---|---|---|---|
| 1 | **`origin/main` không biên dịch được:** 10 lỗi. Commit `6e27027` đổi API Analytics nhưng chưa sửa `meal_plan_viewmodel.dart`, `profile_viewmodel.dart` | Merge với nhánh này không xung đột file nhưng vẫn lỗi biên dịch | Thái An; riêng `logExportReport` thuộc S5-4 của Charlie |
| 2 | **Docs của Codex chưa commit trùng file với upstream:** `README.md`, `docs/architecture.md`, `docs/code-review.md`, `docs/design-traceability.md`, `docs/tasks/README.md` | Có thể chặn `git merge` trên working tree hiện tại | Codex/Charlie |
| 3 | **DEC-01 chưa chốt:** Storage cần Blaze, Final lại loại Storage | Chặn S3-7, S4-11, một phần S4-13, S4-15 | Thái An (Leader) |
| 4 | **Chưa mời thành viên, thiếu 3 SHA** | Ba bạn chưa đăng nhập Google được | Charlie, cả nhóm |
| 5 | **Món ăn hard-code** khi Firestore chưa có `recipes` (A9) | Trái quy định bản nộp; có 1 plan test chứa món giả trên project | Hoàng |
| 6 | **Nhánh chưa push** | Hoàng chưa dùng được widgets, nhóm chưa có config Firebase và rules | Charlie |

`origin/main` ghi Thái An là Team Leader và đã có code S5-x, nên nhóm không còn ở mốc ban đầu như guide ghi nhận (`ae35f07`).

## Việc tiếp theo đề xuất

1. **Đồng bộ:** push nhánh, báo Thái An về vướng mắc 1, xử lý docs của Codex rồi merge `origin/main`, sửa `logExportReport` và `logLogout` theo API mới.
2. **Mở khóa cho nhóm:** mời 3 bạn, nhận SHA, tải lại `google-services.json`, ghi project ID vào README; nhờ Leader chốt DEC-01.
3. **Gói code kế tiếp: S4-12 FCM.** Không phụ thuộc DEC-01 hay S4-3. Cần Thắng chốt route/payload và cả nhóm chốt nơi lưu history trước.
4. **Song song:** S4-10 PDF với font tiếng Việt, dùng fixture cho đến khi có S4-3.
5. **Sau đó:** S4-13 Profile (thống nhất diff `home_screen.dart` với Hoàng), rồi S3-7/S4-11 khi có DEC-01.
6. **Làm dần từ bây giờ:** `docs/worklog-charlie.md`, phần Auth của S8-3.

## Commit

| Commit | Nội dung |
|---|---|
| `6dfddf9` | UI-01: S2-3, S2-4 |
| `56b1896` | AUTH-01: S3-3, S3-4, S3-5 |
| `4e4bffd` | Firebase: S0-4, S3-1, S3-9, AUD-11 |

Mỗi commit đều qua `flutter analyze`. Không commit: docs của Codex (giữ nguyên trên working tree), XML và logcat thô của lần chạy thật (giữ trên máy Charlie, loại bằng `.git/info/exclude`).

Commit có `google-services.json` và ảnh có email, UID của Charlie. Cân nhắc trước khi push nếu repo công khai.

Chi tiết: [CHARLIE-UI-01](CHARLIE-UI-01.md), [CHARLIE-AUTH-01](CHARLIE-AUTH-01.md).
