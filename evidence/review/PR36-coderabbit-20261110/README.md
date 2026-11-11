# PR #36 — CodeRabbit review, 10/11/2026

Reviewed head: `fe86a64`. PR: https://github.com/ruxenb/LongvitaRC/pull/36

## Round 1 Findings and Decisions

Review sinh bởi `coderabbitai[bot]` (5 actionable inline findings: 2 Major, 3 Minor).

| ID | Vị trí (File:Line) | Mức độ | Loại lỗi | Tóm tắt phát hiện của AI | Quyết định | Lý do kỹ thuật & Cách khắc phục |
|:---:|:---|:---:|:---|:---|:---:|:---|
| **PR36-CR-01** | `firebase/remote-config-defaults.json:8` | Major | Functional Correctness | Model `gemini-1.5-flash` đã cũ/ngừng hỗ trợ, có thể gây lỗi 404 trên các bản build production mới | **Accepted** | Cập nhật cấu hình model sang phiên bản `gemini-2.0-flash` đồng bộ trên Remote Config defaults, `GeminiAiService._defaultModel` và tài liệu `docs/ai-feature.md`. |
| **PR36-CR-02** | `mobile/lib/services/gemini_ai_service.dart:76` | Major | Security & Privacy (CWE-798) | Truyền API Key qua query parameter `?key=` trên URL dễ bị lộ trong log mạng/proxy | **Accepted** | Chuyển việc truyền Gemini API key từ query parameter sang HTTP request header `x-goog-api-key: $key`. |
| **PR36-CR-03** | `mobile/lib/services/gemini_ai_service.dart:129` | Minor | Functional Correctness | Khi HTTP 200 nhưng body rỗng hoặc JSON hỏng, log ghi `http_200` gây hiểu nhầm thành lỗi mạng HTTP | **Accepted** | Tách riêng mã lỗi analytics: ghi nhận `parse_failed` khi payload không hợp lệ, phân biệt rõ với lỗi mã HTTP khác 2xx. |
| **PR36-CR-04** | `mobile/lib/services/gemini_ai_service.dart:179` | Minor | Stability & Availability | Lời gọi async `logEvent` trong hàm `_logAiError` không được await hoặc bắt exception bất đồng bộ | **Accepted** | Bổ sung `.catchError((_) {})` và bọc `unawaited(...)` để đảm bảo lỗi logging không bao giờ phát sinh unhandled async error. |
| **PR36-CR-05** | `packages/core/lib/models/ai_meal_recommendation.dart:143` | Minor | Functional Correctness | `fromJson` tự điền giá trị ngẫu nhiên/mặc định khi thiếu trường dinh dưỡng, khiến dữ liệu giả mạo hiển thị như AI output | **Accepted** | Thêm bước kiểm tra nghiêm ngặt trong `_parseStructuredJson`: nếu thiếu `mealName`, `calories <= 0`, hoặc `ingredients` rỗng thì trả về `null` để kích hoạt Fallback dinh dưỡng chuẩn TS. Longo. |

## Bằng chứng kiểm tra sau khi sửa
- Bộ test `mobile/test/ai/gemini_ai_service_test.dart`: Đạt 100% với các test case kiểm tra header `x-goog-api-key`, `parse_failed`, và validation món ăn thiếu trường.
- Quy chuẩn Monorepo: `python scripts/check-monorepo.py` tiếp tục PASS.
