# S5-4 — tham số export_report được kiểm trên GA4, 08/11/2026

**Kết quả kỹ thuật:** code `af129f9` giữ `topic` và bổ sung `report_topic` cùng giá trị, trong cùng một event `export_report`. Hai lần export thật (một đối chứng QA, một xác nhận code cuối) mỗi lần phát đúng một event. DebugView nhận `report_topic=longevity_meal_plan`, `file_size_kb=19`, `has_shopping_list=0`; không liệt kê `topic` dù SDK gửi nó. Chưa khẳng định nguyên nhân phía GA4 hoặc gọi `topic` là reserved.

Baseline `b31052f`; nhánh `feature/charlie-analytics-03`. Không đổi Auth, Profile nghiệp vụ, router, package, lockfile, Gradle, billing hoặc GA4 settings. Thay đổi production chỉ thêm alias và comment ở AnalyticsService; cập nhật contract trong `docs/analytics-plan.md`.

## Môi trường và cách kiểm

- Flutter 3.47.6, firebase_analytics 11.6.0; AVD LocalMate_API_35, Android 15. Auth/Firestore/Analytics thật: `longvita-8da7e`, package `vn.edu.fpt.longvita`, GA4 property `561857829`.
- Storage SDK thật dùng Storage Emulator `demo-longvita`, `127.0.0.1:9199` trên host / `10.0.2.2:9199` trên AVD, rules owner-only hiện có. Không phải upload Storage project thật.
- App khôi phục phiên A hiện có. Qua UI Home → Plan → kế hoạch đã lưu → Home → Profile → bấm Xuất báo cáo PDF một lần cho mỗi giai đoạn. Không gọi Analytics trực tiếp bằng dữ liệu giả, không logout hoặc tạo/xóa kế hoạch Firestore.
- Dùng kế hoạch A9 cũ đã lưu để kiểm Analytics/bytes; không tính đây là nghiệm thu recipes thật hoặc hai nội dung khác nhau của S4-10.

| Lượt | Build | SDK event / DebugView (giờ VN) | Số export_report tăng | Byte PDF máy = Emulator | Kết quả params |
|---|---|---|---:|---:|---|
| QA đối chứng | Debug + STORAGE_EMULATOR_HOST=10.0.2.2 + QA_EXPORT_TOPIC_ALIAS=true | 21:17:52.593 / 21:17:55 | 1 | 18.950 = 18.950 | SDK có cả topic/report_topic; DebugView chỉ có report_topic đúng giá trị, file_size_kb=19, has_shopping_list=0 |
| Code cuối | Debug + STORAGE_EMULATOR_HOST=10.0.2.2; không cờ QA alias | 21:27:39.140 / 21:27:41 | 1 | 18.950 = 18.950 | Alias permanent được xác nhận lại trên chính event mới; 19 và 0 đúng |

DebugView tổng có **2 export_report** từ hai thao tác có chủ đích, không phải 2 event cho một thao tác. Có thêm `screen_view` tự động; không gộp nó vào số export. Ảnh `03` và `06` ghi lần lượt export count 1 và 2.

QA chỉ bật alias với điều kiện `kDebugMode && bool.fromEnvironment('QA_EXPORT_TOPIC_ALIAS')`; điều kiện tạm này được gỡ trước build cuối, thay bằng alias luôn đi cùng topic. Release contract giữ khóa cũ và thêm khóa mới, không đổi chữ ký API.

## Bằng chứng

- `01`–`05`: params/value, số event của đối chứng; `05-qa-report-topic-value.png` hiển thị đủ giá trị alias.
- `06-final-export-count.png`: hai export theo hai thời điểm; `07-final-report-topic.png`, `08-final-file-size.png`, `09-final-shopping-list.png`: kết quả code cuối.
- `sdk-export-events.txt`: hai dòng Logging event gốc, chỉ che screen ID. Raw log vẫn local, không đưa UID/token/email lên Git.
- `qa-verification.json`, `final-verification.json`: số byte/hash và quan sát backend. Đọc file máy bằng `adb exec-out` để giữ nguyên byte; so với media đọc từ Storage Emulator cục bộ, trùng SHA-256. Dùng `adb shell cat` trên Windows có thể thêm CRLF vào stdout, không dùng nó để đánh giá file PDF.
- Ảnh là chụp vùng UI, loại khung user properties chứa UID; không sửa giá trị hoặc thêm nhãn kết quả vào ảnh. PDF, raw logs, metadata download token và APK chỉ nằm trong thư mục QA local.

## Điều kiện S5-4

| Điều kiện | Đánh giá kỹ thuật | Căn cứ / giới hạn |
|---|---|---|
| login/logout đúng trigger | Đạt theo evidence đã có và code không đổi | Evidence S5-4 ngày 02/11, lượt Auth/Analytics của Thắng ngày 06/11 trên main; Auth regressions trong suite. Không chạy lại login/logout ở lượt này |
| export_report một lần sau thành công | Đạt | Hai thao tác thật, hai event ở SDK và DebugView, mỗi thao tác một file mới trên Emulator |
| params đúng nội dung/kiểu | Đạt | SDK-boundary tests; backend report_topic/string, file_size_kb=19/int, has_shopping_list=0/int; PDF thực 18.950 bytes, chưa có shopping-list section |
| failure/cancel/phiên cũ không báo thành công | Đạt bằng test | Test Profile/report cho lỗi, retry, overlap, cancel, session; siết assertion đếm event đúng một lần. Không chạy lại các ca lỗi/hủy trên thiết bị |
| không PII và có traceability | Đạt trong evidence gói này | Params không thêm UID/email/plan ID; ảnh loại user properties; raw token/URL/PDF chỉ local. Đây không phải audit secret toàn repo S9-1 |

## Kiểm tra code af129f9

- `flutter analyze --no-pub`: no issues, [analyze.txt](analyze.txt).
- Toàn bộ `flutter test --no-pub --reporter expanded`: **391/391 pass** (388 cũ + 3 mới), [summary](full-suite-summary.txt).
- Analytics + Profile export/overlap: **49/49**, [log](targeted-tests.txt).
- Ba test SDK boundary mới: đúng một call, map/kiểu mặc định; đồng bộ topic tùy chọn; SDK lỗi không làm hỏng export và không phát lặp.
- Hai test contract params fail trên AnalyticsService baseline `b31052f`; ca SDK failure đối chứng vẫn pass. [Before log](service-regression-before.txt). Trên code cuối cả ba pass trong suite trên. Các assertion mới ở test có sẵn kiểm pending upload chưa log, success/retry chỉ một event và upload cũ của A không log vào phiên B.
- Build APK debug thành công cho cả bản dùng Storage Emulator và bản thường. Không đổi package/lockfile. Cảnh báo tương thích Kotlin tương lai và SDK XML có sẵn vẫn xuất hiện, không ngăn build.
- APK SHA-256: QA `22100240F0E330B5D68E86EC03C58F6D202AF5BF13D3B2FB88FF38699B9DB9F2`; code cuối dùng Emulator `1B8A770CED56992C05BCAF6D00EBAE3C75C4A68F7C0F28A6670F82E1A67AA01B`; bản thường `ABD54F73AB09C8A22CDEE415AC8E6E12AE7A7D5EAD2F2D8BE656ADE346293581`.

## Hoàn nguyên môi trường và giới hạn

Đã tắt debug Analytics (`.none.`), trả FA/FA-SVC về giá trị rỗng như trước, cài lại APK thường (không STORAGE_EMULATOR_HOST/QA_EXPORT_TOPIC_ALIAS), kiểm Home vẫn đăng nhập A rồi dừng AVD và Storage Emulator do lượt này mở. Giữ PDF local, không xóa dữ liệu người dùng hoặc dữ liệu cloud. Hai event debug vẫn là dữ liệu gửi tới Analytics project thật; không tự đổi data filter hay khẳng định chúng bị loại khỏi mọi báo cáo/export.

S5-4 **Ready for Charlie acceptance**, không tự ghi Charlie đã nghiệm thu. Storage project thật/DEC-01 vẫn theo S3-7/S4-11/S4-15; không dùng kết quả Emulator để đóng các task đó. Không mở đợt S6/S7 hoặc xử lý audit S9-1 trong gói này.

Nguồn API: [Firebase DebugView](https://firebase.google.com/docs/analytics/debugview), [firebase_analytics 11.6.0 logEvent](https://pub.dev/documentation/firebase_analytics/11.6.0/firebase_analytics/FirebaseAnalytics/logEvent.html). Đã đối chiếu 08/11/2026.
