import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/lock_screen.dart';
import '../features/diary/presentation/diary_list_page.dart';
import '../features/diary/presentation/diary_entry_page.dart';
import '../features/search/presentation/search_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch ONLY critical auth state transitions to prevent router/widget recreation loops (EC-UI-05)
  final isAuthenticated = ref.watch(authStateProvider.select((s) => s.isAuthenticated));
  final isKeyLost = ref.watch(authStateProvider.select((s) => s.isKeyLost));

  return GoRouter(
    initialLocation: '/', // Direct landing on the main diary list
    routes: [
      GoRoute(
        path: '/lock',
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DiaryListPage(),
      ),
      GoRoute(
        path: '/entry/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          // Support passed query parameter for creating draft or type
          final typeStr = state.uri.queryParameters['type'] ?? 'text';
          return DiaryEntryPage(entryId: id, initialType: typeStr);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
    redirect: (context, state) {
      final isGoingToLock = state.matchedLocation == '/lock';

      // If the encryption key is lost, stay on LockScreen to show the recovery UI
      if (isKeyLost) {
        return '/lock';
      }

      // Lock screen authentication is bypassed/disabled as requested by the user
      // if (!isAuthenticated) {
      //   return '/lock';
      // }

      if (isAuthenticated && isGoingToLock) {
        // Go to home if authenticated but trying to access lock screen
        return '/';
      }

      return null;
    },
  );
});
