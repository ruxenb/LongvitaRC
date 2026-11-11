# Hoàng — bổ sung nghiệm thu Samsung A15 (11–12/11/2026)

**Phạm vi:** 26 task Lab 3 và các task Mobile HD của Hoàng. **Đây là báo cáo kiểm chứng thực tế, chưa phải xác nhận nghiệm thu 100%.** Baseline main: e9618ee. Thiết bị: Galaxy A15 Android 16. Không công khai dữ liệu riêng hoặc tài khoản.

## Kết quả mới đã thực hiện

| Ca | Kết quả có chứng cứ | Phạm vi kết luận |
| --- | --- | --- |
| Mobile unit/widget test | **487/487 pass**, exit 0; log D:\PRM393\hoang_newest_main_mobile_test_nov11.log | Không thay ARTEMIS E2E |
| Firebase Rules Emulator | **118/118 pass**, 18 suites, 0 fail; log D:\PRM393\hoang_final_rules_emulator_20261111.log | Emulator demo, không phải Firebase Console |
| APK main e9618ee | Build debug pass, bản sao phục hồi D:\PRM393\Longvita_phone_evidence\longvita_main_e9618ee_debug.apk | Build từ main mới |
| S01 → S10 → S04 → S07 | Đã thao tác và chụp 5 ảnh native; S10 có thực đơn cũ, S04 mở món và S07 có nguyên liệu | Đường đi và khả năng đọc dữ liệu |
| S04 bỏ nút chuyên gia | UIAutomator: có “Lưu thay đổi”, “Xem nguyên liệu”; không có “Gửi chuyên gia xét duyệt” | Đúng yêu cầu sau PR #48 |
| S07 → S08 | Mở được S08 từ S07 và quay lại; một assert của script sai vì heading S07 nằm ngoài vùng cuộn | Clip có thật, chưa hoàn tất xóa/Undo native |
| S04 → S05 → S09 | Mở công thức và trang kiến thức sách được trên máy thật | Clip có thật |
| Offline S04 / S07 / S10 | Wi-Fi 1→0→1, dữ liệu di động =0; ba màn vẫn điều hướng/đọc được dữ liệu cache | Chưa chứng minh mọi lỗi ghi hoặc Retry |
| StartupGate Error → Retry | QA APK hiện “Không thể khởi động ứng dụng”; bấm “Thử lại” vào Home. Sau đó cài lại APK chuẩn thành công | **Ca lỗi khởi động Android đạt**, không thay tất cả network-error paths |
| TalkBack | Bật được service và bound; tutorial TalkBack xuất hiện, che nội dung app nên chưa thể kết luận đọc S04. Đã tắt service, đóng tutorial, khôi phục Longvita | **Chưa đạt TalkBack end-to-end** |
| 29 recipe | Dry-run 29/29 qua kiểm tra cấu trúc, exit 0 | **Chưa được duyệt nội dung sách, dinh dưỡng và quyền phát hành** |

Ảnh raw của từng bước: D:\PRM393\Longvita_phone_evidence\native-qa-20261111\
Ảnh offline hợp lệ: D:\PRM393\Longvita_phone_evidence\offline-20261112\
Log offline hợp lệ: D:\PRM393\hoang_a15_offline_3screens_result_v2.log.
Phép đo offline đầu tiên bị tutorial TalkBack che màn là **không hợp lệ** và không được dùng làm bằng chứng.

## Bốn clip native đã ghi (để riêng trên ổ D)

Thư mục: D:\PRM393\Longvita_phone_evidence\videos\
- hoang_flow1_home_s10_s04_native_verified.mp4 — Home → S10 → S04.
- hoang_flow2_s07_s08_native.mp4 — nguyên liệu → danh sách mua sắm; cần kiểm tra lại trước khi đưa vào demo cuối vì một assert script thất bại.
- hoang_flow3_s04_s05_s09_native.mp4 — thực đơn → công thức → kiến thức sách.
- hoang_startup_error_retry_native_qa.mp4 — lỗi khởi động có kiểm soát → Thử lại → Home.

Bản có tên hoang_flow1_home_s10_s04_native_incomplete.mp4 **chỉ là bản nháp**, không tính đạt. Không tự đưa video hoặc ảnh raw có thể chứa dữ liệu sức khỏe lên GitHub.

## Task của Hoàng còn cần nghiệm thu độc lập

1. **S4-5/HD-02:** xóa nguyên liệu + Hoàn tác + Firestore read-back sau refresh trên thiết bị thật (widget tests đã có).
2. **S4-6/S4-7:** S06 thay món thành công với recipe đủ điều kiện; thử update error giữ món, offline/save/retry trên các flow còn lại.
3. **S4-8/S4-16/S4-17:** TalkBack tương tác thật, 360/412dp, scale 200%, contrast và ký duyệt lệch thiết kế 10 màn Figma.
4. **HD-04:** announcement mới từ Web cập nhật real-time trên Mobile với timestamp; Hoàng chịu trách nhiệm bên Mobile.
5. **HD-06/HD-07:** Firebase Console xác nhận metadata PDF, Analytics DebugView và Crashlytics; 118 emulator tests không thay bằng chứng production.
6. **S8-11:** bổ sung toàn bộ edit/Delete/Undo và lỗi/recovery vào video demo 3 flow; các clip trên hiện là đầu vào, chưa phải demo trọn vẹn.
7. **Dữ liệu recipe:** review đối chiếu nguồn sách, định lượng và quyền sử dụng 29 món trước khi nhóm duyệt phát hành. Dry-run không phải chứng nhận khoa học.

**Ranh giới phân công:** Thái An là owner việc chạy ARTEMIS đầy đủ ≥3 lượt, Thắng là owner đo Cross-role x3 và video tổng hợp Web+Mobile. Hoàng phối hợp các bước Mobile, không nhận thay nghiệm thu của owner khác. Luồng “Gửi đến chuyên gia” đã bỏ theo PR #48 nên không thể tự khẳng định HD-05 cũ đã hoàn thành.

## Xác nhận phục hồi thiết bị sau QA

Trong log D:\PRM393\hoang_a15_startup_retry_qa_result.log đã ghi: NORMAL_APK_RESTORED=True, WIFI_ORIGINAL=True và ACCESSIBILITY_ORIGINAL=True. Không xóa ứng dụng, xóa dữ liệu, đăng xuất, ghi món thử vào production hoặc phát hành 29 recipe.
