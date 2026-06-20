class AppConstants {
  // Secure Storage Keys
  static const String keyEncryptionKey = 'diary_encryption_key';
  static const String keyThemeMode = 'theme_mode';
  static const String keySessionTimeout = 'session_timeout_minutes';
  static const String keyScreenshotPrevention = 'screenshot_prevention';

  // Defaults
  static const int defaultSessionTimeoutMinutes = 5;
  static const bool defaultScreenshotPrevention = true;
  static const String defaultThemeMode = 'system';

  // Paths
  static const String audioDirectoryName = 'audio';
  static const String nomediaFileName = '.nomedia';
  static const String isarDatabaseFileName = 'diary';

  // UI
  static const double maxTabletWidth = 600.0;
  static const double maxContentWidth = 720.0;
}
