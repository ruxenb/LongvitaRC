# Tổng Hợp Toàn Bộ Yêu Cầu Lab 3 — PRM393 (Tài Liệu Làm Slide & Báo Cáo)

> **Căn cứ tài liệu gốc:** Handout *PRM393 — Lab 3: Cloud-Enabled Mobile App (Firebase, Google ARTEMIS, AI Code Review)* — Giảng viên: Lâm Phương (Oct 21, 2026).  
> **Mục đích:** Liệt kê đầy đủ, chính xác toàn bộ các yêu cầu kỹ thuật, tiêu chí chấm điểm và bằng chứng bắt buộc của Lab 3 làm cơ sở để thiết kế bộ slide thuyết trình (`slides/Lab03_<StudentID>_slides.pdf`) và hoàn thiện báo cáo.

---

## 1. Cơ Cấu Điểm & Quy Định Bàn Giao (Grading Rubric)

Lab 3 được chấm trên thang điểm 10, phân định rõ ràng giữa **Chất lượng sản phẩm (Product - 6 điểm)** và **Quy trình kỹ thuật (Engineering Process - 4 điểm)**:

```text
Tổng điểm: 10.0 điểm
├── 1. SẢN PHẨM HOÀN THIỆN (Product): 6.0 điểm
│   ├── Yêu cầu chức năng (Functional requirements): 2.5 điểm
│   │   ├── Luồng & Điều hướng (Flows & Navigation): 1.0 điểm
│   │   ├── Dữ liệu & Nội dung thật (Data & Content): 0.75 điểm
│   │   └── Trạng thái & Xử lý lỗi (States & Error handling): 0.75 điểm
│   ├── Tích hợp Firebase & Analytics (Firebase integration): 2.0 điểm
│   │   ├── Authentication: 0.25 điểm
│   │   ├── Cloud Storage: 0.25 điểm
│   │   ├── Cloud Messaging (FCM): 0.5 điểm
│   │   ├── Analytics: 0.5 điểm
│   │   ├── Crashlytics: 0.25 điểm
│   │   └── Remote Config: 0.25 điểm
│   ├── Kiến trúc MVVM (Architecture): 0.75 điểm
│   │   ├── Phân tách tầng (Layer separation): 0.5 điểm
│   │   └── Quản lý trạng thái (State management): 0.25 điểm
│   └── Chất lượng UI/UX (UI/UX Quality): 0.75 điểm
│       ├── Độ khớp thiết kế Lab 2 (Fidelity & Deviations): 0.5 điểm
│       └── Khả năng tiếp cận & Trải nghiệm (Usability & A11y): 0.25 điểm
│
└── 2. QUY TRÌNH KỸ THUẬT (Engineering Process): 4.0 điểm
    ├── Kiểm thử tự động E2E với Google ARTEMIS: 1.5 điểm
    │   ├── Độ bao phủ kế hoạch test (Plan & Coverage): 0.5 điểm
    │   ├── Chất lượng test case (Test quality & Assertions): 0.5 điểm
    │   └── Bằng chứng thực thi (Execution evidence & Pass rate): 0.5 điểm
    ├── AI-Assisted Code Review: 0.5 điểm
    │   ├── Phát hiện & Quyết định kỹ thuật (Findings & Decisions): 0.25 điểm
    │   └── Sửa lỗi có liên kết commit (Fixes in commits): 0.25 điểm
    └── Trình bày & Truyền thông (Presentation): 2.0 điểm
        ├── Bộ Slide thuyết trình (Presentation slides, 12–15 slide PDF): 1.0 điểm
        └── Demo Video (5–10 phút): 1.0 điểm
```

> [!IMPORTANT]
> **Quy tắc truy cập (Access Rule):** Báo cáo, Slide, Video và GitHub Repo bắt buộc phải mở được ở **chế độ ẩn danh (Incognito window)**. Nếu link hỏng hoặc không có quyền truy cập tại thời điểm chấm, điểm phần đó sẽ bị tính là 0.

---

## 2. Toàn Bộ Nội Dung Yêu Cầu Cần Đưa Lên Slide (Theo Từng Khối)

Dưới đây là chi tiết từng yêu cầu trong Handout mà bộ slide cần thể hiện để đạt điểm tối đa:

### KHỐI 1: Nghiệp Vụ & Kế Thừa Thiết Kế Lab 2 (Functional & UI/UX)
*Tương ứng Slide 2, Slide 3 trong dàn ý slide.*

1. **Thông tin đề tài & Persona:**
   - **Persona:** Tên, độ tuổi, nghề nghiệp, mục tiêu và rào cản của người dùng đại diện (ví dụ: Minh Anh, 28 tuổi).
   - **Success Criterion:** Tiêu chí thành công định lượng từ Lab 2 (ví dụ: hoàn thành thực đơn trường thọ 7 ngày trong dưới 3 phút và có danh sách mua sắm).
   - **3 User Flows:** Tóm tắt 3 luồng người dùng cốt lõi (Happy path + Alternative path).
2. **Độ bao phủ màn hình & Điều hướng:**
   - Triển khai toàn bộ các màn hình từ Final UI của Lab 2 (tối thiểu **8 màn hình**) + bổ sung 2 màn hình bắt buộc: **Sign-in** và **Profile/Firebase Demo Area**.
   - Nút **Back** hoạt động đúng và nhất quán ở mọi nơi, không có màn hình "ngõ cụt" (dead ends) hay màn hình không tới được.
3. **Đối chiếu Figma vs. App thực tế (Side-by-side):**
   - Đặt ảnh chụp màn hình Figma Lab 2 cạnh giao diện app Flutter thực tế.
   - **Ghi nhận sai lệch (Deviations):** Bắt buộc giải thích lý do kỹ thuật nếu có điểm khác biệt (ví dụ: đổi padding để đạt touch target 48dp, chỉnh màu để đạt tương phản text 4.5:1, bố cục co giãn responsive). Không được để sai lệch không có lý do.
4. **Dữ liệu thật (No Mock Data):**
   - Dữ liệu hiển thị phải là dữ liệu thật từ REST API hoặc Cloud Firestore; cấm dùng dữ liệu fix cứng (hard-coded) hoặc mock tạm bợ.
5. **Trạng thái giao diện đầy đủ (Explicit UI States):**
   - Mọi màn hình tải dữ liệu phải thể hiện đủ 4 trạng thái: **Loading** (spinner/shimmer), **Empty** (chưa có dữ liệu + nút CTA), **Error** (thông báo lỗi thân thiện + nút Thử lại - Retry), **Success** (hiển thị nội dung).

---

### KHỐI 2: Kiến Trúc Ứng Dụng & Design System in Code (Architecture)
*Tương ứng Slide 4, Slide 5 trong dàn ý slide.*

1. **Mô hình kiến trúc MVVM (Provider hoặc Riverpod):**
   - **View** (`screens/`, `widgets/`): Chỉ render giao diện và bắt sự kiện người dùng; **tuyệt đối không gọi SDK Firebase hay HTTP client trong Widget**.
   - **ViewModel** (`viewmodels/`): Giữ trạng thái màn hình (`ViewState`), xử lý logic nghiệp vụ (lọc, sắp xếp, tính toán đạm/calo), không chứa code UI.
   - **Service / Repository** (`services/`, `firebase/`): Đóng gói các cuộc gọi API và Firebase SDK sau Interface; dịch ngoại lệ thành app error rõ ràng.
   - **Dependencies chỉ hướng xuống:** View $\to$ ViewModel $\to$ Service $\to$ Backend. Tầng dưới không bao giờ import ngược tầng trên.
2. **Cơ chế tiêm phụ thuộc (Dependency Injection):**
   - Mọi Service phải được inject qua constructor vào ViewModel (đăng ký qua Provider ở root), cho phép dễ dàng thay thế bằng Fake/Mock Service khi viết test.
3. **Design System trong Code:**
   - **Design Tokens tập trung (`packages/core/lib/theme/`):** Toàn bộ màu sắc, typography, spacing và radius được chuẩn hóa từ Figma Lab 2 (Foundations v1, node 53:2 & 53:45).
   - **Bảng mã màu chuẩn của dự án (Project Color Palette cho App & Slide):**
     | Tên Token Figma / Code | Mã HEX | Vai trò trên App | Ứng dụng khi thiết kế Slide | Tương phản / Ghi chú |
     |:---|:---:|:---|:---|:---:|
     | **`bgCanvas`** | `#F6F1E7` | Nền màn hình chính (Warm Cream / Linen) | **Màu nền chính của Slide (Background)** | Tone màu ấm, tự nhiên, chống mỏi mắt |
     | **`actionPrimary`** | `#476429` | Nút bấm chính, tiêu đề thương hiệu, tab active | **Tiêu đề Slide, Header, Icon chính, Điểm nhấn thương hiệu** | Xanh ô-liu trường thọ (Longevity Olive) |
     | **`actionPressed`** | `#324E15` | Trạng thái nhấn, nút Undo, snackbar thành công | **Tiêu đề phụ, đường kẻ viền nhấn, Callout quan trọng** | Xanh rêu đậm (Dark Olive) |
     | **`textPrimary`** | `#2F3B2A` | Chữ chính (Body text, Header) | **Màu chữ chính trên Slide (Main text & Bullets)** | Tương phản cao **10.48:1** trên nền Canvas |
     | **`textSecondary`** | `#5C6B53` | Chữ phụ, caption, nhãn mô tả, metadata | **Màu chú thích ảnh, nguồn tham chiếu, subtitle** | Tương phản chuẩn **5.06:1** trên nền Canvas |
     | **`bgSurface`** | `#FFFFFF` | Nền thẻ Card, Dialog, Ô nhập liệu | **Nền thẻ nội dung (Card Container), khung ảnh evidence** | Tạo khối nổi bật trên nền Slide Canvas |
     | **`bgSelected` / `bgSoft`**| `#E4F2DA` / `#EAF8DF` | Badge gợi ý, pill tags, trạng thái được chọn | **Highlight box, Pill badge trạng thái (Pass, Done)** | Xanh nhạt tạo cảm giác an toàn, sinh thái |
     | **`bgPeach`** | `#F2DFCE` | Thẻ nguồn sách TS. Longo, banner lưu ý | **Callout Box ghi chú đặc biệt, Quote trích dẫn** | Tone màu đào ấm áp, phân biệt thẻ sách |
     | **`borderDecorative`**| `#DCCDB0` | Viền thẻ, đường ngăn cách divider | **Đường kẻ phân cách cột, viền bảng minh chứng** | Tinh tế, không gây gắt mắt |
     | **`borderControl`** | `#74796C` | Viền ô nhập liệu, checkbox | **Đường viền box nội dung kỹ thuật** | Tương phản 3.97:1 |
     | **`feedbackError`** | `#BA1A1A` | Báo lỗi, thông báo thất bại | **Màu cảnh báo, Failure Case, Bug finding, Denied** | Đỏ thẫm, cảnh báo rõ ràng |

   - **Hệ thống Font chữ chuẩn (Typography):**
     - **Fraunces (Serif hiện đại, Bold):** Dùng cho Logo thương hiệu **Longvita**, Title Slide bìa.
     - **Newsreader (Serif báo chí, Bold/Medium):** Dùng cho Tiêu đề các slide (Slide Headings: L, M, S).
     - **Quicksand (Sans-serif tròn trịa, SemiBold/Regular):** Dùng cho nội dung trình bày (Body text, Bullet points, Bảng số liệu).

   - **Reusable Components (`packages/core/lib/widgets/`):** Mỗi component Lab 2 (Button, TextField, Card, Navigation, Dialog, Loading, Empty, Error) được đóng gói thành một widget tái sử dụng kèm các trạng thái và biến thể (variants).
4. **Tiêu chuẩn Accessibility (A11y):**
   - Vùng chạm tối thiểu $48 \times 48\text{ dp}$ cho mọi nút bấm.
   - Cỡ chữ nội dung (body text) $\ge 14\text{ sp}$.
   - Tỷ lệ tương phản màu văn bản $\ge 4.5:1$, không truyền tải thông tin chỉ bằng màu sắc.
   - Đảm bảo hiển thị không bị tràn viền (RenderFlex overflow) trên màn hình kích thước $360\text{ dp}$ và $412\text{ dp}$.

---

### KHỐI 3: 6 Dịch Vụ Firebase & Xử Lý Tình Huống Lỗi (Firebase Integration)
*Tương ứng 6 slide riêng biệt từ Slide 6 đến Slide 11 trong dàn ý slide.*

> [!IMPORTANT]
> **Quy định bất biến của Handout:** Mỗi dịch vụ Firebase phải trình bày trên **1 slide riêng**, thể hiện rõ **Hành vi tối thiểu (Minimum behaviour)**, **Cách xử lý khi gặp lỗi (Failure case handling - có thông báo, không crash)** và **Ảnh chụp bằng chứng Console / App**.

| Dịch vụ Firebase | Hành vi tối thiểu bắt buộc | Cơ chế xử lý lỗi (Failure Case) | Bằng chứng bắt buộc (Evidence) |
|---|---|---|---|
| **1. Authentication** | - Đăng nhập Google Sign-In.<br/>- Điều hướng tự động theo auth state (`signed-out` $\to$ Sign-in screen, `signed-in` $\to$ Home).<br/>- Đăng xuất (Sign-out) xóa sạch dữ liệu phiên cục bộ. | Khi người dùng chủ động bấm Hủy chọn tài khoản Google (User cancels) hoặc mất mạng: ứng dụng hiển thị thông báo rõ ràng (SnackBar/Dialog), **không văng lỗi/crash**. | - Ảnh chụp màn hình 2 trạng thái App (Signed-out & Signed-in).<br/>- Ảnh chụp Firebase Console tab **Users** hiển thị danh sách người dùng. |
| **2. Cloud Storage** | - Tạo và xuất 1 file thực tế từ app (ví dụ: PDF tổng hợp thực đơn/báo cáo).<br/>- Tải file lên Storage theo đường dẫn phân quyền: `reports/{uid}/...`.<br/>- Hiển thị tiến trình upload (%) và đường link tải về (download URL). | Khi mất mạng, hết dung lượng hoặc quyền ghi bị chặn: ứng dụng thông báo lỗi tải lên và cho phép lưu trữ tạm/thử lại. | - File cấu hình `storage.rules` (chỉ cho phép user đọc/ghi thư mục của chính mình).<br/>- Ảnh chụp danh sách file trên Firebase Console / Storage Emulator. |
| **3. Cloud Messaging (FCM)** | - Tiếp nhận và xử lý push notification trên cả 3 trạng thái ứng dụng: **Foreground** (Banner trong app), **Background** (Khay hệ thống), **Terminated** (Mở app từ trạng thái đóng).<br/>- Xin quyền hiển thị thông báo runtime trên Android 13+.<br/>- Lưu trữ danh sách thông báo đã nhận trong app; chạm vào thông báo mở đúng màn hình liên quan. | Xử lý khi user từ chối quyền thông báo (Permission denied): app vẫn dùng bình thường, có thể mở trang cài đặt xin lại. Lọc tin nhắn theo `recipient_uid` tránh gửi nhầm tài khoản. | Ảnh chụp thiết bị nhận thành công tin nhắn thử nghiệm gửi từ Firebase Console ở từng trạng thái (Foreground, Background, Terminated). |
| **4. Analytics** | - Viết kế hoạch đo lường tại `docs/analytics-plan.md` với **tối thiểu 7 sự kiện**.<br/>- Bao phủ: sign-in, sign-out, tìm kiếm/hành động chính, xem chi tiết món ăn, xuất file.<br/>- Sử dụng tên chuẩn Firebase (`login`, `search`) và `snake_case` cho sự kiện tự tạo.<br/>- Parameters có kiểu dữ liệu rõ ràng, gắn liền câu hỏi sản phẩm (Product Question).<br/>- **Zero PII:** Tuyệt đối không gửi email, họ tên, plain UID.<br/>- Thiết lập User ID sau khi đăng nhập (`setUserId`). | Khi mất kết nối mạng, SDK tự động lưu đệm (cache) sự kiện và đồng bộ khi online trở lại. | Ảnh chụp màn hình Firebase Console **DebugView** thể hiện rõ dòng thời gian sự kiện, danh sách parameters và giá trị tương ứng trong phiên test thật. |
| **5. Crashlytics** | - Ghi nhận ít nhất **1 lỗi Handled Non-Fatal Error** phát sinh từ luồng nghiệp vụ thực tế (kèm stack trace, lý do).<br/>- Cung cấp **1 nút kích hoạt Test Crash** trong Firebase Demo Area để kiểm chứng.<br/>- Đính kèm User Identifier và ít nhất 1 Custom Key (ví dụ: `current_flow`, `current_screen`) để phân loại lỗi trên console. | Ứng dụng bắt ngoại lệ an toàn qua khối try-catch, ghi log lên Crashlytics và hiển thị Error State cho người dùng mà không bị sập app. | Ảnh chụp **Crashlytics Dashboard** trên Firebase Console thể hiện cả crash nghiêm trọng và handled non-fatal error kèm custom keys. |
| **6. Remote Config** | - Cấu hình ít nhất **2 tham số** làm thay đổi hành vi/giao diện nhìn thấy được (ví dụ: số món gợi ý tối đa, cờ bật/tắt tính năng, chuỗi thông báo banner).<br/>- Thiết lập **In-App Defaults** trong mã nguồn và file `firebase/remote-config-defaults.json`.<br/>- Thay đổi giá trị trên Firebase Console làm thay đổi giao diện ứng dụng mà **không cần rebuild hay cài lại bản mới**. | Khi mất kết nối hoặc fetch lỗi: ứng dụng tự động fallback về In-App Defaults an toàn, không hiển thị màn hình trắng hay crash. | Ảnh chụp giao diện ứng dụng **Trước / Sau khi đổi giá trị (Before & After)** kèm ảnh chụp màn hình bảng thông số trên Firebase Console. |

---

### KHỐI 4: Kiểm Thử Tự Động E2E Với Google ARTEMIS (Testing)
*Tương ứng Slide 12 trong dàn ý slide.*

1. **Tổng quan về Google ARTEMIS:**
   - Công cụ kiểm thử E2E mã nguồn mở (Apache 2.0) sử dụng AI Agent điều khiển thiết bị/máy ảo Android qua lệnh ngôn ngữ tự nhiên.
   - Sử dụng mô hình multimodal (Gemini / Claude / GPT-4o), cấu hình qua Python 3.12+, `uv`, ADB.
2. **Kế hoạch kiểm thử (`docs/test-plan.md`):**
   - Danh sách tối thiểu **10 test cases** bao phủ toàn diện:
     - 3 user flows của Lab 2 (Happy path + Alternative path).
     - Luồng xác thực: Sign-in, Sign-out.
     - Luồng hành động chính: Tìm kiếm, xem chi tiết, xuất file PDF & upload.
     - Tối thiểu **1 test case cho luồng lỗi (Error Path)**: ví dụ tìm kiếm không thấy kết quả, ngắt mạng hiển thị nút retry.
     - Tối thiểu **1 test case cho tương tác native (Native Interaction)**: tương tác Google account picker, xin quyền notification, kéo thanh notification shade mở push.
   - **1 phiên kiểm thử thăm dò (Exploratory Testing Session):** Dùng Pro profile chạy tự do không theo kịch bản từ 15–30 phút và lập danh sách lỗi/vấn đề phát hiện được.
3. **Quy định kỹ thuật khi viết test:**
   - Mỗi test case được viết bằng hàm `pytest` gửi lệnh qua `ArtemisClient`.
   - **Quantitative Assertions:** Không chỉ assert `status == "SUCCESS"`, bắt buộc phải assert dựa trên giá trị có cấu trúc mà agent đọc được trên UI (số lượng item, tiêu đề màn hình, giá trị text).
   - **Quy tắc chạy $\ge 3$ lần:** Mọi test case phải chạy tối thiểu 3 lần để báo cáo tỷ lệ đạt (**pass rate**). Trường hợp không đạt 3/3 là flaky, phải điều tra nguyên nhân (do app, độ trễ timing, hay câu lệnh prompt mơ hồ) và ghi nhận cách khắc phục.
   - **Gắn nhãn `Semantics`:** Gắn nhãn trợ năng vào các widget chính (button, item list) để ARTEMIS đọc Accessibility tree nhanh và chính xác hơn.
4. **Bằng chứng kiểm thử (Evidence):**
   - Câu lệnh chạy test suite.
   - Bảng kết quả tổng hợp: Test ID, số lần chạy, Pass rate (%), thời gian trung bình.
   - File log chi tiết: Trace ID, replay log (`runs.jsonl`), ảnh chụp màn hình từng bước.

---

### KHỐI 5: Đánh Giá Mã Nguồn Với AI (AI-Assisted Code Review)
*Tương ứng Slide 13 trong dàn ý slide.*

1. **Quy trình Review:**
   - Thực hiện review trên **Pull Request (PR)** trên GitHub trước khi merge bằng công cụ AI (ví dụ: CodeRabbit, GitHub Copilot review, SonarCloud). Lưu lại raw output của công cụ.
2. **Hồ sơ ghi nhận (`docs/code-review.md`):**
   - Ghi nhận tối thiểu **5 findings thực tế** gắn liền với vị trí chính xác `file:line`.
   - Bao quát tối thiểu **2 nhóm lỗi khác nhau**: Bug, Security, Architecture (vi phạm quy tắc MVVM), Performance, Test gap, Maintainability.
3. **Quyết định kỹ thuật (Decision Record):**
   - Với mỗi finding, nêu rõ quyết định: **Accepted** (Chấp nhận sửa), **Modified** (Sửa có điều chỉnh), hoặc **Rejected** (Từ chối).
   - **Lý do kỹ thuật rõ ràng:** Căn cứ vào quy định Handout, quy tắc MVVM, số liệu đo lường cụ thể (crash, độ trễ, số lần rebuild) hoặc giới hạn thực tế (scope, API limits). Cấm đưa ra lý do cảm tính như "AI bảo thế" hoặc "Tôi không thích".
4. **Cam kết sửa lỗi (Fix Commits):**
   - Sửa chữa tối thiểu **3 findings được chấp nhận**, mỗi sửa đổi nằm trong một **commit riêng biệt có ghi rõ ID của finding** (ví dụ: `fix(auth): resolve PR7-CR-01...`) và liên kết URL commit vào bảng.
5. **Khai báo công cụ AI (AI Disclosure):**
   - Liệt kê toàn bộ các công cụ AI đã dùng trong đồ án (code generation, chat assistant, review) kèm mục đích cụ thể.

---

### KHỐI 6: Thách Thức Kỹ Thuật, Bài Học & Tổng Kết (Conclusion)
*Tương ứng Slide 14, Slide 15 trong dàn ý slide.*

1. **Challenges & Lessons Learned:**
   - Các trở ngại kỹ thuật thực tế gặp phải và cách giải quyết (ví dụ: xử lý xung đột phiên khi đổi tài khoản trên một thiết bị, độ trễ mạng gây timeout trong ARTEMIS, giới hạn quota gói miễn phí của Firebase/Gemini).
   - Bài học rút ra về kiến trúc phân tầng, quản lý trạng thái và nguyên tắc kiểm thử tự động.
2. **Tổng kết & Khai báo minh bạch:**
   - Tóm tắt kết quả hoàn thành đối chiếu với mục tiêu đề ra.
   - Bảng AI Tools Disclosure đầy đủ.
   - Liên kết truy cập: GitHub Repository, Demo Video, Báo cáo chi tiết.

---

## 3. Quy Cách Bộ Slide Thuyết Trình & Video Demo (Section 9)

### Yêu cầu bộ Slide (`slides/Lab03_<StudentID>_slides.pdf`):
- **Độ dài:** Đúng **12–15 slide**, xuất file **PDF**.
- **Tính tự giải thích:** Người xem chưa từng đọc code vẫn hiểu app làm gì và **vì sao biết nó chạy đúng**.
- **Nguyên tắc trình bày:** Mỗi slide tập trung **một thông điệp chính**, đọc nhanh được, không nhồi nhét chữ.
- **Dẫn chứng minh bạch:** Mọi tuyên bố "app chạy được / tính năng hoạt động" đều phải có ảnh chụp app, Firebase Console, DebugView, Crashlytics hoặc ARTEMIS log đi kèm chú thích rõ ràng.
- **Dẫn link thay vì copy:** Đặt link tới các file tài liệu trong `docs/` thay vì copy nội dung dài dòng.

### Yêu cầu Video Demo (5–10 phút):
- Đi tuần tự qua từng luồng theo đúng thứ tự trong `test-plan.md`:
  1. Đăng nhập Google Sign-In và điều hướng.
  2. Các luồng người dùng chính từ Lab 2 (bao gồm cả nhánh xử lý lỗi - Error path).
  3. Xuất file PDF và tải lên Firebase Storage.
  4. Nhận thông báo push notification (FCM).
  5. Đổi giá trị trên Firebase Remote Config và xem app đổi giao diện tức thì không cần rebuild.
  6. Demo kích hoạt test crash trên màn hình và mở Crashlytics Dashboard.
  7. Trình chiếu một lượt chạy test tự động ARTEMIS trên thiết bị.
  8. Trình bày một finding từ AI Code Review và commit đã sửa trong mã nguồn.
- **Chiếu Firebase Console trực tiếp** tại các bước cần chứng minh kết quả.

---

## 4. Quy Định Vấn Đáp & Tính Liêm Chính (Section 11 — Verification Review)

1. **Phiên vấn đáp nhanh (~5 phút):**
   Giảng viên có thể yêu cầu sinh viên thực hiện trực tiếp tại chỗ:
   - Chạy 1 test case ARTEMIS bất kỳ trên thiết bị.
   - Thay đổi 1 giá trị Remote Config trực tiếp trên Firebase Console và kiểm chứng app cập nhật.
   - Giải thích luồng hoạt động của 1 ViewModel bất kỳ và 1 quyết định trong AI Code Review.
2. **Tính xác thực của bằng chứng Firebase:**
   - Ảnh chụp Firebase Console bắt buộc phải thể hiện rõ **Firebase Project ID** trùng khớp với cấu hình trong `google-services.json` của ứng dụng (`longvita-8da7e`). Không chấp nhận ảnh từ project khác.
3. **Lịch sử Git (Git History):**
   - Mã nguồn phải thể hiện quá trình làm việc liên tục qua thời gian (nhiều commits trải dài qua nhiều ngày), bám theo thứ tự các giai đoạn: *Plan $\to$ Architect $\to$ Integrate $\to$ Instrument $\to$ Test $\to$ Review $\to$ Report*. Cấm việc dồn toàn bộ code vào một commit duy nhất trước giờ nộp.

---

## 5. Bảng Kiểm Duyệt Hoàn Thành Trước Khi Nộp Bài (Submission Checklist)

Đối chiếu đầy đủ 14 tiêu chí này trước khi xuất bản file slide và nộp link:

- [ ] **1. Đề tài & API:** Đúng chủ đề Lab 2 (Longvita) và nguồn dữ liệu quy định.
- [ ] **2. Thứ tự tài liệu:** `docs/design-traceability.md` và `docs/architecture.md` có commit trước khi code tính năng.
- [ ] **3. Kiến trúc MVVM & Design System:** Không gọi Firebase SDK trong Widget; logic nằm ở ViewModel/Service; dùng tokens/widgets tập trung.
- [ ] **4. 6 Dịch vụ Firebase:** Đều hoạt động và có cơ chế xử lý lỗi (mất mạng, từ chối quyền, hủy thao tác) không để app crash.
- [ ] **5. Storage Security Rules:** Phân quyền `reports/{uid}/...` chỉ cho user đọc/ghi thư mục của mình.
- [ ] **6. Analytics Plan & DebugView:** Đủ $\ge 7$ sự kiện có parameters, Zero PII, thấy luồng sự kiện trên DebugView.
- [ ] **7. Crashlytics Dashboard:** Có non-fatal error từ luồng thật, có test crash kèm User ID và custom keys.
- [ ] **8. Remote Config:** Đủ $\ge 2$ tham số đổi hành vi app không cần rebuild, có in-app defaults và ảnh Before/After.
- [ ] **9. Test Plan:** Đủ $\ge 10$ test cases bao gồm Happy path, Error path, Native interaction và Exploratory session.
- [ ] **10. ARTEMIS E2E Runs:** Mỗi test chạy $\ge 3$ lần, có bảng Pass rate, trace ID và runs log.
- [ ] **11. AI Code Review:** Đủ $\ge 5$ findings ( $\ge 2$ loại lỗi), có quyết định kỹ thuật và $\ge 3$ commit sửa lỗi có liên kết.
- [ ] **12. An toàn bảo mật (No Secrets):** Không commit API keys, service account secrets, private keystores.
- [ ] **13. README.md hoàn chỉnh:** Ghi rõ pinned versions, danh sách công cụ AI và link demo video.
- [ ] **14. Kiểm tra ẩn danh (Incognito Check):** Toàn bộ link repo, report PDF, slide PDF, video demo mở được bình thường trong cửa sổ ẩn danh.
