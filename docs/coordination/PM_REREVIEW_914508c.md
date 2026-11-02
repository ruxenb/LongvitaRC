# PM re-review — session fixes và bản tích hợp 914508c

> **Cập nhật đóng lỗi 02/11/2026:** fix `2d547c7`, xác nhận tại HEAD local/remote `f1f397e127c575e6fef6048a95916fab15152077`: **PM-FCM-01 Closed — verified**. Bản tái hiện PM giữ nguyên pass, suite 133/133 pass, analyzer sạch. Xem mục 7 cho checks/giới hạn hiện hành. Các mô tả fail và Changes requested ở mục 1–6 giữ làm lịch sử tại `914508c`, không phải trạng thái mới.

Ngày **02/11/2026**, Codex review theo [bàn giao của Claude](dev-reports/CHARLIE-PM-FIX-20261102.md). Local và ref GitHub `feature/charlie-auth-01` cùng HEAD **`914508cc03a827b88d82f62a4076a9da2020de7a`**. Main remote vẫn `614e7319c84b5374e0373a2b82b669aeabac0b11`; đã kiểm tra commit này là ancestor của nhánh Charlie. Chưa có nghĩa nhánh Charlie đã được merge ngược vào main.

## 1. Quyết định review

| Phần bàn giao | Kết luận PM |
|---|---|
| PM-S3-5-01, PM-S3-5-02 | **Closed — verified bằng hai ca tái hiện độc lập ban đầu**. Session epoch chặn completion cũ ở Profile/MealPlan; suite có thêm ca A→B và A→A, progress/error/generate/save/submit |
| Toàn task S3-5 | Phần sửa race đã được PM chấp nhận; A3/owner review của Hoàng và kiểm chứng A/B native vẫn là dependency ghi trong báo cáo. Không tự đổi cả task thành Done hoặc nghiệm thu toàn Assignment |
| Docs riêng và tích hợp Analytics | Chấp nhận phần gộp nội dung đã kiểm: commits tách riêng, nhận main, không mất policy Figma/Lab 3=Assignment và không biến review samples thành findings thật. Bản tích hợp qua analyzer và 121 tests |
| S5-4 | Callers tương thích API mới, export dùng bytes thực; generate chưa có eatingWindowHours thì không gửi event. Chưa coi là đạt DebugView/event coverage đầy đủ; Hoàng/Thái An còn cần chốt dữ liệu generate |
| S4-12 FCM | **Implemented một phần; Changes requested cho PM-FCM-01** ở mục 3. Chưa nghiệm thu routing/history/token/live delivery |
| S4-10 PDF | Đã kiểm fixture PDF 2 trang, glyph tiếng Việt/bold và layout đọc được. Local store/test có sẵn nhưng chưa nối export đang xem/open/share/Android, nên task vẫn partial |

## 2. Checks trên bản tích hợp PM đã chạy

Evidence riêng: `evidence/review/PM-REREVIEW-914508c/`. Không ghi đè logs/ảnh Dev hoặc ảnh PM trước.

| Lệnh/check | Kết quả | Evidence / giới hạn |
|---|---|---|
| `flutter analyze --no-pub` | **Pass, No issues found**, 57.5 giây | [Analyzer log](../../evidence/review/PM-REREVIEW-914508c/flutter-analyze.txt) |
| `flutter test --no-pub --reporter expanded test` | **121/121 pass** | [Test log](../../evidence/review/PM-REREVIEW-914508c/flutter-test.txt); gồm session/FCM/PDF/QA; fakes không chứng minh live cloud |
| Hai ca reproduction PM cũ, không đổi expected | **2/2 pass** | [Independent probes](../../evidence/review/PM-REREVIEW-914508c/independent-probes.txt), source gốc tại `evidence/review/PM-CHARLIE-20261102/session-race-repro.dart.txt` |
| PM-FCM-01 bổ sung | **Fail**, expected recipient B nhưng raw getter trả A | Cùng log independent probes; tách khỏi suite 121 tests, không gọi kết quả toàn lượt là all-pass |
| `flutter build apk --debug` | **Pass**, assembleDebug 47.1 giây | [Build log](../../evidence/review/PM-REREVIEW-914508c/build-apk-debug.txt); đã kiểm APK chứa Roboto regular/bold/license. Chưa chạy PDF/rootBundle hoặc push thật trên Android trong lượt này |
| Firestore rules | Reuse kết quả **41/41 pass** PM đã chạy ở `d17383c` | Đã so diff: rules, JS tests, package/lock không đổi qua HEAD mới. Không chạy lại vô ích, không tuyên bố vừa deploy hoặc test project thật |
| Fixture PDF | `pdfinfo`: 2 trang A4; render lại bằng Poppler và xem cả hai trang | [Trang 1](../../evidence/review/PM-REREVIEW-914508c/pdf-page-1.png), [trang 2](../../evidence/review/PM-REREVIEW-914508c/pdf-page-2.png). Không sửa PDF; chỉ kiểm file fixture đã bàn giao |

File runner diagnostic tạm trong `test/` đã được xóa sau khi chạy. Chỉ giữ source reproduction đuôi `.txt` và raw log ở evidence; source production/tests/config không bị Codex sửa. Bộ ảnh `evidence/ui/PM-REVIEW-20261102/` trước vẫn giữ nguyên trên máy, không bắt commit để đóng findings session; logs/proof đã đủ cho quyết định đó. QA hiện tại ghi vào `evidence/ui/PM-REREVIEW-914508c/regression-914508c/`.

## 3. PM-FCM-01 / P2 — Cache raw nhận tin bị recipient filter từ chối

**Vị trí:** `lib/firebase/notification_service.dart:138–139`, liên quan getter `messages` tại `:81–83` và `ProfileViewModel.notifications`.

**Nguyên nhân:** `_receive()` ghi `_raw[messageId] = message` trước khi `NotificationInbox.receive()` kiểm tra recipient/dedup. Getter raw dùng IDs từ inbox nhưng lấy nội dung mới nhất trong `_raw`, nên hai cấu trúc không còn cùng quyết định chấp nhận.

**Tái hiện bằng fake gateway, không dùng project thật:**

1. Bind user B; nhận message có application `message_id='shared-id'`, `recipient_uid='uid-b'`, nội dung B. Tin được chấp nhận.
2. Nhận callback muộn của tin có cùng application message ID, `recipient_uid='uid-a'`, nội dung riêng A. FCM message IDs trong ca test khác nhau; collision nằm ở `data.message_id` mà parser ưu tiên.
3. Inbox typed vẫn giữ tin B và từ chối tin A, nhưng getter `messages.single.data['recipient_uid']` trả **`uid-a`**, title cũng bị thay bằng nội dung A.

**Expected:** message không thuộc user hiện hành không được mutate bất kỳ cache/compatibility getter nào; duplicate không làm nội dung raw lệch khỏi entry typed đã chấp nhận. Không dựa hoàn toàn vào giả định sender luôn tạo IDs duy nhất để bỏ qua recipient isolation.

**Giới hạn:** phát hiện ở API service/VM và fake callback. Profile UI chưa được triển khai, chưa có proof thông báo A đã hiện trên thiết bị B hoặc bypass Firebase/rules thực; không diễn giải như sự cố cloud đã xảy ra.

**Reproduction:** [source](../../evidence/review/PM-REREVIEW-914508c/fcm-recipient-repro.dart.txt), [kết quả](../../evidence/review/PM-REREVIEW-914508c/independent-probes.txt). Có thể đặt source tạm ở `test/pm_rereview_fcm_guard_test.dart` để chạy; không ghi đè nếu đường dẫn đã có việc khác.

**Yêu cầu cho Claude:** lọc/chấp nhận message và cập nhật raw/typed state theo cùng quyết định; bao gồm cả tin nhận trước login đang held, bind/reset user và dedup. Không chỉ dời assignment sau `receive()==true` nếu cách đó làm mất raw payload của tin held trước login hoặc làm hỏng foreground→tap cùng một message. Dev chọn API acceptance result/cache model phù hợp, giữ callbacks/routing contract đang đề xuất.

**Điều kiện đóng:** ca trên pass; thêm kiểm tra duplicate cùng ID khác nội dung, recipient mismatch trước/sau bind, clear/logout rồi B login; xác nhận `inbox` và `messages` cùng recipient/nội dung theo policy. Giữ các test existing và cold-start/held-message behavior đã có. Không sửa expected để chấp nhận payload A trong phiên B.

## 4. Review docs và trạng thái tích hợp

Đã xem cách merge `docs/code-review.md`: giữ khung CR pending và mẫu EX từ upstream; giữ cảnh báo số findings PR đã xác minh là 0, full ARTEMIS SHA chưa pin, tool table là template. Disclosure Codex/Claude đúng phạm vi đã sử dụng. **Không lấy hai PM findings session hoặc finding FCM này tự điền vào Stage 7 PR review đã hoàn tất** khi chưa có quy trình/evidence PR tương ứng.

Blocker năm Markdown dirty giao upstream ở lượt trước đã được xử lý bằng commit docs `e829c3c` rồi merge `cd82637`; code callers sửa tại `9ecc806`. Lúc bắt đầu re-review chỉ còn ảnh PM untracked, không còn các docs Codex chưa commit như trước. Một dòng cuối progress Dev vẫn nói docs chưa commit là note cũ, cần sửa mô tả để không tạo blocker giả.

Generate event bị bỏ qua khi chưa có `eatingWindowHours` là giới hạn rõ ràng, tốt hơn bịa params để compile; vẫn phải nối dữ liệu preferences thực và DebugView ở bước owner thực hiện. Build/test pass hiện tại không chứng minh Analytics coverage, FCM delivery hoặc Crashlytics Gradle/demo đã đủ.

## 5. PDF và dependency tiếp theo

Fixture có Roboto regular/bold, hiển thị dấu tiếng Việt và xuống trang đọc được trong hai trang đã render. Nội dung/giá trị dinh dưỡng là fixture, không là dữ liệu catalog hay kiểm chứng công thức. Trang 2 có khoảng trắng lớn do giữ ngày Chủ Nhật thành một khối; hiện không cắt nội dung, có thể cải thiện pagination sau. Không buộc sửa Figma để quyết định font PDF hay layout.

Theo report Dev, text extraction có chỗ dính chữ, chưa rootBundle/runtime Android; local store chưa được Profile gọi và chưa có stable export ID/open/share. **Chưa chốt S4-10 Done**. Hoàng cung cấp active plan/revision S4-3; Charlie nối PDF/local vào luồng thực, test failure/retry/open/share theo policy. Font Roboto khác UI là deviation cần Charlie/Hoàng chốt trong code/review.

FCM còn ba quyết định ở [contract proposal](dev-reports/FCM-CONTRACT-PROPOSAL.md): route intent/ready hook (Thắng), history local theo UID hay Firestore/schema/rules (Hoàng/Thắng), token theo user hay topic và recipient policy (Thái An/Thắng). Sửa PM-FCM-01 độc lập được ngay trong khi chờ; không gọi RAM inbox là history bền hoặc handler registration là evidence push ba trạng thái.

## 6. Giao Claude tiếp tục

1. **Sửa PM-FCM-01**, giao commit/test/evidence và báo cáo riêng; không làm lại hai lỗi session đã đóng.
2. Cập nhật progress note đã cũ về docs/merge và ghi rõ S3-5 local findings closed nhưng A3 vẫn chờ owner. Không đổi tất cả task thành Accepted.
3. Chuẩn bị/nối PDF active plan/local/open/share khi S4-3 đủ; S4-13 Profile vẫn phối hợp Hoàng chuyển demo UI khỏi Home. FCM routing/history/live evidence chờ contract được chốt, phần độc lập vẫn tiếp tục được.
4. A1/A2/A3, AUD-11 B1–B5, DEC-01, lời mời Firebase/SHA của nhóm, PR/ARTEMIS/report/worklog vẫn theo dependency register; không tự duyệt hộ teammates hoặc mở billing.

Không có production change, commit/push/merge, deploy hay sửa Figma do Codex thực hiện trong lượt này. Trạng thái review chỉ áp dụng phạm vi/checks đã nêu tại HEAD trên.

## 7. Xác nhận bản sửa PM-FCM-01 — 2d547c7 / HEAD f1f397e

**Quyết định của Codex: Closed — verified, ngày 02/11/2026.** Đóng riêng finding PM-FCM-01, không tự đánh toàn S4-12, router/history hoặc Assignment là Done. PM-S3-5-01/02 giữ trạng thái Closed, không sửa lại source session trong lượt này.

Đã đối chiếu fix: bỏ `_raw`, `AppNotification.source` đi cùng entry được inbox giữ lại; raw getter đọc cùng entry; recipient mismatch không mutate cache khác. Khi tap duplicate, target lấy từ entry đã chấp nhận. Chính sách **first accepted wins trong một phiên** nhất quán với điều kiện đóng và tests; đây là implementation hiện hành trong contract proposal, không chốt hộ toàn bộ payload/topic/recipient policy cho team.

PM đã chạy độc lập trên HEAD `f1f397e`, source production giống fix `2d547c7` (commit sau chỉ cập nhật báo cáo):

| Check | Kết quả PM | Evidence |
|---|---|---|
| `flutter analyze --no-pub` | **Pass, No issues found**, 52.6 giây | [Analyzer](../../evidence/review/PM-FCM-01-VERIFY/analyze.txt) |
| `flutter test --no-pub --reporter expanded test` | **133/133 pass** | [Suite](../../evidence/review/PM-FCM-01-VERIFY/flutter-test.txt) |
| Bản tái hiện PM gốc | **1/1 pass**, giữ nguyên source/expected; runner tạm đã xóa | [Kết quả](../../evidence/review/PM-FCM-01-VERIFY/original-pm-repro.txt), [source gốc](../../evidence/review/PM-REREVIEW-914508c/fcm-recipient-repro.dart.txt) |
| `flutter build apk --debug` | **Pass**, assembleDebug 24.3 giây | [Build log](../../evidence/review/PM-FCM-01-VERIFY/build-apk-debug.txt); vẫn có cảnh báo Built-in Kotlin của plugins, không đổi versions trong lượt này |
| Rules | **Không chạy lại**; `git diff 914508c HEAD -- firebase` rỗng | Kết quả 41/41 thuộc lần PM trước, không ghi thành lần chạy mới |

Đã đọc 12 tests thêm ở `test/fcm/notification_service_test.dart`: recipient mismatch trước/sau bind, tin trùng khác nội dung/target, foreground→tap, held cold-start payload, clear/logout, direct bind và cùng ID ở phiên B. Không có finding mới trong phạm vi bản sửa sau các checks này.

**Giới hạn còn nguyên:** gateway giả, chưa push thật/chưa chạy lại trên thiết bị ở lượt xác nhận này; RAM history chưa bền, chưa router/Profile/token binding. Tin không có `recipient_uid` chờ người login kế vẫn là câu hỏi mở của Thái An/Thắng, không được xem là private message A→B đã an toàn cho mọi sender policy. `source: Object?` cần adapter/serialization khi history được chốt. Quyết định owner A3 và các dependency khác vẫn theo register.

**Bước tiếp theo:** chốt ba câu hỏi FCM contract với owners và tiếp tục PDF active plan/local/open/share theo S4-3/S4-10, rồi Profile S4-13. Không làm lại finding session/FCM đã đóng. Tài liệu PM và evidence được chuẩn bị thành gói docs riêng để team đọc được; chỉ lấy logs/reproduction và hai ảnh PDF fixture đã được review, giữ các thư mục QA screenshots untracked sẵn có nguyên trạng.
