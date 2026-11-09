# NC-04 — Profile local PDF + thông tin đồng bộ

Code `5cab63b`, sau NC-03 đã Charlie xác nhận. Final thể hiện file local và thông tin báo cáo riêng: saving, pending15s, confirmed hoặc lỗi có Thử đồng bộ lại. Mở/chia sẻ dùng được khi pending/lỗi; không có URL, nút upload retry/cancel hoặc phần trăm upload trong Final. Demo vẫn giữ progress/URL/actions riêng. Nếu file local đã mất, bỏ các nút mở/chia sẻ và hiện yêu cầu xuất lại; không xóa metadata server.

**Kiểm:** full Flutter452/452 (thêm12widget cases), analyzer lib/test sạch, APKdebugFinal build được. Hai kiểm âm tính bỏ metadata UI hoặc xử lý missing file đều làm test tương ứng fail. Test fake-clock chờ đúng trạng thái Auth và frame; Future còn pending được hoàn tất khi kết thúc ca để không rò Timer. Không hạ assertion để che lỗi.

Widget cases bao phủ saving→pending→confirmed; lỗi/retry payload không trùng event và vẫn mở/share; missingfile; loading button disabled/no tap; pending/error ở360/412dp ×textScale1/2. Kiểm liveRegion, button action, tránh diagnostics thô ra UI. Các heading/TalkBack semantics regression cũ vẫn pass.

Đây là widget/fake + build evidence; native NC-05 sẽ kiểm riêng. Không deploy hoặc ghi production trong NC-04. Không sửa Figma, route/AuthGate/FCM/RC/Crash nghiệp vụ, package hoặc rules. Raw logs và ảnh suite tự sinh lưu local ignored. PM đã đối chiếu UI/state/diff và chuyển NC-05 theo yêu cầu Charlie làm hai bước còn lại; chưa tự công bố toàn gói100% từ widget tests.
