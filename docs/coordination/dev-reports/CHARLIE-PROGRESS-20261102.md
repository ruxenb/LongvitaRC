# Tiến độ Charlie — đối chiếu CHARLIE_TASK_GUIDE, 02/11/2026

Đối chiếu [CHARLIE_TASK_GUIDE](../CHARLIE_TASK_GUIDE.md), cập nhật bởi Codex PM theo xác nhận đóng lỗi tại **`c5059d8`**; code được kiểm tại `f1f397e` gồm fix `2d547c7`. Nhánh `feature/charlie-auth-01` đã tích hợp main `614e731`; **chưa có PR vào main khi kiểm tra GitHub trong lượt cập nhật này**. Người dùng sẽ mở PR để Thái An/Thắng/team preview và quyết định merge. Dùng [title/body PR đã chuẩn bị](../CHARLIE_PR_MAIN_DESCRIPTION.md).

Đây là tiến độ implementation/evidence và kết quả review có giới hạn, **không phải tuyên bố cả 29 task đã Done/Accepted**. Đã đồng bộ trạng thái 29 task Charlie trong file cá nhân và master, giữ nguyên IDs/owners/dependencies; trạng thái thành viên khác do owner/leader cập nhật. Closed của finding không thay nghiệm thu toàn task.

**Ký hiệu** theo guide mục 3.4: ✅ verified · 🟡 implemented một phần · 🧱 mới có skeleton · ⬜ chưa có.

## Tóm tắt

| Trạng thái | Số task | Tasks |
|---|---:|---|
| ✅ Verified, chờ nghiệm thu | 6 | S0-3-CM, S2-3, S2-4, S3-3, S3-4, S3-9 |
| 🟡 Đang thực hiện / chuẩn bị PR | 9 | S0-4, S3-1, S3-2, S3-5, S4-10, S4-12, S4-14, S5-4, S7-1-CM |
| 🧱 Skeleton | 2 | S3-7, S4-11 |
| ⬜ Chưa bắt đầu | 12 | S4-13, S4-15, S6-4, S6-7, S6-14, S7-2-CM, S7-3-CM, S8-3, S8-7, S8-12, S8-17-CM, S9-5-CM |
| **Tổng** | **29** | |

**PM kiểm độc lập tại `f1f397e`, code gồm fix `2d547c7`:** analyzer sạch, **133/133 tests pass**, reproduction gốc PM-FCM-01 pass giữ nguyên expected, APK debug build thành công. [PM xác nhận và logs](../PM_REREVIEW_914508c.md#7-xác-nhận-bản-sửa-pm-fcm-01--2d547c7--head-f1f397e) đã push trong `c5059d8`. **PM-S3-5-01, PM-S3-5-02 và PM-FCM-01 đều Closed — verified trong phạm vi kiểm.** Rules 41/41 là kết quả lần trước, không chạy lại vì `firebase/` không đổi; Auth thật do Dev ghi tại `40e47a1`. Lượt cập nhật tiến độ này chỉ sửa docs, không giả kết quả run mới.

Không chuyển 6 task có evidence thành phần trăm hoàn thành toàn bài: UI/contract/native và các dependency còn phải nghiệm thu. S7-1-CM mới **chuẩn bị PR tích hợp sớm**, chưa có output AI review trên PR và chưa đạt đầy đủ Stage 7.

## Theo đợt triển khai (guide mục 9)

| Đợt | Tình trạng | Còn thiếu |
|---|---|---|
| C0 Khóa đầu vào | 🟡 | Mời thành viên, DEC-01 |
| C1 Nền UI | ✅ | Codex/Charlie nghiệm thu, Hoàng review cách dùng |
| C2 Auth end to end | 🟡 | A3 của Hoàng cho S3-5, SHA của ba thành viên, S3-7 |
| C3 PDF/Storage | 🟡 | PDF có font tiếng Việt và lưu local bằng fixture; chờ S4-3 của Hoàng và DEC-01 |
| C4 FCM/Profile | 🟡 | PM-FCM-01 Closed; có service/contract đề xuất; chờ route/history/token/recipient policy/push thật; Profile chưa bắt đầu |
| C5 Kiểm thử/review | 🟡 Chuẩn bị PR | PR tích hợp chuẩn bị cho leader preview; ARTEMIS thật và AI review Stage 7 chưa thực hiện |
| C6 Bàn giao cuối | ⬜ | Chưa bắt đầu |

## Đánh dấu 29 task

| | Task | Note ngắn |
|---|---|---|
| ✅ | **S0-3-CM** Toolchain | Flutter 3.47.6, FlutterFire 1.4.1, ADB 1.0.41, emulator. `flutterfire` và `adb` chưa có trong PATH; Firebase CLI chỉ có trong `firebase/node_modules` |
| 🟡 | **S0-4** Firebase project | Đã tạo `longvita-8da7e`, gói Spark, ID đã ghi trong README. **Thiếu:** mời 3 bạn, chốt DEC-01 |
| ✅ | **S2-3** Theme | Token, typography, font đã có, kèm QA test và ảnh. Commit `6dfddf9` |
| ✅ | **S2-4** 9 widget | Đủ 9 nhóm và widget phụ, kèm QA test. Chờ Hoàng review cách dùng |
| 🟡 | **S3-1** Bootstrap | Plugin `google-services` 4.5.0 build được trên AGP 9.1, Firebase init thành công trên emulator. **Thiếu:** plugin Crashlytics (cùng Thái An). Chưa chạy `flutterfire configure` vì đã cấu hình qua Console, nên chưa có `firebase_options.dart` |
| 🟡 | **S3-2** SHA | Mới có SHA của máy Charlie. **Thiếu:** SHA của Thắng, Hoàng, Thái An |
| ✅ | **S3-3** AuthService | Đăng nhập, hủy thật đạt; tạo `users/{uid}` với `role: user`. Lỗi mạng và lỗi profile mới test bằng fake |
| ✅ | **S3-4** Sign-in | Chạy trên Android, đủ các trạng thái, không overflow khi text scale 2.0 ở 360dp. Chờ Hoàng chốt thiết kế (A5) |
| 🟡 | **S3-5** Logout | **PM đã đóng hai lỗi tác vụ muộn** (`9d76623`). Task chưa xong: chờ Hoàng duyệt guard và `clearSession()` (A3), A/B trên thiết bị thật chưa chạy. Về Sign-in thật đạt; Back và A/B mới test bằng widget/unit test |
| 🧱 | **S3-7** Storage rules | File rules đã có từ skeleton, **chưa deploy, chưa test A/B**. Storage cần Blaze: chờ DEC-01 |
| ✅ | **S3-9** Bằng chứng Auth | `evidence/auth/S3-9-20261102/`. Ảnh độ phân giải thấp, có email thật |
| 🟡 | **S4-10** PDF | Font tiếng Việt Regular/Bold và `LocalReportStore` đã có, kiểm bằng **fixture**. **Thiếu:** plan đang xem (S4-3), nối vào luồng export, mở/chia sẻ, chạy trên Android |
| 🧱 | **S4-11** Upload | Có `uploadReportPdf`; thiếu lỗi typed, cancel, retry ID. Chờ S4-10, S3-7, DEC-01 |
| 🟡 | **S4-12** FCM | Đủ 4 callback/parser/dedup/inbox theo user bằng gateway giả. **PM-FCM-01 Closed — verified** (`2d547c7`, PM `c5059d8`), raw/typed payload và target duplicate thống nhất. **Thiếu:** route/history/token/recipient policy chốt, Profile và push thật |
| ⬜ | **S4-13** Profile + Demo | Chưa có màn Profile. Export và inbox vẫn ở `home_screen.dart`; cần thống nhất với Hoàng |
| 🟡 | **S4-14** Semantics | Mới có Sign-in. Profile, export, notification chưa có. Chưa bật TalkBack thật |
| ⬜ | **S4-15** Bằng chứng Storage/FCM | Chờ S4-11, S4-12 |
| 🟡 | **S5-4** Events | Login, logout, export đã theo API mới của Thái An (`9ecc806`). **Thiếu:** kiểm DebugView; export chờ S4-11 chạy thật |
| ⬜ | **S6-4** test_auth.py | `e2e_test/` mới có `conftest.py` với Dummy client. Chờ S6-2 của Thái An |
| ⬜ | **S6-7** test_export/profile | Chờ S6-2, S4-11, S4-12 |
| ⬜ | **S6-14** Sửa lỗi theo ARTEMIS | Chờ S6-9 |
| 🟡 | **S7-1-CM** PR + AI review | Nhánh và title/body PR đã chuẩn bị; người dùng sẽ mở PR vào main. **Chưa có PR/AI output khi cập nhật**; không đánh Done chỉ vì push hoặc PM review local |
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
| 1 | Main `614e731` chưa nhận các caller fixes Analytics trên nhánh Charlie; bản tích hợp đã qua checks | Leader review/merge fixes; **`generate_meal_plan` vẫn chưa gửi từ Home** vì chưa có `eatingWindowHours` thật | Thái An, Hoàng |
| 2 | **Đã xử lý:** gói docs (`e829c3c`) đã merge, PM đã chấp nhận cách gộp `docs/code-review.md` | Không còn chặn merge | — |
| 3 | **DEC-01 chưa chốt:** Storage cần Blaze, Final lại loại Storage | Chặn S3-7, S4-11, một phần S4-13, S4-15 | Thái An (Leader) |
| 4 | **Chưa mời đủ thành viên, thiếu 3 SHA** | Chưa xác minh Google Sign-in trên ba máy còn lại; quyền Firebase Console và SHA/Auth là hai đầu việc riêng | Charlie, cả nhóm |
| 5 | **Món ăn hard-code** khi Firestore chưa có `recipes` (A9) | Trái quy định bản nộp; có 1 plan test chứa món giả trên project | Hoàng |
| 6 | **Nhánh đã push nhưng chưa vào `main`** | Muốn dùng widgets, config Firebase và rules, các bạn phải lấy từ `feature/charlie-auth-01` | Charlie, Thái An |

`origin/main` ghi Thái An là Team Leader và đã có code S5-x, nên nhóm không còn ở mốc ban đầu như guide ghi nhận (`ae35f07`).

## Việc tiếp theo đề xuất

1. **PR vào main:** người dùng tạo PR từ `feature/charlie-auth-01`, dùng bản mô tả đã chuẩn bị. Ba finding PM đã đóng; Thắng review A1/A2, Hoàng review A3/A5, Hoàng/Thái An review generate Analytics, Hoàng/Thắng review AUD-11 B1–B5 trước quyết định merge.
2. **Mở khóa cho nhóm:** mời 3 bạn, nhận SHA, tải lại `google-services.json`; nhờ Leader chốt DEC-01.
3. **FCM:** khi có câu trả lời cho [3 câu hỏi contract](FCM-CONTRACT-PROPOSAL.md), nối router, history, rồi thử push thật ba trạng thái.
4. **PDF:** khi có S4-3, dùng plan đang xem; nối `LocalReportStore` vào export; chạy trên Android.
5. **Sau đó:** S4-13 Profile (thống nhất diff `home_screen.dart` với Hoàng), rồi S3-7/S4-11 khi có DEC-01.
6. **Làm dần từ bây giờ:** `docs/worklog-charlie.md`, phần Auth của S8-3.

## Commit

| Commit | Nội dung |
|---|---|
| `6dfddf9` | UI-01: S2-3, S2-4 |
| `56b1896` | AUTH-01: S3-3, S3-4, S3-5 |
| `4e4bffd` | Firebase: S0-4, S3-1, S3-9, AUD-11 |
| `9d76623` | Sửa session: PM-S3-5-01, PM-S3-5-02 |
| `e829c3c` | Gói docs điều phối |
| `cd82637` | Merge `origin/main` |
| `9ecc806` | Đồng bộ Analytics: S5-4 |
| `7a9fa8c` | FCM: S4-12 |
| `40e47a1` | PDF: S4-10 |
| `2d547c7` | Sửa FCM: PM-FCM-01 |
| `f1f397e` | Dev báo cáo fix FCM và cập nhật progress |
| `c5059d8` | Codex xác nhận PM-FCM-01 Closed; push PM re-review và evidence |

Riêng `cd82637` không biên dịch được một mình; `9ecc806` sửa ngay sau đó. Bộ docs điều phối đã vào `e829c3c`, PM re-review/evidence đã vào `c5059d8`. Ảnh QA ở các thư mục `evidence/ui/PM-*` còn untracked được giữ trên máy, không cần đưa vào PR để chứng minh đóng finding. XML/logcat thô vẫn chỉ giữ local theo quyết định trước. Không có blocker docs Codex dirty cũ sau khi các commit này đã push.

Repo công khai và nhánh đã push nguyên trạng theo quyết định của Charlie, gồm `google-services.json` và ảnh có email, UID của Charlie. Nên giới hạn API key Android theo package và SHA trên Google Cloud.

Chi tiết: [CHARLIE-UI-01](CHARLIE-UI-01.md), [CHARLIE-AUTH-01](CHARLIE-AUTH-01.md).
