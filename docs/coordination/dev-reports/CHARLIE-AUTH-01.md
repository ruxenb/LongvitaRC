# CHARLIE-AUTH-01 — Toolchain, Firebase bootstrap, Auth và session

**Trạng thái đề nghị: Ready for PM review** cho phần code, test local, build Android và luồng đăng nhập thật với SHA của máy Charlie (mục 2.1). Còn thiếu SHA và lời mời cho ba thành viên, cùng các mục ở mục 6. Bản sửa AUD-11 đã qua test emulator và **đã publish** theo duyệt của Charlie, nhưng Hoàng/Thắng chưa review (mục 2.2). Chưa Accepted. Đã push nhánh, chưa có PR.

| Mục | Giá trị |
|---|---|
| Task chính | S0-3-CM, S0-4 (một phần), S3-1 (phần code), S3-3, S3-4, S3-5 |
| Hỗ trợ | S2-1 (contract Auth), S3-6 (AuthGate). S3-9 đã có bằng chứng; S3-2 mới có SHA của máy Charlie; S3-7 chưa thực hiện |
| Ngày | 02/11/2026 |
| Nhánh | `feature/charlie-auth-01`, tạo từ `feature/charlie-ui-01` (= `ae35f07` cộng UI-01). Đã push, chưa có PR, chưa merge `origin/main` |
| Tách khỏi UI-01 | Trước khi sửa đã chụp snapshot toàn bộ `lib/ test/ android/ pubspec.* firebase/ e2e_test/` của UI-01. Diff riêng của gói này: `evidence/auth/auth01-vs-ui01.diff` |
| Thay đổi của người khác đã giữ nguyên | Docs của Codex (`README.md`, `docs/*`, `docs/coordination/*`, `AGENTS.md`, `CLAUDE.md`) và toàn bộ UI-01 (chỉ thêm `container: true` ở mục 4.3) |

## 1. S0-3-CM — Toolchain thực tế (máy Charlie)

| Thành phần | Phiên bản / trạng thái |
|---|---|
| Flutter / Dart | 3.47.6 stable / 3.13.5 (`flutter doctor`: No issues found) |
| Android SDK | platform android-36, build-tools 36.0.0; emulator 37.2.13; licences đã accept |
| JDK | 21.0.12 |
| Gradle / AGP / Kotlin | Gradle 9.3.1 (wrapper), AGP 9.1.0, Kotlin plugin 2.4.0 |
| Packages (theo lockfile) | firebase_core 3.15.2, firebase_auth 5.7.0, google_sign_in 6.3.0, cloud_firestore 5.6.12, firebase_messaging 15.2.10. **Không nâng/hạ package nào**; `pubspec.lock` không đổi |
| FlutterFire CLI / Firebase CLI | **Chưa cài** (`which flutterfire`, `which firebase` không thấy) |
| Firebase MCP | Chưa đăng nhập (`Authenticated User: <NONE>`, chưa có project) |
| Thiết bị | Không có máy thật. Có sẵn AVD `LocalMate_Pixel` (API 35, 1080×2400, 420dpi) dùng với `-gpu swiftshader_indirect`. AVD `LocalMate_API_35` tắt GPU nên cho màn hình đen, không dùng |

## 2. S0-4 / S3-1 / S3-2 — Project, app ID, config và SHA

- **Trạng thái ban đầu của repo (đã xử lý một phần ở mục 2.1):** không có `google-services.json`, `firebase_options.dart`, `firebase.json` hay `.firebaserc`; Gradle chưa áp plugin `google-services`/Crashlytics.
- **App ID (DEC-03): đã chốt `vn.edu.fpt.longvita`** (Charlie quyết ngày 02/11/2026, khớp `e2e_test/conftest.py` và lệnh DebugView trong `docs/analytics-plan.md`).
  - Đã đổi `namespace` và `applicationId` trong `android/app/build.gradle.kts`. `MainActivity.kt` chuyển sang `android/app/src/main/kotlin/vn/edu/fpt/longvita/` với `package vn.edu.fpt.longvita`.
  - Kiểm chứng: `aapt dump badging` cho `package: name='vn.edu.fpt.longvita'`, `launchable-activity: vn.edu.fpt.longvita.MainActivity`.
  - Cài và mở trên emulator thành công (`android/startup-not-configured-appid.png`); log build `evidence/auth/build-apk-debug-appid.log`.
  - Các docs điều phối (AUD-03 trong file phân tích, QA plan mục 2) vẫn mô tả trạng thái cũ; Codex cập nhật.
- **SHA debug keystore máy Charlie** (`~/.android/debug.keystore`, alias `androiddebugkey`):
  - SHA-1 `2B:AA:67:BC:4F:6B:FD:1D:AB:3E:BF:C5:E5:57:A9:BB:1E:D0:35:EC`
  - SHA-256 `6B:9C:C4:19:3A:F8:6F:42:71:3B:6C:A2:6A:0E:F8:34:16:1A:E5:78:FD:EB:76:5A:1B:D7:0F:A4:64:69:A6:E8`
  - Đây là fingerprint công khai của chứng chỉ, không phải bí mật. Ba thành viên còn lại cần gửi SHA của máy mình.
- **Build Android:** `flutter build apk --debug` **thành công** với AGP 9.1 / Kotlin 2.4 và các plugin Firebase hiện có:
  - baseline UI-01: 285,6 s, log `evidence/auth/build-apk-debug-baseline.log`;
  - sau AUTH-01: 21,8 s, log `evidence/auth/build-apk-debug-auth01.log`.
  - Cảnh báo cần theo dõi: `firebase_analytics` và `firebase_remote_config` vẫn tự áp Kotlin Gradle Plugin (chưa chuyển sang Built-in Kotlin của AGP 9). Build hiện vẫn qua; không tự đổi version.
  - **Chưa kiểm chứng:** plugin Crashlytics trên AGP 9. Plugin `google-services` đã kiểm chứng ở mục 2.1.
- **DEC-01 (Storage/Blaze):** không chặn Auth. Không mở billing.

## 2.1 Kiểm chứng cloud thật (02/11/2026, project `longvita-8da7e`)

Project do Charlie tạo trên Console, gói Spark, không mở billing.

| Hạng mục | Kết quả |
|---|---|
| App Android | `vn.edu.fpt.longvita`, đã đăng ký kèm SHA-1 và SHA-256 debug của máy Charlie |
| Authentication | Provider Google đã bật |
| Cloud Firestore | `(default)`, `asia-southeast1`, tạo ở production mode |
| `android/app/google-services.json` | Có OAuth client Android (khớp SHA-1 debug) và web client |
| Plugin `com.google.gms.google-services` 4.5.0 | Build APK debug thành công trên AGP 9.1, sinh được `default_web_client_id` |
| `firebase/firestore.rules` | Lần đầu publish bản gốc trong commit `ae35f07` (`6e5f4ea3…2e15ed`, còn AUD-11) để test Auth. Hiện đã thay bằng bản sửa ở mục 2.2 |

Chạy trên AVD `LocalMate_API_35` (hiển thị 320×640), tài khoản Google của Charlie do Charlie tự nhập:

| Luồng | Kết quả thực tế |
|---|---|
| Firebase bootstrap | Log có `FirebaseApp initialization successful`, vào màn Sign-in |
| Hủy khi chọn tài khoản | Về Sign-in, hiện thông báo hủy, không crash |
| Đăng nhập lần đầu | Vào Home, hiện `ROLE: USER`. Firestore có `users/{uid}` với `role: "user"` |
| Tắt hẳn rồi mở lại app | Vẫn ở Home, giữ phiên |
| Đăng xuất | Về Sign-in |
| Đăng nhập lại | Có account picker, vào Home. `createdAt` giữ nguyên, document không bị ghi đè |

Bằng chứng S3-9: `evidence/auth/S3-9-20261102/`, xem `README.md` trong thư mục. Ảnh từng bước: `evidence/ui/CHARLIE-AUTH-01/run-20261102-02/android/`. XML và logcat thô chỉ giữ trên máy Charlie, không commit.

Ghi chú:
- Các file bằng chứng có email và UID thật của Charlie. Cần cân nhắc trước khi đưa lên repo chung.
- Lần chạy đầu trên AVD này cho ảnh chụp đen, đúng như ghi nhận ở mục 1. Sau khi cold boot, ảnh chụp bình thường; chưa xác định nguyên nhân chính xác. Bộ ảnh này độ phân giải thấp, chưa phải bằng chứng theo viewport 1080×2400 của `LocalMate_Pixel`.
- `createdAt` đang lưu chuỗi giờ local không có múi giờ (`2026-11-02T14:12:07.034514`). Xem A7 ở mục 8.

## 2.2 AUD-11 — Sửa `firestore.rules`

AUD-11 do Hoàng/Thắng làm chính, Charlie phối hợp. Charlie yêu cầu thực hiện bản sửa, báo cho hai bạn và duyệt publish vì nhóm chưa bắt đầu phần này. **Hoàng/Thắng chưa review**; nếu hai bạn đổi quyết định B1–B5 thì sửa rules, chạy lại test và publish lại.

**Đã publish lên `longvita-8da7e`.** SHA-256 trên Console sau khi tải lại khớp file repo: `6c29bd77…81d403`.

**Đã đổi trong `firebase/firestore.rules`:**

| Collection | Quy tắc mới |
|---|---|
| `users` | Admin chỉ đổi `role` của người khác, không đổi được role của chính mình và không sửa trường khác. Owner chỉ sửa `displayName`, `photoUrl` |
| `meal_plans` (owner) | Chỉ tạo với `status: 'draft'`, `reviewerReason` rỗng. Khi còn `draft`: sửa nội dung hoặc chuyển `submitted`. Khóa `uid`, `createdAt`, `reviewerReason` |
| `meal_plans` (staff/admin) | Chỉ `submitted` → `approved`/`rejected`, chỉ đổi `status`, `reviewerReason`. Từ chối phải có lý do |
| `recipes` | Staff/admin ghi phải đúng schema |
| `announcements` | Staff/admin ghi phải đúng schema, `authorRole` phải trùng role thật. Khi sửa chỉ đổi `title`, `content` |
| Tất cả | Chỉ nhận đúng các key và kiểu theo `toMap()` trong `lib/models/` |

**Kiểm chứng trên emulator** (`firebase/tests/firestore.rules.test.js`, project `demo-longvita`, không đụng project thật). Mỗi collection có ca allowed và denied cho anonymous, user, staff, admin.

| Rules | Kết quả | Log |
|---|---|---|
| Bản mới | 41 tests: **41 pass, 0 fail** | `evidence/rules/AUD-11-20261102/new-rules-run.txt` |
| Bản cũ (SHA `6e5f4ea3…2e15ed`) | 41 tests: 25 pass, **16 fail**, gồm cả các ca AUD-11 | `evidence/rules/AUD-11-20261102/old-rules-run.txt` |

Cách chạy, từ thư mục `firebase/`: `npm ci`, rồi `npm run test:rules`. Cần Java. Trên Windows, tiến trình Java của emulator có thể còn sót sau khi chạy và gây lỗi `port taken` ở lần sau; khi đó dừng tiến trình `cloud-firestore-emulator` rồi chạy lại.

**Thêm mới:** `firebase/firebase.json`, `firebase/package.json`, `firebase/package-lock.json` với devDependencies `firebase-tools`, `@firebase/rules-unit-testing`, `firebase`, chỉ dùng để chạy test rules, không vào app. `.gitignore` bỏ qua `firebase/node_modules/`, `analysis_options.yaml` loại thư mục này khỏi `flutter analyze`.

**Chạy app thật với rules mới** (AVD `LocalMate_API_35`, ảnh ở `evidence/rules/AUD-11-20261102/android/`; XML và logcat chỉ giữ trên máy Charlie):

| Luồng | Kết quả thực tế |
|---|---|
| Mở lại app đã đăng nhập, đọc `users/{uid}` | Vào Dashboard, hiện `ROLE: USER` |
| Bấm "Lưu vào Firestore" | Tạo `meal_plans/NUtQFguy7pPjmM4jlqtc`, `status: "draft"`, đúng `uid`. Log không có `PERMISSION_DENIED` |

**Chưa kiểm chứng trên project thật:** tạo `users/{uid}` lần đầu với rules mới (đã có ca test trên emulator), gửi plan (`submitted`) vì màn hiện tại chưa có nút này, các luồng staff/admin vì chưa có tài khoản role đó.

**Dữ liệu test đang còn trên project:** document `users` của Charlie và 1 `meal_plans` nháp ở trên.

**Cần Hoàng/Thắng chốt** (quyết định tạm của bản sửa, xem B1–B5 ở mục 8).

## 3. Thiết kế Auth và session (S3-3, S3-4, S3-5)

### 3.1 Contract mới `IAuthService` (S2-1 — đổi interface, cần Thắng duyệt)

```dart
Stream<String?> get authUidChanges;      // uid Firebase hoặc null
String? get currentUid;
UserModel? get currentUser;              // profile đã load cho currentUid
Future<AuthSignInResult> signInWithGoogle(); // Succeeded(uid) | Cancelled | Failed(AuthFailure)
Future<UserModel> loadProfile(String uid);   // throw AuthFailure, không trả null
Future<void> signOut();                  // không xóa dữ liệu cloud
```

So với bản cũ: bỏ `authStateChanges: Stream<UserModel?>` (stream cũ nuốt lỗi profile thành `null`) và `fetchUserProfile(): UserModel?`.

`AuthFailureKind` gồm:

| Kind | Nguồn lỗi |
|---|---|
| `cancelled` | Người dùng đóng account picker |
| `network` | Mất mạng (Google, Firebase Auth hoặc Firestore) |
| `configuration` | ApiException 10/12500: SHA, package hoặc OAuth sai; provider chưa bật |
| `credential` | Tài khoản bị khóa, token không hợp lệ… |
| `profileRead` / `profileWrite` | Đọc hoặc tạo `users/{uid}` thất bại |
| `unknown` | Còn lại |

Mapper thuần nằm ở `lib/services/auth_error_mapper.dart`.

### 3.2 `AuthState` (sealed) do `AuthViewModel` sở hữu

| State | Router hiển thị |
|---|---|
| `AuthInitializing` | Loading "Đang kiểm tra phiên đăng nhập" |
| `AuthSignedOut(notice?)` | SignIn; notice cancel thì báo thông tin, lỗi thì báo lỗi |
| `AuthSigningIn` | SignIn, nút loading, không nhận bấm lặp |
| `AuthLoadingProfile(uid)` | Loading "Đang tải hồ sơ của bạn" |
| `AuthProfileError(uid, failure)` | **AuthRecoveryScreen**: Thử lại / Đăng xuất. Firebase đã đăng nhập nhưng nội dung bảo vệ vẫn đóng |
| `AuthSignedIn(user)` | HomeScreen |

Các yêu cầu đã đáp ứng:

- **Hủy, lỗi credential, lỗi profile và đăng xuất là bốn trạng thái khác nhau.** Lỗi profile không bao giờ bị báo thành "hủy đăng nhập".
- **Không kẹt ở màn Sign-in:** đã đăng nhập Firebase nhưng profile lỗi thì vào màn khôi phục.
- **Chống bấm lặp:** khi picker đang mở, bấm thêm không gọi lại; đăng xuất cũng có guard. Luồng "kết quả trả về" và "stream báo uid" dùng chung một lần tải profile.
- **Phiên được phục hồi:** stream có uid lúc mở app thì tải profile, không cần đăng nhập lại.
- Sign-in thành công thì log `login`; lỗi thì ghi Crashlytics non-fatal. Hủy không bị coi là lỗi.

### 3.3 Logout và cách ly phiên (S3-5)

- Interface mới `SessionScoped { onSessionStarted(user); clearSession(); }` ở `lib/viewmodels/session_scoped.dart`. `AuthViewModel` gọi `clearSession()` cho mọi participant khi:
  - người dùng đăng xuất;
  - stream báo `null` (token bị thu hồi);
  - uid đổi từ A sang B.
- Khi kết thúc phiên còn xóa định danh: `analytics.setUserId(null)`, `crashlytics.setUserId('')`, custom key `user_role=signed_out`.
- **Không xóa dữ liệu cloud.** Nếu SDK sign-out lỗi, app vẫn xóa state cục bộ.
- Participants:
  - `ProfileViewModel` (Charlie): xóa URL export, progress, state và lịch sử notification trong RAM.
  - `MealPlanViewModel` và `IngredientViewModel` (**Hoàng**): chỉ **thêm** `clearSession()` đưa state về Idle và xóa activePlan, danh sách, Undo buffer. Không đổi logic khác. **Cần Hoàng xác nhận.**
- **Chặn Back vào nội dung bảo vệ (hỗ trợ S3-6):** `AuthGate` (của Thắng) thêm một bước — khi rời `AuthSignedIn` thì `popUntil(isFirst)`, nên route đã push không còn trên stack. Ngoài ra chỉ đổi phần `switch` sang state mới. Không dựng router thứ hai. **Cần Thắng xác nhận.**

### 3.4 Firebase bootstrap (S3-1)

- `lib/firebase/firebase_bootstrap.dart` trả về `BootstrapReady` hoặc `BootstrapFailed(code)`; `code = not-configured` khi build thiếu cấu hình.
- `lib/screens/startup_gate.dart` hiển thị loading, sau đó vào app hoặc màn lỗi "Không thể khởi động ứng dụng" có nút Thử lại.
- **Service và ViewModel chỉ được tạo sau khi bootstrap thành công** (`buildAppScope()` trong `main.dart`). Hết tình trạng "catch lỗi rồi vẫn tạo `FirebaseAuth.instance`" như trước.
- `main.dart` (file DI của Thắng) đổi cấu trúc nhưng **giữ nguyên danh sách provider**. Khác biệt: ViewModel tạo trước rồi cấp bằng `.value` để `AuthViewModel` dọn được phiên của chúng.

### 3.5 Quyền thông báo và TC-01

`notification.initialize()` không còn chạy lúc khởi động mà chuyển sang `ProfileViewModel.onSessionStarted` (sau đăng nhập, mỗi process một lần). Màn đầu tiên người dùng và ARTEMIS TC-01 gặp là Sign-in, không còn hộp thoại Android 13. Đã xác nhận trên emulator: `POST_NOTIFICATIONS: granted=false` và không có prompt nào lúc mở app.

Phần còn lại của gói FCM (background, terminated, history bền, route) **không** làm trong gói này.

### 3.6 UI Sign-in và màn khôi phục

Không có frame Figma cho hai màn này (S1-5). Theo quy ước Figma đóng băng, chúng được dựng thẳng trong code bằng common widgets của UI-01:

- **Sign-in:** brand, icon spa, Heading/L, Body, notice và một nút `AppButton` primary.
  - Notice "hủy": nền bg/selected + icon info.
  - Notice "lỗi": viền feedback/error + icon error kèm chữ, không chỉ dựa vào màu.
  - Nút: loading "Đang mở tài khoản Google…"; sau lỗi đổi nhãn thành "Thử lại với Google"; có nút ẩn notice.
- **Màn khôi phục:** `AppTopBar` + `ErrorView` với Thử lại / Đăng xuất.
- **Ngôn ngữ:** tiếng Việt, theo chuỗi sẵn có của app và DEC-05 đang mở. Mọi chuỗi gom ở `lib/screens/auth_messages.dart`.
- **Không dùng logo Google** vì không có asset được duyệt.

## 4. File thay đổi (chỉ phần AUTH-01)

### 4.1 Mới

- `lib/models/auth_state.dart`
- `lib/services/auth_error_mapper.dart`
- `lib/viewmodels/session_scoped.dart`
- `lib/firebase/firebase_bootstrap.dart`
- `lib/screens/startup_gate.dart`, `lib/screens/auth_recovery_screen.dart`, `lib/screens/auth_messages.dart`
- Test: `test/auth/auth_fakes.dart`, `auth_viewmodel_test.dart`, `auth_error_mapper_test.dart`, `session_isolation_test.dart`, `auth_screens_test.dart`, `firebase_bootstrap_test.dart`

### 4.2 Sửa

- Của Charlie: `lib/services/i_auth_service.dart`, `lib/services/auth_service.dart`, `lib/viewmodels/auth_viewmodel.dart`, `lib/screens/sign_in_screen.dart`, `lib/viewmodels/profile_viewmodel.dart`, `lib/firebase/notification_service.dart` (thêm guard init một lần và `clearHistory()`).
- Của Thắng: `lib/main.dart`, `lib/screens/auth_gate.dart`.
- Của Hoàng (chỉ thêm `clearSession`): `lib/viewmodels/meal_plan_viewmodel.dart`, `lib/viewmodels/ingredient_viewmodel.dart`.
- Android, app ID (S0-4/S3-1): `android/app/build.gradle.kts`, `MainActivity.kt` chuyển sang `android/app/src/main/kotlin/vn/edu/fpt/longvita/`.

### 4.3 Sửa lỗi phát hiện trên widget UI-01

Khi dump cây accessibility trên emulator, toàn bộ `ErrorView` bị gộp thành **một node có thể bấm**, gồm cả tiêu đề, mô tả và "Thử lại". TalkBack và ARTEMIS vì thế không nhắm riêng được nút.

- **Sửa:** thêm `container: true` vào Semantics của `AppButton`, `AppIconButton`, `AppCard` (khi bấm được), nav item, `AppCheckboxRow`, `AppDaySelector`, nút Undo của snackbar, `AppBadge`, cùng `LoadingView`/`ErrorView`.
- **Kết quả sau sửa:** panel là node thông tin không bấm được; "Thử lại" là node riêng `clickable=true`, bounds `[105,1366][975,1513]` (≈331×56dp).
- `test/qa/qa_support.dart` thêm biến `QA_TASK` để mỗi gói ghi evidence vào thư mục riêng.

## 5. Kiểm tra thực tế

| Lệnh | Kết quả | Log |
|---|---|---|
| `flutter analyze --no-pub` | `No issues found!` | `evidence/auth/flutter-analyze.log` |
| `flutter test --no-pub` (toàn repo, `QA_TASK=CHARLIE-AUTH-01`) | `+69: All tests passed!` (44 test auth/bootstrap + 24 test QA UI-01 + 1 test AppButton cũ; UI-01 không regression) | `evidence/auth/flutter-test-all.log` |
| `flutter build apk --debug` | Thành công (AGP 9.1, Kotlin 2.4) | `evidence/auth/build-apk-debug-*.log` |
| Cài APK lên emulator `LocalMate_Pixel` API 35 và mở app | Hiện màn lỗi khởi động `not-configured`; bấm Thử lại thì chạy lại bootstrap (logcat ghi lần thử mới); không có prompt thông báo | `evidence/ui/CHARLIE-AUTH-01/run-20261102-01/android/` (`startup-not-configured.png`, `logcat-startup.txt`, `ui-tree-startup.xml`) |

Lưu ý: `.gitignore` của repo bỏ qua `*.log`. Các log ở trên có trên máy để Codex đọc, nhưng sẽ không vào commit nếu không đổi tên (ví dụ thành `.txt`) — cần quyết khi commit.

Test có ý nghĩa đã chạy (fakes chỉ nằm trong `test/`):

- **ViewModel:**
  - khởi động ra SignedOut;
  - đăng nhập thành công thì credential → profile → session start, đặt định danh và log `login`;
  - hủy không bị ghi thành lỗi;
  - lỗi credential;
  - **lỗi profile thành ProfileError rồi retry thành công**, hoặc sign-out từ màn khôi phục;
  - bấm lặp chỉ gọi đăng nhập một lần;
  - phiên phục hồi khi mở app;
  - logout xóa định danh và gọi `clearSession` đúng một lần;
  - SDK sign-out lỗi vẫn xóa local;
  - đổi A → B thì clear rồi start;
  - token bị thu hồi thì kết thúc phiên.
- **Mapper:** Google (cancel, network, ApiException 10, khác), Firebase Auth, Firestore.
- **Cách ly phiên (ViewModel thật + service giả):** sau khi A logout, B không thấy plan, saved plans, ingredients/Undo, URL export hay inbox của A; quyền FCM xin sau đăng nhập.
- **Widget:**
  - Sign-in ở các trạng thái idle, loading, hủy, lỗi, retry;
  - màn khôi phục (mỗi nút là node riêng);
  - logout gỡ route đã push nên `canPop` là false;
  - StartupGate lỗi rồi Thử lại thì vào app.
- **Bootstrap:** chuỗi lỗi thật lấy từ logcat Android được phân loại `not-configured`.
  - Lỗi do runtime phát hiện và đã sửa: Android đặt thông điệp trong `code` của PlatformException nên ban đầu bị phân loại sai.

**Ảnh actual** (widget host với font thật, DPR 2, textScale 1.0; ảnh ×2.0 ở DPR 1) nằm trong `evidence/ui/CHARLIE-AUTH-01/run-20261102-01/actual/`:

- `auth-sign-in-{360,412}.png`, `auth-sign-in-loading-*`, `auth-sign-in-cancelled-*`, `auth-sign-in-error-*`, `auth-profile-recovery-*`
- `auth-sign-in-error-360-text2_0.png`: không overflow, nội dung cuộn được

Cùng thư mục có các ảnh regression của UI-01 (`buttons.png`, `qa-responsive-*`…). Ảnh runtime Android: `android/startup-not-configured.png`.

## 6. Chưa kiểm chứng (không suy ra từ widget test)

- **Google Sign-In lỗi thật:** SHA hoặc OAuth sai, mất mạng khi đăng nhập. Luồng thành công và hủy đã chạy (mục 2.1).
- **Rules mới trên project thật:** đã publish và có test allowed/denied trên emulator. Trên project thật mới chạy đọc `users/{uid}` và tạo `meal_plans` nháp (mục 2.2).
- Máy của Thắng, Hoàng, Thái An (S3-2).
- Deploy `storage.rules` (S3-7).
- TalkBack bật thật. Mới có cây accessibility từ uiautomator.
- Màn khôi phục trên Android (`AuthRecoveryScreen`).
- Plugin Crashlytics trên AGP 9.
- HomeScreen (dashboard tạm của skeleton) chưa được dựng lại và nằm ngoài gói này.

## 7. Cần nhóm cung cấp để hoàn tất phần cloud

1. ~~Firebase project~~ — đã tạo `longvita-8da7e`. **Chưa mời** Thắng, Hoàng và Thái An vào project.
2. ~~Quyết định app ID~~ — đã chốt `vn.edu.fpt.longvita`.
3. `firebase-tools` 15.34.2 và `flutterfire_cli` 1.4.1 **đã cài**, nhưng Charlie không đăng nhập được qua terminal nên phần cấu hình làm trên Console. App đọc config native từ `google-services.json`; chưa có `firebase_options.dart`.
4. SHA-1/SHA-256 debug của Thắng, Hoàng và Thái An.
5. ~~Bật provider Google~~ — đã bật. Vẫn cần tài khoản Google test riêng (S0-5, Thái An); lần chạy này dùng tài khoản của Charlie.

Các bước tiếp theo:

1. Hoàng/Thắng review bản sửa AUD-11 đã publish (mục 2.2) và chốt B1–B5.
2. Mời ba thành viên, thêm SHA của họ, tải lại `google-services.json`.
3. Kiểm build AGP 9 với Crashlytics.
4. Xử lý S3-7 sau khi chốt DEC-01.

## 8. Quyết định và việc cần review

| # | Nội dung | Ai |
|---|---|---|
| A1 | Đổi contract `IAuthService` (mục 3.1) | Thắng (S2-1) |
| A2 | `main.dart` tách `buildAppScope()`; `AuthGate` thêm `popUntil` khi rời phiên | Thắng (S2-2/S3-6) |
| A3 | Thêm `clearSession()` vào MealPlan/Ingredient VM | Hoàng |
| A4 | Thêm `container: true` vào semantics các widget UI-01 (đổi hành vi accessibility, nên chốt cùng review UI-01) | Codex/Charlie |
| A5 | Bản Sign-in tiếng Việt, không có logo Google (không có frame Figma) | Charlie/Hoàng, DEC-05 |
| A6 | Theo dõi cảnh báo KGP của `firebase_analytics`/`firebase_remote_config` trên AGP 9 | Thắng/Thái An |
| A7 | Chốt kiểu `createdAt` trong schema chung: hiện là chuỗi giờ local không có múi giờ, cần chọn ISO có múi giờ hoặc Timestamp | Thắng/Hoàng (S2-1) |
| A8 | Bản sửa AUD-11 đã publish theo duyệt của Charlie, trước khi Hoàng/Thắng review (mục 2.2) | Hoàng/Thắng/Charlie |
| A9 | `MealPlanViewModel` dùng món hard-code (`_getInitialLongevityRecipes`, `meal_plan_viewmodel.dart:58`) khi Firestore chưa có `recipes`, nên plan test lưu các món `r_fish_1`, `r_legume_1`, `r_veg_1`. Trái quy định không dùng recipe fallback khi nộp bài; chưa sửa vì ngoài gói này | Hoàng |
| B1 | Plan bị `rejected` là trạng thái cuối, owner không gửi lại được mà phải tạo plan mới. `approved` được phép không có lý do | Hoàng/Thắng (S1-2, SYS-02) |
| B2 | Bỏ quyền tạo plan với `status: 'submitted'` của bản cũ. App hiện chỉ tạo `draft` | Hoàng/Thắng |
| B3 | Staff/admin không còn sửa được nội dung plan, và vẫn duyệt được plan của chính mình | Hoàng/Thắng |
| B4 | `recipes` chỉ nhận đúng các key hiện có. Final yêu cầu chức năng archive, nên khi chốt trường archive phải thêm vào rules. Chưa giới hạn giá trị `category`, chưa kiểm tra chi tiết bên trong `days`, `ingredients` | Hoàng/Thắng (S4-1) |
| B5 | `createdAt` chỉ nhận string theo code hiện tại. Nếu A7 chốt Timestamp thì phải sửa rules và test | Thắng/Hoàng (S2-1) |
