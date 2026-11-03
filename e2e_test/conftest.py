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
from pathlib import Path

import pytest
from artemis_client import ArtemisClient
from dotenv import load_dotenv

load_dotenv()

BASE_URL = os.getenv("ARTEMIS_BASE_URL", "http://127.0.0.1:8000")
DEVICE_SERIAL = os.getenv("ANDROID_SERIAL") or None
PROFILE = os.getenv("ARTEMIS_PROFILE", "flash")  # flash (regression) or pro (exploratory)
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

    def after(self, *words: str) -> str:
        """The steps from the last one that mentions every word (any case).

        Empty when no step mentions them, so a missing action fails the check.
        """
        wanted = [w.lower() for w in words]
        for index in range(len(self.steps) - 1, -1, -1):
            step = self.steps[index].lower()
            if all(w in step for w in wanted):
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
async def artemis():
    """A client whose daemon has answered, so a dead daemon fails in setup."""
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
        try:
            _adb("shell", "uiautomator", "dump", "/sdcard/artemis-screen.xml")
            break
        except subprocess.CalledProcessError:
            if attempt == 9:
                raise
            time.sleep(2)
    return _adb("exec-out", "cat", "/sdcard/artemis-screen.xml").stdout.decode("utf-8")


def screen_texts() -> list[str]:
    """Every text and label currently exposed by Android's UI hierarchy."""
    xml = _screen_xml()
    values = re.findall(r'(?:text|content-desc)="([^"]+)"', xml)
    return [html.unescape(v) for v in values]


def screen_packages() -> set[str]:
    """Packages owning nodes in the current UI, independent of LLM summaries."""
    return set(re.findall(r'package="([^"]+)"', _screen_xml()))


def _stop_app() -> None:
    """Closes the app so a case cannot reuse what an earlier case left on screen."""
    _adb("shell", "am", "force-stop", APP_PACKAGE)


@pytest.fixture
def run_case(artemis, request):
    """Runs one instruction, keeps the raw result, and fails unless it succeeded.

    Each case starts with the app closed, unless it is marked `keep_app` (a push
    case needs the app left in the background). Sign-in survives a restart.

    Returns an `Observation`, for assertions on real values.
    """

    async def run(goal: str, expected_output: str) -> Observation:
        if request.node.get_closest_marker("keep_app") is None:
            _stop_app()
        started = time.time()
        result = await artemis.run(
            goal,
            expected_output=expected_output,
            enable_outputter=True,
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
            "profile": PROFILE,
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
