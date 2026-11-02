# Kế Hoạch & Bảng Theo Dõi Task — Charlie

> **Thành viên:** Charlie (CharlieMinh)  
> **Vai trò:** **Design System in Code + Firebase Core Services** (Theme, 9 Common Widgets, Firebase Auth, Cloud Storage, FCM, PDF Export, Màn Sign-in & Profile/Demo Area)  
> **Cập nhật tiến độ 02/11/2026, trước PR:** **29 task = 6 chờ nghiệm thu + 9 đang thực hiện/chuẩn bị PR + 2 skeleton + 12 chưa bắt đầu.** Chưa tự đánh Done/Accepted toàn task; xem [progress và evidence](../coordination/dev-reports/CHARLIE-PROGRESS-20261102.md). Ba findings PM đã Closed không có nghĩa S3-5/S4-12 hoàn tất mọi điều kiện. IDs/phân công/phụ thuộc của leader được giữ nguyên.

---

## 1. Trách Nhiệm Trọng Tâm
1. **Design System & Common Widgets:**
   - Xây dựng `lib/theme/` chuẩn theo 64 Figma Variables và quyết định D08 từ Lab 2 (Tokens-to-Flutter: ColorScheme, TextTheme, Spacing, Radius 4/8/12/16/full, Action green `#476429`, Border `#74796C`).
   - Xây dựng 9 widget dùng chung trong `lib/widgets/` (Button, TextField, Card, Navigation, AppBar, Dialog, Loading, Empty, Error) với đầy đủ variants/states, touch target $\ge 48$ dp, Semantics label.
2. **Firebase Auth, Storage, FCM & Demo Screens:**
   - Cấu hình Firebase (`flutterfire configure`), nạp `google-services.json`, đăng ký mã SHA-1 của cả 4 máy thành viên.
   - Triển khai Google Sign-In & Sign-Out (không crash khi hủy/mất mạng, xóa data khi sign-out); ghi nhận user vào Firestore `users/{uid}` với `role: 'user'` mặc định.
   - Thiết lập `firebase/storage.rules` (chỉ user đọc/ghi trong thư mục `reports/{uid}/...`).
   - Viết `ReportService` (sinh PDF thực đơn độc lập lưu local) và `StorageService` (upload có thanh tiến trình và hiển thị download URL phục vụ Lab 3).
   - Tích hợp FCM (nhận thông báo ở cả 3 trạng thái: foreground, background, terminated; mở màn hình liên quan khi chạm).
   - Dựng màn hình Sign-in và màn hình Profile kèm **Firebase Demo Area**.
3. **Testing, AI Review & Bàn giao:**
   - Viết `e2e_test/test_auth.py` và `test_export.py` cho Google ARTEMIS.
   - Tham gia AI Code Review trên PR của mình, đóng góp $\ge 1-2$ findings và $\ge 1$ commit sửa lỗi.
   - Soạn mục Báo cáo, Slides và quay Video demo mảng Auth, Storage, FCM.

---

## 2. Bảng Danh Sách 29 Task Chi Tiết

| ID | Giai đoạn | Tên Task | Hỗ trợ | Phụ thuộc | Đầu ra / Bằng chứng | Tiêu chí (Điểm) | Ưu tiên | Tuần | Hạn | Trạng thái | Ghi chú |
|:---|:---|:---|:---:|:---:|:---|:---|:---:|:---:|:---:|:---:|:---|
| **S0-3-CM** | 0. Chuẩn bị | Cài trên máy: Flutter stable, FlutterFire CLI, Android device/emulator, ADB | — | — | `flutter doctor` không lỗi | — | Cao | 1 | | Chờ nghiệm thu | Có toolchain/emulator và logs; CLI một số lệnh chưa trong PATH; chờ nghiệm thu. |
| **S0-4** | 0. Chuẩn bị | Tạo Firebase project (Spark), mời cả nhóm; ghi lại project ID | — | S0-1 | Project ID ghi trong README | Firebase 2.0 | Cao | 1 | | Đang thực hiện | Project longvita-8da7e, ID trong README; còn mời team và DEC-01. |
| **S2-3** | 2. Architect | `lib/theme/`: ColorScheme, TextTheme, spacing/radius/elevation theo Tokens-to-Flutter (64 Variables, radius 4/8/12/16/full, action `#476429`) | Thắng | S0-6 | Theme dùng cho toàn app | Fidelity 0.5 | Cao | 1 | | Chờ nghiệm thu | Theme/fonts/tokens có commit 6dfddf9 và QA; chờ nghiệm thu UI. |
| **S2-4** | 2. Architect | Xây dựng 9 widget dùng chung (Button, TextField, Card, Navigation, AppBar, Dialog, Loading, Empty, Error) có variants/states, Semantics, $\ge 48$ dp | Hoàng | S2-3 | Thư mục `lib/widgets/` | Fidelity 0.5; A11y 0.25 | Cao | 2 | | Chờ nghiệm thu | Đủ common widgets và QA; chờ Hoàng review usage/PM-user preview. |
| **S3-1** | 3. Integrate | Chạy `flutterfire configure`, tích hợp `google-services.json`; ghim phiên bản trong `pubspec.yaml` | — | S0-4, S2-2 | Firebase khởi tạo được | Firebase 2.0 | Cao | 2 | | Đang thực hiện | Firebase init và google-services build được; Crashlytics Gradle còn phối hợp Thái An. |
| **S3-2** | 3. Integrate | Đăng ký SHA-1 (debug) của máy cả 4 thành viên vào Firebase project console | Thắng, Hoàng, Thái An | S3-1 | Mọi máy đăng nhập được | Auth 0.25 | Cao | 2 | | Đang thực hiện | Đã có SHA Charlie; còn SHA và kiểm máy của ba thành viên. |
| **S3-3** | 3. Integrate | Xây dựng `AuthService` + Google Sign-In; lưu doc `users/{uid}` có `role: 'user'`; xử lý hủy/mất mạng rõ ràng (không crash) | — | S3-2, S2-1 | Sign-in chạy mượt mà | Auth 0.25 | Cao | 2 | | Chờ nghiệm thu | Google success/cancel/restore có evidence; failure/profile có tests; A1 chờ Thắng. |
| **S3-4** | 3. Integrate | Dựng màn hình Sign-in (Google) theo thiết kế bổ sung ở S1-5, sử dụng 100% widget design system | Thắng | S2-4, S1-5 | Màn hình Sign-in | Flows 1.0 | Cao | 2 | | Chờ nghiệm thu | Sign-in có evidence Android và widget states; A5/ngôn ngữ chờ chốt. |
| **S3-5** | 3. Integrate | Xử lý Sign-out: xóa toàn bộ dữ liệu người dùng cục bộ, điều hướng quay về màn hình Sign-in | — | S3-3 | Sign-out chạy được | Auth 0.25 | Cao | 2 | | Đang thực hiện | PM-S3-5-01/02 Closed; còn Hoàng duyệt A3 và A/B native. |
| **S3-7** | 3. Integrate | Viết `firebase/storage.rules`: mỗi user chỉ đọc/ghi `reports/{uid}/...`; deploy rules lên console | — | S3-1 | `firebase/storage.rules` | Storage 0.25 | Cao | 2 | | Skeleton | Rules Storage mới skeleton, chưa deploy/test A-B; chờ DEC-01. |
| **S3-9** | 3. Integrate | Chụp bằng chứng Auth: màn signed-out & signed-in, tab Users console (project ID khớp `google-services.json`) | — | S3-5 | `evidence/auth/` | Auth 0.25 | Trung bình | 2 | | Chờ nghiệm thu | Evidence Auth tại evidence/auth/S3-9-20261102; chờ nghiệm thu. |
| **S4-10** | 4. Features | Triển khai `ReportService`: sinh file PDF thực đơn phản ánh đúng nội dung người dùng đang xem | Hoàng | S4-3 | File PDF được tạo | Data 0.75 | Cao | 3 | | Đang thực hiện | PDF TTF/local store kiểm bằng fixture; thiếu active plan, nối export/open-share/Android. |
| **S4-11** | 4. Features | Triển khai `StorageService`: upload vào `reports/{uid}/...`, hiện progress + URL tải; xử lý mất mạng/từ chối/hủy | — | S4-10, S3-7 | Upload file chạy được | Storage 0.25 | Cao | 3 | | Skeleton | Upload skeleton; thiếu typed error/cancel/stable retry ID và live proof. |
| **S4-12** | 4. Features | Tích hợp FCM: xin quyền thông báo Android 13+, nhận ở fg/bg/terminated, lưu danh sách trong app, tap mở màn hình | — | S3-1 | Notification center | FCM 0.5 | Cao | 3 | | Đang thực hiện | PM-FCM-01 Closed tại c5059d8; gateway tests pass; còn route/history/token/push thật. |
| **S4-13** | 4. Features | Dựng màn hình Profile + **Firebase Demo Area** (notification center, export/upload; chừa chỗ cho RC và Crashlytics) | Thắng | S4-11, S4-12, S1-5 | Màn hình Profile hoàn chỉnh | Flows 1.0; Firebase 2.0 | Cao | 3 | | Chưa bắt đầu | Chưa có Profile; phối hợp Hoàng chuyển demo UI khỏi Home. |
| **S4-14** | 4. Features | Gắn Semantics labels cho các màn của mình (Sign-in, Profile, Notification list, Export actions) | — | S4-13 | Semantics đầy đủ | Test quality 0.5 | Trung bình | 3 | | Đang thực hiện | Mới kiểm phần Sign-in/common widgets; Profile/export/push/TalkBack chưa đủ. |
| **S4-15** | 4. Features | Chụp bằng chứng Storage (console file list) và FCM (test message nhận ở cả 3 trạng thái) | — | S4-11, S4-12 | `evidence/storage/`, `evidence/fcm/` | Storage 0.25; FCM 0.5 | Trung bình | 3 | | Chưa bắt đầu | Chưa có bộ evidence Storage/FCM thật. |
| **S5-4** | 5. Instrument | Gắn mã ghi nhận analytics event cho các hành động: `login`, `logout`, `export_report` | Thái An | S5-2, S4-11 | Event login/logout/export | Analytics 0.5 | Cao | 3 | | Đang thực hiện | Callers theo Analytics API mới; thiếu DebugView và export live. |
| **S6-4** | 6. Test | Viết `e2e_test/test_auth.py`: sign-in (Google account picker native), sign-out, hủy sign-in; assert dữ liệu trả về | Thái An | S6-2 | `test_auth.py` | Test quality 0.5 | Cao | 3 | | Chưa bắt đầu | Chưa có test_auth.py ARTEMIS thật; chờ S6-2. |
| **S6-7** | 6. Test | Viết `e2e_test/test_export.py` (export + upload) và test mở push notification từ Android notification shade | Thái An | S6-2 | `test_export.py`, `test_profile.py` | Test plan 0.5 | Cao | 3 | | Chưa bắt đầu | Chưa có test_export/profile ARTEMIS thật; chờ harness/export/push. |
| **S6-14** | 6. Test | Sửa lỗi ứng dụng / bổ sung thuộc tính Semantics khi kiểm thử ARTEMIS phát hiện lỗi (thuộc phạm vi của mình) | — | S6-9 | Fix commit | Test quality 0.5 | Trung bình | 4 | | Chưa bắt đầu | Chưa có fix từ formal ARTEMIS run; PM unit findings không thay task này. |
| **S7-1-CM** | 7. Review | Mở PR cho phần của mình; chạy $\ge 1$ công cụ AI review (CodeRabbit/Copilot/SonarCloud); lưu output | — | S6-1 | PR + output trong `evidence/review/` | Review 0.5 | Cao | 4 | | Đang thực hiện | Đang chuẩn bị PR vào main; chưa có PR/AI PR review output khi cập nhật. |
| **S7-2-CM** | 7. Review | Ghi $\ge 1-2$ findings (file:dòng, loại, tóm tắt), quyết định Accept/Modify/Reject kèm lý do; kê khai AI tools | — | S7-1-CM | Dòng ghi trong `code-review.md` | Findings 0.25 | Cao | 4 | | Chưa bắt đầu | Chưa có bảng findings Stage 7 trên PR; không tự quy PM findings thành CR. |
| **S7-3-CM** | 7. Review | Sửa $\ge 1$ finding đã chấp nhận; commit riêng ghi ID finding; dẫn link commit vào bảng | — | S7-2-CM | Fix commit liên kết | Fixes 0.25 | Cao | 4 | | Chưa bắt đầu | Chưa có accepted PR finding/fix theo Stage 7; PM fix commits ghi riêng. |
| **S8-3** | 8. Report | Soạn mục Báo cáo: Firebase Auth, Storage, FCM — mỗi dịch vụ 1 mục kèm failure handling và ảnh chụp console | — | S4-15 | Bản thảo gửi Thắng | Firebase 2.0 | Cao | 4 | | Chưa bắt đầu | Chưa soạn report chính thức; Auth đã có nguồn evidence. |
| **S8-7** | 8. Report | Soạn Slide: 1 slide cho mỗi dịch vụ Auth, Storage, FCM — cơ chế xử lý lỗi + bằng chứng minh họa | — | S8-3 | Slide gửi Thắng | Slides 1.0 | Cao | 4 | | Chưa bắt đầu | Chưa soạn slides dịch vụ. |
| **S8-12** | 8. Report | Quay video: sign-in, export + upload (mở console xác minh), nhận push notification từ xa | — | S6-1 | Đoạn video clip gửi Thắng | Video 1.0 | Cao | 4 | | Chưa bắt đầu | Chưa có clip bàn giao cuối. |
| **S8-17-CM** | 8. Report | Cập nhật worklog cá nhân `docs/worklog-charlie.md` để đối chiếu lịch sử Git | — | S8-16 | `docs/worklog-charlie.md` | Mục 11 | Thấp | 4 | | Chưa bắt đầu | Chưa có worklog Charlie chính thức; chỉ ghi từ lịch sử/evidence thật. |
| **S9-5-CM** | 9. Nộp bài | Luyện vấn đáp 5 phút: chạy 1 test ARTEMIS, đổi 1 giá trị Remote Config live, giải thích 1 ViewModel và 1 review | — | S8-16 | Sẵn sàng vấn đáp | Mục 11 | Cao | 4 | | Chưa bắt đầu | Chưa luyện vấn đáp theo kịch bản cuối. |
