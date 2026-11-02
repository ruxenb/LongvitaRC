# Giao Claude Code - CHARLIE-UI-01

Ngày chuẩn bị/cập nhật: **02/11/2026**. UI-01 **Ready for PM review**, đã có commit `6dfddf9` trong nhánh đã push `feature/charlie-auth-01`; chưa Accepted. Xem [báo cáo Dev](dev-reports/CHARLIE-UI-01.md) và [PM review mới nhất](PM_REVIEW_CHARLIE_20261102.md). PM đã chạy lại 69 tests hiện có có bao gồm QA UI, chưa nghiệm thu visual toàn bộ components/screens. Auth đã có evidence Android ở gói sau; không dùng trạng thái “chưa chạy Android” lúc UI-01 bàn giao làm mô tả toàn repo hiện tại.

**Quyết định UI mới của user/team:** Figma chỉ là tham chiếu đóng băng. Tiếp tục cải thiện UI trong code, ghi lý do/evidence và review trong repo; không sửa Figma hoặc yêu cầu cập nhật Figma để đóng D1/D5 hay các khác biệt khác. Các mục dưới là packet ban đầu, áp dụng theo chính sách hiện hành của [UI contract](FIGMA_IMPLEMENTATION_CONTRACT.md).

## Task IDs và mục tiêu

**S2-3 + S2-4** theo `docs/tasks/task-charlie.md`: hoàn thiện theme/tokens và chín nhóm common widgets đúng design system Figma Lab 2, để Hoàng có thể dùng lắp S01-S10.

PM/reviewer: Codex. Dev owner: Claude Code. User/task owner: Charlie. Giữ owner của teammates và code đã có.

## Scope

- `lib/theme/`, `lib/widgets/`, assets/fonts/icons và dependency declarations tối thiểu nếu có lý do cụ thể.
- Tests/QA host cho reusable components ở 360/412 và evidence liên quan.
- Hướng dẫn API/variants và token mapping ngắn để team dùng.
- Kế thừa skeleton, không làm lại repo. Trước chỉnh source, kiểm tra `git status/diff`; đang có các thay đổi Markdown do Codex, không reset hoặc đưa chung vào commit code không liên quan.

Ngoài scope: triển khai toàn bộ S01-S10 thay Hoàng, sửa generator/catalog/rules, Firebase billing/config/credentials, web/AI features, đổi state management hoặc mở module sản phẩm mới. Nếu cần thay API liên thành viên, mô tả ảnh hưởng để PM/team phối hợp; làm tiếp phần độc lập.

## Nguồn đầu vào

Đọc `CLAUDE.md`, working agreement, Figma contract, Charlie guide và source hiện có. Sources Figma chính:

- Foundations node `53:2`
- Component Catalog node `58:153`
- Component QA 360/412 node `58:711`
- S01 `103:5`, S04 `103:160`, S07 `106:189`: tham chiếu cách các component phối hợp; không tự thay các screen production của Hoàng.

URL đầy đủ trong [UI contract](FIGMA_IMPLEMENTATION_CONTRACT.md). Dùng baseline/reference/context đã lưu, gồm bộ bàn giao UI-01 ngày 02/11 và `assets/figma/`; không yêu cầu đọc live lại hay tạo/sửa node Figma để tiếp tục cải thiện trong code.

## Cách triển khai mong đợi

1. Xác nhận đang làm đúng repo/task và đã đọc các docs chính. Dùng reference/context/styles/assets đã lưu, ghi nguồn thực sự đọc; không chặn công việc vì thiếu kết nối Figma mới.
2. Đối chiếu tokens/fonts hiện tại với design đã duyệt; tạo bảng source token/style -> Flutter field/value, nêu conflicts chưa có quyết định. Không tự dùng Inter/màu mặc định để lấp thiếu.
3. Implement S2-3 trước rồi S2-4 theo components cần cho flows. Reuse props/variants, không một class cho mỗi Figma instance.
4. Đủ Button/TextField/Card/Navigation/AppBar/Dialog/Loading/Empty/Error và states của nguồn. Supporting components chỉ khi cần, cùng theme.
5. Tạo QA composition/test fixtures có nhãn rõ trong môi trường test; kiểm tra long Vietnamese text, loading/disabled/validation, 360/412, hit target/semantics và text scaling. Không thay data thật trong bản nộp bằng fixture.
6. Chạy checks thích hợp; render/chụp ảnh actual so với reference ở điều kiện thống nhất; sửa lỗi, ghi cải tiến có chủ đích để review trong code, không đồng bộ lên Figma.
7. Ghi API usage/known differences/evidence; báo `Ready for PM review` hoặc trạng thái chính xác với phần chưa kiểm chứng. Không tự ghi Accepted.

## Acceptance

- Theme bám semantic colors/fonts/spacing/radius/elevation của source được chốt; token values tập trung và component tham chiếu theme.
- Chín nhóm widgets đủ variants/states, reusable callbacks/state props, không SDK/business logic bên trong UI.
- Button đủ Primary/Secondary/**Destructive** theo Figma, cùng các variants còn được dùng. Skeleton đang cao 48dp; kiểm tra các mốc 52/56 được nêu trong review với token/component/instance hiện hành, ghi node/variant/value đã chọn. Hit target tối thiểu 48dp không thay chiều cao thiết kế, nội dung không cắt khi text scale lớn.
- Kiểm tra semantics tree/TalkBack cho Button normal/disabled/loading/icon: một tên truy cập, action/state đúng, không đọc lặp label do wrapper và child. Ghi kết quả thực trước khi kết luận có/đã sửa duplicate Semantics.
- Không mất hierarchy/image crop/line wrapping do dùng default widget style; không overflow ở viewports kiểm tra; accessibility theo handoff.
- Có một QA/example usage để Hoàng dùng ngay, chưa cần toàn bộ Firebase để review UI layer.
- Có actual visual evidence hoặc ghi rõ chưa có; analyzer/widget tests pass chỉ được báo đúng phạm vi đó.
- Không thay đổi các files ngoài scope để che gap. Không tạo evidence/claim pass, model run hoặc cloud behaviour giả.

## Bàn giao

Ghi `docs/coordination/dev-reports/CHARLIE-UI-01.md` khi thực hiện, gồm:

- baseline/branch và task IDs;
- exact Figma nodes/context/version/time và assets/fonts used;
- token/component API map và changed files;
- commands/results thật;
- reference + actual screenshot paths, viewport/DPR/textScale/fixture state;
- deviations, missing inputs và ảnh hưởng;
- checklist acceptance và trạng thái đề nghị.

Codex sẽ review diff, component behaviour, evidence và preview cùng Charlie theo chính sách UI mới. Bàn giao đã được ghi nhận; các D1/D3/D7/D11 trong báo cáo vẫn cần phân loại/review ở phạm vi tương ứng, không mặc nhiên được chấp nhận chỉ vì cập nhật chính sách. Không có dispatch tự động hoặc commit được tạo trong lượt này.
