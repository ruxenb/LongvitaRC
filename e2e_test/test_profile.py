"""S6-7: Remote Config on Profile and opening a push from the notification shade."""
import os

import pytest

from conftest import screen_texts

REFRESH_GOAL = (
    "Open the Longvita app signed in and open 'Hồ sơ'. Scroll to 'Remote Config', read "
    "the value of 'Số món gợi ý tối đa', and tap 'Cập nhật Remote Config' once. "
    "When the update finishes, a dark message bar shows at the bottom of the screen "
    "for about 4 seconds. Wait 1 second and look at the bottom of the screen; if no "
    "bar is there yet, wait 1 more second and look again, up to 3 times. Read the "
    "bar's message, then read the value again."
)
REFRESH_EXPECTED = "The value before, the message shown, and the value after."


async def test_tc09_remote_config_refresh_reports_a_result(run_case):
    """TC-09, no Console edit: the app must not claim new values.

    The app shows one message for "nothing new" and for a failed fetch, because
    the Remote Config service reports both as false; this case cannot tell them
    apart. TC-09b covers a real change.
    """
    output = await run_case(REFRESH_GOAL, REFRESH_EXPECTED)

    after_tap = output.after("tap", "Cập nhật Remote Config")
    assert "Không có giá trị mới" in after_tap
    assert "Đã áp dụng giá trị mới" not in after_tap


async def test_tc09b_console_change_is_applied_without_restart(run_case):
    """TC-09, Console edit: a changed value reaches the screen after refresh.

    Before running, change max_meal_recommendations on the Remote Config Console
    (agreed with its owner), publish, and set RC_EXPECTED_MAX to the new value.
    Put the old value back afterwards.
    """
    expected = os.getenv("RC_EXPECTED_MAX")
    if not expected:
        pytest.skip("Needs a Console edit of max_meal_recommendations and RC_EXPECTED_MAX")

    output = await run_case(REFRESH_GOAL, REFRESH_EXPECTED)

    assert "Đã áp dụng giá trị mới" in output.after("tap", "Cập nhật Remote Config")
    assert f"Số món gợi ý tối đa: {expected}" in screen_texts()


@pytest.mark.keep_app
async def test_tc10_push_opens_profile_from_the_shade(run_case):
    """TC-10. Send the message from the Console first, with the app in background.

    Temporary contract agreed by the team: every tap opens the inbox on Profile.
    """
    title = os.getenv("FCM_TEST_TITLE")
    if not title:
        pytest.fail("Set FCM_TEST_TITLE to the title of the push sent from the Console")

    output = await run_case(
        "Pull down the Android notification shade. Tap the notification whose title is "
        f"'{title}'. Wait for the app to open, then scroll to the 'Thông báo' section.",
        "The title of the screen that opened, and the notification titles listed there.",
    )

    after_tap = output.after("tap", title)
    assert "Hồ sơ" in after_tap
    # The action itself names the title; only the final inbox can confirm it.
    assert title in output.last
