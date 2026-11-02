# Analytics Event Plan — Longvita (Lab 3)

> **Tài liệu:** Kế hoạch đo lường sự kiện hành vi người dùng trên Firebase Analytics (Chuẩn Appendix A).  
> **Người phụ trách:** Thái An (Team Leader & Instrumentation)  
> **Trạng thái:** **ĐÃ PHÊ DUYỆT (Final Approved)** — *Được chốt và ký duyệt TRƯỚC KHI viết mã tracking theo quy định Handout Mục 6 & 8*.  
> **Các bên phê duyệt:** Thái An (Team Leader), Lê Nhật Thắng (Architect), Nguyễn Huy Hoàng (Features Dev).  
> **Cam kết bảo mật:** Tuyệt đối không chứa thông tin định danh cá nhân (No PII: không email, không họ tên, không số điện thoại).

---

## 1. Bảng Kế Hoạch Sự Kiện (Analytics Event Plan — Chuẩn Appendix A)

| Event Name | Trigger (Thời điểm kích hoạt) | Parameters (Tên & Kiểu dữ liệu) | Câu hỏi sản phẩm cần trả lời (Product Question) | Ánh xạ bước trong Flow Lab 2 |
|:---|:---|:---|:---|:---|
| **`login`** *(Firebase standard)* | Đăng nhập Google thành công vào ứng dụng | `method` *(string: "google")* | Bao nhiêu người dùng quay lại ứng dụng mỗi tuần? Kênh xác thực hoạt động ổn định không? | **Auth Flow:** Đăng nhập thành công |
| **`logout`** *(Firebase standard)* | Người dùng chủ động bấm Đăng xuất trên Profile | *(Không tham số)* | Thời lượng trung bình một phiên làm việc của người dùng kéo dài bao lâu trước khi đăng xuất? | **Auth Flow:** Đăng xuất |
| **`search`** *(Firebase standard)* | Người dùng gõ tìm kiếm món ăn hoặc chủ đề sách (S09/S06) | `search_term` *(string)*,<br/>`result_count` *(int)* | Những nguyên liệu/chủ đề nào được tìm nhiều nhất nhưng trả về 0 kết quả (cần bổ sung)? | **Flow 3:** Bước tìm kiếm món thay thế |
| **`generate_meal_plan`** *(Custom snake_case)* | Người dùng bấm tạo thực đơn 7 ngày tại S03 | `target_age_group` *(string: "under_65" \| "over_65")*,<br/>`meals_per_day` *(int)*,<br/>`eating_window_hours` *(int)*,<br/>`fish_meals_count` *(int)* | Tỷ lệ người dùng cao tuổi ($\ge 65$) chọn chế độ 2 bữa hay 3 bữa? Quy tắc đạm cá ($2-3$ bữa) có đạt không? | **Flow 1:** Bước S03 $\to$ S04 |
| **`view_recipe_details`** *(Custom snake_case)* | Mở xem chi tiết một món ăn trên S05 | `recipe_id` *(string)*,<br/>`is_fish_meal` *(int: 0 hoặc 1)*,<br/>`is_book_citation` *(int: 0 hoặc 1)*,<br/>`calories` *(int)* | Những món ăn nào trong sách được xem nhiều nhất? Người dùng quan tâm món chay hay cá hơn? | **Flow 3:** Bước S04 $\to$ S05 |
| **`replace_meal`** *(Custom snake_case)* | Hoàn tất đổi một món trong thực đơn tại S06 | `old_recipe_id` *(string)*,<br/>`new_recipe_id` *(string)*,<br/>`day_index` *(int: 1–7)* | Món ăn nào bị người dùng thay thế nhiều nhất và món nào thường được chọn thay thế? | **Flow 3:** Bước S06 $\to$ S04 |
| **`export_report`** *(Custom snake_case)* | Sinh file PDF thực đơn và tải lên Firebase Storage | `topic` *(string: "longevity_meal_plan")*,<br/>`file_size_kb` *(int)*,<br/>`has_shopping_list` *(int: 0 hoặc 1)* | Có bao nhiêu phần trăm người dùng tạo thực đơn thực sự xuất file PDF để áp dụng thực tế? | **Flow 2 / Profile:** Xuất báo cáo |
| **`toggle_shopping_item`** *(Custom snake_case)* | Người dùng tick chọn mua xong nguyên liệu tại S08 | `ingredient_id` *(string)*,<br/>`is_checked` *(int: 0 hoặc 1)* | Tỷ lệ hoàn thành danh sách đi chợ đạt bao nhiêu phần trăm? Nhóm nguyên liệu nào bị bỏ sót? | **Flow 2:** Bước S08 Shopping List |

---

## 2. Đo Lường Success Criterion Của Lab 2

- **Success Criterion Lab 2:** *Minh Anh (28 tuổi) tạo được thực đơn 7 ngày chuẩn đạm Longo trong vòng dưới 3 phút và tạo danh sách mua sắm thuận tiện.*
- **Chỉ số đo lường qua Funnel Analytics:**
  $$\text{Tỷ lệ chuyển đổi Funnel} = \frac{\text{Số lượt } \texttt{export\_report}}{\text{Số lượt } \texttt{generate\_meal\_plan}} \times 100\%$$
- Phân tích điểm rơi (drop-off points): Nếu người dùng dừng lại ở `view_recipe_details` mà không `save_meal_plan` hoặc không `export_report`, ứng dụng cần tối ưu lại độ phức tạp của công thức nấu ăn.

---

## 3. Kế Hoạch Thu Thập Bằng Chứng (DebugView Evidence Plan)

1. Kích hoạt chế độ kiểm thử Firebase Analytics trên thiết bị Android qua ADB:
   ```bash
   adb shell setprop debug.firebase.analytics.app vn.edu.fpt.longvita
   ```
2. Thao tác kích hoạt lần lượt từng sự kiện trong 8 sự kiện trên.
3. Chụp ảnh màn hình Firebase Console $\to$ Analytics $\to$ **DebugView**, thể hiện rõ:
   - Tên sự kiện (ví dụ `generate_meal_plan`).
   - Danh sách parameters và giá trị tương ứng.
   - User ID đã gán (`setUserId`).
4. Lưu toàn bộ ảnh bằng chứng vào thư mục `evidence/analytics/`.
