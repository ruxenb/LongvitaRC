# Ôn vấn đáp S9-5-CM — Charlie

> Kịch bản 5 phút theo `task-charlie.md`: chạy một test, đổi một giá trị Remote Config live, giải thích một ViewModel và một quyết định review. Dòng code dẫn theo `main` `30ca6e3`. Phần ARTEMIS chỉ làm được khi nhóm có key S0-5; nếu chưa có, dùng phương án dự phòng ghi bên dưới và nói rõ lý do.

## 1. Chạy một test (khoảng 1 phút)

**Nếu có ARTEMIS:** daemon chạy với key, emulator mở sẵn app.

```bash
cd e2e_test
python -m pytest test_auth.py::test_tc01_sign_in_with_google -q
```

Nói: test giao một mục tiêu bằng lời cho agent ARTEMIS, agent tự thao tác trên máy và trả về những gì nó quan sát được. `conftest.py` không có client giả: thiếu daemon thì test lỗi ở fixture, không bao giờ pass giả. Mỗi lần chạy ghi một dòng vào `evidence/artemis/raw/runs.jsonl`.

**Dự phòng, chạy được ngay:**

```bash
flutter test test/profile/profile_screen_test.dart --plain-name "PM-FCM-02"
```

Nói: đây là 13 regression cho lỗi PM-FCM-02. Trên code trước khi sửa, phần lớn trong số đó fail. Chúng dùng gateway FCM giả và `AuthViewModel` thật, nên kiểm đúng luồng đăng xuất và đổi tài khoản.

## 2. Đổi một giá trị Remote Config live (khoảng 1 phút)

1. Mở app, vào Hồ sơ, xem thẻ Remote Config: "Số món gợi ý tối đa: 5".
2. Console → Remote Config → sửa `max_meal_recommendations` thành 7 → Publish changes.
3. Trên app bấm "Cập nhật Remote Config": hiện "Đã áp dụng giá trị mới." và thẻ đổi thành 7.
4. Trả lại giá trị 5 sau buổi vấn đáp.

Nói: app nạp giá trị mặc định trong app trước (`setDefaults`), nên luôn có giá trị hợp lệ kể cả khi mất mạng. Bản debug cho fetch lại sau 5 giây, bản release sau 1 giờ (`lib/firebase/remote_config_service.dart:31`). Nút cập nhật gọi `forceFetchAndActivate()`; nếu không có gì mới, app nói thẳng là vẫn dùng giá trị hiện có, không báo thành công giả.

**Cần chuẩn bị:** chưa thử bước 2 trên Console lần nào. Phối hợp với Thái An (chủ Remote Config) và thử trước buổi vấn đáp.

## 3. Giải thích một ViewModel: `ProfileViewModel` (khoảng 1,5 phút)

File `lib/viewmodels/profile_viewmodel.dart`.

- **Vai trò:** cầu nối giữa màn Hồ sơ và các service Storage, FCM, Remote Config, Crashlytics, Analytics. Màn hình không gọi Firebase SDK trực tiếp.
- **Xuất PDF** (`exportAndUploadPdf`, dòng 161): dựng PDF, lưu trên máy trước, rồi mới tải lên. Mất mạng thì file vẫn còn, thử lại dùng cùng export ID nên không tạo file mới.
- **Một thao tác mỗi lúc:** mỗi lần xuất tạo một `Object()` làm token; kết quả chỉ được áp dụng nếu token đó còn là thao tác hiện tại (`_isActive`, dòng 284). Vì vậy file, URL, tiến độ và trạng thái luôn thuộc cùng một lần xuất (lỗi PM-PDF-01).
- **Hủy:** `cancelUpload` (dòng 249) báo đã hủy ngay, vì khi mất mạng SDK chỉ dừng ở lần thử lại kế tiếp. Lỗi này tìm thấy khi chạy thật, test giả không phát hiện được.
- **Phiên đăng nhập:** `onSessionStarted` (dòng 89) gắn hộp thư FCM với người dùng và mới xin quyền thông báo lúc này, nên người dùng mới thấy Sign-in trước. `clearSession` (dòng 114) tăng `SessionEpoch`, hủy upload, xóa PDF trên máy của người đó, xóa hộp thư. Kết quả async về muộn của phiên cũ bị bỏ qua nhờ epoch.

## 4. Giải thích một quyết định review: PM-FCM-02 (khoảng 1,5 phút)

- **Finding (P1):** sau khi đăng xuất, thanh thông báo của người dùng trước vẫn còn trên Sign-in, và nút "Xem" mở được Profile khi chưa đăng nhập. Nguyên nhân: snackbar nằm ở `ScaffoldMessenger` gốc, sống qua lần đổi màn; callback chỉ kiểm `mounted`.
- **Quyết định:** Accept. Đây là lỗi lộ dữ liệu giữa hai phiên.
- **Lượt 1** (`c40d884`): ghi epoch phiên lúc nhận tin, kiểm lại lúc callback chạy (`_isCurrent`, `lib/screens/auth_gate.dart:52`); đóng snackbar của phiên cũ bằng `controller.close()`.
- **Re-review tìm ra lỗi của chính bản sửa:** `close()` assert controller phải đứng đầu hàng đợi, nên với hai tin liên tiếp thì có assertion và tin thứ hai vẫn hiện. Tôi đọc mã nguồn Flutter SDK để xác nhận PM đúng.
- **Lượt 2** (`cb18415`): không chạm vào hàng đợi chung nữa. Nội dung snackbar tự kiểm phiên khi được dựng (`_SessionNotice`, dòng 142); messenger chỉ dựng snackbar đứng đầu, nên nếu phiên đã hết thì nó không vẽ gì và tự gỡ đúng chính nó. Snackbar của màn khác không bị ảnh hưởng.
- **Bài học:** đọc API thật của framework trước khi dựa vào nó; viết regression cho đúng ca đã fail (bản sửa lượt 1 làm 6 test mới fail trên code cũ, lượt 2 thêm 5 test hàng đợi).
- **Giới hạn nên nói:** finding này là review của PM. AI review trên PR (S7-1-CM) chưa làm vì CodeRabbit chưa được cài.

## Câu hỏi có thể gặp

| Câu hỏi | Trả lời ngắn |
|---|---|
| Sao lưu PDF trên máy trước khi tải lên? | Mất mạng hay bị từ chối thì không mất gì, và thử lại không phải dựng lại PDF. |
| Sao giới hạn thời gian thử lại upload 60 giây? | Mặc định của SDK là 10 phút; khi mất mạng, người dùng sẽ thấy app như bị treo. |
| Storage rules bảo vệ thế nào? | Chỉ `request.auth.uid == uid` mới đọc, ghi trong `reports/{uid}/`, còn lại từ chối. 14 test; rules mở toang làm đúng 9 ca fail, chứng tỏ test có tác dụng. |
| Sao Storage chỉ có bằng chứng emulator? | Project dùng Spark, Storage cần Blaze; nhóm chưa chốt DEC-01. Không bật billing khi chưa có quyết định. |
| Một tin FCM đến qua nhiều callback thì sao? | `NotificationInbox` khử trùng theo message ID: một mục, một lần điều hướng. |
| Tin đến khi app chạy nền được lưu thế nào? | Handler nền chạy ở isolate riêng, chưa biết ai đăng nhập, nên ghi vào file chờ; app chuyển vào hộp thư của đúng người khi đăng nhập hoặc quay lại foreground. |
| `SessionEpoch` để làm gì? | Phân biệt kết quả của phiên cũ với phiên mới, kể cả khi cùng một người đăng xuất rồi đăng nhập lại; so UID thì không phân biệt được. |
| Sao không dùng client ARTEMIS giả? | Client giả trả SUCCESS mà không nhìn app; test như vậy không chứng minh gì. Thiếu daemon thì test phải fail. |
| Bằng chứng nào là thật, bằng chứng nào là emulator hay fake? | Auth, FCM, Crashlytics, DebugView: Console thật trên emulator. Storage: Storage Emulator. Một số ca lỗi: test giả. README của từng thư mục bằng chứng ghi rõ. |

## Trước buổi vấn đáp

- [ ] Có key S0-5 và daemon ARTEMIS, chạy thử TC-01 ít nhất một lần.
- [ ] Thử đổi `max_meal_recommendations` trên Console cùng Thái An.
- [ ] Mở sẵn: `profile_viewmodel.dart`, `auth_gate.dart`, `firebase/storage.rules`, báo cáo PM-FCM-02.
- [ ] Luyện nói hết 4 phần trong 5 phút.
