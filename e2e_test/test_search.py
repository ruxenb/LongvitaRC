"""Hoang S6-5: real ARTEMIS search interactions (not fake data)."""


async def test_search_empty_state_and_retry(run_case):
    output = await run_case(
        "Open Longvita while signed in. Tap 'Tra cứu công thức' from Home. "
        "Wait for Firestore to load. Find the text field labelled "
        "'Tên món, danh mục hoặc mô tả'. Enter exactly "
        "'zzzx_nonexistent_longvita_recipe_20261104', then tap the search "
        "icon or Search on the keyboard. Read the title and message on the "
        "empty-result view and locate the 'Thử lại' button. Report any "
        "network error instead of claiming empty results.",
        "Search query and actual no-match message with the Retry button.",
    )
    assert "Chưa có công thức phù hợp" in output.after("zzzx_nonexistent")
    assert "Thử lại" in output.after("zzzx_nonexistent")


async def test_search_real_recipe_and_open_details(run_case):
    output = await run_case(
        "Open Longvita signed in and tap 'Tra cứu công thức'. "
        "Wait for Firestore recipes; if none are available report the empty "
        "state and stop. Select the first displayed recipe and report its "
        "actual name, the new screen title, calories and protein. "
        "Do not invent recipe values.",
        "Actual S05 details after selecting a Firestore recipe.",
    )
    assert "S05" in output.last
    assert "Dinh dưỡng tham khảo" in output.last
