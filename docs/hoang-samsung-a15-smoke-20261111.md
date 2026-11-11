# Samsung Galaxy A15 — nghiệm thu bước đầu trên điện thoại thật

**Dự án:** PRM393 LongvitaRC (nhánh `feature/hoang-vietnamese-figma-20261110`)
**Ngày:** 11/11/2026
**Thiết bị:** Samsung Galaxy A15 SM-A155F, Android 16, màn hình 1080 x 2340, ADB được cấp quyền
**Phạm vi:** Kiểm thử thủ công qua ADB, không ghi dữ liệu lên Firebase chung

## Kết quả quan sát trên điện thoại

| Hạng mục | Kết quả quan sát thực tế | Trạng thái |
| --- | --- | --- |
| Kết nối Android thật | ADB báo `device`, Windows nhận thiết bị Samsung và mô-đun ADB | Đạt |
| Cài đặt lần đầu | `adb install -r` thành công; app id `vn.edu.fpt.longvita` khởi chạy | Đạt |
| S01 — Trang chủ | Giao diện tiếng Việt, lời chào, nút tạo thực đơn 7 ngày, thanh menu bốn mục | Đạt bước hiển thị |
| S10 — Kế hoạch đã lưu | Hiển thị trạng thái chưa có kế hoạch; nút tải lại vẫn hiện trong trạng thái rỗng | Đạt bước hiển thị; UX cần rà soát |
| Tra cứu công thức | Tải và hiển thị **2 công thức trong kết quả truy vấn lúc kiểm tra**, có kcal/đạm | Đạt bước đọc |
| Hồ sơ | Hiển thị hồ sơ hiện tại và vai trò; nút PDF vô hiệu khi chưa có kế hoạch, hộp thư ở trạng thái rỗng | Đạt bước hiển thị |
| S02 — Sở thích ăn uống | Có các trường tuổi, cân nặng, số bữa, khung giờ ăn. Bấm tiếp tục khi chưa nhập bắt lỗi ở tuổi/cân nặng | Đạt validation bắt buộc |
| S05 — Chi tiết công thức | Hiển thị nguyên liệu định lượng gram, các bước nấu, nhãn nguồn. Ảnh chưa được xác minh hiển thị placeholder | Đạt bước đọc |
| Crash smoke | Các lần kiểm tra `FATAL EXCEPTION`, `E/flutter`, `FlutterError` trả về 0 dòng lỗi khớp | Đạt trong thời gian đã quan sát |

**Quan trọng:** “Từ sách” trong UI và ước tính dinh dưỡng từ USDA không phải bằng chứng hoàn chỉnh về nguồn học thuật, quyền sử dụng nội dung hoặc tính chính xác dinh dưỡng. Kết quả hai công thức **không** chứng minh toàn bộ bộ recipe đã được kiểm duyệt.

## Thay đổi sau khi quan sát

- Việt hóa hiển thị vai trò `user/staff/admin/expert` mà không đổi mã quyền trong database.
- Dùng “Cấu hình từ xa” thay cho “Remote Config”, “Làm mới cấu hình” thay cho “Cập nhật Remote Config”, “Thông điệp” thay cho “Banner”.
- Kiểm thử màn Hồ sơ: **60/60** đạt; toàn bộ Flutter: **484/484** đạt; Flutter Analyze: không có vấn đề.
- Bản APK sau sửa đã **build thành công**; tuy nhiên điện thoại mất kết nối ADB ngay trước bước cài đè. **Chưa xác nhận giao diện bản mới trên Samsung A15**; cần nối lại USB, cài đè và chụp bằng chứng.

## Nơi lưu bằng chứng

Ảnh chụp thực tế tại `D:\PRM393\Longvita_phone_evidence\20261111_reconnect\` và thư mục `navigation\`; log test tại `D:\PRM393\hoang_fulltests_phone_20261111.log`. **Không đưa ảnh chụp Hồ sơ hoặc file chứa thông tin tài khoản lên GitHub.** Không chỉnh sửa/bổ sung dữ liệu cá nhân của người dùng và không tạo thực đơn mới trên tài khoản thật trong lượt smoke.

## Còn thiếu để nghiệm thu cuối

1. So sánh ảnh thật với tất cả 10 màn S01–S10 và xác nhận sai lệch Figma/khả năng truy cập.
2. Ghi bằng chứng ít nhất ba lượt ARTEMIS theo `docs/test-plan.md`, với assertions trên giá trị đọc thật; không thay thế bằng unit/widget tests.
3. Kiểm thử xuyên vai trò Firestore/Firebase và các quy tắc bảo mật bằng tài khoản thử nghiệm được phép.
4. Xác minh toàn bộ recipe, các định lượng và nguồn trích dẫn trước khi coi là lộ trình dinh dưỡng được kiểm duyệt.
5. Video demo và hồ sơ nghiệm thu đầy đủ theo Final Assignment.

**Trạng thái:** Hoàn thành native Android smoke cho các màn đọc và validation trên, **chưa nghiệm thu toàn bộ Final Assignment 100%**.

## Xác minh trên monorepo mới nhất (sau PR #29)

- Đã port thay đổi UI sang \`mobile/lib/screens/profile_screen.dart\` của \`origin/main\` và cập nhật test ở \`mobile/test/profile/profile_screen_test.dart\`.
- \`flutter analyze --no-pub lib/screens/profile_screen.dart test/profile/profile_screen_test.dart\`: **No issues found**.
- \`flutter test --no-pub --concurrency=1 test/profile/profile_screen_test.dart\`: **60/60 đạt**.
- \`flutter analyze --no-pub\` toàn ứng dụng trên baseline \`origin/main\` phát hiện **19 vấn đề** ở các file ngoài thay đổi Hoàng, đặc biệt lỗi gọi API trong \`lib/services/gemini_ai_service.dart\`. Cần người phụ trách AI xử lý trước khi coi build monorepo toàn hệ thống đạt.
- Bộ **484/484 unit/widget tests** và Android APK build thành công trước đó thuộc **cây mã mobile cũ** trước khi nhóm chuyển sang monorepo. Không được đồng nhất với việc toàn bộ monorepo đã đạt 484/484 hay APK mới đã được cài trên điện thoại.
- Samsung A15 không còn được Windows phát hiện qua USB ở cuối lượt kiểm thử, nên chưa thể cài lại APK và chụp giao diện đã Việt hóa mới trực tiếp trên điện thoại.

## Cập nhật kiểm thử build mới sau khi đồng bộ main (11/11/2026)

- Sau khi sửa nốt tiêu đề `Firebase Demo Area` thành `Khu vực minh họa Firebase`, bản APK debug monorepo đã **build thành công**, cài đè trên Samsung Galaxy A15 **thành công** (`APK_INSTALL=0`) và mở app có PID. Ảnh trực tiếp xác nhận nhãn Việt hóa mới.
- Flutter Mobile: Analyze 0 vấn đề, 483/483 test đạt. Shared Core: Analyze 0 vấn đề, 20/20 test đạt. Web: Analyze 0 vấn đề, 69/69 test đạt.
- Ảnh có thông tin cá nhân chỉ lưu tại `D:\PRM393\Longvita_phone_evidence\20261111_merged_main`, không upload vào repo.
- Bằng chứng full test là tự động chạy local, không thay cho ARTEMIS 3 lần, Firebase cross-role production 3 lần, kiểm chứng recipe và Video Demo.
