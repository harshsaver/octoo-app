import 'dart:io';

import 'package:path/path.dart' as p;

/// The signed-in family member. Stage 4 brings October sign-in; until then
/// fake mode has one local account.
class Account {
  const Account({required this.userId, required this.name});

  final String userId;

  /// Their first name, as helpers see it ("Harsh").
  final String name;

  static const fake = Account(userId: 'local', name: 'Harsh');
}

/// Where one account's files live. Each account has its own database and
/// screenshot folder (PLAN §3.9).
class AccountDirs {
  const AccountDirs({required this.support, required this.cache});

  /// `ApplicationSupport/<userId>/` — the database; excluded from backup.
  final Directory support;

  /// `Cache/<userId>/` — screenshots; the OS never backs it up.
  final Directory cache;

  factory AccountDirs.under({
    required Directory supportRoot,
    required Directory cacheRoot,
    required Account account,
  }) => AccountDirs(
    support: Directory(p.join(supportRoot.path, account.userId)),
    cache: Directory(p.join(cacheRoot.path, account.userId)),
  );

  File get databaseFile => File(p.join(support.path, 'octo.sqlite'));

  Directory get screenshots => Directory(p.join(cache.path, 'screenshots'));
}
