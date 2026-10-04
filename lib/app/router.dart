import 'package:go_router/go_router.dart';

import '../features/add_octo/add_octo_screen.dart';
import '../features/details/activity_screen.dart';
import '../features/details/details_screen.dart';
import '../features/details/rules_screen.dart';
import '../features/octos_list/octos_list_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/thread/thread_screen.dart';

GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const OctosListScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddOctoScreen(),
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
