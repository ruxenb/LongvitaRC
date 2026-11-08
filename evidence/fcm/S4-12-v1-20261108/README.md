# S4-12 — Contract FCM v1, 08/11/2026

Kiểm commit `ada76da` (nhánh `feature/charlie-fcm-safe-01`, từ main `b7507ec`). Contract: [`docs/tasks/charlie-progress.md`](../../../docs/tasks/charlie-progress.md), mục "Contract FCM v1".

## Thay đổi được kiểm

- Tin chỉ được nhận khi `recipient_uid` khớp chính xác user đang đăng nhập.
  - Tin thiếu, rỗng hoặc sai kiểu người nhận bị loại hoàn toàn: không vào inbox, lịch sử hay hàng chờ.
  - Tin có UID hợp lệ của user khác không vào inbox hay lịch sử của user đang dùng, không hiện thanh thông báo trong app, không mở Profile. Nếu tin đến khi app ở nền, handler (vốn không biết ai đang đăng nhập) vẫn xếp nó vào hàng chờ cho đúng người nhận đó.
- Lịch sử khôi phục được kiểm lại người nhận từng mục. Mục đọc lỗi chỉ bỏ riêng mục đó.
- Mỗi phiên có số thế hệ riêng, kể cả A → đăng xuất → A, nên việc đọc lịch sử, lấy tin chờ hay lưu của phiên cũ không tác động phiên mới. App không lưu trước khi đọc xong lịch sử.
- Tin nền xếp mỗi tin một file trong `notifications/pending/`, tối đa 50. App chỉ lấy tin của user đang đăng nhập và xóa file sau khi lưu thành công. File `pending.json` của bản cũ được chuyển một lần.

## Kiểm tự động

| Kiểm | Kết quả |
|---|---|
| `flutter analyze --no-pub` | Sạch ([analyze.txt](analyze.txt)) |
| `flutter test --no-pub` toàn bộ | 376/376 ([flutter-test.txt](flutter-test.txt)) |
| `test/fcm`, `test/profile` | 143/143 |
| Kiểm đột biến: gỡ từng chỗ sửa rồi chạy lại test | 9/9 bị test bắt ([mutation-check.txt](mutation-check.txt)) |

Các test dùng gateway giả; phần lưu trữ dùng thư mục tạm thật. Hai store cùng thư mục giả lập isolate nền ghi trong lúc app đang lấy tin. Thứ tự race được điều khiển bằng `Completer`, không dùng sleep.

## Kiểm trên AVD

**Môi trường:**
- AVD `LocalMate_API_35` (Android 15), APK debug từ `ada76da` (SHA-256 `cd40981322ced001249622243d7bded20d6179db64a24cabf8c3f4a15abb3224`).
- Firebase project `longvita-8da7e`. Tài khoản kiểm của Charlie đã đăng nhập sẵn.

**Cách gửi:**
- Script QA ngoài Git gọi FCM HTTP v1 bằng tài khoản `firebase login`, gửi tới token của AVD (đọc từ log debug mỗi lượt).
- Nội dung chung: title "Longvita", body "Bạn có thông báo mới. Mở ứng dụng để xem."
- `data` chỉ có `message_id` và `recipient_uid` (đúng UID của tài khoản kiểm, một UID giả `qa-other-uid-0000`, hoặc bỏ trường).

**Cách kiểm:** đọc file của app qua `run-as` (bản debug) và hierarchy qua `uiautomator`. "Terminated" là về Home rồi `am kill` (không force-stop), có kiểm tiến trình đã chết trước khi gửi.

| Ca | Kỳ vọng | Kết quả |
|---|---|---|
| Foreground, đúng người nhận | Thanh "Thông báo mới", vào lịch sử | PASS |
| Foreground, thiếu người nhận | Không gì cả | PASS |
| Foreground, sai người nhận | Không gì cả | PASS |
| Background, đúng | Khay hiện tin; handler xếp 1 file; bấm mở Profile; vào lịch sử; file chờ đã xóa | PASS |
| Background, sai | Khay vẫn hiện tin chung (do hệ điều hành); handler xếp 1 file cho UID kia; bấm thì app mở ở Dashboard, không Profile, không vào lịch sử | PASS |
| Background, thiếu | Khay hiện tin chung; handler không xếp file; bấm không mở Profile, không vào lịch sử | PASS |
| Terminated, đúng | Bấm thì app khởi động, mở Profile, vào lịch sử | PASS |
| Terminated, sai | Lần 1 (14:44): `am kill` chưa dừng được tiến trình nên ca này chưa đạt điều kiện terminated, ghi **FAIL precondition**. Hành vi app vẫn đúng: không Profile, không vào lịch sử. Retry (14:45) sau khi kill có kiểm lại: PASS | FAIL → retry PASS |

**Tổng hợp:** 8 kịch bản đã chạy, cả 8 đạt sau retry. Tổng cộng 9 lượt: 8 PASS và 1 FAIL precondition (lượt terminated-sai đầu tiên). Ca terminated-thiếu người nhận chưa chạy riêng; ca background-thiếu chỉ cho thấy handler nền bỏ tin đó, không thay cho lượt terminated.

Chi tiết từng lượt: [native-results.json](native-results.json), giữ nguyên cả lượt fail và lượt retry. Không ghi token hay UID.

`01-profile-inbox-v1.png`: inbox sau lượt kiểm có đúng ba tin của ca "đúng người nhận".

## Ghi chú và giới hạn

- **Lịch sử cũ trên AVD:** có 21 mục không có `recipient_uid` (tin TC-10 của S6-7). Bản mới không hiện các mục này, và chúng mất khỏi file ở lần lưu kế tiếp, theo contract. Bản sao file cũ được giữ ngoài Git.
- **Hàng chờ của UID giả:** sau lượt kiểm còn 3 file chờ của `qa-other-uid-0000`. Đây là hành vi đúng: tin của user khác được giữ, tối đa 50 file.
- **Giới hạn của bộ lọc:** `recipient_uid` chỉ lọc phía app. Khi app ở nền hoặc đã tắt, Android tự hiện tin trên khay trước khi app kiểm, nên tin gửi nhầm vẫn để lại lời nhắc chung trên khay. App chỉ chặn inbox và điều hướng.
- **Chưa kiểm trên AVD:** A → đăng xuất → A/B trong lúc đang đọc lịch sử hay lấy tin chờ mới được kiểm bằng test có điều khiển thứ tự. Tôi không đăng xuất/đăng nhập Google thật lặp lại cho phần này.

## Sau PM review (bfd17f4), 08/11/2026

PM review `bfd17f4`: Changes requested với PM-S412-01, PM-S412-02 và PM-S412-DOC-01.

### PM-S412-01: lần lưu cũ đang chạy khi cùng user đăng nhập lại

**Lỗi:** hàng lưu chỉ sắp xếp các lần lưu với nhau. Khi A đăng xuất rồi đăng nhập lại trong lúc lần lưu của phiên trước chưa ghi xong, phiên mới đọc file cũ. Lần lưu sau của phiên mới ghi đè, làm mất tin của phiên trước.

**Sửa:** mỗi UID có một hàng tác vụ riêng, gồm cả đọc và lưu, chạy theo đúng thứ tự gọi. Lần đọc của phiên mới chạy sau mọi lần lưu đã yêu cầu trước đó cho UID ấy, nên đọc được cả tin phiên trước. User khác không phải chờ. Kiểm số thế hệ phiên vẫn giữ: lần đọc của phiên cũ trả kết quả muộn không đưa gì vào phiên mới.

### PM-S412-02: lỗi đọc I/O bị coi là lịch sử rỗng

**Lỗi:** store nuốt `FileSystemException` thành danh sách rỗng, nên service coi như đã đọc và ghi đè file chưa đọc được.

**Sửa:**
- Store chỉ trả rỗng khi file không tồn tại. File còn mà đọc lỗi thì ném lỗi; JSON hỏng vẫn đọc là rỗng như trước.
- Service không lưu và không xóa tin khỏi hàng chờ khi chưa đọc được lịch sử của phiên.
- Có tin mới, hoặc app quay lại foreground (drain), thì service đọc lại. Đọc được thì lưu cả lịch sử cũ lẫn tin mới, rồi mới xóa tin khỏi hàng chờ.
- Migration `pending.json`: đọc lỗi thì giữ file.
- Từng file chờ đọc lỗi thì không được lấy, nên cũng không bị xóa.

### Kiểm sau sửa (chưa commit lúc chạy; code của commit sửa)

| Kiểm | Kết quả |
|---|---|
| `flutter analyze --no-pub lib test` | Sạch ([review-fix-analyze.txt](review-fix-analyze.txt)). Analyzer toàn cây báo thêm 5 cảnh báo, chỉ từ probe local của PM trong `docs/coordination` (Git bỏ qua) |
| `flutter test --no-pub` toàn bộ | 383/383 ([review-fix-flutter-test.txt](review-fix-flutter-test.txt)) |
| `test/fcm`, `test/profile`, `test/auth`, `test/report` | 328/328 |
| Probe PM | 3/3: hai probe phát hiện lỗi nay đạt, đối chứng vẫn đạt ([review-fix-pm-probe.txt](review-fix-pm-probe.txt)) |
| Kiểm ngược | 4/4 bị bắt khi gỡ từng phần sửa (R1–R4). M3 và M6 cũ được chạy lại theo cấu trúc mới, cả hai bị bắt ([review-fix-mutation-check.txt](review-fix-mutation-check.txt)) |

**Regression mới** trong `test/fcm/notification_history_test.dart`, nhóm "PM-S412 review fixes":
- PM-S412-01: lần lưu đang chạy lúc đăng nhập lại được đọc, không mất (chuyển từ probe PM).
- PM-S412-01: user khác không phải chờ lần lưu đang giữ của A.
- PM-S412-02: file còn mà đọc lỗi thì ném lỗi; file không có thì rỗng.
- PM-S412-02: đọc lỗi thì không ghi đè; đọc được rồi thì lưu đủ.
- PM-S412-02: `pending.json` cũ được giữ khi chưa đọc được.
- PM-S412-02: file chờ đọc lỗi thì vẫn ở lại hàng chờ.
- PM-S412-02: file bị khóa bởi tiến trình khác (khóa thật, chỉ chạy trên Windows). Các ca trên dùng chỗ đọc file thay thế được (`readFile`) nên chạy trên mọi máy.

**Hai test cũ đổi theo hành vi đã sửa:**
- "A -> logout -> A while the first load waits": thả cổng trước khi chờ lần bind thứ hai, vì nay hai lần đọc cùng UID chạy tuần tự. Assertion giữ nguyên, đổi cách đếm `onChanged`.
- "history that cannot be read…": lỗi kéo dài thì không ghi đè, không xóa tin chờ. Hết lỗi thì lần drain sau đọc lại và lưu đủ.

**Native:** không chạy lại. Phần đổi nằm ở thứ tự đọc/lưu và xử lý lỗi đọc file, đã kiểm bằng test trên thư mục thật và khóa file thật. Kết quả AVD ở trên là của `ada76da`.


## PR #19 — CodeRabbit review, 08/11/2026

Sources: [PR reviews](https://github.com/ruxenb/LongvitaRC/pull/19/files).
The review IDs returned by GitHub are `PRR_kwDOVevJFc8AAAABWrwcRA` (08:46:02Z) and `PRR_kwDOVevJFc8AAAABWrx9sw` (08:54:22Z). Findings were in the review bodies, outside the diff; no inline threads existed.

| Finding | Decision | Result |
|---|---|---|
| PR19-CR-01, Minor: historical contract notes still call settled v1 decisions pending | Accepted | `5997e99` labels the historical table and reconciles old pending notes with the v1 contract |
| PR19-CR-02, Major: foreground arrival lost if history is unreadable until logout | Accepted | `dbf9511` stages accepted arrivals on disk; drain acknowledges only after history save; failed staging keeps unread history intact |
| PR19-CR-03, Major: legacy import gets fresh timestamps and evicts newer queue files | Accepted | Stable checkpoint gives legacy entries older chronological refs; shared 50-file cap retains newer messages |
| PR19-CR-04, Major: interrupted migration imports duplicates on retry | Accepted | Checkpoint precedes writes and reuses the same refs; migrations for one folder serialize across store instances |

Verification of production code `dbf9511` (run immediately before commit):

- Independent probes on old `5997e99`: **0/3 pass**, reproducing all three Major findings. [Before log](pr19-probes-before.txt).
- Original PM probes plus the three new probes on the fix: **6/6 pass**. [After log](pr19-probes-after.txt).
- Five new permanent regressions in `test/fcm/notification_review_persistence_test.dart`: foreground recovery after logout/restart; mixed-user queue at capacity; interrupted migration; concurrent stores; temporarily unreadable checkpoint. Together with history tests: **50/50 pass**.
- Full `flutter test --no-pub --reporter expanded`: **388/388 pass** (383 existing + 5 new).
- `flutter analyze --no-pub`: **no issues**. [Log](pr19-analyze.txt). `git diff --check`: clean.
- `flutter build apk --debug --no-pub`: success, APK SHA-256 `C07D4903ECB51A622BAC764DB6B0B7BDA44A9F886FB6D2C57FC9D357F7C26CBB`. Existing future Kotlin compatibility warnings from Analytics/Remote Config remain; no dependency upgrade.

One existing expectation was strengthened to require both the background message and the foreground arrival to remain pending while history cannot be read. Its original preservation/recovery assertions remain. During verification, full-suite checks initially reported that old expectation; it was updated to reflect the intended durable staging, then all tests passed. Analyzer warnings in an ignored PM probe were resolved only with local lint comments; app rules/config were not relaxed.

No new AVD/push run was performed for these filesystem fixes; the native matrix above remains evidence from `ada76da`, not this code. Disk persistence is conditional on successful file writes and the documented 50-message pending capacity. The change does not touch Auth API, routing, packages, Firebase configuration, billing or recipes.
