# ARTEMIS — chạy thật S6-4, S6-7, 03/11/2026

Bộ test `e2e_test/` chạy bằng `artemis-client` ghim commit `351ca84` với daemon ARTEMIS thật cùng commit, trên AVD `LocalMate_API_35` (Android 15, 320×640), app debug của nhánh `feature/charlie-artemis-01`. Đây là lần chạy của Charlie, chưa phải lần chạy chính thức S6-9 của Thái An.

## Cấu hình daemon

| Mục | Giá trị | Lý do |
|---|---|---|
| Key | Gemini API, gói miễn phí, của Charlie; nằm trong `.env` của daemon, không có trong repo | Nhóm chưa có key S0-5 chung |
| Model | `gemini-3.5-flash-lite` cho mọi agent (sửa `config/artemis.jsonc` của bản ARTEMIS trên máy) | Gói miễn phí giới hạn `gemini-3.8-flash` ở 5 request/phút và model này đang báo 503; `gemini-3.5-flash-lite` trả lời ổn định |
| Profile | `flash` | Mặc định của `conftest.py` |
| Đọc giao diện | UIAutomator2 (`ARTEMIS_HIERARCHY_BACKEND=uiautomator`) | Emulator không cho bật Accessibility Helper qua adb |
| Storage | Storage Emulator trên máy (`npm run emulator:storage`), app build với `--dart-define=STORAGE_EMULATOR_HOST=10.0.2.2` | Project chưa có Storage (DEC-01) |
| Push | Chiến dịch Firebase Console thật, gửi tay trước TC-10 (operator-assisted) | Chưa có cách gửi tự động |

## Kết quả lượt chạy đủ 7 test

Xem `full-pass-batch1.txt`, `full-pass-batch2.txt` (output của pytest) và `raw/runs.jsonl` (mỗi dòng một lần chạy).

**7/7 pass** trong một lượt chạy bằng code cuối (đợt 1: 5 test trong 5 phút 50 giây; đợt 2: push gửi tay rồi TC-10, TC-11 trong 2 phút 9 giây). Lượt này là các record 17–23 của `raw/runs.jsonl` (task IDs trong bảng); các lần chạy local sau đó được giữ thêm, nên không xác định batch bằng “7 dòng cuối”.

| Test | Task ARTEMIS | Thời gian | Kết quả pytest |
|---|---|---:|---|
| TC-01b hủy chọn tài khoản | `46b5c30b` | 59 s | Pass |
| TC-01 đăng nhập Google | `d1996f30` | 69 s | Pass |
| TC-09 cập nhật Remote Config | `327d1e4d` | 84 s | Pass |
| TC-08 xuất và tải PDF | `ec91a349` | 69 s | Pass |
| TC-08b mở PDF đã lưu | `3eb438d8` | 70 s | Pass |
| TC-10 bấm push từ khay | `d765b415` | 63 s | Pass |
| TC-11 đăng xuất, Back | `6f290fcd` | 66 s | Pass |

TC-10 dùng chiến dịch Console "ARTEMIS TC10 lan 2"; tin lên khay sau 52 giây, app ở nền. TC-08 chạy trên Storage Emulator.

## Thay đổi script khi chạy thật

| Thay đổi | Lý do |
|---|---|
| `enable_outputter=True`, và khi task không có output thì lấy tóm tắt từng bước của agent (`/api/sessions/{id}/replay_steps`), ghi `output_source` vào `runs.jsonl` | Ở commit ghim, nhánh Flash của ARTEMIS bỏ qua Outputter (`third_party/mobile_use/sdk/agent.py` 575–598), nên SDK luôn trả `output=None`. Tóm tắt từng bước là quan sát của agent trên ảnh màn hình |
| Tắt app (`am force-stop`) trước mỗi test, trừ test đánh dấu `keep_app` (TC-10) | Một lượt TC-08 pass nhờ đọc kết quả còn lại từ lượt trước; mỗi test phải tự bắt đầu |
| TC-01, TC-01b: chờ 3 giây rồi đọc chữ | Agent chụp màn hình 0,4 giây sau khi bấm, trước khi app nhận kết quả hủy hoặc tải xong hồ sơ |
| TC-08: nói rõ vuốt lên để thấy URL; chỉ bắt buộc `reports` trong URL | Agent vuốt sai chiều; tóm tắt của LLM có thể cắt URL dài. File được kiểm riêng trên emulator |
| TC-09: bắt buộc thông báo "Không có giá trị mới" | Assertion cũ chỉ cần một chữ số nên luôn qua |
| TC-11: chỉ kiểm bước sau khi bấm Back | Các bước trước khi đăng xuất có nhắc Home, làm assertion cũ fail dù app đúng |

## Lỗi app tìm được (S6-14)

| Test | Lỗi | Sửa | Kiểm lại |
|---|---|---|---|
| TC-09 | Mỗi lần bấm "Cập nhật Remote Config" đều báo "Đã áp dụng giá trị mới." dù không có gì đổi. SDK coi mọi lần fetch mới là đã kích hoạt | `fd0951c`: ViewModel so giá trị trước và sau | Widget test mới; TC-09 chạy lại pass |

## Kiểm riêng ngoài agent

- TC-08: file trên Storage Emulator tải về được bằng đúng URL đọc từ màn hình (lấy bằng `uiautomator dump`), 18.955 byte, bắt đầu bằng `%PDF-1.5`. URL do agent đọc nhầm một ký tự trong UID (`I` thành `l`), nên không dùng URL của agent để kiểm file.

## Giới hạn

- Mới chạy một lượt đủ 7 test bằng code cuối; chưa đủ 3 lượt mỗi test theo tiêu chí S6-4.
- Tóm tắt từng bước do LLM viết, có thể sai chi tiết nhỏ (đã thấy sai tên bucket và một ký tự UID). Assertion chỉ dựa vào chữ hiển thị ngắn, ổn định.
- TC-08 chạy trên Storage Emulator, không phải project thật.
- TC-10 cần người gửi push từ Console trước khi chạy.
- `runs.jsonl` có các lượt chạy khi đang sửa script (đầu danh sách), giữ nguyên để thấy quá trình; lượt đủ tương ứng record 17–23, khớp task IDs trong bảng và hai file log.
- Dữ liệu chạy có email và UID thật của Charlie.

## Sau review PR #7 — giới hạn bằng chứng

- `runs.jsonl` có thêm 8 task records do Charlie/Claude chạy trước bàn giao (tổng 31). `status=completed` là trạng thái agent, không tự chứng minh assertions pytest pass; chưa có log pytest riêng trong gói này cho cả 8 task. Giữ nguyên raw history.
- Các assertions được siết theo CR-08..11. Follow-up d41abe0 luôn lấy replay từng bước; final output không được gộp thành một bước để làm assertions, chỉ lưu trong `agent_output`. Record mới có `steps` và `observation_error`. Replay rỗng/lỗi thì test fail, không fallback thành SUCCESS.
- Codex chưa chạy lại ARTEMIS thật: ADB không thấy thiết bị và daemon không chạy khi tiếp quản. TC-10/11 sau fix và TC-09b cần Console edit vẫn chưa có live evidence mới; ba lượt mỗi ca và exploratory còn thuộc S6.
- 23/23 kiểm assertions tại `test_support/e2e_review/` là regression độc lập dùng quan sát fixture, không cộng vào 8 case ARTEMIS hoặc pass rate. [Verification](../review/PR7-coderabbit-20261103/README.md).
