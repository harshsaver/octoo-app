import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/app_settings.dart';
import 'app/config.dart';
import 'data/account_scope.dart';
import 'data/auth/supabase_auth.dart';
import 'data/push/unified_push.dart';

/// `--dart-define-from-file=config/fake.json` runs the simulator;
/// `config/real.json` (untracked) signs in with October. A release build
/// refuses fake mode (see `tool/check_release_config.dart`).
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android started Dart only to show a push that arrived while the app
  // wasn't running (UnifiedPush): show it, no UI.
  if (args.contains('--unifiedpush-bg')) {
    await UnifiedPushService.background();
    return;
  }
  final result = configFromEnvironment(isRelease: kReleaseMode);
  final prefs = await SharedPreferences.getInstance();
  final roots = AppRoots(
    support: await getApplicationSupportDirectory(),
    cache: await getApplicationCacheDirectory(),
  );
  if (result case ConfigOk(:final config) when !config.isFake) {
    await SupabaseAuth.initialize(
      url: config.supabaseUrl.toString(),
      anonKey: config.supabaseAnonKey!,
    );
  }
  runApp(
    buildApp(
      result,
      roots: roots,
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    ),
  );
}
