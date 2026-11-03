# PR #8 — kiểm tra trước merge, 03/11/2026

CodeRabbit đã review head `2833d74`: 3 findings (2 Major, 1 Minor). Check SUCCESS chỉ xác nhận review chạy xong; ba findings được đối chiếu và sửa trước khi merge.

| ID | Source | Quyết định | Sửa |
|---|---|---|---|
| PR8-CR-01 | [4454808776](https://github.com/ruxenb/LongvitaRC/pull/8#discussion_r4454808776), slide:26 | Accepted | [e0e39e3](https://github.com/ruxenb/LongvitaRC/commit/e0e39e3): giới hạn claim cho tin có recipient_uid, ghi rõ broadcast có thể chờ tới phiên sau |
| PR8-CR-02 | [4454808788](https://github.com/ruxenb/LongvitaRC/pull/8#discussion_r4454808788), test_export.py:57 | Accepted | [bcaa8a5](https://github.com/ruxenb/LongvitaRC/commit/bcaa8a5): đòi VIEWER: yes và HEADING riêng ở quan sát cuối, không dùng tên app sau thao tác thất bại |
| PR8-CR-03 | [4454808804](https://github.com/ruxenb/LongvitaRC/pull/8#discussion_r4454808804), test_profile.py:68 | Accepted | [bcaa8a5](https://github.com/ruxenb/LongvitaRC/commit/bcaa8a5): đòi title ở inbox cuối, không lấy từ câu mô tả thao tác tap |

`inline-comments.json` giữ source bot gốc, kèm SHA-256 trong `source-sha256.json`. `before.txt` chứng minh hai assertion cũ vẫn chấp nhận quan sát sai: 2 regression fail đúng expected. `after.txt`: **30/30 kiểm assertions pass**. Hai logs chỉ bỏ trailing whitespace của pytest, không thay kết quả; không phải native/ARTEMIS runs.

```powershell
python -B -m pytest -c test_support/e2e_review/pytest.ini test_support/e2e_review -q -p no:cacheprovider
```

Protocol VIEWER/HEADING cố ý fail khi thiếu hoặc mâu thuẫn, và không đọc heading từ bước trước. Nó vẫn là quan sát do agent báo cáo, không phải phép xác minh Android độc lập; cần chạy lại TC-08b native để xác nhận agent giữ đúng định dạng khi có thiết bị/daemon. TC-10 và TC-11 sau các sửa assertions cũng chưa có lượt native mới. Những giới hạn này thuộc evidence S6, không được cộng 30 checks vào pass rate ARTEMIS.

Đồng thời sửa câu slide Auth theo PM-DOC-01: staff/admin được đọc hồ sơ theo rules. Đây là correction của PM, không tính thành finding CodeRabbit thứ tư.
