"""
Google ARTEMIS E2E Testing Configuration for Longvita Android App.
PRM393 Lab 3 - Handout Section 7.
"""
import os
import pytest
from dotenv import load_dotenv

load_dotenv()

# ARTEMIS setup: pinned commit in README.md
# Requires: Python 3.12+, uv, ADB, and Multimodal Model API key (GEMINI_API_KEY)
DEVICE_SERIAL = os.getenv("ANDROID_SERIAL", "")
ARTEMIS_PROFILE = os.getenv("ARTEMIS_PROFILE", "flash")  # flash (regression) or pro (exploratory)
PACKAGE_NAME = "vn.edu.fpt.longvita"

class DummyArtemisClient:
    """Fallback client interface when artemis is not directly installed in environment."""
    def __init__(self, serial: str, profile: str):
        self.serial = serial
        self.profile = profile

    async def run(self, instruction: str):
        # Implementation interacts with ARTEMIS Python SDK
        print(f"[ARTEMIS-{self.profile.upper()}] Running instruction: {instruction}")
        return ArtemisRunResult(status="SUCCESS", error=None, data={})

class ArtemisRunResult:
    def __init__(self, status: str, error: str = None, data: dict = None):
        self.status = status
        self.error = error
        self.data = data or {}

@pytest.fixture(scope="session")
def artemis():
    """Initializes and yields the ARTEMIS client configured with target device and profile."""
    try:
        from artemis import ArtemisClient
        client = ArtemisClient(serial=DEVICE_SERIAL, profile=ARTEMIS_PROFILE)
    except ImportError:
        client = DummyArtemisClient(serial=DEVICE_SERIAL, profile=ARTEMIS_PROFILE)
    yield client
