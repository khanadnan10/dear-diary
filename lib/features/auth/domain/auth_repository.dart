import 'dart:typed_data';

abstract class AuthRepository {
  Future<bool> isDeviceSupported();
  Future<bool> isBiometricEnrolled();
  Future<bool> authenticate();
  Future<Uint8List> getOrCreateEncryptionKey({required bool dbExists});
  Future<void> deleteKey();
}
