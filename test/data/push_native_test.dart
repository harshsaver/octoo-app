import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/app/config.dart';
import 'package:octo_family/data/backend/octo_backend.dart';
import 'package:octo_family/data/push/apns_push.dart';
import 'package:octo_family/data/push/push_registrar.dart';
import 'package:octo_family/data/push/push_service.dart' as octo;
import 'package:octo_family/data/push/unified_push.dart';
import 'package:unifiedpush/unifiedpush.dart';
import 'package:unifiedpush_platform_interface/data/public_key_set.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnifiedPush (Android, ntfy)', () {
    test("the endpoint becomes October's token: endpoint and keys, base64url without padding", () {
      final token = webPushToken(
        PushEndpoint('https://ntfy.sh/upAbC?up=1', PublicKeySet('BCVx+r7N/eNg==', 'BTBZ+qHH/r4=')),
      );
      expect(jsonDecode(token!), {'endpoint': 'https://ntfy.sh/upAbC?up=1', 'p256dh': 'BCVx-r7N_eNg', 'auth': 'BTBZ-qHH_r4'});
      // Without Web Push keys the backend would refuse it: nothing to register.
      expect(webPushToken(PushEndpoint('https://ntfy.sh/up', null)), isNull);
    });

    test('a decrypted push is read like any other; one that failed to decrypt is dropped', () {
      final content = Uint8List.fromList(utf8.encode(jsonEncode({'computerId': 'cmp_1', 'kind': 'help', 'title': 'Mom needs a hand'})));
      final push = decodePush(PushMessage(content, true))!;
      expect((push.computerId, push.kind, push.title), ('cmp_1', 'help', 'Mom needs a hand'));
      expect(decodePush(PushMessage(content, false)), isNull);
      expect(decodePush(PushMessage(Uint8List.fromList([1, 2]), true)), isNull);
    });

    test('Android registers as unifiedpush, iOS as ios', () {
      final registrar = PushRegistrar(push: octo.NoPush(), backend: FakeBackend(), deviceLabel: 'phone', appVersion: null);
      expect(registrar.platform, 'unifiedpush'); // tests run as Android
    });
  });

  group('APNs (iOS)', () {
    const channel = MethodChannel('dev.october.octo/push');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <String>[];

    setUp(() {
      calls.clear();
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return switch (call.method) {
          'pendingTaps' => [
            {'computerId': 'cmp_cold', 'kind': 'help'},
          ],
          'token' => 'abc123',
          'requestPermission' => true,
          _ => null,
        };
      });
    });
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    Future<void> fromNative(String method, Object? args) => messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
      (_) {},
    );

    test('token, taps (including the one that launched the app) and arrivals come from the native bridge', () async {
      final push = ApnsPushService(setUpLocal: (_) async {});
      final taps = <octo.PushMessage>[], arrivals = <octo.PushMessage>[], tokens = <String>[];
      push.taps.listen(taps.add);
      push.foreground.listen(arrivals.add);
      push.tokenRefresh.listen(tokens.add);
      await push.start();
      await Future<void>.delayed(Duration.zero);
      expect(taps.single.computerId, 'cmp_cold');

      expect(await push.requestPermission(), isTrue);
      expect(await push.token(), 'abc123');
      await fromNative('token', 'def456');
      await fromNative('tap', {'computerId': 'cmp_2', 'kind': 'todo', 'taskId': 't1'});
      await fromNative('foreground', {'computerId': 'cmp_3', 'kind': 'taskEnded', 'title': 'Octo finished'});
      // Not October's: ignored.
      await fromNative('tap', {'something': 'else'});
      expect(tokens, ['def456']);
      expect(taps.map((t) => t.computerId), ['cmp_cold', 'cmp_2']);
      expect(arrivals.single.title, 'Octo finished');
      expect(calls, containsAll(['pendingTaps', 'requestPermission', 'token']));
      await push.dispose();
    });
  });

  test("config: OCTO_PUSH is 'on' or empty (Firebase is gone)", () {
    final base = {'OCTO_MODE': 'fake'};
    expect((parseConfig({...base, 'OCTO_PUSH': 'on'}, isRelease: false) as ConfigOk).config.pushEnabled, isTrue);
    expect((parseConfig(base, isRelease: false) as ConfigOk).config.pushEnabled, isFalse);
    expect(parseConfig({...base, 'OCTO_PUSH': 'firebase'}, isRelease: false), isA<ConfigProblem>());
  });
}
