# S4-10 — PDF theo đúng thực đơn đang xem, 09/11/2026

Kiểm hai ca còn thiếu của S4-10 trên app thật, với recipes thật trên Firestore:
- hai kế hoạch khác nội dung;
- đổi món rồi xuất lại.

Nhánh `feature/charlie-pdf-03`, tạo từ main `eb0d0de`.

## Dữ liệu

- **Batch:** [`docs/s4-10-recipe-batch-approved-20261109.json`](../../../docs/s4-10-recipe-batch-approved-20261109.json), gồm 2 món không phải cá.
  - `lv-fvl-spelt-chicory-carrot-v1`: 358,36 kcal / 13,178 g.
  - `lv-fvl-spelt-lentil-sesame-v1`: 578,11 kcal / 25,1735 g.
- **Nguồn:** thực đơn mẫu của Fondazione Valter Longo (20/04/2020). Dinh dưỡng ước tính theo USDA FoodData Central SR Legacy (API đọc 09/11).
- **Phê duyệt:** Charlie duyệt recipes SHA256 `e07d7fe291c7068baa05f2f30bba1f31ef367dbce6417f27d62a70fe80f8db87` tại [issue #16](https://github.com/ruxenb/LongvitaRC/issues/16#issuecomment-6730769453) (09/11 09:26). Chỉ tạo mới 2 ID.
- **Import thử trên Firestore Emulator:** đạt 4/4 kịch bản ([import-rehearsal-emulator.txt](import-rehearsal-emulator.txt)): tạo và đọc lại; chạy lần hai bị chặn; ID đã có thì không ghi; lỗi giữa chừng thì dừng.
- **Import thật:** `scripts/publish-approved-recipes.cjs` chạy create-only lúc 09:26:58 trên `longvita-8da7e/recipes` ([recipes-import.txt](recipes-import.txt)). Đọc lại độc lập: đủ 2 document, khớp manifest từng trường ([recipes-readback.txt](recipes-readback.txt)). Không sửa hay xóa dữ liệu nào khác; ba plan A9 cũ giữ nguyên.

## Môi trường

- **APK:** debug, build từ `55efe63` (code app giống main `eb0d0de`), `--dart-define=STORAGE_EMULATOR_HOST=10.0.2.2`. SHA-256 `85fafeb21ab86ef12eda110046e299bfda28e10aa6250d9b04e196b36bab0bb8`.
- **Thiết bị:** AVD `LocalMate_API_35`, Android 15, màn 320×640.
- **Dịch vụ:** Auth và Firestore dùng project thật `longvita-8da7e`, tài khoản kiểm của Charlie. Upload PDF lên Storage Emulator, không phải Storage thật (DEC-01).
- **Cách thao tác:** chạm và nhập qua `adb` theo nhãn trên màn hình. PDF lấy bằng `run-as` từ thư mục của app, đúng file vừa tạo trong mỗi lượt xuất.

## Kết quả

| Ca | Thao tác trên app | PDF | Đối chiếu |
|---|---|---|---|
| P1 | S02: 30 tuổi, 60 kg, **2 bữa/ngày** → Tạo kế hoạch → Lưu → Profile → Xuất | [trang 1](10-pdf-P1-page1.png) | Mỗi ngày: diếp xoăn + đậu lăng, 936 kcal / 38,4 g. Mục tiêu 1512 kcal / 48,0 g. Bản nháp. Khớp |
| P2 | Như trên với **3 bữa/ngày** | [trang 1](20-pdf-P2-page1.png), [trang 2](21-pdf-P2-page2.png) | T2/T4/T6/CN: 1295 kcal / 51,5 g; T3/T5/T7: 1515 kcal / 63,5 g. Khác P1 về số món, thứ tự và tổng. Khớp |
| Đổi món | Mở lại P2 từ "Kế hoạch đã lưu" → Thứ Hai, bữa 2 (đậu lăng) → Đổi món ăn → app đề xuất đúng 1 món (diếp xoăn) → Xác nhận → lưu xong → Xuất | [trang 1](30-pdf-after-change-page1.png), [trang 2](31-pdf-after-change-page2.png) | Thứ Hai: 3 × diếp xoăn, 1075 kcal / 39,5 g; các ngày khác giữ nguyên. Plan ID không đổi. Khớp |

- **Đối chiếu tự động** ([pdf-compare.txt](pdf-compare.txt)): so từng dòng ngày/món và phần đầu (trạng thái, mục tiêu) với kế hoạch tính từ batch theo quy tắc chọn món của app. Kết quả 3/3 khớp.
- **Kiểm bằng mắt trên bản render:** dấu tiếng Việt đúng, không cắt chữ, đủ 7 ngày; bản 3 bữa sang trang 2 kèm "Trang 1/2", "Trang 2/2".
- **Firestore sau đổi món** ([firestore-plans-readback.txt](firestore-plans-readback.txt), ID plan đã che UID): P2 cập nhật lúc 02:42:11Z, trước lần xuất C lúc 02:42:42Z; Thứ Hai là 1075,08 kcal / 39,534 g.
- **Mở và chia sẻ:**
  - "Mở PDF đã lưu" mở print preview của hệ thống, PDF 2 trang của lần xuất cuối ([ảnh](05-open-pdf-preview.png)).
  - "Chia sẻ PDF đã lưu" mở share sheet "Sharing 1 file" với đúng tên file đó. Đóng ngay, không gửi; ảnh không lưu vì tên file chứa UID.
- **Ảnh app:** [P1 Thứ Hai](01-app-P1-monday.png), [P2 Thứ Hai](02-app-P2-monday.png), [màn món thay thế](03-app-alternatives.png), [sau khi đổi](04-app-after-change.png).

## Kiểm tự động

- `test/report/export_plan_selection_test.dart` (mang từ `0987a19`): 2/2. Kiểm ngược đạt: tạm hỏng đường chọn plan hoặc đường đổi món thì đúng test tương ứng fail.
- `flutter analyze --no-pub lib test`: sạch. `flutter test --no-pub`: 400/400.
- Chứng minh bằng code app trên batch ([app-logic-proof.txt](app-logic-proof.txt)): generator thật cho P1/P2 khác nội dung; bộ lọc món thay thế chỉ đề xuất đậu lăng → diếp xoăn; `replaceMeal` lưu trước rồi mới áp dụng.

## Giới hạn

- Hai món đều là ngũ cốc. P1 và P2 khác nhau nhờ số bữa/ngày; app chỉ cho chọn 2–5 bữa.
- Số dinh dưỡng là ước tính từ nguyên liệu. Các giả định (spelt cân khô, món đậu lăng chỉ là phần chính, Grana Padano tính theo số của parmesan bào, chicory là phần lá) đã được duyệt cùng batch.
- Upload dùng Storage Emulator. Upload thật thuộc S4-11/DEC-01.
- Chưa chạy trên máy thật.
