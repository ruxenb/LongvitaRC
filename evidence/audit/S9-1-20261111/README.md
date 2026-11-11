# S9-1 security audit — 11/11/2026

> Gitleaks 8.30.1, mọi scan dùng `--redact`. Không lưu hoặc chép giá trị
> credential/token vào báo cáo này.

## Cây hiện tại

Trước sanitize, Gitleaks phát hiện ba Firebase Storage download token trong
`evidence/artemis/raw/runs.jsonl`. File raw đã được làm sạch token, email, tên
người dùng và UID đường dẫn bằng `scripts/sanitize-artemis-evidence.mjs`.

Sau sanitize, các finding trong file được Git theo dõi gồm:

- Firebase client API key trong `mobile/android/app/google-services.json`.
- Firebase client API key trong `mobile/lib/firebase_options.dart`.
- Firebase client API key trong `web/lib/firebase_options.dart`.
- Một false positive `generic-api-key` tại
  `evidence/review/PR25-final-harness-20261110/verification.json`; giá trị là
  SHA-256 của source file, không phải credential.

Các finding tương tự trong `build/` và `.dart_tool/` là output generated, không
được Git theo dõi. Firebase client keys không được gọi là server secret, nhưng
vẫn cần API restrictions và Security Rules đúng trước khi đóng S9-1.

## Lịch sử Git

Full-history scan còn mười finding redacted:

- Ba Storage download token trong các commit raw ARTEMIS cũ.
- Firebase client configuration trong các đường dẫn trước và sau monorepo.
- Một Web build artifact lịch sử chứa Firebase client configuration.
- Một false positive SHA-256 của source.

Không rewrite lịch sử trong lượt này vì có thể phá commit/PR/evidence. Owner
Firebase cần xác minh hoặc revoke ba download token cũ và xác nhận restrictions
cho client keys. Sau đó chạy lại scan ngay trước S9-6.

## Kết luận

S9-1 vẫn **Đang làm**. Cây source hiện tại không còn Storage download token;
blocker còn lại thuộc lịch sử Git và cấu hình kiểm soát phía Firebase/Google
Cloud.
