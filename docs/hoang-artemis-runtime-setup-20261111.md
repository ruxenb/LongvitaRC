# Hoàng — Nghiệm thu ARTEMIS Windows/Samsung A15 (11/11/2026)

## Kết quả đã xác minh

Google ARTEMIS được cài đúng commit đã pin trong e2e_test/pyproject.toml: **351ca8422f7b5b54e80a9c1ce03a222e02415b6b**, checkout ở D:\Tools\ARTEMIS_351ca842 (riêng ngoài repository). Python 3.12, pytest và artemis-client được cài trong môi trường ảo e2e_test/.venv; daemon có môi trường ảo riêng tại thư mục ARTEMIS. Không có file secret trong Git.

Node.js 24.15.0 bản di động được tải từ nodejs.org và **đối chiếu SHA-256 chính thức**, giải nén lên D:\Tools\NodePortable mà không thay đổi Node.js hệ thống. Angular Showcase UI đã build thành công.

| Điều kiện | Kết quả | Giới hạn |
| --- | --- | --- |
| ARTEMIS pinned SHA | PASS | Không dùng commit mới khác version |
| ADB Samsung A15 | PASS ở lần kiểm tra | Chỉ xác minh thiết bị được cấp quyền, không chiếm quyền điều khiển khi có cuộc gọi |
| Python SDK/pytest | PASS | Không đồng nghĩa bài test đã chạy |
| ARTEMIS backend | PASS; SDK health thành công, API JSON trạng thái idle | Trạng thái idle không phải pass E2E |
| Angular UI | PASS; HTTP 200 với HTML, JS bundle và /api/status | UI hoạt động trên localhost:8000 |
| pytest collect | **18 ca nhóm, 10 ca Hoàng** | Chỉ collect; **0 E2E pass mới** |
| Preflight unit tests | **5/5 đạt** | Chỉ kiểm thử công cụ readiness |
| Google Gemini/Google model key | **BLOCKED** | Chưa có khóa chạy AI hợp lệ trên daemon |
| Tài khoản thử riêng | **BLOCKED** | Chưa khai báo tài khoản E2E chuyên dụng |

Các ca ARTEMIS đã chạy từ trước tiếp tục được thống kê riêng trong docs/hoang-artemis-run-audit-20261111.md. Không tính lượt chỉ có trạng thái completed là assertion pass.

## Bộ kiểm tra read-only mới

Chạy trên máy Hoàng sau khi mở PowerShell ở thư mục gốc D:\PRM393\LongvitaRC:

~~~powershell
D:\Tools\Python312\python.exe scripts\hoang_artemis_preflight.py
~~~

Công cụ chỉ đọc git SHA, danh sách ADB, API trạng thái ARTEMIS, sự hiện diện của thông tin cấu hình và dùng pytest --collect-only. **Không mở app, không đăng nhập, không gửi lệnh di chuyển hoặc bấm trên điện thoại, không ghi Firebase**. Không in hoặc lưu email, token, serial thiết bị trong kết quả. Exit 0 nghĩa là đủ điều kiện kỹ thuật để **bắt đầu** kiểm thử, không phải pass; exit 2 nghĩa là đang thiếu điều kiện.

Các tham số --repo, --artemis-root, --python, --adb, --test-env-file, --serial và --base-url hỗ trợ máy khác hoặc Git worktree.

## Điều kiện còn phải cấu hình tại máy (không gửi khóa qua chat)

1. Người vận hành nhập **GEMINI_API_KEY hoặc GOOGLE_API_KEY** hợp lệ vào D:\Tools\ARTEMIS_351ca842\.env trên chính máy, khởi động lại ARTEMIS để daemon nạp key. Không gửi key qua chat và không ghi key vào commit.
2. Người vận hành chọn **tài khoản Google riêng dành cho kiểm thử**, có dữ liệu và quyền đúng, rồi điền ARTEMIS_TEST_ACCOUNT vào D:\PRM393\LongvitaRC\e2e_test\.env. Không sử dụng tài khoản cá nhân đang có cuộc gọi hoặc dữ liệu ngoài phạm vi test.

Hai file .env này được Git bỏ qua. Các cờ an toàn trên daemon đã được cài: ARTEMIS_KEEP_DEVICE_AWAKE=false, ARTEMIS_HELPER_AUTO_INSTALL=false, ARTEMIS_HIERARCHY_BACKEND=uiautomator. Không tự cài Accessibility Helper lên điện thoại cá nhân.

## Quy trình sau khi hai điều kiện được đáp ứng

- Kiểm tra điện thoại không có cuộc gọi/lớp phủ tương tác; đăng nhập bằng tài khoản thử có sự cho phép; kiểm tra thiết bị có trạng thái ADB device.
- Chạy preflight đến READY; sau đó chạy đúng 10 case Hoàng (test_flows.py, test_detail.py, test_search.py) với Python e2e venv.
- Lặp **3 lần thành công cho mỗi case**; lưu assertion, exit code, trace/replay ID và timestamp, phân biệt success, failed, blocked, skipped. Trạng thái completed đơn lẻ không phải thành công.
- Kiểm tra tiếp Web Staff→Mobile 3 lần qua hai tài khoản thật, Firebase Console metadata/Analytics/Crashlytics, bằng chứng video và phê duyệt nguồn dinh dưỡng. Figma 10 màn đã được đối chiếu trong PR #45, nhưng chưa ký nghiệm thu pixel-perfect.

**Trạng thái hiện tại:** chỉ chuẩn bị môi trường và nhận diện 18 test thành công; **0 ARTEMIS E2E test mới được công nhận pass**. Không đánh dấu 100% cho Hoàng khi các điều kiện trên chưa có bằng chứng.

## Cập nhật kiểm tra cuối

Sau khi tạo file cấu hình không chứa bí mật, lần chạy preflight cuối cùng có **PASS** cho pinned SHA, client SDK/pytest, API JSON daemon, pytest collection; **BLOCKED** cho ADB (điện thoại đã ngắt phiên USB sau lúc được cấp quyền), key mô hình và test account. Kết quả chính xác đã được lưu tại evidence/hoang/artemis-readiness-20261111/preflight.json. Đây là trạng thái ở thời điểm chạy, không hạ các kết quả cài đặt đã hoàn tất.

Có thêm script scripts/hoang-start-artemis.ps1 để khởi động lại dịch vụ loopback an toàn; không tự cài Accessibility Helper, không đánh thức điện thoại liên tục và không mở trình duyệt.
