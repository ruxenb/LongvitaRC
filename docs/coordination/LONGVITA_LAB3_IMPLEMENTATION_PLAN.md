# Longvita - kế hoạch triển khai thống nhất Assignment / Lab 3

Cập nhật **02/11/2026**. Đọc cùng [phân tích hiện trạng](LONGVITA_LAB3_FINAL_ANALYSIS.md) và [QA/evidence plan](LONGVITA_LAB3_QA_AND_EVIDENCE_PLAN.md).

**Lab 3 = Assignment, một sản phẩm Longvita kế thừa Lab 2.** Dùng repo `C:/Users/phamv/OneDrive/Desktop/PRM/Assignment/LongvitaRC`, không tiếp tục code ở workspace Restored hoặc repo Lab 2 cũ. Bản chuẩn Markdown tại `docs/coordination/`; bản cùng tên ngoài Assignment đồng bộ theo bản chuẩn.

## 1. Cách dùng kế hoạch với leader/team

- `docs/tasks/danh-sach-task-full.md` và bốn file `task-*.md` giữ **112 task IDs và ownership hiện có**. Không thêm một backlog P01-P30 cạnh tranh với leader.
- Tài liệu này gom các task thành đầu ra tích hợp, giải thích technical gate và bổ sung khoảng trống từ Guide v5/code review.
- Mọi thay đổi contract, schema, params hoặc ownership đi qua PR và cập nhật tài liệu liên quan. Không sửa code người khác để đủ checklist mà không giữ API đã thống nhất.
- Bảng trạng thái hiện chưa đáng dùng để tính % vì đều Chưa bắt đầu dù code skeleton đã tồn tại. Owner cập nhật bằng commit/evidence, không chỉ tick theo file.
- Lịch Tuần 1-4 trong repo là lịch tương đối của leader, chưa có ngày bắt đầu/deadline được xác nhận trong cuộc trao đổi này. Giữ milestone M1-M9, không tự gán ngày.

## 2. Trách nhiệm thực tế và điểm phối hợp

| Owner từ repo | Chủ trì | Bàn giao cho người khác |
|---|---|---|
| Thái An, 29 tasks | Setup ARTEMIS/model, event plan, Analytics/Crashlytics/RC, tổng hợp test/review công cụ | Event schema + RC contract + client thật + raw run evidence |
| Charlie, 29 tasks | DS/widgets, Firebase config/Auth/Storage/FCM/PDF, Sign-in/Profile/demo | Widgets/API auth/session, export state, notification route events |
| Hoàng, 26 tasks | DataService/models, preferences/plans/ingredients/shopping/references, S01-S10/states | Active plan/revision cho PDF; UI actions/events; fixtures nghiệp vụ |
| Thắng, 28 tasks | Architecture/DI/router, docs/truy vết, tích hợp/freeze và bộ nộp | Interface quyết định, routing/session lifecycle, review scope/evidence |

Mỗi owner chịu trách nhiệm unit/widget checks thích hợp và evidence phần mình, không đẩy mọi kiểm thử/report cho một người. Người dùng đã xác nhận chính là **Charlie**: triển khai theo `task-charlie.md` với 29 task và hướng dẫn Charlie trong index điều phối, thay cho phân công gợi ý cũ ngày 30/10.

## 3. Technical gates ưu tiên ngay

| Gate | Công việc cụ thể | Owner/task hiện có | Điều kiện vượt gate |
|---|---|---|---|
| G0 - sự thật về evidence | Gỡ nhãn pass/commit mẫu khỏi kết quả; cấm Dummy SUCCESS | Thái An/Thắng, S6-2/S6-3/S7-4 | Thiếu SDK/device phải báo lỗi setup; docs Planned/template; không claim 3/3 |
| G1 - môi trường/backend | Chốt applicationId, Console/SHA, Google services + Crashlytics Gradle; Firebase bootstrap có error state | Charlie + Thắng, S0-4/S3-1/S3-2/S2-2 | Cold-start trên Android có project đúng, login test được; init lỗi không thành trạng thái giả ready |
| G2 - data/rules | Schema/users/recipes/meal_plans, source catalog, preferences/shopping/references; ownership/transitions | Hoàng + Thắng, S1-2/S4-1/S2-1 | Schema/query/index thống nhất, no sample fallback runtime; rules checks có allowed/denied |
| G3 - design/state | Theme/tokens/fonts + chín component + state conventions và routes | Charlie/Hoàng/Thắng, S2-3/S2-4/S3-6 | Screenshot app đúng baseline, screen không đọc service trực tiếp; VM sở hữu state |
| G4 - tính năng thật | Flow 1 rồi Flow 2/3, retry/Undo/reopen/session isolation | Hoàng + owners, S4-2..S4-7 | End-to-end trên dữ liệu thật, không hard-code persona/weight để thay form |
| G5 - sáu công nghệ | PDF upload/FCM + events/crash/config và failure feedback | Charlie/Thái An, S4-10..S5-10 | Chứng minh app + Console, không chỉ có wrapper/getter |
| G6 - kiểm chứng | ARTEMIS/semantics/PR review/fix, role/rules tests | Thái An + cả nhóm, S6-*/S7-* | Raw results >=3 runs, exploratory, decisions và fix links thật |

G0/G1 là ưu tiên đầu tiên, song song chuẩn hóa tokens/catalog. Không mở thêm module sức khỏe/chấm điểm chỉ để dùng Remote Config. Chỉ phần upload phụ thuộc quyết định billing/Storage; không chặn mọi việc vì DEC-01.

## 4. Crosswalk từ công việc cần làm sang task leader

| Đầu ra tích hợp | IDs được giữ nguyên | Nghiệm thu cụ thể |
|---|---|---|
| Baseline/scope/toolchain | S0-1/S0-2/S0-3-*/S0-5/S0-6 | Repo/nhóm đã có; SDK thực vs README rõ; Figma/hand off/source truy cập được; test accounts không lộ key |
| Traceability + UI trong code | S1-1/S1-5/S4-17 | Từng S01-S10/Sign-in/Profile -> route/VM/service/data/test/evidence; thiết kế bổ sung/cải tiến trong code, ghi khác biệt ở repo; không cập nhật Figma theo quyết định user/team 02/11 |
| Data contract + kiến trúc | S1-2/S2-1/S2-2/S2-5/S4-1 | Models/serialization/query/index/ownership; API error contract; không cam kết migration % chưa đo |
| Design system | S2-3/S2-4 | AppColors/AppTheme đúng olive/cream/fonts Lab 2; đủ Nav/AppBar/Dialog ngoài components đang có; variants/states |
| Firebase Auth + routing | S3-1..S3-6/S3-9 | Login/cancel/session restore/denied role khi áp dụng/logout; xóa session UI/cache/subscriptions, giữ cloud data |
| Flow 1 | S4-2/S4-3/S4-4/S4-7 | Form thật -> catalog -> 7 ngày đúng số bữa -> save/reopen; generation/empty/save errors có recovery |
| Flow 2 | S4-5/S4-7 | Aggregation bằng ID/unit; edit positive finite quantity; delete/Undo; checked lưu theo list, list mới unchecked |
| Flow 3 | S4-6/S4-7 | Recipe/reference -> alternative -> confirm; hủy/lỗi giữ món cũ; totals và list revision được xử lý |
| PDF/Storage | S3-7/S4-10/S4-11/S4-15 | File đúng plan/revision, local retain, upload progress/URL/owner rules, stable retry ID |
| FCM/Profile | S4-12/S4-13/S4-14/S4-15 | Ba lifecycle states, permission denied, persistent inbox/dedup, tap auth-aware target |
| Analytics | S1-3/S5-1..S5-5 | >=7 events, actual count/outcome; tên/params thống nhất plan+code, DebugView từng event |
| Crashlytics | S5-6/S5-7 | Flutter handlers + non-fatal thật + test crash, UID/custom key và clear session |
| Remote Config | S3-8/S5-8/S5-9 | Hai params gây hành vi thật, defaults/fetch/cache/error, cùng build trước/sau |
| Fidelity/a11y/test | S4-8/S4-9/S4-16/S4-17/S5-10/S6-* | 360/412/TalkBack/errors, ARTEMIS thật >=3 runs/case và raw evidence |
| Review/đóng gói | S7-*/S8-*/S9-* | PR output/decisions/fixes, report/slides/video có evidence và link truy cập |

## 5. Contracts phải chốt trước khi nhiều người code song song

### A. MVVM/DI

Giữ Provider + ChangeNotifier + ViewState đã có. Không đổi sang Riverpod/BLoC chỉ vì sở thích của một người. UI gửi event tới VM; VM gọi services qua interface đã thống nhất; SDK nằm trong `services/` hoặc `firebase/`, không trong screen.

Hiện có ba interface Auth/Data/Report. Bổ sung seam test được cho Storage/Messaging/Analytics/Crash/RC khi cần; không bắt test phải khởi tạo singleton Firebase thật. Constructor injection và state consistency quan trọng hơn tạo thêm nhiều tầng không dùng.

`HomeScreen` ở baseline audit là smoke/integration dashboard: dùng mẫu S01 làm tham chiếu, cải thiện UI trực tiếp trong code và di chuyển demo actions vào Profile/demo area. Theo quyết định user/team 02/11, không sửa/đồng bộ Figma, không bắt audit live lại từng thay đổi; ghi khác biệt/lý do/ảnh và review trong repo, code/runtime được chấp nhận là baseline hiện hành. Announcements stream qua VM, không dựng data-fetch/service calls trong build.

### B. Schema kế thừa repo

Giữ collection names đã có **`users`, `recipes`, `meal_plans`, `announcements`**. Bản kế hoạch cũ đề xuất `users/{uid}/mealPlans` không được áp trực tiếp vì sẽ lệch contract team.

| Data | Hướng thống nhất / cần bổ sung |
|---|---|
| `users/{uid}` | Owner profile/preferences theo schema chốt; default role=user; không self-elevation; timestamp kiểu thống nhất |
| `recipes/{id}` | Catalog có nguồn, ingredients ID/amount/unit, instructions, category, image/source refs; published/archive khi web management dùng |
| `meal_plans/{id}` | UID bất biến; 7 ngày/meal slots; stable ID/revision; createdAt; status theo enum đã chốt |
| Shopping | Thống nhất `shopping_lists/{id}` hoặc subcollection trước khi code; uid, planId/revision, items/overrides/checked; thêm rules/query |
| Book references | Chốt collection/schema và citation edition/chapter/page; không dùng label nguồn sách thay reference thật |
| Export metadata | Chốt collection/path với uid, planId/revision, exportId, fileSize/local/upload state; dùng cho policy Final |
| Notifications | FCM history theo user/messageId khác `announcements` staff viết; tách rõ quy tắc dedup/read/route |

Map DateTime/Firestore Timestamp cần serialization rõ, không âm thầm parse lỗi thành DateTime.now làm lệch thứ tự Saved Plans. Quyết định lưu ISO hay Timestamp là của schema chung, không đổi riêng lẻ một service.

### C. State, lỗi và transaction

- Generate: catalog rỗng -> empty có CTA, không fallback data hard-coded trong bản nộp; input lấy từ S02; đủ số bữa, không chỉ tạo list tối đa hai món.
- Save: stable ID trước write/retry, chặn double-submit; success chỉ sau điều kiện đã cam kết; không biến pending sync thành cloud confirmed.
- Replace: confirm mới mutate/persist; lỗi/cancel giữ món cũ; plan revision mới kéo theo ingredient recalculation và shopping-list policy.
- Ingredient: dùng ID/unit tương thích; quantity phải finite và >0; không cộng ml với g nếu không có conversion đã được xác nhận; Undo khôi phục item/value.
- Session: logout clear activePlan/ingredients/checked/messages/export URLs/tác vụ theo user và Analytics/Crashlytics identity; dừng listener, không xóa cloud data.
- Errors: auth cancelled khác network/profile read denied; service không trả null cho mọi error rồi UI nói người dùng đã hủy. Logging failure không che failure gốc.
- Clinical/nutrition rules: chỉ code rule đã truy nguồn; không thêm ratio/calo clamps hoặc longevity score chưa có design/content được duyệt.

### D. Design và nguồn assets

S01 `103:5`, S02 `103:83`, S03 `103:125`, S04 `103:160`, S05 `108:244`, S06 `108:285`, S07 `106:189`, S08 `106:235`, S09 `108:332`, S10 `103:269` là node map đã kiểm tra 30/10. Kiểm tra node/value mới nhất khi triển khai; chưa có live audit ngày 02/11.

Baseline Light: cream `#F6F1E7`, action `#476429`, text `#2F3B2A`; Fraunces/Newsreader/Quicksand theo styles. Dùng semantic token để thể hiện các màu khác, không tự thay toàn bộ bằng Material palette hoặc Inter. Chốt radius/component binding đang duyệt nếu tài liệu snapshot còn khác.

Dựng ở 360/412; từ 600dp căn giữa max-width 600 cho mobile layout theo handoff. Web admin cần wide-layout spec dùng cùng DS; không coi kéo rộng mobile là đã xong web. Body >=14sp, hit target >=48dp, no color-only cues, keyboard/text scale/semantics thực.

## 6. Sáu dịch vụ Firebase: tích hợp tối thiểu đúng công nghệ

| Service | API/luồng cần hoàn thiện trong repo | Demo và failure acceptance |
|---|---|---|
| Auth | Google Sign-In + SHA + Firebase credential -> users profile -> auth stream/router | Login/cancel/offline/logout/restore; không lẫn profile read lỗi với cancel |
| Storage | Report bytes -> local file/export ID -> owner path upload -> progress -> URL/metadata | PDF thực; denied/network/hủy theo khả năng UI; retry không mất local file hoặc tạo trùng |
| FCM | Permission + foreground/background handling + initial message cold start -> route intent -> inbox | Ba states; token/device ghi trong evidence phù hợp, không public credential; deny vẫn dùng app |
| Analytics | S5-1 contract -> service methods/events từ VM -> DebugView | >=7 actual events; actual fish count thay số 2 hard-coded; không tên/email/weight profile không cần thiết |
| Crashlytics | Flutter/async handlers + handled errors + UID/custom key + demo crash | Dashboard có hai loại lỗi, app lỗi nghiệp vụ vẫn thông báo; demo crash không nằm flow thường |
| RC | Defaults -> fetch/activate -> observable VM state -> feature/result list | >=2 params đổi hành vi; cache interval giải thích; no rebuild; offline dùng active/default |

Giữ key `max_meal_recommendations` của team và nối thật vào S06 result limit. Key thứ hai có thể là `banner_announcement` đổi helper/banner tại vị trí đã ghi deviation, hoặc feature flag phục vụ thiết kế đã chốt. `enable_longevity_score`/`daily_protein_target_ratio` chỉ có getter chưa đủ; không xây thêm score/đổi quy tắc dinh dưỡng chỉ để chứng minh RC. Chốt cặp key trước thay code/defaults/test.

Event names ưu tiên hợp nhất với plan team: `login`, `logout`, `generate_meal_plan`, `save_meal_plan`, `view_recipe_details`, `view_book_reference`, `replace_meal`, `toggle_shopping_item`, `export_report`, `upload_report` và event khác nếu có flow thật. Đây là candidate contract, Thái An chốt trigger/types/outcome trước instrumentation; không tạo search UI chỉ vì ví dụ Analytics có search.

Không viết backend gửi FCM đặc quyền trong Flutter. Console test đủ cho bước chứng minh core; announcement Firestore realtime và OS push là hai cơ chế khác nhau. Terminated test không dùng Android force-stop; message route phải chờ auth/router và xử lý target không tồn tại.

## 7. Toàn hệ thống trong cùng Assignment

Các mã SYS là **workstreams bổ sung từ Final PDF**, chưa phải task leader đã giao và không cộng vào số 112. Thái An/Thắng điều phối owner và schedule; không bỏ scope hoặc tự ép Charlie/Hoàng nhận toàn bộ.

| Workstream | Nguồn | Đầu ra tích hợp |
|---|---|---|
| SYS-01 Shared core/clients | Final tr.3-4 | packages/core models/Firestore/theme/widgets; mobile và web dùng chung; MVVM hai client |
| SYS-02 Security | Final tr.4,8-9 | users.role, deny default, schema/status transitions, no self-role change; emulator allowed/denied mỗi role/collection; App Check |
| SYS-03 Web admin | Final tr.4-5 | Sign-in role rejection; recipe management list/search/create/edit/archive; review queue lý do; >=3 aggregation metrics + chart; announcement form; Hosting URL |
| SYS-04 Cross-role/inbox | Final tr.2,6,9 | Mobile submit -> staff approved/rejected/reason -> mobile realtime/inbox; sequence/write/rule/UI mapping; đo latency; deployed 3 lần |
| SYS-05 Gemini | Final tr.5 | AI Logic level 2 JSON -> Dart -> user edits/confirms; App Check; RC model/prompt/on-off; fallback; ai_request/ai_result_accepted/ai_error; 3 IO thực + 1 failure |
| SYS-06 System evidence | Final tr.6-8 | AI/mobile E2E + rules/web checklist + >=3 new review findings/decisions; web URL, system demo và report theo scope chốt |

Giữ `draft -> submitted -> approved/rejected` từ model như đề xuất workflow, nhưng enums, quyền sửa và review reason phải chốt bằng schema/rules trước ghi dữ liệu. Không gắn nhãn staff là chuyên gia y khoa nếu đề tài chưa có vai trò đó.

AI gợi ý tại S06 dựa trên catalog IDs/tags không chứa profile cá nhân; parse/validate output trước hiển thị, user xác nhận và sửa được; tắt/lỗi vẫn thay món bằng bộ lọc xác định. Đây là triển khai hỗ trợ flow cũ, không chuyển Assignment sang chatbot.

Storage/no-Storage và report/video khác khoảng phải theo DEC-01/02 trong file phân tích. Trong lúc chờ quyết định vẫn giữ hai adapters local/share và upload tách rời; không coi Guide mới đã miễn Storage hoặc Final PDF đã bị hủy.

## 8. Mốc M1-M9 theo leader và gate kỹ thuật

| Mốc hiện có | Nghiệm thu được làm rõ | Không được suy ra |
|---|---|---|
| M1 Nền móng | Scope/traceability/interfaces/theme/bootstrap, app ID/config, catalog/test account; G0-G3 | Skeleton commit = toàn M1 đã verified |
| M2 Auth | Login/cancel/restore/logout + routes + owner rules + widgets thật | AuthService file = Google Console đã chạy |
| M3 Flow đầu | S01-S04-S10 bằng data thật; state/retry/save/reopen; event plan khớp | Dashboard generate mẫu = Flow 1 |
| M4 Tính năng | Đủ ba flow + six Firebase behaviours/failures + UI fidelity | Wrapper/getter/in-memory list = đã tích hợp |
| M5 Freeze | Thắng chốt RC build/tag sau checklist; nếu SYS áp dụng thì freeze phải bao gồm scope đó hoặc có integration freeze riêng ghi rõ | Freeze rồi không được sửa lỗi/blocker |
| M6 Test | Real ARTEMIS, >=3 runs/case, exploratory, evidence; SYS tests khi scope đó tích hợp | Dummy/client sample SUCCESS = test pass |
| M7 Review | >=5 findings/2 kinds, >=3 accepted fixes; SYS code có >=3 new findings theo Final | Template CR rows = findings đã xác nhận |
| M8 Hồ sơ | Report/slides/video tổng hợp evidence thật, đủ nội dung công nghệ và UI | Đếm trang đúng = nội dung đạt |
| M9 Nộp | Links, project ID, instructions, contribution/AI disclosure và scope quyết định đầy đủ | Các link placeholders đã truy cập được |

Theo dõi SYS-01..06 song song trong cùng bảng điều phối; chỉ đánh dấu hoàn tất Assignment khi scope hệ thống yêu cầu đã đóng hoặc có quyết định giảng viên điều chỉnh, không kết luận mobile M4 là xong toàn hệ thống.

## 9. Thứ tự hành động tiếp theo

1. Thái An/Thắng đọc bộ Markdown mới, đóng DEC-01..04 và xác nhận applicationId/event/RC/schema contracts.
2. Charlie/Thắng hoàn tất Firebase bootstrap/config/SHA; Thái An thay client mẫu bằng ARTEMIS thật và pin commit; không để báo pass giả.
3. Charlie đối chiếu tokens + chín widgets, Hoàng seed catalog có nguồn và xử lý states; hoàn thiện Flow 1 thật trước Flow 2/3.
4. Mỗi owner vừa tích hợp vừa lưu app/Console/failure evidence; sau đó formal ARTEMIS/review/fix.
5. Chốt owner/contract SYS workstreams và tích hợp trước system freeze/đóng gói theo scope thống nhất.

Không có hành động tạo tài khoản, tăng billing, deploy, publish hoặc nộp bài nào đã được thực hiện trong lượt cập nhật tài liệu. Chưa sửa code Dart/Python/rules để che các gap được phát hiện; chúng là tickets triển khai tiếp theo.
