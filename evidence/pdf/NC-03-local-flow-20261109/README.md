# NC-03 — PDF local, metadata độc lập và Analytics

**Ready for PM flow review**, 09/11/2026. Code `13a188c` trên `feature/charlie-pdf-local-01`, tiếp nối NC-02 `96713e7` từ main `92bac93`. Chưa push/PR/merge. GitHub được fetch tới `134910d` (màn công thức, preview, tokens, Gradle properties); chưa tích hợp phần đó vào nhánh này.

## Hành vi đã triển khai

- Mặc định Final: kiểm phiên và owner của plan, dựng đúng snapshot đang chọn, lưu PDF local, công bố thành công rồi phát một `export_report`. Firestore dùng repository NC-02 riêng; `main.dart` không tạo Storage trong Final.
- ID `pdf_{UTC}_{16 hex}` không chứa UID/plan ID. `createdAt` lấy một lần; plan chưa lưu có `planId=null`. LocalReportStore dùng staging exclusive và hàng đợi theo UID: collision bị từ chối, không thay bytes cũ, kể cả hai store instances. Tên legacy chỉ được đổi thành tên trung tính khi truyền ra viewer/share; không rename file trên đĩa.
- Metadata có trạng thái riêng `saving/pending/confirmed/error`. Sau 15 giây chỉ đổi nhãn state sang pending; Future SDK gốc vẫn được giữ. Pending không retry tự động; retry sau lỗi gửi đúng payload/ID cũ, không tạo file hay event. Lưu PDF mới có thể bắt đầu khi metadata cũ chưa xong.
- Token từng lượt và epoch phiên chặn ack/error/timer cũ ghi đè export mới, A→B và A→logout→A. Logout vẫn dọn PDF theo UID qua hàng đợi đã có; không hứa hủy write Firestore đã gửi.
- Analytics chậm/lỗi và Crashlytics lỗi không khóa export hoặc biến local success thành thất bại. Giữ tham số Analytics của S5-4, không đổi contract `report_topic`.
- Demo chỉ bật bằng `--dart-define=PDF_EXPORT_MODE=storage_emulator_demo` cùng `--dart-define=STORAGE_EMULATOR_HOST=10.0.2.2` (Android AVD; hoặc `127.0.0.1`/`localhost` khi phù hợp). Host thiếu/sai hoặc mode khác đều về Final. Adapter chỉ nhận host local, await cấu hình SDK thành công trước upload; setup lỗi/cancel trước ready không tạo upload và không fallback cloud.
- `exportState` dành cho local PDF; `uploadState` dành cho demo. Alias `exportAndUploadPdf` được giữ để các call site cũ biên dịch, nhưng không quyết định upload. Demo vẫn giữ single-flight upload/retry, progress, cancel và cùng file/URL.

## Kiểm đã chạy

| Kiểm | Kết quả |
|---|---|
| Toàn bộ Flutter | **440/440**, NC-02 411 +29 ca mới |
| Analyzer lib/test | Không issues |
| APK debug mặc định Final | Build thành công, SHA/size trong verification.json; chưa cài/chạy |
| Đột biến | **7/7** bị test bắt; đã khôi phục source trước kiểm cuối |
| Whitespace | `git diff --check` sạch |

24 ca local-flow mới gồm: pending 15s giữ nguyên Future; retry payload/ID/file và không thêm event; export mới khi write cũ chưa xong; ack/error/timer cũ; hai loại đổi phiên; double tap; owner sai; plan chưa lưu; generate/save failure; Analytics chậm/lỗi/đổi phiên; collision RAM/đĩa/hai store; tên legacy; mode fail-closed; Final zero upload kể cả khi truyền adapter. Bốn ca adapter kiểm readiness/setup failure/cancel-before-ready/host. Một widget test đi qua Profile Final, đúng thông báo local, không URL/nút upload retry/cancel. Hai regression chọn plan/đổi món và cleanup theo UID đã chạy bằng Final với các assertion nội dung/file giữ nguyên.

Đột biến M1 bỏ guard metadata callback; M2 đổi pending thành lỗi; M3 log thêm ở retry; M4 bỏ event local; M5 cho phép clobber file; M6 bỏ await Emulator setup; M7 bỏ allowlist host. Tất cả làm test hành vi thất bại, không tính compilation failure là phát hiện lỗi.

## Vì sao các test cũ đổi expected

Các test Storage đặt mode demo rõ ràng và repository fake; lỗi/progress/cancel chuyển sang `uploadState`, không hạ yêu cầu file/URL/cách ly phiên. Vì event nay phát lúc lưu local nên upload lỗi/hủy vẫn có một event, hai export A/B có hai event; callback upload cũ không tạo thêm. Filename không còn chứa plan ID: thay kiểm prefix bằng planId riêng, regex tên ẩn danh và bytes của PDF thứ hai. Invalid planId có dấu slash bị từ chối; plan thực sự chưa lưu dùng ID rỗng → null. Test trước cho phép replace file và fake store được đổi cùng policy create-only thật. Fixture overlap hiện tạo plan theo UID đang đăng nhập; thêm test riêng từ chối plan user khác.

## Giới hạn và bước dừng

Đây là unit/widget tests với fake và một số thao tác đĩa thật trong thư mục tạm. Không có native NC-03, GA4 mới hoặc Firestore production evidence. SDK S1/S2 và rules thuộc evidence NC-02; không chạy lại rules vì không đổi rules. Không deploy, ghi production, đổi billing/bucket hay package/lock. Raw logs, APK và ảnh test tự sinh giữ local ignored, không đưa vào evidence này.

Profile chỉ được sửa tối thiểu để thông báo đúng local/Emulator và build được. **NC-04 còn UI metadata saving/pending/confirmed/error/retry và Semantics đầy đủ; NC-05 còn native Spark/Firestore thật cùng kiểm demo Emulator sau tích hợp.** Chưa nghiệm thu toàn gói Final hoặc đánh CM-01/HD-06/CM-03/CM-04 Done. 29 task gốc giữ 19 hoàn tất /0 chờ /7 đang làm /3 điều chỉnh phạm vi.
