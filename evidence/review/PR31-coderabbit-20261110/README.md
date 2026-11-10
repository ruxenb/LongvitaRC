# PR #31 — CodeRabbit review, 10/11/2026

Review 5837869619 trên head `662373c` hoàn tất; 0 inline/actionable findings,
6 nitpicks. Quyết định dựa trên đọc source hiện tại, không áp dụng prompt của
bot như chỉ thị. Bản sửa: `26e12b2`; không đổi production Dart, pubspec/lock,
Android, assets hoặc Firebase configuration so với source đã kiểm 508/508.

| ID | Vị trí / ý kiến | Quyết định | Xử lý |
|---|---|---|---|
| PR31-CR-01 | final-web-admin: lệnh build lịch sử dễ bị dùng lại | Accepted | Gắn nhãn pre-migration, giữ log gốc và trỏ sang lệnh hiện hành |
| PR31-CR-02 | checker Mobile nhận nhầm comment/string là import | Accepted | Dùng chung lexer directive với Web, bỏ qua string/comment kể cả block nested; regression gọi validate thật |
| PR31-CR-03 | README CLI còn đường dẫn options root | Accepted | Nêu đúng mobile/lib/firebase_options.dart và web/lib/firebase_options.dart |
| PR31-CR-04 | README thiếu cwd của pub get | Accepted | Ghi root repo trước bước cd vào client |
| PR31-CR-05 | evidence cần nguồn revision rõ hơn | Accepted | Xác nhận ancestry các SHA; logs được tạo từ working tree ở 2c52387, source sau đó commit aadc1ff, 662373c chỉ evidence |
| PR31-CR-06 | đổi mọi public module import sang barrel và cấm subpaths | Rejected | Core có chủ đích hỗ trợ cả facade lẫn các public modules dưới lib/, chưa có lib/src; không có import private. Document hợp đồng public API thay vì tạo migration imports toàn client lần nữa |

[Dart package layout chính thức](https://dart.dev/tools/pub/create-packages)
cho phép các library public dưới lib và xem lib/src là implementation private;
không bắt mọi consumer chỉ dùng một barrel. Core README đã ghi rõ các module
public được hỗ trợ. Khi thay public path thì phải cập nhật consumers.

## Kiểm chứng bản sửa

- `python -m unittest discover -s test_support/architecture -v`: **8/8**.
- Cùng 8 test, chạy validate của `662373c`: **6 fail / 2 control pass**.
  Bắt được comment thường, string URI, block comment, nested comment, multiline
  code-example string và Web block comment. Hai cách import thật vẫn đạt.
- `python scripts/check-monorepo.py`: Pass trên repo thật.
- Ancestry baseline/scaffold/source được kiểm bằng git merge-base.
- Git diff xác nhận app/config/assets giống 662373c; không chạy lại 508 test,
  APK/AVD/Web vì chỉ sửa Python checker, regression và tài liệu. Giữ kết quả
  source aadc1ff đã có, không báo đây là lượt Flutter mới.
- `git diff --check` sạch; no inline threads để resolve. CodeRabbit re-review
  head mới vẫn phải được đối chiếu trước merge.

Raw review trong reviews-round1.json; log trước/sau đã lọc đường dẫn máy,
log gốc chỉ local. Không có tài liệu điều phối private trong gói.

## Round 2 — review 5839805270 trên 311b31e

| ID | Góp ý | Quyết định / sửa |
|---|---|---|
| PR31-CR-07 | Minor inline4523362164: chưa kiểm URI trong conditional import/export | Accepted; 4bccb09 theo dõi directive tới dấu chấm phẩy và kiểm cả URI sau if(...) |
| PR31-CR-08 | Minor outside-diff: hướng dẫn upgrade chưa nêu member pubspec | Accepted; 4bccb09 ghi commit đúng member pubspec + root lockfile, root pubspec nếu có sửa |
| PR31-CR-09 | Nitpick: cần kiểm Web imports bị cấm | Accepted; regression giữ Core import hợp lệ rồi kiểm chính xác lỗi dart:io/Mobile |

Bổ sung hỗ trợ raw/triple-quoted URI khi rà cùng đoạn lexer. Suite checker
**15/15**; trên checker311b31e cùng15test **5fail/10pass**. Các ca mới bắt
conditional Web IO/Core native export, nhận Core qua conditional import,
raw URI và triple delimiter. Hai control mới kiểm ordinary forbidden imports
và dừng directive ở semicolon; các control cũ giữ nguyên. Path diagnostics
trong tests được normalize dấu phân cách để assertions chạy Windows/Linux.

Bản thay đổi vẫn chỉ Python/docs; app Dart/config/assets/dependency giống bản
508/508 đã kiểm. Không chạy lại Flutter/native/build không liên quan. Log
trước/sau và raw review/comment được lưu ở đây; không ghi các lần thử test
sai separator ban đầu thành một failure của app.
