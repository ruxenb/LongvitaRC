# LongvitaRC — Nghiên cứu đa nguồn về sách Chế độ ăn trường thọ và công thức (06/11/2026)

**Trạng thái:** Research / Pre-Approval. **Không nhập Firebase production.** Chủ dự án yêu cầu Hoàng nghiên cứu công thức thật, dẫn nguồn và định lượng trước khi xin phép nhóm. Báo cáo này tập trung làm rõ **có thể chứng minh được gì**, không giả vờ đã kiểm chứng toàn văn sách bản Việt.

## I. Phương pháp và kết quả

Đã đối chiếu bốn nhóm nguồn: (1) biên mục bản Việt tại thư viện, (2) thông tin bản gốc tiếng Anh và người viết/nhà xuất bản, (3) hướng dẫn/thực đơn/công thức do Quỹ Valter Longo và chính tác giả phát hành, (4) dữ liệu thành phần thực phẩm Viện Dinh dưỡng Việt Nam và USDA.

- Tên sách Việt: *Chế độ ăn trường thọ: Tối ưu cân nặng, đẩy lùi bệnh tật, kéo dài tuổi thọ*; tác giả Valter Longo; dịch Nguyễn Khánh Chi; ISBN 9786043140545. Biên mục 2021 của Thư viện KHTH TP.HCM ghi 298 tr.; mục lục 2023 của Thư viện Mân Côi ghi 297 tr., **Phụ lục A bắt đầu tr.238**, Phụ lục B từ tr.265. Số trang thay đổi theo bản in; không suy diễn trang từng món từ tiếng Anh sang tiếng Việt.
- Bản tiếng Anh xuất bản bởi Avery/Penguin, ISBN bìa mềm **9780525534099**, 320 trang. Mục lục xác nhận Appendix A là thực đơn hai tuần. Website tác giả cho biết sách có **30 công thức đơn giản**, nhưng đó không phải giấy phép tái bản nguyên văn.
- Một nguồn văn bản trực tuyến của bên thứ ba hiển thị nội dung thực đơn theo tuần/ngày/bữa nhưng tự xác nhận là **ScribdTranslations, AI-enhanced**. Nguồn này chỉ đáng dùng để **dò tên món và phát hiện vấn đề**; không phải ấn bản được xác thực. Nó có lỗi từ vựng/nội dung thực phẩm, ví dụ `octopus` thành `powder`, tiêu đề món đậu thành `veal`, và một số danh từ pha ngôn ngữ khác. Không đưa các số từ nguồn này vào `recipes`.
- Trang **Sample Longevity Diets** của Quỹ (20/04/2020) có lượng thực phẩm cụ thể theo **hai hồ sơ người dùng khác nhau**, không phải công thức mặc định cho mọi người và không phải danh sách Phụ lục A.
- Trang **Recipes of Longevity** của chính tác giả/Quỹ có món, cách chế biến, đôi khi số khẩu phần nhưng vẫn để `salt to taste`, `1 garlic clove`, `olive oil` hoặc khối lượng thô chưa xác định phần ăn được. Không thể coi đây là calo/đạm theo khẩu phần đã chuẩn hóa.

**Deliverable:** `docs/hoang-recipe-research-ledger-20261106.json` — **17 bản ghi ứng viên**: 13 tên món từ Phụ lục A ở mức tham chiếu thứ cấp, 2 bữa có định lượng từ thực đơn mẫu chính thức và 2 công thức có số khẩu phần từ website tác giả. Không chứa `firestore` payload hoặc dinh dưỡng tự suy diễn.

## II. Nguồn và mức độ chứng cứ

| Nhóm | URL kiểm tra | Có thể sử dụng | Không thể suy diễn |
|---|---|---|---|
| Bản Việt — Thư viện Mân Côi | https://thuvienmcbc.org/index.php/thuvien/catalog_product/view/id/5771/ | ISBN nếu đối chiếu thêm, dịch giả, Mục lục, Phụ lục A tr.238 | Chưa nhìn thấy chữ/định lượng của từng trang sách Việt |
| Bản Việt — Thư viện KHTH TP.HCM | https://phucvu.thuvientphcm.gov.vn/Item/ItemDetail/748047 | NXB Dân Trí; năm 2021; ISBN 9786043140545; 298 trang | Không có toàn văn hoặc bản quyền tái phân phối |
| Nhà xuất bản Anh | https://www.penguinrandomhouse.com/books/564866/the-longevity-diet-by-valter-longo-phd/ | Tác giả, ấn bản bìa mềm 2019, ISBN 9780525534099 | Không chứng minh trang tiếng Việt |
| Tác giả | https://valterlongo.com/the-longevity-diet/ | Giới thiệu sách, cơ sở hướng dẫn | Không phải toàn văn phụ lục |
| Quỹ — người trưởng thành | https://www.fondazionevalterlongo.org/en/longevity-diet-for-adults/ | Nguyên tắc ăn giàu thực vật, đạm đậu, 2–3 bữa cá/tuần, điều chỉnh theo tuổi | Không suy ra mọi người cần 0,8g/kg/ngày hoặc thực đơn giống nhau |
| Quỹ — mẫu theo hồ sơ | https://www.fondazionevalterlongo.org/en/sample-longevity-diets/ | Định lượng 2 bữa mẫu và phân nhóm sức khỏe | Không đồng nghĩa đã có kcal/protein từng món |
| Tác giả + Quỹ — công thức web | https://valterlongo.com/recipes-of-longevity/ | Tên món, nguyên liệu và số khẩu phần với một số món | Không phải món chắc chắn nằm trong sách |
| Viện Dinh dưỡng VN | https://viendinhduong.vn/vi/cong-cu-va-tien-ich/gia-tri-dinh-duong-thuc-pham | Tra tên/mã và dưỡng chất/100g phần ăn được | Không có sẵn sự liên kết tự động giữa từng món sách và mã thực phẩm |
| USDA FoodData Central | https://fdc.nal.usda.gov/ | Dưỡng chất/100g, loại mẫu, FDC ID; dữ liệu công khai CC0 | Không được dùng dữ liệu của loại cá/gạo/đậu khác làm cùng một thực phẩm |
| USDA dữ liệu tải về | https://fdc.nal.usda.gov/download-datasets/ | Đóng băng phiên bản dataset/ID phục vụ truy vết | Các dataset Foundation, SR Legacy, FNDDS, Branded khác phương pháp và phạm vi |
| Bản văn không chính thức | https://www.scribd.com/document/970691885/BOOK-TRANSLATED-Longevity-Diet-Valter-Longo-1-1 | Dò ứng viên tên và vị trí tuần/ngày, **mức tin cậy thấp** | Không xác thực được phiên bản, lời dịch, số trang, quyền hoặc số liệu |

## III. Hai nhóm dữ liệu tuyệt đối không được trộn lẫn

**A. Món tham chiếu từ sách / Phụ lục A** (`type=book_appendix_candidate`): đặt nhãn `UNOFFICIAL_AI_TRANSLATED_COPY`, không có `pageVi`/trang ấn bản xác minh, kcal hoặc protein. Một số ứng viên: rau bina với hạt thông và nho khô, pasta bông cải/đậu đen, gạo lứt với đậu que, cá hồi/măng tây, pasta đậu gà, pasta đậu lăng, súp bí đỏ, gạo đen Venere/tôm, minestrone kiểu Genoa. Không sao chép hướng dẫn nấu từ bản dịch không rõ quyền. **Không coi danh mục 13 tên món là toàn bộ hai tuần.**

**B. Tài liệu do chính Quỹ và tác giả công bố** (`FOUNDATION_PRIMARY`/`AUTHOR_FOUNDATION_PRIMARY`): có thể kiểm tra một số lượng g/ml và số khẩu phần, nhưng đây là **các món tham chiếu website**, không tự động ghi `sourceNote='Từ sách Phụ lục A'`. Các minh họa nguồn:
- Bữa spelt/diếp xoăn/cà rốt: 60 g spelt, 9 g dầu ô liu, 5 g Grana Padano, 150 g diếp xoăn, 50 g cà rốt; danh sách lượng g do Quỹ công bố. Cần kiểm tra khô/chín và phần ăn được trước khi tính chất dinh dưỡng.
- Bữa spelt/đậu lăng/mè của nhóm người lớn tuổi: 70 g spelt, 50 g **đậu lăng khô**, 15 g mè, 9 g dầu ô liu; rau ăn kèm tách khỏi món chính.
- Món mực om: website có **4 khẩu phần**, các lượng 500 g mực ống, 300 g mực nang, 500 g cà chua, 40 ml dầu ô liu. Cần quy đổi mực đã sơ chế và dầu ml → g, đo 2 tép tỏi nếu tính toàn phần.
- Món cá cơm nướng: **4 khẩu phần**, 400 g cá cơm tươi, 1 kg escarole, 6 muỗng dầu ô liu. Lượng dầu dùng thực tế và tỷ lệ cá bỏ đầu phải được xác nhận.

## IV. Errata bắt buộc cho bản chỉ mục trước

- **Tuần 1 ngày 2 trưa**: `brown rice` = **gạo lứt**, không phải **gạo hoang**. Gạo hoang là một loài/họ hạt khác; dùng sai có thể làm sai kcal/đạm.
- **Tuần 1 ngày 3 tối**: nguồn thứ cấp ghi **cooked chickpeas and pasta**; chưa có căn cứ để tự gọi là **súp minestrone**.
- **Tuần 1 ngày 4 tối**: nguồn ghi **pasta with lentils**; không chứng minh món mang tính súp.
- **Tuần 1 ngày 5 tối**: bản máy dịch ghi **80 g of powder** ở món bạch tuộc; đây là lỗi nghiêm trọng, cấm đưa lượng đó vào hệ thống.
- **Tuần 2 ngày 4 tối**: nguồn ghi **Venere rice (black)**: phân biệt gạo đen Venere với gạo lứt và gạo hoang.
- Các "trang bản tiếng Anh" liệt kê tại `hoang-book-menu-index-20261106.md` chỉ phục vụ **định vị ban đầu**; chưa xác minh trực quan từng trang trong ấn bản chính thức.

## V. Tính toán thành phần dinh dưỡng — yêu cầu kiểm chứng

Đầu vào cho mỗi nguyên liệu phải có:
`ingredientId`, tên chuẩn, trạng thái **tươi/khô/đã nấu**, g phần ăn được, mã NIN/FDC ID, URL, phiên bản dữ liệu, kcal/100g, protein/100g, lưu ý chuyển đổi/hao hụt. Đối với dầu theo ml phải có khối lượng theo mật độ có nguồn; với bánh, sản phẩm đóng gói và các hạt quy đổi phải có loại cụ thể. Gia vị có khối lượng đáng kể phải được tính hoặc được bên duyệt cho phép loại trừ có ghi chú.

Công thức:
- kcal/bữa = tổng `(g ăn được × kcal mỗi 100g / 100)` / số khẩu phần;
- protein/bữa (g) = tổng `(g ăn được × protein mỗi 100g / 100)` / số khẩu phần.

Chỉ báo **ước tính từ thành phần thực phẩm**, không được gọi là số đo phòng thí nghiệm. Lỗi có thể phát sinh khi lấy dữ liệu khô cho nguyên liệu chín, tính nước luộc, tổn thất khi nấu, lượng dầu hấp thụ và phần cá bỏ xương.

**Không có đủ chứng cứ để kết luận kcal và protein CHÍNH XÁC cho bất kỳ ứng viên nào trong đợt này.** Vì vậy không ghi số giả hay tính trên giả định mà không dán nhãn ước tính. Quy trình bảo đảm tính truy vết được chuẩn bị tại `docs/hoang-recipe-approval-20261106.md`.

## VI. Vấn đề khoa học và nghiệp vụ cho ứng dụng

1. Thực đơn hai tuần trong sách không được biến thành phác đồ cá nhân hóa cho mọi người. Chính Quỹ lưu ý nhu cầu thay đổi theo tuổi, tình trạng giảm khối cơ và thể trạng. Nếu không có chuyên gia thẩm định, chỉ nên gắn nhãn **gợi ý tham khảo** chứ không phải điều trị.
2. Nếu người dùng dị ứng cá, giáp xác, sữa, hạt, gluten… ứng dụng hiện chưa chứng minh lọc toàn diện. Không suy ra món `category=ca` đã an toàn cho người dị ứng cá, hoặc món rau luôn không có gluten.
3. Giải thuật chọn 7 ngày hiện tại dựa trên tập `recipes`; khi tập chưa được duyệt, tính đúng chức năng không đồng nghĩa thực đơn có tính đúng dinh dưỡng.
4. `sourceNote` chỉ được nêu **tên cuốn và trang** khi chính xác trang/ấn bản đã được xác minh. Nếu chỉ tham khảo website Quỹ, phải ghi là **nguồn website**, không gán giả "Phụ lục A".
5. Hướng dẫn chế biến và ảnh của sách có quyền tác giả; không chép toàn bộ sách vào Firebase từ bản copy không được phép. Dữ liệu dinh dưỡng USDA là công khai CC0, độc lập với quyền của sách và hình ảnh.

## VII. Quyết định triển khai

| Hạng mục | Hiện trạng sau nghiên cứu |
|---|---|
| Nhận diện đúng sách/bản Việt/phụ lục | **Đủ nguồn biên mục** |
| Danh mục 13 món tiêu biểu theo tuần/ngày | **Ứng viên, thứ cấp; cần đối chiếu sách chính thức** |
| 4 ứng viên từ nguồn chính thức | **Nguồn xác minh, định lượng mới một phần** |
| `name`, `category`, `ingredients` cấp sản phẩm | **Chưa có đủ chứng cứ cho bản ghi sản xuất** |
| `calories`, `proteinGrams` theo khẩu phần | **Chưa tính, không suy diễn** |
| `sourceNote` và quyền tái sử dụng | **Chưa duyệt** |
| Cho phép nhập Firebase dùng chung | **Chưa có chấp thuận theo đúng batch** |
| Tập `recipes` đã nhập | **0 bản ghi được nhập trong tác vụ này** |

**Cổng phê duyệt:** https://github.com/ruxenb/LongvitaRC/issues/16. Không tạo seed demo trá hình, không deploy `firebase/firestore.rules`, không ghi vào dự án thật trước khi nhóm phê duyệt.
