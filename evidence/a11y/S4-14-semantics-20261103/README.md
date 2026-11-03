# S4-14 — Semantics và TalkBack trên Sign-in, Profile, hộp thư và PDF, 03/11/2026

Đợt hai của S4-14, tiếp theo [`../S4-14-talkback-20261103/`](../S4-14-talkback-20261103/). Đợt đó đi TalkBack hết Sign-in và nửa đầu Profile; Remote Config và Crashlytics mới chỉ kiểm nhãn bằng `uiautomator dump`.

- **Code:** nhánh `feature/charlie-a11y-02`, tách từ `main` `b2101a3` (sau khi merge PR #8).
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

Lỗi 5 chỉ thấy được khi chạy TalkBack thật; cây Semantics không cho thấy nó.

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

## Kiểm bằng lệnh

- `flutter analyze --no-pub`: No issues found.
- `flutter test --no-pub`: 277/277 pass (271 trước đó + 6 mới).

## Giới hạn

- Sign-in không đi lại bằng TalkBack đợt này: muốn vậy phải đăng xuất, rồi Charlie tự đăng nhập lại. Sign-in chỉ đổi một chỗ (lỗi 7), kiểm bằng widget test. Lần đi tuần tự trước vẫn là bằng chứng chính cho Sign-in.
- Các trạng thái sau chỉ kiểm bằng widget test với service giả, chưa thấy trên máy:
  - đang tải lên có %;
  - lỗi tải lên, "Thử tải lên lại" và "Hủy tải lên";
  - hộp thư trống;
  - thông báo bị tắt quyền;
  - nút Remote Config đang tải ("Đang cập nhật…"), vì bước này quá nhanh trên emulator.
- "Chia sẻ PDF đã lưu": TalkBack đọc đúng nhãn và vai trò nút, nhưng chưa chạm đúp mở bảng chia sẻ.
- Chưa thử trên máy thật. Chưa nghe kiểm cách phát âm (xem phần Cách kiểm).
- Ngoài phạm vi, chưa sửa: `meal_plan_viewmodel.dart` và `ingredient_viewmodel.dart` còn chuỗi "..." sẽ bị đọc "3 Period". Các chuỗi này không thuộc màn của Charlie.
