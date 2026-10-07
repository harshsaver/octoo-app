import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../features/add_octo/add_octo_screen.dart';
import '../features/details/activity_screen.dart';
import '../features/details/details_screen.dart';
import '../features/details/rules_screen.dart';
import '../features/octos_list/octos_list_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../data/account_scope.dart';
import '../data/auth/auth_service.dart';
import '../features/thread/thread_screen.dart';

/// Re-runs the router's redirect whenever the signed-in account changes.
class AuthRefresh extends ChangeNotifier {
  AuthRefresh(this.auth) {
    _sub = auth.changes.listen((_) => notifyListeners());
  }

  final AuthService auth;
  late final StreamSubscription<Account?> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}

/// Signed out: only the welcome screen. Signed in: never the welcome screen.
/// `/auth-callback` is the sign-in return link (Supabase reads it itself).
GoRouter buildRouter(AuthService auth, AuthRefresh refresh) => GoRouter(
  refreshListenable: refresh,
  redirect: (context, state) {
    final signedIn = auth.current != null;
    final path = state.uri.path;
    if (path == '/auth-callback') return '/';
    if (!signedIn && path != '/welcome') return '/welcome';
    if (signedIn && path == '/welcome') return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(path: '/auth-callback', redirect: (context, state) => '/'),
    GoRoute(
      path: '/',
      builder: (context, state) => const OctosListScreen(),
      routes: [
        GoRoute(
          path: 'add',
          // Also Octo's own link: https://octo.october.dev/add#<id>.<secret>.
          builder: (context, state) => AddOctoScreen(
            initialPayload: state.uri.fragment.isEmpty
                ? null
                : 'https://octo.october.dev/add#${state.uri.fragment}',
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/octo/add',
      // The enrollment universal link: https://www.october.dev/octo/add#<id>.<secret>.
      // The secret stays in memory: it is passed to the screen, never stored.
      builder: (context, state) => AddOctoScreen(
        initialPayload: state.uri.fragment.isEmpty
            ? null
            : 'https://www.october.dev/octo/add#${state.uri.fragment}',
      ),
    ),
    GoRoute(
      path: '/octo/:id',
      builder: (context, state) =>
          ThreadScreen(computerId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'details',
          builder: (context, state) =>
              DetailsScreen(computerId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'rules',
              builder: (context, state) =>
                  RulesScreen(computerId: state.pathParameters['id']!),
            ),
            GoRoute(
              path: 'activity',
              builder: (context, state) =>
                  ActivityScreen(computerId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
