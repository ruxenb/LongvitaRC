# Design Traceability Matrix — Longvita (Lab 3)

> **Tài liệu:** Truy vết thiết kế từ Lab 2 (Figma & `screen-spec.md`) sang Flutter App.  
> **Người phụ trách:** Thắng VLQ (Lead) & Hoàng DV  
> **Giai đoạn:** Stage 1 — Plan (Bắt buộc hoàn thành trước khi triển khai tính năng theo Mục 4 Handout).

---

## 1. Ma Trận Ánh Xạ Màn Hình (Screen Traceability Matrix)

Ứng dụng kế thừa 10 màn hình chuẩn từ Lab 2 (`S01`–`S10`) và bổ sung 2 màn hình phục vụ yêu cầu Lab 3 (`Sign-in` và `Profile` kèm Firebase Demo Area):

| Screen ID | Tên màn hình Lab 2 | Flutter Route | Widget chính | Nguồn dữ liệu (Data Source) | Trạng thái triển khai |
|:---:|:---|:---|:---|:---|:---:|
| **AUTH** | Sign-In *(bổ sung Lab 3)* | `/sign-in` | `SignInScreen` | Firebase Auth (Google Sign-In) | ⏳ Sẵn sàng code |
| **S01** | Home Dashboard | `/home` | `HomeScreen` | Firestore / Remote Config / Local Cache | ⏳ Sẵn sàng code |
| **S02** | Food Preferences | `/preferences` | `PreferencesScreen` | Local State / User Profile Firestore | ⏳ Sẵn sàng code |
| **S03** | Create Meal Plan | `/create-plan` | `CreatePlanScreen` | REST API / Firestore Calculation Engine | ⏳ Sẵn sàng code |
| **S04** | Weekly Meal Plan | `/weekly-plan` | `WeeklyPlanScreen` | Firestore `meal_plans` / REST API | ⏳ Sẵn sàng code |
| **S05** | Recipe Details | `/recipe-details` | `RecipeDetailsScreen` | Firestore `recipes` / Book Database | ⏳ Sẵn sàng code |
| **S06** | Meal Alternatives | `/alternatives` | `MealAlternativesScreen` | Firestore `recipes` (lọc theo đạm & calo) | ⏳ Sẵn sàng code |
| **S07** | Ingredient Summary | `/ingredient-summary` | `IngredientSummaryScreen` | MealPlan Data Aggregator | ⏳ Sẵn sàng code |
| **S08** | Shopping List | `/shopping-list` | `ShoppingListScreen` | Local Persistent Storage / Firestore | ⏳ Sẵn sàng code |
| **S09** | Book Knowledge | `/book-knowledge` | `BookKnowledgeScreen` | Trích dẫn sách *La dieta della longevità* | ⏳ Sẵn sàng code |
| **S10** | Saved Plans | `/saved-plans` | `SavedPlansScreen` | Firestore `meal_plans` (per-user) | ⏳ Sẵn sàng code |
| **PROF** | Profile & Firebase Demo *(bổ sung)* | `/profile` | `ProfileScreen` | Firebase Auth, Storage, FCM, RC, Crashlytics | ⏳ Sẵn sàng code |

---

## 2. Ma Trận Ánh Xạ Luồng Người Dùng (User Flows Traceability)

| Flow ID | Tên Flow | Chuỗi màn hình | Luồng thay thế / Error & Recovery Paths | Người phụ trách |
|:---:|:---|:---|:---|:---:|
| **Flow 1** | Lập và lưu thực đơn 7 ngày | `S01` $\to$ `S02` $\to$ `S03` $\to$ `S04` $\to$ `S10` | - `S03 Generation Error`: hiển thị nút `Retry` hoặc quay về `S02` chỉnh lại sở thích.<br/>- `S04 Save Error`: lưu ngoại tuyến / thông báo thử lại không làm mất thực đơn đang xem. | Hoàng |
| **Flow 2** | Tổng hợp nguyên liệu và đi chợ | `S04` $\to$ `S07` $\to$ `S08` | - `S07 Edit Quantity`: overlay dialog có validation chặn số $\le 0$.<br/>- `S07 Delete Ingredient`: `SnackBar` hoàn tác (Undo).<br/>- `S07 Empty State`: thông báo chưa có nguyên liệu kèm nút tạo lại.<br/>- `S08 Checklist`: khôi phục trạng thái check/uncheck khi mở lại. | Hoàng |
| **Flow 3** | Tra cứu sách và thay đổi món ăn | `S04` $\to$ `S05` $\to$ `S06` / `S09` $\to$ `S04` | - `S06 No Alternative`: cho phép chuyển sang `S02` để nới lỏng bộ lọc.<br/>- `S06 Update Error`: giữ nguyên món ăn cũ, không làm lỗi giao diện tuần.<br/>- `S09 Book Knowledge`: xem trích dẫn nguồn sách của TS. Valter Longo. | Hoàng |
| **Auth Flow** | Xác thực & Phân quyền | `/sign-in` $\leftrightarrow$ `/home` | - Người dùng hủy Google account picker: hiển thị `SnackBar` thông báo, không crash.<br/>- Mất mạng: hiển thị thông báo lỗi mạng kèm nút đăng nhập lại. | Charlie |

---

## 3. Ma Trận Ánh Xạ Thành Phần Giao Diện (Components-to-Widgets)

| STT | Component Figma (Lab 2) | Flutter Widget Tương Ứng | Variants & Trạng Thái Bắt Buộc | Semantics & A11y |
|:---:|:---|:---|:---|:---|
| 1 | Button | `AppButton` | Primary, Secondary, Outlined; Default, Pressed, Disabled, Loading | `button: true`, min target $48 \times 48$ dp |
| 2 | Text Field | `AppTextField` | Default, Focused, Filled, Error, Disabled | `textField: true`, nhãn lỗi bằng text rõ ràng |
| 3 | Card Container | `AppCard` | Default, Pressed (với `InkWell`), Elevation 1 / 2 | BoxShadow `#2F3B2A`, bo góc 16 dp |
| 4 | Bottom Navigation | `AppBottomNav` | Selected, Unselected cho 4 tab chính | Nhãn rõ ràng, icon $\ge 24$ dp, thanh cao 80 dp |
| 5 | App Bar | `AppBarWidget` | Standard, Back button, With actions | Chiều cao 64 dp, title $\ge 20$ sp |
| 6 | Dialog Overlay | `AppDialog` | Confirmation Dialog, Edit Quantity Dialog (Form validation) | Modal chặn click nhầm, cuộn khi màn hình nhỏ |
| 7 | Loading State | `LoadingView` | Center Spinner, thông điệp tiến trình, chống bấm lặp | `liveRegion: true`, nhãn mô tả cho Screen Reader |
| 8 | Empty State | `EmptyStateView` | Minh họa icon tròn, tiêu đề, mô tả, nút CTA | Nhãn mô tả đầy đủ ngữ nghĩa |
| 9 | Error State | `ErrorStateView` | Icon cảnh báo, nguyên nhân dễ hiểu, nút Thử lại (Retry) | Không để màn hình trắng / spinner quay vô hạn |

---

## 4. Nhật Ký Ghi Nhận Sai Lệch Thiết Kế (Design Deviation Log)

> **Quy định Handout Mục 3:** Mọi thay đổi hoặc sai lệch giữa Figma và Flutter App phải được ghi nhận tại đây kèm lý do kỹ thuật (ràng buộc nền tảng, accessibility, giới hạn API). Thay đổi chưa ghi nhận sẽ bị trừ điểm theo rubric.

| Deviation ID | Màn hình / Component | Thiết kế gốc trên Figma | Triển khai thực tế trên Flutter | Lý do kỹ thuật & Biện pháp xử lý | Người thực hiện |
|:---:|:---:|:---|:---|:---|:---:|
| **DEV-01** | Navigation & Routing | Lab 2 chỉ có 10 màn `S01`–`S10`, không có đăng nhập | Bổ sung màn hình `/sign-in` và `/profile` | Yêu cầu bắt buộc của Lab 3 (Firebase Authentication & Firebase Demo Area). Dùng chung 100% token màu và typography Lab 2. | Thắng & Hoàng |
| **DEV-02** | Nút bấm CTA (D08) | Figma Variable: `size/button/height = 52` | Đặt min-height = 56 dp cho Primary CTA | Đảm bảo diện tích chạm thực tế an toàn cho người cao tuổi (Persona Bác Hoàng 67 tuổi) và tuân thủ A11y touch target $\ge 48$ dp. | Charlie |
| **DEV-03** | Font chữ hiển thị | Local font files | Tích hợp qua package `google_fonts` (Newsreader, Quicksand, Fraunces) | Tối ưu hóa kích thước build apk và tải font chuẩn cross-platform, đảm bảo cỡ chữ luôn $\ge 14$ sp. | Charlie |
| **DEV-04** | Edit Ingredient | S07 thiết kế dạng dialog | `AppDialog.showEditIngredientQuantity` mở dạng Overlay | Phù hợp cơ chế Material 3 Dialog trong Flutter, có Form key và validation số dương trực tiếp. | Hoàng |
