"""S6-7: export a PDF and upload it, then open it through the native viewer.

Needs a working Storage: the real project once DEC-01 allows it, or a debug build
with STORAGE_EMULATOR_HOST and the local emulator. State which one in the run notes.
"""


async def test_tc08_export_uploads_and_shows_url(run_case):
    output = await run_case(
        "Open the Longvita app signed in. On the home screen tap 'Tạo thực đơn mẫu ngay' "
        "and wait for the success message. Open 'Hồ sơ', scroll to 'Báo cáo PDF', and tap "
        "'Xuất báo cáo PDF'. Wait until the export finishes. Then swipe up from the "
        "lower part of the screen (this moves the content up) until the download URL "
        "under the result message is fully visible, and read it.",
        "The result message under the export button, and the full download URL if shown.",
    )

    assert "Đã tải PDF lên Cloud Storage" in output
    # The agent's summary may shorten a long URL, so only its per-user folder
    # is required; the file itself is checked against the emulator in the notes.
    assert "reports" in output


async def test_tc08b_saved_pdf_opens_in_the_native_viewer(run_case):
    output = await run_case(
        "Open the Longvita app signed in. Create a meal plan with 'Tạo thực đơn mẫu ngay' "
        "if none exists, open 'Hồ sơ', and tap 'Xuất báo cáo PDF'. When it finishes tap "
        "'Mở PDF đã lưu'.",
        "The name of the system screen that opened, and any heading readable in the PDF.",
    )

    # The heading must be seen after the tap that opens the viewer.
    assert "LONGVITA" in output.after("tap", "Mở PDF đã lưu").upper()
