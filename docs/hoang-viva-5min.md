# Hoàng — Kịch bản vấn đáp 5 phút (S9-5-HD)

Trạng thái: bản hướng dẫn luyện tập, KHÔNG ghi nhận đã thực hiện trước giảng viên.

## 0:00–0:40: Kiến trúc
"Tôi phụ trách Cloud Firestore, IDataService/DataService và ViewModel của ba luồng S01–S10. Giao diện không gọi Firebase trực tiếp. ViewModel trả state Loading/Empty/Error/Data và kiểm soát bất đồng bộ."

Mở: docs/hoang-firestore-schema.md, lib/main.dart, lib/services/i_data_service.dart.

## 0:40–1:40: Trình diễn một luồng
S01 > S02 nhập tuổi, cân nặng, bữa/ngày, khung giờ > S03 tạo > S04 xem thực đơn 7 ngày > lưu > S10 đọc lại. Nếu dữ liệu recipes rỗng, giải thích Empty State đúng; KHÔNG dựng mock giả. Nếu mạng lỗi, nhấn Retry.

## 1:40–2:35: Giải thích ViewModel
Mở lib/viewmodels/meal_plan_viewmodel.dart:
- generatePlan(): đọc recipes thật, chặn input không hợp lệ, tạo ViewStateSuccess khi dữ liệu hợp lệ.
- saveActivePlan(): không xóa activePlan khi cloud write thất bại.
- replaceMeal(): ghi Firestore xong mới thay activePlan; lỗi giữ món cũ.
- SessionEpoch: bỏ qua Future từ phiên cũ sau đăng xuất.

## 2:35–3:30: Một test ARTEMIS
Mở e2e_test/test_flows.py và chạy TC02 trên emulator/Android test account khi daemon sẵn sàng. Quan sát replay_steps, không chỉ nhìn status success. Nêu dữ liệu screenshot, tên màn thực và thời gian thực tế. Nếu daemon chưa sẵn, trả lời rõ là chưa chạy, không trình bày fixture như evidence.

## 3:30–4:20: Remote Config live
Mở màn Profile do Charlie phụ trách và Firebase Console. Trước khi test cần xin phép team; đọc max_meal_recommendations, đổi một giá trị khác, publish, bấm "Cập nhật Remote Config", đọc giá trị sau. Hoàn nguyên sau khi thử. Không nói đã thử nếu chưa có Console access.

## 4:20–5:00: Review, bug và câu hỏi
- HOANG-F01: announcement stream complete without data could spin forever. Fixed in Home.
- HOANG-F02: old user shopping write could queue writes for another session. Separate fix commit d078f89 + unit regression.
- Phân biệt unit/widget test với ARTEMIS native runs; nêu các kiểm chứng còn thiếu.

## Câu hỏi dự phòng
1. Vì sao cần interface IDataService? Để cách ly SDK và fake unit tests, không nối Firestore trực tiếp ở build().
2. Vì sao không dùng dữ liệu mẫu khi Firestore rỗng? Vì rubric đòi dữ liệu thật, tránh false demo và sai nguồn.
3. Lỗi offline ở S03 khác lỗi save ở S04 thế nào? Generation trả Error state với Retry; save error giữ activePlan và cho phép lưu lại.
4. Checklist lưu ở đâu? shopping_lists/{uid}/plans/{planId}; owner-only rules chờ deploy.
5. Quyền riêng tư? UID-scoped reads/writes; AuthViewModel clears SessionScoped on logout and SessionEpoch stops late completions.
6. Đã đạt 100% chưa? Chưa: còn Android live, Firebase permissions, ARTEMIS, screenshot, review và nghiệm thu.
