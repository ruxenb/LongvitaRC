# Worklog — Charlie (Phạm Văn Minh)

Task S8-17-CM. Ghi theo commit và evidence thật, cập nhật dần. Trạng thái nghiệm thu theo [bàn giao kỹ thuật](tasks/charlie-progress.md), không theo file này.

**Công cụ AI đã dùng:** Claude Code để viết code, test và báo cáo kỹ thuật; Codex để phân tích, review và tài liệu. Charlie quyết định phạm vi, duyệt các thao tác trên Firebase và GitHub, tự đăng nhập tài khoản Google khi test.

## 02/11/2026

### Design system (S2-3, S2-4) — `6dfddf9`

- **Đã làm:** tokens, theme, typography với font có license, 9 nhóm widget dùng chung và widget phụ.
- **Quyết định:** Figma Lab 2 là tham chiếu đóng băng, cải thiện UI trực tiếp trong code.
- **Kiểm tra:** QA test và ảnh ở 360/412dp, text scale, `test/qa/`.

### Firebase Auth và session (S3-3, S3-4, S3-5) — `56b1896`, `9d76623`

- **Đã làm:** bootstrap có màn lỗi và thử lại, Google Sign-in, kết quả đăng nhập có kiểu rõ ràng, profile recovery, dọn dữ liệu khi đăng xuất.
- **Quyết định:** lỗi đọc profile tách khỏi hủy đăng nhập. Xin quyền thông báo sau khi đăng nhập, không phải lúc mở app.
- **Sửa lỗi:** kết quả upload hoặc query về muộn có thể lọt vào phiên của user sau. Sửa bằng `SessionEpoch`, phủ cả trường hợp đăng nhập lại cùng user. Trước khi sửa 16 ca test fail.
- **Kiểm tra:** đăng nhập, hủy, mở lại, đăng xuất chạy thật với tài khoản của Charlie, xem `evidence/auth/S3-9-20261102/`.
- **Còn vướng:** chưa chạy A/B bằng hai tài khoản trên thiết bị; Hoàng chưa duyệt phần sửa trong ViewModel của Hoàng.

### Firebase project và Firestore rules (S0-4, S3-1, S3-9, AUD-11) — `4e4bffd`

- **Đã làm:** tạo project `longvita-8da7e`, app `vn.edu.fpt.longvita`, SHA máy Charlie, bật Google provider, tạo Firestore `asia-southeast1`, thêm plugin `google-services`.
- **Quyết định:** cấu hình qua Console vì `firebase login` trên terminal không chạy được, nên chưa có `firebase_options.dart`.
- **AUD-11:** sửa rules (không tự đổi role, khóa owner và status, kiểm tra data shape), publish lên project trước khi Hoàng, Thắng review vì phần này chưa ai bắt đầu. Cần hai bạn review và chốt B1–B5.
- **Kiểm tra:** 41/41 test emulator; rules cũ trượt 16 ca với cùng bộ test. Đọc profile và lưu plan nháp chạy thật với rules mới.

### Tích hợp `main` và Analytics (S5-4) — `cd82637`, `9ecc806`

- **Vấn đề:** `main` không biên dịch được vì API Analytics đổi nhưng caller chưa sửa.
- **Quyết định:** không gửi `generate_meal_plan` khi chưa có `eatingWindowHours`, thay vì điền số giả. `file_size_kb` lấy từ byte PDF thật.
- **Còn vướng:** chưa kiểm DebugView; cần màn S02 của Hoàng.

### FCM chuẩn bị (S4-12) — `7a9fa8c`, `2d547c7`

- **Đã làm:** 4 callback sau một gateway, parser có version, chống trùng, inbox theo từng user.
- **Sửa lỗi:** tin bị từ chối hoặc tin trùng ID có thể ghi đè nội dung tin đã nhận, do lưu ở hai nơi. Sửa bằng cách chỉ giữ một nơi lưu.
- **Kiểm tra:** chỉ bằng gateway giả. **Chưa có push thật.**
- **Còn vướng:** route, history, token và recipient chờ nhóm chốt.

### PDF chuẩn bị (S4-10) — `40e47a1`

- **Đã làm:** font tiếng Việt Regular/Bold, `LocalReportStore` lưu theo UID.
- **Quyết định:** dùng Roboto cho PDF vì thư viện `pdf` không chọn được độ đậm từ font biến thiên. Cần chốt với Hoàng.
- **Kiểm tra:** render fixture và xem ảnh. Chưa chứng minh đúng plan đang xem.

### Pull Request (S7-1-CM) — [PR #1](https://github.com/ruxenb/LongvitaRC/pull/1)

- Mở PR vào `main`. Chưa có output AI review.
- Tài liệu làm việc nội bộ giữ ở local, không đưa vào cây file chia sẻ.

### Lưu, mở và chia sẻ PDF (S4-10) — nhánh `feature/charlie-pdf-01`

- **Đã làm:** lưu PDF trên máy trước khi upload, export ID giữ nguyên khi thử lại, mở và chia sẻ qua service riêng dùng gói `printing` có sẵn.
- **Quyết định:** làm trên nhánh riêng để PR #1 không to thêm. Hai nút mở và chia sẻ đặt tạm trên Home để test được trên Android, sẽ chuyển sang Profile ở S4-13.
- **Lỗi tìm được khi chạy thật:** upload thất bại gây `Unhandled Exception` vì stream tiến độ không có xử lý lỗi. Test giả không phát hiện được. Đã sửa trong `StorageService` và chạy lại trên emulator.
- **Kiểm tra:** 150/150 test. Emulator: file được lưu, upload lỗi vẫn còn file, mở được màn xem trước, mở được cửa sổ chia sẻ.
- **Còn vướng:** chưa có plan thật từ S4-3; project chưa có Storage nên upload thành công chưa chạy thật; cần chốt chính sách giữ file.
- **Sửa lỗi sau review (PM-PDF-01):** hai lần xuất chồng nhau làm file trên máy và URL thuộc hai lần xuất khác nhau. Sửa bằng cách chỉ cho một thao tác chạy tại một thời điểm, kết quả cũ không ghi đè được thao tác mới. Thêm nút Thử lại trên Home và test cho lỗi stream của `StorageService`. Trên emulator, bấm xuất 3 lần liên tiếp chỉ tạo 1 file.

### Merge vào `main` — [PR #1](https://github.com/ruxenb/LongvitaRC/pull/1), [PR #2](https://github.com/ruxenb/LongvitaRC/pull/2)

- **Đã làm:** leader yêu cầu tự kiểm tra rồi merge. Merge PR #1 (`a6f489e`), đổi base PR #2 sang `main` rồi merge (`6f58786`).
- **Vấn đề:** Thắng vừa đẩy `d9d0a90`, gây xung đột ở 4 file: hai file ViewModel và hai file task.
- **Quyết định:** dùng merge commit để không phải dựng lại nhánh PDF. Giữ các dòng task của Thắng và của Charlie. Không nhận `eating_window_hours: 12` cố định vì đó là số giả. Sửa `age > 65` thành `age >= 65` theo Thắng, vì analytics plan ghi từ 65 tuổi.
- **Kiểm tra:** trên `main` sau merge, analyzer sạch, 168/168 test, rules 41/41.
- **Còn vướng:** hai PR chưa có review của thành viên khác hay AI. S7-1-CM phải chạy trên PR kế tiếp.

### Profile và Firebase Demo Area (S4-13) — [PR #3](https://github.com/ruxenb/LongvitaRC/pull/3)

- **Merge:** Charlie quyết định merge thủ công khi không có lỗi, vì CodeRabbit chưa được cài. PR chưa có AI review và Hoàng chưa xem phần sửa Home.
- **Đã làm:** màn Profile có danh tính, đăng xuất, xuất PDF với tiến độ và URL, hộp thư FCM, Remote Config, crash thử.
- **Quyết định:** chỉ thêm một nút mở Profile trên Home, chưa gỡ khối xuất tạm vì Home thuộc Hoàng. Gây crash phải qua hộp xác nhận. Khi cập nhật Remote Config trả về false, chỉ báo "không có giá trị mới hoặc chưa tải được", vì service không phân biệt hai trường hợp này.
- **Lỗi tìm được:** hộp thư không tự cập nhật khi có tin mới vì `NotificationService` không báo cho ViewModel. Thêm `onChanged`.
- **Kiểm tra:** 191/191 test. Emulator: mở và quay lại Profile, upload lỗi có thông báo, thử lại không tạo file mới, xem trước, chia sẻ, hủy crash, đăng xuất về Sign-in.
- **Còn vướng:** chưa có upload thành công, push thật, crash thật, TalkBack.

### Kiểm Analytics trên DebugView (S5-4) — `evidence/analytics/S5-4-debugview-20261102/`

- **Đã làm:** bật chế độ debug trên emulator, đăng nhập và đăng xuất bằng tài khoản thật, xem trên Console.
- **Kết quả:** `login` có `method=google`, `logout` có; mỗi lần thao tác một event, không gửi trùng.
- **Còn vướng:** `export_report` chờ upload thật (DEC-01), `generate_meal_plan` chờ màn S02.

### Storage không chờ Blaze (S3-7, S4-11) — [PR #4](https://github.com/ruxenb/LongvitaRC/pull/4)

- **Vấn đề:** nhóm cần tiến độ gấp, nhưng Storage cần Blaze và DEC-01 chưa chốt.
- **Quyết định:** làm đủ code và test trên Storage Emulator, ghi rõ đây là bằng chứng emulator. Khi có Blaze chỉ cần deploy rules và chụp Console. Không bật billing.
- **Đã làm:** lỗi có kiểu, hủy thật, 14 test rules, đăng xuất hủy upload và xóa PDF trên máy, ghi chú PDF chuyển xuống chân trang.
- **Lỗi tìm được khi chạy thật:** khi mất mạng, SDK chờ tới lần thử lại kế tiếp mới hủy, nên nút Hủy trông như không có tác dụng trong hàng chục giây. Sửa bằng cách báo đã hủy ngay và bỏ qua kết quả về sau. Test giả không phát hiện được.
- **Kiểm tra:** 223/223 test, rules 55/55. Rules mở toang làm đúng 9 ca fail. Emulator: upload thành công và file trùng byte, hủy, mất mạng, thử lại không tạo file mới, bị từ chối, đăng xuất giữa chừng.
- **Còn vướng:** chưa deploy, chưa có file trên project thật (DEC-01). Tiến độ tăng dần chưa thấy trên thiết bị vì file quá nhỏ.

### Push thật, Crashlytics và ARTEMIS (S4-12, S4-15, S3-1, S6-4, S6-7) — [PR #4](https://github.com/ruxenb/LongvitaRC/pull/4)

- **Merge:** Charlie quyết định merge khi không có lỗi để nhóm có code mới. PR chưa có AI review, nên S7-1-CM chuyển sang PR kế tiếp.
- **Phối hợp:** Thắng, Hoàng, Thái An đồng ý cho sửa Home, thêm route, plugin Crashlytics, `conftest.py` và dùng contract FCM tạm.
- **Đã làm:** lịch sử thông báo theo UID, bấm tin mở Profile, Home chỉ còn lối sang Profile, hộp xác nhận đăng xuất, plugin Crashlytics, viết lại harness ARTEMIS và 3 file test.
- **Quyết định:** tin nhận ở isolate nền chưa biết ai đăng nhập nên chờ ở file riêng. Gửi từ Console bằng chiến dịch tới app, không nhập token vào Console.
- **Lỗi tìm được:** `conftest.py` cũ nhập SDK không tồn tại nên luôn rơi vào client giả báo SUCCESS. Một test lịch sử có lúc fail vì chờ cố định 50ms; sửa bằng cách chờ đúng lúc ghi xong. TC-11 yêu cầu hộp xác nhận đăng xuất mà app chưa có.
- **Kiểm tra:** 251/251 test. Thật: push 3 trạng thái, bấm tin mở Profile, lịch sử còn sau khi mở lại, crash thử lên Console.
- **Còn vướng:** ARTEMIS chưa chạy vì chưa có key. Chưa nối `FlutterError.onError`. Chưa có thông báo trên màn khác khi tin đến lúc app đang mở.

### Nháp báo cáo Auth (S8-3) — `docs/report-drafts/s8-3-firebase-auth.md`

- **Đã làm:** phần Auth, gồm luồng, xử lý lỗi, kiểm thử, bằng chứng, giới hạn. Mỗi ca lỗi ghi rõ đã kiểm trên emulator hay chỉ bằng fake.
- **Còn vướng:** phần Storage và FCM chờ bằng chứng thật (S4-15).

### Tin đến khi app đang mở, TalkBack, nháp FCM (S4-12, S4-14, S8-3) — [PR #5](https://github.com/ruxenb/LongvitaRC/pull/5)

- **Vấn đề:** khi app đang mở, Android không đưa tin lên khay, nên tin chỉ âm thầm vào hộp thư. Hướng dẫn S4-12 yêu cầu phải có phản hồi thấy được.
- **Đã làm:** `AuthGate` hiện thanh thông báo trên màn đang xem, nút "Xem" mở hộp thư. Chỉ tin mới mới hiện; bấm tin, tin trùng, tin của người khác, tin sau khi đăng xuất thì không.
- **Kiểm tra:** 257/257 test. Thật: hai chiến dịch Console, thanh thông báo hiện trên Home, "Xem" mở Profile, hộp thư có cả hai tin.
- **TalkBack:** lệnh chạm của adb bỏ qua chế độ chạm để khám phá, nên dùng console của emulator để chạm và vuốt. Sign-in đi hết; Profile đi đến hộp thư; vuốt giả lập đôi khi nhảy về nút Quay lại, nên phần cuối Profile mới kiểm nhãn.
- **Báo cáo:** nháp FCM trong `docs/report-drafts/s8-3-firebase-fcm.md`.
- **Lỗi tìm thấy khi review (PM-FCM-02):** thanh thông báo nằm ở `ScaffoldMessenger` gốc nên còn trên Sign-in sau khi đăng xuất, và callback chỉ kiểm `mounted` nên "Xem" mở được Profile khi chưa đăng nhập. Sửa bằng cách ghi epoch phiên lúc lấy tin, kiểm lại lúc callback chạy, và đóng thanh thông báo của phiên đã kết thúc. 8 regression, 6 trong đó fail trên code cũ. 265/265 test; thử đăng xuất trên emulator với tin thật.
- **Lượt 2 (hàng đợi):** `close()` của SDK chỉ ẩn snackbar đứng đầu và assert điều đó, nên hai tin rồi đăng xuất vẫn để lọt tin thứ hai. Sửa bằng cách cho nội dung thông báo tự kiểm phiên khi được dựng (messenger chỉ dựng snackbar đầu hàng) và tự gỡ nếu phiên đã hết; không đụng snackbar của màn khác. 5 regression hàng đợi, 270/270 test.
- **Merge:** 03/11, `30ca6e3`, sau khi PM xác minh PM-FCM-02 tại `0321aee`; theo quyết định của Charlie, chưa có AI review.
- **Còn vướng:** S7-1-CM chuyển sang PR kế tiếp; token theo user và route theo đích chờ contract cuối.

### Báo cáo Storage và nội dung slide (S8-3, S8-7) — nhánh `feature/charlie-report-02`

- **Quyết định:** viết phần Storage ngay bằng bằng chứng Storage Emulator thay vì chờ DEC-01, và ghi rõ ở đầu bản nháp đó là emulator. Khi có Storage thật chỉ cần thay ảnh và bỏ ghi chú.
- **Đã làm:** `docs/report-drafts/s8-3-firebase-storage.md` (luồng, lỗi, rules, kiểm thử, bằng chứng, giới hạn). `docs/report-drafts/s8-7-slides.md`: ba slide, mỗi slide một thông điệp, cơ chế lỗi, ảnh bằng chứng thật và ghi chú người nói.
- **Kiểm tra:** số liệu trong bản nháp đối chiếu với log rules (55/55, rules mở toang fail 9) và các test hiện có; mọi đường dẫn ảnh trong slide đều tồn tại.
- **Kịch bản clip (S8-12):** `docs/report-drafts/s8-12-clip-script.md`, 6 cảnh, mỗi cảnh có thao tác, màn Console, lời nói và thời lượng.
- **Thử hàng đợi PM-FCM-02 trên thiết bị:** tắt mạng, phát hành hai chiến dịch, bật mạng lại. Chỉ một tin đến trước khi đăng xuất (logcat có một lần nhận), nên chưa tái hiện được hai tin cùng chờ; Sign-in sạch trong 72 giây sau đăng xuất. Ghi nhận là ca một tin.
- **Còn vướng:** chưa có template slide chung; Storage chưa có trên project thật; clip chưa quay (Charlie tự quay sau).

### Cài ARTEMIS client, ôn vấn đáp (S6-4, S6-7, S9-5-CM) — nhánh `feature/charlie-report-02`

- **Đã làm:** cài `artemis-client` đúng commit ghim vào venv ngoài repo; kiểm bằng `inspect` rằng mọi hàm và trường mà script gọi đều có; pytest nhận đủ 7 test; chạy khi chưa có daemon thì cả 7 lỗi ở fixture, không test nào pass. Ghi `asyncio_default_fixture_loop_scope` trong `pyproject.toml` để bỏ cảnh báo và giữ hành vi ở bản pytest-asyncio sau.
- **Quyết định:** chưa cài daemon. Script khởi động của ARTEMIS tự cài công cụ và helper APK, và cần key LLM; làm khi có key S0-5.
- **Vấn đáp:** `docs/report-drafts/s9-5-viva-charlie.md`, kịch bản 5 phút và câu hỏi thường gặp, dẫn dòng code trên `main`. Lệnh test dự phòng đã chạy: 13/13.
- **Còn vướng:** key S0-5; chưa thử đổi Remote Config trên Console.
