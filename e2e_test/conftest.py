"""
Google ARTEMIS E2E configuration for the Longvita Android app (Handout Section 7).

Runs against a real ARTEMIS daemon and device. There is no fallback client: a
missing SDK, daemon or device fails the run, because a test that cannot observe
the app must never report success.

Setup: docs in README.md, section 5. Requires GEMINI_API_KEY on the daemon host.
"""
import json
import os
import time
from pathlib import Path

import pytest
from artemis_client import ArtemisClient
from dotenv import load_dotenv

load_dotenv()

BASE_URL = os.getenv("ARTEMIS_BASE_URL", "http://127.0.0.1:8000")
DEVICE_SERIAL = os.getenv("ANDROID_SERIAL") or None
PROFILE = os.getenv("ARTEMIS_PROFILE", "flash")  # flash (regression) or pro (exploratory)
EVIDENCE_DIR = Path(__file__).parent.parent / "evidence" / "artemis" / "raw"


@pytest.fixture
async def artemis():
    """A client whose daemon has answered, so a dead daemon fails in setup."""
    client = ArtemisClient(BASE_URL, device_serial=DEVICE_SERIAL, default_profile=PROFILE)
    await client.health()
    return client


@pytest.fixture
def run_case(artemis, request):
    """Runs one instruction, keeps the raw result, and fails unless it succeeded.

    Returns the agent's observed output as text, for assertions on real values.
    """

    async def run(goal: str, expected_output: str) -> str:
        started = time.time()
        result = await artemis.run(
            goal,
            expected_output=expected_output,
        )
        EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
        record = {
            "test": request.node.nodeid,
            "profile": PROFILE,
            "task_id": result.task_id,
            "status": result.status,
            "device": result.device_serial,
            "turns": result.turns,
            "seconds": round(time.time() - started, 1),
            "output": result.output,
            "error": result.error,
        }
        with (EVIDENCE_DIR / "runs.jsonl").open("a", encoding="utf-8") as file:
            file.write(json.dumps(record, ensure_ascii=False, default=str) + "\n")

        assert result.succeeded, f"{result.status}: {result.error}"
        output = "" if result.output is None else str(result.output)
        assert output.strip(), "the agent reported success but observed nothing"
        return output

    return run
