# Contract xuất PDF Final: PDF trên máy + metadata Firestore

NC-01, 09/11/2026. Trạng thái: **PM chốt contract sau review 9d460d3**, với các quyết định tại mục14. Cho phép tiếp tục DUY NHẤT NC-02; chưa nghiệm thu gói app Final. Chưa có code, rules deploy hoặc dữ liệu Firestore nào theo contract này.

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
  - 64 bit lấy từ `Random.secure()`, không phụ thuộc riêng vào clock. Xác suất trùng rất thấp nhưng không bằng0; cần bảo vệ collision ở cả file local và metadata.
  - Regex: `^pdf_[0-9]{8}T[0-9]{6}Z_[0-9a-f]{16}$`.
  - Không chứa plan ID hay UID, nên tên file khi chia sẻ không lộ UID.
- **Mỗi lần người dùng bấm "Xuất":** luôn tạo ID mới, file mới và metadata mới.
- **Retry metadata:** dùng **đúng** `ReportMetadata` đã tạo (cùng ID, `createdAt`, `sizeBytes`). Không tạo lại PDF, không đổi ID.
- **Ghi:** `doc(exportId).set(metadata.toMap())`, ghi toàn bộ, không merge. Rules:
  - `create` khi document chưa tồn tại và payload hợp lệ;
  - `update` chỉ khi payload mới **bằng hệt** payload đã có, tức retry idempotent;
  - mọi khác biệt là trùng ID (collision): bị từ chối, không ghi đè.
- Khi một lần xuất mới trùng ID với file local có sẵn hoặc metadata khác nội dung: báo collision, không ghi đè file/document cũ và không tự đổi ID trong retry. `LocalReportStore.save` hiện có semantics replace; NC-03 cần đường save-new kiểm tra tồn tại và ghi trong cùng hàng đợi UID hoặc cơ chế tương đương bảo đảm không clobber. Kiểm trước ở ViewModel rồi gọi save ở hai thao tác tách rời không là bảo đảm nguyên tử. Test ép RNG trả cùng giá trị phải giữ nguyên bytes file cũ.

## 5. Plan chưa lưu và tham chiếu plan

- Vẫn cho xuất PDF từ `activePlan` chưa lưu, đúng hành vi hiện tại; không ép người dùng lưu plan. Khi đó metadata có `planId: null`.
- Khi tạo metadata mới cho plan đã lưu, rules kiểm planId là document segment hợp lệ và `get(/meal_plans/{planId}).data.uid == uid`; plan không tồn tại hoặc khác owner thì từ chối. Không tự tạo/lưu plan để vượt lỗi này. Metadata không cấp thêm quyền đọc plan.
- Retry với payload giống hệt record đã tồn tại chỉ kiểm owner + shape + equality, không đọc lại plan. Vì vậy metadata vẫn đọc được và retry no-op vẫn hợp lệ sau khi plan gốc đã bị xóa; lịch sử không phụ thuộc plan phải còn sống mãi. get() là kiểm create và có thể tiêu thụ document reads/quota kể cả khi bị từ chối, không cam kết đúng1 lượt tính phí ở mọi retry.
- Không đổi trạng thái `submitted` hiện dùng. Sự khác nhau giữa `pending` (bảng Final) và `submitted` thuộc CM-01, không xử lý trong gói này.
- Snapshot plan: lấy `activePlan` **một lần** khi bấm Xuất, và dùng đúng bản đó cho cả PDF lẫn `planId`, kể cả khi người dùng đổi plan lúc PDF đang tạo.

## 6. Hai trạng thái độc lập

| State | Giá trị | Chuyển trạng thái |
|---|---|---|
| **PDF trên máy** | `idle` → `generating` → `saved` hoặc `error` | `saved` khi `LocalReportStore.save` xong và phiên còn hợp lệ. `error` khi tạo hoặc lưu thất bại; khi đó không ghi metadata |
| **Metadata** | `idle` → `saving` → `confirmed`, hoặc `saving` → `pending` → `confirmed`, hoặc `error` | Bắt đầu ngay sau `saved`. `confirmed` khi Future của `set()` hoàn tất. `pending` khi quá ngưỡng chờ (`reportMetadataPendingAfter` = 15 s, hằng số riêng được inject cho test, không phụ thuộc DataService) mà Future chưa xong. `error` khi Future báo lỗi |

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
- Chưa tuyên bố đã kiểm chứng FlutterFire giữ hàng ghi đúng user. NC-02 phải dùng chính FlutterFire5.6.12 trên Android QA host + Auth/Firestore Emulator để quan sát: A ghi offline → logout → B đăng nhập → online. Ghi trạng thái Future gốc và server state của cả path A/B, không chỉ assert “không có doc ở B” vì request vốn cố định path A. Sau đó đăng nhập lại A để quan sát queued write phục hồi hoặc bị từ chối theo SDK thực. Không tạo write mới dưới B/A để làm probe pass. Unit fake/Node hoặc JS SDK chỉ kiểm rules, không thay bằng chứng này. Nếu không chạy được/khác giả định, báo đúng giới hạn cho PM trước NC-03; chưa kết luận an toàn offline đa tài khoản từ rules đơn thuần.
- Rules tự chặn mọi ghi sai owner, vì path chứa UID và rules yêu cầu `request.auth.uid == uid`.

## 8. Chế độ Final và demo Storage

- Thêm `--dart-define=PDF_EXPORT_MODE`, mặc định `final`.
  - `final`: không tạo `StorageService`, không gọi upload.
  - `storage_emulator_demo`: chỉ bật upload khi `STORAGE_EMULATOR_HOST` thuộc `{10.0.2.2, 127.0.0.1, localhost}`.
- Đặt demo mà host thiếu hoặc sai thì **fail closed**: chạy như Final và ghi cảnh báo debug. Không có đường nào upload lên Storage production.
- `StorageService` chỉ được tạo (lazy) trong demo hợp lệ. Upload chỉ được phép sau khi Future cấu hình Emulator hoàn tất thành công; lỗi cấu hình thì zero upload và không fallback production. Constructor hiện gọi `useStorageEmulator` bằng unawaited, nên NC-03 được sửa tối thiểu initialization readiness để thực thi yêu cầu này; đây là điều kiện cấu hình, chưa khẳng định đã tái hiện upload production.
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

## 11. Rules dự kiến theo quyết định PM (NC-02 phải compile/test Emulator)

```text
function isValidReportExportShape(data, exportId) {
  return data.keys().hasOnly(['exportId','planId','createdAt','fileName','sizeBytes','schemaVersion'])
      && data.keys().hasAll(['exportId','planId','createdAt','fileName','sizeBytes','schemaVersion'])
      && data.exportId == exportId
      && exportId.matches('^pdf_[0-9]{8}T[0-9]{6}Z_[0-9a-f]{16}$')
      && data.fileName == exportId + '.pdf'
      && data.createdAt is string
      && data.createdAt.matches('^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\\.[0-9]{1,6})?Z$')
      && data.sizeBytes is int && data.sizeBytes > 0 && data.sizeBytes <= 10485760
      && data.schemaVersion is int && data.schemaVersion == 1
      && (data.planId == null || (data.planId is string
          && data.planId.size() > 0 && !data.planId.matches('.*[/].*')));
}
function referencesOwnedPlan(planId, uid) {
  return planId == null
      || get(/databases/$(database)/documents/meal_plans/$(planId)).data.uid == uid;
}
match /users/{uid}/report_exports/{exportId} {
  allow read: if isOwner(uid);
  allow create: if isOwner(uid)
      && isValidReportExportShape(request.resource.data, exportId)
      && referencesOwnedPlan(request.resource.data.planId, uid);
  allow update: if isOwner(uid)
      && isValidReportExportShape(request.resource.data, exportId)
      && request.resource.data == resource.data;
  allow delete: if false;
}
```

Ghi chú: `isOwner` đã có. Không dùng `isStaffOrAdmin`, nên staff/admin của UID khác bị từ chối. Mọi match hiện có giữ nguyên.

## 12. File dự kiến thay đổi

| Gói | File |
|---|---|
| NC-02 | mới: `lib/models/report_metadata.dart`, `lib/services/i_report_metadata_repository.dart`, `lib/services/firestore_report_metadata_repository.dart`, `test/report/report_metadata_test.dart`; sửa: `firebase/firestore.rules`, `firebase/tests/firestore.rules.test.js` |
| NC-03 | mới: `lib/config/pdf_export_mode.dart`, test mode/flow; sửa: `lib/models/report_export.dart`, `lib/viewmodels/profile_viewmodel.dart`, `lib/main.dart` (wiring tối thiểu), `lib/services/local_report_store.dart` (save-new chống clobber), `lib/firebase/storage_service.dart` (readiness Emulator), `lib/services/report_viewer.dart` hoặc boundary tên chia sẻ nếu cần, `test/auth/auth_fakes.dart`, `test/report/profile_export_test.dart`, `export_overlap_test.dart`, `session_cleanup_test.dart`, `export_plan_selection_test.dart`, `test/analytics/analytics_service_test.dart` nếu cần |
| NC-04 | sửa: `lib/screens/profile_screen.dart`, `test/profile/profile_screen_test.dart` |
| Không đổi nghiệp vụ | `firebase/storage.rules`, `firebase/tests/storage.rules.test.js`, `lib/services/data_service.dart`, `lib/services/i_data_service.dart`; các thay đổi LocalReportStore/StorageService chỉ đúng guard đã chốt, không rewrite toàn bộ |

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
| S1 | FlutterFire5.6.12 Android: ghi offline rồi bật mạng | Quan sát Future gốc pending khi offline, hoàn tất khi backend ack; một document đúng payload; cached snapshot không thay ack | Firestore Emulator + QA host, NC-02 |
| S2 | FlutterFire Android: A ghi offline, logout→B→online, sau đó A đăng nhập lại | Ghi trạng thái Future gốc và server doc A/B từng mốc, không tạo write bù; chứng minh request không bị gán cho phiên B, báo khác giả định | Auth/Firestore Emulator + QA host, NC-02 |
| R9 | Tạo khi plan thiếu/khác owner và retry bằng hệt metadata hợp lệ sau khi plan bị xóa | Create bị từ chối; retry no-op và owner read metadata cũ vẫn allowed | rules |
| T16 | Ép RNG trùng ID/file đã có | Không overwrite PDF cũ; không metadata/event success mới | unit/filesystem, NC-03 |
| T17 | Preview/share một export legacy có UID trong filename | Tên hiển thị an toàn, không chứa UID; file gốc giữ nguyên | unit + native khi có file, NC-03/04 |
| T18 | Demo host hợp lệ nhưng cấu hình Emulator chậm/thất bại | Không upload trước khi ready; fail thì zero upload | unit, NC-03 |
| N1–N4 | Native Spark ở NC-05: xuất → mở/chia sẻ; đổi plan; offline rồi reconnect; đọc lại metadata độc lập | Theo mục 9 của kế hoạch NC | AVD |

## 14. Quyết định PM đã chốt — 09/11/2026

Các điểm này được Codex chốt theo ủy quyền kỹ thuật của Charlie/nhóm; không ghi có review trực tiếp của Hoàng hay nghiệm thu app Final.

| Điểm | Quyết định |
|---|---|
| Owner xóa metadata | Không cấp delete trong gói này; chỉ lịch sử metadata, không có flow xóa. Không triển khai cơ chế admin cleanup mới. |
| Pending | 15 giây mặc định, hằng số riêng reportMetadataPendingAfter inject được để test. Không import DataService.writeTimeout hoặc dùng timeout để hủy Future gốc. |
| Plan ownership | get() khi create cho planId khác null; không chỉ kiểm format. Retry equality không get lại plan để giữ lịch sử sau khi plan bị xóa. Không tự tăng quyền hoặc tạo plan bù. |
| HD-06/CM-01 | Một schema và repository duy nhất là contract này. “Update doc” trong HD-06 không quy định phải thêm field vào meal_plans. Map gói NC vào phần PDF/metadata của HD-06 và phần schema/rules liên quan CM-01/03/04; owners/tracker không đổi, chưa đánh các task đó Done. Public technical contract/PR sau này là nguồn handoff cho team, chưa gửi tin nhắn cho ai hoặc yêu cầu chờ Hoàng mới làm NC-02. |
| Mode | --dart-define PDF_EXPORT_MODE, default/unknown mode về Final. Chỉ exact storage_emulator_demo + host allowlist + Emulator setup ready mới upload; không cần build flavor mới. Final + host có sẵn vẫn Final. |
| Legacy files | Không rename/migrate/xóa file cũ. Khi mở/share qua app, filename đưa ra external viewer/share phải an toàn: ID mới nếu hợp lệ, còn legacy fallback tên trung tính như Longvita-report.pdf; không truyền nguyên tên có UID. Không đổi đường dẫn đọc file local. Không thể thu hồi bản file đã được chia sẻ trước đây. |

### Các yêu cầu bổ sung đã chốt

- Collision phải giữ bytes file cũ, không chỉ để Firestore từ chối sau khi LocalReportStore đã replace file. Random64 rất ít collision, không là chứng minh không thể trùng.
- Chờ cấu hình Emulator thực sự xong trước upload, không freeze StorageService khi constructor hiện unawaited.
- Statement về Future/set và user-bound queue là giả định triển khai cần S1/S2 trên đúng FlutterFire; không gọi JS reference là chứng minh Android đã pass.
- Rules trong mục11 vẫn là draft để NC-02 compile/test. Validation schemaVersion phải là int; owner/no-op retry/plan-deleted và schema mismatch phải có tests. Dữ liệu confirmed do client ghi không là chứng nhận độc lập nội dung PDF hoặc thời gian máy chủ; createdAt là client timestamp.

### Bước tiếp theo được giao

**NC-01 hoàn tất review contract. Tiếp tục DUY NHẤT NC-02**, dùng toàn bộ các quyết định mục14. Chưa đổi default export/UI/Analytics (NC-03/04), chưa production deploy/write, chưa push/PR/merge. Nếu S1/S2 chưa chạy được, vẫn hoàn thành phần độc lập model/repository/rules/tests và báo rõ cổng SDK còn thiếu cho PM; không fake một SDK khác để gắn nhãn đã kiểm.


## 15. NC-02 implementation and SDK verification — 09/11/2026

Codex trực tiếp triển khai theo Charlie yêu cầu, kế thừa3file/rules đang dở của Claude sau khi Charlie xác nhận Claude đã dừng. Code8f2bf6a; evidence tại evidence/firebase/NC-02-metadata-20261109/. Chưa push/PR/deploy hoặc ghi production; chưa thực hiện NC-03/04.

- Model/repository metadata và scoped owner-only rules đã có. 11 metadata unit tests, full411Flutter tests,64Firebase rules (50Firestore+14Storage),22Hoang rules đạt; analyzer lib/test sạch. Nodeclient thực dùng13.1.0 từ shared firebase modules, không ghi rằng đã chạy lock13.2.0 của Hoang.
- S1/S2 đã kiểm bằng đúng cloud_firestore5.6.12/firebase_auth5.7.0/core3.15.2 trên Android15, ứng dụng QA riêng và Auth/FirestoreEmulator demo-longvita. Đây là quan sát SDK đã chạy, không còn chỉ dựa trên JS reference hoặc fake cho hai ca này.
- S1: localpending=true, Future gốc pending và server absent khioffline; online thì chính Future đó confirmed, server khớp và đúng1document.
- S2: Awriteoffline; Bonline thì FutureA vẫnpending, cả serverA/B chưa códoc và Bclientserver-read missing. Ađăngnhậplại thì FutureA gốc confirmed, Adata khớp, Bdoc vẫnabsent; không gửi write bù. Không suy thành bảo đảm cho mọi platform/SDK hoặc UIcallbackepoch đã được kiểm; NC-03 vẫn phải thực thi guards.
- Với baseline rules61fcfdd,6/9nhóm metadata fail,3deny-onlypass; rulesmới9/9pass. Giữ nguyên tất cả expected. Rulesdraft đã compile/chạy Emulator.

NC-02 sẵn sàng PM review. Các T1–T18/UI/Analytics/legacy share/collisionlocal thuộc bước tương ứng chưa tự đánh pass từ kết quả model/repository. Chưa đưa metadata repository vào app main/default export.


## 16. NC-03 implementation — 09/11/2026

Charlie xác nhận NC-02 và giao Codex trực tiếp NC-03. Code `13a188c` chuyển default sang Final local với metadata state/Future độc lập, Analytics một lần tại local save, owner/session/ID/collision/share guards và demo Emulator opt-in có readiness. Profile/main chỉ wiring và nhãn tối thiểu cho đúng nghĩa; chưa hoàn thiện NC-04.

`exportState` nay mô tả local PDF; `uploadState` riêng cho demo. Các test upload dùng mode demo rõ ràng. Alias `exportAndUploadPdf` còn để tương thích; default không tự upload. Trạng thái metadata public: `ReportMetadataState`, `metadataError`, `canRetryMetadata`, `retryMetadata()`. 15 giây là ngưỡng hiển thị, không timeout/cancel write gốc. Retry giữ payload/ID/file và không phát Analytics.

440/440 Flutter (thêm29), analyzer lib/test sạch, APK debug Final build được, mutation7/7 bị test bắt. Chưa cài/chạy native NC-03, chưa deploy/write production hoặc đổi rules/package/lock; không suy thành nghiệm thu Final toàn phần. Evidence chi tiết tại [NC-03](../evidence/pdf/NC-03-local-flow-20261109/README.md).


## 17. NC-04 implementation — 09/11/2026

Code 5cab63b: Profile tách local file/metadata/demo, thêm trạng thái và retry metadata, xử lý file không còn. 452/452 Flutter, analyzer sạch, debug APK build được;12widgetcases mới gồm360/412dp và textScale1/2, Semantics/actions/liveRegion. Hai kiểm âm tính bị bắt. [Evidence NC-04](../evidence/pdf/NC-04-profile-20261109/README.md). Chưa native/deploy trong NC-04; NC-05 theo yêu cầu Charlie triển khai tiếp sau PM kiểm.


## 18. NC-05 native/integration — 09/11/2026

Final No-Cost kiểm trên Android35/Spark thật: local save/open/share, hai plan khác nội dung, offline pending rồi reconnect đúng document/file;5clientmetadata records đọc lại đúng schema/owner/size. 5local saves có5SDKexport_report vàHTTP204; chưa xem GA4 DebugView do Google identity của browser thiếu quyền, không yêu cầu quyền/settings mới. Demo opt-in StorageEmulator upload có byte-for-byte readback; FinalAPK đã cài lại và môi trường/log/network đã phục hồi rồi dừng.

Rules deployed chỉ thêm block metadata vào live, giữ tình trạng Shopping chưa deploy có trước; candidate64/64 rồi deploy firestore:rules và GET readback đúng source. Canonical repo rules giữ nguyên cả Shopping+metadata; xem scope/rollback/limits trong [NC-05 evidence](../evidence/firebase/NC-05-final-no-cost-20261109/README.md). Không Storage cloud/billing/IAM/role/recipes/meal_plan writes hoặc xóa data QA. Native logs/raw PDFs/APKs chỉ local; public evidence lọc UID/token. Gói NC-01..05 đủ kiểm kỹ thuật theo phạm vi đã chốt, Ready for Charlie final acceptance, chưa PR/merge hoặc tự đóng task CM/HD/29task khác.


## 19. Delivery PR24 — integrated review, 09/11/2026

Charlie nghiệm thu toàn gói và cho phép PR/CodeRabbit/tíchhợp main trước FinalUI. Đã tích hợp main134910d; integrationfix0634c3e xử lý S05 overflow và stale hidden-label assertions từ main, giữ accessibility checks. CodeRabbit Round1 nêu1Minor hợp lệ về lời cảnh báo đăng xuất; đã làm rõ app không lưu backup PDF cloud, giữ cảnh báo xóa local và giữ thực đơn. Regression fail trước/pass sau; snapshot453Flutter/analyzer/APKđạt. [Evidence review/integration](../evidence/review/PR24-coderabbit-20261109/README.md). Rules/data/scope cloud và dependency giữ nguyên; chưa xem native hoặc GA4 mới trong bước copy/integration này. Chỉ merge sau review head sửa và kiểm thread/status thực tế.
