"""
Google ARTEMIS E2E configuration for the Longvita Android app (Handout Section 7).

Runs against a real ARTEMIS daemon and device. There is no fallback client: a
missing SDK, daemon or device fails the run, because a test that cannot observe
the app must never report success.

Setup: docs in README.md, section 5. Requires GEMINI_API_KEY on the daemon host.
"""
import json
import os
import subprocess
import time
import urllib.parse
import urllib.request
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


def _step_summaries(task_id: str) -> str | None:
    """What the agent reported seeing after each step, oldest first."""
    url = f"{BASE_URL}/api/sessions/{urllib.parse.quote(task_id)}/replay_steps"
    with urllib.request.urlopen(url, timeout=30) as response:
        steps = json.load(response)
    summaries = [s.get("summary") or "" for s in sorted(steps, key=lambda s: s.get("step_number", 0))]
    text = "\n".join(s for s in summaries if s.strip())
    return text or None


@pytest.fixture
async def artemis():
    """A client whose daemon has answered, so a dead daemon fails in setup."""
    client = ArtemisClient(BASE_URL, device_serial=DEVICE_SERIAL, default_profile=PROFILE)
    await client.health()
    return client


def _stop_app() -> None:
    """Closes the app so a case cannot reuse what an earlier case left on screen."""
    command = [ADB, "shell", "am", "force-stop", APP_PACKAGE]
    if DEVICE_SERIAL:
        command[1:1] = ["-s", DEVICE_SERIAL]
    subprocess.run(command, check=True, capture_output=True, timeout=30)


@pytest.fixture
def run_case(artemis, request):
    """Runs one instruction, keeps the raw result, and fails unless it succeeded.

    Each case starts with the app closed, unless it is marked `keep_app` (a push
    case needs the app left in the background). Sign-in survives a restart.

    Returns the agent's observed output as text, for assertions on real values.
    """

    async def run(goal: str, expected_output: str) -> str:
        if request.node.get_closest_marker("keep_app") is None:
            _stop_app()
        started = time.time()
        result = await artemis.run(
            goal,
            expected_output=expected_output,
            enable_outputter=True,
        )
        output, source = result.output, "output"
        if output is None:
            # At the pinned ARTEMIS commit the Flash profile skips the Outputter,
            # so the task carries no output. The agent's own per-step summaries
            # of what it saw on screen are the observation in that case.
            output, source = _step_summaries(result.task_id), "replay_steps"
        output = "" if output is None else str(output)

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
            "output": output,
            "error": result.error,
        }
        with (EVIDENCE_DIR / "runs.jsonl").open("a", encoding="utf-8") as file:
            file.write(json.dumps(record, ensure_ascii=False, default=str) + "\n")

        assert result.succeeded, f"{result.status}: {result.error}"
        assert output.strip(), "the agent reported success but observed nothing"
        return output

    return run
