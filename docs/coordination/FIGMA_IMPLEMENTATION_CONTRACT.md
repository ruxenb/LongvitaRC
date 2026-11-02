# Longvita - contract UI trong code, tham chiếu Figma Lab 2

Ngày lập: **02/11/2026**. Áp dụng cho Claude Code khi triển khai UI và Codex khi review. Đây là tiêu chí dự án, không phải kết quả visual QA đã đạt.

## 0. Quyết định hiện hành của người dùng/team - 02/11/2026

**Figma là bản thiết kế tham chiếu đã đóng băng. Từ mốc này, phát triển và cải thiện UI trực tiếp trong code dự án; không tạo/sửa frame, cập nhật prototype hay đồng bộ ngược từ code lên Figma.** Không giao task sửa Figma cho Claude, Codex hoặc teammate để xử lý khác biệt UI.

Được chủ động cải thiện UI trong phạm vi task, giữ định hướng thiết kế, flows/nghiệp vụ, accessibility và contracts liên thành viên. Khác biệt có chủ đích ghi tại `docs/design-traceability.md` hoặc báo cáo gói với lý do, ảnh actual và trạng thái review; sau khi PM/user chấp nhận, code/runtime là baseline UI hiện hành. Không yêu cầu duyệt riêng mọi chỉnh sửa reversible thông thường; thay đổi sản phẩm/nghiệp vụ/ownership vẫn theo working agreement.

Ưu tiên context/assets/reference đã lưu; không bắt đọc live Figma lại cho từng thay đổi và không chặn implementation vì thiếu node mới cho Sign-in/Profile. Nếu cần đọc tham chiếu bổ sung thì chỉ đọc, không chỉnh Figma. Báo cáo CHARLIE-UI-01 ghi Claude đã đọc Figma 02/11; Codex chưa xác nhận độc lập toàn bộ evidence đó trong lượt cập nhật chính sách này.

Quyết định này thay các yêu cầu điều phối cũ “cập nhật/đồng bộ Figma” và “mọi UI phải giống tuyệt đối Figma”. Các câu đó trong task master/handout vẫn là nội dung nguồn lịch sử, không phải lệnh thực thi hiện hành; chưa có xác nhận giảng viên thay rubric. Tiếp tục giữ mapping và deviation/evidence trong repo để truy vết.

## 1. Nguồn chuẩn và mức độ tin cậy

Figma: https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design

- Dùng frame/component/token đã lưu làm tham chiếu, ghi thời điểm/version nguồn khi có; các quyết định UI trong code đã được chấp nhận được ưu tiên cho trạng thái sản phẩm hiện hành.
- Node map bên dưới là baseline đã đọc ngày **30/10/2026**. Context/reference bổ sung của gói UI-01 ở `evidence/ui/CHARLIE-UI-01/`; không yêu cầu audit live lại để tiếp tục.
- Repo có 10 reference PNG ở `assets/figma/`, đã kiểm tra kích thước **360x800 pixels** ngày 02/11. Chúng là snapshots tham chiếu, không đại diện mọi cải tiến UI sau đó.
- Nếu các nguồn khác nhau, ghi discrepancy và quyết định áp dụng trong repo. Giải quyết bằng code/review; không sửa Figma để làm hai bản giống nhau.
- Sign-in/Profile: Hoàng phối hợp yêu cầu/layout, Charlie triển khai theo phân công S1-5/S3-4/S4-13. Có thể thống nhất bằng mô tả và preview code, không bắt tạo approved Figma node mới; skeleton chưa mặc nhiên được Accepted.

## 2. Node map để lấy đúng đầu vào

| Phần | Link node |
|---|---|
| Foundations | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=53-2 |
| Component Catalog | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=58-153 |
| Component QA 360/412 | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=58-711 |
| S01 Home | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=103-5 |
| S02 Preferences | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=103-83 |
| S03 Create Plan | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=103-125 |
| S04 Weekly Plan | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=103-160 |
| S05 Recipe | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=108-244 |
| S06 Alternatives | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=108-285 |
| S07 Ingredients | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=106-189 |
| S08 Shopping | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=106-235 |
| S09 Knowledge | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=108-332 |
| S10 Saved Plans | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=103-269 |
| Required states | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=108-360 |
| Screen QA 412 | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=111-275 |
| Prototype | https://www.figma.com/design/73GTcipwH825N7l501or8D/Longvita---UI-UX-Design?node-id=1-6 |

Map route/task hiện có trong `docs/design-traceability.md` và `docs/tasks`. Node links xác định nguồn tham chiếu, không tự giao tất cả screens cho Charlie.

## 3. Điều kiện trước code UI

1. Đọc reference/context đã lưu liên quan task và baseline code hiện hành; ghi nguồn thực sự dùng, không coi việc có URL là bằng chứng đã đọc.
2. Ưu tiên exports/context/tokens và báo cáo đã bàn giao; không bắt có kết nối Figma mới hoặc đọc lại live cho mỗi task. Không gọi công cụ ghi/sửa Figma.
3. Đối chiếu structure và hình đã có: sizes/constraints, padding/gap, alignment, typography, colors, radius/elevation, image crop, variants và states; bổ sung responsive/states trực tiếp trong code khi bản mẫu chưa đủ.
4. Lấy assets/fonts/icons nguồn thay vì tự vẽ lại hoặc thay bằng icon tương tự. Ghi tên/nguồn/license và cách bundle ổn định; screenshot renderer/test host không được âm thầm fallback font.
5. Lập intake ngắn: task/node/version, source exports, token map, component map, expected viewport/states và missing inputs. Nếu context đủ thì tiếp tục code trong task được giao, không cần xin xác nhận lặp cho việc thường lệ.

Có thể dùng exports + spec/tokens/measurements đã lưu, ghi rõ giới hạn. Chỉ có PNG thì chưa đủ khẳng định chính xác mọi metric/variant; ghi lựa chọn triển khai thực tế và kiểm chứng UI trong code. Thiếu MCP/node mới không tự tạo blocker; không gắn nhãn pixel-perfect khi chưa đo.

## 4. Quy tắc chuyển sang Flutter

- React/Tailwind output của MCP là mô tả thiết kế, không phải kiến trúc app đích. Giữ Flutter/Dart + MVVM/Provider hiện có.
- Semantic colors/TextTheme/ThemeExtension hoặc constants có tên trong `lib/theme/`; component trong `lib/widgets/`; screen ghép lại bằng components đó.
- Giữ định hướng fonts/styles (baseline Fraunces/Newsreader/Quicksand), màu olive/cream và hierarchy. Cải thiện layout/contrast/line wrapping/states trong code theo nhu cầu thực tế, dùng tokens nhất quán và ghi khác biệt có ý nghĩa để review.
- Chọn layout/constraints Flutter phù hợp. Không dựng màn hình bằng một ảnh Figma toàn màn hoặc fixed absolute positions cho mọi phần để giả đạt fidelity.
- Dùng variants/props cho component reuse; 64 variables/81 main components không đồng nghĩa cần từng ấy Dart classes.
- Figma style không phải lý do đưa business logic/SDK vào View. Không thêm fake success để navigation nhìn giống prototype.
- Dùng text/data tương đương khi so ảnh; fixtures chỉ trong test/QA host, tách khỏi data submission thật.
- Giữ loading/empty/error/dialog/disabled/pressed/selected/Undo cùng hợp đồng nghiệp vụ. Prototype timeout 1000ms không thành delay mạng giả.

## 5. Cách chụp ảnh để đối chiếu có ý nghĩa

| Thuộc tính | Cần thống nhất/ghi nhận |
|---|---|
| Viewport chuẩn | Logical 360x800; kiểm tra thêm 412x915 theo baseline, đối chiếu node QA đúng kích thước |
| Device pixels | Ghi DPR/resolution; screenshot Android physical pixels phải được chuẩn hóa có giải thích trước so ảnh logical frame |
| SafeArea/system UI | Ghi status/nav bars, insets, edge-to-edge; so cùng vùng content, không crop tùy ý để che sai layout |
| Typography | Font thực được load, weights/line height/textScale; baseline textScale 1.0, test accessibility riêng ở scale lớn |
| Nội dung | Cùng labels/recipe images/long text và state; timestamp/name dynamic khác phải được chỉ rõ, không đánh giá lệch do data thành bug layout |
| Thời điểm chụp | Fonts/images đã load, scroll position/focus/keyboard đúng trạng thái; không chụp spinner thay loaded frame |

Lưu trong `evidence/ui/<task-or-screen>/<run-id>/`: reference, actual, metadata, side-by-side hoặc overlay/diff khi hữu ích, và danh sách sai lệch. Chưa có ảnh thực thì ghi Not visually verified.

Ảnh widget/QA host chứng minh component/state trong host đó. Ảnh Android chứng minh composition runtime. Golden test hữu ích cho regression sau khi baseline đã được PM/user chấp nhận; không tạo golden từ code hiện tại rồi dùng chính nó làm proof giống Figma.

## 6. Thứ tự review visual và tiêu chí chấp nhận

1. **Bố cục lớn:** hierarchy, containers, width/height, alignment, scroll, nav/AppBar/sticky CTA.
2. **Fonts/nội dung:** family, size/weight/line height, wrap, overflow, labels/nguồn sách.
3. **Tokens/chi tiết:** colors, borders, radius, gaps/padding, image crop, icon shape/size, elevation.
4. **Trạng thái và thao tác:** loading/disabled/errors/validation, keyboard, Back/overlay, responsive 360/412 và text scaling.

Phân biệt lỗi triển khai với cải tiến có chủ đích: sửa lỗi behaviour/accessibility/layout; ghi cải tiến có lý do/ảnh hưởng/ảnh và trạng thái review trong repo. Không bắt revert cải tiến hợp lý chỉ để giống bản mẫu hoặc yêu cầu cập nhật Figma. Lỗi font/asset, thiếu component hoặc overflow không được bỏ qua vì aggregate pixel score cao; sai khác raster/antialiasing có thể ghi rõ.

Không đặt “>=95% giống” hoặc “100% pixel-perfect” tùy ý khi chưa có phương pháp đo/baseline/threshold được chốt. Mục tiêu là UI trong code dùng tốt, nhất quán, đáp ứng flows/accessibility, giải trình được khác biệt so với tham chiếu và có evidence để PM/user quyết định.

**Ready for PM review** khi có source context, token/component map, code/check outputs, reference+actual screenshots, viewport metadata và deviation list. Chỉ Codex/user review mới đề nghị/chốt Accepted theo working agreement.

## 7. Tham khảo chính thức đã đối chiếu 02/11

- Figma MCP rules: https://developers.figma.com/docs/figma-mcp-server/add-custom-rules/
- Setup cho Claude Code: https://developers.figma.com/docs/figma-mcp-server/remote-server-installation/

Các tài liệu hướng dẫn đọc context/screenshot và reuse design system; kết nối/tool access thật trong Claude vẫn cần được kiểm tra. Không cài plugin hoặc đăng nhập thay user trong lượt soạn contract này.
