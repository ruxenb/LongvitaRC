enum UploadFailureKind { network, denied, notConfigured, quota, cancelled, unknown }

/// Why a report did not reach Cloud Storage. The saved file stays on the device
/// in every case, so the same export can be uploaded again.
class UploadFailure implements Exception {
  final UploadFailureKind kind;
  final String? code;
  final Object? cause;

  const UploadFailure(this.kind, {this.code, this.cause});

  @override
  String toString() => 'UploadFailure(${kind.name}, $code)';
}
