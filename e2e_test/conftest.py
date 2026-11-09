"""
Google ARTEMIS E2E configuration for the Longvita Android app (Handout Section 7).

Runs against a real ARTEMIS daemon and device. There is no fallback client: a
missing SDK, daemon or device fails the run, because a test that cannot observe
the app must never report success.

Setup: docs in README.md, section 5. Requires GEMINI_API_KEY on the daemon host.
"""
import html
import json
import os
import re
import subprocess
import time
import urllib.parse
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET
from pathlib import Path

import pytest
from artemis_client import ArtemisClient
from dotenv import load_dotenv

load_dotenv()

BASE_URL = os.getenv("ARTEMIS_BASE_URL", "http://127.0.0.1:8000")
DEVICE_SERIAL = os.getenv("ANDROID_SERIAL") or None
PROFILE = os.getenv("ARTEMIS_PROFILE", "flash")  # flash (regression) or pro (exploratory)
FLASH_MODEL = os.getenv("ARTEMIS_FLASH_MODEL", "gemini-3.5-flash-lite")
PRO_MODEL = os.getenv("ARTEMIS_PRO_MODEL", "gemini-3.8-flash")
APP_PACKAGE = os.getenv("APP_PACKAGE", "vn.edu.fpt.longvita")
ADB = os.getenv("ADB", "adb")
EVIDENCE_DIR = Path(__file__).parent.parent / "evidence" / "artemis" / "raw"


class Observation(str):
    """What the agent saw: the whole text, plus one entry per step.

    Each step summary describes one action and the screen it led to. Assert on
    the steps from the relevant action onwards, so a value seen on an earlier
    screen cannot pass a check for an action that failed later.
    """

    steps: list[str]

    def __new__(cls, steps: list[str]):
        obj = super().__new__(cls, "\n".join(steps))
        obj.steps = steps
        return obj

    @property
    def last(self) -> str:
        """The final step: the screen the task ended on."""
        return self.steps[-1] if self.steps else ""

    def after(self, *words: str, whole_word: bool = False) -> str:
        """The steps from the last one that mentions every word (any case).

        Empty when no step mentions them, so a missing action fails the check.
        Whole-word matching keeps Back distinct from background; tap callers
        retain substring matching so they also recognize tapped.
        """
        wanted = [w.lower() for w in words]
        for index in range(len(self.steps) - 1, -1, -1):
            step = self.steps[index].lower()
            if all(
                re.search(rf"(?<!\w){re.escape(w)}(?!\w)", step) is not None
                if whole_word else w in step
                for w in wanted
            ):
                return "\n".join(self.steps[index:])
        return ""


def _step_summaries(task_id: str) -> list[str]:
    """What the agent reported seeing after each step, oldest first."""
    url = f"{BASE_URL}/api/sessions/{urllib.parse.quote(task_id)}/replay_steps"
    with urllib.request.urlopen(url, timeout=30) as response:
        steps = json.load(response)
    ordered = sorted(steps, key=lambda s: s.get("step_number", 0))
    return [s["summary"] for s in ordered if (s.get("summary") or "").strip()]


@pytest.fixture
async def artemis(case_config):
    """A client whose daemon has answered, so a dead daemon fails in setup.

    Depends on case_config, so a case's configuration is checked first.
    """
    client = ArtemisClient(BASE_URL, device_serial=DEVICE_SERIAL, default_profile=PROFILE)
    await client.health()
    return client


def _adb(*args: str) -> subprocess.CompletedProcess:
    command = [ADB, *(["-s", DEVICE_SERIAL] if DEVICE_SERIAL else []), *args]
    return subprocess.run(command, check=True, capture_output=True, timeout=60)


def _screen_xml() -> str:
    """Read the current native UI hierarchy once through uiautomator.

    For values the agent's summary may shorten or misread, such as a long URL.
    ARTEMIS keeps its own UIAutomator session open for a few seconds after a
    task, and a dump made meanwhile is killed, so it is retried for a while.
    """
    for attempt in range(10):
        # A dump can exit 0 without writing (for example "could not get idle
        # state"); removing the old file first keeps a stale screen from being read.
        try:
            _adb("shell", "rm", "-f", "/sdcard/artemis-screen.xml")
            dumped = _adb("shell", "uiautomator", "dump", "/sdcard/artemis-screen.xml")
            if b"dumped to" in dumped.stdout:
                break
        except subprocess.CalledProcessError:
            pass
        if attempt == 9:
            raise RuntimeError("uiautomator could not dump the screen")
        time.sleep(2)
    return _adb("exec-out", "cat", "/sdcard/artemis-screen.xml").stdout.decode("utf-8")


def screen_texts() -> list[str]:
    """Every text and label currently exposed by Android's UI hierarchy."""
    xml = _screen_xml()
    values = re.findall(r'(?:text|content-desc)="([^"]+)"', xml)
    return [html.unescape(v) for v in values]


def active_window_package() -> str:
    """The active hierarchy's root owner; descendants can belong to other apps."""
    root = ET.fromstring(_screen_xml())
    windows = [root] if root.tag == "node" else root.findall("node")
    if len(windows) != 1 or not windows[0].get("package"):
        raise ValueError("expected one active window root with a package")
    return windows[0].attrib["package"]


def _stop_app() -> None:
    """Closes the app so a case cannot reuse what an earlier case left on screen."""
    _adb("shell", "am", "force-stop", APP_PACKAGE)


# The Google account a case signs in with, from the git-ignored e2e_test/.env.
# Required when the device has more than one account.
TEST_ACCOUNT = os.getenv("ARTEMIS_TEST_ACCOUNT", "")
SIGN_IN_BUTTON = "Đăng nhập bằng Google"
HOME_TITLES = ("Longvita", "Trang chủ", "Longvita Dashboard")


def _nodes() -> list[tuple[str, tuple[int, int]]]:
    """Each label on screen with the centre of its bounds."""
    nodes = []
    for match in re.finditer(r"<node [^>]*>", _screen_xml()):
        node = match.group(0)
        label = re.search(r' text="([^"]*)"', node).group(1) or re.search(
            r'content-desc="([^"]*)"', node).group(1)
        x1, y1, x2, y2 = map(int, re.findall(r"\d+", re.search(r'bounds="([^"]*)"', node).group(1)))
        if label:
            nodes.append((html.unescape(label), ((x1 + x2) // 2, (y1 + y2) // 2)))
    return nodes


class SetupError(Exception):
    """The device could not be put in a case's starting state.

    Not an AssertionError: it is raised in the fixture's setup, so pytest
    reports an error before the agent runs, not a failed agent run.
    """


# Poll interval and how long a sign-in screen must stay before it counts as
# signed out. Module values, so offline tests can run the logic without delay.
POLL_SECONDS = 1.0
RESTORE_SECONDS = 8.0


def configured_account() -> str:
    """ARTEMIS_TEST_ACCOUNT, or a setup error when it is not configured."""
    if not TEST_ACCOUNT:
        raise SetupError("precondition: set ARTEMIS_TEST_ACCOUNT in e2e_test/.env")
    return TEST_ACCOUNT


def _labels() -> list[str]:
    return [label for label, _ in _nodes()]


def _first_line_starts(labels: list[str], wanted: str) -> bool:
    return any(label.split("\n")[0].startswith(wanted) for label in labels)


def _wait_for(*labels: str, timeout: float = 40) -> str:
    """Waits until a label starting with one of `labels` is on screen."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        seen = _labels()
        for wanted in labels:
            if _first_line_starts(seen, wanted):
                return wanted
        time.sleep(POLL_SECONDS)
    raise SetupError(f"precondition: none of {labels} appeared")


def _tap(label: str, timeout: float = 10) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        for text, (x, y) in _nodes():
            if text.split("\n")[0] == label:
                _adb("shell", "input", "tap", str(x), str(y))
                time.sleep(1.5)
                return
        time.sleep(POLL_SECONDS)
    raise SetupError(f"precondition: {label!r} is not on screen")


def _open_app() -> str:
    """Starts the app and returns the screen it settles on.

    The sign-in screen can show for a moment before a saved session is
    restored. Signed out is only reported when the sign-in screen is still
    there after RESTORE_SECONDS; any other screen (a system dialog, an
    unknown page) is a setup error.
    """
    _stop_app()
    _adb("shell", "am", "start", "-n", f"{APP_PACKAGE}/.MainActivity")
    if _wait_for(SIGN_IN_BUTTON, *HOME_TITLES) in HOME_TITLES:
        return "home"
    deadline = time.time() + RESTORE_SECONDS
    while time.time() < deadline:
        if any(_first_line_starts(_labels(), title) for title in HOME_TITLES):
            return "home"
        time.sleep(POLL_SECONDS)
    final = _labels()
    if any(_first_line_starts(final, title) for title in HOME_TITLES):
        return "home"
    if _first_line_starts(final, SIGN_IN_BUTTON):
        return SIGN_IN_BUTTON
    raise SetupError("precondition: the sign-in screen did not stay, and the app is not on its home screen")


def _home_shows_test_account() -> bool:
    """Whether the signed-in identity on the home screen is TEST_ACCOUNT."""
    account = configured_account().lower()
    return any(account in label.lower().split("\n") for label in _labels())


def ensure_signed_out() -> None:
    """Starts a case on the sign-in screen, through the app's own sign-out."""
    if _open_app() == "home":
        _tap("Hồ sơ")
        _wait_for("Đăng xuất")
        _tap("Đăng xuất")
        _tap("Đồng ý")
        _wait_for(SIGN_IN_BUTTON)
    if _open_app() != SIGN_IN_BUTTON:
        raise SetupError("precondition: still signed in")
    _stop_app()


def ensure_signed_in() -> None:
    """Starts a case signed in as TEST_ACCOUNT, picked in Google's account picker.

    A session of another account is a setup error; the message does not name it.
    """
    account = configured_account()
    if _open_app() == SIGN_IN_BUTTON:
        _tap(SIGN_IN_BUTTON)
        _wait_for(account)
        _tap(account)
        _wait_for(*HOME_TITLES, timeout=60)
    if _open_app() != "home":
        raise SetupError("precondition: not signed in")
    if not _home_shows_test_account():
        raise SetupError("precondition: signed in with an account other than ARTEMIS_TEST_ACCOUNT")
    _stop_app()


def _set_up_account_state(request) -> dict | None:
    """Puts the device in the state the case's marker asks for, and reports it."""
    if request.node.get_closest_marker("signed_out"):
        state, ensure = "signed_out", ensure_signed_out
    elif request.node.get_closest_marker("signed_in"):
        state, ensure = "signed_in", ensure_signed_in
    else:
        return None
    started = time.time()
    ensure()
    return {
        "state": state,
        "verified_by": "uiautomator after reopening the app",
        "account_checked": state == "signed_in",
        "seconds": round(time.time() - started, 1),
    }


@pytest.fixture
def case_config(request):
    """Checks a case's configuration before the daemon or the device is used.

    The artemis fixture depends on it, so a missing account is a setup error
    before the daemon is contacted, with no device action and no agent run.
    """
    if request.node.get_closest_marker("needs_account") or request.node.get_closest_marker("signed_in"):
        configured_account()


@pytest.fixture
def run_case(artemis, request):
    """Runs one instruction, keeps the raw result, and fails unless it succeeded.

    Each case starts with the app closed, unless it is marked `keep_app` (a push
    case needs the app left in the background). Sign-in survives a restart.

    Returns an `Observation`, for assertions on real values.
    """

    # Set the account state during setup, so no case depends on the one before
    # and a failure here is a setup error, not a failed agent run.
    precondition = _set_up_account_state(request)

    async def run(goal: str, expected_output: str) -> Observation:
        if request.node.get_closest_marker("keep_app") is None:
            _stop_app()
        started = time.time()
        selected_model = PRO_MODEL if PROFILE == "pro" else FLASH_MODEL
        result = await artemis.run(
            goal,
            expected_output=expected_output,
            enable_outputter=True,
            options={"model": selected_model},
        )
        # A final Outputter summary can mention earlier screens too. Never use
        # it as one synthetic step: after(action) would then accept stale text
        # from before that action (PR7-CR-08). Keep it only as raw evidence.
        observation_error = None
        try:
            observation = Observation(_step_summaries(result.task_id))
        except (urllib.error.URLError, OSError, ValueError, KeyError, TypeError) as error:
            observation = Observation([])
            observation_error = str(error)
        source = "replay_steps"

        EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
        record = {
            "test": request.node.nodeid,
            "precondition": precondition,
            "profile": PROFILE,
            "model": selected_model,
            "task_id": result.task_id,
            "status": result.status,
            "device": result.device_serial,
            "turns": result.turns,
            "seconds": round(time.time() - started, 1),
            "output_source": source,
            "output": str(observation),
            "steps": observation.steps,
            "agent_output": result.output,
            "observation_error": observation_error,
            "error": result.error,
        }
        with (EVIDENCE_DIR / "runs.jsonl").open("a", encoding="utf-8") as file:
            file.write(json.dumps(record, ensure_ascii=False, default=str) + "\n")

        assert result.succeeded, f"{result.status}: {result.error}"
        assert observation.strip(), (
            "no action-scoped replay observations: "
            f"{observation_error or 'empty replay; final output alone cannot pass the test'}"
        )
        return observation

    return run
