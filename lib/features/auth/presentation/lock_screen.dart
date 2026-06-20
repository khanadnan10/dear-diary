import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/logger.dart';
import 'providers/auth_provider.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    // Trigger biometric prompt automatically on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoAuth();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _attemptAutoAuth() {
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated && !authState.isKeyLost) {
      ref.read(authStateProvider.notifier).authenticate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Minimal icon indicating security
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 64,
                      color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Dear Diary',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'serif',
                            fontSize: 28,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your quiet space',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),

                    // Main lock states and feedback
                    if (authState.isKeyLost)
                      _buildKeyLostUI(context)
                    else if (authState.isInitialized && !authState.isSupported)
                      _buildUnsupportedHardwareUI(context)
                    else
                      _buildStandardUnlockUI(context, authState),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardUnlockUI(BuildContext context, AuthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        if (state.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.alertColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              state.errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.alertColor,
                  ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        ElevatedButton.icon(
          onPressed: () => ref.read(authStateProvider.notifier).authenticate(),
          icon: const Icon(Icons.fingerprint_rounded),
          label: const Text('Unlock Diary'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 50),
            backgroundColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            foregroundColor: isDark ? AppTheme.darkBg : Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            // Re-trigger standard auth prompt (allows OS PIN fallback)
            ref.read(authStateProvider.notifier).authenticate();
          },
          child: const Text('Use PIN / Pattern'),
        ),
      ],
    );
  }

  Widget _buildUnsupportedHardwareUI(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.warning_amber_rounded, size: 48, color: AppTheme.alertColor),
        const SizedBox(height: 16),
        Text(
          'Lock Screen Required',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.alertColor,
              ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Dear Diary requires a device lock screen to protect your entries. Please set one up in your device settings.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            // Re-check security state
            ref.read(authStateProvider.notifier).init();
          },
          child: const Text('Check Settings'),
        ),
      ],
    );
  }

  Widget _buildKeyLostUI(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.alertColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.alertColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_reset_rounded, size: 48, color: AppTheme.alertColor),
          const SizedBox(height: 16),
          Text(
            'Encryption Key Wiped',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.alertColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your diary's encryption key was reset by your device. Unfortunately, your previous entries can no longer be read. You can start fresh.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
                  // Keep old data: go to a locked empty state or keep old entries on disk
                  ref.read(authStateProvider.notifier).resetKeyLostState();
                },
                child: const Text('Keep Old Data'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.alertColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _confirmReset(context),
                child: const Text('Delete & Start Fresh'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Reset?'),
        content: const Text(
          'This will permanently delete all existing entries and recordings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).clearAllAndReset();
              AppLogger.i('App storage and keys reset initiated.');
            },
            child: const Text('Confirm Reset'),
          ),
        ],
      ),
    );
  }
}
