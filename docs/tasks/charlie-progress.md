# Charlie — bàn giao kỹ thuật cho team, 02/11/2026

Nhánh **`feature/charlie-auth-01`** đã tích hợp main `614e731`; PR vào `main` phục vụ leader/team preview và quyết định merge. Đây là bàn giao nền tảng mobile của cùng Assignment, không tuyên bố toàn bộ các task đã hoàn tất. Lab 3 = Assignment; Figma Lab 2 là tham chiếu đóng băng, UI được cải thiện trong code.

**PR đang mở:** [#1 — design system, Firebase Auth và nền tảng PDF/FCM](https://github.com/ruxenb/LongvitaRC/pull/1). S7-1-CM đang thực hiện; chưa có AI PR review output và chưa merge vào main.

## Tiến độ 29 task

| Trạng thái | Số lượng | IDs |
|---|---:|---|
| Có kiểm chứng/evidence, chờ nghiệm thu | 6 | S0-3-CM, S2-3, S2-4, S3-3, S3-4, S3-9 |
| Đang thực hiện / PR | 9 | S0-4, S3-1, S3-2, S3-5, S4-10, S4-12, S4-14, S5-4, S7-1-CM |
| Skeleton | 2 | S3-7, S4-11 |
| Chưa bắt đầu | 12 | S4-13, S4-15, S6-4, S6-7, S6-14, S7-2-CM, S7-3-CM, S8-3, S8-7, S8-12, S8-17-CM, S9-5-CM |
| **Tổng** | **29** | |

Chi tiết IDs/owner/dependency tại [task Charlie](task-charlie.md) và [master 112 task](danh-sach-task-full.md). Chưa tự đánh Done thay leader; S7-1 đang thực hiện, chưa có AI PR review output để tính đủ Stage 7.

## Phần đã bàn giao

- **UI:** tokens/theme, Fraunces/Newsreader/Quicksand bundle cùng license, 9 nhóm widgets và supporting components. Team dùng `package:longvita/widgets/longvita_widgets.dart`; gallery và QA trong `test/qa/`. Screen integration/visual acceptance còn theo owner.
- **Auth:** Firebase project `longvita-8da7e`, app ID `vn.edu.fpt.longvita`, google-services; typed Auth outcomes, profile recovery, bootstrap gate, restore/logout và session epoch. UID/profile lỗi không bị báo thành cancel. Đổi phiên loại response/progress/error muộn; không xóa cloud records của user cũ.
- **Firestore AUD-11:** schema/role/status/owner constraints và 41 emulator tests. Theo ghi nhận của Charlie, rules đã publish lên project trước PR; Hoàng/Thắng còn cần review các policy bên dưới.
- **Analytics:** callers theo API mới của Thái An. Export params lấy từ PDF bytes thực. Chưa có eating window thật thì không gửi generate event; Hoàng nối dữ liệu S02, không điền số giả.
- **FCM preparation:** gateway và 4 callback, parser, inbox/dedup theo phiên. Payload gốc đi cùng entry đã chấp nhận; first accepted message thắng trong một phiên, tap duplicate dùng target đã chấp nhận. Chưa phải live FCM hoàn chỉnh.
- **PDF preparation:** TTF tiếng Việt regular/bold, fixture PDF và `LocalReportStore` theo UID; chưa nối active plan/local/open/share/Android trọn flow.

Các commits chức năng: `6dfddf9` (UI), `56b1896` (Auth), `4e4bffd` (Firebase/rules), `9d76623` (session guards), `9ecc806` (Analytics callers), `7a9fa8c` (FCM), `40e47a1` (PDF), `2d547c7` (FCM recipient/dedup fix).

## Kiểm chứng và giới hạn

Code `2d547c7` / HEAD báo cáo `f1f397e` đã được kiểm độc lập: analyzer sạch, **133/133 unit/widget tests pass**, APK debug build thành công. Ca tái hiện recipient collision giữ nguyên expected đã pass. Hai lỗi response muộn qua đổi phiên và lỗi raw notification cache đã được xác nhận sửa; không tự đổi các fix này thành evidence PR Stage 7 hoàn tất.

- [Analyzer](../../evidence/review/PM-FCM-01-VERIFY/analyze.txt), [133 tests](../../evidence/review/PM-FCM-01-VERIFY/flutter-test.txt), [APK build](../../evidence/review/PM-FCM-01-VERIFY/build-apk-debug.txt), [recipient regression](../../evidence/review/PM-FCM-01-VERIFY/original-pm-repro.txt).
- [Rules 41/41](../../evidence/rules/AUD-11-20261102/new-rules-run.txt) là kết quả emulator trước; không chạy lại sau FCM fix vì `firebase/` không đổi. Không coi emulator là live rules/role evidence đầy đủ.
- [Auth thật](../../evidence/auth/S3-9-20261102/README.md): success/cancel/restore/logout với SHA Charlie. Ba máy còn lại, network/profile lỗi native và A/B native chưa được kiểm đầy đủ.
- FCM tests dùng fake gateway, history chỉ ở RAM; chưa push thật, chưa router/Profile/token binding. PDF dùng fixture, không chứng minh xuất đúng plan đang xem hay rootBundle/open/share trên Android.
- ARTEMIS thật, AI review trên PR và deliverables report/slides/video/worklog chưa hoàn tất. Các ví dụ trong `docs/code-review.md` không được tính là findings thật.

## Các điểm reviewer/team cần chốt

1. **Thắng (A1/A2):** Auth interface, bootstrap/DI/AuthGate/Back, route intent và điểm router ready cho FCM.
2. **Hoàng (A3/A5):** session guards/clearSession của MealPlan/Ingredient VM, UI Sign-in và active plan/revision S4-3. **Hoàng/Thái An:** dữ liệu generate Analytics và loại recipe hard-code fallback A9 khi catalog rỗng.
3. **Hoàng/Thắng (AUD-11 B1–B5):** rejected plan có được resubmit, staff tự duyệt plan, archive/schema/nested data và kiểu createdAt. Rules/test hiện theo schema model; thay policy phải sửa và kiểm lại.
4. **Thái An/leader (DEC-01):** Guide yêu cầu Storage upload, Final loại Storage; quyết định áp dụng/billing trước S3-7/S4-11. Không chặn Auth hoặc PDF local vì việc này.
5. **FCM contract còn mở:** route intent của `meal_plan`/`announcement` (Thắng); history local theo UID hay Firestore/schema/rules (Hoàng/Thắng); token theo user hay topic và cách xử lý tin thiếu `recipient_uid` (Thái An/Thắng). Hiện tin không recipient chờ người login kế, chưa được team chốt cho production.
6. **Charlie/team:** mời đủ thành viên Firebase, nhận SHA-1/SHA-256 và kiểm Google Sign-in trên từng máy; quyền Console và SHA/Auth là các đầu việc riêng. Đồng thời chốt ngôn ngữ UI và font Roboto cho PDF.

Sau review: tiếp tục S4-10 với active plan/local/open/share, S4-12 routing/history/token/push thật, S4-13 Profile/demo cùng Hoàng; S3-7/S4-11 khi DEC-01 rõ. Giữ nguyên ba fix regression đã xác nhận và các task owners.
