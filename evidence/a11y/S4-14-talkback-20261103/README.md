# S4-14 — TalkBack trên Sign-in và Profile, 03/11/2026

AVD `LocalMate_API_35` (Android 15, 320×640), TalkBack của Android Accessibility Suite có sẵn trong image, bản debug của nhánh `feature/charlie-fcm-feedback-01`. Khung xanh trong ảnh là tiêu điểm thật của TalkBack.

Thao tác chạm và vuốt được gửi qua console của emulator (`adb emu event mouse`), nên TalkBack nhận như ngón tay thật. Lệnh `adb shell input` không dùng được vì nó bỏ qua chế độ chạm để khám phá của TalkBack.

| File | Nội dung |
|---|---|
| `signin-focus-order.png` | Sign-in sau khi hủy chọn tài khoản: thứ tự tiêu điểm khi vuốt sang phải |
| `signin-nodes.txt` | Nhãn của từng node mà TalkBack đọc trên Sign-in |
| `profile-focus.png` | Profile: thứ tự tiêu điểm phần đầu, thẻ PDF và hộp thư |
| `profile-nodes.txt` | Nhãn của mọi node trên Profile, lấy bằng `uiautomator dump` khi cuộn hết màn |

## Kết quả

**Sign-in, đi tuần tự bằng TalkBack:** Longvita → "Thực đơn trường thọ cho cả tuần" → mô tả → thông báo đã hủy chọn tài khoản → "Ẩn thông báo" (nút) → "Đăng nhập bằng Google" (nút) → quay lại đầu. Icon lá chỉ để trang trí và được bỏ qua.

**Profile, đi tuần tự bằng TalkBack:** "Quay lại" (nút) → "Hồ sơ" → tên và email trong một lần đọc → "Vai trò: user" → "Đăng xuất" (nút) → "Firebase Demo Area" → thẻ Báo cáo PDF cùng lý do chưa xuất được → "Xuất báo cáo PDF" (nút, bị tắt). Trong hộp thư, mỗi tin được đọc một lần gồm tiêu đề và nội dung.

**Profile, phần chỉ kiểm nhãn:** "Cập nhật Remote Config" và "Gây crash thử" là nút có tên; các giá trị Remote Config và mô tả Crashlytics đều có chữ.

Không có nút nào chỉ có icon mà thiếu tên.

## Giới hạn

- Thao tác vuốt giả lập không ổn định: thỉnh thoảng tiêu điểm nhảy về "Quay lại" thay vì sang phần tử kế tiếp. Lần chạy lại từ giữa màn hình thì đúng thứ tự, nên đây có vẻ là lỗi của cách giả lập, chưa phải lỗi app. Phần Remote Config và Crashlytics chưa được đi tuần tự bằng TalkBack, chỉ có nhãn từ `uiautomator dump`.
- Log cho thấy bộ đọc dùng giọng en-US trong khi đang tải giọng tiếng Việt. Văn bản TalkBack đọc vẫn là các nhãn tiếng Việt ở trên. Chưa nghe kiểm tra cách phát âm.
- Chưa kiểm tra trên máy thật, chưa thử cỡ chữ lớn khi bật TalkBack.
- Nên có một người thử lại bằng tay trên emulator hoặc máy thật để xác nhận phần cuối Profile.
