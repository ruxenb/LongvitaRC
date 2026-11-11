"""Hoàng S6-5 — real ARTEMIS search; no fabricated Firestore recipes."""

async def test_search_empty_state_and_retry(run_case):
    output = await run_case(
        "Open signed-in Longvita, tap 'Dinh dưỡng' to open "
        "'Tra cứu công thức' and wait for real Firestore results. "
        "In 'Tên món, danh mục hoặc mô tả' enter exactly "
        "'zzzx_nonexistent_longvita_recipe_20261104', tap 'Tìm kiếm', "
        "and read the actual empty state 'Chưa có công thức phù hợp' "
        "and 'Thử lại'. If it is a network error, report the network "
        "error instead of claiming zero results.",
        "Observed exact query, no-match title and Retry button.",
    )
    assert "Chưa có công thức phù hợp" in output.after("zzzx_nonexistent")
    assert "Thử lại" in output.after("zzzx_nonexistent")


async def test_search_real_recipe_and_open_details(run_case):
    output = await run_case(
        "Open signed-in Longvita, tap 'Dinh dưỡng' then "
        "'Tra cứu công thức'. Wait for real Firestore recipes. "
        "If none exist, report that and fail this case. "
        "Select the first displayed recipe and read its actual name, "
        "calories and protein; check the next screen title is "
        "'Chi tiết công thức', and that 'Nguyên liệu' is visible. "
        "Do not invent recipe names or nutrition figures.",
        "Actual 'Chi tiết công thức' and ingredients from Firestore.",
    )
    assert "Chi tiết công thức" in output.last
    assert "Nguyên liệu" in output.last
