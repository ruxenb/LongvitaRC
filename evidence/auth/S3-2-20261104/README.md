# S3-2 — SHA debug và Google Sign-in trên bốn máy, 04/11/2026

- **Baseline:** `main` `e12719c` (merge PR #11). Nhánh `feature/charlie-signin-02`.
- **Firebase:** project `longvita-8da7e`, app Android duy nhất "Longvita Android", App ID `1:1041459198085:android:33939d119fc3892d8e11ec`, package `vn.edu.fpt.longvita`. Gói Spark; không đổi billing, rules, OAuth consent hay chính sách Auth.
- **Phạm vi:** chỉ SHA-1/SHA-256 debug. Bản release dùng tạm debug signing (`build.gradle.kts`, có TODO), nên vân tay release và Play App Signing chưa thuộc task này.

> **Cập nhật 04/11/2026:** Charlie xác nhận An, Thắng, Hoàng đều đã phản hồi đăng nhập thành công và hiện không có lỗi. Ba kết quả này là owner report qua Charlie; không phải PM tự chạy hoặc ảnh native mới được đính kèm. Các dòng mô tả lần kiểm trước giữ rõ nguồn.

## Ma trận bốn máy

| Máy | Nguồn vân tay | SHA-1 | SHA-256 | Firebase Console | OAuth client Android (server) | Đăng nhập Google từ trạng thái đã đăng xuất |
|---|---|---|---|---|---|---|
| Charlie | Claude đọc trực tiếp chữ ký APK debug build từ `e12719c` trên máy này (`apksigner verify --print-certs`) | `2B:AA:67:BC:4F:6B:FD:1D:AB:3E:BF:C5:E5:57:A9:BB:1E:D0:35:EC` | `6B:9C:C4:19:3A:F8:6F:42:71:3B:6C:A2:6A:0E:F8:34:16:1A:E5:78:FD:EB:76:5A:1B:D7:0F:A4:64:69:A6:E8` | Có | `1041459198085-qhs7…` (2/11) | **Đạt** — Claude chạy, Charlie tự chọn tài khoản (xem bên dưới) |
| Thái An | An tự gửi; Claude không chạy lệnh trên máy An | `EF:32:D1:B3:60:03:6F:FB:92:DF:82:49:2F:A5:95:42:50:0C:7C:88` | `5E:88:7E:C1:8D:5F:AD:F9:70:E9:DB:D5:22:C2:40:BB:82:97:05:64:23:89:83:C3:B1:1D:03:F7:A1:60:74:81` | Có (thêm 03/11) | `1041459198085-v3me…` (3/11) | **Đạt theo phản hồi An, Charlie xác nhận 04/11**; chưa đính kèm ảnh/device/Android/build SHA riêng |
| Thắng | Thắng tự gửi; Claude không chạy lệnh trên máy Thắng | `9D:9C:D3:03:14:86:02:C5:5A:3A:5E:68:97:22:35:4C:19:F6:D5:71` | `DF:E1:24:36:77:DE:ED:4C:85:17:B4:7A:DC:16:4B:14:5B:7E:6A:EE:5B:3B:75:C2:2B:55:29:3F:0D:A9:9A:0A` | Có (thêm 03/11) | `1041459198085-e7e9…` (3/11) | **Đạt theo phản hồi Thắng, Charlie xác nhận 04/11**; chưa đính kèm ảnh/device/Android/build SHA riêng. Bằng chứng restore cũ không phải nguồn xác nhận mới |
| Hoàng | `docs/hoang-android-sha.md` (Hoàng đọc bằng keytool ngày 04/11) | `D3:BE:85:D5:84:A9:92:9D:46:23:D2:5F:AD:6C:10:71:18:77:7E:62` | `2F:BA:C1:BE:7E:38:64:DD:FC:E2:1D:31:61:4D:3A:44:F9:D4:F3:0A:DA:D9:6E:DB:7E:57:09:B4:09:CC:12:83` | Có (thêm 04/11) | `1041459198085-pklr…` (4/11) | **Đạt theo phản hồi Hoàng, Charlie xác nhận 04/11**; chưa đính kèm ảnh/device/Android/build SHA riêng. Ghi chú chưa build được trong tài liệu cũ là snapshot trước phản hồi mới |

### Cách kiểm

- **Firebase Console:** đọc lúc 04/11 trên Project settings → Your apps → Android. Có đủ 8 vân tay (4 SHA-1, 4 SHA-256), khớp từng ký tự với bảng trên. Ảnh: `console-01-app-and-sha1.jpg`, `console-02-all-fingerprints.jpg`.
- **Google Cloud → Credentials** (cùng project): có 4 OAuth client Android do Google tự tạo. Mở từng client (chỉ đọc) thấy đúng package `vn.edu.fpt.longvita`, mỗi client mang một SHA-1 ở bảng trên. Có thêm web client `1041459198085-09p0…`. Không chụp trang này vì nó có danh sách service account; client ID không phải bí mật.
- **`android/app/google-services.json`:** `project_id` `longvita-8da7e`, App ID và package khớp. File tạo ngày 02/11 nên chỉ có client Android của Charlie (`2baa67bc…`) cùng web client.
  - Khi chạy, app dùng web client; client Android được Google kiểm theo package + SHA-1 ở phía server, và cả 4 đã có.
  - Vì vậy **không thay file** trong task này.
  - Nếu một máy báo lỗi cấu hình (ví dụ `ApiException: 10`), lúc đó mới tải file mới từ Console và đối chiếu lại trước khi thay.

## Máy Charlie: đăng nhập trên `e12719c`

- **Máy:** Windows; Flutter 3.47.6; AVD `LocalMate_API_35` (`sdk_gphone64_x86_64`, Android 15) có Google Play services.
- **Build:** `flutter build apk --debug` từ `e12719c`. Chữ ký: `CN=Android Debug`, SHA-1 `2baa67bc…35ec`, SHA-256 `6b9cc419…a6e8`.

| Bước | Ảnh | Kết quả |
|---|---|---|
| Cài bản build, mở app | `charlie-00-restored.png` | Phiên trước được khôi phục (A) |
| Profile → Đăng xuất → Đồng ý | `charlie-01-signed-out.png` | Màn Sign-in |
| "Đăng nhập bằng Google" → Charlie tự chọn tài khoản trong account picker | `charlie-02-signed-in-home.png` | Home của A (`minhpvse183365@fpt.edu.vn`, tài khoản trường) |
| Profile, rồi đăng xuất | `charlie-03-profile.png`, `charlie-04-signed-out-again.png` | Đúng tài khoản; về Sign-in |

Logcat không có `ApiException`, `DEVELOPER_ERROR` hay `12500`. Claude không nhập mật khẩu và không chọn tài khoản thay Charlie.

Emulator này còn có tài khoản B. Ca A→B ở `evidence/auth/S3-5-20261104/` chỉ chứng minh cách ly tài khoản, không chứng minh máy hoặc certificate của người khác chạy được.

## Hướng dẫn cho An, Thắng, Hoàng

Mỗi bạn làm trên máy và bản build của mình:

1. Kiểm `git status --short` trước. Nếu còn thay đổi local thì giữ nguyên, không reset/clean/stash chỉ để cập nhật; phối hợp Charlie trước khi đổi nhánh. Khi working tree sạch: `git switch main`, `git pull --ff-only origin main`, `git rev-parse HEAD`, rồi `flutter pub get`. Baseline code là `e12719c` hoặc mới hơn; ghi đúng SHA đã build.
2. Kiểm SHA-1 debug của máy, chọn một trong hai cách:
   - `cd android && ./gradlew signingReport` (Windows: `.\gradlew signingReport`), xem phần `Variant: debug`;
   - hoặc `keytool -list -v` trên `%USERPROFILE%\.android\debug.keystore` như trong `docs/hoang-android-sha.md`.

   SHA-1 phải trùng giá trị của mình trong bảng trên. Nếu khác, gửi giá trị mới cho Charlie; không tạo keystore mới.
3. `flutter run` lên điện thoại hoặc emulator có Google Play và một tài khoản Google.
4. Nếu app đã đăng nhập: Profile → Đăng xuất → Đồng ý. Sau đó bấm "Đăng nhập bằng Google", chọn tài khoản, xem Home có đúng tên/email, rồi Profile → Đăng xuất.
5. Gửi Charlie:
   - ảnh dòng SHA-1 (không gửi mật khẩu hay file keystore);
   - ảnh Home sau khi đăng nhập (có thể che email cá nhân);
   - loại máy và phiên bản Android;
   - commit đã build.

   Nếu lỗi: gửi chữ trên màn hình và các dòng `ApiException`/`PlatformException` trong log của `flutter run`.

## Trạng thái

S3-2 chuyển **Chờ nghiệm thu** sau khi Charlie xác nhận phản hồi thành công của cả ba bạn (04/11). Phần Charlie có ảnh native; An/Thắng/Hoàng được ghi nhận theo owner report qua Charlie, hiện không báo lỗi. Đăng ký SHA đã có nguồn ở trên; chưa nhận ảnh/metadata từng máy trong lượt xác nhận này, không tạo bằng chứng thay hoặc coi PM đã tự chạy 4 máy. Ảnh/metadata có thể bổ sung để hồ sơ nộp bài đầy đủ; chưa tự đánh leader Accepted.

## PM review local và giới hạn bằng chứng

- PM đọc chữ ký APK hiện có bằng `apksigner verify --print-certs`: SHA-1 và SHA-256 khớp hàng Charlie. Đây là kiểm certificate của artifact; PM không tự chạy lại Google account picker hay thao tác Console trong lượt review.
- PM kiểm `google-services.json`, resource `processDebugGoogleServices/values/values.xml` và source plugin đang cài (`google_sign_in_android 6.2.1`): đúng project/package/App ID; `default_web_client_id` đúng web OAuth client trong config, được plugin dùng khi không truyền serverClientId. [Google services plugin docs](https://firebase.google.com/docs/android/google-services-plugin-and-file) mô tả resource này lấy từ OAuth `client_type: 3`. Giữ nguyên config hiện tại có cơ sở; chưa dùng kết quả này để suy ba máy còn lại đăng nhập thành công.
- Ảnh Console cho phép PM đối chiếu đủ bốn SHA-1. Phần cuối SHA-256 của Hoàng bị cắt ở ảnh thứ hai; “đủ 8 vân tay khớp từng ký tự” là quan sát Console của Dev, chưa được PM đọc độc lập đủ từ hai ảnh. Có thể bổ sung ảnh cuối danh sách khi cập nhật kết quả team; SHA-256 bổ sung không thay tiêu chí chính SHA-1 và đăng nhập trên bốn máy.
- Bốn OAuth Android clients/package/timestamps là kiểm tra trực tiếp của Dev đã ghi ở trên; PM chưa tự mở lại Credentials. Không đổi Console, billing, code hoặc config trong lượt PM review.
- Không chạy lại analyzer/tests vì diff chỉ là docs/evidence, source/config giống main e12719c. Kết quả 334 tests của bản nền không được ghi thành một lượt chạy mới cho task docs này. Ở snapshot a0e65ef, S3-2 còn Waiting input và 70% là ước lượng Dev. Xác nhận mới 04/11 phía trên thay trạng thái đó thành Chờ nghiệm thu; không dùng phần trăm cũ làm bằng chứng native.
