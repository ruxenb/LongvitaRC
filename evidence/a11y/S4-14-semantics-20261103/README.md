# S4-14 — Semantics và TalkBack trên Sign-in, Profile, hộp thư và PDF, 03/11/2026

Đợt hai của S4-14, tiếp theo [`../S4-14-talkback-20261103/`](../S4-14-talkback-20261103/). Đợt đó đi TalkBack hết Sign-in và nửa đầu Profile; Remote Config và Crashlytics mới chỉ kiểm nhãn bằng `uiautomator dump`.

- **Code:** `14ec763`, nhánh `feature/charlie-a11y-02`, tách từ `main` `b2101a3` (sau khi merge PR #8). PM đã đọc diff/evidence và chạy lại analyzer sạch, 277/277 tests pass; PM chưa tự thực hiện cử chỉ TalkBack trong lượt review.
- **Bổ sung sau PM review:** commit tiếp theo trên cùng nhánh, gồm ba mục PM-S4-14-01..03 và lỗi 8 tìm thấy khi làm mục 02. Xem mục [Bổ sung sau PM review](#bổ-sung-sau-pm-review-03112026).
- **Thiết bị:** AVD `LocalMate_API_35`, Android 15, màn gốc 320×640 px ở mật độ 160 (320×640 dp), TalkBack 15.0 có sẵn trong image.
- **Bản build:** debug với `--dart-define=STORAGE_EMULATOR_HOST=10.0.2.2`. Xuất PDF tải lên Storage Emulator ở máy, không lên Storage thật.
- **Tài khoản:** của Charlie, đã đăng nhập sẵn. Ảnh có email và UID của Charlie, theo quyết định ngày 02/11.

## Cách kiểm

- **TalkBack thật:** cử chỉ gửi qua console của emulator (cổng 5554, lệnh `event mouse`), nên TalkBack nhận như ngón tay. Vuốt phải để sang phần tử kế tiếp, chạm một lần để khám phá, chạm đúp để kích hoạt.
- **Câu TalkBack đọc:** bật *Developer settings → Display speech output* của TalkBack, nên câu được đọc hiện ở cuối màn và nằm trong ảnh. Khung xanh là tiêu điểm thật của TalkBack. Tùy chọn này đã tắt lại sau khi chụp.
- **Không có âm thanh:** TTS đang dùng giọng en-US. Không nghe kiểm cách phát âm tiếng Việt; chỉ kiểm câu chữ TalkBack gửi đi.
- **Widget test:** dùng service giả (`uid-a`) cho các trạng thái khó tạo trên máy: đang tải lên 40%, lỗi tải lên rồi thử lại, hộp thư trống. Đây không phải bằng chứng Storage hoặc FCM thật.

## Lỗi tìm thấy và cách sửa

Cây Semantics trước và sau khi sửa, lấy từ widget test: [`semantics-tree-before.txt`](semantics-tree-before.txt), [`semantics-tree-after.txt`](semantics-tree-after.txt). Bản "after" được chụp trước lần sửa 5, nên trong đó tiến trình vẫn còn "...".

| # | Lỗi (trước) | Sửa | Kiểm |
|:-:|---|---|---|
| 1 | Bốn thẻ Báo cáo PDF, Thông báo, Remote Config, Crashlytics: mô tả nhập vào tiêu đề, cả thẻ thành một "heading" đọc trước các nút | `_CardHeader`: tiêu đề và mô tả mỗi cái một node | test `each card title is a heading of its own`; ảnh 01–03 |
| 2 | Sau khi tải lên xong, ô URL (SelectableText) nhập vào thẻ: cả thẻ thành ô nhập liệu kiêm tiêu đề, URL được đọc trước nút và trước thông báo thành công | URL thành node riêng, đứng sau "Đã tải PDF lên Cloud Storage." | cùng test trên; ảnh 09 |
| 3 | Tiến trình xuất/tải lên là live region có % trong nhãn, nên TalkBack đọc lại mỗi khi % đổi | Nhãn là tên bước, % là `value`: mỗi bước đọc một lần, focus vào thì đọc % hiện tại | test `upload progress speaks its phase once` |
| 4 | Hộp thoại Đăng xuất và Gây crash: mở ra không xướng tiêu đề; vùng nền quanh hộp thoại đọc "Dismiss" tiếng Anh | `AppDialog` đặt tên route bằng tiêu đề, giống `AlertDialog`; nền đọc "Đóng" | test `… dialog is announced, closes in Vietnamese`; ảnh 04, 05 |
| 5 | TalkBack đọc "Đang tải PDF lên Cloud Storage **3 Period**" vì chuỗi trạng thái dùng ba dấu chấm ASCII | Ba chuỗi trong `ProfileViewModel` đổi sang ký tự "…", như các nút đang dùng | ảnh 07 (trước), 08 (sau) |
| 6 | Tên và email nhập vào thẻ danh tính, khung tiêu điểm bao cả thẻ gồm vai trò và nút Đăng xuất | Tên và email thành một node riêng | ảnh 01 |
| 7 | Sign-in: dòng tiêu đề lớn "Thực đơn trường thọ cho cả tuần" không phải heading | Đánh dấu heading | test `sign-in headline is a heading` |
| — | Hộp thư trống: câu "Chưa có thông báo nào." sẽ nhập vào thẻ sau khi sửa lỗi 1 | Node riêng | test `each card title is a heading of its own` |
| 8 | Trên Android **không tiêu đề nào là heading**. Flutter 3.47 chỉ đặt `isHeading` khi `headingLevel > 0` (`BaseRoleConfigurator.configureHeading`), nên `header: true` của lỗi 1 và 7 không có tác dụng với TalkBack. Ở chế độ đọc Headings, TalkBack báo "No previous heading" | Thêm `headingLevel` cho cả 8 tiêu đề: thanh tiêu đề, tên Longvita và tiêu đề hộp thoại cấp 1; tiêu đề Sign-in, "Firebase Demo Area" và `state_views` cấp 2; tiêu đề thẻ cấp 3 | test `every heading has a level`, `sign-in headline is a heading`; ảnh 15 (trước), 16 và 19 (sau) |

Lỗi 5 và lỗi 8 chỉ thấy được khi chạy TalkBack thật. Cây Semantics không cho thấy lỗi 5, còn với lỗi 8 thì cây vẫn có cờ `isHeader`.

Năm test Semantics mới fail trên code gốc `b2101a3` và pass sau khi sửa. Lỗi 5 được kiểm thêm trong test tiến trình. Test mới thứ sáu kiểm bố cục Profile ở 412 dp với cỡ chữ 2.0; nó pass cả trước và sau khi sửa.

## Kết quả TalkBack trên emulator

| Ảnh | Thao tác và kết quả |
|---|---|
| `01-profile-walk-top.png` | Vuốt phải từ "Quay lại": Hồ sơ → tên + email (một lần đọc, khung chỉ bao tên và email) → "Vai trò: user" → "Đăng xuất" → "Firebase Demo Area" → "Báo cáo PDF" |
| `02-profile-walk-pdf-inbox.png` | Mô tả thẻ PDF → "Xuất báo cáo PDF" → "Thông báo" → mô tả → từng tin, mỗi tin một lần đọc (tiêu đề + nội dung) |
| `03-profile-walk-rc-crashlytics.png` | Phần trước đây chưa đi tuần tự. Mô tả Remote Config → "Số món gợi ý tối đa: 5" → "Điểm trường thọ: Bật" → "Banner: …" → "Cập nhật Remote Config" → "Crashlytics" → mô tả → "Gây crash thử" (Button) → vòng lại "Quay lại" |
| `04-crash-dialog-talkback.png` | Chạm đúp "Gây crash thử": hộp thoại mở, TalkBack đọc ngay "Gây crash thử?". Vuốt: nội dung → "Gây crash" → "Hủy" → "Đóng" (nền). Tiêu điểm không ra khỏi hộp thoại. Chạm đúp "Hủy": hộp thoại đóng, tiêu điểm về "Gây crash thử", app không crash (PID không đổi) |
| `05-signout-dialog-talkback.png` | Tương tự với "Đăng xuất?": tiêu đề → nội dung → "Đồng ý" → "Hủy" → "Đóng". Chạm đúp "Hủy": vẫn đăng nhập, tiêu điểm về "Đăng xuất" |
| `06-export-disabled-talkback.png` | Chưa có thực đơn: "Xuất báo cáo PDF … Button. disabled" |
| `07-export-before-ellipsis-fix.png` | Trước sửa lỗi 5: "0%, Đang khởi tạo tài liệu PDF 3 Period" |
| `08-export-after-fix-talkback.png` | Sau sửa: "Đang khởi tạo tài liệu PDF…" → "Đang tải PDF lên Cloud Storage…" → "Đã tải PDF lên Cloud Storage." |
| `09-export-success-walk.png` | Sau khi tải lên: thông báo thành công → URL → "Mở PDF đã lưu" → "Chia sẻ PDF đã lưu" → "Thông báo" |
| `10-open-pdf-talkback.png` | Chạm đúp "Mở PDF đã lưu" mở trình xem PDF của hệ thống (Print dialog). Back quay về Profile, tiêu điểm vẫn ở "Mở PDF đã lưu" |
| `11-rc-refresh-talkback.png` | Chạm đúp "Cập nhật Remote Config": TalkBack đọc thông báo "Không có giá trị mới hoặc chưa tải được. Vẫn dùng giá trị hiện có." |

Back trên thanh tiêu đề cũng chạy được bằng TalkBack: chạm đúp "Quay lại" đưa về Home.

Flutter trên Android đặt `value` trước nhãn, nên tiến trình được đọc là "0%, Đang …".

## Cỡ chữ và chiều rộng

TalkBack tắt. Kích thước được đặt bằng `wm size` và `wm density 320`; cỡ chữ đặt bằng `settings put system font_scale`. Mỗi ảnh cuộn Profile từ đầu đến cuối, ở trạng thái đã tải lên và có tin trong hộp thư. Sau đó đã trả về mặc định.

| Ảnh | Viewport | Cỡ chữ |
|---|---|---|
| `12-layout-360-1.0.png` | 360×720 dp (720×1440 px, DPR 2) | 1.0 |
| `12-layout-360-2.0.png` | 360×720 dp | 2.0 |
| `12-layout-412-1.0.png` | 412×824 dp (824×1648 px, DPR 2) | 1.0 |
| `12-layout-412-2.0.png` | 412×824 dp | 2.0 |
| `13-dialogs-360-text2.0.png` | 360 dp: hộp thoại Gây crash và Đăng xuất | 2.0 |

Không có tràn bố cục: logcat không có "overflowed", không có sọc vàng đen, mọi nút còn đủ chữ. Widget test kiểm thêm Profile ở 360 và 412 với cỡ chữ 2.0, hai hộp thoại ở cỡ chữ 2.0, và Sign-in ở 360 với cỡ chữ 2.0.

## Bổ sung sau PM review, 03/11/2026

Ba mục còn thiếu theo PM review của `14ec763`. Thiết bị và cách kiểm giống phần trên.

**Cử chỉ mới:**
- Vuốt xuống rồi lên: đổi chế độ đọc (reading control).
- Vuốt xuống, vuốt lên: sang mục kế tiếp, mục trước theo chế độ đọc đó.
- Vuốt xuống rồi sang trái: Back của TalkBack.

Chế độ đọc đã trả về "Characters" như ban đầu.

### PM-S4-14-01 — Remote Config đang cập nhật (widget test)

Test `while refreshing, the action says so and cannot be repeated`. Fake `ScriptedRemoteConfig` giữ fetch bằng một `Completer`.

- **Lúc đang chờ:** nút là button, nhãn "Đang cập nhật…", disabled, không có tap action. Chạm lần nữa không tạo fetch thứ hai (`fetches == 1`), không hiện thông báo, giá trị vẫn là 5.
- **Khi fetch xong:** nhãn về "Cập nhật Remote Config", enabled, có tap action. Hiện "Đã áp dụng giá trị mới.", giá trị thành 7.
- **Kiểm ngược:** tạm bỏ `isLoading` của nút thì test fail đúng ở assertion pending. Code đã khôi phục.
- Không sửa production. Đây là widget test với fake, không phải Remote Config thật.

### PM-S4-14-02 — Sign-in trên bản mới (QA host, TalkBack thật)

**Môi trường:**
- `test/qa/sign_in_talkback_host.dart` chạy `SignInScreen` thật và `AuthViewModel` thật trên `FakeAuthService`. Build bằng `flutter build apk --debug -t test/qa/sign_in_talkback_host.dart`.
- Không chạy Firebase và không mở Google sign-in thật: đây **không** phải bằng chứng đăng nhập Google/Firebase.
- Mỗi lần bấm Google, picker giả "mở" 3 giây rồi lần lượt trả: hủy, lỗi mạng.
- Bản debug có dải "DEBUG" ở góc màn.
- Cài đè lên app giữ dữ liệu app, nên phiên của Charlie vẫn còn. Sau đó đã cài lại app thật từ code cuối.

| Ảnh | Kết quả |
|---|---|
| `14-signin-qa-walk-order.png` | Thứ tự vuốt phải: Longvita → "Thực đơn trường thọ cho cả tuần" → mô tả → "Đăng nhập bằng Google" (Button). Icon lá được bỏ qua. QA host lần 1, trước lỗi 8; thứ tự này không đổi theo `headingLevel` |
| `15-signin-headings-before-fix.png` | Chọn chế độ Headings, đứng ở mô tả rồi vuốt lên: "No previous heading". Đây là cách tìm ra lỗi 8 |
| `16-signin-headings-after-fix.png` | Sau khi sửa: từ mô tả vuốt lên → "Thực đơn trường thọ cho cả tuần" → "Longvita" → "No previous heading"; vuốt xuống lại về tiêu đề |
| `17-signin-google-loading-cancel.png` | Chạm đúp nút Google: nút thành "Đang mở tài khoản Google…" và bị tắt. Khi hủy, TalkBack đọc live region "Bạn đã đóng cửa sổ chọn tài khoản. Đăng nhập lại khi bạn sẵn sàng."; tiêu điểm giữ ở nút |
| `18-signin-dismiss-and-retry.png` | Thông báo → "Ẩn thông báo"; chạm đúp thì thông báo mất. Tiêu điểm về "Longvita" và lần này TalkBack đọc cả "Heading". Bấm Google lần nữa: lỗi mạng được đọc ngay ("Không có kết nối mạng. Kiểm tra mạng rồi thử lại."), nút đổi thành "Thử lại với Google" (Button) |

### PM-S4-14-03 — Chia sẻ PDF (TalkBack thật, app thật)

| Ảnh | Kết quả |
|---|---|
| `20-share-pdf-talkback.png` | Trên bản app từ code cuối, chạm đúp "Chia sẻ PDF đã lưu". Bảng chia sẻ Android (ChooserActivity) mở với "Sharing 1 file", tệp `plan_….pdf`; không gửi đi đâu. Cử chỉ Back của TalkBack đưa về Profile (MainActivity), tiêu điểm vẫn ở "Chia sẻ PDF đã lưu". Vuốt trái/phải vẫn chạy |

Lần thử trước trên bản `14ec763` (về bằng phím Back hệ thống) cho cùng kết quả.

### Tiêu đề trên Profile sau lỗi 8

`19-profile-headings-after-fix.png`: ở chế độ Headings, vuốt xuống từ "Quay lại" đi qua Hồ sơ → Firebase Demo Area → Báo cáo PDF → Thông báo → Remote Config → Crashlytics. Có lúc TalkBack báo "No next heading" khi tiêu đề kế tiếp còn nằm ngoài màn; lần vuốt sau nó cuộn tới tiêu đề đó.

## Kiểm bằng lệnh

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 279/279 pass. Gồm 271 test trước đó, 6 test của `14ec763`, và 2 test mới: Remote Config đang chờ, heading có level.
- Test heading cũng fail khi bỏ `headingLevel` (kiểm ngược), và pass khi có.
- `git diff --check`: sạch.

## Giới hạn

- Sign-in trên bản mới được đi bằng QA host với Auth giả. Đăng nhập Google/Firebase thật vẫn dựa vào evidence của S3-4.
- Lúc đang mở picker, TalkBack không đọc nhãn mới "Đang mở tài khoản Google…" của nút đang được focus. Trên app thật, picker của Google mở ngay nên người dùng vẫn biết. Khi hủy hoặc lỗi thì có thông báo đọc ra.
- Sau "Ẩn thông báo", tiêu điểm nhảy về đầu màn ("Longvita") vì node đang được focus đã mất. Không bị kẹt, nhưng chưa đặt lại tiêu điểm vào nút Google.
- Các trạng thái sau chỉ kiểm bằng widget test với service giả, chưa thấy trên máy:
  - đang tải lên có %;
  - lỗi tải lên, "Thử tải lên lại" và "Hủy tải lên";
  - hộp thư trống;
  - thông báo bị tắt quyền;
  - Remote Config đang chờ.
- Chưa thử trên máy thật. Chưa nghe kiểm cách phát âm (xem phần Cách kiểm).
- Ngoài phạm vi, chưa sửa: `meal_plan_viewmodel.dart` và `ingredient_viewmodel.dart` còn chuỗi "..." sẽ bị đọc "3 Period". Các màn khác dùng `Semantics(header: true)` mà không có `headingLevel` cũng sẽ không là heading trên Android; trong `lib/` hiện không còn chỗ nào như vậy.
