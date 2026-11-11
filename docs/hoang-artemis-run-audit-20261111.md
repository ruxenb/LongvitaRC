# ARTEMIS run audit — Hoàng — 11/11/2026

Nguồn duy nhất của bảng: evidence/artemis/raw/runs.jsonl, tổng cộng 45 dòng của nhóm. Chỉ thống kê những test thuộc test_flows.py, test_search.py và test_detail.py do Hoàng phụ trách.

**Số bản ghi thuộc Hoàng:** 11 (completed: 8, failed: 3). **Không có test case nào đạt >=3 trạng thái completed.** Nhãn completed của runner là trạng thái tác vụ, không tự chứng minh assertion cuối đã pass; cần xem replay/log theo test plan.

| Test case | Tổng lần | Completed | Failed | Đủ 3 completed? |
| --- | ---: | ---: | ---: | --- |
| test_detail.py::test_meal_alternatives_and_original_preserved_on_error | 1 | 0 | 1 | Chưa |
| test_detail.py::test_recipe_detail_book_knowledge | 1 | 1 | 0 | Chưa |
| test_detail.py::test_top_level_navigation_tabs | 1 | 0 | 1 | Chưa |
| test_flows.py::test_tc02_create_seven_day_plan | 2 | 1 | 1 | Chưa |
| test_flows.py::test_tc03_generation_offline_retry | 2 | 2 | 0 | Chưa |
| test_flows.py::test_tc04_save_and_reopen_firestore_plan | 1 | 1 | 0 | Chưa |
| test_flows.py::test_tc05_edit_quantity_validation_and_undo | 2 | 2 | 0 | Chưa |
| test_flows.py::test_tc06_shopping_checklist_persists | 1 | 1 | 0 | Chưa |

Những ca chưa có bản ghi: bất kỳ test_search.py nào; đây không phải bằng chứng pass. Các test Auth/Export/Profile có vài ca >=3 completed nhưng **không thay thế** yêu cầu các case Hoàng.

Các log ARTEMIS đã ghi sẵn trong Git từ nhóm; Hoàng không tự tạo thêm run để cải thiện chỉ số. Một số replay chứa thông tin tài khoản đã redacted trong nguồn; bảng chỉ trích dẫn tên test và số lần, không sao chép replay hay PII.

**Điều kiện hoàn tất:** Có daemon, tài khoản test và môi trường phù hợp; chạy đủ >=3 mỗi test case, kiểm tra assertion/replay thực sự đúng; lưu kết quả lần chạy, thời gian, failure root cause và pass rate có định nghĩa vào docs/test-report.md.


## Kiểm tra an toàn tài khoản khi chạy lại (11/11, sau PR #45)

Đã cập nhật **10 ca của Hoàng** (5 trong `test_flows.py`, 3 trong `test_detail.py`, 2 trong `test_search.py`) để yêu cầu marker `signed_in` trước mọi lệnh ARTEMIS. Fixture buộc cung cấp `ARTEMIS_TEST_ACCOUNT`, đối chiếu tài khoản ở Profile và đóng app trước khi bắt đầu ca thử. Mục đích: tránh tự động sinh/sửa/lưu dữ liệu bằng một tài khoản bất kỳ đang đăng nhập trên điện thoại.

- Samsung Galaxy A15 `RF8X8017T5N`: ADB báo `device`, Longvita đang chạy.
- ARTEMIS pinned runtime: dependency sync và import `artemis`, `uvicorn`, `uiautomator2` thành công.
- `python -m compileall -q e2e_test`: đạt. `pytest --collect-only -q e2e_test`: **18 tests collected**; đây không phải 18 tests passed.
- Khi chưa có cấu hình test account, `pytest -q e2e_test/test_search.py` trả **2 setup errors** `precondition: set ARTEMIS_TEST_ACCOUNT`, trước khi gọi daemon/thiết bị. Log local (không commit): `D:\PRM393\hoang_e2e_auth_precondition.log`.
- Local `e2e_test/.env` chưa có; GEMINI_API_KEY và các model API key trong cấu hình ARTEMIS chưa được cấp; cổng 8000 chưa có daemon health. **Không có lượt chạy ARTEMIS thành công mới; không thay đổi pass rate**.

Điều kiện nghiệm thu: cấu hình tài khoản kiểm thử riêng trong `.env` được Git ignore, cấp model API key chỉ ở máy local, khởi chạy ARTEMIS và xác minh `/health`, thực hiện mỗi ca ít nhất 3 lượt, xem từng replay/assertion, cập nhật kết quả thực vào `docs/test-report.md`. Thiếu điều kiện thì ghi BLOCKED, không ghi PASS.
