# Kiểm toán 26 task Hoàng (Lab 3) và HD Final — 11/11/2026

Bản này là **bảng bằng chứng hiện tại, không phải xác nhận nghiệm thu 100%**. Nguồn đối chiếu: docs/tasks/task-hoang.md, docs/tasks/final-task-assignment.md, docs/hoang-native-acceptance-20261111.md, report/hoang-implementation-report.md và kết quả CI trên máy.

Phép kiểm vừa chạy: **Flutter Analyze 0 issues; 487/487 Flutter tests; Android APK build thành công và cài đè Galaxy A15 thành công**. Lưu thành công Firestore là thông báo app, chưa phải independent read-back. Bản mới nhất tiếp tục thêm toàn bộ sourceNote tại S05, cần xác minh trong lần chạy sau.

## 26 task Lab 3

| Task | Trạng thái có bằng chứng | Kiểm chứng còn thiếu / đối chiếu |
| --- | --- | --- |
| S0-3-HD | Có công cụ và máy Android | Đã build/cài Samsung A15; còn rà flutter doctor toàn diện |
| S1-2 | Có schema; chờ dữ liệu được duyệt | Firestore dùng thật qua app; recipe nutrition/nguồn cần phê duyệt độc lập |
| S1-5 | Đã triển khai code, chờ Figma | Sign-in/Profile; chưa có duyệt Page 03/06 |
| S4-1 | Có code/test, live một phần | Models, IDataService, Firestore; native lưu thành công client, S10 read-back thiếu |
| S4-2 | Có code/test | ViewModel và 4 states; 487/487 Flutter tests chung |
| S4-3 | Có code/test; thiếu nghiệm thu native | Plan getter và PDF tests, chưa xuất PDF trên A15 sau save |
| S4-4 | Native một phần, chưa đủ E2E | S02→S03→S04→Save thành công theo client; S10 re-open pending |
| S4-5 | Có code/test, chưa native | S07/S08 edit/undo/persistence chưa chứng minh trên A15 |
| S4-6 | Native một phần | S05/S06 Empty/Retry/→S02 thật; S09 và thay món thành công chưa xác minh |
| S4-7 | Có code/test, native một phần | S06 Empty/Retry thật; offline và toàn bộ màn chưa được nghiệm thu |
| S4-8 | Có code/test; thiếu TalkBack | Semantics Flutter tests; TalkBack end-to-end thực tế pending |
| S4-9 | Đủ đầu ra kỹ thuật | Fake service và ViewModel unit tests chạy |
| S4-16 | Có responsive tests; pending toàn bộ | 360/412dp, chữ 100/200%; thiết bị A15, contrast/TalkBack đầy đủ pending |
| S4-17 | Có tài liệu; pending duyệt Figma | Traceability đã có, chưa được nhóm duyệt sai lệch của 10 màn |
| S5-3 | Có code; thiếu Console | Analytics events có mã, DebugView live chưa có |
| S6-5 | Có script; chưa có ARTEMIS run | e2e_test/test_flows.py và test_search.py; đã có vài runs thực nhưng chưa đủ 3 lượt mỗi case |
| S6-6 | Có script; chưa có ARTEMIS run | test_detail.py đã có 3 runs trên 3 ca khác nhau (1 completed, 2 failed); không được lấy compileall làm test E2E |
| S6-13 | Có regression fixes; chưa chứng minh ARTEMIS | Đã sửa UI phát hiện qua native; không có run ARTEMIS + retest |
| S7-1-HD | Có đầu ra kỹ thuật | PR #20 từng merged và review AI; PR #40 mở chờ checks/review cuối |
| S7-2-HD | Có đầu ra kỹ thuật | Bảng findings/quyết định trong docs/code-review.md |
| S7-3-HD | Có đầu ra kỹ thuật | Các commit sửa nhận xét CodeRabbit đã có |
| S8-2 | Có báo cáo và ảnh thật | report/hoang-implementation-report.md + evidence Android; chờ nhóm duyệt |
| S8-6 | Có slide 4 trang và ảnh thật | slides/Longvita_Hoang_4_Slides_Verified_20261111.pptx; chờ nhóm duyệt |
| S8-11 | Chưa đủ bằng chứng | Không có video E2E 3 flows trên device được xác minh |
| S8-17-HD | Có đầu ra kỹ thuật | docs/worklog-hoang.md cập nhật ngày 11/11 |
| S9-5-HD | Chưa nghiệm thu | Chưa diễn tập live ARTEMIS + Remote Config + VModel + review |

## 9 task HD trong Final Assignment

| ID | Trạng thái và bằng chứng |
| --- | --- |
| HD-01 | PR findings Lab3 và fixes có mã; chưa review đóng toàn bộ mismatch ngoài phạm vi ảnh. |
| HD-02 | 10 màn có code, native đã đi qua S02 S03 S04 S05 S06; thiếu full path S07 S08 S09 S10 và Figma 10/10. |
| HD-03 | Có 4 states qua code/widget tests; native Empty S06 đạt; chưa đủ offline/error cho từng màn. |
| HD-03B | Role gatekeeper/bootstrap có unit tests; chưa test tài khoản staff đăng nhập mobile bị từ chối thật. |
| HD-04 | Inbox hiển thị CM-07 trên Samsung A15; chưa kiểm thử thông báo mới realtime. |
| HD-05 | Submit/approval có widget test; chưa có Staff Web→User Mobile live ba lần. |
| HD-06 | PDF generation/offline/Firestore metadata có unit tests; chưa có ảnh PDF thực trên A15. |
| HD-07 | Analytics/Crashlytics có instrumentation; chưa có DebugView/Crashlytics Console chạy live. |
| HD-08 | Báo cáo module Mobile cập nhật, ảnh thật 7 tệp + slides 4 trang; chờ review nhóm. |

## Trạng thái Git và giới hạn

- Main đã cập nhật tới 733aa7a và PR #41 được merge tại 706ffef. Nhánh Hoàng tích hợp remote PR #40 qua merge 4030f63, đã giải quyết hunk S04 và giữ nguyên thay đổi khác của PR #41. Bản mới đạt 576/576 Flutter tests với 0 vấn đề Analyze trên Mobile/Core/Web. Nhánh audit/resolve-pr40-pr41-20261111 là lịch sử snapshot cũ, không merge audit trực tiếp vào main.
- CodeRabbit PR #40 cần được nhóm kiểm tra trạng thái cuối sau khi push; PR #41 đã merge vào main. Không suy diễn kết quả check đã hoàn tất từ code local. Không coi MERGEABLE của từng PR với main là không conflict giữa hai PR.
- Không tự nhập recipe chưa qua gate dữ liệu, không tự ghi ARTEMIS success, không tiết lộ PII/credential.

## Bằng chứng giữ riêng

- Mobile code/QA: mobile/lib/screens, mobile/lib/viewmodels, mobile/test/flows.
- Ảnh đã cắt PII: evidence/hoang/android-a15-20261111/. Ảnh raw nằm ở D:\PRM393\Longvita_phone_evidence, không commit.
- Slide cập nhật: slides/Longvita_Hoang_4_Slides_Verified_20261111.pptx.
- Biên bản native: docs/hoang-native-acceptance-20261111.md.
- Lỗi còn chờ: ARTEMIS daemon, Firebase admin live role, duyệt nutrition, video và Figma đủ 10 màn.
