# Kiểm bản tích hợp Final — 11/11/2026

Baseline main `17cbbd1` gồm PR36 (AI), PR29 (Mobile/realtime/S04), PR37 (audit/docs) và PR38 (CM08). Lượt kiểm trên cùng workspace phát hiện các điểm không thấy khi chỉ xem kết quả từng nhánh.

## Phát hiện và sửa

| Mã | Trước sửa | Bản sửa |
| --- | --- | --- |
| INT-01 | Core model AI có import `dart:convert` không dùng, analyzer dừng | Gỡ đúng import thừa |
| INT-02 | `GeminiAiService` gọi `getBool/getString` chưa có ở wrapper Remote Config và gọi `AnalyticsService.logEvent` bằng named arguments trái API Core | Bổ sung hai getter wrapper, đồng bộ ba AI defaults với file JSON, đổi caller Analytics sang positional contract hiện có |
| INT-03 | Callback AI dùng BuildContext qua async gap và ba chỗ `withOpacity` deprecated | Kiểm đúng `context.mounted`, dùng `withValues(alpha: ...)`; không đổi action/route |
| INT-04 | Hai HTTP fixture AI không khai báo JSON/UTF-8, nội dung tiếng Việt rơi vào fallback; test Apply chạm nút ngoài viewport khi bàn phím mở | Khai báo đúng response Content-Type; test đóng bàn phím/cuộn tới nút trước khi tap. Giữ nguyên expected món ăn và accepted/edited assertions |
| INT-05 | Hai regression late-submit treo: fixture có một ngày nên guard mới đủ7ngày trả về trước SDK gate | Fixture riêng tạo đủ7ngày để thật sự có submit đang chờ; giữ assertion kết quả cũ bị bỏ qua khi A→B hoặc A→logout→A, thêm kiểm loading |

Ba regression mới kiểm flag Remote Config chặn trước HTTP, model từ RC + hai event request/accepted qua API Core, và event error + fallback khi HTTP500. Test dùng HTTP giả/recording ports, **không** gọi Gemini thật hoặc chứng minh App Check/AI Logic.

## Kiểm chứng

- Workspace boundary và lockfile restore đạt. Analyzer Core/Mobile/Web sạch sau sửa.
- Core **20/20**, Mobile **483/483**, Web **69/69**: tổng **572/572**. Ba test mới đã nằm trong Mobile483, không cộng thêm lần nữa.
- `verification.json` ghi source digests, kết quả build và phạm vi; `checks.txt` chứa các dòng tổng kết đã bỏ đường dẫn máy.
- Snapshot build không có Gemini key được cấp qua dart-define; build thành công không chứng minh AI live. Không tự deploy Hosting/rules, ghi data hoặc bật paid services.
- Các lỗi compile/lint được sửa theo API đang có; không nâng SDK/package hoặc đổi schema/role/rules. Prompt AI từ RC, Firebase AI Logic, App Check, cross-role live và tài liệu/slide/video cuối vẫn phải đối chiếu với handout riêng.

## Review báo cáo

Phần [PR38](../PR38-coderabbit-20261111/README.md) sửa so sánh byte với normalized, nhãn số Dashboard và mô tả self-approval theo đúng source. Không nhận runtime thay đổi từ các chỉnh sửa Markdown đó.
