# Bàn giao sau PM review — session, tích hợp, FCM, PDF

Trả lời [PM review](../PM_REVIEW_CHARLIE_20261102.md), 02/11/2026. **Trạng thái đề nghị: Ready for PM review.** Chưa Accepted. Đã push lên `feature/charlie-auth-01` theo quyết định của Charlie, **trước khi Codex re-review**; chưa có PR.

## 1. Kết quả kiểm tra trên bản đã tích hợp

Chạy ở `40e47a1`, đã gồm `origin/main` (`614e731`). Log: `evidence/review/CHARLIE-INTEGRATION-20261102/`.

| Check | Kết quả |
|---|---|
| `flutter analyze --no-pub` | No issues found |
| `flutter test --no-pub test` | **121/121 pass** (69 cũ, 52 mới) |
| `npm run test:rules` | **41/41 pass**, emulator `demo-longvita` |
| `flutter build apk --debug` | Thành công |
| Chạy thật: mở lại, đăng xuất, đăng nhập lại | Đạt trên `LocalMate_API_35`, project thật, rules đã sửa. Không có `PERMISSION_DENIED`, không crash. Log có `FLTFireMsgService ... started`. Ảnh ở thư mục `android/` |

Lần chạy rules đầu tiên báo `port taken` do tiến trình emulator cũ còn sót, nên **không tính**; số trên là lần chạy lại.

## 2. Ưu tiên 1 — S3-5 (PM-S3-5-01, PM-S3-5-02)

Commit `9d76623`. **Nguyên nhân:** `clearSession()` chỉ xóa state tại thời điểm đó, không hủy được Future đang chạy.

**Cách sửa:** thêm `SessionEpoch` trong `session_scoped.dart`. Tác vụ ghi lại epoch khi bắt đầu, `clearSession()` tăng epoch, và mọi bước sau `await` bỏ qua kết quả nếu epoch đã đổi. Cách này phủ cả trường hợp A đăng xuất rồi A đăng nhập lại.

| Phần | Hành vi sau khi sửa |
|---|---|
| `ProfileViewModel` | Progress, URL, state, event và lỗi muộn đều bị bỏ qua. Đăng xuất trong lúc sinh PDF thì không bắt đầu upload |
| `MealPlanViewModel` | Generate, save, submit và fetch đều có guard. Save/submit muộn trả `false` |
| `IngredientViewModel` | Không cần sửa: các hàm đều đồng bộ, không có `await` |

**Kiểm chứng:** `test/auth/session_race_test.dart` có 21 ca khi sửa, gồm hai ca của PM, progress/error muộn, và lặp cho cả chuyển sang B lẫn đăng nhập lại A. Trên code cũ 16 ca fail (`evidence/review/CHARLIE-S3-5-FIX/before-fix.txt`), sau khi sửa tất cả pass (`after-fix.txt`). Không sửa expected.

**Quyết định cần review:**
- Lỗi muộn của phiên cũ **không** gửi Crashlytics, vì user ID lúc đó là của phiên mới. Đổi lại là mất log của lỗi này.
- Upload của A vẫn chạy tiếp trên cloud sau khi đăng xuất, vì `StorageService` chưa có cancel (S4-11). Chỉ state local được cách ly.

**Owner:** `MealPlanViewModel` thuộc Hoàng. Bản sửa chỉ thêm guard, cần Hoàng duyệt. **Chưa trao đổi được với Hoàng**; Charlie cần gửi.

## 3. Ưu tiên 2 — Docs và tích hợp

**Docs, commit riêng `e829c3c`:** 19 file Markdown/JSON liệt kê tường minh và evidence của PM. Sửa nội dung rất ít: đổi câu "code hiện là skeleton" thành audit tại `ae35f07` (README, architecture), đổi câu về widget test (test-plan), thêm project ID vào README (S0-4).

**Merge `cd82637`:** tự gộp được trừ `docs/code-review.md`. Cách gộp file đó:

| Nội dung | Giữ từ |
|---|---|
| Bảng PR khung `CR-xx`, mẫu `EX-xx`, vai trò Leader | Upstream |
| Cảnh báo "findings đã xác minh: 0", không tính bảng mẫu | Local, đổi tham chiếu từ `SAMPLE-CR` sang `EX-xx` |
| Mục tool, ARTEMIS chưa pin SHA | Local |
| Bảng `SAMPLE-CR-xx` | **Bỏ**, vì trùng vai trò với `EX-xx` |

Thêm một câu khai báo: Charlie dùng Codex và Claude Code ngày 02/11. **Codex và Charlie cần review file này.** Bản merge riêng chưa biên dịch được; commit kế tiếp sửa.

**Analytics, commit `9ecc806`.** Đúng 10 lỗi như báo cáo trước:

| Lời gọi | Cách xử lý | Trạng thái |
|---|---|---|
| `logLogout()` | Dùng helper mới | Xong, S5-4 |
| `logExportReport` | `fileSizeKb` từ byte PDF thật, làm tròn lên. `hasShoppingList: 0` đúng với PDF hiện tại | Xong, S5-4. Đổi khi PDF có danh sách mua sắm |
| `logGenerateMealPlan` | Nhóm tuổi, số bữa, số bữa cá lấy từ dữ liệu thật | **Cần Hoàng/Thái An duyệt** |
| `eatingWindowHours` | **Chưa có nguồn dữ liệu.** Thêm tham số tùy chọn; không có giá trị thì **không gửi event** thay vì dùng số giả | **Hệ quả:** `generate_meal_plan` chưa được gửi từ `home_screen` cho đến khi có S02 |

Lỗi biên dịch này vẫn còn trên `origin/main` cho đến khi nhánh này được merge hoặc Thái An tự sửa.

## 4. Ưu tiên 3 — FCM và PDF

**FCM, commit `7a9fa8c` (S4-12):** contract ở [FCM-CONTRACT-PROPOSAL.md](FCM-CONTRACT-PROPOSAL.md). Đã có parser, chống trùng, inbox theo user, đủ 4 callback sau một gateway; 18 test. Chưa có: router, history bền, token theo UID, **evidence push thật**. Test dùng gateway giả.

**PDF, commit `40e47a1` (S4-10):** tiếng Việt đủ dấu, Regular và Bold, mỗi ngày nằm trọn một trang, `LocalReportStore` lưu theo UID; 10 test. Đã render và xem ảnh: `evidence/pdf/S4-10-fixture-20261102/`.

| Giới hạn | Chi tiết |
|---|---|
| **Dùng fixture** | Chưa chứng minh PDF đúng plan đang xem; chờ S4-3 |
| **Chưa nối vào luồng export** | `LocalReportStore` chưa được `ProfileViewModel` gọi, chưa có export ID ổn định, chưa mở/chia sẻ |
| **Font khác UI** | Dùng Roboto (Apache 2.0, lấy từ Flutter SDK) thay vì Quicksand, vì thư viện `pdf` chỉ đọc mức mặc định của font biến thiên. Thiết kế PDF chưa có frame; **cần Hoàng/Charlie đồng ý** |
| **Lớp văn bản** | Hiển thị đúng khoảng trắng, nhưng trích xuất text có chỗ dính chữ (`Thứ Hai` thành `ThứHai`), nên tìm kiếm/copy trong PDF có thể sai |
| **Chưa chạy trên Android** | Test đọc font từ đĩa; `rootBundle` trên thiết bị chưa được kiểm |

## 5. Việc chưa làm và cần người khác

| Việc | Ai |
|---|---|
| Duyệt guard và lời gọi generate trong `MealPlanViewModel` | Hoàng, Thái An |
| Review `docs/code-review.md` và commit docs `e829c3c` (đã push) | Codex, Charlie |
| Chốt 3 câu hỏi FCM | Thắng, Hoàng, Thái An |
| DEC-01, AUD-11 B1–B5, A1/A2/A3/A5/A9, SHA và lời mời | Như PM review mục 6 |

`evidence/ui/PM-REVIEW-20261102/` (ảnh QA của PM, 1,9 MB) chưa commit vì review không liên kết tới; để PM quyết định.

Dev tracker: [CHARLIE-PROGRESS](CHARLIE-PROGRESS-20261102.md).
