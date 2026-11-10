import 'package:cloud_firestore/cloud_firestore.dart';

enum DataFailureKind {
  offline,
  permission,
  unavailable,
  invalid,
  notFound,
  unknown,
}

/// User-facing data-layer error. SDK exceptions must not leak into UI.
class DataFailure implements Exception {
  final DataFailureKind kind;
  final String message;
  final Object? cause;

  const DataFailure(this.kind, this.message, [this.cause]);

  factory DataFailure.from(Object error) {
    if (error is DataFailure) return error;
    if (error is FirebaseException) {
      switch (error.code) {
        case 'unavailable':
        case 'deadline-exceeded':
          return DataFailure(
            DataFailureKind.offline,
            'Không thể kết nối dữ liệu. Kiểm tra mạng rồi thử lại.',
            error,
          );
        case 'permission-denied':
        case 'unauthenticated':
          return DataFailure(
            DataFailureKind.permission,
            'Bạn chưa có quyền thực hiện thao tác. Hãy đăng nhập lại.',
            error,
          );
        case 'not-found':
          return DataFailure(
            DataFailureKind.notFound,
            'Dữ liệu không còn tồn tại. Hãy tải lại.',
            error,
          );
        case 'failed-precondition':
          return DataFailure(
            DataFailureKind.invalid,
            'Dữ liệu đã thay đổi hoặc chưa sẵn sàng. Hãy thử lại.',
            error,
          );
      }
    }
    return DataFailure(
      DataFailureKind.unknown,
      'Có lỗi khi tải hoặc lưu dữ liệu. Hãy thử lại.',
      error,
    );
  }

  @override
  String toString() => 'DataFailure(${kind.name}): $message';
}
