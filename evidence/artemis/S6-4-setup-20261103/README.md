# S6-4, S6-7 — Cài ARTEMIS client và chạy thử khi chưa có daemon, 03/11/2026

**Đây không phải lần chạy ARTEMIS.** Chưa có key mô hình (S0-5), nên chưa có daemon và chưa có raw run. Thư mục này chỉ chứng minh bộ test cài được, đúng API của SDK đã ghim, và không báo pass khi không quan sát được app.

| File | Nội dung |
|---|---|
| `01-install.txt` | `artemis-client 0.1.0` cài từ `google/artemis@351ca8422f7b5b54e80a9c1ce03a222e02415b6b` (đúng commit ghim trong `e2e_test/pyproject.toml`), cùng pytest và pytest-asyncio. Python 3.12.10, venv ngoài repo |
| `02-collect.txt` | `pytest --collect-only`: đủ 7 test (TC-01, TC-01b, TC-11, TC-08, TC-08b, TC-09, TC-10) |
| `03-run-without-daemon-sanitized.txt` | Bản tóm tắt đã loại username/đường dẫn máy: chạy cả 7 test khi không có daemon, cả 7 **lỗi ngay ở fixture** với `NetworkError` tại `http://127.0.0.1:8000/api/status`. Không test nào pass |

## Đã kiểm

- Mọi lời gọi SDK trong `conftest.py` và các file test có trong client đã ghim: `ArtemisClient(base_url, device_serial=, default_profile=)`, `health()`, `run(goal, expected_output=)`, và các trường `task_id`, `status`, `device_serial`, `turns`, `output`, `error`, `succeeded` của `TaskResult`. Kiểm bằng `inspect` trên package đã cài.
- `e2e_test/pyproject.toml` ghi rõ `asyncio_default_fixture_loop_scope = "function"`, vì pytest-asyncio cảnh báo giá trị mặc định sẽ đổi ở bản sau.

## Chưa làm

- **Daemon:** repo ARTEMIS khởi động bằng `start.bat` → `scripts/start.ps1`. Script này tự cài công cụ và cài Accessibility Helper APK lên máy, và cần ít nhất một key LLM (`.env.example`: Gemini, Google, OpenAI, Anthropic, OpenRouter hoặc xAI). Sẽ cài khi nhóm gửi key S0-5 và chốt dùng nhà cung cấp nào.
- Chạy thật mỗi test ít nhất 3 lần, lưu `evidence/artemis/raw/runs.jsonl`.
- TC-08 cần Storage (DEC-01) hoặc chạy trên Storage Emulator có ghi rõ.
