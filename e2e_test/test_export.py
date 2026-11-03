"""S6-7: export a PDF and upload it, then open it through the native viewer.

Needs a working Storage: the real project once DEC-01 allows it, or a debug build
with STORAGE_EMULATOR_HOST and the local emulator. State which one in the run notes.
"""

import re
import urllib.request

from conftest import screen_texts

# reports/{uid}/{exportId}.pdf in a Storage download URL, with its access token.
REPORT_URL = re.compile(
    r"^https?://[^/\s]+/v0/b/[^/\s]+/o/reports%2F(?P<uid>[A-Za-z0-9]{20,})%2F"
    r"(?P<file>[A-Za-z0-9_-]+\.pdf)\?alt=media&token=[0-9a-f-]{36}$"
)


def _download(url: str) -> bytes:
    # 10.0.2.2 is the host machine as seen from the Android emulator.
    url = url.replace("://10.0.2.2:", "://127.0.0.1:", 1)
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read()


async def test_tc08_export_uploads_and_shows_url(run_case):
    output = await run_case(
        "Open the Longvita app signed in. On the home screen tap 'Tạo thực đơn mẫu ngay' "
        "and wait for the success message. Open 'Hồ sơ', scroll to 'Báo cáo PDF', and tap "
        "'Xuất báo cáo PDF'. Wait until the export finishes. Then swipe up from the "
        "lower part of the screen (this moves the content up) until the download URL "
        "under the result message is fully visible, and read it.",
        "The result message under the export button, and the full download URL if shown.",
    )

    assert "Đã tải PDF lên Cloud Storage" in output.after("tap", "Xuất báo cáo PDF")

    # The agent's summary may shorten or misread a long URL, so the URL is read
    # from the screen itself, checked against the per-user path, and fetched.
    urls = [t for t in screen_texts() if "/o/reports%2F" in t]
    assert len(urls) == 1, f"expected one report URL on screen, found {urls}"
    match = REPORT_URL.match(urls[0])
    assert match, urls[0]
    assert _download(urls[0]).startswith(b"%PDF-")


async def test_tc08b_saved_pdf_opens_in_the_native_viewer(run_case):
    output = await run_case(
        "Open the Longvita app signed in. Create a meal plan with 'Tạo thực đơn mẫu ngay' "
        "if none exists, open 'Hồ sơ', and tap 'Xuất báo cáo PDF'. When it finishes tap "
        "'Mở PDF đã lưu'. Check whether the system PDF preview actually opened. "
        "Read the heading printed inside the PDF, not the app name. End your final "
        "observation with two separate lines: VIEWER: yes (or no), then HEADING: "
        "followed by the heading actually visible in the PDF. If the viewer failed, "
        "report VIEWER: no and HEADING: unavailable.",
        "Two lines in the final observation: VIEWER: yes/no and HEADING: printed PDF heading.",
    )

    # A mention of the app after a failed tap is not a viewer result (PR8-CR-02).
    # Missing/ambiguous fields fail closed; no earlier step supplies the heading.
    assert output.after("tap", "Mở PDF đã lưu"), "the open action was not observed"
    viewer = re.findall(r"^\s*VIEWER:\s*(yes|no)\s*$", output.last, re.I | re.M)
    headings = re.findall(r"^\s*HEADING:[ \t]*(\S[^\r\n]*)$", output.last, re.I | re.M)
    assert [value.lower() for value in viewer] == ["yes"], output.last
    assert len(headings) == 1 and re.search(r"\bLONGVITA\b", headings[0], re.I), output.last
