"""S6-4: sign-in through the native Google picker, cancel and sign-out.

Precondition: the test Google account (ARTEMIS_TEST_ACCOUNT) is on the device.
Each case sets its own starting state through a marker (signed_out or
signed_in), so the cases do not depend on the order they run in.
"""

import re

import pytest

import conftest as harness

# Signs of Android's launcher in the agent's description, as opposed to the app.
LAUNCHER = re.compile(r"launcher|device'?s home screen|app icons|app drawer|\bdock\b", re.I)
# Signs that Back went back into the signed-in app.
APP_HOME = re.compile(
    r"Trang chủ|Longvita Dashboard|ROLE: USER|Hành động nhanh|Tạo thực đơn|Hồ sơ",
    re.IGNORECASE,
)


@pytest.mark.needs_account
@pytest.mark.signed_out
async def test_tc01_sign_in_with_google(run_case):
    """TC-01. The bottom navigation in the plan waits for the S01 screen."""
    # needs_account: a missing account is a setup error before any device step.
    account = harness.configured_account()
    output = await run_case(
        "Open the Longvita app; it opens on the sign-in screen. Tap 'Đăng nhập bằng "
        f"Google'. In the native Google account picker choose the account {account}, "
        "and wait for the app to leave the sign-in screen. Then wait 3 seconds and "
        "read the screen title and the role label on the home screen.",
        "The title of the screen shown after signing in, and the role text on it.",
    )

    # The screen the task ended on, not the sign-in screen it started from.
    assert "Longvita" in output.last
    assert "USER" in output.last.upper()


@pytest.mark.signed_out
async def test_tc01b_cancelled_sign_in_stays_on_sign_in(run_case):
    output = await run_case(
        "Open the Longvita app; it opens on the sign-in screen. "
        "Tap 'Đăng nhập bằng Google'. When the native account picker opens, press the "
        "Android Back button instead of choosing an account. Then wait 3 seconds for "
        "the sign-in screen to settle, and read the notice text and the button label.",
        "The notice shown after closing the picker, and the label of the sign-in button.",
    )

    after_back = output.after("back", whole_word=True)
    assert "đóng cửa sổ chọn tài khoản" in after_back
    assert "Đăng nhập bằng Google" in after_back


@pytest.mark.signed_in
async def test_tc11_sign_out_cannot_return_with_back(run_case):
    output = await run_case(
        "Open the Longvita app; it opens signed in on the home screen. Open 'Hồ sơ'. Tap 'Đăng xuất'. In the "
        "confirmation dialog tap 'Đồng ý'. When the sign-in screen shows, press the "
        "Android Back button once.",
        "Whether the sign-in screen appeared after confirming, and what is on screen "
        "after pressing Back: the launcher, the sign-in screen or the home screen.",
    )

    assert "Đăng nhập bằng Google" in output.after("tap", "Đồng ý")
    # Only the screen after Back counts. "Home screen" alone is ambiguous: it
    # may be Android's launcher or the app's own dashboard.
    after_back = output.after("back", whole_word=True)
    assert after_back, "the agent did not report pressing Back"
    assert not APP_HOME.search(after_back), after_back
    assert LAUNCHER.search(after_back) or "Đăng nhập bằng Google" in after_back, after_back
