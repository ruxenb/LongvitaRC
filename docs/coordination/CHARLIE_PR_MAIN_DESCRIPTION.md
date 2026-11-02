# PR Charlie -> main — nội dung để người dùng mở PR

Chuẩn bị **02/11/2026** từ nhánh đã push `feature/charlie-auth-01`, sau PM xác nhận `c5059d8`. **Base:** `main`. **Compare/head:** `feature/charlie-auth-01`. Chưa có PR của nhánh vào main khi kiểm GitHub trong lượt cập nhật; người dùng sẽ tự mở, leader/team preview và quyết định merge.

Đây là PR tích hợp nền tảng mobile, không tuyên bố toàn Assignment hoặc mọi task Charlie đã Done. Source code không thay đổi trong gói cập nhật tiến độ/PR description này. Bản kiểm chứng PM mới nhất là code fix `2d547c7`, HEAD báo cáo `f1f397e`; commit docs sau đó không thay kết quả code.

## Tiêu đề đề xuất

```text
feat(charlie): design system, Firebase Auth và nền tảng PDF/FCM
```

## Nội dung để dán vào PR

### Thay đổi

Hoàn thiện nền tảng giao diện và Google Sign-in cho Longvita từ skeleton Lab 2: tokens/fonts và common widgets dùng chung, Firebase bootstrap có recovery, typed Auth outcomes và cách ly state theo phiên. Đồng thời tích hợp Analytics API mới từ main, siết Firestore rules và chuẩn bị services PDF/FCM cho các gói tiếp theo.

- Design system: theme/fonts/tokens, 9 nhóm common widgets và supporting components, QA 360/412 và text scaling. Hoàng có thể dùng `longvita_widgets.dart` để ghép màn.
- Firebase/Auth: project `longvita-8da7e`, Android ID `vn.edu.fpt.longvita`, google-services; Sign-in/cancel/profile-recovery/restore/logout, default role `user` và session epoch chống kết quả muộn từ phiên cũ.
- Firestore AUD-11: kiểm shape/role/status transitions và owner access, kèm 41 tests emulator. Theo báo cáo Dev, rules đã publish lên project trước PR theo duyệt Charlie; Hoàng/Thắng còn review B1–B5.
- Analytics: callers tương thích API mới; export params lấy từ bytes thực. Chưa có `eatingWindowHours` thì không gửi generate event thay vì bịa dữ liệu; chờ S02/Hoàng nối giá trị thật.
- FCM preparation: gateway, 4 callbacks, payload parser, inbox/dedup theo phiên, raw payload đi cùng entry đã chấp nhận. First accepted message thắng trong cùng phiên, tap duplicate dùng target đã được chấp nhận. Chưa phải live FCM hoàn chỉnh.
- PDF preparation: TTF regular/bold tiếng Việt, fixture layout và local store theo UID; chưa nối trọn luồng export của active plan/open/share.
- Docs/progress/evidence: giữ 112 IDs và ownership, Lab 3 = Assignment; Figma chỉ tham chiếu đóng băng, cải thiện UI trực tiếp trong code.

### Kiểm chứng

- PM chạy độc lập: `flutter analyze --no-pub` sạch, **133/133 tests pass**, `flutter build apk --debug` thành công trên code đã tích hợp main `614e731`.
- Bản tái hiện PM-FCM-01 giữ nguyên expected: pass. **PM-S3-5-01, PM-S3-5-02, PM-FCM-01 đều Closed — verified** trong phạm vi local regression.
- Firestore emulator **41/41 pass** ở lần kiểm trước; không chạy lại sau FCM fix vì `firebase/` không đổi. Không trình bày đây là lần chạy rules mới hoặc proof mọi live-role flow.
- Dev đã chạy Google success/cancel/restore/logout thật với SHA Charlie và có ảnh Console. PM không chạy lại live Auth/push trong lần đóng FCM.
- Unit/widget/gateway tests và fixture PDF không thay ARTEMIS/native/cloud evidence.

Nguồn trong nhánh PR: [PM xác nhận](https://github.com/ruxenb/LongvitaRC/blob/c5059d841b296e799cc261cb3e9d9f1e646b9ccc/docs/coordination/PM_REREVIEW_914508c.md), [progress 29 tasks](https://github.com/ruxenb/LongvitaRC/blob/feature/charlie-auth-01/docs/coordination/dev-reports/CHARLIE-PROGRESS-20261102.md), [Auth report](https://github.com/ruxenb/LongvitaRC/blob/feature/charlie-auth-01/docs/coordination/dev-reports/CHARLIE-AUTH-01.md), [bản sửa FCM](https://github.com/ruxenb/LongvitaRC/blob/feature/charlie-auth-01/docs/coordination/dev-reports/CHARLIE-PM-FCM-01.md), [FCM contract proposal](https://github.com/ruxenb/LongvitaRC/blob/feature/charlie-auth-01/docs/coordination/dev-reports/FCM-CONTRACT-PROPOSAL.md).

### Cần reviewer chốt

- **Thắng — A1/A2:** Auth interface, bootstrap/DI/AuthGate và route stack; route intent/ready hook cho FCM.
- **Hoàng — A3/A5:** session guards/clearSession trong MealPlan/Ingredient VM, Sign-in/code UI và active plan/revision S4-3.
- **Hoàng/Thái An:** Analytics generate fields; Home chưa có eating window nên event hiện chưa gửi. Fallback recipe hard-code A9 còn phải thay bằng catalog thật/empty/recovery.
- **Hoàng/Thắng — AUD-11 B1–B5:** resubmit rejected plan, tự duyệt plan, archive/schema/nested data và kiểu createdAt; bổ sung rules/tests khi policy đổi.
- **Thái An/team:** DEC-01 Storage/Blaze so với Final exclusion; quyền project/SHA còn thiếu, language DEC-05 và FCM sender/recipient/history policy.

### Phần tiếp tục sau PR

- S3-5 còn owner A3 và native A/B coverage; chưa tự đánh toàn task Accepted chỉ vì hai finding đã đóng.
- S3-7/S4-11: owner-only Storage rules/live upload/progress/cancel/retry, phụ thuộc DEC-01.
- S4-10: active plan thật, stable export ID, nối local store, open/share và kiểm trên Android.
- S4-12/S4-13: route/payload/history/token/recipient policy, push thật fg/bg/terminated và Profile/demo. Tin không có `recipient_uid` tới người login kế vẫn chưa được team chốt.
- S6/S7/S8: ARTEMIS thật, AI review trên PR, findings/fix traceability đúng Stage 7, report/slides/clip/worklog. Các findings PM hiện tại chưa tự thay bộ evidence PR bắt buộc.

**Tiến độ Charlie trước PR:** 6 task có kiểm chứng/evidence chờ nghiệm thu, 9 đang thực hiện/chuẩn bị PR, 2 skeleton, 12 chưa bắt đầu — tổng 29. Không quy thành % hoàn thành toàn bài hoặc tự chốt Done thay leader.
