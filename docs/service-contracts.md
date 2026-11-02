# Service Contracts & ViewModel Baseline — Longvita Lab 3

> **Task:** S2-1 — chốt service contracts và tên ViewModel  
> **Người phụ trách:** Thắng VLQ (Technical Architect)  
> **Trạng thái:** Đã chốt làm baseline kiến trúc; implementation đã merge vào `main` tại commit `ae35f07`.

## 1. Quyết định chung

- UI không gọi trực tiếp Firebase SDK, HTTP hoặc storage API.
- ViewModel nhận dependency bằng constructor; đăng ký dependency tập trung trong `lib/main.dart` bằng Provider.
- Model và service contract không phụ thuộc vào widget, route hoặc `BuildContext`.
- Lỗi SDK/network được chuyển thành trạng thái ứng dụng tại ViewModel (`loading`, `empty`, `error`, `success`).
- Các Firebase wrapper nhỏ được inject bằng constructor. Chỉ tạo interface riêng khi có nhiều implementation hoặc cần fake độc lập; tránh tạo interface rỗng chỉ để bọc SDK.

## 2. Service baseline

| Nhóm | Contract/Wrapper hiện hành | Trách nhiệm | Consumer chính |
|:---|:---|:---|:---|
| Auth | `IAuthService` / `AuthService` | Auth state, Google sign-in, sign-out, user profile | `AuthViewModel`, `ProfileViewModel` |
| Data | `IDataService` / `DataService` | Recipe, meal plan, announcement và nghiệp vụ tạo thực đơn | `MealPlanViewModel` |
| Report | `IReportService` / `ReportService` | Sinh PDF cục bộ, không phụ thuộc Firebase Storage | `ProfileViewModel` |
| Storage | `StorageService` | Upload báo cáo vào `reports/{uid}/...`, progress và download URL | `ProfileViewModel` |
| Messaging | `NotificationService` | Xin quyền, FCM foreground/background/opened-app | `ProfileViewModel` |
| Analytics | `AnalyticsService` | User ID và event theo `analytics-plan.md`, không ghi PII | Auth/MealPlan/Ingredient/Profile ViewModel |
| Crash | `CrashlyticsService` | User ID, custom keys, non-fatal và test crash | Các ViewModel tại error boundary |
| Remote Config | `RemoteConfigService` | Defaults, fetch/activate và fallback khi offline | `MealPlanViewModel`, `ProfileViewModel` |

## 3. ViewModel baseline

| ViewModel | Phạm vi | Dependency chính |
|:---|:---|:---|
| `AuthViewModel` | Phiên đăng nhập và auth state | Auth, Analytics, Crashlytics |
| `MealPlanViewModel` | Flow 1 và Flow 3, tạo/lưu/thay món | Data, Analytics, Crashlytics, Remote Config |
| `IngredientViewModel` | Flow 2, validation, Undo và shopping state | Analytics, Crashlytics |
| `ProfileViewModel` | Profile và Firebase Demo Area | Auth, Storage, Messaging, Report, Remote Config, Crashlytics, Analytics |

## 4. Điểm kiểm chứng trong code

- DI composition root: `lib/main.dart`.
- Explicit state model: `lib/models/view_state.dart`.
- Service contracts: `lib/services/i_auth_service.dart`, `i_data_service.dart`, `i_report_service.dart`.
- Firebase wrappers: `lib/firebase/`.
- ViewModels: `lib/viewmodels/`.
- Quy tắc phân tầng, sequence diagram và ánh xạ dependency: `docs/architecture.md`.

Mọi thay đổi contract sau baseline này phải cập nhật đồng thời implementation, consumer, `docs/architecture.md` và tài liệu này.
