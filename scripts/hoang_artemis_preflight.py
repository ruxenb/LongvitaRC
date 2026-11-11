#!/usr/bin/env python3
"""Read-only ARTEMIS readiness gate. NEVER executes a device test.

Exit 0: prerequisites visible; exit 2: blocked. It does not certify E2E pass.
Does not print or persist account names, API keys, or device identifiers.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from urllib.error import URLError
from urllib.request import urlopen

EXPECTED_SHA = "351ca8422f7b5b54e80a9c1ce03a222e02415b6b"
HOANG_FILES = ("test_flows.py::", "test_detail.py::", "test_search.py::")


def read_dotenv(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    values: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip("\"'")
    return values


def configured(value: str | None) -> bool:
    if not value or not value.strip():
        return False
    low = value.strip().lower()
    return not (
        low in {"none", "null", "placeholder", "changeme", "todo", "test"}
        or low.startswith("test_")
        or "your-api-key" in low
        or low.startswith("<")
        or "example.com" in low
    )


def server_status(payload: object) -> bool:
    return (
        isinstance(payload, dict)
        and payload.get("status") in {"idle", "running", "busy", "active"}
        and isinstance(payload.get("model_info"), dict)
    )


def case_counts(output: str) -> tuple[int, int]:
    match = re.search(r"(\d+)\s+tests?\s+collected", output)
    if not match:
        return (0, 0)
    count = sum(
        1 for line in output.splitlines()
        if line.startswith(HOANG_FILES)
    )
    return (int(match.group(1)), count)


def adb_connected(output: str, serial: str) -> bool:
    return any(
        line.split()[0] == serial and line.split()[1] == "device"
        for line in output.splitlines()
        if len(line.split()) >= 2 and not line.startswith("List of")
    )


def invoke(command: list[str], cwd: Path | None = None, timeout: int = 30):
    try:
        return subprocess.run(
            command, cwd=cwd, capture_output=True, text=True,
            encoding="utf-8", errors="replace", timeout=timeout, check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None


def assess(args: argparse.Namespace) -> dict:
    repo = args.repo.resolve()
    e2e = repo / "e2e_test"
    artemis = args.artemis_root.resolve()
    env = read_dotenv(args.test_env_file)
    daemon_env = read_dotenv(artemis / ".env")
    checks: dict[str, str] = {}

    rev = invoke(["git", "-C", str(artemis), "rev-parse", "HEAD"], timeout=10)
    checks["pinned_artemis_sha"] = (
        "PASS" if rev and rev.returncode == 0 and rev.stdout.strip() == EXPECTED_SHA
        else "BLOCKED"
    )
    python = args.python
    imports = invoke(
        [str(python), "-c", "import artemis_client,pytest"], timeout=20
    ) if python.is_file() else None
    checks["python_sdk_pytest"] = (
        "PASS" if imports and imports.returncode == 0 else "BLOCKED"
    )

    adb = invoke([str(args.adb), "devices", "-l"], timeout=12)
    serial = args.serial or env.get("ANDROID_SERIAL", "")
    checks["authorized_adb_phone"] = (
        "PASS" if serial and adb and adb.returncode == 0
        and adb_connected(adb.stdout, serial) else "BLOCKED"
    )

    try:
        url = args.base_url.rstrip("/") + "/api/status"
        with urlopen(url, timeout=6) as response:
            mime = response.headers.get("Content-Type", "")
            payload = json.loads(response.read(100000).decode("utf-8"))
        checks["real_artemis_status_api"] = (
            "PASS" if "application/json" in mime and server_status(payload)
            else "BLOCKED"
        )
    except (OSError, ValueError, URLError, TypeError):
        checks["real_artemis_status_api"] = "BLOCKED"

    key = (
        os.environ.get("GEMINI_API_KEY")
        or os.environ.get("GOOGLE_API_KEY")
        or daemon_env.get("GEMINI_API_KEY")
        or daemon_env.get("GOOGLE_API_KEY")
    )
    checks["google_model_key_configured"] = (
        "PRESENT_NOT_VALIDATED" if configured(key) else "BLOCKED"
    )
    account = (
        os.environ.get("ARTEMIS_TEST_ACCOUNT")
        or env.get("ARTEMIS_TEST_ACCOUNT")
    )
    checks["dedicated_test_account_configured"] = (
        "PRESENT_NOT_VALIDATED" if configured(account) and "@" in (account or "")
        else "BLOCKED"
    )

    collection = invoke(
        [str(python), "-m", "pytest", "--collect-only", "-q"],
        cwd=e2e, timeout=30,
    ) if checks["python_sdk_pytest"] == "PASS" else None
    collected = case_counts(collection.stdout) if (
        collection and collection.returncode == 0
    ) else (0, 0)
    checks["pytest_collection"] = (
        "PASS" if collected[0] >= 18 and collected[1] >= 10 else "BLOCKED"
    )

    blockers = [name for name, status in checks.items() if status == "BLOCKED"]
    return {
        "gate": "READY_TO_EXECUTE_NOT_E2E_PASSED" if not blockers else "BLOCKED",
        "checks": checks,
        "collected_group_cases": collected[0],
        "collected_hoang_cases": collected[1],
        "new_e2e_passes": 0,
        "blockers": blockers,
        "note": (
            "No device commands beyond adb devices; no test execution or Firebase "
            "writes. API key and account presence are not credential validity."
        ),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    repo = Path(__file__).resolve().parents[1]
    artemis_default = Path(
        os.environ.get("ARTEMIS_ROOT", r"D:\Tools\ARTEMIS_351ca842")
    )
    parser.add_argument("--repo", type=Path, default=repo)
    parser.add_argument("--artemis-root", type=Path, default=artemis_default)
    parser.add_argument("--python", type=Path, default=repo / "e2e_test/.venv/Scripts/python.exe")
    parser.add_argument("--adb", type=Path, default=Path(
        os.environ.get("ADB", r"D:\Tools\AndroidSDK\platform-tools\adb.exe")
    ))
    parser.add_argument("--serial", default=os.environ.get("ANDROID_SERIAL", ""))
    parser.add_argument("--test-env-file", type=Path, default=repo / "e2e_test/.env")
    parser.add_argument("--base-url", default=os.environ.get(
        "ARTEMIS_BASE_URL", "http://127.0.0.1:8000"
    ))
    args = parser.parse_args()
    result = assess(args)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if result["gate"].startswith("READY") else 2


if __name__ == "__main__":
    sys.exit(main())
