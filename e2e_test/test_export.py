"""S6-7: export a PDF and upload it, then open it through the native viewer.

Needs a working Storage: the real project once DEC-01 allows it, or a debug build
with STORAGE_EMULATOR_HOST and the local emulator. State which one in the run notes.
"""

import os
import re
import urllib.request

from conftest import active_window_package, screen_texts

PDF_VIEWER_PACKAGE = os.getenv("PDF_VIEWER_PACKAGE", "com.android.printspooler")
PDF_HEADING = re.compile(r"(?:heading|titled|report title|tiêu đề)[^.;\n]{0,100}\bLONGVITA\b", re.I)
_HEADING = r"(?:heading|titled|report title|tiêu đề)"
_NOT_VISIBLE = (
    r"(?:not\s+(?:visible|shown|displayed|present)|absent|missing|unavailable|"
    r"(?:không|chưa)\s+(?:hiển thị|hiện|thấy|có))\b"
)
NEGATED_HEADING = re.compile(
    r"\b(?:no|without|missing|absent)\s+"
    r"(?:(?:a|the|visible|printed|PDF|report)\s+){0,4}" + _HEADING + r"|"
    r"\b(?:không|chưa)\s+(?:(?:có|thấy|hiển thị|hiện|in)\s+){0,3}" + _HEADING + r"|"
    + _HEADING + r"[^.;\n]{0,100}\bLONGVITA\b['\"“”]?\s*"
    r"(?:(?:is|was|remains|appears)\s+)?" + _NOT_VISIBLE + r"|"
    + _HEADING + r"\s+(?:is\s+)?" + _NOT_VISIBLE + r"[^.;\n]{0,60}\bLONGVITA\b", re.I,
)

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
        "Read the heading printed inside the PDF, not the app name. Keep the system "
        "preview open at the end and describe its title and the printed heading. "
        "If no heading is visible, say that instead of supplying the app name.",
        "The system preview title and the heading actually visible inside the PDF.",
    )

    # The pinned Flash summarizer emits one paragraph, not VIEWER/HEADING fields.
    # Confirm the native viewer independently, then the heading in the final step.
    assert output.after("tap", "Mở PDF đã lưu"), "the open action was not observed"
    assert active_window_package() == PDF_VIEWER_PACKAGE, "system PDF preview is not the active window"
    assert PDF_HEADING.search(output.last) and not NEGATED_HEADING.search(output.last), output.last
