# PR #8 — kiểm tra trước merge, 03/11/2026

**Bản hiện tại:** [d7c7609](https://github.com/ruxenb/LongvitaRC/commit/d7c7609) thu hẹp phủ định vào heading/visibility; [d7ffa05](https://github.com/ruxenb/LongvitaRC/commit/d7ffa05) phân biệt Back/background. Tiếp nối `1d3d995` kiểm root cửa sổ và `0df2563` thay protocol hai dòng bằng native UI package + replay. Bộ kiểm assertions **49/49 pass**, có test dùng replay thật đã lưu. Các kết quả 30/30, 33/33, 40/40 và parser hai dòng bên dưới là lịch sử các lượt trước.

CodeRabbit đã review head `2833d74`: 3 findings (2 Major, 1 Minor). Check SUCCESS chỉ xác nhận review chạy xong; ba findings được đối chiếu và sửa trước khi merge.

| ID | Source | Quyết định | Sửa |
|---|---|---|---|
| PR8-CR-01 | [4454808776](https://github.com/ruxenb/LongvitaRC/pull/8#discussion_r4454808776), slide:26 | Accepted | [e0e39e3](https://github.com/ruxenb/LongvitaRC/commit/e0e39e3): giới hạn claim cho tin có recipient_uid, ghi rõ broadcast có thể chờ tới phiên sau |
| PR8-CR-02 | [4454808788](https://github.com/ruxenb/LongvitaRC/pull/8#discussion_r4454808788), test_export.py:57 | Accepted | [bcaa8a5](https://github.com/ruxenb/LongvitaRC/commit/bcaa8a5): đòi VIEWER: yes và HEADING riêng ở quan sát cuối, không dùng tên app sau thao tác thất bại |
| PR8-CR-03 | [4454808804](https://github.com/ruxenb/LongvitaRC/pull/8#discussion_r4454808804), test_profile.py:68 | Accepted | [bcaa8a5](https://github.com/ruxenb/LongvitaRC/commit/bcaa8a5): đòi title ở inbox cuối, không lấy từ câu mô tả thao tác tap |

`inline-comments.json` giữ source bot gốc, kèm SHA-256 trong `source-sha256.json`. `before.txt` chứng minh hai assertion cũ vẫn chấp nhận quan sát sai: 2 regression fail đúng expected. `after.txt`: **30/30 kiểm assertions pass**. Hai logs chỉ bỏ trailing whitespace của pytest, không thay kết quả; không phải native/ARTEMIS runs.

```powershell
python -B -m pytest -c test_support/e2e_review/pytest.ini test_support/e2e_review -q -p no:cacheprovider
```

Protocol VIEWER/HEADING cố ý fail khi thiếu hoặc mâu thuẫn, và không đọc heading từ bước trước. Nó vẫn là quan sát do agent báo cáo, không phải phép xác minh Android độc lập; cần chạy lại TC-08b native để xác nhận agent giữ đúng định dạng khi có thiết bị/daemon. TC-10 và TC-11 sau các sửa assertions cũng chưa có lượt native mới. Những giới hạn này thuộc evidence S6, không được cộng 30 checks vào pass rate ARTEMIS.

## Lượt 2 — kiểm đúng producer đã ghim

CodeRabbit phát hiện thêm hai vấn đề tại `323d930`; cả hai Accepted và được sửa cùng `0df2563`:

- [PR8-CR-04, 4455074344](https://github.com/ruxenb/LongvitaRC/pull/8#discussion_r4455074344): parser có thể bỏ qua dòng VIEWER sai/duplicate. Parser bị loại bỏ hoàn toàn, không giữ lỗ hổng này trong code cuối.
- [PR8-CR-05, 4455074363](https://github.com/ruxenb/LongvitaRC/pull/8#discussion_r4455074363): [Flash summarizer đúng commit pin](https://raw.githubusercontent.com/google/artemis/351ca8422f7b5b54e80a9c1ce03a222e02415b6b/artemis/agents/flash/flash_summarizer.md) chỉ sinh một đoạn không xuống dòng. Đòi hai dòng đánh nhãn là sai contract của producer.

Code cuối kiểm package owning nodes trong UIAutomator hierarchy: mặc định `com.android.printspooler` theo native preview của `Printing.layoutPdf`; có `PDF_VIEWER_PACKAGE` cho môi trường đã xác minh dùng viewer khác. Chỉ sau khi xác nhận native viewer, test mới kiểm printed heading trong quan sát cuối, với dạng một đoạn như replay thật. Không dùng tên app đơn lẻ làm bằng chứng viewer mở, không lấy final SDK output thành một bước giả. [AOSP PrintSpooler manifest](https://android.googlesource.com/platform/frameworks/base/+/eae43fb/packages/PrintSpooler/AndroidManifest.xml).

`producer-compatible.txt`: 33/33 kiểm assertions pass, bao gồm case UI vẫn là app dù LLM nói có heading, hierarchy package parsing và replay TC-08b đã lưu (`46f57d95`). Đây là kiểm contract/logic với native hierarchy fixture, **chưa phải native rerun mới**. Cần TC-08b/10/11 live khi môi trường sẵn sàng; không sửa số lượt ARTEMIS từ 33 checks này.

`followup-inline-comments.json` lưu hai source comments mới, được bổ sung vào manifest SHA-256.

Đồng thời sửa câu slide Auth theo PM-DOC-01: staff/admin được đọc hồ sơ theo rules. Đây là correction của PM, không tính thành finding CodeRabbit thứ tư.

## Lượt 3 — root cửa sổ và heading phủ định

Hai Minor tại `f9f2130` được Accepted và sửa trong `1d3d995`:

- [PR8-CR-06, 4455233119](https://github.com/ruxenb/LongvitaRC/pull/8#discussion_r4455233119): package ở descendant không chứng minh cửa sổ hiện hành. Chỉ đọc package của root; hierarchy thiếu hoặc có nhiều root bị từ chối.
- [PR8-CR-07, 4455233159](https://github.com/ruxenb/LongvitaRC/pull/8#discussion_r4455233159): từ chối câu phủ định như “No heading LONGVITA is visible” và “Không có tiêu đề LONGVITA”. Replay dương đã lưu vẫn được chấp nhận.

`round3-inline-comments.json` lưu nguồn của hai comments; `root-window-and-heading.txt` ghi **40/40 kiểm assertions độc lập pass** (chỉ bỏ trailing whitespace của pytest). Không có native rerun, không cộng 40 checks này vào số lượt ARTEMIS. Heading vẫn dựa vào quan sát agent, còn package được kiểm độc lập qua UIAutomator; không tuyên bố đây là phép so nội dung PDF tự động hoàn toàn.

## Lượt 4 — phủ định đúng chủ thể và Back/background

Hai Minor tại `06b8f9f` được Accepted:

- [PR8-CR-08, 4455418593](https://github.com/ruxenb/LongvitaRC/pull/8#discussion_r4455418593): “The printed heading LONGVITA is visible, not the app name” phải pass. `d7c7609` thu hẹp các mẫu phủ định vào heading/visibility; thêm ca dương với phủ định mô tả nội dung khác và ca âm khi heading không hiện.
- [PR8-CR-09, ngoài diff trong review 5753132961](https://github.com/ruxenb/LongvitaRC/pull/8#pullrequestreview-5753132961): `back` khớp nhầm `background`, làm kiểm Back pass dù thiếu hành động. `d7ffa05` bật whole-word chỉ ở hai Back checks; các callers khác giữ substring để nhận `tapped`.

`round4-inline-comments.json` và `round4-review.json` lưu nguồn, kể cả finding ngoài diff không có inline thread. `heading-visibility-and-back.txt`: **49/49 checks pass**, chỉ chuẩn hóa trailing whitespace. Các ca âm background, ca dương Back, tap/tapped và replay heading đã lưu đều được kiểm. Không có native rerun mới; các giới hạn của lượt 3 vẫn áp dụng.
