# Review PR #6 — Bugbot và Security Review, 03/11/2026

## Phạm vi

- PR: `ruxenb/LongvitaRC#6`
- Head được review: `feature/charlie-report-02` tại `08e74930ca7268fffccaf4e410d636f0422bdb71`
- Base: `main`
- Nhánh khắc phục: `Thang`
- Công cụ: Codex Bugbot, sau đó Codex Security Review.
- Trọng tâm: độ đúng của claim/evidence/task; secret, PII, đường dẫn máy; hướng dẫn Firebase/Storage; tính nhất quán report/slide/clip/ARTEMIS.

## Findings và quyết định

| ID | Mức | Công cụ | Finding | Quyết định | Xử lý |
|---|---|---|---|---|---|
| PR6-01 | P1 | Security Review | Ảnh `07-queue-attempt-snackbar.png` chứa tên và email thật. | Accepted | Loại ảnh khỏi repo; README giải thích giới hạn evidence. |
| PR6-02 | P2 | Bugbot + Security Review | Traceback ARTEMIS 2.188 dòng lộ username và đường dẫn máy. | Modified | Thay raw log bằng bản tóm tắt khử PII, giữ đủ kết quả kỹ thuật. |
| PR6-03 | P2 | Security Review | Kịch bản clip coi việc che định danh là tùy chọn. | Accepted | Bắt buộc che/cắt PII trên repo, slide và video; tránh quay vùng Auth Users có định danh. |
| PR6-04 | P3 | Bugbot | Checklist ghi bốn chiến dịch cho ba cảnh FCM. | Accepted | Sửa thành ba chiến dịch. |
| PR6-05 | P3 | Bugbot | Header task Charlie ghi 02/11 dù evidence/tiến độ thuộc 03/11. | Accepted | Sửa ngày thành 03/11/2026. |

Security Review không phát hiện API key, service-account key, bearer token,
password, private key hoặc hướng dẫn Storage rules không an toàn trong diff PR.
Bugbot không phát hiện regression chức năng; các claim về 14 Storage rule tests,
9 open-rule failures, retry semantics, Remote Config intervals và 7 ARTEMIS
collection cases khớp implementation/evidence.

## Commit khắc phục

- `55bdf3e591808e5bfcf5af52a6a866384b0b83fe`
  — `fix(review): resolve PR #6 privacy and evidence findings`

## Kiểm chứng sau sửa

- `flutter analyze`: không có issue.
- `flutter test`: 270/270 pass.
- `pytest --collect-only -q`: nhận đủ 7 test E2E.
- `git diff --check`: pass.
- Quét text diff cho username/OneDrive, email FPT, Google API key, private key
  và bearer token: không còn pattern mục tiêu.

## Giới hạn

- Không chạy ARTEMIS thật vì daemon/model key chưa có; chỉ kiểm `collect-only`.
- Không dùng ảnh do AI tạo/chỉnh sửa làm evidence. Ảnh có PII được loại thay vì
  biến đổi, để không làm sai lệch bằng chứng chạy thật.
- Stage 7 chưa hoàn tất toàn nhóm: hồ sơ này ghi review PR #6, không thay review
  cho các PR/thành viên còn lại và chưa đáp ứng yêu cầu tối thiểu ba fix commits.

## Trạng thái tích hợp 04/11/2026

- Commit sửa `55bdf3e` và toàn bộ hồ sơ này đã được merge vào `main` qua merge
  commit `90d9fd0`.
- Nội dung hiện đủ để tiếp tục S7-2-VLQ/S7-3-VLQ ở trạng thái **Đang làm**,
  nhưng chưa tự đóng hai task vì S7-1-VLQ vẫn phụ thuộc feature freeze S6-1 và
  quy trình PR riêng của giai đoạn review.
