import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app_theme.dart';
import '../../../core/utils/logger.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../presentation/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _securityChannel = MethodChannel('com.deardiary/security');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    
    final timeoutMinutes = ref.watch(sessionTimeoutProvider);
    final timeoutNotifier = ref.read(sessionTimeoutProvider.notifier);
    
    final screenshotPrevention = ref.watch(screenshotPreventionProvider);
    final screenshotNotifier = ref.read(screenshotPreventionProvider.notifier);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            _buildSectionHeader(context, 'Security & Privacy'),
            
            // Screenshot Prevention Toggle
            _buildCard(
              context,
              child: SwitchListTile.adaptive(
                title: const Text('Prevent Screenshots', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('Block screenshots and hide diary content in multitasking view.'),
                value: screenshotPrevention,
                activeColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                onChanged: (val) async {
                  await screenshotNotifier.setEnabled(val);
                  try {
                    if (Platform.isAndroid) {
                      await _securityChannel.invokeMethod('setSecureMode', {'enabled': val});
                      AppLogger.i('Screenshot prevention flag updated: $val');
                    }
                  } catch (e) {
                    AppLogger.e('Error applying screenshot prevention flag', e);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // Timeout Duration
            _buildCard(
              context,
              child: ListTile(
                title: const Text('Session Lock Timeout', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('Lock the app after $timeoutMinutes minutes in background.'),
                trailing: DropdownButton<int>(
                  value: timeoutMinutes,
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val != null) {
                      timeoutNotifier.setTimeout(val);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 min')),
                    DropdownMenuItem(value: 5, child: Text('5 min')),
                    DropdownMenuItem(value: 15, child: Text('15 min')),
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(context, 'Appearance'),
            
            // Theme selector
            _buildCard(
              context,
              child: ListTile(
                title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(_getThemeLabel(themeMode)),
                trailing: DropdownButton<ThemeMode>(
                  value: themeMode,
                  underline: const SizedBox(),
                  onChanged: (val) {
                    if (val != null) {
                      themeNotifier.setThemeMode(val);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: ThemeMode.system, child: Text('System Default')),
                    DropdownMenuItem(value: ThemeMode.light, child: Text('Light Theme')),
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark Theme')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(context, 'System'),
            
            // Clear All Data
            _buildCard(
              context,
              child: ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.alertColor),
                title: const Text('Factory Reset Diary', style: TextStyle(color: AppTheme.alertColor, fontWeight: FontWeight.bold)),
                subtitle: const Text('Delete all encryption keys, journal entries, and voice recordings permanently.'),
                onTap: () => _confirmFactoryReset(context, ref),
              ),
            ),
            const SizedBox(height: 32),

            Center(
              child: Text(
                'Dear Diary v1.0.0 • Privacy-First',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: child,
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light (warm off-white)';
      case ThemeMode.dark:
        return 'Dark (soft charcoal)';
      case ThemeMode.system:
        return 'Follow System Settings';
    }
  }

  void _confirmFactoryReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Factory Reset?'),
        content: const Text(
          'This is extremely serious. This will permanently delete your AES-256-GCM encryption key and erase your entire diary. There is absolutely NO backup. You will never be able to recover your entries.',
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
              AppLogger.w('Factory reset complete. Database and keys wiped.');
              if (context.mounted) {
                context.go('/lock');
              }
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }
}
