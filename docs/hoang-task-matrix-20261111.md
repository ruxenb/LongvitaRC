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
| S4-3 | PDF được xuất và mở trên A15 | Android Print Preview 2 trang; Console metadata và offline reopen chưa xác minh |
| S4-4 | Native S04→S10 read-back thành công | Sau cài đè/restart S10 thấy plan 7 ngày ngày 11/11 và mở vào S04; chưa đọc backend Console |
| S4-5 | Native S07/S08 edit và checkbox persistence | S07 sửa→đọc lại→hoàn nguyên; S08 checkbox giữ sau trở lại và đã bỏ chọn; xóa/Undo native chưa chạy |
| S4-6 | S05/S06/S09 native đã đi qua | S09 hiển thị sách và URL nguồn; S06 Empty/Retry→S02; thay món thành công và offline error còn chờ |
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
| S8-2 | Báo cáo có thêm 13 ảnh Android thật | Ảnh redacted S04 S05 S07 S08 S10 PDF; nhóm chưa ký duyệt |
| S8-6 | Có slide 4 trang và ảnh thật | slides/Longvita_Hoang_4_Slides_Verified_20261111.pptx; chờ nhóm duyệt |
| S8-11 | Chưa đủ bằng chứng | Không có video E2E 3 flows trên device được xác minh |
| S8-17-HD | Có đầu ra kỹ thuật | docs/worklog-hoang.md cập nhật ngày 11/11 |
| S9-5-HD | Chưa nghiệm thu | Chưa diễn tập live ARTEMIS + Remote Config + VModel + review |

## 9 task HD trong Final Assignment

| ID | Trạng thái và bằng chứng |
| --- | --- |
| HD-01 | PR findings Lab3 và fixes có mã; chưa review đóng toàn bộ mismatch ngoài phạm vi ảnh. |
| HD-02 | Cả S01–S10 đã có kiểm tra native | Đường đi/hiển thị 10 màn trên Samsung A15 đã quan sát; Figma đối chiếu chi tiết, loading/error/offline, a11y chưa đủ |
| HD-03 | Có 4 states qua code/widget tests; native Empty S06 đạt; chưa đủ offline/error cho từng màn. |
| HD-03B | Role gatekeeper/bootstrap có unit tests; chưa test tài khoản staff đăng nhập mobile bị từ chối thật. |
| HD-04 | Inbox hiển thị CM-07 trên Samsung A15; chưa kiểm thử thông báo mới realtime. |
| HD-05 | Submit/approval có widget test; chưa có Staff Web→User Mobile live ba lần. |
| HD-06 | PDF native 2 trang được mở trên A15; App báo lưu/sync; chưa chứng minh Console metadata và offline after restart |
| HD-07 | Analytics/Crashlytics có instrumentation; chưa có DebugView/Crashlytics Console chạy live. |
| HD-08 | Báo cáo và ảnh QA native bổ sung; 13 ảnh redacted, biên bản và báo cáo; video 3 flows và nhóm duyệt còn chờ |

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

## Cập nhật Android 17:30 ngày 11/11

PR #42 đã merge. Có bằng chứng native mới: S10 read-back; S07 edit/validation/read-back/restore; S08 checkbox/read-back/restore; S05 toàn nguồn; Profile PDF 2 trang. Lưu tại evidence/hoang/android-a15-20261111/native-*.png. Không thay chứng cứ ARTEMIS và console bằng widget tests. Bộ recipe staged vẫn bị chặn publication.

## S09 thực tế và main build mới 17:38

S09 từ S05 đã mở trên Samsung A15, UIAutomator xác nhận 4 nguyên tắc và nguồn URL rõ ràng. Main 95b1c31: 576/576 Flutter tests đạt, 0 issues Analyze Mobile/Core/Web, APK debug build và cài thành công. Hiện Firebase search chỉ trả 2 recipe; 29 recipe catalog code mới chưa phải là chứng cứ duyệt/publish. 14 ảnh native redacted ở evidence/hoang/android-a15-20261111.
