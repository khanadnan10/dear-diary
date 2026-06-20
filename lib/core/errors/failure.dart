abstract class Failure {
  final String message;
  Failure(this.message);

  @override
  String toString() => message;
}

class StorageFailure extends Failure {
  StorageFailure(super.message);
}

class AudioFailure extends Failure {
  AudioFailure(super.message);
}

class AuthFailure extends Failure {
  AuthFailure(super.message);
}

class EncryptionFailure extends Failure {
  EncryptionFailure(super.message);
}

class PermissionFailure extends Failure {
  PermissionFailure(super.message);
}
