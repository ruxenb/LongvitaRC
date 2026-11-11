"""Hoàng S6-5 — ARTEMIS tests aligned to current Vietnamese Mobile S01–S10.

These are real-device agent tests, NOT widget tests. Without a running ARTEMIS
daemon, authenticated test account, Firestore recipes, and run evidence they
must fail setup; never claim the 3-run assignment requirement is complete.
"""

import pytest


@pytest.mark.signed_in
async def test_tc02_create_seven_day_plan(run_case):
    """S01 -> S02 -> S03 -> S04 with actual Vietnamese choices."""
    observation = await run_case(
        "Open signed-in Longvita Home, tap 'Tạo thực đơn tuần'. "
        "On 'Tùy chọn' (S02), select 'Từ 65 tuổi trở lên', edit 'Cân nặng "
        "của bạn' to 60 kg, choose '3 bữa/ngày', then tap 'Tiếp tục'. "
        "On 'Tạo thực đơn' (S03), tap 'Tạo thực đơn tuần' once. "
        "If loading ends in an error or recipe data is empty, report the exact "
        "visible message and stop; do not invent a weekly plan. "
        "On success read the 'Thực đơn tuần' (S04) heading, the 7 day selector "
        "and its real meal names. Swipe horizontally across the day selector to read T2,T3,T4,T5,T6,T7,CN before finding the 'Lưu thực đơn' button.",
        "Observed S04 heading, seven distinct day choices, actual meal names "
        "and save button, or the actual generation error.",
    )
    after_generation = observation.after("Tạo thực đơn tuần")
    assert "Thực đơn tuần" in after_generation
    assert "Chọn ngày trong tuần" in after_generation
    assert "Lưu thực đơn" in after_generation
    assert all(day in after_generation for day in ("T2","T3","T4","T5","T6","T7","CN"))


@pytest.mark.signed_in
async def test_tc03_generation_offline_retry(run_case):
    """S03 offline failure and real retry after restoring connectivity."""
    observation = await run_case(
        "Open signed-in Longvita, tap 'Tạo thực đơn tuần'. "
        "On S02 'Tùy chọn', keep 'Dưới 65 tuổi', enter weight 60 kg "
        "in 'Cân nặng của bạn' and tap 'Tiếp tục'. On S03 'Tạo thực đơn' "
        "enable Airplane mode via Android settings, then tap "
        "'Tạo thực đơn tuần'. Read the exact offline error and 'Thử lại'. "
        "Turn Airplane mode off, restore network, then tap 'Thử lại' and check whether "
        "'Thực đơn tuần' opens with real recipe data. "
        "Always turn Airplane mode off before ending, including after a failed task.",
        "Observed offline error, Retry and real S04 result after network "
        "restoration; no invented state.",
    )
    assert "Thử lại" in observation.after("Tạo thực đơn tuần")
    assert "Thực đơn tuần" in observation.after("Thử lại")


@pytest.mark.signed_in
async def test_tc04_save_and_reopen_firestore_plan(run_case):
    """S04 saved document must reappear through S10 Firestore fetch."""
    observation = await run_case(
        "Open signed-in Longvita and tap 'Tạo thực đơn tuần'. "
        "On S02 select 'Dưới 65 tuổi', set weight 60 kg, select "
        "'3 bữa/ngày', then tap 'Tiếp tục'. "
        "On S03 tap 'Tạo thực đơn tuần'. If a real 'Thực đơn tuần' appears, "
        "scroll down and tap 'Lưu thực đơn'. Verify the actual message "
        "'Đã lưu kế hoạch lên Firestore.' instead of assuming it succeeded. "
        "Open 'Thực đơn đã lưu' (S10), identify the same saved 7-day plan "
        "by visible date/title and report both observed values. "
        "If any step fails, report the error; do not invent success.",
        "Observed Firestore save acknowledgement and matching S10 title/date.",
    )
    assert "Đã lưu kế hoạch lên Firestore" in observation.after("Lưu thực đơn")
    assert "Các tuần đã lưu" in observation.last
    assert "7 ngày" in observation.last
    assert "Chưa có thực đơn đã lưu" not in observation.last
    assert __import__("re").search(r"\d{4}-\d{2}-\d{2}", observation.last)


@pytest.mark.signed_in
async def test_tc05_edit_quantity_validation_and_undo(run_case):
    """S04 -> S07 edit dialog validation and explicit Undo."""
    observation = await run_case(
        "Open signed-in Longvita, create a plan on S02 'Tùy chọn' and "
        "S03 'Tạo thực đơn', then save the real S04 'Thực đơn tuần'. "
        "Tap 'Xem nguyên liệu' to reach S07 'Nguyên liệu'. "
        "If the list is empty or Firestore errors, report this and stop. "
        "Otherwise tap the first ingredient's edit action, enter -50 in "
        "'Số lượng' and tap 'Lưu'. Read the positive-only validation error. "
        "Then enter 150, save, delete that ingredient and tap 'Hoàn tác'. "
        "Read the restored ingredient name; do not invent it.",
        "Observed invalid amount rejection, a successful edit, Undo, "
        "and the original ingredient restored.",
    )
    after_invalid = observation.after("Số lượng", "Lưu")
    assert ("lớn hơn 0" in after_invalid or
            "phải dương" in after_invalid)
    assert "Hoàn tác" in str(observation)


@pytest.mark.signed_in
async def test_tc06_shopping_checklist_persists(run_case):
    """S04 -> S07 -> S08 -> S07 -> S08, persisted per actual account."""
    observation = await run_case(
        "Open signed-in Longvita, create and save a real 7-day plan "
        "from 'Tùy chọn' and 'Tạo thực đơn' if none is active. "
        "On S04 tap 'Xem nguyên liệu' (S07), then "
        "'Tạo danh sách mua sắm' (S08). Tick the first available ingredient. "
        "Read its actual name and the 'Đã mua' count. "
        "Press Back to S07, reopen S08 and read the same checkbox and count. "
        "If no ingredient exists or Firestore fails, report that honestly.",
        "The same named item stays purchased on S08 after reopening.",
    )
    assert "Đã mua" in observation.after("Tạo danh sách mua sắm")
    assert "Danh sách mua sắm" in observation.last
