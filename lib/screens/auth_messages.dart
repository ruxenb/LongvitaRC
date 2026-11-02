import '../models/auth_state.dart';

/// User-facing copy for each [AuthFailureKind]. Kept in one place so the
/// wording (pending DEC-05 on UI language) changes in one file.
class AuthMessages {
  AuthMessages._();

  static String signInNotice(AuthFailure failure) => switch (failure.kind) {
        AuthFailureKind.cancelled =>
          'Bạn đã đóng cửa sổ chọn tài khoản. Đăng nhập lại khi bạn sẵn sàng.',
        AuthFailureKind.network =>
          'Không có kết nối mạng. Kiểm tra mạng rồi thử lại.',
        AuthFailureKind.configuration =>
          'Thiết bị này chưa được cấu hình đăng nhập Google cho Longvita. '
              'Vui lòng báo nhóm phát triển.',
        AuthFailureKind.credential =>
          'Google chưa xác nhận được tài khoản này. '
              'Thử lại hoặc chọn tài khoản khác.',
        AuthFailureKind.profileRead ||
        AuthFailureKind.profileWrite ||
        AuthFailureKind.unknown =>
          'Đăng nhập chưa thành công. Vui lòng thử lại.',
      };

  static String profileErrorTitle(AuthFailure failure) =>
      failure.kind == AuthFailureKind.profileWrite
          ? 'Chưa tạo được hồ sơ'
          : 'Chưa tải được hồ sơ';

  static String profileErrorMessage(AuthFailure failure) =>
      switch (failure.kind) {
        AuthFailureKind.network =>
          'Bạn đã đăng nhập, nhưng mất kết nối khi tải hồ sơ Longvita. '
              'Kiểm tra mạng rồi thử lại.',
        AuthFailureKind.profileWrite =>
          'Bạn đã đăng nhập, nhưng hồ sơ Longvita chưa được tạo. '
              'Thử lại, hoặc đăng xuất rồi đăng nhập lại.',
        _ => 'Bạn đã đăng nhập, nhưng hồ sơ Longvita chưa tải được. '
            'Thử lại, hoặc đăng xuất rồi đăng nhập lại.',
      };
}
