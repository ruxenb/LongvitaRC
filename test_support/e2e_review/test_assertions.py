"""Deterministic checks of E2E assertions, not ARTEMIS/device runs.

Negative observations represent the false-pass risks from PR7-CR-08..11.
No daemon, account, emulator, Console edit or network request is used here.
"""
import sys
import urllib.error
from pathlib import Path
from types import SimpleNamespace

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "e2e_test"))
import conftest as harness
import test_auth as auth_cases
import test_export as export_cases
import test_profile as profile_cases


def observe(*steps):
    async def run(*_args, **_kwargs):
        return harness.Observation(list(steps))
    return run


async def test_sign_in_does_not_accept_role_seen_before_the_final_screen():
    with pytest.raises(AssertionError):
        await auth_cases.test_tc01_sign_in_with_google(observe(
            "Longvita Dashboard, ROLE: USER before sign-out.",
            "The account picker was cancelled; Đăng nhập bằng Google is visible.",
        ))


async def test_cancel_does_not_accept_a_notice_seen_before_back():
    with pytest.raises(AssertionError):
        await auth_cases.test_tc01b_cancelled_sign_in_stays_on_sign_in(observe(
            "Old notice: đóng cửa sổ chọn tài khoản; Đăng nhập bằng Google.",
            "Press Android Back; account picker is still open.",
        ))


@pytest.mark.parametrize("last", [
    "Press Android Back: Android launcher and app icons are visible.",
    "Press Android Back: Đăng nhập bằng Google remains visible.",
])
async def test_sign_out_accepts_launcher_or_sign_in(last):
    await auth_cases.test_tc11_sign_out_cannot_return_with_back(observe(
        "Tap Đồng ý: Đăng nhập bằng Google appears.", last,
    ))


@pytest.mark.parametrize("last", [
    "Press Android Back: the Longvita home screen appeared.",
    "Press Android Back: Longvita Dashboard, ROLE: USER.",
    "Press Android Back: an unknown blank screen.",
])
async def test_sign_out_rejects_app_home_or_unknown_result(last):
    with pytest.raises(AssertionError):
        await auth_cases.test_tc11_sign_out_cannot_return_with_back(observe(
            "Tap Đồng ý: Đăng nhập bằng Google appears.", last,
        ))


async def test_viewer_heading_must_follow_open_action():
    with pytest.raises(AssertionError):
        await export_cases.test_tc08b_saved_pdf_opens_in_the_native_viewer(observe(
            "LONGVITA on the dashboard.",
            "Tap Mở PDF đã lưu: the viewer failed to open.",
        ))


async def test_viewer_accepts_heading_observed_after_open():
    await export_cases.test_tc08b_saved_pdf_opens_in_the_native_viewer(observe(
        "Tap Mở PDF đã lưu: Android print preview opens.",
        "VIEWER: yes\nHEADING: LONGVITA — THỰC ĐƠN",
    ))


async def test_viewer_rejects_app_name_when_open_failed():
    with pytest.raises(AssertionError):
        await export_cases.test_tc08b_saved_pdf_opens_in_the_native_viewer(observe(
            "Tap Mở PDF đã lưu: Longvita still shows Không mở được file PDF đã lưu.",
        ))


@pytest.mark.parametrize("last", [
    "VIEWER: no\nHEADING: LONGVITA",
    "VIEWER: yes\nLongvita app is still visible.",
    "VIEWER: yes\nHEADING: A different document",
    "VIEWER: yes\nVIEWER: no\nHEADING: LONGVITA",
    "HEADING: LONGVITA",
])
async def test_viewer_requires_unambiguous_success_and_pdf_heading(last):
    with pytest.raises(AssertionError):
        await export_cases.test_tc08b_saved_pdf_opens_in_the_native_viewer(observe(
            "Tap Mở PDF đã lưu.", last,
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
