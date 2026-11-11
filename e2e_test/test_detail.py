"""Hoang S6-6: real detail, book, alternative and top-level navigation."""

async def test_recipe_detail_book_knowledge(run_case):
    output = await run_case(
        "Open Longvita signed in. From Home tap 'Tra cứu công thức', "
        "wait until recipes load, and open the first available recipe. "
        "Read the actual S05 recipe name and 'Nguồn trong dữ liệu'. "
        "Scroll down to the bottom and tap 'Kiến thức sách (TS. Valter Longo)' or 'Kiến thức sách' to open S09, "
        "then read the source note, principles, and any disclaimer about unverified citations. "
        "If there are no recipes, report the empty state instead.",
        "Actual recipe source metadata on S05 and S09; no fabricated citations.",
    )
    assert any(m in str(output) for m in ("S09", "Kiến thức sách", "Book knowledge"))
    assert any(w in str(output) for w in ("Nguồn tham khảo", "Source", "nguồn", "Nguồn", "Kiến thức", "Longevity", "sách"))


async def test_meal_alternatives_and_original_preserved_on_error(run_case):
    output = await run_case(
        "Open Longvita signed in. Create a real 7-day plan, save it on S04, "
        "expand a day and open a meal card on S05. Tap 'Đổi món ăn' on S05. "
        "On S06, if alternatives are empty, read that message and use "
        "'Điều chỉnh sở thích (S02)' to verify the recovery route. "
        "If alternatives exist, select one, disconnect network and tap "
        "'Xác nhận thay đổi'; report the cloud error and verify the original "
        "meal remained in S04. Restore the network and Retry. "
        "Report the exact ending screen and actual meal name.",
        "Observed S06 branch: no alternatives -> S02, or cloud failure "
        "retains original and Retry succeeds after network restoration.",
    )
    text = str(output)
    assert "S06" in text
    assert ("Điều chỉnh sở thích" in text or
            ("Chưa cập nhật được món" in text and "Thử lại" in text) or
            ("Không thể đổi món" in text and "Thử lại" in text) or
            ("món gốc" in text.lower() or "original" in text.lower()))


async def test_top_level_navigation_tabs(run_case):
    output = await run_case(
        "Open Longvita while signed in. On the Home navigation bar, "
        "tap 'Plan' to open S10, press Back, then tap 'Nutrition' to open "
        "the Firestore recipe catalogue, press Back, and tap 'Profile' "
        "to open the profile screen. Read the title after each tap.",
        "Observed S10, recipe catalogue and Profile titles following tab taps.",
    )
    text = str(output)
    assert "S10" in text
    assert "Tra cứu công thức" in text
    assert "Hồ sơ" in output.last
