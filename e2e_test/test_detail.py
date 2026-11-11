"""Hoàng S6-6 — real ARTEMIS recipe and Vietnamese navigation checks."""

async def test_recipe_detail_book_knowledge(run_case):
    output = await run_case(
        "Open signed-in Longvita and tap 'Dinh dưỡng', opening "
        "'Tra cứu công thức'. Open the first actually returned recipe "
        "to 'Chi tiết công thức'; read its visible name and source note "
        "without making up book metadata. Scroll to "
        "'Kiến thức sách (TS. Valter Longo)' and open it (S09). "
        "Read the actual source and any missing-citation disclaimer. "
        "If there are no recipes, report the empty state and fail this case.",
        "Actual recipe source metadata in S05 and S09, no fabricated citations.",
    )
    assert "Chi tiết công thức" in str(output)
    assert "Nguồn tham khảo" in output.after("Kiến thức sách")


async def test_meal_alternatives_and_original_preserved_on_error(run_case):
    output = await run_case(
        "Open signed-in Longvita. On 'Tùy chọn' pick age group/weight, "
        "then on 'Tạo thực đơn' tap 'Tạo thực đơn tuần'. "
        "Save the actual seven-day plan on 'Thực đơn tuần' if generated. "
        "Choose a day using the horizontal 'Chọn ngày trong tuần' selector "
        "and open a meal card in 'Chi tiết công thức'. Tap 'Đổi món'. "
        "On S06, if no alternatives exist, read the empty state and tap "
        "'Điều chỉnh sở thích (S02)' to verify recovery. "
        "If alternatives exist, choose one, disconnect the network and "
        "attempt the shown 'Xác nhận: <tên món>' action. "
        "Read the save error, verify the original meal remains selected, "
        "restore the network and use 'Thử lại'. "
        "Report the actual meal name and ending screen; never invent a swap.",
        "Observed no-alternative route to S02, or failed Firestore write "
        "preserving the original meal with a real retry.",
    )
    text = str(output)
    assert ("Đổi món" in text and
            ("Điều chỉnh sở thích" in text or
             ("Không thể đổi món" in text and "Thử lại" in text)))


async def test_top_level_navigation_tabs(run_case):
    output = await run_case(
        "Open signed-in Longvita home screen. Tap 'Thực đơn' "
        "to open 'Thực đơn đã lưu', press Android Back, "
        "then tap 'Dinh dưỡng' to open 'Tra cứu công thức', press Back, "
        "and tap 'Hồ sơ' to open the profile. "
        "Report the exact heading displayed after each tap. "
        "Use Vietnamese labels visible in the current APK, not old "
        "English 'Plan', 'Nutrition', 'Profile' labels.",
        "Observed 'Thực đơn đã lưu', 'Tra cứu công thức' and 'Hồ sơ'.",
    )
    text = str(output)
    assert "Thực đơn đã lưu" in text
    assert "Tra cứu công thức" in text
    assert "Hồ sơ" in output.last
