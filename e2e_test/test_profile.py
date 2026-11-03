"""S6-7: Remote Config on Profile and opening a push from the notification shade."""
import os

import pytest


async def test_tc09_remote_config_refresh_reports_a_result(run_case):
    """TC-09. A value change also needs a Console edit: see evidence/remote-config."""
    output = await run_case(
        "Open the Longvita app signed in and open 'Hồ sơ'. Scroll to 'Remote Config', read "
        "the value of 'Số món gợi ý tối đa', and tap 'Cập nhật Remote Config' once. "
        "Within 2 seconds, read the message in the dark bar that appears at the bottom "
        "of the screen, then read the value again.",
        "The value before, the message shown, and the value after.",
    )

    # Without a Console edit the values stay the same, and the app must say so.
    assert "Không có giá trị mới" in output
    assert "Đã áp dụng giá trị mới" not in output


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

    assert "Hồ sơ" in output
    assert title in output
