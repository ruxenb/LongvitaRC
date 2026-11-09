# Contract xuất PDF Final: PDF trên máy + metadata Firestore

Bản đề xuất NC-01, 09/11/2026. Trạng thái: **chờ PM review contract**. Chưa có code, rules, deploy hay dữ liệu Firestore nào theo contract này.

Baseline: `main` `92bac93`. SDK theo `pubspec.lock`: `cloud_firestore` 5.6.12, `firebase_core` 3.15.2. Không nâng package.

Phạm vi: luồng xuất PDF trên Profile của app mobile. Không gồm màn lịch sử, đồng bộ hay tải file giữa thiết bị, Web Admin, monorepo, hay đổi schema `meal_plans`, `users`, `recipes`.

## 1. Hiện trạng trên `92bac93`

| Điểm | Code hiện tại | Hệ quả cho Final |
|---|---|---|
| Luồng xuất | `ProfileViewModel.exportAndUploadPdf`: tạo PDF → `LocalReportStore.save` → luôn gọi `_upload` (Storage) | Final phải dừng ở bản lưu local, không upload |
| Export ID | `_newExportId`: `{planId đã lọc}_{millisecondsSinceEpoch}`, hoặc `plan_{ms}` khi plan chưa lưu | Hai lần xuất trong cùng mili giây trùng ID. ID plan do `DataService.draftDocumentId` tạo là `{uid}_{micros}`, nên **tên file PDF khi chia sẻ chứa UID** |
| Model | `ReportExport(exportId, planId, filePath)` | Thiếu thời điểm, kích thước; `planId` không cho null |
| Metadata | Không có API ghi metadata báo cáo trong `IDataService`/`DataService` | Cần repository mới |
| Analytics | `logExportReport` chỉ gọi sau khi upload thành công, và được `await` sau `_finish` | Final cần đổi thời điểm phát event |
| Wiring | `main.dart` luôn tạo `StorageService()`; constructor gọi `FirebaseStorage.instance` | Final không nên khởi tạo Storage chỉ để xuất local |
| Rules | Deny-by-default; `users`, `meal_plans`, `shopping_lists/{uid}/plans/{planId}` có `hasOnly`. Không có match cho metadata báo cáo | Cần match riêng; subcollection **không** kế thừa quyền của document cha |
| Ghi Firestore hiện có | `saveMealPlan`, `saveShoppingItems` dùng `.set(...).timeout(writeTimeout)` và coi timeout là "chưa có xác nhận từ máy chủ" | Metadata giữ cùng ngữ nghĩa: timeout không phải lỗi, không hủy lệnh ghi |
| Phiên | `SessionEpoch` và `_activeOperation` trong `ProfileViewModel`; `clearSession` xóa PDF local của UID cũ | Giữ nguyên, áp thêm cho kết quả ghi metadata |

## 2. Nơi lưu metadata

| Phương án | Ưu | Nhược | Kết luận |
|---|---|---|---|
| **A. `users/{uid}/report_exports/{exportId}`** | Owner nằm ngay trong path; rules owner-only độc lập; không đụng `users` hay `meal_plans`; chạy được cả khi plan chưa lưu | Thêm một match rules mới | **Chọn** |
| B. Thêm field vào `meal_plans/{planId}` | Gắn trực tiếp với plan | Phá `hasOnly` và `isOwnerDraftUpdate` của `meal_plans`; bị chặn khi plan `submitted`/`approved`; không có chỗ cho plan chưa lưu; staff đọc được | Loại |
| C. Collection gốc `report_exports/{id}` có field `uid` | Dễ cho truy vấn tổng hợp sau này | Owner phải kiểm bằng field; dễ lộ qua query sai | Loại |

Phương án A không làm `users/{uid}` lộ thêm dữ liệu: staff/admin đọc được profile `users/{uid}`, nhưng **không** đọc được subcollection, vì rules phải khai báo match riêng.

## 3. Schema `users/{uid}/report_exports/{exportId}`

| Field | Kiểu | Bắt buộc | Bất biến | Ý nghĩa và ràng buộc |
|---|---|---|---|---|
| `exportId` | string | có | có | Bằng document ID. Dạng ở mục 4 |
| `planId` | string hoặc null | có (có thể null) | có | ID trong `meal_plans` khi plan đã lưu; `null` khi xuất plan chưa lưu |
| `createdAt` | string ISO-8601 UTC | có | có | Lấy **một lần** khi bắt đầu lần xuất (ví dụ `2026-11-09T02:42:42.123Z`). Retry dùng lại đúng giá trị này |
| `fileName` | string | có | có | Bằng `{exportId}.pdf` |
| `sizeBytes` | int | có | có | Kích thước file đã lưu; `0 < sizeBytes <= 10485760` (10 MiB) |
| `schemaVersion` | int | có | có | Bằng `1` |

**Không lưu:** UID (đã có trong path), tên, email, ảnh, tiêu đề plan (tiêu đề hiện chứa tuổi và cân nặng), PDF bytes hay base64, đường dẫn tuyệt đối trên máy, download URL hay token.

Model Dart dự kiến (NC-02): `ReportMetadata` với `toMap()` trả đúng 6 key trên, `planId` được ghi ra là `null` khi chưa lưu.

## 4. Export ID, lần xuất mới và retry

- **Dạng:** `pdf_{yyyyMMdd'T'HHmmss'Z'}_{16 hex ngẫu nhiên}`, ví dụ `pdf_20261109T024242Z_9f3c1a2b4d5e6f70`.
  - Phần thời gian lấy từ `createdAt` để file dễ sắp xếp.
  - 64 bit lấy từ `Random.secure()`, nên hai lần xuất trong cùng mili giây vẫn khác ID.
  - Regex: `^pdf_[0-9]{8}T[0-9]{6}Z_[0-9a-f]{16}$`.
  - Không chứa plan ID hay UID, nên tên file khi chia sẻ không lộ UID.
- **Mỗi lần người dùng bấm "Xuất":** luôn tạo ID mới, file mới và metadata mới.
- **Retry metadata:** dùng **đúng** `ReportMetadata` đã tạo (cùng ID, `createdAt`, `sizeBytes`). Không tạo lại PDF, không đổi ID.
- **Ghi:** `doc(exportId).set(metadata.toMap())`, ghi toàn bộ, không merge. Rules:
  - `create` khi document chưa tồn tại và payload hợp lệ;
  - `update` chỉ khi payload mới **bằng hệt** payload đã có, tức retry idempotent;
  - mọi khác biệt là trùng ID (collision): bị từ chối, không ghi đè.
- Collision thật chỉ xảy ra khi trùng 64 bit ngẫu nhiên, nên coi là lỗi, không tự tạo ID khác.

## 5. Plan chưa lưu và tham chiếu plan

- Vẫn cho xuất PDF từ `activePlan` chưa lưu, đúng hành vi hiện tại; không ép người dùng lưu plan. Khi đó metadata có `planId: null`.
- Với plan đã lưu, rules kiểm `get(/meal_plans/{planId}).data.uid == uid`, nên không thể gắn metadata vào plan của người khác. Metadata không cấp thêm quyền đọc plan.
- Không đổi trạng thái `submitted` hiện dùng. Sự khác nhau giữa `pending` (bảng Final) và `submitted` thuộc CM-01, không xử lý trong gói này.
- Snapshot plan: lấy `activePlan` **một lần** khi bấm Xuất, và dùng đúng bản đó cho cả PDF lẫn `planId`, kể cả khi người dùng đổi plan lúc PDF đang tạo.

## 6. Hai trạng thái độc lập

| State | Giá trị | Chuyển trạng thái |
|---|---|---|
| **PDF trên máy** | `idle` → `generating` → `saved` hoặc `error` | `saved` khi `LocalReportStore.save` xong và phiên còn hợp lệ. `error` khi tạo hoặc lưu thất bại; khi đó không ghi metadata |
| **Metadata** | `idle` → `saving` → `confirmed`, hoặc `saving` → `pending` → `confirmed`, hoặc `error` | Bắt đầu ngay sau `saved`. `confirmed` khi Future của `set()` hoàn tất. `pending` khi quá ngưỡng chờ (`DataService.writeTimeout` = 15 s, dùng chung hằng số) mà Future chưa xong. `error` khi Future báo lỗi |

**Ngữ nghĩa xác nhận từ server:**
- Theo tài liệu Firebase, lệnh ghi không hoàn tất cho tới khi backend nhận dữ liệu: "the returned `Promise` does *not* resolve until the data is successfully written to the remote Firestore backend" (JS reference, `setDoc`). Snapshot giữ `metadata.hasPendingWrites = true` cho tới khi backend ghi xong.
- Persistence offline bật mặc định trên Android, nên lệnh ghi được xếp hàng và gửi lại khi có mạng.
- Vì vậy `confirmed` = Future của `set()` hoàn tất. NC-02 sẽ kiểm lại hành vi này với Firestore Emulator (tắt/bật mạng) trên đúng SDK 5.6.12.

**Quy tắc:**
- `pending` **không** phải lỗi. App tiếp tục chờ **chính Future cũ** và không hủy nó (SDK không hủy được lệnh đã xếp hàng). Khi Future xong, chuyển sang `confirmed`.
- Không tạo document hay lệnh ghi mới khi đang `pending`; không có nút thử lại lúc này.
- `error` (ví dụ `permission-denied`): hiện thông báo và nút "Thử đồng bộ lại". Nút này gửi lại đúng payload cũ; chỉ một lần thử chạy tại một thời điểm; không tự lặp.
- Mở và chia sẻ PDF **luôn** dùng được khi PDF đã `saved`, bất kể metadata đang `saving`, `pending` hay `error`.
- Không quay spinner vô hạn: sau ngưỡng chờ, UI hiện "Đang chờ kết nối để đồng bộ", không chặn thao tác khác.
- Lần xuất mới thay `lastExport`. Kết quả metadata của lần xuất cũ về muộn không được ghi đè state của lần mới; dùng token của từng lần xuất.

## 7. Phiên đăng nhập và logout

- Mọi callback (tạo, lưu, kết quả `set()`, analytics) đều kiểm **epoch phiên và token của lần xuất** sau mỗi `await`.
  - A → B: B không nhận state, lỗi hay log của lần xuất của A.
  - A → logout → A: cũng không nhận, vì đã là phiên mới.
- Logout vẫn xóa PDF local của UID cũ như hiện tại (S3-5). Metadata đã gửi trước logout có thể vẫn tới server sau đó: không hứa xóa hay hủy, không coi metadata là bằng chứng file còn trên máy.
- Lệnh ghi đang xếp hàng của A không được gửi bằng phiên B. Firestore SDK giữ hàng ghi theo user. Tài liệu offline đã đọc chưa nói rõ điểm này, nên NC-02 kiểm bằng Emulator (A ghi offline → logout → B đăng nhập → bật mạng: document vẫn thuộc A hoặc bị rules từ chối, không bao giờ ghi vào path của B). Nếu SDK không đảm bảo, phải báo PM trước khi tiếp tục.
- Rules tự chặn mọi ghi sai owner, vì path chứa UID và rules yêu cầu `request.auth.uid == uid`.

## 8. Chế độ Final và demo Storage

- Thêm `--dart-define=PDF_EXPORT_MODE`, mặc định `final`.
  - `final`: không tạo `StorageService`, không gọi upload.
  - `storage_emulator_demo`: chỉ bật upload khi `STORAGE_EMULATOR_HOST` thuộc `{10.0.2.2, 127.0.0.1, localhost}`.
- Đặt demo mà host thiếu hoặc sai thì **fail closed**: chạy như Final và ghi cảnh báo debug. Không có đường nào upload lên Storage production.
- `StorageService` chỉ được tạo (lazy) trong demo hợp lệ.
- Ở demo, upload là bước phụ sau `saved`. Kết quả upload không đổi state PDF hay metadata, và metadata không chứa URL.
- Giữ nguyên `storage.rules`, `storage.rules.test.js` và evidence Emulator cũ.

## 9. Analytics `export_report`

- Phát **đúng một** event cho mỗi lần xuất, ngay khi PDF ở `saved` và phiên còn hợp lệ. Không phụ thuộc metadata hay upload.
- Giữ tham số: `topic`, `report_topic`, `file_size_kb` (= ceil(sizeBytes / 1024)), `has_shopping_list` (= 0).
- Retry metadata hay upload demo **không** phát thêm event. Lần xuất lỗi ở bước tạo hoặc lưu không phát event.
- Gọi không `await` trước khi cập nhật UI (`unawaited`); lỗi hay chậm của Analytics/Crashlytics không chặn state.

## 10. Interface đề xuất

```dart
// lib/models/report_metadata.dart
class ReportMetadata {
  final String exportId;      // == document id
  final String? planId;       // null when the plan was never saved
  final String createdAt;     // ISO-8601 UTC, captured once
  final int sizeBytes;
  static const schemaVersion = 1;
  String get fileName => '$exportId.pdf';
  Map<String, Object?> toMap();
}

// lib/services/i_report_metadata_repository.dart
abstract interface class IReportMetadataRepository {
  /// Writes the metadata of one export under users/{uid}/report_exports.
  /// Completes when the server acknowledged it; throws when it was rejected.
  /// Never times out or cancels by itself: callers decide when to show
  /// "pending" and keep awaiting the same Future.
  Future<void> save(String uid, ReportMetadata metadata);
}

// lib/services/firestore_report_metadata_repository.dart
class FirestoreReportMetadataRepository implements IReportMetadataRepository { ... }

// lib/config/pdf_export_mode.dart
enum PdfExportMode { finalLocal, storageEmulatorDemo }
PdfExportMode resolvePdfExportMode({String mode, String emulatorHost});
```

- Repository tách khỏi `IDataService`, nên các fake nghiệp vụ hiện có không phải đổi.
- `ProfileViewModel` nhận `IReportMetadataRepository`, `PdfExportMode` và một `StorageService?` (chỉ có ở demo) qua constructor.
- `ReportExport` mở rộng thêm `createdAt` và `sizeBytes`; `planId` thành `String?`.

## 11. Rules dự kiến (NC-02)

```text
match /users/{uid}/report_exports/{exportId} {
  allow read: if isOwner(uid);
  allow create: if isOwner(uid) && isValidReportExport(request.resource.data, uid, exportId);
  allow update: if isOwner(uid) && request.resource.data == resource.data;   // idempotent retry only
  allow delete: if false;
}

function isValidReportExport(data, uid, exportId) {
  return data.keys().hasOnly(['exportId','planId','createdAt','fileName','sizeBytes','schemaVersion'])
      && data.keys().hasAll(['exportId','planId','createdAt','fileName','sizeBytes','schemaVersion'])
      && data.exportId == exportId
      && exportId.matches('^pdf_[0-9]{8}T[0-9]{6}Z_[0-9a-f]{16}$')
      && data.fileName == exportId + '.pdf'
      && data.createdAt is string
      && data.createdAt.matches('^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]{1,6})?Z$')
      && data.sizeBytes is int && data.sizeBytes > 0 && data.sizeBytes <= 10485760
      && data.schemaVersion == 1
      && (data.planId == null
          || (data.planId is string
              && get(/databases/$(database)/documents/meal_plans/$(data.planId)).data.uid == uid));
}
```

Ghi chú: `isOwner` đã có. Không dùng `isStaffOrAdmin`, nên staff/admin của UID khác bị từ chối. Mọi match hiện có giữ nguyên.

## 12. File dự kiến thay đổi

| Gói | File |
|---|---|
| NC-02 | mới: `lib/models/report_metadata.dart`, `lib/services/i_report_metadata_repository.dart`, `lib/services/firestore_report_metadata_repository.dart`, `test/report/report_metadata_test.dart`; sửa: `firebase/firestore.rules`, `firebase/tests/firestore.rules.test.js` |
| NC-03 | mới: `lib/config/pdf_export_mode.dart`, test mode/flow; sửa: `lib/models/report_export.dart`, `lib/viewmodels/profile_viewmodel.dart`, `lib/main.dart` (wiring tối thiểu), `test/auth/auth_fakes.dart`, `test/report/profile_export_test.dart`, `export_overlap_test.dart`, `session_cleanup_test.dart`, `export_plan_selection_test.dart`, `test/analytics/analytics_service_test.dart` nếu cần |
| NC-04 | sửa: `lib/screens/profile_screen.dart`, `test/profile/profile_screen_test.dart` |
| Không đổi | `lib/firebase/storage_service.dart` (chỉ đổi cách khởi tạo), `firebase/storage.rules`, `firebase/tests/storage.rules.test.js`, `lib/services/data_service.dart`, `lib/services/i_data_service.dart`, `lib/services/local_report_store.dart` |

## 13. Ma trận kiểm thử

| # | Tình huống | Kỳ vọng | Mức |
|---|---|---|---|
| T1 | Xuất Final thành công, plan đã lưu | PDF `saved`; 0 lần upload; metadata `confirmed`; payload đúng 6 field, `planId` đúng; 1 event | unit + widget |
| T2 | Xuất plan chưa lưu | `planId: null`; vẫn `saved` và `confirmed` | unit + rules |
| T3 | Tạo PDF lỗi / lưu file lỗi | `error`; không metadata, không event; ghi Crashlytics | unit |
| T4 | Hai lần xuất cùng plan, cùng mili giây | Hai ID khác nhau, hai file, hai metadata, 2 event | unit (clock + random giả) |
| T5 | Metadata chậm quá ngưỡng | `pending`, mở/chia sẻ vẫn chạy; Future cũ xong thì `confirmed` mà không ghi lần hai | unit (Completer) |
| T6 | Metadata bị từ chối | `error` + thử lại; retry gửi đúng payload cũ; 0 event thêm; không tạo PDF mới | unit |
| T7 | Bấm thử lại khi đang `pending` hoặc đang retry | Không có lệnh ghi thứ hai | unit |
| T8 | A → B khi metadata hoặc PDF đang chạy | B không nhận state, lỗi hay event của A; file của B không bị xóa | unit (epoch) |
| T9 | A → logout → A khi metadata đang chạy | Phiên mới không nhận kết quả cũ; PDF cũ đã dọn | unit |
| T10 | Xuất mới khi metadata lần trước còn `pending` | State thuộc lần mới; kết quả lần cũ về muộn bị bỏ qua | unit |
| T11 | Đổi plan hoặc đổi món rồi xuất | PDF và `planId` đúng plan lúc bấm (giữ 2 regression S4-10) | widget |
| T12 | Analytics lỗi hoặc chậm | State vẫn `saved`; event vẫn được gọi đúng 1 lần | unit |
| T13 | Mode `storage_emulator_demo` + host hợp lệ | Upload chạy sau `saved`; lỗi upload không đổi PDF/metadata | unit |
| T14 | Mode demo với host thiếu hoặc sai | Không upload; chạy như Final | unit |
| T15 | Final không khởi tạo `StorageService` | Không gọi `FirebaseStorage.instance` | unit/wiring |
| R1 | Owner tạo document hợp lệ (plan đã lưu, plan null) | allow | rules (Emulator) |
| R2 | Ẩn danh; user khác; staff/admin khác UID | deny đọc và ghi | rules |
| R3 | `exportId` ≠ doc ID; regex sai; thiếu hoặc thừa field; sai kiểu; `sizeBytes` ≤ 0 hoặc > 10 MiB; `schemaVersion` ≠ 1; `fileName` sai | deny | rules |
| R4 | Gửi lại cùng ID, cùng payload | allow (update giống hệt) | rules |
| R5 | Cùng ID, payload khác | deny | rules |
| R6 | `planId` là plan của người khác hoặc không tồn tại | deny | rules |
| R7 | Owner xóa document | deny | rules |
| R8 | Các suite rules hiện có: `firebase/tests/firestore.rules.test.js` (`users`, `recipes`, `meal_plans`, `shopping_lists`, `announcements`) và `test/firestore/hoang_rules.test.cjs` | vẫn pass | rules |
| S1 | Ghi offline rồi bật mạng (Emulator) | Future treo khi offline, hoàn tất khi online; đúng 1 document | Emulator, NC-02 |
| S2 | Lệnh ghi xếp hàng của A, logout, B đăng nhập, bật mạng | Không có document nào trong path của B | Emulator, NC-02 |
| N1–N4 | Native Spark ở NC-05: xuất → mở/chia sẻ; đổi plan; offline rồi reconnect; đọc lại metadata độc lập | Theo mục 9 của kế hoạch NC | AVD |

## 14. Quyết định còn mở cho PM

1. **Xóa metadata:** đề xuất `delete: false`, vì không có luồng xóa. Có cần cho owner tự xóa không?
2. **Ngưỡng chuyển `pending`:** dùng lại `DataService.writeTimeout` (15 s), giống `saveMealPlan` và `saveShoppingItems`. Có cần ngưỡng riêng ngắn hơn cho Profile không?
3. **Kiểm tham chiếu plan bằng `get()`:** mỗi lần ghi tốn thêm 1 lượt đọc (trong hạn mức Spark). Nếu plan bị xóa trước khi metadata tới server thì ghi bị từ chối và vào `error`. Chấp nhận, hay chỉ kiểm `planId` là chuỗi hợp lệ?
4. **HD-06** trong bảng Final (Hoàng) có cùng nội dung "metadata lịch sử vào Firestore", và đầu ra ghi "update doc". Contract chọn subcollection riêng, không cập nhật `meal_plans`. PM cần thống nhất với owner HD-06 hoặc CM-01 để không có hai schema.
5. **Tên file chia sẻ:** contract đổi sang ID không chứa UID. File PDF đã xuất trước đó giữ tên cũ; không đổi tên file cũ.
6. **Nơi đặt mode:** `--dart-define` như trên, hay hằng số build flavor? Đề xuất `--dart-define`, cùng cách `STORAGE_EMULATOR_HOST` đang dùng.
