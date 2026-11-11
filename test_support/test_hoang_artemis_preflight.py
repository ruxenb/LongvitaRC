"""Offline regression for the read-only ARTEMIS preflight gate."""
import importlib.util
from pathlib import Path
import unittest

SOURCE = Path(__file__).resolve().parents[1] / "scripts/hoang_artemis_preflight.py"
spec = importlib.util.spec_from_file_location("hoang_artemis_preflight", SOURCE)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ReadinessTests(unittest.TestCase):
    def test_unset_or_placeholder_keys_never_count_as_configured(self):
        for value in (None, "", " ", "changeme", "test", "TEST_KEY",
                      "your-api-key-here", "<API_KEY>", "test.account@example.com"):
            self.assertFalse(module.configured(value))
        self.assertTrue(module.configured("nonplaceholder-but-not-validated"))

    def test_dotenv_parser_does_not_need_secrets(self):
        from tempfile import TemporaryDirectory
        with TemporaryDirectory() as tmp:
            p = Path(tmp) / ".env"
            p.write_text("# comment\nKEY=value\nQUOTED='hello world'\nEMPTY=\n", encoding="utf8")
            values = module.read_dotenv(p)
            self.assertEqual(values["KEY"], "value")
            self.assertEqual(values["QUOTED"], "hello world")
            self.assertEqual(values["EMPTY"], "")
            self.assertNotIn("# comment", values)

    def test_reject_spa_html_or_incomplete_status_as_health(self):
        self.assertFalse(module.server_status("<html>OK</html>"))
        self.assertFalse(module.server_status({"status": "idle"}))
        self.assertFalse(module.server_status({"status": "pending", "model_info": {}}))
        self.assertTrue(module.server_status({"status": "idle", "model_info": {"id": "flash"}}))

    def test_cases_count_only_real_pytest_collection(self):
        sample = (
            "test_flows.py::test_A\n"
            "test_detail.py::test_B\n"
            "test_search.py::test_C\n"
            "test_auth.py::test_D\n"
            "\n18 tests collected in 0.18s\n"
        )
        self.assertEqual(module.case_counts(sample), (18, 3))
        self.assertEqual(module.case_counts("18 test cases maybe"), (0, 0))

    def test_reject_offline_and_unauthorized_devices(self):
        status = (
            "List of devices attached\n"
            "RF8X... offline product:a15\n"
            "EMULATOR-5554 device product:sdk\n"
            "DEVICE-02 unauthorized\n"
        )
        self.assertFalse(module.adb_connected(status, "RF8X..."))
        self.assertFalse(module.adb_connected(status, "DEVICE-02"))
        self.assertTrue(module.adb_connected(status, "EMULATOR-5554"))


if __name__ == "__main__":
    unittest.main()
