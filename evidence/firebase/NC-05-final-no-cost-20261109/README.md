# NC-05 — Final No-Cost trên Spark

**Hoàn tất kiểm kỹ thuật; Ready for Charlie final acceptance.** Code `5cab63b`, tiếp NC-01/02/03 đã Charlie chốt và NC-04 đã PM đối chiếu. Chưa push/PR/merge. Đây là gói PDF local + metadata, không tuyên bố toàn Assignment hoặc mọi task CM/HD đã Done.

## Kết quả theo phạm vi đã chốt

| Điều kiện | Bằng chứng |
|---|---|
| Final không cần Storage | APK default không dart-define demo/host; Storage Emulator tắt khi kiểm Final; Spark/billing=false, Cloud Storage0bucket |
| Metadata thật | App FlutterFire client tạo5record, mỗi record đúng6field/ID/filename/size, đúng owner của plan; GET server độc lập đọc lại khớp |
| Offline | Tắt mạng AVD, local save và mở/share vẫn dùng được, UI pending15s; GET server404. Kết nối lại: đúng ID được xác nhận, chỉ1file mới |
| Đổi plan | Chọn hai plan đã lưu khác nội dung: plan-A3bữa và plan-B2bữa. PDF2/1trang;28/21dòng ngày/món khớp Firestore, đủ7ngày, đã xem render và viewer/share |
| Lỗi/retry/phiên | NC-02/03/04 regressions và SDK S1/S2; retry giữ payload/ID/file, không event trùng; A/B/cùng UID callback guard. Không gọi đây là native mới của NC-05 |
| Analytics | 5local saves →5event native service, size21/21/21/19/19KiB, report_topic đúng và has_shopping_list0; có HTTP204. DebugView chưa xem được, không đồng nhất SDK log với GA4 UI |
| Demo | Build riêng exactmode+host10.0.2.2; upload bằng app thật lên Storage Emulator, đọc độc lập và so đúng19.247bytes. Không upload Storage cloud |
| Khôi phục | Cài lại đúng Final APK/hash, Home vẫn tài khoảnA; mạng/log/debug trở về ban đầu; AVD, Emulators và logcat đã dừng |

Full Flutter **452/452**, analyzer lib/test sạch, Final và demo APK build được. Exact rules candidate **64/64** (50Firestore+14Storage), không lấy bộ rules khác để chứng minh bản deploy. NC-04 có12widgetcase và2negativechecks; NC-03 có29case và7mutants. Không chạy lại suite sau thay đổi chỉ evidence/docs.

## Deploy an toàn và khác biệt đã phát hiện

Rules live trước deploy khớp baseline ngoài việc **chưa có khối shopping_lists** của repo. NC-05 không tự triển khai khối đó: đã lưu release/source cũ, ghép DUY NHẤT khối metadata NC-02 vào rules live, assert bỏ khối này thì byte-text chuẩn hóa trở về live cũ. Re-check release ngay trước deploy rồi chỉ `firestore:rules`, đúng project longvita-8da7e. Readback sau deploy khớp candidate; release/hash/command đã lọc trong verification.json. `deployed-firestore.rules` là snapshot kỹ thuật của đúng candidate; canonical `firebase/firestore.rules` trong repo vẫn giữ Shopping và metadata.

Khối Shopping chưa deploy là tình trạng có trước gói này, cần owner đối chiếu riêng; không ghi Hoàng đã review hoặc S4-5 đã pass production. Không thay collection/rules khác, IAM, billing, Storage rules cloud, Hosting hoặc role schema. Lần guard đầu dừng vì hash LF/CRLF trên Windows; đã đối chiếu nội dung normalize khớp trước khi deploy, không bỏ qua guard. Release trước vẫn được giữ cho rollback; chưa rollback.

## Nguồn native và dữ liệu để lại

AVD LocalMate_API_35, imageAndroid35/google_apis, viewport320x640/density160. Không dùng ảnh giả hoặc QA host để thay app thật. Auth/Firestore/Analytics project thật; chỉ demo upload dùng Storage Emulator. Các screenshot01/04–10 đã chọn góc không có email/UID; ảnh demo có URL/token giữ riêng local. Raw PDFs, XML, SDK/logcat, APK, operator email và UID/path thật chỉ ở docs/coordination/qa/NC05-20261109 ignored.

Ledger5export gồm4Final và1demo. Có một Final export lúc thiết bị offline nhưng harness cuộn quá chỗ metadata nên không quan sát được pending; lượt này KHÔNG tính là native pending pass. Đã giữ file/event/record và chạy một lượt offline mới đúng trạng thái. Lần đợi online đầu cũng không cuộn được vì tọa độ vượtviewport; phục hồi chính file đã xuất, không bấm xuất lần nữa. Cold-start đôi lúc hierarchy chưa sẵn sàng; driver chỉ nhận dump mới hợp lệ, không đọc XML cũ. Tất cả các lượt đều giữ dấu vết.

Sau kiểm: **5metadata document mới và5PDF local mới**;17PDF cũ giữ nguyên (tổng22). Không tạo/sửa/xóa recipe hoặc meal_plan; dùng2plan đã có. Không tự xóa dữ liệu kiểm. Metadata không có file bytes/localpath/downloadURL. planId trong exports-readback.json được alias để không lộ UID nằm trong ID plan; các field còn lại và hash/size giữ nguyên. Demo object chỉ nằm trên Emulator đã tắt, binary copy lưu private.

## Giới hạn được phân biệt

- Browser IAB dùng Google identity không có quyền property này và hiện hộp email preferences; không gửi access request hay đổi email settings. Logcat+HTTP204 chứng minh SDK xử lý/gửi bundle, không chứng minh đã nhìn event/params ở GA4 DebugView. Đây là kiểm Console bổ sung nếu môi trường cho phép theo packet.
- Race đổi phiên, deny/retry và trạng thái hiếm dùng controlled tests/rules Emulator; native lần này tài khoảnA, không chạy lại toàn bộ S3-5/ARTEMIS/TalkBack. New liveRegion/button/layout được widget kiểm, chưa nghe TTS tiếng Việt hay chạy máy thật.
- PDF2trang có khoảng trắng ở trang2 theo layout đã có; không đổi template ngoài phạm vi gói. Màn lịch sử, đồng bộ/tải PDF giữa thiết bị và phục hồi UI file cũ sau khởi động không thuộc contract.

**Bước bàn giao:** Charlie chốt nghiệm thu toàn gói → push/PR/CodeRabbit/review → tích hợp main trước đợt Final UI. 29task gốc giữ19hoàn tất/0chờ/7đang làm/3điều chỉnh phạm vi; không đánh Storage cloud100% vì ngoài scope. Phạm vi No-Cost là xác nhận Charlie/nhóm, không bịa xác nhận mới của giảng viên.

API đối chiếu: [Firebase getAnalyticsDetails](https://firebase.google.com/docs/reference/firebase-management/rest/v1beta1/projects/getAnalyticsDetails) chỉ GET thông tin property; không đổi liên kết Analytics. Các API version-sensitive dùng SDK/CLI đang cài và đã chạy kiểm thực tế.
