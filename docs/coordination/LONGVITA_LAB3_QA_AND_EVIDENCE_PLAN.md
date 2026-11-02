# Longvita - QA và bằng chứng thống nhất Assignment / Lab 3

Cập nhật **02/11/2026**. Lab 3 = Assignment, kế thừa Figma Lab 2; dùng [phân tích](LONGVITA_LAB3_FINAL_ANALYSIS.md) và [kế hoạch triển khai](LONGVITA_LAB3_IMPLEMENTATION_PLAN.md) cùng bộ.

**Mọi ARTEMIS/system case dưới đây đều Planned, 0 runs được xác minh trong repo.** Đã chạy một widget test AppButton và analyzer local; kết quả nằm ở `verification-20261102.md`, không tính thành E2E pass rate hoặc Firebase evidence.

## 1. Chặn kết quả mẫu bị hiểu thành evidence

- `e2e_test/conftest.py` hiện có DummyArtemisClient trả SUCCESS khi thiếu SDK. Không dùng client này để nghiệm thu; thiếu server/model/device phải fail setup rõ ràng. Việc sửa harness là S6-2 của Thái An, chưa được thực hiện trong lượt sửa tài liệu.
- Các ô 3/3 trong `docs/test-plan.md` trước đối chiếu không có raw run tương ứng; đã chuyển về Planned. Giữ TC-01..TC-11 của leader làm mã chuẩn, mở rộng tới TC-26 thay vì tạo bộ ID song song.
- Các CR rows/commit dạng `commit-a1b2c3d` trong `docs/code-review.md` là ví dụ template. Chỉ tính finding thật khi có PR/tool output/file:line/decision; không tính ví dụ vào >=5 findings/>=3 fixes.
- Findings AUD-01..14 trong bản phân tích là review hiện trạng code, chưa phải PR findings đã được team accept/fix. Không tự đổi AUD thành CR để đủ rubric.

## 2. Điều kiện chung của một run hợp lệ

1. Ghi app commit/build/applicationId, SDK/lockfile, Firebase project ID, ARTEMIS full commit/profile/model, device serial/API, fixture revision và thời điểm chạy.
2. ApplicationId trong Gradle/Firebase/ADB/ARTEMIS phải cùng giá trị. Hiện Gradle dùng `vn.edu.fpt.longvita.longvita`, harness/docs dùng bản thiếu hậu tố: chốt trước native/DebugView tests.
3. Dùng dedicated test accounts A/B; reset đúng dữ liệu test trước mỗi case. Không phụ thuộc case trước hoặc xóa dữ liệu dùng chung tùy tiện.
4. Real ARTEMIS Python SDK/client theo commit pin, Flash regression, Pro exploratory. Profile không phải tên model; không mặc định Gemini 2.5 hay model nào nếu chưa kiểm tra khả năng tài khoản.
5. Mỗi pytest function gửi instruction có starting point/steps/expected UI; yêu cầu agent báo observed values. Assert observed values và outcomes, không chỉ `SUCCESS`/`succeeded`.
6. Structured output fields ở bảng là **assertion contract đề xuất**, không phải API property có sẵn. Thái An xác nhận parse/result schema từ SDK đang pin.
7. Không đưa key, test password hoặc FCM token dùng thực lên public log/slide. Guide tr.13 yêu cầu ghi thiết bị/token/cách xử lý quyền; evidence nội bộ giữ giá trị cần kiểm chứng, bản trình chiếu che phần không cần công khai.
8. Tắt mạng chưa chắc gây Firestore error vì cache/queued writes; dựng precondition uncached/server-read/deny hoặc fault test rõ ràng. Ghi đúng test build/emulator/live và giới hạn, không trình bày fault giả như cloud thực.

## 3. Bộ mobile/core E2E: giữ 11 IDs leader và mở rộng đến 26

Đề yêu cầu >=10 cases và coverage đủ. **26 là đề xuất kỹ thuật**, không phải ngưỡng thầy đặt thêm. Mỗi case >=3 runs khi formal execution; nếu giữ đủ 26 thì tối thiểu **78 executions**, chưa bao gồm exploratory/reruns/system cases. Không thực hiện run model trả phí trong lượt lập tài liệu này.

| ID | Owner phối hợp | Preconditions và hành động chính | Observed values/expected result | Status |
|---|---|---|---|---|
| TC-01 | Charlie + Thái An | Signed out; Google native picker -> chọn account A | Home/4 tabs đúng thiết kế, identity đúng account test, login event; không dùng label dashboard thay Final UI | Planned |
| TC-02 | Hoàng + Thái An | Home -> S02 hợp lệ -> S03 generate -> S04 | days=7, mealsPerDay đúng lựa chọn, catalog IDs có nguồn; loading kết thúc theo task thật | Planned |
| TC-03 | Hoàng + Thái An | Generate gặp error có thể tái lập -> phục hồi -> Retry | Error/retry rõ, input giữ nguyên, success sau phục hồi; không mock fallback hoặc spinner vô hạn | Planned |
| TC-04 | Hoàng + Thái An | Plan generated -> save -> S10 -> mở lại | Cùng planId/revision/title, đủ ngày; chứng minh server-confirmed theo policy; không chỉ snackbar | Planned |
| TC-05 | Hoàng + Charlie | S07 edit amount <=0 -> sửa số hợp lệ -> S08 | Error text, dialog không đóng khi invalid; amount mới lưu; units và tổng đúng | Planned |
| TC-06 | Hoàng | S08 check 2 items -> đóng/mở lại; mở list khác mới | Checked giữ theo list cũ; list mới unchecked, không rò state giữa list | Planned |
| TC-07 | Hoàng | S04 -> S05 -> nguồn S09 -> Back -> S06 confirm -> S04 | Recipe/reference IDs đúng, Back đúng origin, replacement/totals/revision cập nhật; rule đã chốt còn đúng | Planned |
| TC-08 | Charlie | Có plan/revision -> generate PDF -> local/open -> upload khi DEC-01 áp dụng | Nội dung PDF khớp, progress/URL/state/file Console đúng owner; URL không phải proof duy nhất | Planned |
| TC-09 | Thái An + Charlie/Hoàng | Defaults -> đổi 2 RC values -> refresh -> tác vụ sử dụng chúng | Values và 2 hành vi đổi trên cùng binary; fetch/cache rõ; không chỉ in getter | Planned |
| TC-10 | Charlie + Thái An | App background; operator/harness gửi Console push -> notification shade tap | Native marker đúng, route target đúng, inbox ghi theo policy và không duplicate | Planned |
| TC-11 | Charlie + Hoàng | A có plan/list/messages -> logout -> protected route -> login B | B không thấy dữ liệu A, active state/listeners/IDs được reset, cloud A không bị xóa | Planned |
| TC-12 | Charlie | Signed out -> mở Google picker -> Cancel | Vẫn Sign-in, thông báo hủy rõ, khác error profile/network, không vô tình vào Home | Planned |
| TC-13 | Charlie + Thắng | A đã login -> cold reopen bình thường | Session phục hồi, route đúng, không hiện data account cũ khác; xử lý expired session | Planned |
| TC-14 | Hoàng | Có preferences hợp lệ, catalog/filter không có kết quả -> sửa preferences | Không bị bắt khai lại vô ích; no-result có recovery; không chèn recipes hard-coded | Planned |
| TC-15 | Hoàng | Save failure -> giữ draft -> Retry | Plan không mất, same stable ID/revision; không tạo hai docs do retry/double-submit | Planned |
| TC-16 | Hoàng | S07 ingredient result rỗng theo fixture | Empty có CTA về plan/chỉnh phù hợp, không lỗi trắng/đếm màn state thành screen mới | Planned |
| TC-17 | Hoàng | S07 delete item -> Undo | Khôi phục đúng item/quantity/unit/vị trí theo contract, không duplicate | Planned |
| TC-18 | Hoàng | Create Shopping List failure -> Retry | Giữ ingredient/manual edits; khi thành công list một lần, error có hướng phục hồi | Planned |
| TC-19 | Hoàng | S06 không alternatives -> Edit Preferences -> quay lại | Empty rõ; về đúng flow alternatives, kết quả mới đúng settings | Planned |
| TC-20 | Hoàng | S06 chọn replacement -> cancel/keep original | Recipe ID và ingredient totals không đổi; Back đúng nguồn | Planned |
| TC-21 | Hoàng | Confirm replacement failure -> Retry sau phục hồi | Món cũ giữ khi lỗi; success áp dụng đúng một lần và recalculation đúng | Planned |
| TC-22 | Hoàng + Thắng | Đi bốn tabs, S05/S09/S10 detail, Back từ nhiều origin | Tab/selected/route stack đúng; không hard-code Back về một destination; states lỗi/thiếu target có fallback | Planned |
| TC-23 | Charlie | PDF local đã có; upload denied/network -> Retry | Không success giả; local file giữ, error có lý do; same export ID; đủ progress/final state | Planned |
| TC-24 | Charlie | App foreground, Console test message | Visible feedback/inbox đúng marker, UI cập nhật, dedup/target hợp lệ | Planned |
| TC-25 | Charlie + Thắng | App đã đăng ký FCM, terminated không force-stop; tap push cold-start | Initial message được xử lý sau auth/router, đúng target, không crash | Planned |
| TC-26 | Charlie | Android 13+ permission chưa cấp -> Deny -> sử dụng app | Permission state rõ, không lặp dialog vô hạn; app vẫn dùng được, history/target errors có feedback | Planned |

TC-09/10/24/25 cần operator/server-side Console actions. Ghi chúng là **operator-assisted** nếu harness chưa tự động hóa, mô tả rõ người làm bước nào; không gắn nhãn fully automated toàn kịch bản khi không có khả năng đó. Muốn đổi yêu cầu công cụ phải có chấp thuận giảng viên, không tự thay ARTEMIS bằng thao tác tay.

### Mapping với test plan hiện có

- TC-01..11 giữ nguyên chủ đề của bảng leader. TC-07 bổ sung S09/citation; TC-09 bổ sung kiểm tra **hai hành vi**; TC-11 mở rộng logout isolation, không đổi thành testcase khác.
- TC-02 hoặc TC-04 phải có ít nhất một assertion Analytics từ captured Logcat/DebugView; Console screenshot chung chưa đủ cho yêu cầu một test xác minh event.
- TC-03/14/15/16/18/19/21/23 là nhóm error/alternative; mỗi precondition/failure mechanism phải được owner mô tả khi viết script.
- Mọi data-loading screen vẫn cần checklist loading/empty/error/retry, ngoài coverage E2E. Không chỉ kiểm tra một ErrorStateView ở S03 rồi suy ra toàn app đạt.

## 4. Failure matrix sáu services theo Guide v5

| Công nghệ / Guide | Success evidence | Failure/default evidence | Owner/task |
|---|---|---|---|
| Auth / tr.5-7 | Account picker, logged-in/out app, Users Console | Cancel và network/profile denied phân biệt; protected route/session logout | Charlie, S3-3/S3-5/S3-9 |
| Storage / tr.8-10 | PDF, progress, URL, owner-path file Console, storage.rules | A/B access denied; mất kết nối; giữ local file/retry; không open rules | Charlie, S3-7/S4-10/S4-11/S4-15 |
| FCM / tr.11-13 | Ba lifecycle states và tap target/inbox/device marker | Android deny; target thiếu/sai quyền; dedup và cold start; token evidence được bảo vệ | Charlie, S4-12/S4-13/S4-15 |
| Analytics / tr.14-16 | >=7 events, typed params/trigger/question/flow, UID, DebugView từng event | Không PII hoặc profile measurements không cần thiết; logging errors không chặn nghiệp vụ | Thái An + owners, S5-1..S5-5 |
| Crashlytics / tr.17-19 | Console non-fatal thật và test crash, UID/custom key | Lỗi thật vẫn có user message; reopen gửi report nếu cần; crash demo không ở flow thường | Thái An, S5-6/S5-7 |
| RC / tr.20-22 | Active defaults, Console values và hai behaviour changes cùng build | Offline/fetch fail vẫn dùng defaults/safe active; giải thích interval/cache, không đòi “ngay lập tức” vô điều kiện | Thái An + owners, S3-8/S5-8/S5-9 |

Config mới phải làm mới VM/UI state; hiện `ProfileViewModel` getters và wrappers chưa chứng minh notify/UI behaviour. Dùng lỗi nghiệp vụ thật đã xử lý để gửi non-fatal, không tạo lỗi giả rồi mô tả như crash production.

## 5. Thiết kế và unit/widget/rules checks

Các unit/widget tests sau là cách kiểm chứng tập trung rủi ro, không ngưỡng số lượng mới của thầy:

- Generator: đủ 7 ngày/số bữa; no-candidate; rules đã có source, không hard-code persona; không công thức mới chưa xác nhận.
- Ingredient: ID/unit aggregation, conversions đã chốt, finite >0, rounding, manual override và Undo.
- State: lỗi save/replace giữ data, double-submit guard, empty khác error, retry cùng operation ID.
- Persistence/session: checked theo list/reopen/new-list; logout A/login B, stale callbacks/listeners/URL cache.
- PDF: file bytes/local save/open và layout/Unicode đọc được, plan/revision/content đúng, retry ID.
- UI: S01-S10/Sign-in/Profile dùng Figma làm tham chiếu, fonts/tokens/variants nhất quán; cải tiến có chủ đích được kiểm tra và ghi lý do/ảnh/review trong repo theo [UI contract](FIGMA_IMPLEMENTATION_CONTRACT.md). Theo quyết định user/team 02/11, không sửa/đồng bộ Figma; code/runtime được chấp nhận là baseline UI hiện hành. Giữ body >=14sp, hit target >=48dp, 360/412/max-width; keyboard/text scale/TalkBack và checked/selected/error semantics.
- Rules: signed-out, owner A, non-owner B; role/status/uid invariants và deny cases. Admin không tự đổi role; owner không duyệt plan bằng cách patch status.

Firebase SDK gọi đúng lớp không đồng nghĩa security đã đúng. Cần emulator checks cho state transitions/schema; Final yêu cầu allowed/denied **mỗi role x mỗi collection** và tất cả pass.

## 6. Test toàn hệ thống cùng Assignment (Final PDF)

Không đánh dấu các case này là dự án khác hoặc mặc định optional. Chúng được tích hợp khi SYS workstreams sẵn sàng, cùng data model và design system.

| ID | Coverage | Acceptance |
|---|---|---|
| SYS-T01 | Web sign-in/role rejection | user bị từ chối web staff; staff/admin đúng role; mobile sai role báo rõ; native UI rejection không thay rules |
| SYS-T02 | Web management | list/search/create/edit/archive recipe; mobile đọc kết quả phù hợp, loading/empty/error |
| SYS-T03 | Review queue | Item mobile submitted -> approve/reject kèm reason; quyền và transitions đúng |
| SYS-T04 | Dashboard | >=3 số liệu aggregation và một chart từ data thật, không số hard-coded; web checklist screenshot |
| SYS-T05 | Announcement | Form ghi announcements -> mobile inbox realtime; phân biệt với FCM push |
| SYS-T06 | Cross-role end to end | Mobile + web deployed, đo write->UI latency; sequence collection/fields/rule/actor; chạy >=3 lần |
| SYS-T07 | Gemini level 2 | JSON->model hợp lệ, label AI, user sửa/xác nhận; 3 input/output thực, events cần thiết; mobile E2E >=3 runs |
| SYS-T08 | AI fallback/config | quota/network/invalid output/off flag vẫn hoàn thành S06; model/prompt/on-off RC/App Check được chứng minh; failure thật có log |
| SYS-T09 | Rules/App Check/shared package | Role x collection allowed/denied pass; schema/transitions; Firestore/AI Logic App Check; shared core/MVVM hai clients |

Web checklist theo hành động chính/role rejection/empty/error mỗi screen; không tự áp mọi web case ba lần như một yêu cầu trong đề. Mobile AI/cross-role steps dùng ARTEMIS ba runs; cross-role deployed ba lần riêng, không lấy một loại run thay cho tất cả.

## 7. Ghi kết quả, review và evidence

Giữ thư mục team đã tạo: `evidence/auth`, `storage`, `fcm`, `analytics`, `crashlytics`, `remote-config`, `artemis`, `review`. Bổ sung `ui`, `rules`, `system` khi có scope; không tạo cây evidence thứ hai cạnh tranh.

```text
evidence/artemis/TC-01/<run-id>/
  metadata.json   # build/commit/device/profile/model/project/fixture/time
  raw-trace-or-replay
  screenshots/
evidence/artemis/results.csv
  # test_id, run_id, status, duration, trace_id, build, issue, evidence
```

- Formal run >=3/case, giữ cả failed/skipped/flaky; denominator không bỏ run fail. Phân tích app/timing/instruction/semantics và liên kết fix/rerun. Không chạy lặp một ca đã biết hỏng chỉ để đủ số trước khi sửa.
- Pro exploratory 15-30 phút, có start/end, profile/model, trace và issue list; không giả số issue nếu không phát hiện.
- AI PR review >=5 real findings, >=2 types; mỗi finding quyết định/lý do. >=3 accepted fixes commit riêng chứa finding ID. Phần code hệ thống mới có >=3 findings/decisions theo Final.
- Tool disclosure chỉ ghi tool thực dùng và mục đích. Các tool trong template không tự trở thành đã dùng; phiên này dùng Codex để đọc repo/PDF, đối chiếu và cập nhật docs, chưa chạy CodeRabbit/Copilot/ARTEMIS.
- Tách Installed/Configured/Implemented/Verified và giới hạn. Console screenshot đúng project ID; copy cảnh UI mẫu không chứng minh cloud/permission/persistence.

## 8. Bộ bài nộp của cùng Assignment

Guide tr.25 + Handout: report 8-12 trang, slides 12-15, video 5-10 phút. Final: report 10-15, slides 12-15, video 8-12 phút + web URL và nội dung hệ thống. **DEC-02 đang cần leader chốt rubric áp dụng**; phương án chuẩn bị chung 10-12 trang / 12-15 slides / 8-10 phút nằm trong các khoảng, không tự giảm nội dung bắt buộc.

Một bộ hồ sơ: baseline Lab 2/persona/flows -> architecture/tokens/data -> sáu Firebase technologies và failure -> E2E/review/evidence -> web/cross-role/AI khi scope đó hoàn tất -> lessons/AI disclosure/contributions. Mỗi claim “works” có evidence; link phải mở được ở cửa sổ riêng tư, phần chức năng vẫn cần đúng demo role.

## 9. Definition of Done

- [ ] Đúng 10 screens Lab 2 + additions cần thiết, ba flows đủ recovery, fidelity/runtime a11y.
- [ ] MVVM/DI rõ, UI không gọi services/SDK trực tiếp, true data/no sample fallback, ownership/persistence/session isolation.
- [ ] Sáu Firebase services có success/failure behaviour và Console/log evidence theo Guide.
- [ ] >=7 Analytics events, >=2 RC behaviours, Crashlytics non-fatal thật + crash test + UID/key.
- [ ] ARTEMIS thật >=10 cases/coverage đủ, >=3 runs mỗi case, observed-value assertions, native/error/exploratory; không Dummy SUCCESS.
- [ ] PR review real findings/decisions/fix commits, no placeholder evidence.
- [ ] SYS scope web/cross-role/AI/security/shared core theo Final đóng hoặc có quyết định giảng viên điều chỉnh rõ.
- [ ] DEC-01/02 về Storage và rubric/deliverables được ghi nhận trước nộp; không tự mặc định một PDF đã hủy PDF kia.
- [ ] Report/slides/video/web URL theo scope, README chạy lại được, versions/pinned SHAs và đóng góp đúng; secrets không commit.

Nguồn: Guide v5 tr.1-25; Handout Lab 3 sections 3-11; Final sections 3-12; repo/task baseline `ae35f07`. Đây là kế hoạch nghiệm thu, chưa phải bảng kết quả.
