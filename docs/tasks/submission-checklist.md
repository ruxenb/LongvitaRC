# Checklist Nộp Bài — PRM393 Lab 3

> Bảng kiểm duyệt 14 tiêu chí đánh giá bắt buộc trích xuất từ Handout Mục 11 & Appendix để rà soát trước giờ nộp bài.  
> **Trạng thái hiện tại:** 0/14 tiêu chí hoàn thành.

---

| # | Hạng mục kiểm tra | Người phụ trách | Handout yêu cầu | Trạng thái | Ghi chú & Bằng chứng kiểm tra |
|:---:|:---|:---:|:---|:---:|:---|
| **1** | **Chủ đề và API đã được giảng viên duyệt** | Thái An | Mục 3, Mục 11: Chủ đề Lab 2 (Longvita) & nguồn dữ liệu phải có xác nhận. | ⏳ Chưa | Lưu tin nhắn/email xác nhận vào `evidence/` |
| **2** | **`design-traceability.md` & `architecture.md` viết trước khi code feature** | Thắng | Mục 4: Stage 1 và Stage 2 phải có commit trước các commit tính năng trong git log. | ⏳ Chưa | Commit stage 1, 2 trước khi code S4 |
| **3** | **Quy tắc MVVM & Design System đúng trên toàn codebase** | Thắng | Mục 5: Không SDK call trong widget; Business logic trong ViewModel/Service; State model rõ ràng; Dùng tokens/widgets dùng chung; 100% màn hình Lab 2 được truy vết. | ⏳ Chưa | Rà soát code không có `Firebase.instance` trong Widget |
| **4** | **Cả 6 dịch vụ Firebase hoạt động, xử lý failure case** | Charlie | Mục 6: Auth, Storage, FCM, Analytics, Crashlytics, Remote Config không crash khi mất mạng / từ chối quyền / hủy thao tác. | ⏳ Chưa | Thử nghiệm tắt mạng / hủy đăng nhập |
| **5** | **Storage security rules giới hạn mỗi user trong thư mục riêng** | Charlie | Mục 6: Quy tắc `reports/{uid}/...` trong `firebase/storage.rules` và đã deploy lên Firebase. | ⏳ Chưa | File `firebase/storage.rules` |
| **6** | **Analytics plan đã viết; mọi sự kiện thấy trong DebugView** | Thái An | Mục 6, 7 & Appendix A: $\ge 7$ events có parameters, không chứa PII (email, tên), có screenshot DebugView. | ⏳ Chưa | Screenshot lưu trong `evidence/analytics/` |
| **7** | **Crashlytics có non-fatal error và test crash kèm User ID, custom key** | Thái An | Mục 6: Có handled non-fatal error từ luồng thật và 1 nút test crash; có dashboard screenshot. | ⏳ Chưa | Screenshot lưu trong `evidence/crashlytics/` |
| **8** | **Ít nhất 2 giá trị Remote Config thay đổi app mà không cần rebuild** | Thái An | Mục 6: `max_meal_recommendations`, `enable_longevity_score`; có ảnh before/after và giá trị console. | ⏳ Chưa | Screenshot lưu trong `evidence/remote-config/` |
| **9** | **Test plan $\ge 10$ test cases (có error path, native interaction, exploratory)** | Thái An | Mục 7 & Appendix B: Đúng template, phủ đủ 3 flow, sign-in, export, Remote Config, sign-out. | ⏳ Chưa | File `docs/test-plan.md` |
| **10** | **Chạy ARTEMIS đủ $\ge 3$ lần mỗi test, có trace và bảng pass rate** | Thái An | Mục 7: Chạy bằng Google ARTEMIS Python SDK, ghi nhận tỉ lệ pass/fail, logcat, video replay/trace. | ⏳ Chưa | Lưu trace vào `evidence/artemis/` |
| **11** | **$\ge 5$ findings AI review có quyết định; $\ge 3$ fixes trong commit liên kết** | Thắng | Mục 8 & Appendix C: Review trên PR; $\ge 2$ loại lỗi; lý do kỹ thuật định lượng; commit ghi rõ ID finding. | ⏳ Chưa | File `docs/code-review.md` & link commit |
| **12** | **Không commit secrets (service account keys, API keys, keystores)** | Thắng | Mục 9, 11: Cho phép commit `google-services.json` Android; tuyệt đối cấm commit API secrets, keystores. | ⏳ Chưa | Quét `git log` và `.gitignore` |
| **13** | **README.md ghi rõ phiên bản pinned, AI tools đã dùng, link video demo** | Thắng | Mục 3, 9, 11: Pinned versions (Flutter, Dart, Firebase, ARTEMIS commit), danh sách AI tools, link video. | ⏳ Chưa | File `README.md` ở root |
| **14** | **Repo, report PDF, slide PDF, video link mở được ở chế độ ẩn danh** | Thắng | Access rule (Mục 10): Nếu link hỏng hoặc không có quyền xem tại thời điểm chấm, điểm = 0. | ⏳ Chưa | Mở trình duyệt ẩn danh (Incognito) test lại |

---

### Hướng Dẫn Ký Duyệt Hoàn Thành Checklist
Trước khi bấm nộp bài trên hệ thống LMS/Flm:
- **Thắng** (Lead) triệu tập cuộc họp nghiệm thu 15 phút.
- Từng thành viên báo cáo và trình chiếu bằng chứng tương ứng với mục mình phụ trách.
- Đánh dấu `[x]` vào từng mục và ghi chú link commit / đường dẫn file bằng chứng.
