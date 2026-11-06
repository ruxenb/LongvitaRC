# Kế Hoạch & Bảng Theo Dõi Task — Hoàng

> **Thành viên:** Hoàng (Hoàng DV / YAHsaveme)  
> **Vai trò:** **Dữ liệu Nghiệp Vụ, Core UI Flows & State Management** (DataService, Models, ViewModels & Explicit State Models, 3 Flows S01–S10, Accessibility, Đồng bộ Figma)  
> **Tổng task:** 26 tasks | **Có bằng chứng đầu ra kỹ thuật:** 5/26 | **Đã triển khai, chờ nghiệm thu:** 18/26 | **Bị chặn/chưa đủ đầu ra:** 3/26

> **Đối chiếu 06/11/2026:** Các mức trên chỉ xác nhận bằng chứng thực hiện, KHÔNG phải 26/26 task đã được nghiệm thu. Người yêu cầu đã xác nhận mình là người phê duyệt và cho phép tiếp tục triển khai trong chat ngày 06/11/2026. Quyền này không khắc phục các giả định dinh dưỡng chưa xác minh, Firebase CLI đã hết xác thực hoặc thiếu kết quả chạy ARTEMIS trên Android. Xem [bảng kiểm toán](../hoang-acceptance-audit-20261106.md) và [PR #17](https://github.com/ruxenb/LongvitaRC/pull/17). Không tự ghi dữ liệu thử vào Firebase thật.


---

## 1. Trách Nhiệm Trọng Tâm
1. **Dữ Liệu Thật & ViewModels Chuẩn MVVM (Đón đầu Final Assignment):**
   - Chốt chuẩn hóa 100% bằng **Cloud Firestore** (`users`, `recipes`, `meal_plans`); tuyệt đối **không dùng dữ liệu hard-coded hoặc mock data**.
   - Xây dựng Data Models (`lib/models/`) đón đầu Assignment: `UserModel` (có sẵn `role: 'user'`), `MealPlan` (có sẵn `status: 'draft'`).
   - Triển khai `DataService` kết nối Firestore phía sau interface; bắt exception và chuyển hóa thành application errors dễ hiểu.
   - Xây dựng các ViewModels (`lib/viewmodels/`) với **explicit state model** (`loading`, `empty`, `error`, `data`) cho mọi màn hình nạp dữ liệu. Đảm bảo toàn bộ business logic (lọc, tính đạm, validate) nằm trong ViewModel/Service, **tuyệt đối không để trong hàm `build()`**.
2. **Triển Khai 3 User Flows & 10 Màn Hình Lab 2:**
   - **Flow 1 (S01, S02, S03, S04, S10):** Lập và lưu thực đơn 7 ngày. Xử lý `S03 Loading` $\to$ `S04 Result`; xử lý `Generation Error` và `Save Error` có nút `Retry` và `Back`.
   - **Flow 2 (S07, S08):** Tổng hợp nguyên liệu và đi chợ. Xây dựng Edit Ingredient Dialog dạng overlay trên S07 có validation (chặn số âm/bằng 0); Empty state; `SnackBar` Undo khi xóa nhầm nguyên liệu; Checkbox shopping list có tính bền vững (persistence).
   - **Flow 3 (S05, S06, S09):** Tra cứu công thức, trích dẫn sách và đổi món ăn. Xử lý `S06 No-Alternative` $\to$ `S02`; `Update Error` giữ nguyên món gốc + nút Retry.
   - Đảm bảo hiển thị đầy đủ Loading, Empty và Error state với nút Retry ở mọi màn hình; không có spinner quay vô hạn hay màn hình trắng khi lỗi mạng.
3. **Accessibility, Đồng Bộ Figma & Bàn Giao:**
   - Rà soát tiêu chuẩn Accessibility (A11y): độ tương phản đạt chuẩn, touch target $\ge 48$ dp, cỡ chữ $\ge 14$ sp, không phân biệt chỉ bằng màu sắc, test hiển thị tại cả 360 dp và 412 dp, không overflow stripes.
   - Gắn thuộc tính `Semantics` cho các nút, list item, cards để phục vụ Google ARTEMIS.
   - Đối chiếu Figma Page 03/06 $\leftrightarrow$ Flutter App; ghi nhận mọi sai lệch và lý do vào [`docs/design-traceability.md`](../design-traceability.md).
   - Viết các test script ARTEMIS: `e2e_test/test_flows.py`, `test_search.py`, `test_detail.py`.
   - Mở PR, chạy AI review, ghi nhận findings và fix commits.
   - Soạn Báo cáo, Slides và quay Video demo 3 user flows.

---

## 2. Bảng Danh Sách 26 Task Chi Tiết

| ID | Giai đoạn | Tên Task | Hỗ trợ | Phụ thuộc | Đầu ra / Bằng chứng | Tiêu chí (Điểm) | Ưu tiên | Tuần | Hạn | Trạng thái | Ghi chú |
|:---|:---|:---|:---:|:---:|:---|:---|:---:|:---:|:---:|:---:|:---|
| **S0-3-HD** | 0. Chuẩn bị | Cài trên máy: Flutter stable, FlutterFire CLI, Android device/emulator, ADB | — | — | `flutter doctor` không lỗi | — | Cao | 1 | | Chưa đủ điều kiện | Chuẩn bị máy |
| **S1-2** | 1. Plan | Chốt nguồn dữ liệu Cloud Firestore (chuẩn hóa schema `users`, `recipes`, `meal_plans` đón đầu Assignment), cấm mock data | Thắng | S0-1 | Bản schema Firestore | Data 0.75 | Cao | 1 | | Đã triển khai / chờ nghiệm thu | Firestore 100% |
| **S1-5** | 1. Plan | Thiết kế bổ sung màn Sign-in & Profile (kèm Firebase demo area) trên Figma Page 03 & nối prototype Page 06 | Charlie | S0-6 | Figma Page 03/06 cập nhật | Fidelity 0.5; Flows 1.0 | Cao | 1 | | Đã triển khai / chờ nghiệm thu | Giữ design system |
| **S4-1** | 4. Features | Xây dựng Data Models (User role, MealPlan status) + `DataService` Firestore sau interface; chuyển exception thành app errors | — | S2-1, S1-2 | `lib/models/`, `lib/services/` | Data 0.75 | Cao | 2 | | Đã triển khai / chờ nghiệm thu | Data Firestore 100% |
| **S4-2** | 4. Features | Xây dựng ViewModels + explicit state model (loading/empty/error/data); tách triệt để logic ra khỏi hàm `build()` | — | S4-1 | `lib/viewmodels/` | Layer 0.5; State 0.25 | Cao | 2 | | Đã triển khai / chờ nghiệm thu | Quản lý state |
| **S4-3** | 4. Features | Cung cấp dữ liệu thực đơn đang xem (getter/model) để Charlie tích hợp module sinh file PDF | Charlie | S4-2 | API nội bộ cho `ReportService` | Data 0.75 | Cao | 2 | | Đã triển khai / chờ nghiệm thu | Kết nối với PDF |
| **S4-4** | 4. Features | **Flow 1 (S01, S02, S03, S04, S10):** Lập & lưu thực đơn 7 ngày; Loading $\to$ S04; Error tại S03/S04 có Retry + Back | Thắng | S4-2, S2-4 | Flow 1 chạy end-to-end | Flows 1.0 | Cao | 2 | | Đã triển khai / chờ nghiệm thu | Mốc Milestone M3 |
| **S4-5** | 4. Features | **Flow 2 (S07, S08):** Tổng hợp nguyên liệu & đi chợ; Edit dialog overlay có validate dương; Empty state; Snackbar Undo | Thắng | S4-4 | Flow 2 chạy end-to-end | Flows 1.0 | Cao | 3 | | Đã triển khai / chờ nghiệm thu | Validation số dương |
| **S4-6** | 4. Features | **Flow 3 (S05, S06, S09):** Tra cứu sách & đổi món; S06 No-Alternative $\to$ S02; Update Error giữ món gốc + Retry | Thắng | S4-4 | Flow 3 chạy end-to-end | Flows 1.0 | Cao | 3 | | Đã triển khai / chờ nghiệm thu | Tổng $\ge 8$ screens |
| **S4-7** | 4. Features | Đảm bảo Loading / Empty / Error + nút Retry hoạt động trên mọi màn hình load dữ liệu; thông báo khi mất mạng | — | S4-2 | Không spinner vô hạn/màn trắng | States 0.75 | Cao | 3 | | Đã triển khai / chờ nghiệm thu | Xử lý ngoại lệ |
| **S4-8** | 4. Features | Gắn nhãn `Semantics` cho các nút, list item, cards, thông số trên toàn bộ màn hình của mình | — | S4-6 | Semantics trên màn hình của Hoàng | Test quality 0.5; A11y 0.25 | Trung bình | 3 | | Đã triển khai / chờ nghiệm thu | Hỗ trợ ARTEMIS |
| **S4-9** | 4. Features | Viết Fake service & unit test cho ViewModel chính (khuyến khích thực hiện) | — | S4-2 | Thư mục `test/` | State mgmt 0.25 | Thấp | 3 | | Có bằng chứng kỹ thuật | Kiểm thử đơn vị |
| **S4-16** | 4. Features | Rà soát Accessibility & Responsive: contrast, target $\ge 48$ dp, text $\ge 14$ sp, non-color cues, test tại 360 & 412 dp | Charlie | S4-6 | Bảng checklist A11y | A11y 0.25 | Cao | 3 | | Đã triển khai / chờ nghiệm thu | Tránh overflow |
| **S4-17** | 4. Features | Đối chiếu Figma Page 03/06 $\leftrightarrow$ App; ghi mọi thay đổi/sai lệch kèm lý do vào `design-traceability.md` | Charlie | S4-6 | Traceability & Figma đồng bộ | Fidelity 0.5 | Cao | 3 | | Đã triển khai / chờ nghiệm thu | Tránh lỗi lệch Figma |
| **S5-3** | 5. Instrument | Gắn mã log sự kiện Analytics trong ViewModel của flow (`search`, `view_<entity>`, ...) đúng vị trí bước người dùng | Thái An | S5-2, S4-2 | Events có parameters | Analytics 0.5 | Cao | 3 | | Đã triển khai / chờ nghiệm thu | Phối hợp Thái An |
| **S6-5** | 6. Test | Viết `e2e_test/test_flows.py` & `test_search.py`: test 3 flow gồm cả error paths (empty state / mất mạng + retry) | Thái An | S6-2 | `test_flows.py`, `test_search.py` | Test plan 0.5; Test quality 0.5 | Cao | 3 | | Đã triển khai / chờ nghiệm thu | ARTEMIS test flow |
| **S6-6** | 6. Test | Viết `e2e_test/test_detail.py`: test mở các màn hình chi tiết và các tab top-level | Thái An | S6-2 | `test_detail.py` | Test plan 0.5 | Cao | 3 | | Đã triển khai / chờ nghiệm thu | ARTEMIS test detail |
| **S6-13** | 6. Test | Sửa lỗi ứng dụng / bổ sung thuộc tính Semantics khi kiểm thử ARTEMIS phát hiện lỗi (thuộc phạm vi của mình) | — | S6-9 | Fix commit | Test quality 0.5 | Trung bình | 4 | | Đã triển khai / chờ nghiệm thu | Fix theo log ARTEMIS |
| **S7-1-HD** | 7. Review | Mở PR cho phần của mình; chạy $\ge 1$ công cụ AI review (CodeRabbit/Copilot/SonarCloud); lưu output | — | S6-1 | PR + output trong `evidence/review/` | Review 0.5 | Cao | 4 | | Có bằng chứng kỹ thuật | AI review trên PR |
| **S7-2-HD** | 7. Review | Ghi $\ge 1-2$ findings (file:dòng, loại, tóm tắt), quyết định Accept/Modify/Reject kèm lý do; kê khai AI tools | — | S7-1-HD | Dòng ghi trong `code-review.md` | Findings 0.25 | Cao | 4 | | Có bằng chứng kỹ thuật | Lý do định lượng |
| **S7-3-HD** | 7. Review | Sửa $\ge 1$ finding đã chấp nhận; commit riêng ghi ID finding; dẫn link commit vào bảng | — | S7-2-HD | Fix commit liên kết | Fixes 0.25 | Cao | 4 | | Có bằng chứng kỹ thuật | Commit chuẩn format |
| **S8-2** | 8. Report | Soạn mục Báo cáo: Chức năng, dữ liệu thật, loading/empty/error states kèm nút retry (kèm ảnh chụp màn hình) | — | S4-7 | Bản thảo gửi Thắng | Flows/Data/States | Cao | 4 | | Đã triển khai / chờ nghiệm thu | Minh họa đầy đủ |
| **S8-6** | 8. Report | Soạn Slide (3–4 trang): Đối chiếu Figma vs App song song kèm sai lệch; kết quả flows, dữ liệu và states | — | S8-2 | Slide gửi Thắng | Slides 1.0 | Cao | 4 | | Đã triển khai / chờ nghiệm thu | Trực quan, rõ ràng |
| **S8-11** | 8. Report | Quay video: Trình diễn 3 user flows Lab 2 gồm cả error paths (thực hiện theo thứ tự trong test plan) | — | S6-1 | Đoạn video clip gửi Thắng | Video 1.0 | Cao | 4 | | Chưa đủ điều kiện | Thao tác mượt mà |
| **S8-17-HD** | 8. Report | Cập nhật worklog cá nhân `docs/worklog-hoang.md` để đối chiếu lịch sử Git | — | S8-16 | `docs/worklog-hoang.md` | Mục 11 | Thấp | 4 | | Có bằng chứng kỹ thuật | Tùy chọn kiểm tra |
| **S9-5-HD** | 9. Nộp bài | Luyện vấn đáp 5 phút: chạy 1 test ARTEMIS, đổi 1 giá trị Remote Config live, giải thích 1 ViewModel và 1 review | — | S8-16 | Sẵn sàng vấn đáp | Mục 11 | Cao | 4 | | Chưa đủ điều kiện | Nắm vững code |
