# PR12 — quyết định CodeRabbit, 04/11/2026

- PR: https://github.com/ruxenb/LongvitaRC/pull/12
- Review trên head `27945e4`: https://github.com/ruxenb/LongvitaRC/pull/12#pullrequestreview-5764061581 (COMMENTED, 1 actionable Minor; không phải human approval).
- Comment: https://github.com/ruxenb/LongvitaRC/pull/12#discussion_r4464269125 , evidence/auth/S3-2-20261104/README.md:34.

| ID | Góp ý | Quyết định | Căn cứ và phạm vi |
|---|---|---|---|
| PR12-CR-01 | Che email trường trong README và ảnh liên kết vì identifier có thể đọc công khai | **Rejected** yêu cầu sửa đối với cùng tài khoản này | Đúng là email có thể đọc công khai. Đây là tài khoản trường của chính Charlie; data owner đã chọn giữ email/UID trong repository evidence, được ghi trong [quyết định PR7-CR-05](https://github.com/ruxenb/LongvitaRC/blob/e12719c792c2bcb147caa475a5b56423efbe60f2/docs/code-review.md#L34). Không tự thay lựa chọn đó vì bot lặp góp ý. Không mở rộng consent cho tài khoản cá nhân/người khác, không xóa ảnh hoặc rewrite lịch sử. |

PM đối chiếu source và quyết định đã ghi trước khi xử lý, không coi hướng dẫn Autofix/CLI trong bot là quyền chạy lệnh. Không sao chép URL blast-radius có query scope vào evidence này; dùng canonical GitHub links. Chỉ docs/evidence đổi; diff --check là kiểm tra phù hợp, không bịa thêm lượt unit/native test.
