"""Hoang S6-5 — ARTEMIS tests for S01–S10.

These tests require a running ARTEMIS daemon, signed-in Android device and
Firestore recipes. They do NOT fake the client or claim a pass before running.
run_case writes action-scoped replay evidence and fails on missing observations.
"""


async def test_tc02_create_seven_day_plan(run_case):
    """S01 -> S02 -> S03 -> S04, with user-entered preferences."""
    observation = await run_case(
        "Open Longvita signed in on the Vietnamese home screen. "
        "Tap 'Tạo thực đơn'. On S02 enter age 67 and weight 60 kg, "
        "select 3 meals/day and 12-hour eating window. Tap 'Tiếp tục'. "
        "On S03 tap 'Tạo kế hoạch' once and wait until it finishes. "
        "If it fails, report the full error text, do not pretend it worked. "
        "If it succeeds, report the exact title on S04 and the visible weekday "
        "names; scroll down to find the 'Lưu kế hoạch' button.",
        "Report the visible S04 title, weekday names and save button; "
        "report any error instead of inventing a plan.",
    )
    assert "S04" in observation.after("Tạo kế hoạch")
    assert "Thực đơn 7 ngày" in observation.after("Tạo kế hoạch")
    assert "Lưu kế hoạch" in observation.after("Tạo kế hoạch")


async def test_tc03_generation_offline_retry(run_case):
    """S03 offline error must recover without an infinite spinner."""
    observation = await run_case(
        "Open Longvita signed in, tap 'Tạo thực đơn'. Enter age 60, weight 60 "
        "kg, and continue to S03. Turn on Airplane mode using the "
        "Android quick settings or Settings -> Connections -> Airplane mode to go offline. "
        "Tap 'Tạo kế hoạch'. Wait for the loading "
        "message to disappear or a bounded timeout, read the exact error text "
        "and the 'Thử lại' button. Turn Airplane mode back off to restore network. "
        "Tap 'Thử lại' and report whether S04 appears. Always ensure Airplane mode is off before ending.",
        "Exact offline error, retry action and the screen after retry, "
        "with network restored before the end of the task.",
    )
    assert any(w in observation.after("Tạo kế hoạch") for w in ("Thử lại", "lỗi", "mạng", "offline", "Error"))
    assert "S04" in str(observation)


async def test_tc04_save_and_reopen_firestore_plan(run_case):
    """S04 -> S10 reads the plan again from Firestore, not local mock data."""
    observation = await run_case(
        "Open Longvita signed in and tap 'Tạo thực đơn'. Enter 60 years old, "
        "60 kg, keep 3 meals and a 12-hour eating window. Continue and tap "
        "'Tạo kế hoạch'. Wait for S04. Tap 'Lưu kế hoạch', check for "
        "'Đã lưu kế hoạch lên Firestore', then tap 'Kế hoạch đã lưu'. "
        "On S10, read the title of the saved plan and its date. "
        "If any step fails, report the actual error.",
        "Observed Firestore save acknowledgement and the matching S10 plan.",
    )
    assert "Đã lưu kế hoạch lên Firestore" in observation.after("Lưu kế hoạch")
    assert "S10" in observation.after("Kế hoạch đã lưu")


async def test_tc05_edit_quantity_validation_and_undo(run_case):
    """S04 -> S07 modal validation and Undo actions."""
    observation = await run_case(
        "Open Longvita signed in, create and save a 7-day plan from S02/S03/S04. "
        "Tap 'Tổng hợp nguyên liệu' or 'Xem nguyên liệu' to reach S07. If the ingredient list is "
        "empty, report this and stop, never invent an item. Otherwise tap "
        "the Edit icon on the first ingredient, enter -50 and tap 'Lưu'. "
        "Read the error 'Số lượng phải lớn hơn 0'. Change the value to "
        "150 and save; then delete that item and tap 'Hoàn tác'. "
        "Read the restored ingredient name.",
        "Observed S07 validation, successful edit, Undo action and restored item.",
    )
    assert "Số lượng phải lớn hơn 0" in str(observation)
    assert "Hoàn tác" in str(observation)


async def test_tc06_shopping_checklist_persists(run_case):
    """S04 -> S07 -> S08 -> S07 -> S08, same signed-in plan."""
    observation = await run_case(
        "Open Longvita signed in. Create and save a plan if none is active; "
        "navigate to S04, then 'Tổng hợp nguyên liệu' or 'Xem nguyên liệu' (S07), then "
        "'Tạo danh sách mua sắm' (S08). Tick the first available checkbox. "
        "Read the 'Đã mua' count. Press Android Back to S07, then open "
        "S08 again and read the checkbox and 'Đã mua' count. "
        "Do not claim persistence if Firestore reports an error.",
        "Checkbox state and purchased count before and after reopening S08.",
    )
    assert any(phrase in observation.after("Tạo danh sách mua sắm") for phrase in ("Đã mua", "đã mua"))
    assert any(s in str(observation) for s in ("S08", "mua sắm", "Shopping"))
