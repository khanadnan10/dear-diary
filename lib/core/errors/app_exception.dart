abstract class AppException implements Exception {
  final String message;
  final String? technicalDetail;

  AppException(this.message, [this.technicalDetail]);

  @override
  String toString() => 'AppException: $message (${technicalDetail ?? ''})';
}

class StorageException extends AppException {
  StorageException(super.message, [super.technicalDetail]);
}

class AudioException extends AppException {
  AudioException(super.message, [super.technicalDetail]);
}

class AuthException extends AppException {
  AuthException(super.message, [super.technicalDetail]);
}

class EncryptionException extends AppException {
  EncryptionException(super.message, [super.technicalDetail]);
}

class PermissionException extends AppException {
  PermissionException(super.message, [super.technicalDetail]);
}
