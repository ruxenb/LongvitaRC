# Charlie — bàn giao kỹ thuật cho team, 03/11/2026

Đây là bàn giao nền tảng mobile của cùng Assignment, không tuyên bố toàn bộ các task đã hoàn tất. Lab 3 = Assignment; Figma Lab 2 là tham chiếu đóng băng, UI được cải thiện trong code.

**Đã merge vào `main` theo yêu cầu của leader, sau khi Charlie tự kiểm tra:** [#1 — design system, Firebase Auth và nền tảng PDF/FCM](https://github.com/ruxenb/LongvitaRC/pull/1), [#2 — lưu, mở, chia sẻ PDF](https://github.com/ruxenb/LongvitaRC/pull/2). [#3 — màn Profile và Firebase Demo Area](https://github.com/ruxenb/LongvitaRC/pull/3), [#4 — push thật, Storage trên emulator, Crashlytics, harness ARTEMIS](https://github.com/ruxenb/LongvitaRC/pull/4), [#5 — thông báo khi app đang mở, TalkBack, nháp FCM](https://github.com/ruxenb/LongvitaRC/pull/5) (merge 03/11, `30ca6e3`). Cả năm PR **chưa có review trên GitHub của thành viên khác hay AI**, nên các điểm cần chốt bên dưới vẫn còn mở. CodeRabbit chưa được cài, chờ leader xác nhận; S7-1-CM sẽ chạy AI review trên PR kế tiếp, và PR đó chỉ merge sau khi có output AI review.

Thắng, Hoàng và Thái An đã đồng ý các phần của PR #4 chạm vào việc của họ (theo Charlie, 02/11).

**Đợt 03/11, [PR #5](https://github.com/ruxenb/LongvitaRC/pull/5), đã vào `main` (`30ca6e3`) sau khi lỗi PM-FCM-02 được xác minh đã sửa; chưa có AI review:** tin đến khi app đang mở hiện thanh thông báo có nút "Xem" (S4-12), TalkBack thật (S4-14), nháp báo cáo FCM (S8-3). Analyzer sạch, 270/270 tests. Đã sửa lỗi tìm thấy khi review (PM-FCM-02): thanh thông báo của phiên cũ còn trên Sign-in sau khi đăng xuất, và nút "Xem" của nó mở được Profile khi chưa đăng nhập. Giờ mọi thao tác của thanh thông báo kiểm đúng phiên lúc chạy, và nội dung thông báo của phiên đã hết tự gỡ khi tới lượt hiện, kể cả khi đang chờ sau snackbar khác; snackbar của màn khác giữ nguyên. Có regression cho đăng xuất, A → B, A → đăng xuất → A và hàng đợi nhiều thông báo; đã thử đăng xuất trên emulator với tin thật. **Thắng xem giúp `auth_gate.dart`.**

## Mức hoàn thành công việc

```text
Toàn dự án   [███████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]  28%
Charlie      [████████████████████████░░░░░░░░░░░░░░░░]  61%
```

Code và tích hợp Firebase (18 task, giai đoạn 0–5): **82%**. Test, AI review, báo cáo, nộp bài (11 task, giai đoạn 6–9): **27%**.

Mỗi task chấm theo phần tiêu chí nghiệm thu đã đạt và có bằng chứng. Đây là ước lượng của Charlie, chưa được leader duyệt. Số của Thái An, Thắng, Hoàng lấy từ bảng task (đã xong 100%, đang làm 50%), nên có thể thấp hơn thực tế. Task đã nghiệm thu chính thức: 0/29.

<details>
<summary>Chi tiết 29 task</summary>

| Task | % | Lý do |
|---|---:|---|
| S0-3-CM | 95% | Công cụ chạy đủ; còn FlutterFire CLI chưa có trong PATH |
| S0-4 | 70% | Project, README, 2/3 thành viên; còn Hoàng và DEC-01 |
| S2-3 | 100% | Đủ theo tiêu chí, chờ nghiệm thu |
| S2-4 | 100% | Đủ theo tiêu chí, chờ nghiệm thu |
| S3-1 | 90% | Build, init, Crashlytics đều chạy; còn chốt ghim phiên bản |
| S3-2 | 25% | 1/4 máy |
| S3-3 | 90% | Chạy thật; lỗi mạng và lỗi hồ sơ mới test bằng fake |
| S3-4 | 95% | Đủ trạng thái; còn chốt layout và ngôn ngữ |
| S3-5 | 85% | Chạy thật; còn A/B bằng hai tài khoản và Hoàng duyệt A3 |
| S3-7 | 70% | Rules và 14 test trên emulator; còn deploy lên project thật |
| S3-9 | 100% | Đủ theo tiêu chí, chờ nghiệm thu |
| S4-10 | 80% | PDF, lưu, mở, chia sẻ xong; còn thực đơn thật từ S4-3 |
| S4-11 | 85% | Đủ các ca trên emulator; còn upload lên project thật |
| S4-12 | 90% | Push thật 3 trạng thái, lịch sử, bấm mở màn, thanh thông báo khi app đang mở; còn token theo user, route theo đích |
| S4-13 | 90% | Đủ khu vực; còn upload thật và đổi Remote Config từ Console |
| S4-14 | 85% | TalkBack thật: Sign-in đi hết, Profile phần lớn; còn phần cuối Profile và máy thật |
| S4-15 | 50% | FCM đủ; Storage trên Console chờ DEC-01 |
| S5-4 | 80% | login, logout đã thấy trên DebugView; còn export_report thật |
| S6-4 | 40% | Script đã viết; chưa chạy, cần key và 3 lần chạy |
| S6-7 | 35% | Script đã viết; chưa chạy, cần key và Storage |
| S6-14 | 0% | Chờ lần chạy ARTEMIS chính thức |
| S7-1-CM | 40% | Đã có PR; còn chạy AI review và lưu output |
| S7-2-CM | 0% | Chờ output AI review |
| S7-3-CM | 0% | Chờ finding được chấp nhận |
| S8-3 | 75% | Nháp đủ Auth, FCM, Storage (Storage là emulator); còn ảnh Console Storage và gửi Thắng |
| S8-7 | 40% | Nội dung 3 slide có ảnh bằng chứng; còn dựng theo template chung |
| S8-12 | 0% | Chưa quay; bằng chứng Auth và push đã sẵn |
| S8-17-CM | 70% | Đã ghi theo từng đợt; cập nhật đến khi chốt |
| S9-5-CM | 0% | Làm cuối dự án |

</details>

## Tiến độ 29 task

| Trạng thái | Số lượng | IDs |
|---|---:|---|
| Có kiểm chứng/evidence, chờ nghiệm thu | 6 | S0-3-CM, S2-3, S2-4, S3-3, S3-4, S3-9 |
| Đang thực hiện / PR | 18 | S0-4, S3-1, S3-2, S3-5, S3-7, S4-10, S4-11, S4-12, S4-13, S4-14, S4-15, S5-4, S6-4, S6-7, S7-1-CM, S8-3, S8-7, S8-17-CM |
| Chưa bắt đầu | 5 | S6-14, S7-2-CM, S7-3-CM, S8-12, S9-5-CM |
| **Tổng** | **29** | |

Chi tiết IDs/owner/dependency tại [task Charlie](task-charlie.md) và [master 112 task](danh-sach-task-full.md). Chưa tự đánh Done thay leader; S7-1 đang thực hiện, chưa có AI PR review output để tính đủ Stage 7. Merge vào `main` không đồng nghĩa task đã được nghiệm thu.

## Phần đã bàn giao

- **UI:** tokens/theme, Fraunces/Newsreader/Quicksand bundle cùng license, 9 nhóm widgets và supporting components. Team dùng `package:longvita/widgets/longvita_widgets.dart`; gallery và QA trong `test/qa/`. Screen integration/visual acceptance còn theo owner.
- **Auth:** Firebase project `longvita-8da7e`, app ID `vn.edu.fpt.longvita`, google-services; typed Auth outcomes, profile recovery, bootstrap gate, restore/logout và session epoch. UID/profile lỗi không bị báo thành cancel. Đổi phiên loại response/progress/error muộn; không xóa cloud records của user cũ.
- **Firestore AUD-11:** schema/role/status/owner constraints và 41 emulator tests. Theo ghi nhận của Charlie, rules đã publish lên project trước PR; Hoàng/Thắng còn cần review các policy bên dưới.
- **Analytics:** callers theo API mới của Thái An. Export params lấy từ PDF bytes thực. Chưa có eating window thật thì không gửi generate event; Hoàng nối dữ liệu S02, không điền số giả. `login` (`method=google`) và `logout` đã thấy trên [DebugView](../../evidence/analytics/S5-4-debugview-20261102/README.md), mỗi lần thao tác một event; `export_report` chưa kiểm thật vì chờ DEC-01.
- **FCM preparation:** gateway và 4 callback, parser, inbox/dedup theo phiên. Payload gốc đi cùng entry đã chấp nhận; first accepted message thắng trong một phiên, tap duplicate dùng target đã chấp nhận. Chưa phải live FCM hoàn chỉnh.
- **Storage (S3-7, S4-11):** lỗi có kiểu (mất mạng, bị từ chối, chưa cấu hình, hết dung lượng), hủy thật, thử lại cùng ID. Rules owner-only có 14 test. Upload thành công bằng SDK thật **trên Storage Emulator**, [bằng chứng](../../evidence/storage/S4-11-emulator-20261102/README.md). Chưa deploy và chưa có file trên project thật vì DEC-01.
- **FCM thật (S4-12, S4-15):** tin từ Console về đủ foreground, background, terminated; bấm tin mở Profile; lịch sử lưu trên máy theo UID. [Bằng chứng](../../evidence/fcm/S4-15-push-20261102/README.md). Tin đến khi app đang mở hiện thanh thông báo trên màn đang xem, nút "Xem" mở hộp thư ([bằng chứng 03/11](../../evidence/fcm/S4-12-foreground-20261103/README.md)). Đây là contract tạm nhóm đã đồng ý.
- **TalkBack (S4-14):** [chạy thật trên emulator](../../evidence/a11y/S4-14-talkback-20261103/README.md). Sign-in đọc đúng thứ tự, nút nào cũng có tên. Profile đi tuần tự đến hộp thư; phần Remote Config, Crashlytics mới kiểm nhãn.
- **Crashlytics:** có plugin Gradle, [crash thử đã lên Console](../../evidence/crashlytics/S4-13-test-crash-20261102/README.md). **Thái An cần chốt:** chưa nối `FlutterError.onError` và `PlatformDispatcher.onError` (S5-6), nên lỗi Flutter không bắt được chưa tự lên Crashlytics.
- **ARTEMIS (S6-4, S6-7):** bỏ `DummyArtemisClient` trả SUCCESS giả, dùng `artemis-client` thật, ghim commit `351ca84`, viết `test_auth.py`, `test_export.py`, `test_profile.py`. **Chưa chạy lần nào:** cần key mô hình (S0-5). Thiếu SDK hoặc daemon thì test fail.
- **Profile (S4-13), đã vào `main` qua PR #3:** danh tính, đăng xuất, xuất PDF với tiến độ và URL, hộp thư FCM, giá trị và nút cập nhật Remote Config, crash thử có xác nhận. Có route `/profile`, Home bỏ khối xuất tạm và chỉ còn lối sang Profile, đăng xuất từ Profile có hộp xác nhận theo TC-11. Nút đăng xuất trên Home vẫn không hỏi xác nhận, Hoàng xem có đổi không.
- **PDF (S4-10), đã vào `main` qua PR #2:** TTF tiếng Việt regular/bold, lưu trên máy trước khi upload, export ID giữ nguyên khi thử lại, mở và chia sẻ qua `IReportViewer`. Mỗi lúc chỉ chạy một export hoặc retry, nên file, URL, tiến độ và trạng thái luôn thuộc cùng một lần xuất. Đăng xuất hủy upload đang chạy và xóa PDF của user đó trên máy, không đụng bản đã lên Storage. Từ PR #4, Home không còn các nút xuất, mở, chia sẻ, thử lại; mọi thao tác PDF nằm ở Profile. Chưa chứng minh đúng plan đang xem vì chờ S4-3.

Các commits chức năng: `6dfddf9` (UI), `56b1896` (Auth), `4e4bffd` (Firebase/rules), `9d76623` (session guards), `9ecc806` (Analytics callers), `7a9fa8c` (FCM), `40e47a1` (PDF), `2d547c7` (FCM recipient/dedup fix).

## Kiểm chứng và giới hạn

**`main` tại `6f58786`, sau khi merge PR #1 và #2:** analyzer sạch, 168/168 tests, rules 41/41 trên emulator. APK debug build được trên nhánh PDF ngay trước khi merge, cùng nội dung code với `main`. **PR #4, trước khi merge:** analyzer sạch, APK debug build được, 251/251 tests, rules 55/55 (41 Firestore, 14 Storage). Với rules mở toang, đúng 9 ca từ chối của Storage fail, [log](../../evidence/rules/S3-7-20261102/).

**PR #3:** analyzer sạch, 191/191 tests; chạy trên emulator, xem [bằng chứng](../../evidence/ui/S4-13-profile-20261102/README.md), gồm cả phần chưa kiểm chứng.

Code `2d547c7` / HEAD báo cáo `f1f397e` đã được kiểm độc lập: analyzer sạch, **133/133 unit/widget tests pass**, APK debug build thành công. Ca tái hiện recipient collision giữ nguyên expected đã pass. Hai lỗi response muộn qua đổi phiên và lỗi raw notification cache đã được xác nhận sửa; không tự đổi các fix này thành evidence PR Stage 7 hoàn tất.

- [Analyzer](../../evidence/review/PM-FCM-01-VERIFY/analyze.txt), [133 tests](../../evidence/review/PM-FCM-01-VERIFY/flutter-test.txt), [APK build](../../evidence/review/PM-FCM-01-VERIFY/build-apk-debug.txt), [recipient regression](../../evidence/review/PM-FCM-01-VERIFY/original-pm-repro.txt).
- [Rules 41/41](../../evidence/rules/AUD-11-20261102/new-rules-run.txt) là kết quả emulator trước; không chạy lại sau FCM fix vì `firebase/` không đổi. Không coi emulator là live rules/role evidence đầy đủ.
- [Auth thật](../../evidence/auth/S3-9-20261102/README.md): success/cancel/restore/logout với SHA Charlie. Ba máy còn lại, network/profile lỗi native và A/B native chưa được kiểm đầy đủ.
- (Ảnh chụp tại `2d547c7`, đã cũ.) Khi đó FCM tests dùng fake gateway, history chỉ ở RAM, chưa push thật. Từ PR #4: lịch sử lưu trên máy theo UID, push thật 3 trạng thái, bấm tin mở Profile; còn thiếu token theo user.
- [PDF trên Android](../../evidence/pdf/S4-10-export-20261102/) và [xuất chồng nhau](../../evidence/pdf/PM-PDF-01/): 168/168 tests, chạy thật trên emulator: font nạp được, file lưu trong `app_flutter/reports/<uid>/`, upload lỗi thì file còn và có thông báo, mở màn xem trước, mở cửa sổ chia sẻ, bấm xuất liên tiếp 3 lần chỉ tạo 1 file, thử lại khi upload lỗi không tạo file mới. Plan thử dùng món hard-code (A9), không chứng minh đúng plan đang xem. Upload và thử lại **thành công** chỉ test bằng fake vì project chưa có Storage. Trạng thái khóa nút trong lúc chạy lúc đó chỉ test ở ViewModel; từ PR #3 có thêm widget test trên Profile. Chưa thử trên máy thật.
- ARTEMIS thật, AI review trên PR và deliverables report/slides/video/worklog chưa hoàn tất. Các ví dụ trong `docs/code-review.md` không được tính là findings thật.

## Các điểm reviewer/team cần chốt

1. **Thắng (A1/A2):** Auth interface, bootstrap/DI/AuthGate/Back, route intent và điểm router ready cho FCM.
2. **Hoàng (A3/A5):** session guards/clearSession của MealPlan/Ingredient VM, UI Sign-in và active plan/revision S4-3. **Hoàng/Thái An:** dữ liệu generate Analytics và loại recipe hard-code fallback A9 khi catalog rỗng.
   **Thắng, khi gộp `d9d0a90`:** commit này gửi `generate_meal_plan` với `eating_window_hours: 12`, `fish_meals_count: 2` cố định và `has_shopping_list` suy từ nguyên liệu của món. Khi gỡ xung đột, `main` giữ cách cũ: chưa có dữ liệu S02 thì không gửi event, đếm cá từ plan, `has_shopping_list: 0` vì PDF chưa có danh sách đi chợ. Lấy theo Thắng phần `age >= 65`, đúng với analytics plan. Nếu nhóm muốn khác thì nói để đổi.
3. **Hoàng/Thắng (AUD-11 B1–B5):** rejected plan có được resubmit, staff tự duyệt plan, archive/schema/nested data và kiểu createdAt. Rules/test hiện theo schema model; thay policy phải sửa và kiểm lại.
4. **Thái An/leader (DEC-01):** Guide yêu cầu Storage upload, Final loại Storage; quyết định áp dụng/billing trước S3-7/S4-11. Không chặn Auth hoặc PDF local vì việc này.
5. **FCM contract còn mở:** route intent của `meal_plan`/`announcement` (Thắng); history local theo UID hay Firestore/schema/rules (Hoàng/Thắng); token theo user hay topic và cách xử lý tin thiếu `recipient_uid` (Thái An/Thắng). Hiện tin không recipient chờ người login kế, chưa được team chốt cho production.
6. **Charlie/team:** mời đủ thành viên Firebase, nhận SHA-1/SHA-256 và kiểm Google Sign-in trên từng máy; quyền Console và SHA/Auth là các đầu việc riêng. Đồng thời chốt ngôn ngữ UI và font Roboto cho PDF.
7. **PDF cần chốt:** app làm theo đề xuất tối thiểu: giữ file để thử lại, mở, chia sẻ trong phiên; khi đăng xuất xóa file của user đó, không đụng dữ liệu cloud. Sau khi mở lại app vẫn chưa xem lại được file cũ. Nếu muốn giữ qua đăng xuất, nhóm cần chốt thêm retention, quota, cách khôi phục và thao tác xóa. Hành vi này chưa được nhóm duyệt và dễ đổi.

## Contract FCM tạm (S4-12)

Thắng, Hoàng, Thái An đã đồng ý dùng tạm (theo Charlie, 02/11): mọi tin bấm vào đều mở Profile, lịch sử lưu trên máy theo UID và còn sau đăng xuất, thiếu `recipient_uid` thì hiện cho người đang đăng nhập, token chỉ dùng để thử. Các câu hỏi dưới đây vẫn cần chốt cho bản cuối.

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
- Đăng xuất: xóa inbox trong bộ nhớ và tin đang chờ, lịch sử của user đó vẫn ở trên máy. Tin đến khi chưa đăng nhập chờ tới lần đăng nhập kế.
- Bấm tin: `AuthGate` mở Profile, mỗi tin một lần. `takePendingTarget()` vẫn giữ đích để nối route thật sau. Handler nền không điều hướng, chỉ lưu tin chờ.

**Câu hỏi cần trả lời:**

| Câu hỏi | Ai |
|---|---|
| `meal_plan`, `announcement` mở màn nào; router gọi `takePendingTarget()` khi nào; đích lỗi hiển thị ra sao | Thắng |
| Lịch sử lưu local theo UID hay Firestore; nếu Firestore thì schema, rules, read state, retention | Hoàng, Thắng |
| Gửi theo token từng user hay topic chung; có lưu token theo UID, xóa khi đăng xuất không | Thái An, Thắng |
| Tin **không có** `recipient_uid` hiện đến người đăng nhập kế tiếp: có chấp nhận không | Thái An, Thắng |

Tiếp theo: S4-10 với active plan khi có S4-3, S4-12 routing/history/token/push thật khi có contract, S4-13 gỡ khối tạm trên Home cùng Hoàng, S3-7/S4-11 khi DEC-01 rõ. Giữ nguyên ba fix regression đã xác nhận và các task owners.
