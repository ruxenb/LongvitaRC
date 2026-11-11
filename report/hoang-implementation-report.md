# Longvita — Phần báo cáo của Hoàng (PRM393 Lab 3)

Ngày lập: 04/11/2026 | Cập nhật: 09/11/2026 | Trạng thái: bản thảo kỹ thuật đã kiểm thử lại trên `main`, vẫn chờ ảnh demo Android và nghiệm thu nhóm.

## 1. Phạm vi
Hoàng phụ trách dữ liệu nghiệp vụ Cloud Firestore, DataService/ViewModel, 3 user flows kế thừa Lab 2 (S01–S10), accessibility, test scripts, báo cáo và trình bày. Đăng nhập Google/Firebase Core, Profile, PDF Upload, FCM do thành viên khác phụ trách; Hoàng dùng lại contract đã chốt.

## 2. Kiến trúc và dữ liệu thật
Ứng dụng tuân thủ tầng Flutter Screen -> ViewModel (Provider) -> IDataService -> DataService -> Firebase Firestore.
Dữ liệu nghiệp vụ lấy từ users, recipes, meal_plans, shopping_lists; announcements hiển thị từ collection thật. Khi recipes rỗng, ứng dụng thể hiện Empty State và đề nghị bổ sung nội dung, không đưa dữ liệu mẫu giả dạng dữ liệu thật. Các ngoại lệ Firebase được chuyển thành DataFailure (offline/permission/not found/invalid/unknown), sau đó ViewModel xuất Loading/Empty/Error/Data.

MealPlanModel có trạng thái draft mặc định và thông tin người sở hữu. Thao tác cập nhật món trong một kế hoạch đã lưu ghi Firestore trước, cập nhật màn hình sau. Trường hợp ghi thất bại, món gốc được giữ lại và có nút Retry.

## 3. Ba luồng nghiệp vụ
### Flow 1 — Tạo kế hoạch 7 ngày (S01 -> S02 -> S03 -> S04 -> S10)
- Người dùng nhập tuổi, cân nặng, số bữa/ngày, khung giờ ăn (không dùng giá trị cá nhân hardcode).
- ViewModel kiểm tra đầu vào, đọc recipes, sinh 7 ngày và đưa sang S04.
- Tại S04, người dùng xem chi tiết từng ngày và lưu vào meal_plans theo uid; S10 tải lại từ Firestore.
- Recovery: lỗi mạng tạo/lưu -> hiển thị lỗi, Retry, Back; khi lưu lỗi vẫn giữ dữ liệu trên màn hình.

### Flow 2 — Nguyên liệu và đi chợ (S04 -> S07 -> S08)
- Tổng hợp ingredient theo tên + đơn vị, cộng số lượng qua 7 ngày.
- S07 chỉnh số lượng bằng dialog: chặn âm, 0, NaN; xóa có SnackBar Hoàn tác.
- S08 đánh dấu đã mua, lưu theo shopping_lists/{uid}/plans/{planId}; có Loading/Error/Retry. Lỗi đồng bộ hiển thị rõ, không nói đã lưu khi chưa có xác nhận.
- Session isolation: dữ liệu người A bị xóa khỏi ViewModel khi chuyển tài khoản B; hàng đợi ghi cũ không chặn người mới.

### Flow 3 — Công thức, nguồn sách, thay món (S04 -> S05 -> S06 / S09)
- S05 hiển thị tên công thức, calo, đạm, nguyên liệu, cách làm, sourceNote lấy từ Firestore.
- S09 trình bày nguồn dữ liệu mà không tự tạo số trang hoặc câu trích dẫn sách.
- S06 tìm phương án thay món theo chênh lệch calo/đạm và giới hạn hai bữa cá/tuần của thuật toán minh họa.
- Khi không có lựa chọn thay, dẫn về S02; khi cập nhật Firestore lỗi, món cũ được giữ nguyên và có Retry.

**Giới hạn học thuật:** Công thức tính dinh dưỡng trong app là ước lượng để minh họa luồng kỹ thuật, không phải tư vấn y khoa hoặc khuyến nghị cá nhân đã được chuyên gia thẩm định.

## 4. UI, Accessibility, Figma
Các màn có SafeArea, cuộn, trạng thái Loading/Empty/Error, nhãn nút và tiêu đề mô tả. Widget tests đã kiểm tra 360dp, 412dp và text scale 1x, 2x; không ghi nhận lỗi overflow ở các màn mẫu.
Figma Page 03/06 được nhóm giữ làm baseline đóng băng theo quyết định 02/11; mọi khác biệt ghi vào docs/hoang-accessibility-audit.md thay vì tự sửa Figma.

## 5. Kiểm thử đã có bằng chứng
- flutter analyze: clean sau giai đoạn triển khai đầu.
- Toàn bộ Flutter tests: 305/305 pass sau khi thêm 6 widget tests và bugfix cô lập phiên.
- Unit tests Hoàng: 8/8 pass ban đầu, sau thêm HOANG-F02 thành 9/9 pass.
- A11y & responsive widget tests bổ sung: 6/6 pass.
- Firestore Emulator rules tests trên project demo-longvita: **22/22 pass**, kiểm tra quyền owner/staff, ngăn truy cập khác UID, bảo vệ trạng thái bản nháp; chưa deploy lên Firebase thật.
- Mẫu kiểm tra thực tế: mất mạng -> Error/Retry; Firestore trống -> Empty; lưu lỗi -> giữ nguyên plan; thay món lỗi -> giữ món; số lượng âm -> dialog validation; Undo; checkbox bền vững trong fake service; cô lập phiên.

Kiểm thử trên fake service không xác nhận dữ liệu Firebase production, Google Account Picker, hay khả năng điều khiển ARTEMIS trên emulator.
ARTEMIS scripts được viết tại e2e_test/test_flows.py, test_search.py, test_detail.py nhưng chưa có run logs thực tế từ thiết bị.

## 6. Screenshots cần chèn trước khi nộp
| Hình | Trạng thái |
|---|---|
| S02 form/validation trên Android | Chưa chụp |
| S03 Error/Retry và S04 kết quả 7 ngày | Chưa chụp |
| S07 Edit dialog, Undo, S08 checklist | Chưa chụp |
| S05-S06-S09 công thức, nguồn, đổi món | Chưa chụp |
| Firebase DebugView, Firestore collection list | Chưa chụp |
| ARTEMIS raw result trên emulator | Chưa chạy |

## 7. Công tác nghiệm thu còn thiếu
1. Chấp nhận giấy phép Android SDK, cài platforms/build-tools, xác nhận thiết bị/emulator và Google Sign-In.
2. Đã xác nhận trên Firebase Console (06/11) rằng SHA-1/SHA-256 debug của laptop đã được đăng ký; `google-services.json` trong repo có thể cũ và đăng nhập thực tế vẫn cần chạy kiểm tra. Recipes vẫn phải có nguồn và số liệu được kiểm chứng. Chi tiết tại docs/hoang-android-sha.md.
3. Review/test/deploy Firestore rules cho shopping list mới, có tách quyền UID.
4. Chạy ARTEMIS >=3 lượt cho test cases chính, chụp ảnh bằng chứng; kiểm tra Firebase Analytics DebugView.
5. Xem lại Figma, TalkBack và độ tương phản thực tế.
6. Các PR #10, #15, #17 và #20 của Hoàng đã được merge vào `main`; riêng PR #20 qua CodeRabbit tại commit `7fb8c26` trước khi merge (`934b7f4`). Điều này không thay thế kiểm thử ARTEMIS, dữ liệu production hay chấp thuận của nhóm.
7. Quay video 3 user flows, cập nhật slide và báo cáo bằng ảnh thực.

### Nguồn kiểm chứng trong repository
docs/tasks/task-hoang.md; docs/design-traceability.md; docs/hoang-firestore-schema.md; docs/hoang-accessibility-audit.md; test/flows; e2e_test; git commits 0dc6253 và d078f89.

## 8. Cập nhật kiểm chứng trên `main` (09/11/2026, giờ Việt Nam)
- PR [#20](https://github.com/ruxenb/LongvitaRC/pull/20) đã **MERGED** vào `main` tại merge commit `934b7f4`. Đây là phần sửa accessibility (heading semantics), hiển thị ảnh công thức có HTTPS/no-redirect/size bound và trạng thái tải ảnh rõ ràng cho TalkBack; cả 4 nhận xét CodeRabbit đã được xử lý.
- Sau merge, `flutter test --no-pub`: **398/398 pass**; `flutter analyze --no-pub`: **0 issues**. Chạy trên Flutter 3.47.2 / Dart 3.13.2 tại máy Windows trong `D:\PRM393\LongvitaRC`. Các bài test còn dùng fake services và không phải ARTEMIS chạy trên Android.
- `python -m compileall -q e2e_test`: **pass**. Đã cài `uv 0.13.7` ở `D:\Tools\uv`, đồng bộ thành công `artemis-client` đúng commit `351ca84` cùng pytest trong virtualenv của `e2e_test`; lệnh `pytest --collect-only -q` tìm được **18 test**, exit 0. Đây chỉ là **collection**, không phải 18 test ARTEMIS đã chạy. Vẫn thiếu Android SDK platform/build-tools, thiết bị ADB và daemon ARTEMIS để có bằng chứng E2E.
- `flutter doctor -v` vẫn cảnh báo Android: chưa có `platforms`, `build-tools`, `emulator`; thư mục licenses trống và `adb devices` không có thiết bị. JDK Temurin hợp lệ nằm ở `D:\Tools\Java21\jdk-21.0.13+9`, được nạp bởi `scripts/project-env.ps1`; khi gọi SDK Manager cần dot-source script này để tránh bản Java C: bị lỗi `java.security`.
- `firebase projects:list --json` chưa xác thực được. Không sửa Firebase production, không triển khai rules, không nhập batch recipes chưa thẩm định. Việc đánh giá và quyền publish batch recipe được theo dõi tại [issue #16](https://github.com/ruxenb/LongvitaRC/issues/16).
- Không có ảnh chụp Android thực tế hay video demo 3 flows của Hoàng. Những khác biệt Figma (S02/S03/S04/S09 và các màn khác) còn cần review theo `docs/hoang-figma-deviation-audit.md`.
- Đối chiếu 26 task: **5 có bằng chứng kỹ thuật, 18 đã triển khai hoặc triển khai một phần nhưng thiếu nghiệm thu, 3 bị chặn/chưa đủ artifact**. Không xác nhận 26/26 hoàn tất. Tham khảo `docs/hoang-acceptance-audit-20261106.md` để biết yêu cầu nghiệm thu cho từng ID.


## 9. Kiểm chứng trên Android thật và monorepo (cập nhật 11/11/2026)

Phần lịch sử trước mục này ghi tình hình tới 09/11; việc thiếu Android SDK và ảnh thực tế đã được khắc phục trong ngày 11/11. Báo cáo nộp chính thức phải dẫn phiên bản mới nhất thay vì chỉ đọc các thống kê 305/398 tests cũ.

- **Môi trường thật:** Flutter 3.47.2 / Dart 3.13.2, Android SDK/NDK và Samsung Galaxy A15 SM-A155F, Android 16. Ứng dụng đã build APK debug và cài lại qua ADB thành công, giữ nguyên dữ liệu trên máy.
- **Đo kiểm lập trình:** Trên monorepo kết hợp origin/main và nhánh Hoàng, Flutter Analyze không có lỗi; bộ Mobile widget/unit tests chạy serial đạt **483/483**. Sau khi thay tiêu đề Firebase tiếng Việt, đã clean build, test lại toàn bộ và xác nhận trực tiếp trên A15.
- **Các màn hình đọc-only đã kiểm:** S01 Trang chủ, S02 Sở thích và validation thiếu dữ liệu, tra cứu công thức, S05 Chi tiết công thức, S10 Kế hoạch đã lưu và Hồ sơ. Chưa xem các màn đó là ba luồng E2E hoàn tất.
- **Dữ liệu quan sát:** ứng dụng đã trả về hai công thức trong lúc test. Nhãn nguồn sách và số ước tính USDA chưa chứng minh dữ liệu toàn bộ recipe đã được chuyên gia thẩm định.
- **Bằng chứng hình ảnh loại bỏ PII:** [Hồ sơ A15 — Tiện ích Firebase](../evidence/hoang/android-a15-20261111/profile-vietnamese-no-pii.png). Ảnh tên/email thật chỉ lưu ở D:\PRM393\Longvita_phone_evidence\20261111_clean_rebuild.
- **Giới hạn:** không tự nhận đã có 3 lượt ARTEMIS đạt cho mỗi test, đối chiếu Figma cả 10 màn, xác nhận Firebase liên vai trò bằng hai tài khoản thực, hoặc hoàn tất video demo. File evidences trên máy thành viên khác có một batch ARTEMIS 7/7 đạt, nhưng chưa đủ chuẩn >=3 lượt/ca và không thay thế live cross-role.
- **Xung đột Git:** main cục bộ đã đồng bộ origin/main tại 53d7fc5; file Git theo dõi không có trạng thái unmerged hoặc thay đổi chưa commit. PR40 và PR41 thử merge với nhau không có xung đột văn bản; cần kiểm thử chung và review lại khi merge thật.

Các ảnh chứa thông tin tài khoản cá nhân, token, UID hoặc tài liệu nội bộ chưa qua duyệt không đưa vào repo.


## 10. Bổ sung nghiệm thu thực tế và số liệu mới nhất (11/11/2026)

**Các thống kê 305/398/483 ở phần lịch sử là kết quả snapshot cũ.** Bản báo cáo hiện tại được cập nhật bằng phép kiểm thử trực tiếp Samsung A15 SM-A155F Android 16.

**Flow 1 (S01–S04 và lưu):** Đã mở S02, S03, bấm Tạo thực đơn tuần, nhận công thức có ghi chú nguồn của hệ thống trên S04. Sau khi bấm Lưu thực đơn, ứng dụng thông báo Đã lưu kế hoạch lên Firestore. Ảnh đã loại vùng nhận diện: evidence/hoang/android-a15-20261111/s02-options-no-pii.png, s03-setup-no-pii.png, s04-generated-preview-before-polish.png, firestore-save-confirmation.png. Chưa xác minh read-back S10 sau khởi động lại.

**Flow 3 (S05–S06):** Đã mở S05 từ thẻ món, quan sát nguyên liệu và hướng dẫn. S06 hiển thị Chưa có dữ liệu khi không có món thay thế, có Thử lại và Điều chỉnh sở thích. Đã kiểm chứng S06 quay về S02. Ảnh an toàn: s06-empty-and-retry.png, s06-recovery-to-s02-no-pii.png. Không tự tạo món thay thế giả.

**Inbox (HD-04):** S01 hiển thị thông báo CM-07 được mô tả là từ Web Admin. Ảnh: inbox-web-admin-notification-no-pii.png. Đây là chứng cứ đọc dữ liệu hiện có, chưa đo realtime của một thông báo mới.

**Sửa lỗi từ Android thật:** Tên món dài bị nhãn Đang chờ không đại diện trạng thái plan chen lấn ở S04, sourceNote chiếm quá nhiều dòng; S05 còn nhãn tiếng Anh và hàng nguyên liệu có chiều cao cố định. Đã sửa: bỏ nhãn không đúng nghĩa, giới hạn nguồn 2 dòng (nguồn đầy đủ tại S05), Việt hóa các nhãn Nguyên liệu, Các bước thực hiện, khẩu phần và đạm, row nguyên liệu tự giãn ở chữ 200%, sửa S02/S03/S06. Thêm hai regression widget tests cho tên dài. Bốn expectation A11y cũ được cập nhật chính xác theo ngôn ngữ mới, không bỏ assertion.

**Kiểm thử bản mới nhất:** Flutter Analyze 0 issues; Mobile Flutter Test serial 487/487 pass; build Android debug APK thành công. Sau khi USB kết nối lại, cài APK trên Galaxy A15 bằng ADB với Success, khởi chạy PID 28804, smoke logcat 0 dòng lỗi Flutter nghiêm trọng. Biên bản: docs/hoang-native-acceptance-20261111.md; logs: D:\PRM393\hoang_a15_final_*.

**Giới hạn chưa nghiệm thu:** S10 read-back sau restart, S07/S08 edit/undo/persistence native, PDF metadata trên máy, hai vai trò Web Staff→Mobile 3 lần, Firebase Analytics/Crashlytics console, ARTEMIS >=3 lượt/ca (thiếu daemon và test account), Figma 10 màn, phê duyệt nguồn/định lượng recipe, demo video đầy đủ. Không xem số test Flutter tương đương ARTEMIS và không đánh dấu task 100% khi thiếu bằng chứng.

**Slide Hoàng cập nhật:** slides/Longvita_Hoang_4_Slides_Verified_20261111.pptx, 4 trang với ảnh Android thật đã cắt PII và thống kê 487/487.

### Cập nhật nguồn trích dẫn tại màn S05

Sau kiểm tra bố cục S04, code đã giữ ghi chú nguồn trên thẻ ở tối đa hai dòng, đồng thời **hiển thị đầy đủ trường sourceNote trong S05 dưới nhãn Nguồn tham khảo**, không lược bỏ dữ liệu. Widget test kiểm tra chuỗi đầy đủ và chống tràn khi phóng chữ. Kết quả cuối chạy lại: Mobile Flutter Analyze 0 lỗi, 487/487 tests, APK debug build thành công. Việc cài lại APK của thay đổi S05 sau cùng cần ADB kết nối ổn định.


## 11. Hợp nhất main và kết quả ARTEMIS theo log mới (11/11/2026)

Trong lúc sửa S04/S05, main đã cập nhật tới 733aa7a (PR #41 merge 706ffef), và nhánh PR40 nhận main vào e4ec827. Sau khi commit thay đổi Hoàng 4aa85ff, đã merge nhánh remote mới vào local tại 4030f63. Xung đột duy nhất của lượt này là thẻ món ở mobile/lib/screens/meal_flow_screens.dart. Bản giải quyết giữ cả chỉ số kcal/đạm của PR41 và ghi chú nguồn tối đa hai dòng trên S04; S05 có toàn văn nguồn và không có nhãn Đang chờ chen vào tên món.

Kiểm thử lại chính bản ghép tại 4030f63: Mobile Flutter tests **487/487**, Core **20/20**, Web **69/69**, tổng **576/576 đạt**; Flutter Analyze 0 vấn đề trên cả ba; Python compileall e2e_test/ đạt. Đây là kiểm thử code/mock, không phải ARTEMIS hay Firestore cross-role live.

Từ evidence/artemis/raw/runs.jsonl mới trên main, có **45 bản ghi của nhóm / 15 tên test**, trong đó **11 bản ghi** thuộc test_flows.py và test_detail.py của Hoàng (8 completed, 3 failed). Không có test case Hoàng nào đạt ba completed. Trạng thái completed không mặc nhiên là pass về nội dung. Xem docs/hoang-artemis-run-audit-20261111.md để biết từng ca và yêu cầu kiểm tra lại.

Bảng 26 task Lab3 và 9 task HD đã đối chiếu theo bằng chứng thực: docs/hoang-task-matrix-20261111.md. Không tự nhận hoàn tất 100% các task còn thiếu ARTEMIS 3 lần, cross-role Web Staff live, native S10/S07/S08/PDF và phê duyệt nutritional recipe.

## 13. Nghiệm thu Android thật bổ sung trên Samsung A15 (11/11/2026)

S10 đã mở lại bản nháp 7 ngày sau cài đè; S04 hiển thị đúng dữ liệu thực đơn có nguồn; S05 toàn văn nguồn; S07 chặn input 0, cho lưu 1360→1361g, đọc lại sau điều hướng và trả về 1360g; S08 checkbox giữ sau điều hướng và trả về không đánh dấu; HD-06 tạo và mở PDF 2 trang trên Android Print Preview. 13 ảnh đã cắt PII ở evidence/hoang/android-a15-20261111/native-*.png và biên bản docs/hoang-native-acceptance-20261111.md.

Firebase Emulator Rules 22/22 đạt; recipe offline safety gates 31/31 đạt nhưng bộ staged không được publish. Chưa có ARTEMIS 3 lượt/ca, Web Staff live x3, metadata PDF và Analytics/Crashlytics đối chiếu qua Console, video ba luồng, Figma full-screen và phê duyệt nutrition. Không kết luận hoàn tất 100%.

## 14. Bổ sung S09 native và latest main (11/11/2026)

Sau khi PR42 merge, latest main 95b1c31 đã được phân tích và test lại hoàn toàn: Mobile Flutter 487/487, Core 20/20, Web 69/69, tổng 576/576 và Analyze không lỗi. Build APK debug, cài -r và mở được trên Samsung A15. Mở Dinh dưỡng → Tra cứu công thức → Chi tiết công thức → Kiến thức sách (S09): bốn nguyên tắc và nguồn web rõ; không khẳng định số trang sách hoặc giá trị dinh dưỡng đã được thẩm định y khoa. Có ảnh redacted bổ sung. Tổng 14 ảnh native mới, không chứa email/PII.

Trên app thực Firebase đang trả 2 món; commit 29 recipe catalog chưa có bằng chứng phê duyệt và seed thật vào shared Firebase. ARTEMIS x3 và luồng xét duyệt Web Staff live vẫn chưa nghiệm thu.
