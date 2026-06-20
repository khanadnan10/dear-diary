import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/settings_repository_impl.dart';
import '../../domain/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return SettingsRepositoryImpl(secureStorage);
});

class ThemeNotifier extends Notifier<ThemeMode> {
  late final SettingsRepository _repository;

  @override
  ThemeMode build() {
    _repository = ref.watch(settingsRepositoryProvider);
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    state = await _repository.getThemeMode();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _repository.setThemeMode(mode);
    state = mode;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() => ThemeNotifier());

class SessionTimeoutNotifier extends Notifier<int> {
  late final SettingsRepository _repository;

  @override
  int build() {
    _repository = ref.watch(settingsRepositoryProvider);
    _load();
    return 5;
  }

  Future<void> _load() async {
    state = await _repository.getSessionTimeoutMinutes();
  }

  Future<void> setTimeout(int minutes) async {
    await _repository.setSessionTimeoutMinutes(minutes);
    state = minutes;
  }
}

final sessionTimeoutProvider = NotifierProvider<SessionTimeoutNotifier, int>(() => SessionTimeoutNotifier());

class ScreenshotPreventionNotifier extends Notifier<bool> {
  late final SettingsRepository _repository;

  @override
  bool build() {
    _repository = ref.watch(settingsRepositoryProvider);
    _load();
    return true;
  }

  Future<void> _load() async {
    state = await _repository.getScreenshotPreventionEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    await _repository.setScreenshotPreventionEnabled(enabled);
    state = enabled;
  }
}

final screenshotPreventionProvider = NotifierProvider<ScreenshotPreventionNotifier, bool>(() => ScreenshotPreventionNotifier());
