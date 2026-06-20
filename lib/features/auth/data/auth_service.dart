import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../domain/auth_repository.dart';

class AuthService implements AuthRepository {
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;
  bool _isAuthInProgress = false;

  AuthService(this._localAuth, this._secureStorage);

  @override
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e, stack) {
      AppLogger.e('Error checking device support', e, stack);
      return false;
    }
  }

  @override
  Future<bool> isBiometricEnrolled() async {
    try {
      return await _localAuth.canCheckBiometrics &&
          (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (e, stack) {
      AppLogger.e('Error checking biometrics enrollment', e, stack);
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    if (_isAuthInProgress) {
      AppLogger.d('Auth already in progress, ignoring duplicate request');
      return false;
    }

    _isAuthInProgress = true;
    try {
      final hasEnrolled = await isBiometricEnrolled();
      final deviceSupported = await isDeviceSupported();

      if (!deviceSupported) {
        throw AuthException('DEVICE_NOT_SUPPORTED', 'Device does not support secure lock screens.');
      }

      final success = await _localAuth.authenticate(
        localizedReason: 'Unlock your diary to read and write entries',
        biometricOnly: false, // Allows PIN/pattern fallback
      );

      return success;
    } on PlatformException catch (e) {
      // Keystore or Keychain reset / invalidation can throw PlatformExceptions
      if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        throw AuthException('OS_LOCKOUT', 'Too many attempts. Locked out by OS.');
      }
      throw AuthException('AUTH_PLATFORM_ERROR', e.message ?? e.toString());
    } finally {
      _isAuthInProgress = false;
    }
  }

  @override
  Future<Uint8List> getOrCreateEncryptionKey({required bool dbExists}) async {
    try {
      final exists = await _secureStorage.containsKey(key: AppConstants.keyEncryptionKey);

      if (dbExists) {
        if (!exists) {
          // EC-AS-03: DB exists but key is lost! Key was wiped by Keystore or user cleared secure storage
          AppLogger.w('DB exists but encryption key is missing! Key lost scenario.');
          throw EncryptionException('KEY_LOST', 'The encryption key was reset or lost by the OS.');
        } else {
          // Key exists and DB exists - happy path
          final base64Key = await _secureStorage.read(key: AppConstants.keyEncryptionKey);
          if (base64Key == null) {
            throw EncryptionException('KEY_READ_FAILED', 'Failed to read encryption key.');
          }
          return base64.decode(base64Key);
        }
      } else {
        // DB does not exist
        if (exists) {
          // EC-AS-04: DB is empty but key exists (iOS Keychain survival after uninstall)
          // Treat as first launch: delete stale key and generate fresh one
          AppLogger.i('DB is empty but stale key exists. Discarding stale key.');
          await deleteKey();
        }

        // Create fresh key
        final keyBytes = _generateSecureRandomBytes(32);
        final base64Key = base64.encode(keyBytes);
        await _secureStorage.write(key: AppConstants.keyEncryptionKey, value: base64Key);
        AppLogger.i('Successfully generated and stored a brand-new 256-bit AES encryption key.');
        return keyBytes;
      }
    } on PlatformException catch (e) {
      AppLogger.e('Platform exception in getOrCreateEncryptionKey', e);
      // EC-PL-04: OS upgrade/patch invalidates Keystore
      throw EncryptionException('KEYSTORE_ERROR', e.message ?? 'Platform Keystore access failed');
    } catch (e, stack) {
      if (e is EncryptionException) rethrow;
      AppLogger.e('Error getting/creating encryption key', e, stack);
      throw EncryptionException('KEY_GEN_FAILED', e.toString());
    }
  }

  @override
  Future<void> deleteKey() async {
    await _secureStorage.delete(key: AppConstants.keyEncryptionKey);
  }

  Uint8List _generateSecureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }
}
