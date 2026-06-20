import 'package:flutter/material.dart';

abstract class SettingsRepository {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);

  Future<int> getSessionTimeoutMinutes();
  Future<void> setSessionTimeoutMinutes(int minutes);

  Future<bool> getScreenshotPreventionEnabled();
  Future<void> setScreenshotPreventionEnabled(bool enabled);
}
