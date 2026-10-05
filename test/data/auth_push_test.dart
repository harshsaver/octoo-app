import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/data/account_scope.dart';
import 'package:octo_family/data/auth/auth_service.dart';
import 'package:octo_family/data/backend/octo_backend.dart';
import 'package:octo_family/data/push/push_registrar.dart';
import 'package:octo_family/data/push/push_service.dart';
import 'package:octo_family/data/sign_out.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Push extends NoPush {
  _Push(this._token);

  String? _token;
  final _refresh = StreamController<String>.broadcast();

  @override
  Future<String?> token() async => _token;

  @override
  Stream<String> get tokenRefresh => _refresh.stream;

  void rotate(String token) {
    _token = token;
    _refresh.add(token);
  }
}

void main() {
  test('push payloads: only Octo kinds with a computer route anywhere', () {
    final push = PushMessage.fromData({
      'computerId': 'cmp_1',
      'kind': 'help',
      'taskId': '',
      'title': 'Mom needs a hand',
    });
    expect(
      (push!.computerId, push.kind, push.taskId, push.title),
      ('cmp_1', 'help', null, 'Mom needs a hand'),
    );
    expect(
      PushMessage.fromData({'computerId': 'cmp_1', 'kind': 'promo'}),
      isNull,
    );
    expect(PushMessage.fromData({'kind': 'help'}), isNull);
    expect(PushMessage.fromData(push.toData())!.title, 'Mom needs a hand');
  });

  test(
    'registers on sign-in and on rotation; unregisters before sign-out',
    () async {
      final backend = FakeBackend();
      final push = _Push('token-1');
      final registrar = PushRegistrar(
        push: push,
        backend: backend,
        deviceLabel: "Harsh's Pixel",
        appVersion: '1.0',
        platform: 'android',
      );
      await registrar.register();
      expect(backend.pushTokens, {'token-1'});
      push.rotate('token-2');
      await Future<void>.delayed(Duration.zero);
      expect(backend.pushTokens, {'token-1', 'token-2'});
      await registrar.unregister();
      expect(backend.pushTokens, {
        'token-1',
      }, reason: 'the current token is removed');
      // No push available: nothing to register, nothing breaks.
      final none = PushRegistrar(
        push: NoPush(),
        backend: backend,
        deviceLabel: 'x',
        appVersion: null,
        platform: 'ios',
      );
      await none.register();
      await none.unregister();
    },
  );

  test('a backend error while registering is kept quiet', () async {
    final backend = FakeBackend()
      ..failNext = const BackendException('unavailable', 'x');
    final registrar = PushRegistrar(
      push: _Push('t'),
      backend: backend,
      deviceLabel: 'x',
      appVersion: null,
      platform: 'ios',
    );
    await registrar.register();
    expect(registrar.registeredToken, isNull);
  });

  test('a sign-out interrupted midway is finished at the next start', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final root = Directory.systemTemp.createTempSync('octo-wipe-');
    final dirs = AccountDirs.under(
      supportRoot: root,
      cacheRoot: root,
      account: Account.fake,
    );
    await dirs.support.create(recursive: true);
    File('${dirs.support.path}/octo.sqlite').writeAsStringSync('x');
    await prefs.setStringList(pendingWipeKey, [dirs.support.path]);
    await wipePending(prefs);
    expect(dirs.support.existsSync(), isFalse);
    expect(prefs.getStringList(pendingWipeKey), isNull);
    root.deleteSync(recursive: true);
  });

  test('fake sign-in: email code, Google, sign out', () async {
    final auth = FakeAuth(signedIn: false);
    final seen = <Account?>[];
    final sub = auth.changes.listen(seen.add);
    expect(await auth.accessToken(), isNull);
    await expectLater(
      auth.sendEmailLink('nope'),
      throwsA(isA<AuthException>()),
    );
    await auth.verifyEmailCode('a@b.c', '123456');
    expect(await auth.accessToken(), 'fake-token');
    await auth.signOut();
    await auth.signInWithGoogle();
    await Future<void>.delayed(Duration.zero);
    expect(seen.map((a) => a?.name), ['Harsh', null, 'Harsh']);
    await sub.cancel();
  });
}
