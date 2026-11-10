# CM-00 / CM-02 — Monorepo và Shared Core

Log public đã lọc đường dẫn máy và bỏ khoảng trắng cuối dòng do Flutter sinh;
log gốc giữ riêng local.

Ngày kiểm: 10/11/2026. Baseline `ea7b888` (PR #25 đã merge).
Code migration: `aadc1ff`, sau scaffold `2c52387`.
Logs được tạo trên working tree từ `2c52387` trong lúc thực hiện migration;
source đã kiểm sau đó được commit nguyên trạng tại `aadc1ff`. Commit
`662373c` chỉ bổ sung evidence. Cả bốn SHA (gồm baseline `ea7b888`) đều có
trong ancestry PR. Các lần kiểm dưới đây thuộc source `aadc1ff`, không phải
một lượt chạy mới sau commit chỉ thêm evidence.
Branch `feature/charlie-shared-core-01`. Yêu cầu gốc:
[`final-task-assignment.md`](../../../docs/tasks/final-task-assignment.md).

## Kết quả theo task

- **CM-00:** commit `2c52387` chuẩn bị ba thư mục/package boundary, map migration
  và đủ evidence `auth`, `rules`, `web`, `cross_role`, `ai`. Mốc này chưa đổi
  runtime. CM-02 tiếp theo mới thực hiện di chuyển đồng bộ.
- **CM-02:** Mobile (`longvita`) và Web (`longvita_admin`) cùng phụ thuộc
  `longvita_core`. Core sở hữu models/serialization, Firestore services
  (DataService, AdminService, report metadata), Analytics/Remote Config,
  theme/tokens Lab 2 và 9 nhóm common widgets. Native adapters, PDF local,
  FCM, Crashlytics, auth/lifecycle của từng client nằm ở client.
- Dart Pub workspace có một lockfile. 102 record dependency giữ nguyên source,
  version và digest; chỉ nhãn direct/transitive thay đổi khi root thành workspace.
  Không nâng package/SDK/Gradle. Web khai báo Cupertino Icons cùng bản cũ để
  giữ asset cho Material controls; bản build cuối không còn cảnh báo thiếu font.
- Hai client có Firebase options riêng, giữ nguyên App ID/project. Android
  package, SHA và native config không đổi; 20 file Android và 11 asset di chuyển
  giữ nguyên byte theo snapshot trước migration.
- Final mặc định vẫn PDF local + Firestore metadata; Storage chỉ demo opt-in
  Emulator. Không đổi schema, rules, role gate, routes hoặc nghiệp vụ.

## Kiểm chứng

| Kiểm tra | Kết quả | Nguồn |
|---|---|---|
| Workspace pub get `--enforce-lockfile` | Pass | `workspace-checks.txt` |
| Analysis Core / Mobile / Web | 3/3 sạch | `workspace-checks.txt` |
| Core tests | 16/16 | `workspace-checks.txt` |
| Mobile tests | 465/465 | `workspace-checks.txt` |
| Web tests (Flutter VM, fake gateways) | 27/27 | `workspace-checks.txt` |
| Tổng Flutter | **508/508** = 505 cũ + 3 mới | Các dòng tổng trong log |
| QA design system + Flow 2 | 44/44 | `ui-targeted.txt`, hai ảnh responsive |
| APK debug | Build được | `build-apk.txt` |
| Web release + Wasm dry run | Build được | `build-web.txt` |
| ARTEMIS harness offline (SDK thật đã ghim) | 67/67 | `artemis-offline-regression.txt` |
| Dependency/config boundary | Pass; 4 fixture sai bị chặn | `boundary-negative-checks.json` |
| Font/giấy phép trong hai bundle | 6/6 asset mỗi client, đúng byte Core | `bundle-verification.json` |
| Native smoke | Cài đè giữ data; COLD start vào Home với phiên cũ | `runtime-smoke.json` |
| Browser release smoke | Sign-in tiếng Việt hiển thị; không console error | `runtime-smoke.json` |

Ba test mới: Core widget chạy chỉ qua facade, giữ action/size/Semantics;
Mobile và Web đều load được TTF/OFL bằng package asset path. Các test cũ được
chuyển owner, không xóa hoặc giảm assertion. `migration-map.json` liệt kê
172 file cũ → mới, gồm 33 file `*_test.dart`. Hai QA host/screenshot helpers
được đổi đường dẫn theo workspace, font expectations dùng family namespace.

`source-preservation.json`: sau loại import và format hai bản bằng cùng SDK,
119/124 Dart file gốc có nội dung còn lại giống hệt. Năm adapter có thay đổi
có chủ đích: Firebase options tách platform; Typography đổi package font/license
path; ví dụ import trong widget barrel; QA font expectation; QA filesystem root.
Web Firebase options là file mới sao chép đúng literal của registration cũ.

`final-invariants.json` và Git diff xác nhận Firestore/Storage rules, data model
và ARTEMIS harness không đổi. Không chạy lại rules suite vì các file đó và
dependency Node không đổi. Không ghi việc giữ evidence cũ thành kết quả mới.

## Tái lập

Tại root, Flutter 3.47.6 / Dart 3.13.5, JDK 21 cho Android:

```powershell
python scripts/check-monorepo.py
.\scripts\check-workspace.ps1 -Build
```

Hoặc chạy từng member theo [README](../../../README.md) và
[migration map](../../../docs/monorepo-migration.md). APK nằm ở
`mobile/build/app/outputs/flutter-apk/app-debug.apk`; Hosting output là
`web/build/web`. Không dùng root `lib/admin_main.dart` hoặc root `flutter run`
sau migration. Chỉ có **một** `pubspec.lock` ở root.

## Giới hạn và bàn giao

- Native smoke chạy AVD Android 15, chưa máy thật; không chạy lại đầy đủ
  sign-in, PDF upload, FCM hay chiến dịch ARTEMIS live. Browser chỉ mở màn
  sign-in từ Web release, không đăng nhập hoặc ghi dữ liệu.
- Web role/cross-role widgets dùng fake như suite gốc; không gọi đây là nghiệm
  thu live CM-06/TV-04. Firebase Hosting, rules, IAM, billing, Firestore dữ liệu
  và Figma không được chỉnh/deploy trong gói này.
- Cảnh báo AGP/Kotlin của plugin đã ghim và Android SDK XML vẫn được giữ trong
  log APK; build thành công, không dùng migration để nâng toolchain ngoài scope.
- AVD và server loopback đã dừng sau kiểm, phiên app được giữ. Raw native XML/log
  có dữ liệu tài khoản chỉ giữ local; public smoke JSON chỉ chứa nhãn an toàn.
- PR #29 đang có sửa Mobile ở đường dẫn root cũ. Khi tích hợp phải áp dụng
  bản đồ old → new và giữ thay đổi nghiệp vụ/UI của owner; không tạo lại `lib/`
  hoặc copy models/theme vào client. Gói này không tự merge PR #29/#30.
- Tài liệu điều phối/tiến độ riêng và script migration một lần chỉ local;
  không thuộc PR. Tổng 29 task Lab 3 không tăng từ hai task Final này.
