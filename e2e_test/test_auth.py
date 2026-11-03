"""S6-4: sign-in through the native Google picker, cancel and sign-out.

Precondition for each test: the test Google account is on the device. Each test
states the app state it starts from and reports what it saw.
"""


async def test_tc01_sign_in_with_google(run_case):
    """TC-01. The bottom navigation in the plan waits for the S01 screen."""
    output = await run_case(
        "Open the Longvita app. If the home screen is showing, sign out first from "
        "the profile icon. On the sign-in screen tap 'Đăng nhập bằng Google'. In the "
        "native Google account picker choose the test account, and wait for the app "
        "to leave the sign-in screen. Then wait 3 seconds and read the screen title "
        "and the role label on the home screen.",
        "The title of the screen shown after signing in, and the role text on it.",
    )

    assert "Longvita" in output
    assert "USER" in output.upper()


async def test_tc01b_cancelled_sign_in_stays_on_sign_in(run_case):
    output = await run_case(
        "Open the Longvita app on the sign-in screen, signing out first if needed. "
        "Tap 'Đăng nhập bằng Google'. When the native account picker opens, press the "
        "Android Back button instead of choosing an account. Then wait 3 seconds for "
        "the sign-in screen to settle, and read the notice text and the button label.",
        "The notice shown after closing the picker, and the label of the sign-in button.",
    )

    assert "đóng cửa sổ chọn tài khoản" in output
    assert "Đăng nhập bằng Google" in output


async def test_tc11_sign_out_cannot_return_with_back(run_case):
    output = await run_case(
        "Open the Longvita app signed in, and open 'Hồ sơ'. Tap 'Đăng xuất'. In the "
        "confirmation dialog tap 'Đồng ý'. When the sign-in screen shows, press the "
        "Android Back button once.",
        "Whether the sign-in screen appeared after confirming, and what is on screen "
        "after pressing Back: the launcher, the sign-in screen or the home screen.",
    )

    assert "Đăng nhập bằng Google" in output or "sign-in" in output.lower()
    # Earlier steps show the home screen before signing out; only what is on
    # screen after Back matters: the launcher or Sign-in, never the dashboard.
    after_back = output.strip().splitlines()[-1]
    assert "Dashboard" not in after_back
    assert "home screen" in after_back.lower() or "Đăng nhập bằng Google" in after_back
