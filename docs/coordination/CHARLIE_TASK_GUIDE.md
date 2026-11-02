# Charlie - đọc hiểu task và trình tự triển khai Assignment Longvita

Cập nhật **02/11/2026**. Người dùng xác nhận **mình là Charlie**. Lab 3 chính là Assignment; UI/flows kế thừa Lab 2 đã duyệt.

**Snapshot mới sau bàn giao/push:** [PM review tại d17383c](PM_REVIEW_CHARLIE_20261102.md) ghi analyzer/69 tests/41 rules tests pass và hai lỗi callback muộn qua đổi account; **S3-5: Changes requested**. Xem [progress Dev](dev-reports/CHARLIE-PROGRESS-20261102.md) cho Auth cloud/UI/rules hiện có. Nhánh đang làm `feature/charlie-auth-01`, main `614e731` có API Analytics mới; chưa merge. Thái An là Team Leader/QA Lead, Thắng là Architect/Co-Lead. Các audit source/status trước triển khai bên dưới là lịch sử, không tự suy ra lỗi cũ còn nguyên hay cả nhóm vẫn ở `ae35f07`.

**Quyết định UI mới của user/team:** Figma giữ làm mẫu tham chiếu đóng băng; cải thiện UI trực tiếp trong code, không sửa/đồng bộ Figma, không bắt đọc live lại mỗi thay đổi. Ghi lý do, ảnh actual và review trong repo theo [UI contract](FIGMA_IMPLEMENTATION_CONTRACT.md). Các task nguồn S1-5/S4-17 giữ nguyên IDs/owner nhưng phần làm rõ áp dụng quyết định này. Gói UI-01 đã bàn giao Ready for PM review; mục 8 là audit trước triển khai, không phải kết luận source UI mới vẫn còn các lỗi cũ. Xem [báo cáo Dev](dev-reports/CHARLIE-UI-01.md); chưa Accepted/chưa kiểm chứng Android.

Đã đọc trực tiếp cả tám file GitHub `docs/tasks` tại commit `ae35f07e36cab9ad4843396a1c22d72c247853ea`; remote main vẫn ở commit này khi kiểm tra. Tài liệu này giải thích phân công của leader, không thay thế/đổi owner hoặc tự đánh dấu Done.

## 1. Hiểu sản phẩm trước khi hiểu task

Longvita hỗ trợ người dùng từ kiến thức trong sách tới ba việc cụ thể:

1. **Lập/lưu thực đơn:** S01 -> S02/S03 -> S04 -> S10.
2. **Chuẩn bị đi chợ:** S04 -> S07 -> S08; chỉnh số lượng, Undo và checked persistence.
3. **Tra cứu/thay món:** S04 -> S05 -> S09/S06 -> S04, có nguồn sách và recovery.

Assignment biến các flow thiết kế thành ứng dụng Flutter với dữ liệu thật, các states/lỗi, Firebase và bằng chứng chạy. Sáu công nghệ cần được tích hợp vào các flow và khu demo; không thay mười màn Figma bằng dashboard thử SDK.

Charlie cung cấp nền tảng giao diện và dịch vụ cloud để các flow đó hoạt động. Có widgets/service files trong skeleton chưa đồng nghĩa nhiệm vụ đã xong. Bộ phận hoàn thành phải có contract, behaviour, error handling, test và evidence phù hợp.

## 2. Bản đồ công việc của toàn team

| Người | Chủ trì theo task leader | Sản phẩm bàn giao | Điểm liên quan Charlie |
|---|---|---|---|
| **Thái An** | Setup/điều phối; Analytics, Crashlytics, Remote Config; ARTEMIS/test/review tooling | Event plan/service, RC keys/defaults/refresh, crash actions, client test thật và results | Charlie dùng service/contract này cho Auth/export và Profile, viết test mảng mình; không tự tạo bộ keys/events hoặc test client khác |
| **Charlie** | Design System in Code; Auth, Storage, FCM, PDF; Sign-in/Profile/demo; test/review/evidence mảng mình | Theme/chín widgets, Google auth/session, owner-only export/upload, notifications/history/routes, screens dùng được | Nằm trên đường găng UI/Auth/M2; phải bàn giao sớm để Hoàng/Thắng tích hợp |
| **Hoàng** | Schema/models/DataService/VM; S01-S10/ba flows; states/persistence; Figma/a11y | Catalog thật, preferences/plan/list/reference, dữ liệu đang xem, screen actions/errors | Charlie nhận active plan từ Hoàng để xuất PDF; giao widgets cho Hoàng; Hoàng chủ trì thiết kế bổ sung Sign-in/Profile, Charlie phối hợp |
| **Thắng** | Kiến trúc/interfaces/Provider/routing; docs/truy vết; integration/freeze; tổng hợp bài nộp | Dependency graph/API thống nhất, AuthGate/route stack, release build, report/slides/video tổng | Charlie thống nhất API/auth/routes và reset phiên với Thắng, giao evidence/clip/report phần mình |

### Những điểm chéo không được hiểu thành nhận hết việc

Master giao Charlie **29 task chủ trì và 18 task hỗ trợ**. Bảng dưới liệt kê đủ phần hỗ trợ; đây là quan hệ phối hợp trong 112 task của nhóm, không phải 47 task độc lập do Charlie sở hữu. Phần việc hỗ trợ được cụ thể hóa từ mô tả master, không chuyển owner.

| Task hỗ trợ | Owner theo leader | Charlie cần đóng góp / bàn giao |
|---|---|---|
| **S1-5** | Hoàng | Phối hợp yêu cầu/layout/states Sign-in/Profile theo DS và nhu cầu Auth/export/inbox/demo; chốt qua mô tả/preview code, không tạo/sửa Figma |
| **S2-1** | Thắng | Chốt signatures/outcomes Auth/Storage/Messaging/Report, tên VM, DI và session seams trước tích hợp |
| **S3-6** | Thắng | Cung cấp auth stream/status; phối hợp login/cancel/restore/logout, Back và pending notification route |
| **S4-3** | Hoàng | Chốt active plan/revision và đầu vào ReportService; xác minh PDF dùng đúng dữ liệu đang xem |
| **S4-16** | Hoàng | Rà common widgets và màn Charlie ở 360/412dp, text scaling, contrast, hit target và semantics; giao evidence/fix phần mình |
| **S4-17** | Hoàng | Giao mapping reference/app, screenshots và khác biệt/cải tiến phần Charlie để tổng hợp traceability trong repo; không cập nhật Figma |
| **S5-5** | Thái An | Kích hoạt login/logout/export đúng event contract; cung cấp thao tác, params và DebugView evidence phần mình |
| **S5-9** | Thái An | Dựng vùng RC/refresh trên Profile, hỗ trợ chụp before/after cùng build; không tự đổi keys/defaults |
| **S5-10** | Thắng | Thử cancel/network/denied/init failure của Auth/Storage/FCM và vùng tích hợp Profile; ghi kết quả, sửa phần mình |
| **S6-3** | Thái An | Bổ sung preconditions/instructions/assertions Auth/export/push; làm rõ permission dialog ảnh hưởng TC-01 |
| **S6-9** | Thái An | Hỗ trợ chạy suite >=3 lần/test, chuẩn bị tài khoản/device/cloud actions và raw evidence phần Charlie |
| **S6-10** | Thái An | Phân tích fail/flaky của Auth/export/push, phân biệt app/timing/instruction, sửa và chạy lại cases bị ảnh hưởng |
| **S7-4** | Thắng | Giao findings thật, quyết định, disclosure và fix links; hỗ trợ tổng hợp >=5 findings, >=2 loại, >=3 fixes theo yêu cầu nhóm |
| **S8-5** | Thắng | Giao phần report S8-3 và evidence/link kiểm chứng để ghép bản chung |
| **S8-10** | Thắng | Giao slides S8-7 và nguồn ảnh/link đúng để ghép bản chung |
| **S8-15** | Thắng | Giao clip S8-12, thao tác và giới hạn đã kiểm chứng để ghép video chung |
| **S8-16** | Thắng | Cung cấp versions/config/run instructions, Firebase setup và evidence/deliverable paths phần Charlie cho README |
| **S9-2** | Thắng | Đối chiếu project ID trên ảnh Auth/Storage/FCM Console với `google-services.json` của build; thay ảnh sai project |

- **S1-5:** Hoàng phối hợp/chủ trì yêu cầu thiết kế Sign-in/Profile theo owner gốc, Charlie hỗ trợ; **S3-4/S4-13:** Charlie hiện thực bằng Flutter và preview code. Không yêu cầu bổ sung frame Figma theo chính sách mới.
- **S3-6:** Thắng chủ trì router/AuthGate; Charlie cung cấp auth stream/status và hỗ trợ native/session cases. Không dựng router thứ hai trong AuthService.
- **S4-3:** Hoàng cung cấp plan đang xem; **S4-10:** Charlie xuất đúng plan đó thành PDF. Charlie không viết lại generator thực đơn hoặc tự query một plan khác.
- **S5-2/S5-6/S5-8:** Thái An chủ trì Analytics/Crash/RC; **S5-4:** Charlie gắn events Auth/export; **S4-13/S5-9:** Profile do Charlie dựng phải có điểm tích hợp RC/Crash của Thái An.
- **S6-2/S6-9:** Thái An sở hữu harness và chạy/tổng hợp suite; **S6-4/S6-7:** Charlie viết cases mảng Auth/export/push, hỗ trợ chạy/fix, không chỉ giao app rồi chờ người khác test hộ.
- **S8-5/S8-10/S8-15:** Thắng tổng hợp; Charlie vẫn phải soạn report/slides/clip, không chỉ nộp code.

## 3. Các điểm lệch giữa tài liệu team cần đọc đúng

1. Master có **112 IDs**: Thái An 29, Charlie 29, Hoàng 26, Thắng 28. Charlie/Hoàng/Thắng khớp file cá nhân; file `task-thai-an.md` có **28 task rows**, thiếu **S0-2** mà master giao Thái An. Đối chiếu theo master, chưa tự thêm/xóa task người khác.
2. `submission-checklist.md` mục 4 ghi Charlie phụ trách nghiệm thu sáu services. Chi tiết task chia **Auth/Storage/FCM cho Charlie**, **Analytics/Crash/RC cho Thái An**, **integration/failure acceptance cho Thắng + nhóm**. Hiểu đây là phối hợp nghiệm thu, không biến Charlie thành người phải tự code cả sáu.
3. Task S0-4 nói Spark đủ; vấn đề Storage/billing đã ghi DEC-01 trong bộ điều phối. Chốt project/plan phù hợp trước upload; không tự bỏ Storage hoặc tự mở billing.
4. Mọi bảng đang ghi Chưa bắt đầu/0%; code đã có skeleton. Không làm lại toàn bộ, cũng không coi file có sẵn là Done. Dùng status: **chưa có -> skeleton -> implemented -> verified** và kèm giới hạn.
5. Mỗi cá nhân đóng góp 1-2 review findings không bảo đảm nhóm đủ >=5 nếu mỗi người chỉ có một. Thắng cần tổng hợp đúng ngưỡng và >=2 loại; không tạo finding/commit giả cho đủ số. Charlie có nghĩa vụ >=1 accepted fix theo phân công cá nhân.
6. S5-4 liệt kê login/logout/export chung một task phụ thuộc upload, nhưng có thể tích hợp login/logout sớm sau khi S5-2/event contract sẵn; chưa cần chờ PDF xong. Đây là chia nhỏ triển khai, không đổi dependency nghiệm thu toàn task.

## 4. Bảng làm rõ đủ 29 task Charlie

**Không có task nào được đánh dấu hoàn thành trong bảng này.** Cột nghiệm thu là điều kiện cần đạt, không phải kết quả đã chạy.

| Task ID | Việc Charlie thực sự phải xử lý | Nhận đầu vào / phối hợp | Đầu ra và điều kiện bàn giao |
|---|---|---|---|
| **S0-3-CM** | Kiểm tra toolchain Flutter/Android/FlutterFire/ADB của máy mình | Baseline version nhóm; Thái An/Thắng | Ghi versions và thiết bị; command chạy được. Doctor đã được kiểm tra trước nhưng FlutterFire còn cần xác nhận |
| **S0-4** | Xác định Firebase project chung, quyền thành viên, project ID và plan | S0-1 của Thái An; **DEC-01 (Blaze/Storage)** | Dùng project đã có nếu nhóm có, tránh tạo trùng; xác nhận plan/bucket đáp ứng upload; README/config cùng project; chưa tự tăng billing |
| **S2-3** | Dịch tokens/styles Lab 2 sang ThemeData/ColorScheme/TextTheme/spacing/radius/elevation | S0-6 của Thắng; token/component tham chiếu và quyết định UI trong code | Theme nhất quán theo định hướng Lab 2, tên semantic rõ, bảng mapping dùng chung; cải tiến tokens trong code có lý do/evidence/review |
| **S2-4** | Hoàn thiện chín nhóm widgets và variants/states | S2-3; Hoàng review cách dùng | Button/Field/Card/Nav/AppBar/Dialog/Loading/Empty/Error, semantics/hit target; API + ví dụ để Hoàng dùng |
| **S3-1** | Configure FlutterFire và Android/Firebase bootstrap | S0-4 + skeleton S2-2 Thắng; Thái An cho Crashlytics | Một app ID, đúng config/plugin theo SDK; build Android sau configure, kiểm tra AGP/Kotlin/google-services/Crashlytics theo mục 8; init thành công hoặc error state rõ |
| **S3-2** | Thu SHA fingerprints máy team và đăng ký đúng Firebase Android app | Cả bốn bạn gửi fingerprint | Các máy đăng nhập được theo package/SHA; không cần gửi keystore riêng của nhau |
| **S3-3** | Hoàn thiện AuthService Google credential/profile/auth stream | Interfaces S2-1 Thắng; users schema Hoàng | Login/cancel/network/profile-error rõ; user mới role=user; auth state đủ cho router, không tự cấp staff/admin |
| **S3-4** | Code SignInScreen bằng common widgets | Layout/states S1-5 phối hợp Hoàng qua preview code + S2-4; Thắng hỗ trợ | Màn đúng DS; loading/disabled/cancel/error; không gọi SDK trực tiếp, không overflow khi text scale; không cần frame Figma mới |
| **S3-5** | Logout và phối hợp reset session toàn app | AuthService; Thắng router; Hoàng data state | Về Sign-in, Back không vào nội dung bảo vệ; clear local state/listeners/URLs/IDs theo session, không xóa cloud data |
| **S3-7** | Rules Storage theo UID và phối hợp deploy/kiểm chứng | Firebase config S3-1; quyền project | Owner read/write reports/uid; B/signed-out denied; có rules file và evidence môi trường thật phù hợp |
| **S3-9** | Thu bằng chứng Auth | S3-3..S3-5 đã chạy | App signed-in/out/cancel, Users Console đúng project ID; instructions tái lập |
| **S4-10** | PDF từ plan đang xem, lưu local và xem/chia sẻ theo policy | Active plan/model API S4-3 Hoàng | Nội dung/revision đúng; nhúng font TTF có glyph tiếng Việt vào PDF, kiểm tra regular/bold và layout; lỗi generate rõ; không viết lại luật chọn món |
| **S4-11** | Upload PDF đúng owner path, progress/URL, cancel/retry/error | S4-10 + S3-7 + DEC-01 | Stable export ID; local file còn khi lỗi; denied/network/cancel phân biệt; không duplicate upload do retry |
| **S4-12** | FCM permission, ba lifecycle states, history, target routing | Config S3-1; Thắng route contract, Thái An/Console test | Native push thực ở fg/bg/terminated; dedup/history đúng user; tap đúng screen; deny và target lỗi có feedback |
| **S4-13** | Profile + Firebase Demo Area | S1-5/S4-11/S4-12; **Hoàng: di chuyển export/inbox khỏi Home**, Thái An RC/Crash, Thắng DI/routes | Identity/logout, inbox, export progress/URL, RC values/refresh và crash demo; thống nhất diff `home_screen.dart` với Hoàng, giữ active plan và đường vào đúng Figma |
| **S4-14** | Semantics phần Sign-in/Profile/export/notification | UI và actions sẵn có | Label/checked/disabled/loading/action feedback đủ để TalkBack/ARTEMIS xác định; không icon-only vô danh |
| **S4-15** | Bằng chứng Storage/FCM | S4-11/S4-12 thật | File Console/progress/URL/denied; ba FCM states và route; device/project/message marker rõ |
| **S5-4** | Gắn login/logout/export_report tại success/outcome đúng | S5-2/event plan Thái An; UI/VM của Charlie | Tên/typed params thống nhất; không log lặp; event export khác upload nếu contract tách; hỗ trợ DebugView |
| **S6-4** | test_auth.py native/cancel/logout và observed assertions | ARTEMIS harness thật S6-2 Thái An | Preconditions độc lập, agent báo state/value thật; không Dummy SUCCESS; tham gia formal >=3 runs |
| **S6-7** | test_export.py và push-tap case trong test_profile.py | S6-2 + export/FCM chạy thật | Assert PDF/URL/state/target; ghi operator-assisted bước gửi push nếu chưa tự động; raw evidence |
| **S6-14** | Sửa bug/semantics trong phạm vi Charlie khi suite phát hiện | Log S6-9/10 | Fix liên kết issue/commit; rerun đúng cases, không sửa expected chỉ để pass |
| **S7-1-CM** | PR code phần mình, chạy AI review, giữ output | Feature branch + mốc review team | PR/diff/file:line và output thật; không chỉ review một ảnh hoặc bịa tool đã dùng |
| **S7-2-CM** | Quyết định cho 1-2 real findings, ghi lý do/disclosure | S7-1-CM | Accepted/Modified/Rejected có căn cứ, không mặc định AI đúng; phối hợp nhóm đủ >=5 findings/2 types |
| **S7-3-CM** | Sửa >=1 accepted finding bằng commit riêng | S7-2-CM | Commit có finding ID, nội dung sửa đúng và có check; links thật trong code-review.md |
| **S8-3** | Viết phần report Auth/Storage/FCM | S4-15/evidence + quyết định scope | Mỗi service: khái niệm/luồng tích hợp/failure/test/evidence/giới hạn, gửi Thắng tổng hợp |
| **S8-7** | Slide mỗi service Auth/Storage/FCM | S8-3 + evidence | Khoảng ba slide theo phân công, một thông điệp rõ; app/Console proof, không chỉ định nghĩa |
| **S8-12** | Clip sign-in, PDF/upload và nhận push | Build ổn định, config/data/evidence | Thao tác thật + Console phù hợp, lời giải thích kỹ thuật, gửi Thắng ghép trong tổng thời lượng |
| **S8-17-CM** | Worklog cá nhân | Task/PR/commit/evidence thực tế | Ghi quyết định, phần sửa, cách test, còn vướng; cập nhật dần rồi chốt theo lịch team, không viết lịch sử giả |
| **S9-5-CM** | Chuẩn bị giải thích code và demo | Một test/RC value/VM/review thật đã dùng | Tự chạy test, đổi config cùng Thái An khi cần, giải thích VM và một quyết định review; không chỉ nhớ màn hình |

## 5. Các đầu vào Charlie cần và các đầu ra người khác đang chờ

| Từ / tới | Contract phải có | Nếu chưa có thì Charlie vẫn làm được |
|---|---|---|
| **Thắng -> Charlie** | Interface/service names, DI/bootstrap, router/notification destination, auth reset hooks | Đọc source/Figma, hoàn thiện token/widget API proposal, tests UI bằng fakes rõ ràng |
| **Hoàng -> Charlie** | Yêu cầu/layout/states Sign-in/Profile S1-5 chốt qua mô tả/preview code; UserModel/users schema; active MealPlan/revision S4-3; lifecycle reset state | Common widgets và PDF layout bằng fixtures test; chưa gọi mẫu là data thật của bản nộp |
| **Thái An -> Charlie** | Analytics methods/params, RC keys + observable refresh, Crash actions, ARTEMIS client/fixtures/trace convention | Chừa integration seams trong Profile, semantics và manual acceptance plan; không viết một harness cạnh tranh |
| **Charlie -> Hoàng** | Theme + chín reusable widgets, props/state examples, fonts/assets hướng dẫn | Hoàng có thể lắp S01-S10 mà không copy CSS/token hoặc dùng style lẻ |
| **Charlie -> Thắng** | Auth stream/outcomes/session cleanup contract; route intents FCM; config/project metadata | Router/DI/failure tests tích hợp đúng; không nhập SDK call vào screen |
| **Charlie -> Thái An** | Event hooks/login/logout/export, target semantics, auth/export/push test cases và Console evidence | DebugView/RC/demo/test suite có điểm nối, không cần reverse-engineer UI cuối kỳ |

## 6. Cụ thể hoá gói Design System in Code

64 variables và 81 main components trong Figma **không có nghĩa phải viết 64/81 widget classes**. Triển khai nhóm reusable widgets bằng props/variants/state, thêm supporting components khi flows cần.

| Nhóm | Các khả năng Charlie phải bàn giao |
|---|---|
| Button | Primary/Secondary/Destructive theo Figma; pressed/disabled/loading; loading chặn submit và giữ kích thước/label semantics |
| TextField | Label/value/unit/helper/error, focus/filled/disabled; nối Form/validator và keyboard; nội dung lỗi xuống dòng không cắt |
| Card | Meal/Summary hoặc variants đã duyệt; optional interaction; ảnh/nguồn/status, nội dung dài không overflow |
| Navigation | Bốn tabs và selected state; callback/declarative selection để Thắng/Hoàng nối router; không gọi Firebase |
| AppBar | Back/actions/title theo DS; hit targets và origin navigation qua callback/router |
| Dialog | Confirm/destructive/error/edit/edit-error; validation không đóng dialog khi sai; cancel không mutate dữ liệu |
| Loading | Screen/region loading và skeleton/spinner theo Figma; semantics; khác loading của nút |
| Empty | Message/icon/CTA theo context; có hành động giúp tiếp tục flow |
| Error | Message/retry/cancel phù hợp; giữ dữ liệu cũ nếu tác vụ cập nhật lỗi |

Supporting pieces có thể gồm badge, icon button, day selector, ingredient row/checkbox, quantity control, Snackbar Undo. Chỉ tạo khi có sử dụng, giữ cùng tokens.

Source chuẩn: design system/handoff Lab 2 và component bindings được duyệt; action green #476429, border control #74796C, cream/font styles cần đối chiếu. Không tiếp tục Inter/màu nền skeleton khi khác thiết kế. Test 360/412dp, tiếng Việt dài, keyboard/text scaling, body >=14sp, hit target >=48dp. Cỡ chính xác của CTA lấy component đã duyệt, không coi 48dp tối thiểu là chiều cao cho mọi nút.

Bàn giao S2-3/S2-4: code/theme, bảng token->Flutter, catalog/ví dụ props/states, ảnh kiểm tra kích thước đã dùng và một hướng dẫn ngắn để Hoàng sử dụng. Không cần chờ toàn bộ Firebase hoàn thành mới giao common widgets.

## 7. Cụ thể hoá Firebase và Profile

### Auth và session

Google picker -> Firebase credential -> users/{uid} -> typed auth outcome -> AuthViewModel -> AuthGate. Cancel khác network failure và lỗi đọc profile. User mới chỉ role=user. Các route và roles phải tuân schema/rules team, không chỉ kiểm tra trên UI.

Logout cần cả SDK sign-out và session cleanup: plan/ingredients/shopping/messages/export URL/identifiers/listeners của user A không xuất hiện khi user B login. Charlie điều phối hooks với Hoàng/Thắng/Thái An; không tự rewrite VM người khác. Giữ cloud records của A.

### PDF và Storage

`MealPlanModel đang xem -> ReportService -> local PDF/exportId -> StorageService -> progress/URL/state`. Hoàng cung cấp data đúng, Charlie chịu trách nhiệm render/export/upload. Nhúng font **TTF hỗ trợ tiếng Việt** (regular/bold theo nội dung) bằng font/theme của thư viện PDF; khai báo assets/license phù hợp. Font Flutter UI không tự áp dụng cho `pw.Document`. Xuất và mở file có tên món/ngày tiếng Việt đủ dấu để kiểm chứng glyph, xuống dòng và phân trang; local file giữ khi mất mạng, retry cùng ID.

Rules owner path phải được test với A/B/signed-out; file rules trong Git chưa chứng minh deploy đúng project. Nếu thiết kế có Cancel upload thì cần handle tác vụ tương ứng, không chỉ đổi nhãn trên UI.

### FCM và Profile

FCM permission -> message lifecycle -> history/dedup -> target route chờ auth/router. App foreground cần phản hồi thấy được; background/terminated có test Console; history phải có cách tồn tại qua reopen theo policy. FCM inbox khác announcements Firestore do staff tạo; không thay cơ chế này bằng cơ chế kia để tick task.

S4-12 phải xử lý đủ `onMessage`, `onBackgroundMessage`, `onMessageOpenedApp` và `getInitialMessage()`. Handler background theo SDK cần top-level/entry-point phù hợp; không điều hướng UI từ background isolate. Thống nhất payload/message ID, auth gate và pending destination với Thắng; một message qua nhiều callbacks không được nhân đôi history hay route.

Chốt **nơi lưu history** trong S2-1/S4-12: local theo UID hoặc Firestore theo contract đã duyệt. Nếu dùng Firestore, cần Hoàng/Thắng thống nhất schema/owner-only rules, cách ghi khi background/auth chưa sẵn và test allowed/denied; đây là dependency trước nghiệm thu persistence, không tự thêm collection/rules ngoài thỏa thuận. Tách push inbox khỏi announcements, giữ history của đúng user sau reopen/logout/login.

Profile là giao diện tích hợp: identity/logout, notification center, PDF/local/upload/progress/URL, RC values/refresh và crash demo trong vùng chuyên biệt. Charlie dựng UI và gọi VM/service contract; Thái An cung cấp RC/Crash implementation và evidence công nghệ đó.

**Điểm phối hợp S4-13:** skeleton đang đặt export/upload và inbox trong `lib/screens/home_screen.dart`. Trước sửa, Charlie thống nhất với Hoàng phần chuyển sang Profile, entry points còn giữ theo Figma và active plan/revision truyền qua VM; Thắng nối route/DI. Bàn giao diff để tránh cả hai cùng sửa Home hoặc còn hai khu demo lệch state. Không gỡ nguồn announcements/service dùng chung chỉ vì chuyển UI.

### Tác động của yêu cầu Final lên phần Charlie

Final PDF là nguồn yêu cầu của cùng Assignment; phần hệ thống bổ sung vẫn cần leader phân công trong SYS workstreams, không tự nhập tất cả vào 29 task Charlie.

| Hạng mục | Tác động cần chuẩn bị | Phối hợp / giới hạn |
|---|---|---|
| Shared core | Theme/tokens/common widgets tổ chức để dời được sang `packages/core`, dùng lại mobile/web; assets/fonts và imports không phụ thuộc screens/VM riêng mobile | Theo kiến trúc S2-2 của Thắng; chưa coi core-ready là đã có shared package. Local file/open/share của export cần adapter phù hợp nền tảng |
| App Check | Chuẩn bị điểm bootstrap/config client và kiểm chứng truy cập Firestore/AI Logic với provider phù hợp | Charlie phối hợp Thắng/Hoàng/Thái An theo phân công bổ sung; không tự nhận toàn bộ security/AI. Chỉ bật enforcement theo kế hoạch đã kiểm thử các clients; debug provider không phải evidence production |
| **S0-4 -> DEC-01** | Kiểm tra plan/bucket/quyền **Blaze** trước S3-7/S4-11; không dựa câu “Spark đủ” của task cũ | Storage vẫn nằm trong hướng triển khai theo Guide mới; Final có exclusion cần leader chốt. Không tự mở billing hoặc bỏ upload để né xung đột |

## 8. Hiện trạng code Charlie: nên tiếp tục từ đâu

Đối chiếu baseline `ae35f07` và đọc lại source local ngày **02/11/2026** theo góp ý Claude; không kiểm chứng cloud/account hoặc chạy lại app trong lượt này. Phân biệt thiếu sót thấy trực tiếp trong source với tác động suy ra và rủi ro cần chạy test.

| Khu vực | Có thể kế thừa | Phần chưa đủ nghiệm thu |
|---|---|---|
| `lib/theme/` | AppColors/AppSpacing/AppRadius/AppTheme | Typography Inter/một số màu khác Lab 2; cần token reconciliation |
| `lib/widgets/` | AppButton/AppCard/AppTextField và state views | Chưa đủ Nav/AppBar/Dialog và variants/states/field validation API phù hợp |
| `lib/widgets/app_button.dart` | Primary/Secondary/Outlined, loading, Semantics wrapper | **Chưa có Destructive**; chiều cao đang lấy `AppSpacing.minTouchTarget = 48`. Đối chiếu mốc **52/56** Claude nêu với token/component/instance Figma hiện hành trước chốt từng variant; 48 là minimum hit target, không thay metric thiết kế. Wrapper có `label: text` bao button/Text có semantics riêng: **nguy cơ lặp nhãn**, cần kiểm tra semantics tree/TalkBack |
| `main.dart`, Android config | Provider wiring/bootstrap skeleton | Firebase config/plugin/applicationId chưa thống nhất; không nuốt init error |
| AuthService/AuthViewModel/SignIn | Luồng credential/auth state và màn khung | `fetchUserProfile` catch rồi trả null: khi đọc/tạo profile lỗi, Firebase có thể đã đăng nhập nhưng VM nhận null, AuthGate còn ở Sign-in. Picker cancel thành `ViewStateEmpty('Đăng nhập bị hủy')`, còn SignInScreen chỉ hiển thị `ViewStateError`, nên không hiện thông báo cancel. Logout chưa reset session các VMs |
| ReportService | Sinh bytes PDF theo model | `pw.Document` chưa nhúng font tiếng Việt; cần TTF regular/bold, kiểm tra tên món/ngày có dấu, local persistence/open/share/error và data/revision contract |
| StorageService/ProfileViewModel | reports/uid path, progress callback, URL | Error typed/cancel/listener lifecycle, stable retry ID, local file retention, UI/Profile thật |
| `lib/firebase/notification_service.dart` | requestPermission/onMessage/onMessageOpenedApp | Thiếu `onBackgroundMessage` và `getInitialMessage`; `_messages` chỉ ở RAM, chưa có history bền vững/dedup/routes/UI updates/session clear; xem dependency schema/rules ở mục 7 |
| Permission trong `main.dart` | Gọi `notification.initialize()` trước `runApp`/tạo AuthService | `requestPermission()` có thể hiện **trước đăng nhập** trên fresh install nếu init tới bước đó. TC-01 hiện giả định tới Sign-in rồi mở Google picker; dialog thông báo có thể chặn bước đầu. Phối hợp chính sách xin quyền và precondition với Thắng/Thái An |
| Tests/evidence | Một widget test AppButton đã pass trong lần kiểm tra trước | Chưa có auth/export E2E scripts thật/evidence cloud; Dummy harness không dùng để nghiệm thu |

### Những ca kiểm chứng Claude cần bổ sung theo task

- **S3-3/S3-4:** tách cancel, profile-read/write failure và credential failure; lỗi profile có feedback/retry phù hợp, không báo thành hủy đăng nhập. Test trường hợp Firebase user tồn tại nhưng profile lỗi; không khẳng định mọi lần sign-in đều kẹt.
- **S2-4/S4-14:** kiểm tra semantics tree/TalkBack ở normal/disabled/loading/icon để có một tên truy cập và action/state đúng; chỉ kết luận “Semantics bị lặp” sau khi có kết quả. Đo chiều cao theo variant Figma, giữ hit target >=48dp và không cắt nội dung khi text scale lớn.
- **S4-12/S6-3/S6-4:** chốt thời điểm xin quyền (ví dụ sau login/tại ngữ cảnh notification theo UX được duyệt) hoặc mô tả permission dialog rõ trong TC-01. Tách nhánh allow/deny/chưa hỏi, signed-out và cold start; không xử lý dialog thủ công rồi báo test fresh-install đã pass.
- **S4-10/S4-12:** mở PDF thực có dấu; push fg/bg/terminated, reopen history/dedup, tap chờ auth và đổi A/B. Có source handler hay font assets chưa chứng minh các ca này chạy được.

### Rủi ro Android toolchain khi thực hiện S3-1

Source đang khai báo **AGP 9.1.0**, **Kotlin Gradle plugin 2.4.0 (`apply false`)**, wrapper **Gradle 9.3.1**; `gradle.properties` có `android.builtInKotlin=false`, `android.newDsl=false`. Module app hiện chưa apply `google-services`/Crashlytics; khai báo KGP ở settings chưa đồng nghĩa module app đã apply KGP.

Ghi đây là **rủi ro tương thích cần kiểm chứng**, chưa có evidence build lỗi do tổ hợp trên. `flutterfire configure` có thể bổ sung/cập nhật cấu hình Gradle, trong đó Crashlytics cần plugin tương ứng khi service được cấu hình. AGP 9 có thay đổi Kotlin/DSL; không tự đổi versions hoặc xóa flags theo một recipe chung. Đối chiếu Flutter/JDK/plugin thực dùng và hướng dẫn chính thức trước migration.

Điều kiện bàn giao S3-1: ghi versions trước/sau và diff do configure, project/app ID đúng; **chạy Android build sau cấu hình** (ví dụ `flutter build apk --debug`) và launch kiểm tra Firebase init trên thiết bị. Thái An cùng xác nhận cấu hình Crashlytics theo phạm vi của mình; Thắng phối hợp build/kiến trúc. `flutter analyze` hoặc CLI configure thành công riêng lẻ chưa đủ chứng minh Gradle/plugins build được. Lượt review tài liệu này chưa chạy configure/build và chưa đổi Gradle.

Không xoá skeleton để làm lại từ đầu. Review từng API rồi hoàn thiện theo contract; ưu tiên khắc phục đúng chỗ thay vì thêm nhiều lớp/service trùng tên.

## 9. Thứ tự triển khai riêng cho Charlie

Các đợt dưới đây là cách chia việc đề xuất; không thay mốc/deadline của leader.

| Đợt | Tasks chính | Mốc bàn giao |
|---|---|---|
| **C0 - khóa đầu vào** | S0-3-CM/S0-4; phối hợp S0-6/S2-1/S1-5 | Một app ID/project/versions; token source; interface/routing/session contract; Storage decision rõ |
| **C1 - nền UI** | S2-3/S2-4 | Theme/common widget API để Hoàng dùng ngay; có QA representative states |
| **C2 - Auth end to end** | S3-1..S3-5/S3-7/S3-9; hỗ trợ S3-6 | Sign-in/cancel/logout/restore đúng UI và Console; M2 có evidence |
| **C3 - PDF/Storage** | S4-10/S4-11 từ S4-3; bắt đầu event hooks S5-4 khi sẵn | PDF đúng plan, owner upload/retry/error; evidence không chờ cuối |
| **C4 - FCM/Profile** | S4-12..S4-15; phối hợp S5-9 | Notifications ba states và Profile tích hợp RC/Crash đúng contract |
| **C5 - kiểm thử/review** | S6-4/S6-7/S6-14, S7-1/2/3-CM | Cases trên harness thật, raw evidence, findings/accepted fix commit |
| **C6 - bàn giao cuối** | S8-3/S8-7/S8-12/S8-17-CM/S9-5-CM | Report/slides/clip/worklog và giải thích được code/test |

Hai đường có thể tiến triển song song sau khi chốt API: **theme/widgets** và **Firebase project/bootstrap**. Nếu cloud account/billing chưa sẵn, vẫn hoàn thiện C1 và test UI; nếu plan API chưa sẵn, vẫn làm FCM/Auth, không ngồi chờ hoặc dùng dữ liệu hard-coded trong bản nộp.

Không cần chờ code mọi màn mới chuẩn bị tests/semantics/evidence. Điều kiện formal suite/freeze vẫn do Thắng/Thái An điều phối.

## 10. Gói bàn giao thực tế để tránh “code xong nhưng team chưa dùng được”

Mỗi PR/gói Charlie nên có: **task IDs -> files/API thay đổi -> cách dùng/cấu hình -> success/error cases -> evidence/checks -> còn phụ thuộc gì**. Đây là quy ước đề xuất, không cần tạo sáu tài liệu dài cho mỗi thay đổi nhỏ.

- Gói UI: theme/widgets/catalog states theo baseline tham chiếu và UI code hiện hành; cải tiến palette/radius/layout có lý do/evidence/review trong repo, không sửa Figma; Hoàng review usage.
- Gói Auth: config instructions/app ID/SHA, auth outcomes/session cleanup và evidence; Thắng review routing.
- Gói Export: plan/export contract, PDF/local/upload/rules/retry proof; Hoàng review data đúng, Thái An review events/tests.
- Gói FCM/Profile: route payload/history/permissions và demo integration points; Thắng/Thái An review theo phạm vi.
- Gói QA/review: test_auth/test_export/test_profile, raw runs và real finding/fix links; không tự report pass rate chưa có.

## 11. Điều kiện để bắt đầu rõ ràng

Trước chỉnh source, xác nhận/ghi vào contract: (1) app ID/Firebase project/quyền đã có hay chưa; (2) bản tokens/component chuẩn; (3) interfaces + auth/router/session seams; (4) Sign-in/Profile design; (5) active plan model cho PDF; (6) event/RC/Crash/test harness contracts; (7) nhánh/PR convention của team.

Mục nào chưa có thì ghi owner cung cấp và tiếp tục phần độc lập. Không yêu cầu duyệt lại Lab 2, không tự đổi 112 task IDs hoặc nhận luôn việc của người khác.

Lượt này chỉ phân tích và làm rõ: chưa tạo Firebase project, chưa sửa Dart/Python/rules, chưa đăng ký SHA/deploy/upload hoặc chạy model API.

## Nguồn trực tiếp

- Task Charlie: https://github.com/ruxenb/LongvitaRC/blob/ae35f07e36cab9ad4843396a1c22d72c247853ea/docs/tasks/task-charlie.md
- Master 112 tasks: https://github.com/ruxenb/LongvitaRC/blob/ae35f07e36cab9ad4843396a1c22d72c247853ea/docs/tasks/danh-sach-task-full.md
- Các file README/milestones/submission và ba task cá nhân khác: cùng thư mục/commit, đã đọc và đối chiếu IDs/owner/dependencies.
- Bộ [phân tích Assignment](LONGVITA_LAB3_FINAL_ANALYSIS.md), [kế hoạch](LONGVITA_LAB3_IMPLEMENTATION_PLAN.md), [QA](LONGVITA_LAB3_QA_AND_EVIDENCE_PLAN.md) chứa yêu cầu công nghệ, source conflicts và baseline audit.
- Tài liệu kỹ thuật chính thức đối chiếu 02/11/2026: [FCM lifecycle/background/interaction](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages), [Flutter AGP 9/built-in Kotlin](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin), [FlutterFire/Crashlytics configure và rebuild](https://firebase.google.com/docs/crashlytics/flutter/get-started), [pdf: TrueType fonts](https://pub.dev/packages/pdf), [Storage plan changes](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024). Đây là hướng dẫn xác minh triển khai, không phải bằng chứng SDK/cloud đã chạy trên repo.
