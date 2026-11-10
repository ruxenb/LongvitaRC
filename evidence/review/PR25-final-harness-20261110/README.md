# Bàn giao cho Thắng — đóng hai finding harness của PR #25

Ngày 10/11/2026. Charlie xác nhận Thắng kết thúc ca và giao Codex xử lý phần
còn lại, kiểm và merge khi đủ điều kiện. Baseline: `968fb71`, main `3297ed6`.
Gói này chỉ sửa Python harness/regression; không di chuyển cấu trúc CM-00.

## Những gì đã sửa

| Finding | Quyết định | Cách sửa và bằng chứng |
|---|---|---|
| Major outside-diff, `conftest.py:249`, review `5837067175` | Accepted | Home mới không có email. Setup xác nhận Home, mở Hồ sơ, chờ nút Đăng xuất và đối chiếu **đúng cả dòng email**. Cho phép dấu ngắt zero-width trước @ mà UI Profile đang dùng. Không bỏ kiểm đúng tài khoản, không lấy email ở Home để suy ra tài khoản. Metadata ghi rõ identity được kiểm tại Profile. |
| Minor inline `4521350940`, TC-11 | Modified | Bỏ marker chung `Trang chủ` và `Hồ sơ`; dùng dấu hiệu riêng của app, giữ Dashboard cũ và các nhãn nghiệp vụ. “Trang chủ Android (launcher)” được chấp nhận, nhưng “Trang chủ Longvita ... not the launcher” vẫn bị chặn. Các assertion yêu cầu Back, Sign-in sau logout và kết quả launcher/Sign-in vẫn giữ. |
| Trivial: chạy coroutine bằng `send(None)` | Accepted | Dùng `asyncio.run()` trong regression đồng bộ, tránh phụ thuộc coroutine không có điểm await. |
| Trivial: guard `instrumentation.initialize()` nếu contract đổi trong tương lai | Deferred | RemoteConfig service hiện tự bắt lỗi; gói này không mở rộng sang bootstrap Dart. Không coi góp ý về giả định tương lai là lỗi runtime đã được tái hiện. |

Nguồn: [CodeRabbit review trên baseline](https://github.com/ruxenb/LongvitaRC/pull/25#pullrequestreview-5837067175).

## Kiểm chứng

| Kiểm tra | Kết quả |
|---|---|
| Bộ Python regression hiện có, trước thêm ca mới | 60/60 |
| Bộ mở rộng trên code harness cũ | **8 fail / 59 pass** |
| Bộ mở rộng sau sửa | **67/67 pass** |
| Thu thập E2E | 18 ca, không chạy agent/thiết bị |
| Python compileall | Đạt |
| Git diff whitespace | Sạch |

Regression mới dùng Home không có email và Profile có identity đúng/sai;
kiểm Profile không mở được, thiếu email, email chỉ giống một phần, dấu ngắt
layout và email giả xuất hiện ở Home. Các ca replay phân biệt launcher Android
với Home Longvita. FakeDevice chỉ ghi lệnh adb vào bộ nhớ, không điều khiển máy.
Hai regression subprocess vẫn chứng minh thiếu tài khoản dừng trước thiết bị
và daemon; cấu hình hợp lệ mới được đi tiếp.

Môi trường kiểm Python được tạo riêng trong QA local, không sửa môi trường
Python toàn máy. Package registry khớp phiên bản và hash trong `e2e_test/uv.lock`;
SDK Google ARTEMIS client đúng commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`.
Không thay dependency/lockfile của dự án. Test dùng tài khoản example.com giả.

## Phạm vi và giới hạn

- Các file `lib/`, `test/` Dart, pubspec/lock và `firebase/` không đổi so với
  `968fb71`. Lượt kiểm độc lập trên baseline đó đã đạt **505/505 Flutter**,
  analyzer lib/test sạch, Web release và Wasm dry run build được. Không chạy lặp
  Flutter/build cho thay đổi Python-only và không gọi các số này là test mới.
- Không chạy ARTEMIS thật, AVD hay browser/native E2E trong gói này; 67 là
  regression offline, **không phải 67 lượt agent/device**.
- Không deploy Hosting/rules, publish Remote Config, đổi role/billing hoặc ghi
  Firestore thật. Các bằng chứng live còn thiếu trong checklist Final giữ nguyên.
- Gói không nghiệm thu CM-06/07 hoặc TV-00…04 thay owner. Sau khi tích hợp,
  CM-00/02 mới được tiếp tục theo kế hoạch.
- Log chia sẻ đã bỏ đường dẫn máy và chuẩn hóa khoảng trắng cuối dòng;
  bản thô và môi trường Python chỉ ở QA local. Tài liệu điều phối không push.

## Sau khi Thắng quay lại

Pull main sau khi PR được merge; xem commit/merge receipt ở PR #25. Tiếp tục
bằng chứng live Hosting/role/Remote Config/Analytics theo checklist đã có.
Không lấy regression offline làm bằng chứng đã hoàn thành những bước đó.
