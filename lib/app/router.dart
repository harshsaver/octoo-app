import 'package:go_router/go_router.dart';

import '../features/add_octo/add_octo_screen.dart';
import '../features/octos_list/octos_list_screen.dart';
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
    ),
  ],
);
