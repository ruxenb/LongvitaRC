"""Deterministic checks of E2E assertions, not ARTEMIS/device runs.

Negative observations represent the false-pass risks from PR7-CR-08..11; the
account-state setup checks cover PM-S64-01..03.
No daemon, account, emulator, Console edit or network request is used here.
"""
import os
import asyncio
import sys
import json
import urllib.error
from pathlib import Path
from types import SimpleNamespace

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "e2e_test"))
import conftest as harness
import test_auth as auth_cases
import test_export as export_cases
import test_profile as profile_cases


PLACEHOLDER_ACCOUNT = "test.account@example.com"


@pytest.fixture(autouse=True)
def placeholder_account(monkeypatch):
    """Every check runs with a placeholder account, whatever the local .env says."""
    monkeypatch.setattr(harness, "TEST_ACCOUNT", PLACEHOLDER_ACCOUNT)
    # An older test_auth bound the value at import time.
    monkeypatch.setattr(auth_cases, "TEST_ACCOUNT", PLACEHOLDER_ACCOUNT, raising=False)


def observe(*steps, calls=None):
    async def run(*_args, **_kwargs):
        if calls is not None:
            calls.append(True)
        return harness.Observation(list(steps))
    return run


class FakeDevice:
    """Scripted screens for the account-state setup, with a fake clock.

    Each read of the screen returns the next set of labels; the last set
    repeats. Taps and adb commands are only recorded.
    """

    def __init__(self, monkeypatch, *screens):
        self.screens = [list(s) for s in screens]
        self.reads = 0
        self.now = 0.0
        self.commands = []
        monkeypatch.setattr(harness, "_nodes", self.nodes)
        monkeypatch.setattr(harness, "_adb", self.adb)
        monkeypatch.setattr(harness, "time", SimpleNamespace(time=self.time, sleep=self.sleep))

    def nodes(self):
        screen = self.screens[min(self.reads, len(self.screens) - 1)]
        self.reads += 1
        return [(label, (0, 0)) for label in screen]

    def adb(self, *args):
        self.commands.append(args)

    def time(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


SIGN_IN = ["Longvita", "Thực đơn trường thọ cho cả tuần", "Đăng nhập bằng Google"]
ANR = ["Google Play services isn't responding", "Close app", "Wait"]


class ProfileDevice(FakeDevice):
    """Final Home has no identity; only tapping Profile reveals its email."""

    def __init__(self, monkeypatch, account, *, home_email=None, profile_labels=None):
        self.screen = "home"
        self.home_labels = ["Longvita", "Trang chủ", "Hồ sơ", "Tạo thực đơn tuần"]
        if home_email is not None:
            self.home_labels.append(home_email)
        self.profile_labels = profile_labels if profile_labels is not None else [
            "Hồ sơ", f"Test User\n{account}\nVai trò: user", "Đăng xuất",
        ]
        super().__init__(monkeypatch, self.home_labels)

    def nodes(self):
        labels = self.home_labels if self.screen == "home" else self.profile_labels
        return [(label, (20, 40) if label == "Hồ sơ" else (0, 0)) for label in labels]

    def adb(self, *args):
        super().adb(*args)
        if args == ("shell", "input", "tap", "20", "40"):
            self.screen = "profile"

    def assert_profile_opened(self):
        assert ("shell", "input", "tap", "20", "40") in self.commands


def home(account):
    return ["Longvita Dashboard", "Hồ sơ", f"Test User\n{account}\nROLE: USER"]


def raises_setup_error(error):
    """The setup failed as setup, not as an assertion on what the agent saw."""
    assert type(error).__name__ == "SetupError", type(error).__name__
    assert "precondition" in str(error)


# PM-S64-01: being signed in is not enough; it must be the configured account.

def test_signed_in_setup_rejects_another_account(monkeypatch):
    device = ProfileDevice(monkeypatch, "someone.else@example.com")
    with pytest.raises(Exception) as caught:
        harness.ensure_signed_in()
    raises_setup_error(caught.value)
    assert "someone.else" not in str(caught.value)
    device.assert_profile_opened()


def test_signed_in_setup_accepts_the_configured_account(monkeypatch):
    device = ProfileDevice(monkeypatch, PLACEHOLDER_ACCOUNT)
    harness.ensure_signed_in()
    device.assert_profile_opened()
    assert ("shell", "am", "force-stop", harness.APP_PACKAGE) in device.commands


def test_signed_in_setup_does_not_trust_identity_on_home(monkeypatch):
    device = ProfileDevice(monkeypatch, "someone.else@example.com", home_email=PLACEHOLDER_ACCOUNT)
    with pytest.raises(harness.SetupError):
        harness.ensure_signed_in()
    device.assert_profile_opened()


def test_signed_in_setup_rejects_a_missing_profile_identity(monkeypatch):
    device = ProfileDevice(monkeypatch, "", profile_labels=["Hồ sơ", "Đăng xuất"])
    with pytest.raises(harness.SetupError):
        harness.ensure_signed_in()
    device.assert_profile_opened()


def test_signed_in_setup_rejects_an_unavailable_profile(monkeypatch):
    device = ProfileDevice(monkeypatch, PLACEHOLDER_ACCOUNT, profile_labels=ANR)
    with pytest.raises(harness.SetupError):
        harness.ensure_signed_in()
    device.assert_profile_opened()


def test_signed_in_setup_accepts_the_profile_layout_email_break(monkeypatch):
    device = ProfileDevice(monkeypatch, PLACEHOLDER_ACCOUNT.replace("@", "\u200b@"))
    harness.ensure_signed_in()
    device.assert_profile_opened()


def test_signed_in_setup_requires_an_exact_profile_email(monkeypatch):
    device = ProfileDevice(monkeypatch, "not-" + PLACEHOLDER_ACCOUNT)
    with pytest.raises(harness.SetupError):
        harness.ensure_signed_in()
    device.assert_profile_opened()


# PM-S64-02: a sign-in screen seen for a moment is not proof of signed out.

def test_sign_in_screen_that_gives_way_to_a_system_dialog_is_not_signed_out(monkeypatch):
    FakeDevice(monkeypatch, SIGN_IN, ANR)
    with pytest.raises(Exception) as caught:
        harness._open_app()
    raises_setup_error(caught.value)


def test_signed_out_setup_stops_on_a_system_dialog(monkeypatch):
    FakeDevice(monkeypatch, SIGN_IN, ANR)
    with pytest.raises(Exception) as caught:
        harness.ensure_signed_out()
    raises_setup_error(caught.value)


def test_sign_in_screen_that_stays_is_signed_out(monkeypatch):
    FakeDevice(monkeypatch, SIGN_IN)
    assert harness._open_app() == harness.SIGN_IN_BUTTON


def test_sign_in_screen_before_a_restored_session_is_signed_in(monkeypatch):
    FakeDevice(monkeypatch, SIGN_IN, SIGN_IN, home(PLACEHOLDER_ACCOUNT))
    assert harness._open_app() == "home"


# PM-S64-03: a missing account must not make a negative check pass early.

async def test_missing_account_is_a_setup_error_before_any_replay(monkeypatch):
    monkeypatch.setattr(harness, "TEST_ACCOUNT", "")
    monkeypatch.setattr(auth_cases, "TEST_ACCOUNT", "", raising=False)
    calls = []
    with pytest.raises(Exception) as caught:
        await auth_cases.test_tc01_sign_in_with_google(observe(
            "Longvita Dashboard, ROLE: USER.", calls=calls,
        ))
    raises_setup_error(caught.value)
    assert calls == []


async def test_sign_in_does_not_accept_role_seen_before_the_final_screen():
    calls = []
    with pytest.raises(AssertionError):
        await auth_cases.test_tc01_sign_in_with_google(observe(
            "Longvita Dashboard, ROLE: USER before sign-out.",
            "The account picker was cancelled; Đăng nhập bằng Google is visible.",
            calls=calls,
        ))
    # Failed on the replay, not on configuration.
    assert calls == [True]


async def test_cancel_does_not_accept_a_notice_seen_before_back():
    with pytest.raises(AssertionError):
        await auth_cases.test_tc01b_cancelled_sign_in_stays_on_sign_in(observe(
            "Old notice: đóng cửa sổ chọn tài khoản; Đăng nhập bằng Google.",
            "Press Android Back; account picker is still open.",
        ))


async def test_cancel_does_not_accept_background_as_a_back_action():
    with pytest.raises(AssertionError):
        await auth_cases.test_tc01b_cancelled_sign_in_stays_on_sign_in(observe(
            "Tapped outside; background dimmed. đóng cửa sổ chọn tài khoản; Đăng nhập bằng Google.",
        ))


async def test_sign_out_does_not_accept_background_as_a_back_action():
    with pytest.raises(AssertionError):
        await auth_cases.test_tc11_sign_out_cannot_return_with_back(observe(
            "Tap Đồng ý: background dimmed, then Đăng nhập bằng Google appears.",
        ))


def test_action_substrings_remain_available_for_tapped():
    assert harness.Observation(["Tapped Đồng ý: sign-in appears."]).after("tap", "Đồng ý")


@pytest.mark.parametrize("last", [
    "Press Android Back: Android launcher and app icons are visible.",
    "Pressed Back. Trang chủ Android (launcher) is visible.",
    "Press Android Back: Đăng nhập bằng Google remains visible.",
])
async def test_sign_out_accepts_launcher_or_sign_in(last):
    await auth_cases.test_tc11_sign_out_cannot_return_with_back(observe(
        "Tap Đồng ý: Đăng nhập bằng Google appears.", last,
    ))


@pytest.mark.parametrize("last", [
    "Press Android Back: the Longvita home screen appeared.",
    "Pressed Back. Longvita Dashboard is visible, not the launcher.",
    "Pressed Back. Trang chủ Longvita is visible, not the launcher.",
    "Press Android Back: Longvita Dashboard, ROLE: USER.",
    "Press Android Back: an unknown blank screen.",
])
async def test_sign_out_rejects_app_home_or_unknown_result(last):
    with pytest.raises(AssertionError):
        await auth_cases.test_tc11_sign_out_cannot_return_with_back(observe(
            "Tap Đồng ý: Đăng nhập bằng Google appears.", last,
        ))


def test_tc11_dashboard_marker_regression_sync():
    """Keep the critical TC-11 replay runnable without an async test plugin."""
    asyncio.run(auth_cases.test_tc11_sign_out_cannot_return_with_back(observe(
        "Tap Đồng ý: Đăng nhập bằng Google appears.",
        "Press Android Back: Android launcher and app icons are visible.",
    )))
    asyncio.run(auth_cases.test_tc11_sign_out_cannot_return_with_back(observe(
        "Tap Đồng ý: Đăng nhập bằng Google appears.",
        "Press Android Back: Đăng nhập bằng Google remains visible.",
    )))
    with pytest.raises(AssertionError):
        asyncio.run(auth_cases.test_tc11_sign_out_cannot_return_with_back(observe(
            "Tap Đồng ý: Đăng nhập bằng Google appears.",
            "Pressed Back. Longvita Dashboard is visible, not the launcher.",
        )))


async def test_viewer_heading_must_follow_open_action(monkeypatch):
    monkeypatch.setattr(export_cases, "active_window_package", lambda: export_cases.PDF_VIEWER_PACKAGE)
    with pytest.raises(AssertionError):
        await export_cases.test_tc08b_saved_pdf_opens_in_the_native_viewer(observe(
            "LONGVITA on the dashboard.",
            "Tap Mở PDF đã lưu: the viewer failed to open.",
        ))


async def test_viewer_accepts_heading_observed_after_open(monkeypatch):
    monkeypatch.setattr(export_cases, "active_window_package", lambda: export_cases.PDF_VIEWER_PACKAGE)
    await export_cases.test_tc08b_saved_pdf_opens_in_the_native_viewer(observe(
        "Tap Mở PDF đã lưu: Android print preview opens.",
        "The system print preview shows Select a printer and the printed heading 'LONGVITA — THỰC ĐƠN'.",
    ))


@pytest.mark.parametrize("last", [
    "The printed heading LONGVITA is visible, not the app name.",
    "No app name is shown, but the printed heading LONGVITA is visible.",
    "The printed heading LONGVITA is visible. The toolbar title is missing.",
])
async def test_viewer_accepts_heading_when_negation_describes_other_content(monkeypatch, last):
    monkeypatch.setattr(export_cases, "active_window_package", lambda: export_cases.PDF_VIEWER_PACKAGE)
    await export_cases.test_tc08b_saved_pdf_opens_in_the_native_viewer(observe(
        "Tap Mở PDF đã lưu: Android print preview opens.", last,
    ))


async def test_viewer_rejects_app_name_when_open_failed(monkeypatch):
    monkeypatch.setattr(export_cases, "active_window_package", lambda: "vn.edu.fpt.longvita")
    with pytest.raises(AssertionError):
        await export_cases.test_tc08b_saved_pdf_opens_in_the_native_viewer(observe(
            "Tap Mở PDF đã lưu: Longvita still shows Không mở được file PDF đã lưu.",
        ))


@pytest.mark.parametrize("last", [
    "Longvita app is still visible.",
    "The preview shows the heading 'A different document'.",
    "Select a printer is shown above a blank preview pane.",
    "I see Longvita mentioned in the app title, with no printed heading visible.",
    "No PDF content is visible in the system dialog.",
    "No heading LONGVITA is visible in the blank preview.",
    "The heading LONGVITA is not visible in the blank preview.",
    "Không có tiêu đề LONGVITA trong bản xem trước.",
    "The heading is not visible: LONGVITA cannot be read.",
    "The heading LONGVITA is missing from the preview.",
    "The heading LONGVITA không hiển thị trong bản xem trước.",
])
async def test_viewer_requires_a_printed_heading_in_final_observation(monkeypatch, last):
    monkeypatch.setattr(export_cases, "active_window_package", lambda: export_cases.PDF_VIEWER_PACKAGE)
    with pytest.raises(AssertionError):
        await export_cases.test_tc08b_saved_pdf_opens_in_the_native_viewer(observe(
            "Tap Mở PDF đã lưu.", last,
        ))


async def test_viewer_rejects_good_llm_description_while_app_is_still_foreground(monkeypatch):
    monkeypatch.setattr(export_cases, "active_window_package", lambda: "vn.edu.fpt.longvita")
    with pytest.raises(AssertionError):
        await export_cases.test_tc08b_saved_pdf_opens_in_the_native_viewer(observe(
            "Tap Mở PDF đã lưu: printed heading LONGVITA.",
        ))


def test_native_package_comes_from_window_root_not_agent_text(monkeypatch):
    monkeypatch.setattr(harness, "_screen_xml", lambda: '<hierarchy><node package="com.android.printspooler" text="Select a printer"><node package="com.android.systemui"/></node></hierarchy>')
    assert harness.active_window_package() == "com.android.printspooler"


def test_descendant_viewer_package_does_not_replace_app_window_owner(monkeypatch):
    monkeypatch.setattr(harness, "_screen_xml", lambda: '<hierarchy><node package="vn.edu.fpt.longvita"><node package="com.android.printspooler"/></node></hierarchy>')
    assert harness.active_window_package() == "vn.edu.fpt.longvita"


@pytest.mark.parametrize("xml", [
    '<hierarchy/>',
    '<hierarchy><node package="a"/><node package="b"/></hierarchy>',
    '<hierarchy><node><node package="com.android.printspooler"/></node></hierarchy>',
])
def test_ambiguous_or_missing_window_owner_fails_closed(monkeypatch, xml):
    monkeypatch.setattr(harness, "_screen_xml", lambda: xml)
    with pytest.raises(ValueError, match="one active window root"):
        harness.active_window_package()


async def test_viewer_accepts_recorded_single_paragraph_replay(monkeypatch):
    """Producer-compatibility check using an existing recorded TC-08b summary."""
    records = Path(__file__).resolve().parents[2] / "evidence/artemis/raw/runs.jsonl"
    raw = [json.loads(line) for line in records.read_text(encoding="utf-8").splitlines() if line.strip()]
    recorded = next(r for r in raw if r["task_id"].startswith("46f57d95"))
    monkeypatch.setattr(export_cases, "active_window_package", lambda: export_cases.PDF_VIEWER_PACKAGE)
    await export_cases.test_tc08b_saved_pdf_opens_in_the_native_viewer(observe(
        *recorded["output"].splitlines(),
    ))


VALID_URL = ("http://10.0.2.2:9199/v0/b/test-bucket/o/reports%2F"
             "abcdefghijklmnopqrstuvwx1234%2Fplan_123.pdf?alt=media&token="
             "12345678-1234-1234-1234-123456789abc")


@pytest.mark.parametrize("url", [
    "reports...", VALID_URL.replace("plan_123.pdf", "plan_123.txt"),
    VALID_URL.replace("reports%2F", "other%2F"),
])
async def test_export_rejects_truncated_or_wrong_target_url(monkeypatch, url):
    monkeypatch.setattr(export_cases, "screen_texts", lambda: [url])
    monkeypatch.setattr(export_cases, "_download", lambda _: pytest.fail("must not fetch invalid URL"))
    with pytest.raises(AssertionError):
        await export_cases.test_tc08_export_uploads_and_shows_url(observe(
            "Tap Xuất báo cáo PDF: Đã tải PDF lên Cloud Storage.",
        ))


@pytest.mark.parametrize("body,accepted", [(b"%PDF-1.5\nfixture", True), (b"<html>error</html>", False)])
async def test_export_verifies_downloaded_pdf_bytes(monkeypatch, body, accepted):
    monkeypatch.setattr(export_cases, "screen_texts", lambda: [VALID_URL])
    monkeypatch.setattr(export_cases, "_download", lambda _: body)
    call = export_cases.test_tc08_export_uploads_and_shows_url(observe(
        "Tap Xuất báo cáo PDF: Đã tải PDF lên Cloud Storage.",
    ))
    if accepted:
        await call
    else:
        with pytest.raises(AssertionError):
            await call


async def test_push_does_not_accept_profile_seen_before_tapping(monkeypatch):
    monkeypatch.setenv("FCM_TEST_TITLE", "Expected push")
    with pytest.raises(AssertionError):
        await profile_cases.test_tc10_push_opens_profile_from_the_shade(observe(
            "Hồ sơ already contains Expected push from earlier.",
            "Tap Expected push: the app did not open.",
        ))


async def test_push_accepts_profile_and_exact_title_after_tapping(monkeypatch):
    monkeypatch.setenv("FCM_TEST_TITLE", "Expected push")
    await profile_cases.test_tc10_push_opens_profile_from_the_shade(observe(
        "Tap Expected push: Hồ sơ appears and its inbox contains Expected push.",
    ))


async def test_push_rejects_tap_title_missing_from_final_inbox(monkeypatch):
    monkeypatch.setenv("FCM_TEST_TITLE", "Expected push")
    with pytest.raises(AssertionError):
        await profile_cases.test_tc10_push_opens_profile_from_the_shade(observe(
            "Tap Expected push: Hồ sơ opens.",
            "Scrolled to inbox. Only an older announcement is visible.",
        ))


async def test_unchanged_config_ignores_old_notice_before_refresh():
    with pytest.raises(AssertionError):
        await profile_cases.test_tc09_remote_config_refresh_reports_a_result(observe(
            "Old bar: Không có giá trị mới.",
            "Tap Cập nhật Remote Config: Đã áp dụng giá trị mới.",
        ))


@pytest.mark.parametrize("actual", ["5", "7"])
async def test_changed_config_requires_expected_value_on_screen(monkeypatch, actual):
    monkeypatch.setenv("RC_EXPECTED_MAX", "7")
    monkeypatch.setattr(profile_cases, "screen_texts", lambda: [f"Số món gợi ý tối đa: {actual}"])
    call = profile_cases.test_tc09b_console_change_is_applied_without_restart(observe(
        "Tap Cập nhật Remote Config: Đã áp dụng giá trị mới.",
    ))
    if actual == "7":
        await call
    else:
        with pytest.raises(AssertionError):
            await call


async def test_changed_config_is_explicitly_skipped_without_console_precondition(monkeypatch):
    monkeypatch.delenv("RC_EXPECTED_MAX", raising=False)
    with pytest.raises(pytest.skip.Exception):
        await profile_cases.test_tc09b_console_change_is_applied_without_restart(observe())


async def test_agent_output_cannot_replace_action_scoped_replay(monkeypatch, tmp_path):
    class Client:
        async def run(self, *_args, **_kwargs):
            return SimpleNamespace(task_id="fixture-task", status="completed",
                device_serial="fixture-device", turns=2, succeeded=True, error=None,
                output="LONGVITA was on Home. Tap Mở PDF đã lưu failed.")

    monkeypatch.setattr(harness, "_stop_app", lambda: None)
    monkeypatch.setattr(harness, "_step_summaries", lambda _: [
        "LONGVITA was on Home.", "Tap Mở PDF đã lưu: failed to open viewer.",
    ])
    monkeypatch.setattr(harness, "EVIDENCE_DIR", tmp_path)
    request = SimpleNamespace(node=SimpleNamespace(nodeid="assertion-fixture", get_closest_marker=lambda _: None))
    run = harness.run_case.__wrapped__(Client(), request)
    output = await run("fixture goal", "fixture expectation")
    assert "LONGVITA" not in output.after("tap", "Mở PDF đã lưu")


@pytest.mark.parametrize("replay_error", [False, True])
async def test_missing_replay_cannot_fall_back_to_final_output(monkeypatch, tmp_path, replay_error):
    class Client:
        async def run(self, *_args, **_kwargs):
            return SimpleNamespace(task_id="fixture-task", status="completed",
                device_serial="fixture-device", turns=2, succeeded=True, error=None,
                output="Tap Mở PDF đã lưu: LONGVITA.")

    def replay(_):
        if replay_error:
            raise urllib.error.URLError("replay unavailable")
        return []

    monkeypatch.setattr(harness, "_stop_app", lambda: None)
    monkeypatch.setattr(harness, "_step_summaries", replay)
    monkeypatch.setattr(harness, "EVIDENCE_DIR", tmp_path)
    request = SimpleNamespace(node=SimpleNamespace(nodeid="assertion-fixture", get_closest_marker=lambda _: None))
    run = harness.run_case.__wrapped__(Client(), request)
    with pytest.raises(AssertionError, match="no action-scoped replay observations"):
        await run("fixture goal", "fixture expectation")


# PM-S64-03 (setup phase): run the real TC-01 in a separate pytest process
# with no account. The harness is loaded fresh there and reads its settings
# from the environment: adb is a spy script and the daemon URL a closed port,
# so any device step or daemon call would show.

def test_missing_account_stops_tc01_in_setup_without_device_or_agent(pytester, monkeypatch, tmp_path):
    e2e = Path(harness.__file__).parent
    adb_log = tmp_path / "adb-calls.txt"
    if os.name == "nt":
        adb = tmp_path / "adb.bat"
        adb.write_text(f'@echo %* >> "{adb_log}"\r\n', encoding="utf-8")
    else:
        adb = tmp_path / "adb"
        adb.write_text(f'#!/bin/sh\necho "$@" >> "{adb_log}"\n', encoding="utf-8")
        adb.chmod(0o755)
    monkeypatch.setenv("ARTEMIS_TEST_ACCOUNT", "")
    monkeypatch.setenv("ADB", str(adb))
    monkeypatch.setenv("ARTEMIS_BASE_URL", "http://127.0.0.1:9")

    result = pytester.runpytest_subprocess(
        f"{e2e / 'test_auth.py'}::test_tc01_sign_in_with_google",
        f"--rootdir={e2e}", "-p", "no:cacheprovider",
    )

    result.assert_outcomes(errors=1)
    output = result.stdout.str()
    assert "SetupError" in output and "ARTEMIS_TEST_ACCOUNT" in output
    assert "NetworkError" not in output, "the daemon was contacted"
    assert not adb_log.exists(), adb_log.read_text() if adb_log.exists() else ""


def test_configured_account_lets_tc01_reach_the_daemon(pytester, monkeypatch, tmp_path):
    """Control: with an account the check passes and setup goes on to the daemon."""
    e2e = Path(harness.__file__).parent
    monkeypatch.setenv("ARTEMIS_TEST_ACCOUNT", PLACEHOLDER_ACCOUNT)
    monkeypatch.setenv("ARTEMIS_BASE_URL", "http://127.0.0.1:9")

    result = pytester.runpytest_subprocess(
        f"{e2e / 'test_auth.py'}::test_tc01_sign_in_with_google",
        f"--rootdir={e2e}", "-p", "no:cacheprovider",
    )

    result.assert_outcomes(errors=1)
    output = result.stdout.str()
    assert "NetworkError" in output
    assert "SetupError" not in output
