# Release gate cho 29 công thức dựa theo sách — 11/11/2026

## Kết quả kiểm toán

- Có 29 ID duy nhất, đầy đủ trường dữ liệu và có _bookProvenance. Các dữ liệu này là bản chép lại hoặc tái cấu trúc nội bộ, KHÔNG phải bằng chứng sách gốc đã được đối chiếu từng dòng.
- Catalog SHA256 (exact bytes): 894be09966a2f33676768b4516ccb91727161386f16ba04f4de00b8f43df223c
- Repository thêm script scripts/seed-book-recipes.cjs, có lệnh --apply. Bản ban đầu chỉ cần Firestore access token và in thông báo mọi món sẵn sàng sau một dry-run chưa có phê duyệt. Điều này không đủ an toàn cho collection recipes dùng chung.
- Đã thêm chốt bảo vệ: dry-run chỉ kết luận kiểm tra cấu trúc; apply cần chỉ rõ project, file phê duyệt đúng SHA256, chữ ký nghiệm thu nguồn và định lượng cho từng 29 ID, cuối cùng mới xét token. Không có file phê duyệt thì script FAIL trước khi gọi Firebase.
- Một bản ghi phê duyệt cần có id, approved=true, sourceReviewedBy, nutritionReviewedBy, bookSourceEvidence, nutrientEvidence. File tổng cần approved=true, projectId=longvita-8da7e, collection=recipes, catalogSha256 và recipeReviews gồm đủ 29 phần tử. Reviewer phải xác minh thật; việc kiểm tra chuỗi không tự xác minh độ đúng của tài liệu.
- Các công thức chưa được phê duyệt trong lượt kiểm toán này; KHÔNG viết, sửa hay seeding vào Firebase production.

## Quy trình phát hành an toàn

1. Chạy node scripts/seed-book-recipes.cjs --dry-run để đọc 29 candidate và hash. Không kết nối Firebase.
2. Nhóm dữ liệu đối chiếu nguyên văn từng món với sách, ghi bằng chứng trang/phụ lục và kiểm tra phép tính dinh dưỡng theo nguyên liệu định lượng; đánh dấu sai khác và giới hạn sử dụng.
3. Người có thẩm quyền xác nhận từng món (sourceReviewedBy, nutritionReviewedBy, evidence refs), tạo file phê duyệt ở vị trí bảo mật ngoài Git.
4. Chạy kiểm thử Node offline, kiểm tra đúng SHA256 file đã nghiệm thu. Bất kỳ thay đổi nào ở catalog sẽ làm sai hash, buộc duyệt lại.
5. Chỉ khi đã được nhóm phê duyệt, sử dụng lệnh apply với hai flags --approval-file [file] --confirm-project longvita-8da7e và FIRESTORE_ACCESS_TOKEN trong phiên shell hợp lệ. Không ghi token vào code/log/commit.
6. Script chỉ tạo bản ghi chưa tồn tại; vẫn cần kiểm tra đọc lại trên môi trường Firebase và thống kê số món thực tế. Không sửa record đang bán/sử dụng tự động.

## Quyền nghiệm thu còn thiếu

Bài kiểm thử tự động chỉ xác minh cấu trúc và tính đầy đủ của hồ sơ review; KHÔNG chứng minh nội dung 29 món thật sự xuất hiện đúng trong sách hay calo/đạm chính xác. Cần người đủ năng lực kiểm định nguồn, định lượng và chấp thuận dùng chung trước khi phát hành.

## Kết quả kỹ thuật

- 10/10 Node unit tests cho cổng review, duplicate IDs, invalid quantities, provenance mismatch, wrong hash, thiếu reviewer, token giả và dry-run không gọi network.
- 29 món pass schema hiện tại; đây không phải chứng nhận nguồn hay dinh dưỡng.
- Script và unit tests chỉ chạy offline trong lần kiểm toán này. Không có Firebase writes.
