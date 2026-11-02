# PM review Charlie — UI/Auth, integration và bước kế tiếp

> **Re-review mới nhất:** PM-S3-5-01/02 đã **Closed — local regression verified** tại `914508c`; PM-FCM-01 cũng **Closed — verified** sau fix `2d547c7`, PM kiểm HEAD `f1f397e` với 133 tests/reproduction gốc pass. Xem [mục 7 của re-review](PM_REREVIEW_914508c.md#7-xác-nhận-bản-sửa-pm-fcm-01--2d547c7--head-f1f397e). Nội dung dưới giữ làm lịch sử tại `d17383c`, không dùng trạng thái chưa merge/Changes requested cũ làm snapshot hiện tại.

Ngày **02/11/2026**. Người review: **Codex**. Căn cứ: [báo cáo tiến độ Dev](dev-reports/CHARLIE-PROGRESS-20261102.md), [Auth report](dev-reports/CHARLIE-AUTH-01.md), source và các kiểm chứng local bên dưới. Đây là review tập trung Auth/session và dependency tích hợp, không phải nghiệm thu visual toàn UI hay toàn Assignment.

**Kết luận: Changes requested cho S3-5/session isolation.** Hai ca tác vụ hoàn thành sau đổi tài khoản tái hiện lỗi; các checks hiện có vẫn pass. Chưa chuyển các gói sang Accepted. Giữ các kết quả Dev đã đạt với giới hạn tương ứng, không yêu cầu làm lại UI/Auth từ đầu.

## 1. Trạng thái đã đối chiếu

| Hạng mục | Kết quả PM kiểm tra |
|---|---|
| Local | `feature/charlie-auth-01`, HEAD `d17383c7bdacb4236e322cdff1414ea244280da7` |
| Nhánh GitHub | Ref `refs/heads/feature/charlie-auth-01` khớp `d17383c`; đã push được xác nhận qua GitHub connector |
| Main GitHub | `614e7319c84b5374e0373a2b82b669aeabac0b11`, chưa được tích hợp vào nhánh Charlie |
| Leadership hiện hành | Thái An: Team Leader/QA Lead; Thắng: Technical Architect/Co-Lead theo `main` |
| Source | UI/Auth/Firebase/rules đã được commit, khác thời điểm audit skeleton `ae35f07` |
| Docs chưa commit | Sáu tracked Markdown còn sửa; năm file trong số đó cũng bị upstream sửa; root instructions và bộ coordination vẫn có untracked files |
| Auth cloud | Có ảnh signed-in/out/cancel và Console tại `evidence/auth/S3-9-20261102/`; báo cáo Dev ghi Google/SHA Charlie/init/restore/logout đã chạy thật. PM không đăng nhập Console hoặc chạy lại Google Sign-in trong lượt này |
| Rules live | Dev báo đã publish AUD-11 theo duyệt Charlie. PM đọc source và chạy lại emulator; không tự publish lại hoặc coi emulator là xác nhận rules live |

Hai file khôi phục bộ nhớ đã hủy theo yêu cầu trước vẫn không được tạo lại. Không đổi Dart/rules/Gradle production, không commit/push/merge trong lượt PM review này.

## 2. Checks PM đã chạy lại

| Check | Kết quả | Giới hạn / evidence |
|---|---|---|
| `flutter analyze --no-pub` | **Pass — No issues found**, 54.0 giây | Nhánh Charlie ở `d17383c`, không phải main hoặc bản đã merge |
| `flutter test --no-pub --reporter expanded test/auth test/qa test/widget_test.dart` | **69/69 pass** | [Log regression](../../evidence/review/PM-CHARLIE-20261102/flutter-regression.txt). QA_TASK=`PM-REVIEW-20261102`, QA_RUN_ID=`regression-d17383c`, tránh ghi đè ảnh Dev |
| `npm run test:rules` trong `firebase/` | **41/41 pass**, 14 suites, 0 fail | Firestore emulator `demo-longvita`; lệnh exit 0. Không dùng Firebase project thật, không xác minh đầy đủ SYS security chỉ từ số test |
| Hai ca race bổ sung | **0/2 pass — cả hai fail như mô tả mục 3** | [Reproduction source](../../evidence/review/PM-CHARLIE-20261102/session-race-repro.dart.txt), [raw result](../../evidence/review/PM-CHARLIE-20261102/session-race-results.txt) |

Hai ca bổ sung chạy tách khỏi 69 tests hiện có, dùng ViewModels thật và các fake services sẵn có, có Completer giữ tác vụ đang chạy qua lần logout/login. File runner tạm trong `test/` đã xóa sau kiểm tra; bản reproduction còn ở evidence dưới đuôi `.txt`, không đưa hai test đang fail vào suite production của Claude. Dev cần đưa regression tests phù hợp vào suite khi sửa.

## 3. Findings cần sửa trước nghiệm thu S3-5

### PM-S3-5-01 / P1 — Upload cũ ghi lại URL vào Profile của phiên mới

- **Vị trí:** `lib/viewmodels/profile_viewmodel.dart:54` và `:67–118`; đặc biệt completion tại `:100–103`.
- **Tái hiện:** A login -> bắt đầu export/upload -> giữ response upload -> A logout, B login -> hoàn thành upload của A.
- **Actual:** `profile.user.uid` là B nhưng `lastUploadedUrl` trở lại `https://storage.test/reports/uid-a/late.pdf` và export state thành success của tác vụ A. `clearSession()` chỉ xóa state tại thời điểm logout, không vô hiệu hóa completion/progress/error cũ.
- **Expected:** URL/progress/state của A không xuất hiện trong phiên B; callback cũ không phát event như thể tác vụ thuộc phiên hiện tại. Nếu logout trước bước upload, không bắt đầu bước kế tiếp dưới phiên mới với context cũ.
- **Phạm vi kết luận:** lỗi cách ly state local đã tái hiện bằng fake upload; không kết luận B đã đọc được file A trên cloud hoặc bypass Storage rules.
- **Dev/owner:** Claude sửa phần Profile của Charlie trong S3-5, giữ contract cho gói PDF/Storage sắp tới.

### PM-S3-5-02 / P1 — Query cũ đưa saved plans của A vào state phiên B

- **Vị trí:** `lib/viewmodels/meal_plan_viewmodel.dart:35` và `:127–145`.
- **Tái hiện:** A bắt đầu `fetchSavedPlans('uid-a')` -> giữ response -> A logout, B login -> hoàn thành response với plans của A.
- **Actual:** state đã được clear thành Idle lúc đổi phiên nhưng sau đó thành `ViewStateSuccess` chứa plans của A. Test session hiện có chỉ đổi account sau khi mọi tác vụ đã xong, nên chưa bắt được trường hợp này.
- **Expected:** response của epoch/UID cũ bị bỏ qua, B không thấy plans A. Rà các đường async generate/save/submit có cùng kiểu ghi state sau await; không giả định một lần clear đã hủy Future đang chạy.
- **Dev/owner:** Hoàng sở hữu MealPlan VM; Charlie phối hợp sửa seam session của S3-5 với Hoàng/Thắng. Không biến yêu cầu này thành rewrite toàn bộ VM hoặc nhận hết feature scope của Hoàng.

**Hướng sửa để Claude lựa chọn:** session UID + generation/epoch hoặc cơ chế cancellation tương đương. Capture context lúc bắt đầu; vô hiệu hóa ở clear/session switch; kiểm tra trước các bước side-effect tiếp theo, khi nhận progress và ở mọi completion/error path có mutate state. Chỉ kiểm tra UID có thể chưa đủ nếu A logout rồi login lại A; phải phủ trường hợp này bằng regression thích hợp. Quyết định kỹ thuật thuộc Dev, không bắt một implementation máy móc.

**Điều kiện đóng:** hai ca trên pass; thêm ca progress/error muộn và logout/login lại cùng UID theo phần bị ảnh hưởng; tests hiện có không regression; báo files/API và phối hợp owner. Không sửa expected để chấp nhận state cũ.

## 4. Tích hợp Analytics/main

Đối chiếu trực tiếp source `origin/main` xác nhận API mới không khớp callers local/nhánh Charlie:

- `logGenerateMealPlan`: `targetAgeGroup`, `mealsPerDay`, `eatingWindowHours`, `fishMealsCount`; MealPlan VM vẫn dùng `targetAge`, `weightKg`, `fishCount`.
- `logExportReport`: `fileSizeKb`, `hasShoppingList`, optional `topic`; Profile VM vẫn dùng `format`.
- Có helper `logLogout()` mới; đây là đổi cách gọi thống nhất, không tự đặt thêm event mới.

Con số **10 lỗi trên main là báo cáo Dev**; PM chưa checkout/chạy analyzer riêng main trong lượt này. Analyzer sạch ở Charlie không chứng minh main sạch hoặc bản merge sẽ sạch. Lỗi build không tự chặn thao tác Git merge, nhưng không được nhận bản tích hợp khi chưa compile/test được.

Thái An/Hoàng phối hợp sửa generate callers/data fields; Charlie sửa export/logout thuộc S5-4. Không thêm số giả cho eating window/fish count/hasShoppingList chỉ để hết compile error. `fileSizeKb` lấy bytes xuất thực theo convention đã chốt. Test fakes/callers phải theo cùng contract; chạy analyzer/tests trên **bản đã tích hợp**, và build Android khi Gradle/plugins thay đổi.

## 5. Docs còn chặn merge — xử lý riêng, bảo toàn nội dung

Năm file giao nhau đã kiểm tra: `README.md`, `docs/architecture.md`, `docs/code-review.md`, `docs/design-traceability.md`, `docs/tasks/README.md`. `docs/test-plan.md` cũng đang sửa nhưng không giao với upstream ở commit này. Các `AGENTS.md`, `CLAUDE.md`, Charlie guide và các file coordination chưa tracked cũng cần được đưa vào kế hoạch bàn giao; bản guide hiện được Dev report link tới nhưng chưa có trên remote nhánh Charlie.

Chuẩn bị một gói docs riêng: đối chiếu **base `ae35f07` / bản local / upstream `614e731`**, giữ policy Figma đóng băng, Lab 3=Assignment, evidence thật và ownership; nhận leadership/event plan/review-template mới của nhóm. Những đoạn nói “skeleton/chưa config/chưa chạy Android” cần ghi là audit lịch sử hoặc thay bằng trạng thái có source.

Sau khi nội dung đã review, lưu docs bằng commit riêng có danh sách files rõ trước merge; không stage cả working tree, không discard/stash/xóa docs để vượt chặn. Báo trước ranh giới giữa commit docs điều phối và commit code của Dev. **Lượt này chưa commit docs hay thực hiện merge**, nên blocker working tree chưa được tuyên bố đã giải quyết.

## 6. Dependency cần team quyết

- **DEC-01:** Storage cần Blaze theo [Firebase FAQ](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024); Final exclusion và Guide upload là xung đột đề cần Thái An chốt cùng giảng viên. Không tự nâng plan hoặc bỏ task upload. Không chặn Auth, chuẩn bị FCM hay PDF local vì quyết định này.
- **A1/A2:** Thắng duyệt Auth interfaces/bootstrap/router; **A3:** Hoàng duyệt session hooks; **A5/DEC-05:** thống nhất UI/ngôn ngữ trong code.
- **AUD-11/B1–B5:** 41 tests pass không chốt chính sách rejected resubmit/self-review/archive/timestamp. Hoàng/Thắng cần quyết định và bổ sung tests khi schema/role policy thay đổi; không tự xem là đã nghiệm thu toàn SYS-02.
- **A9:** hard-coded recipes fallback vẫn tồn tại trong MealPlan VM; Hoàng xử lý bằng data thật/empty/recovery. Không dùng plan demo đã lưu để chứng minh catalog thật.
- **S0-4/S3-2:** email trường/quyền Firebase và SHA của ba thành viên còn lại do Charlie/team cung cấp. Việc mời/project access/SHA là các đầu việc khác nhau; không suy ra Auth chỉ chạy được sau khi từng bạn có quyền Console.

## 7. S4-12 FCM: phần bắt đầu được và phần chờ contract

Không cần đợi DEC-01 hoặc active plan S4-3 để chuẩn bị FCM. Trong khi chờ Thắng/team chốt, Claude có thể lập API/payload proposal, tests parser/dedup/session/invalid target và lifecycle service seams; không bịa route rồi ghi đã tích hợp xong.

Đầu vào cần ghi cụ thể trước nghiệm thu routing/history:

| Contract | Nội dung cần chốt |
|---|---|
| Payload | Loại message/version, message ID, target type/ID, destination params, policy thiếu/sai/không có quyền; không tin tùy ý một route string từ push |
| Router | Thắng cung cấp route intent/handler, thời điểm router ready, pending tap qua auth/profile recovery, fallback khi đích chưa có |
| History | Local theo UID hay Firestore; persist/reopen/read state/retention/dedup. Nếu Firestore: Hoàng/Thắng chốt collection/schema/rules/test trước ghi |
| Session/device | Token refresh/UID binding/logout cleanup; messages hoặc callback của A không vào inbox B, kể cả callback muộn và background/terminated |
| Evidence | Foreground/background/terminated không force-stop, tap target, allow/deny, invalid target, dedup và A/B; Console send là operator-assisted nếu harness chưa tự động gửi |

FCM callbacks cần `onMessage`, `onBackgroundMessage`, `onMessageOpenedApp`, `getInitialMessage`; background không navigate UI trực tiếp. Profile UI và export/inbox migration tiếp tục theo S4-13, phối hợp Hoàng; không viết lại Home của teammate.

## 8. Gói giao lại Claude ngay

**Ưu tiên 1 — sửa S3-5:** đọc findings/proof mục 3, sửa Profile guard và phối hợp Hoàng xử lý MealPlan guard; giao regression/source/log thật. Chưa tự Accepted.

**Ưu tiên 2 — đồng bộ an toàn:** xử lý gói docs riêng và thống nhất fix Analytics API với Thái An/Hoàng; tích hợp khi có phương án giữ cả code và docs, rồi kiểm bản tích hợp. Không đợi thụ động mọi task trong khi các phần độc lập còn làm được.

**Ưu tiên 3 — mở đầu FCM/PDF:** soạn contract FCM đủ các ô mục 7; làm phần service/test độc lập; PDF local có font tiếng Việt có thể dùng fixture test khi chưa có active plan API. Không đánh dấu live FCM hoặc PDF data thật chỉ từ fixture.

Worklog Charlie và phần report Auth có thể ghi dần từ evidence/commit thật. Bảng 7 task “verified, chờ nghiệm thu” trong Dev report là mức tự đánh giá có giới hạn; **S3-5 hiện chuyển sang Changes requested ở PM review**. Các acceptance khác chưa được review đầy đủ không tự đổi thành Accepted chỉ vì suite hiện có pass.
