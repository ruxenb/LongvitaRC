# CHARLIE-UI-01 — S2-3 + S2-4: theme và common widgets

**Trạng thái đề nghị: Ready for PM review.** Chưa Accepted; Codex và Charlie review.

| Mục | Giá trị |
|---|---|
| Task IDs | S2-3 (tokens → ThemeData), S2-4 (common widgets) — owner Charlie |
| Dev | Claude Code, 02/11/2026 |
| Baseline | `ae35f07e36cab9ad4843396a1c22d72c247853ea` (= `origin/main` lúc bắt đầu) |
| Nhánh | Làm trên `feature/charlie-ui-01` (tạo từ `main`). Commit local cùng AUTH-01 trên `feature/charlie-auth-01`, chưa push |
| Thay đổi có sẵn đã giữ nguyên | Bản sửa docs của Codex (`README.md`, `docs/architecture.md`, `docs/code-review.md`, `docs/tasks/README.md`, `docs/test-plan.md`), `AGENTS.md`, `CLAUDE.md`, `docs/coordination/*`. Không đụng tới các file này |

## 1. Nguồn đã đọc

Figma `73GTcipwH825N7l501or8D`, đọc live qua Figma MCP ngày **02/11/2026, khoảng 11:30–11:45 (UTC+7)**, gồm design context và screenshot của từng node:

| Node | Nội dung |
|---|---|
| `53:2` (`53:45`, `53:72`, `53:119`) | Foundations: 8 màu, 8 text style, spacing, radius, elevation, quy tắc dùng |
| `55:111` Button, `55:59` IconButton, `55:143` TextField | Đủ variant/state |
| `56:80` Card, `56:35` Badge, `56:174`/`56:89` Navigation/NavigationItem, `56:191` AppBar | |
| `57:169` Dialog, `57:181` Loading, `57:212` Empty, `57:255` Error | |
| `56:198` DaySelector, `56:213` CheckboxRow, `57:256` Snackbar, `57:260` QuantityStepper | |
| `58:711` Responsive QA 360/412 | Mục tiêu so sánh chính |
| `61:595` | SVG spinner (arc 270°, stroke 3) để đo hình dạng |
| `56:38` | Ảnh "Meal photo / Stitch source": **chỉ dùng làm fixture QA** trong `test/qa/fixtures/` |

Docs đã đọc: `CLAUDE.md`, `AGENTS.md`, `WORKING_AGREEMENT.md`, `FIGMA_IMPLEMENTATION_CONTRACT.md`, `CHARLIE_TASK_GUIDE.md`, `CLAUDE_FIRST_TASK.md`, `docs/tasks/*`.

**Font** tải từ `github.com/google/fonts` (SIL OFL 1.1), giấy phép đi kèm `assets/fonts/*-OFL.txt`:

| File | SHA-256 |
|---|---|
| `Quicksand-Variable.ttf` (`Quicksand[wght]`) | `39c9b642…61e1cc` |
| `Newsreader-Variable.ttf` (`Newsreader[opsz,wght]`) | `8a08d13f…54d7c1` |
| `Fraunces-Variable.ttf` (`Fraunces[SOFT,WONK,opsz,wght]`) | `177ff6c0…58abbb` |

**Icon:** Figma dùng Material Icons Round; app dùng glyph `Icons.*_rounded` có sẵn trong font MaterialIcons của Flutter, không thêm asset mới.

## 2. Token → Flutter

| Figma | Flutter | Giá trị |
|---|---|---|
| color/action/primary · pressed · on-primary | `AppColors.actionPrimary` · `actionPressed` · `actionOnPrimary` | `#476429` · `#324E15` · `#FFFFFF` |
| color/bg/canvas · surface · selected · pressed · soft | `bgCanvas` · `bgSurface` · `bgSelected` · `bgPressed` · `bgSoft` | `#F6F1E7` · `#FFFFFF` · `#E4F2DA` · `#EEE6D6` · `#EAF8DF` |
| color/text/primary · secondary | `textPrimary` · `textSecondary` | `#2F3B2A` · `#5C6B53` |
| color/border/control · focus · decorative | `borderControl` · `borderFocus` · `borderDecorative` | `#74796C` · `#476429` · `#DCCDB0` |
| color/feedback/error | `feedbackError` | `#BA1A1A` |
| disabled/bg · disabled/text | `disabledBg` · `disabledText` | `#E4E2DB` · `#62685D` |
| Brand | `AppTypography.brand` | Fraunces Bold 20/28, SOFT 0, WONK 1 |
| Heading/L · Heading/M · Title | `headingL` · `headingM` · `title` | Newsreader Bold 28/36 · SemiBold 24/32 · SemiBold 20/28 |
| Body · Supporting · Label · Label/Strong | `body` · `supporting` · `label` · `labelStrong` | Quicksand Regular 16/26 · Medium 14/22 · SemiBold 14/20 · Bold 14/20 |
| space 0/4/8/12/16/24/32/48 | `AppSpacing.s0…s48` (giữ thêm `xs/sm/md/lg/xl/xxl`) | |
| size touch-min · button-height · nav-height · AppBar | `AppSizes.touchMin` · `buttonMinHeight` · `navHeight` · `appBarHeight` | 48 · 52 · 80 · 64 |
| radius 4/8/12/16/full | `AppRadius.rounded4…16`, `roundedFull` | |
| Elevation/1 · Elevation/2 | `AppElevation.level1` · `level2` | `#2F3B2A14` y1 blur3 · `#2F3B2A1F` y4 blur16 |

`AppTypography.textTheme` ánh xạ các slot Material về 8 style trên. `AppTheme.lightTheme` dựng ColorScheme cùng theme cho button, input, dialog, snackbar và app bar từ các token này.

**Alias cũ** (`primary`, `surface`, `outline`, `error`, `success`…) được giữ để code skeleton vẫn biên dịch, và đều trỏ về token Figma. Chi tiết ở mục 6.

## 3. Component → widget

Một import duy nhất: `import 'package:longvita/widgets/longvita_widgets.dart';`

| Figma | Widget | API chính / state |
|---|---|---|
| Button 55:111 | `AppButton` | `text`, `onPressed` (null → Disabled), `variant` primary/secondary/destructive (`outlined` = secondary), `icon` (trailing, tùy chọn), `isLoading` + `loadingText`. Pressed tự xử lý. Cao tối thiểu 52, có icon thì 56 |
| IconButton 55:59 | `AppIconButton` | `icon`, `semanticLabel` (bắt buộc), `onPressed`, `color`. Kích thước 48×48 |
| TextField 55:143 | `AppTextField` | `label`, `controller`, `hintText`, `unit`, `helperText`, `errorText` (thay helper và đổi viền đỏ), `enabled`, `keyboardType`, `inputFormatters`. Focus: viền 2px |
| Card 56:80 | `AppCard`, `AppMealCard`, `AppSummaryCard` | Pressed khi có `onTap`. Meal: `image` (ImageProvider từ dữ liệu), `sourceBadge`, `status`. Summary: `note` |
| Badge 56:35 | `AppBadge` | `kind` fromBook/appSuggestion/logged/pending/plantRich; `label` override được |
| Navigation 56:174 | `AppNavigationBar` | `selectedIndex`, `onDestinationSelected`. Mặc định 4 nhãn Home/Plan/Nutrition/Profile. Không tự điều hướng (router thuộc S3-6 của Thắng) |
| AppBar 56:191 | `AppTopBar` (PreferredSizeWidget) | `title` (mặc định "Longvita"), `onBack` (có thì hiện nút Back), `actions` |
| Dialog 57:169 | `AppDialog` + `.confirmation` / `.destructive` / `.error` / `.edit` | `primaryLabel`/`onPrimary` (null → disabled; EditError giữ dialog mở), `secondaryLabel`, `content` |
| Loading 57:181 | `LoadingView` | `style` spinner/skeleton, `title`, `message`, live region. `AppSpinner` dùng riêng được |
| Empty 57:212 | `EmptyView` | `icon`, `title`, `message`, `actionLabel`/`onAction` |
| Error 57:255 | `ErrorView` | `title`, `message`, `onRetry` (+ icon refresh), `backLabel`/`onBack` |
| DaySelector 56:198 | `AppDaySelector` | `day`, `date`, `selected`, `onTap` |
| CheckboxRow 56:213 | `AppCheckboxRow` | `label`, `checked`, `onChanged` (null → disabled) |
| Snackbar 57:256 | `AppSnackBarContent`, `showAppSnackBar()` | `message`, `actionLabel`, `onAction` (hành động Undo do ViewModel quyết định) |
| QuantityStepper 57:260 | `AppQuantityStepper` | `valueLabel`, `onDecrement`/`onIncrement` (null → disabled). Giới hạn giá trị do ViewModel xử lý |
| Icon/* 55:2–55:48 | `AppIcons` | 24 icon đúng tên Figma |

Không widget nào gọi SDK hoặc chứa business logic. Mọi widget tương tác đều có semantics `button`/`checked`/`selected`/`enabled` kèm tap action, và vùng chạm ≥48.

**Hướng dẫn nhanh cho Hoàng:**

- Dùng `Scaffold(appBar: AppTopBar(...), bottomNavigationBar: AppNavigationBar(...))`, nền đã là `bgCanvas`. Lề trang dùng `AppSpacing.pageMargin` (16).
- Chữ dùng `AppTypography.*` hoặc `Theme.of(context).textTheme`, màu dùng `AppColors.*`. Không hard-code màu hay cỡ chữ trong màn hình.
- Trạng thái của ViewModel ánh xạ thành `LoadingView` / `EmptyView` / `ErrorView`.
- Mẫu dùng thực tế xem ở `test/qa/component_gallery.dart`.

## 4. File thay đổi

Code của app:

- Sửa: `lib/theme/app_colors.dart`, `lib/theme/app_spacing.dart`, `lib/theme/app_theme.dart`, `lib/widgets/app_button.dart`, `lib/widgets/app_card.dart`, `lib/widgets/app_text_field.dart`, `lib/widgets/state_views.dart`.
- Mới: `lib/theme/app_typography.dart`, `lib/theme/app_icons.dart`, `lib/widgets/app_icon_button.dart`, `lib/widgets/app_badge.dart`, `lib/widgets/app_navigation_bar.dart`, `lib/widgets/app_top_bar.dart`, `lib/widgets/app_dialog.dart`, `lib/widgets/app_supporting.dart`, `lib/widgets/longvita_widgets.dart`.
- `pubspec.yaml`: khai báo 3 font family và 3 file OFL làm asset. Không thêm hay nâng package; `pubspec.lock` không đổi.
- `lib/main.dart`: thêm **1 dòng** `AppTypography.registerFontLicenses()` để giấy phép OFL hiện ở trang licences (yêu cầu của OFL khi phân phối font). Đây là file bootstrap của Thắng, nên cần Thắng xác nhận.
- Mới: `assets/fonts/` gồm 3 TTF và 3 OFL.

QA (không nằm trong bản build app): `test/qa/qa_support.dart`, `test/qa/component_gallery.dart`, `test/qa/design_system_qa_test.dart`, `test/qa/fixtures/meal_photo_stitch_source.jpg`.

Evidence: `evidence/ui/CHARLIE-UI-01/` (chi tiết ở mục 5).

## 5. Kiểm tra thực tế

| Lệnh | Kết quả | Log |
|---|---|---|
| `flutter pub get` | OK, `pubspec.lock` không đổi (`git diff pubspec.lock` rỗng) | — |
| `flutter analyze --no-pub` | `No issues found!` | `evidence/ui/CHARLIE-UI-01/run-20261102-04/flutter-analyze.log` |
| `flutter test --no-pub` (`QA_RUN_ID=run-20261102-04`) | `+25: All tests passed!` (24 test QA + 1 test AppButton cũ) | `…/run-20261102-04/flutter-test.log` |

Môi trường: Flutter 3.47.6 stable / Dart 3.13.5, Windows. **Không có Android device/emulator** (`flutter devices` chỉ thấy windows/chrome/edge).

Test spec đã kiểm tra:

- Chiều cao: button 52 (có icon 56), ô input 58, navigation 80. Dialog rộng 360 khi màn 360 (khung 328 sau lề 16). Snackbar rộng 328.
- Màu Pressed / Disabled / Loading của button. Khi Loading, button bỏ qua thao tác chạm.
- Semantics của button / checkbox / tab đã chọn đều có tap action.
- Mọi vùng chạm ≥48.
- Dialog EditError: nút chính disabled nên dialog không đóng; Cancel thì đóng.
- Snackbar: bấm Undo gọi callback rồi ẩn.
- Bố cục QA ở 360 và 412, textScale 1.0 / 1.3 / 2.0: **không overflow**.

Lỗi do self-check phát hiện và đã sửa trước khi bàn giao:

1. Semantics của các control tương tác thiếu tap action (TalkBack/ARTEMIS sẽ không bấm được). Đã thêm `Semantics.onTap`.
2. Viền của button Secondary làm nút cao 58. Đã chuyển viền sang `foregroundDecoration` cho khớp stroke vẽ vào trong của Figma (56).
3. `AppNavigationBar` giãn hết chiều cao do `alignment`. Đã bỏ.
4. Ở textScale 2.0, nhãn tab đè lên nhau. Đã thêm `FittedBox(scaleDown)`.
5. Checkbox vừa disabled vừa checked hiện ô trống. Đã đổi thành dấu check màu disabled.

### Ảnh reference / actual

- Host: widget host của `flutter_test`, chạy với font thật (Quicksand/Newsreader/Fraunces + MaterialIcons của SDK) và shadow thật (`debugDisableShadows=false`). **Không phải runtime Android.**
- DPR khi chụp: 2.0 cho bộ component và QA ở textScale 1.0; 1.0 cho ảnh textScale 1.3 và 2.0.
- Mỗi PNG có kèm `.json` ghi metadata (kích thước logic, pixelRatio, node, textScale).
- Nội dung trên ảnh là chữ mẫu của Figma.

| Reference (Figma) `evidence/ui/CHARLIE-UI-01/reference/` | Actual `evidence/ui/CHARLIE-UI-01/run-20261102-04/actual/` |
|---|---|
| `58-711-responsive-qa.png` (360 và 412) | `qa-responsive-360.png`, `qa-responsive-412.png`; scale: `qa-responsive-{360,412}-text1_3.png`, `-text2_0.png` |
| `55-111-buttons.png` | `buttons.png` |
| `55-143-text-fields.png` | `text-fields.png` |
| `56-80-cards.png` | `cards.png` |
| `56-174-navigation.png` | `navigation.png` |
| `56-191-app-bar.png` | `app-bar.png` |
| `57-169-dialogs.png` | `dialogs.png` |
| `57-181-loading.png`, `57-212-empty.png`, `57-255-error.png` | `states.png` |
| `56-35-badge.png`, `55-59-icon-button.png`, `56-198-day-selector.png`, `56-213-checkbox-row.png`, `57-256-snackbar.png`, `57-260-quantity-stepper.png` | `supporting.png` |
| `53-45-typography.png`, `53-72-metrics.png` | (đối chiếu qua token test và các ảnh trên) |

So sánh bằng mắt từng cặp:

- Bố cục, font, màu, radius, khoảng cách và wrap tiếng Việt ở QA 360/412 khớp reference.
- Chưa có diff pixel tự động, vì máy không có PIL và phương pháp hay ngưỡng chưa được chốt theo contract §6.

## 6. Khác biệt còn lại và quyết định cần PM/team

Theo quyết định của team (02/11/2026), Figma là bản tham khảo đã đóng băng. Lượt này chỉ **đọc** Figma (design context, screenshot, metadata, variables, tải asset); không tạo, sửa hay đồng bộ gì lên Figma. Các khác biệt dưới đây là lựa chọn trong code; khi được PM/Charlie chấp nhận, chúng trở thành baseline UI.

| # | Khác biệt | Lý do / ảnh hưởng | Cần quyết định |
|---|---|---|---|
| D1 | Icon refresh khi Loading là màu trắng trên nền primary/destructive; render Figma cho thấy icon tối | Icon tối trên `#476429` có tương phản thấp. Code dùng màu foreground của biến thể, giống icon ở state Default | PM/Charlie xác nhận cách làm trong code |
| D2 | Spinner và icon loading có quay (Figma là hình tĩnh) | Thể hiện trạng thái đang chạy. Ở thời điểm 0, hình dạng đúng như node `61:595` | — |
| D3 | `AppTopBar` chỉ hiện nút Back khi có `onBack` (Figma luôn vẽ Back) | Màn gốc của tab không có đích Back; tránh dead-end. Router S3-6 quyết định | Thắng/Hoàng xác nhận |
| D4 | Nhãn tab co lại (scaleDown) khi textScale lớn | Figma không có spec cho text scale lớn; tránh chữ chồng nhau | — |
| D5 | Checkbox Disabled+Checked hiện dấu check màu disabled | Figma không có variant này | — (cải thiện trong code) |
| D6 | Fraunces/Newsreader đặt `opsz` = cỡ chữ | Giả định Figma để "auto optical size"; Figma context không ghi giá trị opsz | Kiểm khi review ảnh |
| D7 | Nhãn mặc định tiếng Anh theo Figma (Back, Try again, nhãn Badge, tab Home/Plan/Nutrition/Profile, Decrease/Increase) | Mọi nhãn đều truyền vào được; chờ DEC-05 về ngôn ngữ UI | Leader chốt DEC-05 |
| D8 | Màn hiện có (`home_screen.dart`, `sign_in_screen.dart`, `auth_gate.dart`) giờ hiển thị bằng token/font mới qua alias. `displayLarge` (logo SignIn) đổi từ Inter 32 sang Newsreader Bold 28. Các màn này **chưa được visual verify** | Ngoài scope S2-4; SignIn (S3-4) và Home (Hoàng) sẽ dựng lại bằng widget mới | — |
| D9 | Package `google_fonts` không còn được import nhưng vẫn nằm trong pubspec | Không gỡ để tránh đổi lockfile ngoài scope | Thắng quyết khi dọn dependency |
| D10 | Dialog dùng scrim mặc định của Material | Component Figma không định nghĩa scrim | Đối chiếu frame `S07 / Edit Ingredient Dialog` khi Hoàng dựng màn |
| D11 | `lib/main.dart` thêm 1 dòng đăng ký license | File của Thắng | Thắng xác nhận |

**Chưa kiểm chứng:**

- Chạy trên thiết bị Android thật hoặc emulator (bao gồm TalkBack, bàn phím thật, safe area).
- So sánh với các màn S01–S10 (thuộc Hoàng).
- Diff pixel định lượng.
- Không chạy Firebase, ARTEMIS hay deploy.

## 7. Checklist acceptance (packet)

- [x] Theme bám semantic colors / fonts / spacing / radius / elevation của Figma; token tập trung ở `lib/theme/`; widget tham chiếu token.
- [x] Đủ 9 nhóm component cùng variant/state, kèm supporting components. Callback và state truyền qua props; không SDK hay business logic.
- [x] Không overflow ở 360/412 với textScale 1.0/1.3/2.0 trong QA host; vùng chạm ≥48; chữ body ≥14.
- [x] Có QA host và mẫu dùng để Hoàng dùng ngay (`test/qa/component_gallery.dart`).
- [x] Có ảnh actual cạnh reference cho QA host. Chưa có ảnh runtime Android (ghi rõ ở trên).
- [x] Không sửa file ngoài scope để che gap (ngoại lệ duy nhất là 1 dòng ở `main.dart`, D11). Không tạo evidence giả.

**Bước tiếp theo:** Codex và Charlie review diff cùng các cặp ảnh. Sau khi chốt D1/D3/D7, mình commit trên `feature/charlie-ui-01` (chỉ gồm file của gói này) để Hoàng bắt đầu dùng.
