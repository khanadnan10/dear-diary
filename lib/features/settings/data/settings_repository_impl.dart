import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final FlutterSecureStorage _secureStorage;

  SettingsRepositoryImpl(this._secureStorage);

  @override
  Future<ThemeMode> getThemeMode() async {
    try {
      final value = await _secureStorage.read(key: AppConstants.keyThemeMode);
      if (value == null) return ThemeMode.system;
      switch (value) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        default:
          return ThemeMode.system;
      }
    } catch (_) {
      return ThemeMode.system;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      default:
        value = 'system';
    }
    await _secureStorage.write(key: AppConstants.keyThemeMode, value: value);
  }

  @override
  Future<int> getSessionTimeoutMinutes() async {
    try {
      final value = await _secureStorage.read(key: AppConstants.keySessionTimeout);
      if (value == null) return AppConstants.defaultSessionTimeoutMinutes;
      return int.tryParse(value) ?? AppConstants.defaultSessionTimeoutMinutes;
    } catch (_) {
      return AppConstants.defaultSessionTimeoutMinutes;
    }
  }

  @override
  Future<void> setSessionTimeoutMinutes(int minutes) async {
    await _secureStorage.write(
      key: AppConstants.keySessionTimeout,
      value: minutes.toString(),
    );
  }

  @override
  Future<bool> getScreenshotPreventionEnabled() async {
    try {
      final value = await _secureStorage.read(key: AppConstants.keyScreenshotPrevention);
      if (value == null) return AppConstants.defaultScreenshotPrevention;
      return value == 'true';
    } catch (_) {
      return AppConstants.defaultScreenshotPrevention;
    }
  }

  @override
  Future<void> setScreenshotPreventionEnabled(bool enabled) async {
    await _secureStorage.write(
      key: AppConstants.keyScreenshotPrevention,
      value: enabled.toString(),
    );
  }
}
