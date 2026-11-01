# Architecture Document — Longvita (Lab 3)

> **Mô hình kiến trúc:** MVVM (Model - View - ViewModel) với Provider Dependency Injection  
> **Người phụ trách:** Thắng VLQ (Kiến trúc & Tích hợp)  
> **Nguyên tắc bất biến:** Phụ thuộc một chiều hướng xuống (`Dependencies point downwards only`); một tầng tuyệt đối không import ngược tầng phía trên nó.

---

## 1. Cấu Trúc Thư Mục (Folder Structure — 1 Dòng / Thư Mục)

```text
lib/
├── models/       # Chứa các Plain Dart Data Classes (User, MealPlan, Recipe, Ingredient, ViewState), dùng chung cho toàn bộ app
├── services/     # Chứa các Interfaces và Implementations gọi REST API, Local DB, sinh PDF báo cáo
├── firebase/     # Chứa các mã bọc dịch vụ Firebase (Auth, Cloud Storage, FCM, Remote Config, Analytics, Crashlytics)
├── viewmodels/   # Chứa các ViewModels quản lý trạng thái màn hình (ViewState), xử lý business logic và gọi Services
├── screens/      # Chứa các Màn hình giao diện (Views) lắng nghe State từ ViewModel, chỉ forward sự kiện người dùng
├── widgets/      # Chứa 9 Component dùng chung theo Design System Lab 2 (Button, TextField, Card, Dialog, Loading...)
├── theme/        # Chứa toàn bộ Design Tokens: ColorScheme, TextTheme, AppSpacing, AppRadius, AppElevation
└── utils/        # Chứa các hàm tiện ích thuần túy (date formatting, validators, constants)
```

---

## 2. Sơ Đồ Phân Tầng Kiến Trúc (Mermaid Layer Diagram)

```mermaid
flowchart TD
    subgraph ViewLayer["TẦNG VIEW (screens/, widgets/)"]
        V1["Screens (Home, Plan, Profile, etc.)"]
        V2["Reusable Widgets (AppButton, AppCard, etc.)"]
    end

    subgraph ViewModelLayer["TẦNG VIEWMODEL (viewmodels/) — Provider"]
        VM1["AuthViewModel"]
        VM2["MealPlanViewModel"]
        VM3["IngredientViewModel"]
        VM4["ProfileViewModel"]
        ST["Explicit ViewState<T> (Loading, Empty, Error, Success)"]
    end

    subgraph ModelLayer["TẦNG MODEL (models/)"]
        M1["UserModel"]
        M2["MealPlan & DailyMeal"]
        M3["Recipe"]
        M4["Ingredient"]
    end

    subgraph ServiceLayer["TẦNG SERVICE & REPOSITORY (services/, firebase/)"]
        S1["AuthService"]
        S2["DataService (Firestore / REST API)"]
        S3["StorageService"]
        S4["NotificationService (FCM)"]
        S5["AnalyticsService"]
        S6["CrashlyticsService"]
        S7["RemoteConfigService"]
        S8["ReportService (PDF Generator)"]
    end

    subgraph BackendLayer["TẦNG DỮ LIỆU NGOÀI (External Services)"]
        B1["Cloud Firestore / REST API"]
        B2["Firebase Authentication (Google)"]
        B3["Firebase Cloud Storage"]
        B4["Firebase Cloud Messaging (FCM)"]
        B5["Firebase Analytics, Crashlytics, Remote Config"]
    end

    ViewLayer -->|"User Events (Tap, Input)"| ViewModelLayer
    ViewModelLayer -->|"State Changes (notifyListeners)"| ViewLayer
    ViewModelLayer -->|"Calls Async Methods"| ServiceLayer
    ViewModelLayer -.->|"Holds / Maps"| ModelLayer
    ServiceLayer -.->|"Returns Plain Models"| ViewModelLayer
    ServiceLayer -->|"SDK / HTTP Calls"| BackendLayer
    BackendLayer -->|"Raw JSON / Stream"| ServiceLayer
```

---

## 3. Quy Tắc Kiến Trúc Bắt Buộc (Architecture Rules)

1. **Tuyệt đối không gọi SDK trực tiếp trong Widget:**  
   Không có bất kỳ widget nào được gọi `http`, `FirebaseAuth.instance`, `FirebaseAnalytics.instance`, `FirebaseFirestore.instance`... Mọi tương tác ra bên ngoài bắt buộc phải đi qua Service Interface.
2. **Business Logic tách khỏi hàm `build()`:**  
   Các logic tính toán (tính gram đạm theo cân nặng $0.8 \times kg$, đếm số bữa cá $\le 2-3$ bữa/tuần, lọc món thay thế, kiểm tra form nhập số âm) bắt buộc nằm trong ViewModel hoặc Service, tuyệt đối không viết trong hàm `build()`.
3. **Explicit State Model cho mọi màn hình nạp dữ liệu:**  
   Mỗi màn hình có ViewModel sở hữu trạng thái rõ ràng qua class `ViewState<T>`:
   - `ViewStateIdle<T>`: Chưa bắt đầu tải
   - `ViewStateLoading<T>`: Đang xử lý (kèm nhãn thông điệp)
   - `ViewStateSuccess<T>`: Dữ liệu tải thành công
   - `ViewStateEmpty<T>`: Tải thành công nhưng không có dữ liệu
   - `ViewStateError<T>`: Xảy ra lỗi (có message thân thiện và nút Thử lại - Retry)
4. **Dependency Injection qua Provider:**  
   Mọi Service được đăng ký tại `MultiProvider` ở `main.dart` dưới dạng Interface. ViewModel nhận Service qua Constructor Injection, giúp kiểm thử dễ dàng bằng Fake/Mock Service.

---

## 4. Sơ Đồ Tuần Tự (Sequence Diagram — Luồng Lập & Lưu Thực Đơn)

```mermaid
sequenceDiagram
    autonumber
    actor User as Người dùng (Minh Anh)
    participant S03 as CreatePlanScreen (View)
    participant VM as MealPlanViewModel
    participant DataSvc as DataService (Service)
    participant Analytics as AnalyticsService
    participant Backend as Firestore / REST API

    User->>S03: Bấm nút "Tạo thực đơn" (CTA)
    S03->>VM: generatePlan()
    VM->>VM: _currentPlanState = ViewStateLoading()
    VM-->>S03: notifyListeners() (Hiển thị LoadingView)

    VM->>DataSvc: generateMealPlan(age, weight, meals, window)
    DataSvc->>Backend: HTTP POST / Firestore Query (Fetch recipes)
    Backend-->>DataSvc: Raw Meal Data
    DataSvc-->>VM: Trả về đối tượng MealPlan (Model)

    VM->>Analytics: logEvent('generate_meal_plan', {target_age, fish_count})
    VM->>VM: _currentPlanState = ViewStateSuccess(mealPlan)
    VM-->>S03: notifyListeners() (Chuyển sang màn hình S04 Weekly Plan)

    User->>S03: Bấm nút "Lưu thực đơn" trên S04
    S03->>VM: saveActivePlan()
    VM->>DataSvc: saveMealPlan(plan)
    DataSvc->>Backend: Firestore set doc reports/uid/plans
    Backend-->>DataSvc: Write Success
    DataSvc-->>VM: Success Confirmation
    VM->>Analytics: logEvent('save_meal_plan', {plan_id})
    VM-->>S03: Hiển thị SnackBar thành công & cập nhật S10
```

---

## 5. Bảng Ánh Xạ ViewModels và Các Services Sử Dụng

| Tên ViewModel | File | Trách nhiệm chính | Các Services phụ thuộc (Injected via Constructor) |
|:---|:---|:---|:---|
| **`AuthViewModel`** | `lib/viewmodels/auth_viewmodel.dart` | Quản lý đăng nhập Google, trạng thái phiên làm việc, xóa dữ liệu khi đăng xuất, cập nhật user ID | `AuthService`, `AnalyticsService`, `CrashlyticsService` |
| **`MealPlanViewModel`** | `lib/viewmodels/meal_plan_viewmodel.dart` | Quản lý Flow 1 & Flow 3: thiết lập sở thích (S02), sinh thực đơn 7 ngày (S03-S04), lưu kế hoạch (S10), tra cứu món thay thế (S06) | `DataService`, `AnalyticsService`, `CrashlyticsService`, `RemoteConfigService` |
| **`IngredientViewModel`** | `lib/viewmodels/ingredient_viewmodel.dart` | Quản lý Flow 2: tổng hợp nguyên liệu (S07), chỉnh sửa số lượng có validation, hoàn tác Undo, đồng bộ trạng thái mua sắm (S08) | `AnalyticsService`, `CrashlyticsService` |
| **`ProfileViewModel`** | `lib/viewmodels/profile_viewmodel.dart` | Quản lý màn Profile & Firebase Demo Area: danh sách thông báo FCM, sinh PDF và upload Storage có progress, đọc/đổi Remote Config, kích hoạt lỗi Crashlytics | `StorageService`, `NotificationService`, `ReportService`, `RemoteConfigService`, `CrashlyticsService`, `AnalyticsService` |
