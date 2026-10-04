import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app/app.dart';
import 'app/config.dart';
import 'data/account_scope.dart';

/// Run with `--dart-define-from-file=config/fake.json` for the simulator.
/// A release build refuses fake mode (see `tool/check_release_config.dart`).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = configFromEnvironment(isRelease: kReleaseMode);
  final Directory supportRoot = await getApplicationSupportDirectory();
  final Directory cacheRoot = await getApplicationCacheDirectory();
  runApp(
    buildApp(
      config,
      dirs: AccountDirs.under(
        supportRoot: supportRoot,
        cacheRoot: cacheRoot,
        account: Account.fake,
      ),
    ),
  );
}
