# Flow 2 — UI tiếng Việt, 09/11/2026

Charlie xác nhận nhóm chốt tiếng Việt cho toàn bộ Mobile/Web Admin và giao Việt hóa riêng Flow 2 trước. Xem [quy ước chung](../../../docs/ui-language.md). Kế thừa UI/native đã kiểm tại780b175; không sửa Figma.

## Phần đã chuyển

- S07: Nguyên liệu; Nguyên liệu trong tuần; mô tả gộp trùng; Sửa; Tạo danh sách mua sắm.
- S08: Danh sách mua sắm; Sẵn sàng đi chợ; hướng dẫn đánh dấu; nhóm Rau củ/Các loại đậu/Hạt và dầu/Ngũ cốc/Cá/Gia vị/Sữa và phô mai/Khác.
- Thanh điều hướng: Trang chủ/Kế hoạch/Dinh dưỡng/Hồ sơ; routing và thứ tự cũ giữ nguyên. Shared navigation có presetVI opt-in cho các owner dùng khi migrate, không tự đổi các màn chưa Việt hóa.
- Hộp sửa, validation, loading/empty/error/retry, snackbar và Semantics dùng tiếng Việt; bỏ chữ checklist trong thông báo Flow 2. Tooltip không đọc lặp nhãn Sửa.
- Số lượng hiển thị dấu phẩy thập phân; editor nhận cả chấm/phẩy. Đơn vị nguồn đã biết chỉ dịch nhãn (cans→lon, tbsp→muỗng canh...), không đổi số lượng hoặc đơn vị lưu. Không tự dịch tên nguyên liệu hoặc taxonomy/đơn vị lạ của nguồn.
- VietnameseUi dùng Flutter SDK localizations cho controls built-in. Context menu nằm ở root Overlay nên cũng được bọc localeVI, không chỉ bọc màn/dialog.

## Dependency có chủ đích

Thêm flutter_localizations từ SDK đang dùng; SDK Flutter 3.47.6 yêu cầu intl ^0.20.3 nên ghim 0.20.3 thay 0.19.0 trong cả pubspec/lock. Chỉ 2 dependency đổi; không nâng các package hosted khác. flutter pub get --enforce-lockfile đạt. API đã đối chiếu sourceSDK và [Flutter internationalization](https://docs.flutter.dev/ui/internationalization).

## Kiểm chứng

- Targeted Flow 2/Hoang UI/VM: 34/34. Full cuối sau sửa Overlay: 467/467; analyzer lib/test sạch; APK Final debug build được.
- 8 ảnh widget 360/412 dp × cỡ chữ 1/2 dùng font thật, dữ liệu/service giả ở final/actual. Dữ liệu mẫu món Việt chỉ ở test. Có test giữ nguyên tên nguồn English/unit/category và giá trị lưu khi đổi số 1,5 → 2,5; test menu Overlay thật hiển thị Chọn tất cả, không còn Select all.
- Native APK cuối trên AVD Android 15 320×640, Firebase thật vàthực đơn QA có sẵn gồm 7 nguyên liệu. Đi Home → Plan → thực đơn → S07 → S08; Edit/Hủy, native menu Chọn tất cả, 4 nhãn điều hướng tiếng Việt, Back về Nguyên liệu/Trang chủ đạt. Không sửa số/tick/lưu dữ liệu trong lượt Việt hóa. Không deploy rules/billing/Storage.
- 4 ảnh native cuối ở native/:05 S07, 06 hộp sửa, 07 menu tiếng Việt, 08 S08. Không có email/UID/token. AVD đã về Home, giữ phiên rồi tắt. Không đổi ngôn ngữ Android/bàn phím hệ thống; không khẳng định các màn ngoài Flow 2 đã Việt hóa.

## Các lần kiểm trước bản cuối

Native lần đầu vẫn hiện Select all vì menu Overlay ngoài locale subtree; sửa contextMenuBuilder bọc VietnameseUi, thêm regression kiểm menu hiển thị và xác nhận lại APK cuối. Không giảm điều kiện kiểm. Lần cleanup cuối chờ tiêu đề S07 bịtimeout vì màn đang cuộn dưới; AppBar Nguyên liệu vẫn hiện, đã xác nhận Back và về Home. Đây là lỗi điều kiện quan sát của harness, không phải Back lỗi; log gốc/ảnh lượt đầu giữ riêng trong QA bị Git bỏ qua.

Các ảnh/rules/evidence tiếng Anh trước ở FLOW2-FINAL-20261109 là lịch sử gói UI trước quyết định ngôn ngữ; không thay bằng chứng cũ. Chưa có máy thật hoặc TalkBack giọng Việt mới; Semantics được widget test và XML native, không coi đó là kiểm giọng đọc thực tế. Code chỉ ở local, chưa push/PR/merge main. Tài liệu tiến độ/điều phối chỉ local.
