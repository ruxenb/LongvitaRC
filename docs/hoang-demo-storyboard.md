# Hoàng — Storyboard quay video ba user flows (S8-11)

Đây là **kế hoạch quay**, chưa phải file video đã quay. Không điền thời gian/kết quả giả.

## Chuẩn bị quay
- Android emulator hoặc điện thoại thật, APK LongvitaRC mới nhất, dữ liệu recipes đã duyệt, test Google account đăng nhập được.
- Firebase rules shopping_lists đã deploy sau khi nhóm review; kiểm tra mẫu dữ liệu recipes có nguyên liệu thật và nguồn trích dẫn.
- Công cụ ghi: Android adb shell screenrecord /sdcard/longvita_hoang_demo.mp4 hoặc OBS Studio.
- Bật âm thanh/hiển thị thao tác rõ, quay dọc 9:16 nếu dùng điện thoại; đảm bảo không lộ email riêng tư/credential trong video.
- Đặt dữ liệu demo test account, không dùng dữ liệu bệnh án hoặc thông tin nhạy cảm của người dùng.

## Cảnh 1 — Flow 1: S01/S02/S03/S04/S10
1. Mở Home và Tạo thực đơn.
2. Nhập tuổi/cân nặng hợp lệ, chọn số bữa và khung giờ.
3. Tạo kế hoạch: show Loading và S04 đủ 7 ngày.
4. Lưu lên Firestore, quay S10 đọc lại kế hoạch.
5. Error path: tắt mạng để hiển thị Retry, sau đó bật lại và thử lại.

## Cảnh 2 — Flow 2: S04/S07/S08
1. Mở S07 tổng hợp nguyên liệu.
2. Mở Edit dialog; thử số -50, thấy lỗi; nhập 150 hợp lệ.
3. Xóa một nguyên liệu, nhấn Hoàn tác.
4. Mở S08, tích checkbox, quay lại và vào lại S08; kiểm tra persistence.

## Cảnh 3 — Flow 3: S04/S05/S06/S09
1. Mở món ở S04 -> S05, đọc calo/đạm và nguồn Firestore.
2. Mở S09 (không đọc trích dẫn không được xác minh).
3. Mở S06, chọn món thay thế và xác nhận; kiểm tra S04.
4. Recovery: no-alternative -> S02; nếu mất mạng lúc Update phải giữ món gốc và có Retry.

## Quay và lưu
- Quay màn Android thật; lưu file video và metadata commit/PR sau khi kiểm chứng.
- Không chỉnh sửa video để làm giả trạng thái Firebase hoặc số liệu ARTEMIS.
- Đính kèm screenshot và kết quả TC02–TC07 vào evidence/hoang/ khi có dữ liệu.
