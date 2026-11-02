# Charlie — bàn giao kỹ thuật cho team, 02/11/2026

Đây là bàn giao nền tảng mobile của cùng Assignment, không tuyên bố toàn bộ các task đã hoàn tất. Lab 3 = Assignment; Figma Lab 2 là tham chiếu đóng băng, UI được cải thiện trong code.

**Đã merge vào `main` theo yêu cầu của leader, sau khi Charlie tự kiểm tra:** [#1 — design system, Firebase Auth và nền tảng PDF/FCM](https://github.com/ruxenb/LongvitaRC/pull/1), [#2 — lưu, mở, chia sẻ PDF](https://github.com/ruxenb/LongvitaRC/pull/2). `main` tại `6f58786`. Cả hai PR **chưa có review của thành viên khác hay AI**, nên các điểm cần chốt bên dưới vẫn còn mở. S7-1-CM cần chạy AI review trên PR kế tiếp.

**Chưa merge:** nhánh `feature/charlie-profile-01`, gồm màn Profile (S4-13).

## Tiến độ 29 task

| Trạng thái | Số lượng | IDs |
|---|---:|---|
| Có kiểm chứng/evidence, chờ nghiệm thu | 6 | S0-3-CM, S2-3, S2-4, S3-3, S3-4, S3-9 |
| Đang thực hiện / PR | 12 | S0-4, S3-1, S3-2, S3-5, S4-10, S4-12, S4-13, S4-14, S5-4, S7-1-CM, S8-3, S8-17-CM |
| Skeleton | 2 | S3-7, S4-11 |
| Chưa bắt đầu | 9 | S4-15, S6-4, S6-7, S6-14, S7-2-CM, S7-3-CM, S8-7, S8-12, S9-5-CM |
| **Tổng** | **29** | |

Chi tiết IDs/owner/dependency tại [task Charlie](task-charlie.md) và [master 112 task](danh-sach-task-full.md). Chưa tự đánh Done thay leader; S7-1 đang thực hiện, chưa có AI PR review output để tính đủ Stage 7. Merge vào `main` không đồng nghĩa task đã được nghiệm thu.

## Phần đã bàn giao

- **UI:** tokens/theme, Fraunces/Newsreader/Quicksand bundle cùng license, 9 nhóm widgets và supporting components. Team dùng `package:longvita/widgets/longvita_widgets.dart`; gallery và QA trong `test/qa/`. Screen integration/visual acceptance còn theo owner.
- **Auth:** Firebase project `longvita-8da7e`, app ID `vn.edu.fpt.longvita`, google-services; typed Auth outcomes, profile recovery, bootstrap gate, restore/logout và session epoch. UID/profile lỗi không bị báo thành cancel. Đổi phiên loại response/progress/error muộn; không xóa cloud records của user cũ.
- **Firestore AUD-11:** schema/role/status/owner constraints và 41 emulator tests. Theo ghi nhận của Charlie, rules đã publish lên project trước PR; Hoàng/Thắng còn cần review các policy bên dưới.
- **Analytics:** callers theo API mới của Thái An. Export params lấy từ PDF bytes thực. Chưa có eating window thật thì không gửi generate event; Hoàng nối dữ liệu S02, không điền số giả.
- **FCM preparation:** gateway và 4 callback, parser, inbox/dedup theo phiên. Payload gốc đi cùng entry đã chấp nhận; first accepted message thắng trong một phiên, tap duplicate dùng target đã chấp nhận. Chưa phải live FCM hoàn chỉnh.
- **Profile (S4-13), nhánh `feature/charlie-profile-01`:** danh tính, đăng xuất, xuất PDF với tiến độ và URL, hộp thư FCM, giá trị và nút cập nhật Remote Config, crash thử có xác nhận. Home chỉ thêm một nút mở Profile; khối xuất PDF tạm trên Home chưa gỡ, chờ thống nhất với Hoàng. Bấm vào thông báo chưa điều hướng. Route `/profile` chờ Thắng.
- **PDF (S4-10), đã vào `main` qua PR #2:** TTF tiếng Việt regular/bold, lưu trên máy trước khi upload, export ID giữ nguyên khi thử lại, mở và chia sẻ qua `IReportViewer`. Mỗi lúc chỉ chạy một export hoặc retry, nên file, URL, tiến độ và trạng thái luôn thuộc cùng một lần xuất. Đăng xuất chỉ vô hiệu hóa kết quả ở ViewModel, **chưa hủy `UploadTask` của SDK**: upload đang chạy vẫn tiếp tục cho đến khi kết thúc; hủy thật thuộc S4-11. Các nút mở, chia sẻ, thử lại trên Home là tạm thời. Chưa chứng minh đúng plan đang xem vì chờ S4-3.

Các commits chức năng: `6dfddf9` (UI), `56b1896` (Auth), `4e4bffd` (Firebase/rules), `9d76623` (session guards), `9ecc806` (Analytics callers), `7a9fa8c` (FCM), `40e47a1` (PDF), `2d547c7` (FCM recipient/dedup fix).

## Kiểm chứng và giới hạn

**`main` tại `6f58786`, sau khi merge PR #1 và #2:** analyzer sạch, 168/168 tests, rules 41/41 trên emulator. APK debug build được trên nhánh PDF ngay trước khi merge, cùng nội dung code với `main`. **Nhánh Profile:** analyzer sạch, 191/191 tests; chạy trên emulator, xem [bằng chứng](../../evidence/ui/S4-13-profile-20261102/README.md), gồm cả phần chưa kiểm chứng.

Code `2d547c7` / HEAD báo cáo `f1f397e` đã được kiểm độc lập: analyzer sạch, **133/133 unit/widget tests pass**, APK debug build thành công. Ca tái hiện recipient collision giữ nguyên expected đã pass. Hai lỗi response muộn qua đổi phiên và lỗi raw notification cache đã được xác nhận sửa; không tự đổi các fix này thành evidence PR Stage 7 hoàn tất.

- [Analyzer](../../evidence/review/PM-FCM-01-VERIFY/analyze.txt), [133 tests](../../evidence/review/PM-FCM-01-VERIFY/flutter-test.txt), [APK build](../../evidence/review/PM-FCM-01-VERIFY/build-apk-debug.txt), [recipient regression](../../evidence/review/PM-FCM-01-VERIFY/original-pm-repro.txt).
- [Rules 41/41](../../evidence/rules/AUD-11-20261102/new-rules-run.txt) là kết quả emulator trước; không chạy lại sau FCM fix vì `firebase/` không đổi. Không coi emulator là live rules/role evidence đầy đủ.
- [Auth thật](../../evidence/auth/S3-9-20261102/README.md): success/cancel/restore/logout với SHA Charlie. Ba máy còn lại, network/profile lỗi native và A/B native chưa được kiểm đầy đủ.
- FCM tests dùng fake gateway, history chỉ ở RAM; chưa push thật, chưa router/Profile/token binding.
- [PDF trên Android](../../evidence/pdf/S4-10-export-20261102/) và [xuất chồng nhau](../../evidence/pdf/PM-PDF-01/): 168/168 tests, chạy thật trên emulator: font nạp được, file lưu trong `app_flutter/reports/<uid>/`, upload lỗi thì file còn và có thông báo, mở màn xem trước, mở cửa sổ chia sẻ, bấm xuất liên tiếp 3 lần chỉ tạo 1 file, thử lại khi upload lỗi không tạo file mới. Plan thử dùng món hard-code (A9), không chứng minh đúng plan đang xem. Upload và thử lại **thành công** chỉ test bằng fake vì project chưa có Storage. Trạng thái khóa nút trong lúc chạy chỉ test ở ViewModel. Chưa thử trên máy thật.
- ARTEMIS thật, AI review trên PR và deliverables report/slides/video/worklog chưa hoàn tất. Các ví dụ trong `docs/code-review.md` không được tính là findings thật.

## Các điểm reviewer/team cần chốt

1. **Thắng (A1/A2):** Auth interface, bootstrap/DI/AuthGate/Back, route intent và điểm router ready cho FCM.
2. **Hoàng (A3/A5):** session guards/clearSession của MealPlan/Ingredient VM, UI Sign-in và active plan/revision S4-3. **Hoàng/Thái An:** dữ liệu generate Analytics và loại recipe hard-code fallback A9 khi catalog rỗng.
   **Thắng, khi gộp `d9d0a90`:** commit này gửi `generate_meal_plan` với `eating_window_hours: 12`, `fish_meals_count: 2` cố định và `has_shopping_list` suy từ nguyên liệu của món. Khi gỡ xung đột, `main` giữ cách cũ: chưa có dữ liệu S02 thì không gửi event, đếm cá từ plan, `has_shopping_list: 0` vì PDF chưa có danh sách đi chợ. Lấy theo Thắng phần `age >= 65`, đúng với analytics plan. Nếu nhóm muốn khác thì nói để đổi.
3. **Hoàng/Thắng (AUD-11 B1–B5):** rejected plan có được resubmit, staff tự duyệt plan, archive/schema/nested data và kiểu createdAt. Rules/test hiện theo schema model; thay policy phải sửa và kiểm lại.
4. **Thái An/leader (DEC-01):** Guide yêu cầu Storage upload, Final loại Storage; quyết định áp dụng/billing trước S3-7/S4-11. Không chặn Auth hoặc PDF local vì việc này.
5. **FCM contract còn mở:** route intent của `meal_plan`/`announcement` (Thắng); history local theo UID hay Firestore/schema/rules (Hoàng/Thắng); token theo user hay topic và cách xử lý tin thiếu `recipient_uid` (Thái An/Thắng). Hiện tin không recipient chờ người login kế, chưa được team chốt cho production.
6. **Charlie/team:** mời đủ thành viên Firebase, nhận SHA-1/SHA-256 và kiểm Google Sign-in trên từng máy; quyền Console và SHA/Auth là các đầu việc riêng. Đồng thời chốt ngôn ngữ UI và font Roboto cho PDF.
7. **PDF cần chốt:** hiện file PDF còn trên máy sau khi đăng xuất (chỉ xóa tham chiếu trong app), chưa giới hạn số file, và sau khi mở lại app chưa xem lại được file cũ. Đề xuất tối thiểu: giữ file để thử lại, mở, chia sẻ trong phiên; khi đăng xuất xóa file của user đó, không đụng dữ liệu cloud. Cách này bám được cả S3-5 và S4-11. Nếu muốn giữ qua đăng xuất hoặc mở lại app, nhóm cần chốt thêm retention, quota, cách khôi phục và thao tác xóa. Hành vi hiện tại chưa được duyệt.

## Đề xuất contract FCM (S4-12), chưa được duyệt

Phần này cần Thắng, Hoàng, Thái An trả lời trước khi nối router, history và thử push thật. Code đã theo đề xuất dưới đây ở `lib/models/app_notification.dart` và `lib/firebase/notification_inbox.dart`; đổi được khi nhóm chốt.

**Payload, các trường trong `data`:**

| Trường | Bắt buộc | Ý nghĩa |
|---|---|---|
| `message_id` | Có, nếu thiếu thì dùng ID của FCM | Khóa chống trùng |
| `schema_version` | Khi có target | Hiện là `"1"` |
| `target_type`, `target_id` | Khi tin cần mở một màn | Hiện nhận `meal_plan`, `announcement`. Không nhận route string từ push |
| `recipient_uid` | Khi tin dành riêng một user | Khác user đang đăng nhập thì tin bị bỏ |

**Hành vi hiện có:**
- Target sai hoặc thiếu: tin vẫn vào inbox, không điều hướng.
- Trùng `message_id` trong một phiên: tin được chấp nhận đầu tiên thắng.
- Đăng xuất: xóa inbox và tin đang chờ. Tin đến khi chưa đăng nhập chờ tới lần đăng nhập kế.
- Router lấy đích bằng `NotificationService.takePendingTarget()`, mỗi tin một lần. Handler nền không điều hướng và chưa lưu gì.

**Câu hỏi cần trả lời:**

| Câu hỏi | Ai |
|---|---|
| `meal_plan`, `announcement` mở màn nào; router gọi `takePendingTarget()` khi nào; đích lỗi hiển thị ra sao | Thắng |
| Lịch sử lưu local theo UID hay Firestore; nếu Firestore thì schema, rules, read state, retention | Hoàng, Thắng |
| Gửi theo token từng user hay topic chung; có lưu token theo UID, xóa khi đăng xuất không | Thái An, Thắng |
| Tin **không có** `recipient_uid` hiện đến người đăng nhập kế tiếp: có chấp nhận không | Thái An, Thắng |

Tiếp theo: S4-10 với active plan khi có S4-3, S4-12 routing/history/token/push thật khi có contract, S4-13 gỡ khối tạm trên Home cùng Hoàng, S3-7/S4-11 khi DEC-01 rõ. Giữ nguyên ba fix regression đã xác nhận và các task owners.
