import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/logger.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/auth_service.dart';
import '../../domain/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final localAuth = ref.watch(localAuthProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthService(localAuth, secureStorage);
});

class AuthState {
  final bool isInitialized;
  final bool isSupported;
  final bool isEnrolled;
  final bool isAuthenticated;
  final bool isKeyLost;
  final String? errorMessage;
  final DateTime? lastPausedTime;

  AuthState({
    this.isInitialized = false,
    this.isSupported = false,
    this.isEnrolled = false,
    this.isAuthenticated = true,
    this.isKeyLost = false,
    this.errorMessage,
    this.lastPausedTime,
  });

  AuthState copyWith({
    bool? isInitialized,
    bool? isSupported,
    bool? isEnrolled,
    bool? isAuthenticated,
    bool? isKeyLost,
    String? errorMessage,
    DateTime? lastPausedTime,
  }) {
    return AuthState(
      isInitialized: isInitialized ?? this.isInitialized,
      isSupported: isSupported ?? this.isSupported,
      isEnrolled: isEnrolled ?? this.isEnrolled,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isKeyLost: isKeyLost ?? this.isKeyLost,
      errorMessage: errorMessage ?? this.errorMessage,
      lastPausedTime: lastPausedTime ?? this.lastPausedTime,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    init();
    return AuthState();
  }

  Future<void> init() async {
    try {
      final supported = await _repository.isDeviceSupported();
      final enrolled = await _repository.isBiometricEnrolled();
      state = state.copyWith(
        isInitialized: true,
        isSupported: supported,
        isEnrolled: enrolled,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialized: true,
        errorMessage: 'Failed to initialize security hardware check.',
      );
    }
  }

  Future<void> authenticate() async {
    try {
      state = state.copyWith(errorMessage: null);
      final success = await _repository.authenticate();
      if (success) {
        state = state.copyWith(isAuthenticated: true);
      }
    } on AuthException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Authentication failed.');
    }
  }

  void lock() {
    state = state.copyWith(isAuthenticated: false);
  }

  void triggerKeyLostState() {
    state = state.copyWith(isKeyLost: true);
  }

  void resetKeyLostState() {
    state = state.copyWith(isKeyLost: false);
  }

  /// Called when the app is paused (backgrounded) to record the pause timestamp (EC-AS-05)
  void recordPause() {
    state = state.copyWith(lastPausedTime: DateTime.now());
  }

  /// Checks if the session timeout has expired on resume
  void checkTimeout() {
    final pausedTime = state.lastPausedTime;
    if (pausedTime == null || !state.isAuthenticated) return;

    final timeoutMinutes = ref.read(sessionTimeoutProvider);
    final elapsed = DateTime.now().difference(pausedTime);

    if (elapsed >= Duration(minutes: timeoutMinutes)) {
      AppLogger.i('Session timed out after ${elapsed.inMinutes} minutes. Lock applied.');
      lock();
    } else {
      AppLogger.d('Resuming session. No timeout expired.');
    }
    state = state.copyWith(lastPausedTime: null);
  }

  Future<Uint8List> loadEncryptionKey(bool dbExists) async {
    try {
      return await _repository.getOrCreateEncryptionKey(dbExists: dbExists);
    } on EncryptionException catch (e) {
      if (e.message == 'KEY_LOST') {
        triggerKeyLostState();
      }
      rethrow;
    }
  }

  Future<void> clearAllAndReset() async {
    await _repository.deleteKey();
    state = AuthState(
      isInitialized: state.isInitialized,
      isSupported: state.isSupported,
      isEnrolled: state.isEnrolled,
      isAuthenticated: true, // Auto-authenticate after reset
    );
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());
