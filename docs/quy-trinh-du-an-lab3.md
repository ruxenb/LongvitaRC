# Quy Trình Toàn Bộ Dự Án & Người Phụ Trách — PRM393 Lab 3

> **Dự án:** Longvita — Cloud-Enabled Mobile App (Flutter + Firebase + Google ARTEMIS + AI Code Review)  
> **Nhóm:** Thái An (Team Leader & QA Lead), Thắng (Technical Architect), Charlie (Firebase & Design System), Hoàng (Core Features)  
> **Nguồn:** `README.md`, `milestones-and-dependencies.md`, `submission-checklist.md`, 4 file `task-*.md`

---

## Tổng quan theo tuần

| Tuần | Giai đoạn chính | Mốc kết thúc |
|:---:|:---|:---:|
| 1 | Chuẩn bị, Plan, Architect | **M1** Nền móng (Thắng) |
| 2 | Integrate (Auth, Storage rules), Flow 1, widget dùng chung | **M2** Đăng nhập chạy (Charlie), **M3** Flow đầu tiên (Hoàng) |
| 3 | Features, Instrument, Feature freeze | **M4** Tính năng đầy đủ (Thắng), **M5** Feature freeze (Thắng) |
| 4 | Test (ARTEMIS), AI Review, Report/Slide/Video, Nộp bài | **M6** (Thái An), **M7**, **M8**, **M9** (Thắng) |

---

## Giai đoạn 0 — Chuẩn bị (Tuần 1)

| Việc | Task | Phụ trách |
|:---|:---:|:---|
| Xác nhận với giảng viên: làm nhóm 4, chủ đề/API, số commit/ngày, rubric | S0-1 | Thái An |
| Tài khoản Google test riêng + API key model multimodal (không commit) | S0-5 | Thái An |
| Tạo Firebase project (Spark), mời cả nhóm, ghi project ID | S0-4 | Charlie |
| Gom đầu vào Lab 2: Figma, persona, user-flow, DESIGN, screen-spec, flutter-handoff | S0-6 | Thắng (hỗ trợ Hoàng) |
| Cài môi trường máy: Flutter, FlutterFire CLI, thiết bị/emulator, ADB (Thái An thêm Python 3.12+, uv) | S0-3 | Cả 4 người, mỗi người máy mình |
| Chưa rõ nội dung | S0-2 | Chưa rõ |

## Giai đoạn 1 — Plan (Tuần 1)

| Việc | Task | Phụ trách |
|:---|:---:|:---|
| Viết `docs/design-traceability.md` (≥ 8 màn hình, 3 flow) | S1-1 | Thắng (hỗ trợ Hoàng) |
| Chốt nguồn dữ liệu Firestore (`users`, `recipes`, `meal_plans`), cấm mock data | S1-2 | Hoàng (hỗ trợ Thắng) |
| Nháp `docs/analytics-plan.md` (≥ 7 events, không PII) | S1-3 | Thái An (hỗ trợ Thắng) |
| Nháp `docs/test-plan.md` (≥ 10 cases) | S1-4 | Thái An (hỗ trợ Thắng) |
| Thiết kế bổ sung màn Sign-in & Profile trên Figma | S1-5 | Hoàng (hỗ trợ Charlie) |

## Giai đoạn 2 — Architect (Tuần 1–2)

| Việc | Task | Phụ trách |
|:---|:---:|:---|
| Họp chốt interface 7 service và tên ViewModel **(đường găng)** | S2-1 | Thắng chủ trì, cả nhóm tham gia |
| Dựng khung `lib/` Core-Package-Ready + DI Provider | S2-2 | Thắng |
| `lib/theme/` từ design tokens (64 Variables, action `#476429`) | S2-3 | Charlie (hỗ trợ Thắng) |
| 9 widget dùng chung (Button, TextField, Card, Navigation, AppBar, Dialog, Loading, Empty, Error) | S2-4 | Charlie (hỗ trợ Hoàng) |
| Viết `docs/architecture.md` | S2-5 | Thắng |

> **M1 — Nền móng:** Thắng

## Giai đoạn 3 — Integrate (Tuần 2)

| Việc | Task | Phụ trách |
|:---|:---:|:---|
| `flutterfire configure`, `google-services.json`, ghim phiên bản | S3-1 | Charlie |
| Đăng ký SHA-1 của cả 4 máy | S3-2 | Charlie (hỗ trợ cả nhóm) |
| `AuthService` + Google Sign-In, lưu `users/{uid}` với `role: 'user'` | S3-3 | Charlie |
| Màn hình Sign-in | S3-4 | Charlie (hỗ trợ Thắng) |
| Sign-out, xóa dữ liệu cục bộ | S3-5 | Charlie |
| Router theo auth state (`AuthGate`), nút Back đúng | S3-6 | Thắng (hỗ trợ Charlie) |
| `firebase/storage.rules` (`reports/{uid}/...`), deploy | S3-7 | Charlie |
| `remote-config-defaults.json`, chọn ≥ 2 tham số | S3-8 | Thái An |
| Bằng chứng Auth (`evidence/auth/`) | S3-9 | Charlie |

> **M2 — Đăng nhập chạy:** Charlie

## Giai đoạn 4 — Features (Tuần 2–3)

| Việc | Task | Phụ trách |
|:---|:---:|:---|
| Data Models + `DataService` Firestore | S4-1 | Hoàng |
| ViewModels + explicit state (loading/empty/error/data) | S4-2 | Hoàng |
| API dữ liệu thực đơn cho `ReportService` | S4-3 | Hoàng (hỗ trợ Charlie) |
| **Flow 1** (S01, S02, S03, S04, S10) | S4-4 | Hoàng (hỗ trợ Thắng) |
| **Flow 2** (S07, S08) | S4-5 | Hoàng (hỗ trợ Thắng) |
| **Flow 3** (S05, S06, S09) | S4-6 | Hoàng (hỗ trợ Thắng) |
| Loading/Empty/Error + Retry ở mọi màn hình | S4-7 | Hoàng |
| Semantics cho màn hình của Hoàng | S4-8 | Hoàng |
| Fake service + unit test ViewModel (tùy chọn) | S4-9 | Hoàng |
| `ReportService` sinh PDF | S4-10 | Charlie (hỗ trợ Hoàng) |
| `StorageService` upload kèm progress | S4-11 | Charlie |
| FCM (foreground / background / terminated) | S4-12 | Charlie |
| Màn Profile + Firebase Demo Area | S4-13 | Charlie (hỗ trợ Thắng) |
| Semantics cho màn hình của Charlie | S4-14 | Charlie |
| Bằng chứng Storage và FCM | S4-15 | Charlie |
| Rà soát Accessibility & Responsive (360 / 412 dp) | S4-16 | Hoàng (hỗ trợ Charlie) |
| Đối chiếu Figma ↔ App, cập nhật `design-traceability.md` | S4-17 | Hoàng (hỗ trợ Charlie) |

> **M3 — Flow đầu tiên (Flow 1 + `analytics-plan.md` chốt):** Hoàng

## Giai đoạn 5 — Instrument (Tuần 2–3)

| Việc | Task | Phụ trách |
|:---|:---:|:---|
| Chốt `analytics-plan.md` **(phải xong trước khi viết mã tracking)** | S5-1 | Thái An (hỗ trợ Thắng, Hoàng) |
| `AnalyticsService`, set user ID sau sign-in | S5-2 | Thái An |
| Log event trong ViewModel của các flow | S5-3 | Hoàng (hỗ trợ Thái An) |
| Log event `login`, `logout`, `export_report` | S5-4 | Charlie (hỗ trợ Thái An) |
| Ảnh DebugView cho ≥ 7 event | S5-5 | Thái An (hỗ trợ Hoàng, Charlie) |
| Crashlytics: user ID, custom key, non-fatal, nút test crash | S5-6 | Thái An (hỗ trợ Hoàng) |
| Ảnh dashboard Crashlytics | S5-7 | Thái An |
| `RemoteConfigService` (≥ 2 tham số đổi UI, fetch lỗi dùng default) | S5-8 | Thái An (hỗ trợ Hoàng) |
| Hiển thị Remote Config trên Profile, ảnh trước/sau | S5-9 | Thái An (hỗ trợ Charlie) |
| Thử thủ công failure case của 6 dịch vụ (mất mạng, từ chối quyền, hủy) | S5-10 | Thắng (hỗ trợ cả nhóm) |

> **M4 — Tính năng đầy đủ:** Thắng

## Giai đoạn 6 — Test với Google ARTEMIS (Tuần 3–4)

| Việc | Task | Phụ trách |
|:---|:---:|:---|
| **Feature freeze, tag `v1.0-rc`** | S6-1 | Thắng |
| Cài ARTEMIS, ghim commit, `conftest.py`, `pyproject.toml` | S6-2 | Thái An |
| Chốt `docs/test-plan.md` (≥ 10 test cases) | S6-3 | Thái An (hỗ trợ Hoàng, Charlie) |
| Script `test_auth.py` | S6-4 | Charlie (hỗ trợ Thái An) |
| Script `test_flows.py`, `test_search.py` | S6-5 | Hoàng (hỗ trợ Thái An) |
| Script `test_detail.py` | S6-6 | Hoàng (hỗ trợ Thái An) |
| Script `test_export.py` + test push notification | S6-7 | Charlie (hỗ trợ Thái An) |
| Test Remote Config + test analytics event | S6-8 | Thái An |
| Chạy suite ≥ 3 lần mỗi test, lập bảng pass rate | S6-9 | Thái An (hỗ trợ cả nhóm) |
| Phân tích test flaky/fail, fix, chạy lại | S6-10 | Thái An (hỗ trợ cả nhóm) |
| Phiên exploratory 15–30 phút (profile Pro) | S6-11 | Thái An |
| Sửa lỗi theo log ARTEMIS, phần của mình | S6-12 / S6-13 / S6-14 | Thắng / Hoàng / Charlie |

> **M5 — Feature freeze:** Thắng
> **M6 — ARTEMIS hoàn tất:** Thái An

## Giai đoạn 7 — AI Code Review (Tuần 4)

| Việc | Task | Phụ trách |
|:---|:---:|:---|
| Mở PR phần của mình, chạy ≥ 1 công cụ AI review, lưu output | S7-1 | Mỗi người một task: Thắng (VLQ), Hoàng (HD), Charlie (CM), Thái An (TA) |
| Ghi findings, quyết định Accept/Modify/Reject kèm lý do, kê khai AI tools | S7-2 | Như trên |
| Sửa ≥ 1 finding, commit riêng ghi ID finding | S7-3 | Như trên |
| Tổng hợp `docs/code-review.md` (≥ 5 findings, ≥ 2 loại, ≥ 3 fix commit) | S7-4 | Thắng (hỗ trợ cả nhóm) |
| Chạy lại các test ARTEMIS liên quan sau fix | S7-5 | Thái An |

> **M7 — Code review xong:** Thắng

## Giai đoạn 8 — Báo cáo, Slide, Video (Tuần 4)

| Mảng nội dung | Báo cáo | Slide | Video | Phụ trách |
|:---|:---:|:---:|:---:|:---|
| Tổng quan, Lab 2 recap, traceability, MVVM, design system, code review, lessons | S8-1 | S8-9 | S8-14 | Thắng |
| Flows, dữ liệu thật, loading/empty/error, Figma vs App | S8-2 | S8-6 | S8-11 | Hoàng |
| Firebase Auth, Storage, FCM | S8-3 | S8-7 | S8-12 | Charlie |
| Analytics, Crashlytics, Remote Config, ARTEMIS | S8-4 | S8-8 | S8-13 | Thái An |

| Việc tổng hợp | Task | Phụ trách |
|:---|:---:|:---|
| Ghép `report/Lab03_<StudentID>.pdf` (8–12 trang) | S8-5 | Thắng |
| Ghép `slides/Lab03_<StudentID>_slides.pdf` (12–15 slide) | S8-10 | Thắng |
| Biên tập và upload video demo 5–10 phút, đặt link public | S8-15 | Thắng |
| Hoàn thiện `README.md` (pinned versions, AI tools, link video, deliverable map) | S8-16 | Thắng |
| Worklog cá nhân `docs/worklog-<tên>.md` | S8-17 | Cả 4 người, mỗi người của mình |

> **M8 — Báo cáo, Slide, Video:** Thắng

## Giai đoạn 9 — Kiểm tra & Nộp bài (Tuần 4)

| Việc | Task | Phụ trách |
|:---|:---:|:---|
| Quét secret trong repo và toàn bộ git log | S9-1 | Thắng |
| Đối chiếu Project ID trên ảnh console với `google-services.json` | S9-2 | Thắng (hỗ trợ Charlie) |
| Mở repo, report, slide, video bằng chế độ ẩn danh | S9-3 | Thắng |
| Kiểm tra lịch sử Git (commit rải đều, đúng thứ tự giai đoạn) | S9-4 | Thắng |
| Luyện vấn đáp 5 phút (chạy 1 test ARTEMIS, đổi 1 giá trị Remote Config live, giải thích 1 ViewModel và 1 review) | S9-5 | Cả 4 người |
| **Nộp bài chính thức** (link repo, report PDF, slide PDF, link video) | S9-6 | Thắng |

> **M9 — Nộp bài:** Thắng

---

## Chuỗi đường găng (rút gọn)

```
S2-1 Interface service (Thắng)
  → S4-1 DataService (Hoàng) → S4-2 ViewModel (Hoàng) → S4-4/5/6 Flow 1-2-3 (Hoàng)
  → S3-3 AuthService (Charlie) → S3-6 Router (Thắng), S5-2 AnalyticsService (Thái An)
S2-3 Theme → S2-4 9 Widget (Charlie) → S3-4 Sign-in, S4-4 Flow 1, S4-13 Profile
S1-3 → S5-1 Chốt Analytics Plan (Thái An) → S5-2 → S5-3 / S5-4 → S5-5 DebugView
S4-10 PDF + S3-7 storage.rules (Charlie) → S4-11 Upload
        ↓ (tất cả hoàn tất)
S6-1 Feature freeze (Thắng) → S6-3 Test plan → S6-9 Chạy ARTEMIS (Thái An)
S6-1 → S7-1..S7-3 Review (cả nhóm) → S7-4 code-review.md (Thắng)
S6-9 + S7-4 → S8-5 Report / S8-10 Slide / S8-15 Video (Thắng) → S9-6 Nộp bài (Thắng)
```

---

## Các điểm cần xử lý trước khi chạy kế hoạch

1. Xác định nội dung và người phụ trách task **S0-2**; kiểm tra lại tổng task (các file cá nhân cộng ra 111, README ghi 112).
2. Giảm tải tuần 2 của Charlie (chuỗi theme → widget → Firebase → Auth) và tuần 4 của Thắng (19 task).
3. Bổ sung phụ thuộc: S4-1 cần chờ S2-5; S6-4 đến S6-9 cần chờ S6-3; S7-5 chờ fix của cả 4 người; video S8-11/12/13 nên chờ S6-10 và S7-3.
4. Cài Python 3.12+ / uv và chia API key ARTEMIS cho Charlie và Hoàng, vì họ cũng viết và chạy script.
5. Quy định tối thiểu **2 findings mỗi người** để đủ ≥ 5 findings tổng.
6. Ghi đồng sở hữu cho mốc/mục có hai chủ: M2 (Charlie + Thắng), M3 (Hoàng + Thái An), checklist #4 (Charlie + Thái An + Thắng).
