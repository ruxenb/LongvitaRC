# S7 — CodeRabbit PR #7 và gói sửa của Charlie, 03/11/2026

## Nguồn và quyết định

- PR nguồn: [#7](https://github.com/ruxenb/LongvitaRC/pull/7), code được review tại `cdf90e54d6c91be253e343c848ecfe23f69fd9cf`, merge `bc89635`.
- Công cụ: GitHub App `coderabbitai[bot]`, cấu hình do Thái An thêm. Có **11 inline findings: 5 Major / 6 Minor**, không tính template EX-xx.
- [Bảng quyết định](../../../docs/code-review.md#11-charlie--coderabbit-trên-pr-7-03112026): **8 Accepted / 2 Modified / 1 Rejected**, với file:dòng, lý do, source và commit sửa. CR-05 giữ quyết định Charlie về bằng chứng email/UID của chính mình và không rewrite lịch sử repo chung.
- Các commit của Claude được giữ nguyên, tích hợp main `97cbaa9` vào nhánh `feature/charlie-review-delivery-01`. Codex tiếp quản phần bàn giao/sửa follow-up theo yêu cầu Charlie. Chưa tự merge hoặc nghiệm thu task thay leader.

Ví dụ ba findings Accepted có commit sửa riêng: CR-03 → [2fd3e2e](https://github.com/ruxenb/LongvitaRC/commit/2fd3e2e), CR-04 → [ec61765](https://github.com/ruxenb/LongvitaRC/commit/ec61765), CR-09 → [46de7be](https://github.com/ruxenb/LongvitaRC/commit/46de7be). Các findings khác gắn cùng commit được ghi đúng như thực tế, không đếm một commit thành hai.

| File | Nội dung |
|---|---|
| `inline-comments.json` | 11 comment gốc, gồm ID/link/path/line/body và tác giả bot |
| `reviews.json` | Review submission của bot trên PR #7 |
| `summary-comments.json` | Conversation comments tại thời điểm lưu |
| `findings.md` | Bản đọc của 11 findings, có link tới comment gốc; chỉ chuẩn hóa trailing whitespace Markdown |
| `source-sha256.json` | SHA-256 ba JSON gốc giữ nguyên nội dung và bản Markdown diễn giải |
| `assertions-before.txt` | Probe trước follow-up: 20 pass / 1 fail, tái hiện final-output fallback của CR-08 |
| `assertions-after.txt` | Sau follow-up và hai ca thiếu replay: 23/23 kiểm assertions pass |
| `validation.json` | Kiểm IDs, quyết định, fix SHA, task counts và manifest |

Có thể đối chiếu lại nguồn mà không sửa PR:

```powershell
gh api repos/ruxenb/LongvitaRC/pulls/7/comments --paginate
gh api repos/ruxenb/LongvitaRC/pulls/7/reviews
gh api repos/ruxenb/LongvitaRC/issues/7/comments --paginate
```

## Kiểm chứng sửa lỗi

Lệnh chạy từ gốc repo, trong Python environment đã cài dependencies của `e2e_test/pyproject.toml`:

```powershell
python -B -m pytest -c test_support/e2e_review/pytest.ini test_support/e2e_review -q -p no:cacheprovider
python -B -m pytest --collect-only -q -p no:cacheprovider e2e_test
```

**23 regression assertions là kiểm tra độc lập bằng quan sát fixture, không phải 23 ca ARTEMIS hoặc lượt native.** Chúng gọi các test functions thật của TC-01/01b/11, TC-08/08b, TC-09/09b và TC-10 để xác nhận quan sát sai sẽ bị từ chối, còn quan sát phù hợp được chấp nhận. Không gọi daemon, model, thiết bị, Console hoặc tải file mạng.

- CR-08: giá trị/heading trước thao tác không làm bước sau pass. Follow-up [d41abe0](https://github.com/ruxenb/LongvitaRC/commit/d41abe0) chặn cả trường hợp SDK trả final `output`; harness luôn dùng replay từng bước, giữ final output chỉ như raw evidence. Replay thiếu/lỗi thì fail rõ.
- CR-09: launcher và Sign-in được chấp nhận sau Back; app Home hoặc kết quả không rõ bị từ chối.
- CR-10: URL thiếu/cụt/sai đường dẫn/sai đuôi bị từ chối; bytes tải về phải bắt đầu `%PDF-`.
- CR-11: ca không đổi không dùng thông báo trước thao tác; ca đổi yêu cầu thông báo áp dụng và giá trị trên màn hình khớp `RC_EXPECTED_MAX`. Thiếu Console precondition thì skip rõ. Đây là quyết định Modified, không tuyên bố đã phân biệt fetch lỗi và không có thay đổi ở service của Thái An.

Hai log assertions được giữ nội dung kết quả; chỉ bỏ trailing whitespace của pytest khi lưu bản dùng chung. Output gốc vẫn lưu trong workspace private. Các số 21 trước sửa / 23 sau sửa khác nhau vì sau đó bổ sung hai ca empty/error replay, không đổi expected để tạo pass.

## Evidence ARTEMIS và giới hạn

- Giữ nguyên 31 task records đã có khi tiếp quản. Batch đủ 7/7 trước merge #7 là record 17–23, khớp hai log pytest ở `evidence/artemis/`; không dùng “7 dòng cuối” sau khi append.
- 8 record thêm do Charlie/Claude chạy trước bàn giao: `status=completed` là trạng thái agent, không tự tương đương pytest assertions pass. Không tự bịa log pytest cho những task này.
- Khi Codex tiếp quản, ADB không thấy thiết bị và `127.0.0.1:8000/api/status` không có daemon. **Không có lượt ARTEMIS thật mới trong gói này.** TC-10/TC-11 sau sửa và TC-09b cần sửa Console vẫn chờ kiểm trên thiết bị; các lượt >=3 và exploratory còn ở S6.
- Flutter app/tests/config không đổi so với main `97cbaa9`; audit cùng tree Flutter đã có analyzer sạch, 271/271. Gói này kiểm lại Python/collection và không nhận là một lượt Flutter/Android/cloud mới.
- S7-1/2/3 ở trạng thái **Chờ nghiệm thu**, không phải Accepted; các vấn đề native của S6 và nghiệm thu chung vẫn mở.
