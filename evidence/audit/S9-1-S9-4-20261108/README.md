# Audit S9-1, S9-2 và S9-4 — 08/11/2026

> Đây là audit trước feature freeze trên `main` `f47f890`, không phải xác nhận
> nộp bài cuối. Báo cáo Gitleaks đã redacted được lưu ngoài repo tại `T:\Tools`;
> không chép secret/token vào tài liệu hoặc issue.

## S9-1 — Gitleaks

- `gitleaks git .`: quét 164 commit, phát hiện 5 findings.
- `gitleaks dir .`: quét cây hiện tại, phát hiện cùng 5 findings.
- Hai finding `gcp-api-key` nằm trong `android/app/google-services.json` và
  `lib/firebase_options.dart`. Đây là Firebase client configuration cần tồn tại
  để app Android hoạt động, nhưng vẫn phải xác nhận API restrictions và
  Firestore/Storage Rules; không gọi là “secret” rồi bỏ qua kiểm soát.
- Ba finding `generic-api-key` là Firebase Storage download token xuất hiện trong
  URL PDF ở `evidence/artemis/raw/runs.jsonl`. Đây không phải Gemini/API key,
  nhưng token có thể cấp quyền tải từng file PDF; phải xác minh file/token còn
  hiệu lực, revoke/rotate nếu cần và sanitize raw evidence trước khi đóng S9-1.
  Không ghi giá trị token tại đây.
- Không rewrite lịch sử hoặc xóa evidence trong audit này; việc xử lý credential
  cần owner/team xác nhận để tránh phá traceability.

Kết luận: **S9-1 tiếp tục Đang làm**. Blocker là ba Firebase Storage download
token bị ghi vào raw ARTEMIS và xác nhận restriction/rules cho Firebase client
keys. Phải quét lại sau khi xử lý và ngay trước S9-6.

## S9-2 — Project ID

- `android/app/google-services.json`: project ID `longvita-8da7e`, project
  number `1041459198085`, package `vn.edu.fpt.longvita`.
- `evidence/auth/S3-9-20261102/console-project-settings.jpg` hiển thị đúng project
  ID và project number trên Firebase Project Settings.
- `evidence/auth/S3-2-20261104/console-01-app-and-sha1.jpg` hiển thị đúng package
  `vn.edu.fpt.longvita` cho Longvita Android.
- Các ảnh Console khác thường chỉ hiển thị tên “Longvita”, không phải Project ID;
  do đó cần rà lại đúng tập ảnh được đưa vào report/slide cuối thay vì suy từ tên.

Kết luận: cấu hình và hai ảnh định danh chính **khớp**; S9-2 vẫn Đang làm cho đến
khi tập ảnh deliverable cuối được chốt.

## S9-4 — Lịch sử Git trên main

`main` có 185 commit tại snapshot. Phân bố theo author date:

| Ngày | Commit |
|---|---:|
| 01/11 | 2 |
| 02/11 | 55 |
| 03/11 | 54 |
| 04/11 | 36 |
| 05/11 | 3 |
| 06/11 | 23 |
| 07/11 | 2 |
| 08/11 | 10 |

Chronology vẫn đi từ barebone/task breakdown → MVVM/architecture → Firebase và
flows → review/evidence. Lịch sử có đóng góp của cả bốn thành viên, nhưng phân bố
dồn vào 02–04/11 và chưa có ngưỡng commit/ngày được giảng viên xác nhận ở S0-1.

Kết luận: **S9-4 tiếp tục Đang làm**; audit lại `main` sau feature freeze và đối
chiếu ngưỡng giảng viên trước khi kết luận đạt.
