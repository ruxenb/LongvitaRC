# Test Plan — Google ARTEMIS Automated E2E Testing (Lab 3)

> **Trạng thái 02/11/2026: PLANNED - chưa có ARTEMIS raw runs để xác minh.** Các kết quả 3/3 điền sẵn ở bản mẫu đã được trả về Planned. Widget/unit tests pass không phải E2E. Dùng [QA/evidence plan thống nhất](coordination/LONGVITA_LAB3_QA_AND_EVIDENCE_PLAN.md), giữ TC-01..11 và mở rộng coverage; thiếu SDK/device phải fail setup, không dùng Dummy SUCCESS.

> **Tài liệu:** Kế hoạch kiểm thử tự động toàn diện bằng Agent AI Google ARTEMIS.  
> **Người phụ trách:** Thái An (Instrument & Testing)  
> **Môi trường:** Python 3.12+, uv, ADB, model hỗ trợ được tài khoản cho phép; ARTEMIS Flash profile (hồi quy) và Pro profile (thăm dò).

---

## 1. Bản Đồ Luồng Nghiệp Vụ Quan Trọng $\to$ Màn Hình

| Mã Luồng | Tên Luồng Nghiệp Vụ | Màn hình liên quan | Mục tiêu kiểm thử E2E |
|:---:|:---|:---|:---|
| **Flow Auth** | Đăng nhập & Đăng xuất Google | `SignInScreen`, `HomeScreen`, `ProfileScreen` | Tương tác native picker, điều hướng AuthGate, xóa phiên làm việc |
| **Flow 1** | Lập & lưu thực đơn 7 ngày trường thọ | `S01`, `S02`, `S03`, `S04`, `S10` | Nhập form, tính toán thực đơn, hiển thị 7 ngày, lưu vào Firestore |
| **Flow 2** | Tổng hợp nguyên liệu & Đi chợ | `S04`, `S07`, `S08` | Dialog chỉnh số lượng, validate chặn số âm, checkbox shopping list |
| **Flow 3** | Tra cứu sách & Thay đổi món ăn | `S04`, `S05`, `S06`, `S09` | Xem trích dẫn sách, đổi món ăn, cập nhật lại thực đơn tuần |
| **Flow Cloud** | Xuất báo cáo, FCM & Remote Config | `ProfileScreen`, Android Notification Shade | Sinh PDF, upload Storage, nhận notification native, đổi giá trị UI |

---

## 2. Danh Sách $\ge 10$ Test Cases (Chuẩn Appendix B)

| ID | Luồng | Điều kiện tiên quyết (Precondition) | Lệnh ngôn ngữ tự nhiên (Natural-Language Instruction cho ARTEMIS) | Kết quả mong đợi (Verifiable Expected Result) | Loại Test | Tỷ lệ Pass (>=3 runs) |
|:---:|:---|:---|:---|:---|:---:|:---:|
| **TC-01** | Flow Auth | App cài đặt mới, trạng thái signed out | *"Mở ứng dụng Longvita. Trên màn hình Đăng nhập, chạm vào nút 'Đăng nhập bằng Google'. Trong hộp thoại native Google Account Picker, chọn tài khoản test. Xác minh chuyển hướng về Trang chủ (S01) và thanh điều hướng dưới hiển thị."* | Thấy tiêu đề 'Longvita', thanh navigation có 4 tab | **Native Interaction** | Planned - 0 runs |
| **TC-02** | Flow 1 | Đã đăng nhập, đang ở Trang chủ (S01) | *"Từ Trang chủ, bấm 'Tạo thực đơn'. Trên màn hình S02, chọn nhóm tuổi '< 65', nhập cân nặng '60', chọn 3 bữa/ngày, khung giờ ăn 12h, bấm 'Tiếp tục'. Trên S03, bấm 'Tạo kế hoạch'. Chờ loading và báo cáo số ngày hiển thị trên S04."* | Màn hình S04 hiển thị đủ danh sách 7 ngày, có nút 'Lưu kế hoạch' | **Happy Path** | Planned - 0 runs |
| **TC-03** | Flow 1 | Đang ở S03 Create Plan, ngắt kết nối mạng | *"Trên màn hình S03, ngắt kết nối mạng (Airplane mode) và bấm 'Tạo kế hoạch'. Xác minh màn hình hiển thị trạng thái lỗi ErrorStateView kèm nút 'Thử lại'. Bật lại mạng, bấm 'Thử lại' và xác minh chuyển sang S04."* | ErrorStateView xuất hiện với nút Retry hoạt động thành công | **Error Path** | Planned - 0 runs |
| **TC-04** | Flow 1 | Đang ở S04 với thực đơn hợp lệ | *"Trên S04, bấm nút 'Lưu kế hoạch'. Xác minh có thông báo xác nhận thành công. Điều hướng đến tab Cá nhân -> Kế hoạch đã lưu (S10) và xác minh kế hoạch vừa lưu có trong danh sách."* | Kế hoạch xuất hiện trong danh sách S10 với đúng ngày tạo | **Happy Path** | Planned - 0 runs |
| **TC-05** | Flow 2 | Đang ở S04 Weekly Plan | *"Từ S04, bấm 'Tổng hợp nguyên liệu' để sang S07. Bấm icon sửa tại nguyên liệu đầu tiên. Trong hộp thoại, nhập '-50' rồi bấm Lưu. Xác minh thông báo lỗi validation. Nhập lại '150' và lưu. Bấm 'Tạo danh sách mua sắm' sang S08."* | Báo lỗi 'Số lượng phải lớn hơn 0'; sau khi sửa hợp lệ chuyển sang S08 | **Happy / Validation** | Planned - 0 runs |
| **TC-06** | Flow 2 | Đang ở S08 Shopping List | *"Trên S08, tick chọn 2 nguyên liệu đầu tiên. Thoát ra Trang chủ (S01), sau đó mở lại S08 từ thanh điều hướng. Báo cáo trạng thái của 2 nguyên liệu đó."* | 2 nguyên liệu vừa chọn vẫn giữ nguyên trạng thái checked (Persistence) | **Happy Path** | Planned - 0 runs |
| **TC-07** | Flow 3 | Đang ở S04 Weekly Plan | *"Chạm vào thẻ món ăn thứ hai để mở Chi tiết món ăn (S05). Xác minh trích dẫn sách 'La dieta della longevità' hiển thị. Bấm 'Đổi món ăn' sang S06. Chọn một món ăn thay thế và bấm 'Xác nhận thay đổi'. Xác minh S04 cập nhật món mới."* | Món ăn mới được cập nhật trên S04; quy tắc tối đa 2-3 bữa cá không bị vi phạm | **Happy Path** | Planned - 0 runs |
| **TC-08** | Flow Cloud | Đang ở màn hình Profile | *"Trên màn hình Profile, cuộn đến khu vực Firebase Demo Area, bấm 'Xuất báo cáo PDF'. Chờ thanh tiến trình đạt 100% và báo cáo đường link download URL hiển thị trên màn hình."* | Hiển thị link URL hợp lệ chứa định dạng storage `reports/{uid}/...` | **Happy Path** | Planned - 0 runs |
| **TC-09** | Flow Cloud | Đang ở màn hình Profile | *"Quan sát giá trị tham số 'max_meal_recommendations' trên khu vực Demo. Bấm nút 'Cập nhật Remote Config'. Xác minh giá trị cập nhật sau fetch/activate thành công theo cache interval mà không cần khởi động lại ứng dụng."* | Hai tham số làm đổi hành vi thực sự trên cùng build, có defaults/failure handling; hiển thị giá trị thôi chưa đủ | **Happy Path** | Planned - 0 runs |
| **TC-10** | Flow Cloud | App đang chạy nền (Background) | *"Gửi một tin nhắn thông báo push từ Firebase Console. Kéo thanh Android Notification Shade xuống, chạm vào thông báo vừa nhận. Xác minh ứng dụng mở trực tiếp màn hình chi tiết được chỉ định."* | App được đưa lên foreground và điều hướng đúng màn hình đích | **Native Interaction** | Planned - 0 runs |
| **TC-11** | Flow Auth | Đang ở Profile, tài khoản đang đăng nhập | *"Bấm nút 'Đăng xuất'. Trong hộp thoại xác nhận, bấm 'Đồng ý'. Xác minh ứng dụng chuyển hướng về màn hình Đăng nhập (SignInScreen) và không thể truy cập lại Home bằng nút Back."* | Điều hướng về SignInScreen; bấm Back thoát app thay vì vào Home | **Happy Path** | Planned - 0 runs |

---

## 3. Quy Định Assertions Định Lượng & Hạn Chế Test Flaky

- **Không chỉ assert `status == 'SUCCESS'`:** Mỗi test case bắt buộc yêu cầu ARTEMIS đọc giá trị cấu trúc trên giao diện (text đếm, tên món ăn, URL tải) và assert so sánh với giá trị mong đợi.
- **Quy tắc chạy $\ge 3$ lần:** Mọi test case phải chạy tối thiểu 3 lần với preconditions độc lập và log từng run. Test case nào không đạt 3/3 được coi là *Flaky*, phải phân tích nguyên nhân:
  - Do thời gian chờ (Timing / Asynchronous latency): Tăng timeout hoặc chờ loading indicator biến mất.
  - Do câu lệnh tự nhiên mơ hồ (Ambiguous instruction): Viết lại prompt rõ ràng, chỉ định chính xác tên nút.
  - Do lỗi giao diện thiếu nhãn `Semantics`: Bổ sung Semantics label vào Flutter widget.

---

## 4. Kế Hoạch Phiên Kiểm Thử Thăm Dò (Exploratory Testing Session — Pro Profile)

- **Thời lượng:** 20 phút chạy tự do không theo kịch bản có sẵn.
- **Mô hình AI:** ARTEMIS Pro profile, model thực tế được ghi theo cấu hình đã pin để phân tích sâu giao diện, phát hiện góc chết navigation, xoay màn hình, và ngắt kết nối mạng bất ngờ.
- **Báo cáo kết quả:** Ghi nhận toàn bộ issue phát hiện, mức độ nghiêm trọng và commit khắc phục tương ứng vào thư mục `evidence/artemis/`.
