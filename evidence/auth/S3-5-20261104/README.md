# S3-5 — Đăng xuất và cách ly phiên, 04/11/2026

> **Delivery 04/11/2026:** [PR #11](https://github.com/ruxenb/LongvitaRC/pull/11) đang mở vào main, chưa merge/auto-merge. Code eee1547 đã qua PM review; tích hợp main b657ca9 tại 911a65d không xung đột, analyzer sạch/334 tests pass. 01–06 Closed trong phạm vi kiểm. S3-5 vẫn chờ Hoàng A3, PDF/history policy và Thắng chốt SDK sign-out failure; recipient-less FCM chờ An/Thắng. Giữ PR mở cho CodeRabbit/owner review. Native evidence thuộc các đợt trước; chưa chạy native trên bản tích hợp. Các mục dưới giữ như lịch sử.

- **Code:** `main` `96c9f57` (sau khi merge PR #9). Đợt này không đổi code: không tái hiện được lỗi nào.
- **Thiết bị:** AVD `LocalMate_API_35`, Android 15.
- **Bản build:** debug, app thật (entrypoint `lib/main.dart`), build với `--dart-define=STORAGE_EMULATOR_HOST=10.0.2.2`. Xuất PDF tải lên Firebase Storage Emulator trên máy, không lên Storage thật. Không dùng QA host Sign-in của S4-14.
- **Tài khoản:** hai tài khoản Google thật trên cùng emulator. Charlie tự đăng nhập; không có mật khẩu hay token nào trong evidence.
  - **A:** `minhpvse183365@fpt.edu.vn`, UID `vFIifNJKUcfOvrOVqoZL3m85diu2`.
  - **B:** tài khoản Gmail cá nhân của Charlie, UID `k6sBvDYQ7oXW2hy4ddJdhGz0Qh93`. Email B đã được làm mờ trong ảnh 08, 09, 12. Quyết định giữ email trong evidence ngày 02/11 chỉ nói về tài khoản trường.
- **Cách kiểm file:** liệt kê `app_flutter/reports/` và `app_flutter/notifications/` bằng `adb shell run-as vn.edu.fpt.longvita ls` (được vì là bản debug). Chỉ xem tên và kích thước file; không xóa tay, không reset dữ liệu app.

## Marker

| Phiên | Marker |
|---|---|
| A | Thực đơn mẫu; export `plan_1793726751351` cùng URL Storage Emulator trên màn; 7 PDF cũ trên máy (tổng 8); hộp thư có tin "ARTEMIS TC10 review", "ARTEMIS TC10 lan 2"…; lịch sử `notifications/vFIif….json` 2601 byte |
| B | Hộp thư trống; lịch sử `notifications/k6sB….json` là `[]`; export `plan_1793727154298` |

## Kết quả

| # | Ca | Ảnh | Thực tế | Kỳ vọng |
|:-:|---|---|---|---|
| 1 | A: Profile → Đăng xuất → **Hủy** | 03, 04 | Vẫn A, export và URL vẫn hiện, 8 PDF vẫn trên máy | Đạt |
| 2 | A: Profile → Đăng xuất → **Đồng ý** | 05 | Về Sign-in. `reports/vFIif…/` hết 8 PDF. `notifications/vFIif….json` còn nguyên. Bản cloud `reports/vFIif…/plan_1793726751351.pdf` trên Storage Emulator vẫn tải được, bắt đầu bằng `%PDF-` | Đạt |
| 3 | **Back** sau khi đăng xuất | 06 | Về launcher (NexusLauncher), không vào Home hay Profile | Đạt |
| 4 | **Tắt hẳn (force-stop) rồi mở lại** sau khi đăng xuất | 07 | Vẫn ở Sign-in, không tự khôi phục phiên | Đạt |
| 5 | A → đăng xuất → **B** | 08, 09, 10 | B thấy "Chưa có thực đơn để xuất", không URL, không export, hộp thư "Chưa có thông báo nào.". Duyệt hết Profile của B không thấy marker nào của A (tên, email, UID, tin ARTEMIS, export) | Đạt |
| 6 | B đăng xuất **từ Home** | 11, 12, 13 | Nút Đăng xuất của Home đăng xuất ngay, không hỏi xác nhận (thiết kế hiện có, không đổi). Về Sign-in. `plan_1793727154298` của B bị xóa khỏi máy; lịch sử của cả A và B vẫn giữ | Đạt |
| 7 | B → đăng xuất → **A** (cùng UID A đăng nhập lại) | 14, 15, 16 | A thấy "Chưa có thực đơn để xuất", không URL hay export cũ, `reports/` trống. Hộp thư hiện lại tin của A từ lịch sử trên máy (file vẫn 2601 byte) | Đạt. Khôi phục lịch sử của chính A là đúng contract tạm, không phải state cũ chưa dọn |

## Dữ liệu khi kết thúc phiên

| Dữ liệu | Hành vi hiện tại | Đã kiểm | Trạng thái quyết định |
|---|---|---|---|
| Thực đơn, danh sách đã lưu, trạng thái tạo (MealPlan VM) | Xóa khỏi RAM; kết quả async muộn bị bỏ qua (`SessionEpoch`) | Native ca 5, 7; test `session_isolation`, `session_race` (PM-S3-5-02) | Code A3 của Hoàng, **chờ Hoàng duyệt** |
| Nguyên liệu và bộ nhớ Undo (Ingredient VM) | Xóa khỏi RAM (đồng bộ, không có việc async) | Test `session_isolation` (`canUndo` false) | Code A3 của Hoàng, **chờ Hoàng duyệt** |
| Export, URL, tiến trình, upload đang chạy (Profile VM) | Xóa khỏi RAM; yêu cầu hủy upload; kết quả, tiến trình, lỗi muộn bị bỏ qua | Native ca 2, 5, 7; test `session_race` (PM-S3-5-01), `profile_export` | Đã chốt |
| PDF trên máy `app_flutter/reports/<uid>/` | **Xóa** cả thư mục của UID vừa đăng xuất; thư mục UID khác và ngoài `reports/` không đụng | Native ca 2, 6; test `report_service` (`deleteAll` chỉ xóa UID đó, chặn path traversal) | Có trong code; **chính sách lưu giữ PDF còn chờ nhóm chốt** |
| Bản PDF trên Cloud Storage | **Giữ** | Native ca 2 (Storage Emulator) | Đã chốt: đăng xuất không xóa dữ liệu cloud |
| Hộp thư thông báo trong RAM, tin vừa đến, yêu cầu mở | Xóa khỏi RAM | Native ca 5; test FCM, PM-FCM-02 | Đã chốt |
| Lịch sử thông báo `app_flutter/notifications/<uid>.json` | **Giữ trên máy theo UID**; người sau chỉ tải file của mình | Native ca 2, 5, 6, 7 | Contract tạm của nhóm |
| Tin đến lúc chưa ai đăng nhập (không có `recipient_uid`) | Giữ lại rồi giao cho người đăng nhập kế tiếp; tin có `recipient_uid` khác bị loại | Test FCM | **Câu hỏi mở của An/Thắng**, S3-5 không quyết |
| Analytics user ID, Crashlytics user ID và `user_role` | Reset khi kết thúc phiên | Test `auth_viewmodel` (fake). Chưa xem trên DebugView/Crashlytics Console | Đã chốt |
| Phiên Firebase/Google | `signOut` của Google (lỗi thì bỏ qua) rồi của Firebase | Native ca 2–4 | Đã chốt |

Câu task gốc ghi "xóa toàn bộ dữ liệu người dùng cục bộ". Hiện tại lịch sử thông báo được giữ theo contract tạm, và chính sách PDF còn chờ chốt. Vì vậy S3-5 chưa đạt nguyên văn câu đó.

## Phân biệt các hành vi bất đồng bộ

- **Gọi hủy upload:** `clearSession` gọi `cancelActiveUpload()` nếu đang tải lên. Khi mạng chậm, SDK có thể chỉ dừng ở lần thử lại kế tiếp.
- **SDK xác nhận hủy:** không chờ. Nếu upload cũ vẫn hoàn tất, bản cloud nằm dưới `reports/<uid cũ>/`, vẫn là dữ liệu của chính người đó.
- **Vô hiệu hóa kết quả đã có test:** các kết quả export/upload và MealPlan trong `session_race_test` được bỏ qua nhờ `_activeOperation`/`SessionEpoch`, kể cả cùng UID. Không suy rộng thành mọi tác vụ: PM-S3-5-03/04 bên dưới chỉ ra hai ranh giới còn lỗi.
- **Đăng xuất giữa lúc lưu PDF:** file vừa lưu bị xóa và upload không bắt đầu. Test: `profile_export_test` (`logout during save…`).

Native chỉ kiểm đăng xuất sau khi upload đã xong. Các race trên dùng test có điều khiển (fake), không phải bằng chứng native.

## Kiểm bằng lệnh

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 279/279 pass. Riêng `test/auth`, `test/fcm` và `test/report/profile_export_test.dart`: 148/148 pass.
- Ở lượt Dev không có test mới vì chưa tìm thấy lỗi tái hiện được. Sau đó PM chạy ba probe riêng: hai regression fail và một observation pass; không cộng chúng vào suite 279 hoặc gọi là native runs. Cần bổ sung regression chính thức cho các fix.

## Giới hạn

- **SDK đăng xuất lỗi:** nếu `FirebaseAuth.signOut` ném lỗi, app vẫn dọn local và hiện Sign-in (test `sign-out SDK failure still clears local session`). Nhưng phiên Firebase có thể còn, nên lần mở app sau sẽ tự đăng nhập lại A. Trên máy không gây được lỗi này nên chưa kiểm native; đây là hành vi hiện có, ghi lại để PM biết.
- **Đăng xuất giữa lúc xuất/tải lên:** chưa thử native, chỉ có test.
- Analytics và Crashlytics user ID chưa xem trên Console.
- Chưa thử trên máy thật.
- **A3 của Hoàng chưa có duyệt:** các guard trong MealPlan/Ingredient VM do Charlie viết (PR #1). Không tìm thấy review hay comment của Hoàng trên GitHub. Merge hoặc CodeRabbit không được tính là Hoàng đã duyệt.
- **Quan sát ban đầu của Dev:** chưa gặp cleanup PDF chạy nền xóa file mới trên máy. Sau review, PM đã tái hiện bằng probe điều khiển dùng LocalReportStore/filesystem thật; chuyển thành PM-S3-5-04 bên dưới. Native vẫn chưa tái hiện ca race này.

## PM review trên code của 0e3ef5a

| Finding | Tái hiện có điều khiển | Expected |
|---|---|---|
| PM-S3-5-03 | Auth restore A đang load profile → stream null → A đăng nhập lại → response profile cũ hoàn tất. Chỉ có 1 load, profile của phiên cũ đi vào phiên mới. AuthViewModel deduplicate và kiểm kết quả chỉ theo UID | Phiên mới load profile mới; stale callback không thay state/identity/role hoặc handle của operation mới |
| PM-S3-5-04 | Giữ việc xóa folder reports/A của logout cũ → A đăng nhập lại và lưu export mới → thả cleanup cũ. File mới bị xóa dù VM vẫn giữ lastExport. Dùng LocalReportStore và filesystem thật trong sandbox, thời điểm directory lookup được giữ bằng fake | File cũ được dọn đúng policy; file đã tạo hợp lệ trong phiên mới vẫn còn để mở/chia sẻ/retry |

Hai regression PM fail đúng invariant trên code hiện tại; không phải finding 01/02 cũ và chưa tái hiện native. Probe thứ ba xác nhận conditional SDK-failure behavior bằng fake: UI signed-out không notice, SDK vẫn UID A, recreate VM thì A restore. Không được coi đây là đã gây lỗi Firebase trên Android thật. Chưa đổi production hoặc sửa expected tests cũ trong lượt PM.

Kết quả native ở phần trên vẫn có giá trị cho các trình tự đã thực hiện; chúng không phủ các lịch async cố ý giữ này. S3-5 giữ Đang thực hiện, gồm code fixes 03/04 và input A3/policy/SDK failure behavior, không chỉ còn chờ owner.

## Sau sửa PM-S3-5-03 và PM-S3-5-04

Các phần trên (ảnh 01–16, kết quả, các con số 279 và 148) là baseline của `0e3ef5a`, giữ nguyên. Phần này là kết quả trên code đã sửa.

Phần bản sửa do Dev bàn giao tương ứng code `9710d81`; xem kết luận PM mới nhất ở cuối tài liệu trước khi coi cả hai findings đã Closed.

### Sửa

| Finding | Thay đổi | Regression (fail trên code cũ / tổng) |
|---|---|---|
| PM-S3-5-03 | `AuthViewModel`: mỗi lần tải profile gắn với "thế hệ" của phiên. Thế hệ tăng khi Firebase báo không có user, khi đổi sang user khác, hoặc khi bắt đầu đăng xuất. Lần tải chỉ được dùng chung trong cùng UID và cùng thế hệ. Kết quả và lỗi của thế hệ cũ bị bỏ qua, không ghi Crashlytics. `whenComplete` chỉ xóa handle nếu đó đúng là lần tải của chính nó. `AuthService`: profile lưu tạm chỉ nhận kết quả của lần tải mới nhất; khi đăng xuất hoặc Firebase báo không có user thì các lần tải đang chạy bị vô hiệu | `test/auth/auth_viewmodel_test.dart`: 4/6 (2 ca đối chứng: A→B, và một lần tải chung trong cùng phiên). `test/auth/auth_service_profile_cache_test.dart`: 2/3 (1 ca đối chứng) |
| PM-S3-5-04 | `LocalReportStore`: mọi thao tác file của cùng UID (save, find, read, delete, deleteAll) chạy lần lượt theo thứ tự gọi. Việc dọn của phiên cũ được xếp hàng trước, nên PDF mới chỉ được ghi sau khi dọn xong. File cũ bị dọn, file mới còn. UID khác không phải chờ. Một thao tác lỗi không chặn thao tác sau | `test/report/report_service_test.dart`: 2/4. `test/report/session_cleanup_test.dart`: 1/2, dùng `LocalReportStore` và ổ đĩa thật trong thư mục tạm; kiểm cả mở và chia sẻ PDF mới |

**Thứ tự gate trong regression 04:** việc xuất PDF mới bắt đầu trong lúc việc dọn cũ còn bị giữ, sau đó thả việc dọn, rồi mới chờ xuất xong. Probe của PM chờ xuất xong rồi mới thả, nên sẽ treo với cách sửa này. Điều kiện kiểm giữ nguyên: file cũ bị dọn, file mới còn và mở/chia sẻ được.

Probe 03 của PM chạy trên code mới: `loads=2, final=PROFILE FROM NEW SESSION`, pass. Probe SDK vẫn pass, vì hành vi đó chưa đổi.

### Kiểm bằng lệnh

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: **294/294 pass**, gồm 279 test cũ và 15 test mới.
- `git diff --check`: sạch.

### Chạy lại native trên code đã sửa

Cùng thiết bị, build debug với Storage Emulator; tài khoản A do Charlie đăng nhập. Ảnh trong `after-fix/`.

| Ca | Ảnh | Kết quả |
|---|---|---|
| Mở app: khôi phục phiên A (đi qua đường tải profile đã sửa) | — | Vào Home của A |
| Xuất PDF → Hủy đăng xuất | r01, r02 | `plan_1793728893288.pdf` vẫn còn |
| Đồng ý đăng xuất | r03 | Về Sign-in, `reports/` trống |
| Back, rồi force-stop và mở lại | r04 | Về launcher, sau đó vẫn ở Sign-in |
| A đăng nhập lại (cùng UID) → Profile | r05, r06 | Không còn export cũ |
| Xuất PDF ngay → Mở PDF → Back | r07, r08 | Chỉ còn `plan_1793729017067.pdf`, mở được trong PrintActivity, Back về app, file vẫn còn |

Race của 03 và 04 vẫn chỉ kiểm bằng test có điều khiển. Trên máy, việc dọn xong trước khi đăng nhập Google hoàn tất, nên lịch race không tự xảy ra. Ca A→B không chạy lại native; phần auth sửa có test đối chứng A→B.

### Khi `FirebaseAuth.signOut` lỗi: hiện trạng và đề xuất (chưa làm)

**Hiện trạng** (PM xác nhận bằng fake; chưa gây được lỗi Firebase thật):
- App vẫn dọn dữ liệu phiên trên máy và hiện Sign-in, không có thông báo.
- Phiên Firebase của A có thể còn, và `authStateChanges` không phát gì, nên trong lúc app đang chạy A không tự quay lại.
- Lần khởi động sau, Firebase khôi phục A và app vào thẳng Home của A.
- Nếu người khác đăng nhập Google trên màn Sign-in, `signInWithCredential` thay A bằng người đó.

**Đề xuất cho PM và Thắng** (cần đồng ý trước khi làm, vì đổi contract hoặc thêm dữ liệu lưu):
1. **Báo lỗi và cho thử lại (nên làm trước):** vẫn dọn dữ liệu trên máy ngay để bảo vệ riêng tư. Hiện Sign-in kèm thông báo "Chưa đăng xuất được khỏi tài khoản trên máy này" và nút "Thử đăng xuất lại" gọi lại `authService.signOut()`. Cần thêm một loại lỗi (`AuthFailureKind`) và câu chữ trong `AuthMessages`. Đây là model và UI dùng chung với AuthGate của Thắng, nên cần Thắng đồng ý.
2. **Ghi lại ý định đăng xuất (nếu nhóm cần chắc chắn qua lần khởi động sau):** ghi một cờ trên máy trước khi gọi SDK, xóa khi đăng xuất thành công. Lúc khởi động, nếu cờ còn mà SDK vẫn có user thì gọi `signOut` lại trước khi vào Home. Cần thêm nơi lưu trữ và đổi luồng khởi động (StartupGate/AuthGate của Thắng).
3. **Không đổi gì:** chấp nhận rủi ro thấp và ghi giới hạn. Trên Android, `FirebaseAuth.signOut` chỉ xóa phiên trên máy, nên hiếm khi lỗi; nhưng chưa có bằng chứng nó không bao giờ lỗi.

Không dùng `setPersistence(NONE)`: tùy chọn này chỉ có trên web.

## PM re-review 9710d81

PM tự chạy analyzer sạch/294 tests pass; reproduction 03 cũ pass (hai profile loads, chỉ nhận profile mới). PM-S3-5-04 Closed: queue theo UID và regressions bảo vệ file cũ được dọn, file mới còn/mở/chia sẻ được; không chạy lại scheduling probe 04 cũ gây deadlock với cách serialize.

| Mục còn lại | Actual bằng probe điều khiển | Expected |
|---|---|---|
| 03, hai error branches | Lỗi profile A đã bắt đầu await Crashlytics khi A còn hợp lệ; stream null/B vào app; logging cũ xong set AuthProfileError(A), SDK vẫn B | Recheck/tách state transition để callback cũ không đổi state B |
| 05-A | Logout A đã signed-out, logLogout đang giữ; B vào app; thả logging thì lượt logout cũ clear B/set signed-out, SDK vẫn B | Lượt logout cũ không dọn phiên mới |
| 05-B | SDK stream đã đưa A vào app khi logLogin còn giữ; A logout; thả logging cũ thì VM khởi động lại AuthLoadingProfile(A) dù SDK UID=null và bị kẹt | Giữ đúng signed-out, không load profile từ operation đã hết phiên |

Bốn probe mới fail, là tests bổ sung độc lập với fake logger delays, không thuộc suite 294 và chưa native. Phần fixes profile generation/dedup/cache đã làm đúng cho các ca trước; còn thiếu bảo vệ async completion nói trên. Native after-fix r01–r08 được giữ, A→B sau fix vẫn chỉ có baseline trước sửa. SDK-error notice/retry và bảo vệ ý định logout qua restart còn cần quyết định owner; A3/retention chưa chốt. Chưa hoàn tất phần kỹ thuật hoặc toàn S3-5.

## Sau sửa phần còn lại của PM-S3-5-03 và PM-S3-5-05

Mọi phần ở trên giữ nguyên: baseline `0e3ef5a`, lượt sửa `9710d81`, và các mục PM. PM-S3-5-04 đã Closed và không đổi.

### Nguyên nhân và cách sửa (`lib/viewmodels/auth_viewmodel.dart`)

Trước đây state chỉ đổi sau khi chờ một lời gọi telemetry (Crashlytics `recordError`, Analytics `logLogin`/`logLogout`). Khi lời gọi đó xong muộn, phiên khác có thể đã bắt đầu.

- **03 remaining:** lỗi tải profile được hiện ngay (`AuthProfileError`) lúc phiên vẫn hiện hành, rồi mới `await recordError`. Sau await không còn đổi state.
- **05-A:** `signOut` lấy thế hệ phiên khi bắt đầu. Sau `authService.signOut()`, chỉ dọn local và đặt `AuthSignedOut` nếu chưa có phiên mới. Nếu SDK đã đăng xuất, stream đã tự dọn trước đó. Log chạy sau và không đổi state. Lỗi SDK vẫn ghi `Sign-out failed`. Lỗi riêng của sự kiện logout được ghi là `Logout event failed`, không còn bị coi là lỗi đăng xuất.
- **05-B:** `signInWithGoogle` bắt đầu tải profile ngay khi có kết quả, dùng chung lần tải với stream. `logLogin` chạy song song. Cờ chống bấm lặp được trả ngay khi màn chọn tài khoản đóng, nên log đang chờ không chặn lần đăng nhập sau.
- **Không đổi:** API, service telemetry, fake. Log vẫn được gửi; không tạo Future nào bị bỏ lơ mà không xử lý lỗi.
- **Ảnh hưởng nhỏ:** sự kiện logout giờ được gửi sau khi dọn phiên, nên có thể không còn gắn user ID. Ở code cũ, khi stream báo không có user trước thì cũng đã như vậy.

### Test

| Ca (`test/auth/auth_viewmodel_test.dart`, group "telemetry finishing late…") | Fail trên `9710d81` |
|---|---|
| Lỗi profile typed của A được ghi muộn; B, và cả cùng UID A, vẫn đăng nhập (2 test) | Có |
| Lỗi profile generic, cùng hai biến thể (2 test) | Có |
| Sự kiện logout của A xong muộn; B, và cả cùng UID A, vẫn đăng nhập, không bị `clear` (2 test) | Có |
| Sự kiện login xong sau khi đã đăng xuất: vẫn `AuthSignedOut`, không tải profile lại | Có |
| Sự kiện login đang chờ không chặn lần đăng nhập sau | Có |
| Lỗi sự kiện logout được ghi lại, đăng xuất vẫn hoàn tất | Không (đối chứng) |

4 probe completion của PM: trước là 0/4 pass, giờ 4/4. Probe 03 gốc và probe SDK vẫn pass.

### Kiểm bằng lệnh

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: **303/303 pass** (294 + 9).
- `git diff --check`: sạch.

### Native smoke trên bản này (`after-fix-2/`)

| Ca | Ảnh | Kết quả |
|---|---|---|
| Mở app khôi phục phiên A | s01 | Home của A |
| Xuất PDF → Hủy → Đồng ý | s02 | Hủy giữ A. Đồng ý thì `reports/` trống và về Sign-in |
| Force-stop rồi mở lại | s03 | Vẫn ở Sign-in |
| A đăng nhập lại (cùng UID) | s04, s05 | Không còn export hay thực đơn cũ |
| Xuất PDF → đăng xuất | s06 | `plan_1793730517967.pdf` còn khi đang trong phiên, bị dọn khi đăng xuất |
| A → B | s07, s08, s09 | B (email đã làm mờ) không thấy marker nào của A. Hộp thư "Chưa có thông báo nào.", lịch sử B `[]`, lịch sử A giữ nguyên 2601 byte |

Các race trong 03 và 05 chỉ kiểm bằng test có điều khiển, không tái hiện trên máy. Đề xuất xử lý khi SDK sign-out lỗi, A3 và chính sách giữ dữ liệu vẫn chờ phối hợp, chưa làm.

## PM re-review f5ece29

PM độc lập chạy analyzer sạch, 303/303 Flutter tests; 4/4 probes completion cũ pass, original profile probe và SDK-failure observation mỗi ca pass. **PM-S3-5-03/04/05 Closed** trong phạm vi kiểm. Đã xem ảnh s03/s05/s07–s09 (signed-out/restart, A vào lại, B không marker A và email B che); PM không tự thao tác emulator. Race tests không tính là native.

**Finding mới PM-S3-5-06:** SDK UID stream đưa A vào app trước khi Future kết quả credential trả; A logout thành công; thả result thành công của request cũ, không đăng nhập lại SDK. AuthViewModel chưa kiểm attempt sau await SDK nên gọi lại profile loading, VM kẹt AuthLoadingProfile dù SDK UID=null. Một probe độc lập fail expected signed-out, chưa tái hiện native và không thuộc suite 303. Đây là SDK-result boundary, tách khỏi các ca telemetry 05 đã sửa. Cần bảo vệ lifecycle attempt và giữ dedup của các result/stream hợp lệ cùng phiên.

S3-5 còn Changes requested cho 06 và Waiting input A3/retention/SDK-error decision. PM không tự sửa production hoặc thay policy. Các tests/evidence f5ece29 và baseline cũ giữ nguyên.

## Sau sửa PM-S3-5-06

Mọi phần ở trên giữ nguyên, gồm baseline và các lượt `9710d81`, `f5ece29`. PM-S3-5-03, 04 và 05 đã Closed, không làm lại.

### Nguyên nhân và cách sửa (`lib/viewmodels/auth_viewmodel.dart`)

**Nguyên nhân:** sau `await authService.signInWithGoogle()`, kết quả được áp dụng mà không kiểm lần đăng nhập đó còn hợp lệ không. Nếu stream đã đưa A vào app, A đăng xuất, rồi kết quả cũ mới trả về, thì `_loadProfile(A)` chạy lại khi SDK không còn user, và VM kẹt ở `AuthLoadingProfile`.

**Cách sửa:**
- Mỗi lần đăng nhập là một attempt có định danh (`_signInAttempt`) được gắn **trước** khi chờ SDK, thay cho cờ `_signInInFlight`.
- Attempt bị bỏ khi bắt đầu `signOut()`, hoặc khi stream báo không có user mà state không còn ở `AuthSigningIn` (tức user đã vào app). Khi còn ở màn chọn tài khoản thì attempt vẫn tự báo kết quả như trước.
- Sau await, kết quả chỉ được áp dụng nếu attempt vẫn là attempt hiện tại. Kết quả của attempt bị bỏ không đổi state, không gửi `logLogin`, và không gỡ attempt mới.
- **Luồng hợp lệ:**
  - Stream đã đăng nhập đúng UID đó: kết quả không tải profile lại.
  - Stream đang tải: kết quả dùng chung lần tải đó.
  - Kết quả đến trước stream: như trước.
- Kết quả báo thành công nhưng `currentUid` không còn là UID đó: không mở màn tải; nếu đang `AuthSigningIn` thì về `AuthSignedOut`.
- **Lỗi có sẵn được sửa cùng lúc:** khi stream đăng nhập trước kết quả trong cùng phiên, code cũ tải profile hai lần và gọi `onSessionStarted` hai lần.
- **Không đổi:** `IAuthService`, AuthGate, chính sách giữ dữ liệu.

### Test

| Ca (`test/auth/auth_viewmodel_test.dart`, group "a sign-in result belongs to its attempt") | Fail trên `f5ece29` |
|---|---|
| Kết quả đến sau khi đăng xuất: vẫn `AuthSignedOut`, không tải thêm, không gửi `logLogin` | Có |
| Kết quả cũ không ảnh hưởng attempt mới, với B và với cùng UID A (2 test). Gồm: attempt mới không bị chặn, bấm lặp vẫn bị bỏ qua, attempt mới đăng nhập đúng | Có |
| Kết quả đến sau khi stream đã đăng nhập (cùng phiên): một lần tải, một lần `start`, vẫn gửi `logLogin` | Có (lỗi có sẵn: tải hai lần) |
| Kết quả đến khi stream còn đang tải: dùng chung lần tải | Không (đối chứng) |

**Probe của PM:**
- `pm_auth_sdk_completion_probe_test.dart`: trước 0/1 pass, giờ 1/1 (`SDK=null, state=AuthSignedOut`).
- 4 probe completion, probe 03 gốc và probe SDK vẫn pass.
- Probe 04 cũ vẫn treo với cơ chế xếp hàng; điều này đã biết khi đóng 04.

### Kiểm bằng lệnh

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: **308/308 pass** (303 + 5).
- `git diff --check`: sạch.

### Native smoke trên bản này (`after-fix-3/`)

Emulator khởi động lại; cài bản build từ code này. Storage Emulator không chạy trong lượt này, nên không kiểm xuất PDF; bản sửa không đụng phần đó.

| Ca | Ảnh | Kết quả |
|---|---|---|
| Mở app khôi phục phiên A | t01 | Home của A |
| Profile → Đăng xuất → Đồng ý | t02 | Sign-in |
| Force-stop rồi mở lại | t03 | Vẫn Sign-in |
| Charlie đăng nhập A bằng Google (đường kết quả đăng nhập và stream thật) | t04, t05 | Vào Home của A, không kẹt màn tải. Profile không còn export cũ |
| Đăng xuất lại | t06 | Sign-in |

Race của 06 chỉ kiểm bằng test có điều khiển; không gây được trên Android. Đề xuất xử lý khi SDK sign-out lỗi, A3, chính sách giữ dữ liệu và tin không có `recipient_uid` vẫn chờ phối hợp.

## PM re-review eee1547 — đóng PM-S3-5-06

PM độc lập kiểm code eee1547: analyzer sạch (80.2s), 308/308 tests pass (24s), probe SDK result 06 và bốn completion probes cũ 5/5 pass; probe profile gốc và SDK-error observation mỗi ca 1/1 pass. Expected các probe giữ nguyên. 06 Closed; 01–05 vẫn Closed. Không chạy probe 04 baseline vì nó deadlock với serialization đã được chấp nhận; regression file chính thức pass trong suite. Race chỉ kiểm bằng fake có điều khiển. Đã đọc diff/5 regression và xem ảnh t03/t05 của native smoke Dev; PM không tự thao tác emulator hay kiểm lại PDF. Giữ các baseline và giới hạn môi trường. Phần sửa kỹ thuật qua PM review; toàn S3-5 vẫn Waiting input A3, retention PDF/history và SDK-error behavior. Recipient-less FCM policy vẫn mở theo owner. Chưa push/PR/merge hoặc chuyển S3-2; tổng 10 chờ nghiệm thu/19 đang thực hiện không đổi.

Bản sửa gắn identity trước await SDK, hủy attempt khi sign-out/session null, bỏ result cũ trước state/telemetry; attempt cũ không giải phóng attempt mới. Stream đã signed-in cùng UID không tải profile/start session lần hai; đang tải thì dùng chung Future. API/AuthGate/policy không đổi. PM không chạy mutation tests của Dev; kết quả 4/5 fail trên f5ece29 là do Dev báo cáo. SDK-failure observation pass chỉ xác nhận giới hạn còn tồn tại: UI signed-out nhưng SDK giữ user có thể restore khi tạo VM lại; không phải tiêu chí SDK failure đã đạt.

## Delivery PR #11 và kiểm bản tích hợp

Charlie yêu cầu đưa gói đã qua PM review lên GitHub để review; mở PR không đồng nghĩa Done hoặc cho phép merge. Đã tích hợp origin/main b657ca9 (PR #10 và cập nhật routing của Thắng) bằng merge 911a65d, không xung đột. PM chạy analyzer sạch (39.5s), full Flutter suite **334/334 pass** (17s) trên bản tích hợp; git diff --check sạch. Đây là kết quả local, không phải CI. Không chạy lại native, APK hay rules trong lượt tích hợp; evidence native là các đợt đã ghi trong README. Rules trong PR giống main. Không tự xem Hoàng đã merge code là duyệt A3.

Đã push feature/charlie-session-02 và mở [PR #11](https://github.com/ruxenb/LongvitaRC/pull/11) vào main, PR thường để CodeRabbit auto-review theo cấu hình, giữ mở cho bot/owner review. Không bật auto-merge, không merge main. Các câu hỏi SDK sign-out failure, A3, PDF/history retention và recipient-less FCM ghi rõ trong mô tả PR. S3-5 vẫn Đang thực hiện / Waiting input; tổng Charlie 10 chờ nghiệm thu/19 đang thực hiện. Chỉ đưa file kỹ thuật/evidence được theo dõi lên Git; các tài liệu điều phối private, 8 thư mục QA PM và 6 file report-drafts xóa local ở workspace chính không bị đưa vào thay đổi.
