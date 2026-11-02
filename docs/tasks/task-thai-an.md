# Kế Hoạch & Bảng Theo Dõi Task — Thái An

> **Thành viên:** Thái An  
> **Vai trò:** **Team Leader & QA Lead** (Điều phối chung toàn nhóm, Nghiệm thu chất lượng, Analytics, Crashlytics, Remote Config, Google ARTEMIS, AI Code Review)  
> **Tổng task:** 29 tasks | **Đã hoàn thành:** 7/29 (24%)

---

## 1. Trách Nhiệm Trọng Tâm
1. **Firebase Instrumentation:**
   - Soạn và chốt [`docs/analytics-plan.md`](../analytics-plan.md) theo chuẩn Appendix A ($\ge 7$ events, câu hỏi sản phẩm, parameters không PII).
   - Triển khai `AnalyticsService`, chụp bằng chứng DebugView cho mọi sự kiện.
   - Triển khai `CrashlyticsService`: non-fatal error từ luồng thật + test crash, user ID + custom key, chụp dashboard.
   - Triển khai `RemoteConfigService`: $\ge 2$ tham số làm thay đổi UI (in-app defaults, fetch/activate không rebuild), chụp before/after.
2. **Google ARTEMIS E2E Testing:**
   - Cài đặt Google ARTEMIS (Python 3.12+, uv, ADB, model API key).
   - Soạn và chốt [`docs/test-plan.md`](../test-plan.md) theo chuẩn Appendix B ($\ge 10$ test cases, assertions định lượng, error path, native interaction).
   - Chạy toàn bộ test suite $\ge 3$ lần/test trên profile Flash, lập bảng tỷ lệ pass rate và phân tích xử lý test flaky.
   - Thực hiện phiên kiểm thử thăm dò (exploratory testing) 15–30 phút trên profile Pro và lập báo cáo lỗi.
3. **AI Code Review & Nghiệm thu:**
   - Mở PR cho phần việc của mình, chạy AI review, ghi $\ge 1-2$ findings vào [`docs/code-review.md`](../code-review.md) và sửa $\ge 1$ commit.
   - Soạn phần Báo cáo, Slides, quay clip Video mảng Analytics/Crashlytics/Remote Config/ARTEMIS và luyện vấn đáp 5 phút.

---

## 2. Bảng Danh Sách 29 Task Chi Tiết

| ID | Giai đoạn | Tên Task | Hỗ trợ | Phụ thuộc | Đầu ra / Bằng chứng | Tiêu chí (Điểm) | Ưu tiên | Tuần | Hạn | Trạng thái | Ghi chú |
|:---|:---|:---|:---:|:---:|:---|:---|:---:|:---:|:---:|:---:|:---|
| **S0-1** | 0. Chuẩn bị | Xác nhận với GV: làm nhóm 4; duyệt chủ đề & API; số commit/ngày tối thiểu; rubric | — | — | Tin nhắn/email xác nhận (lưu `evidence/`) | Mục 11 | Cao | 1 | | Chưa bắt đầu | Cần làm đầu tiên |
| **S0-3-TA** | 0. Chuẩn bị | Cài trên máy: Flutter stable, FlutterFire CLI, Android device/emulator, ADB, Python 3.12+, uv | — | — | `flutter doctor` không lỗi | — | Cao | 1 | | Chưa bắt đầu | Môi trường ARTEMIS |
| **S0-5** | 0. Chuẩn bị | Tạo tài khoản Google test riêng (không dùng cá nhân); lấy multimodal model API key (Gemini/Claude) lưu env | — | — | Tài khoản test + key (KHÔNG commit) | Test quality 0.5 | Cao | 1 | | Chưa bắt đầu | Tuyệt đối không commit key |
| **S1-3** | 1. Plan | Nháp `docs/analytics-plan.md`: $\ge 7$ events, parameters có kiểu, câu hỏi SP, map Lab 2 flow, không PII | Thắng | S1-1 | `docs/analytics-plan.md` (nháp) | Analytics 0.5 | Cao | 1 | | Đã hoàn thành | Mẫu Appendix A |
| **S1-4** | 1. Plan | Nháp `docs/test-plan.md`: critical flow $\to$ screen; $\ge 10$ cases; $\ge 1$ error path; $\ge 1$ native interaction; plan exploratory | Thắng | S1-1 | `docs/test-plan.md` (nháp) | Test plan 0.5 | Trung bình | 1 | | Đã hoàn thành | Mẫu Appendix B (11 cases) |
| **S3-8** | 3. Integrate | `firebase/remote-config-defaults.json` + chọn $\ge 2$ tham số làm đổi hiển thị (vd: max_recommendations, flag) | — | S1-3 | `firebase/remote-config-defaults.json` | RC 0.25 | Trung bình | 2 | | Đã hoàn thành | 4 params in-app defaults |
| **S5-1** | 5. Instrument | Chốt `analytics-plan.md` theo flow thực tế (**PHẢI xong trước khi viết mã tracking**) | Thắng, Hoàng | S1-3, S4-4 | `docs/analytics-plan.md` (chốt) | Analytics 0.5 | Cao | 2 | | Đã hoàn thành | Đã phê duyệt chính thức |
| **S5-2** | 5. Instrument | Triển khai `AnalyticsService` (interface + Firebase impl); set user ID sau sign-in; không tham số PII | — | S5-1, S3-3 | Code trong `lib/services/` | Analytics 0.5 | Cao | 2 | | Đã hoàn thành | lib/firebase/analytics_service.dart |
| **S5-5** | 5. Instrument | Chụp ảnh DebugView cho từng sự kiện ($\ge 7$) và lưu vào `evidence/analytics/` | Hoàng, Charlie | S5-3, S5-4 | `evidence/analytics/` | Analytics 0.5 | Cao | 3 | | Chưa bắt đầu | Bằng chứng chấm điểm |
| **S5-6** | 5. Instrument | `CrashService`/Crashlytics: set user ID + $\ge 1$ custom key; non-fatal từ lỗi thật; nút test crash | Hoàng | S4-1, S3-3 | Crashlytics hoạt động | Crashlytics 0.25 | Cao | 3 | | Đã hoàn thành | lib/firebase/crashlytics_service.dart |
| **S5-7** | 5. Instrument | Chụp dashboard Crashlytics: cả non-fatal và crash, có user ID và custom key | — | S5-6 | `evidence/crashlytics/` | Crashlytics 0.25 | Trung bình | 3 | | Chưa bắt đầu | Project ID phải khớp |
| **S5-8** | 5. Instrument | `RemoteConfigService`: in-app defaults, fetch/activate, $\ge 2$ tham số đổi UI; fetch lỗi dùng default | Hoàng | S3-8, S4-2 | Code `RemoteConfigService` | RC 0.25 | Cao | 3 | | Đã hoàn thành | lib/firebase/remote_config_service.dart |
| **S5-9** | 5. Instrument | Hiển thị giá trị Remote Config trên Profile demo area; chụp trước/sau khi đổi giá trị trên console | Charlie | S5-8, S4-13 | `evidence/remote-config/` | RC 0.25 | Trung bình | 3 | | Chưa bắt đầu | Bằng chứng trước/sau |
| **S6-2** | 6. Test | Cài ARTEMIS, ghim commit trong README; viết `e2e_test/conftest.py` (client, serial, profile Flash), `pyproject.toml` | — | S0-3-TA, S0-5 | `e2e_test/` chạy được | Test quality 0.5 | Cao | 3 | | Chưa bắt đầu | Pin commit ARTEMIS |
| **S6-3** | 6. Test | Chốt `docs/test-plan.md`: $\ge 10$ test cases (ID, precondition, instruction, expected, flow, loại) | Hoàng, Charlie | S6-1 | `docs/test-plan.md` (chốt) | Test plan 0.5 | Cao | 3 | | Chưa bắt đầu | Sau Feature Freeze |
| **S6-8** | 6. Test | Viết test hiển thị giá trị Remote Config và test kiểm tra analytics event đã log (Logcat/DebugView) | — | S6-2 | `test_remote_config.py`, `test_analytics.py` | Test quality 0.5 | Cao | 3 | | Chưa bắt đầu | Kiểm tra event qua Logcat |
| **S6-9** | 6. Test | Chạy toàn bộ suite $\ge 3$ lần mỗi test (Flash); lưu trace/screenshot/replay; lập bảng pass rate | Thắng, Hoàng, Charlie | S6-4..S6-8 | `evidence/artemis/` + bảng pass rate | Evidence 0.5 | Cao | 4 | | Chưa bắt đầu | Chứng minh $\ge 3$ runs |
| **S6-10** | 6. Test | Phân tích test flaky/fail: tìm nguyên nhân (app, timing, instruction mơ hồ), xử lý fix, chạy lại | Thắng, Hoàng, Charlie | S6-9 | Mục Flaky trong `test-plan.md` | Evidence 0.5 | Cao | 4 | | Chưa bắt đầu | Giải trình chi tiết |
| **S6-11** | 6. Test | Thực hiện phiên exploratory 15–30 phút (profile Pro, không kịch bản); lập danh sách lỗi tìm được | — | S6-1 | Báo cáo exploratory | Test plan 0.5 | Cao | 4 | | Chưa bắt đầu | Ghi nhận phát hiện |
| **S7-1-TA** | 7. Review | Mở PR cho phần của mình; chạy $\ge 1$ công cụ AI review (CodeRabbit/Copilot/SonarCloud); lưu output | — | S6-1 | PR + output trong `evidence/review/` | Review 0.5 | Cao | 4 | | Chưa bắt đầu | Chạy trên PR |
| **S7-2-TA** | 7. Review | Ghi $\ge 1-2$ findings (file:dòng, loại, tóm tắt), quyết định Accept/Modify/Reject có lý do; kê khai AI tools | — | S7-1-TA | Dòng ghi trong `code-review.md` | Findings 0.25 | Cao | 4 | | Chưa bắt đầu | Lý do kỹ thuật cụ thể |
| **S7-3-TA** | 7. Review | Sửa $\ge 1$ finding đã chấp nhận; commit riêng ghi ID finding; dẫn link commit vào bảng | — | S7-2-TA | Fix commit liên kết | Fixes 0.25 | Cao | 4 | | Chưa bắt đầu | Ví dụ: `fix(analytics): CR-TA-01...` |
| **S7-5** | 7. Review | Chạy lại các test ARTEMIS liên quan sau khi fix commit nếu fix làm thay đổi app | — | S7-3-TA | Bảng kết quả cập nhật | Evidence 0.5 | Trung bình | 4 | | Chưa bắt đầu | Chống hồi quy |
| **S8-4** | 8. Report | Viết mục Báo cáo: Analytics (plan + DebugView), Crashlytics, Remote Config, ARTEMIS (kết quả, exploratory) | — | S6-10, S6-11 | Bản nháp báo cáo gửi Thắng | Mọi tiêu chí | Cao | 4 | | Chưa bắt đầu | Có kèm hình ảnh |
| **S8-8** | 8. Report | Soạn Slide (3–4 trang): Analytics DebugView, Crashlytics + Remote Config, ARTEMIS plan + pass rate | — | S8-4 | Slide gửi Thắng | Slides 1.0 | Cao | 4 | | Chưa bắt đầu | 1 thông điệp/slide |
| **S8-13** | 8. Report | Quay video: đổi Remote Config không rebuild, demo Crashlytics, chạy 1 test ARTEMIS trên thiết bị | — | S6-1 | Đoạn video clip gửi Thắng | Video 1.0 | Cao | 4 | | Chưa bắt đầu | Thuyết minh rõ ràng |
| **S8-17-TA** | 8. Report | Cập nhật worklog cá nhân `docs/worklog-thai-an.md` để đối chiếu commit Git | — | S8-16 | `docs/worklog-thai-an.md` | Mục 11 | Thấp | 4 | | Chưa bắt đầu | Tùy chọn kiểm tra |
| **S9-5-TA** | 9. Nộp bài | Luyện vấn đáp 5 phút: chạy 1 test ARTEMIS, đổi 1 giá trị Remote Config live, giải thích 1 quyết định review | — | S8-16 | Sẵn sàng vấn đáp | Mục 11 | Cao | 4 | | Chưa bắt đầu | GV gọi ngẫu nhiên |
