import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/data/policy_edit.dart';
import 'package:octo_family/data/screenshot_store.dart';
import 'package:octo_family/data/session/computer_session.dart';
import 'package:octo_family/data/session/session_store.dart';
import 'package:octo_family/protocol/models/policy.dart';
import 'package:octo_family/transport/octo_link.dart';
import 'package:octo_family/transport/simulator/simulated_computer.dart';
import 'package:octo_family/transport/simulator/simulator_link.dart';

import 'dart:io';

void main() {
  group('diff', () {
    test('tightening and loosening, item by item', () {
      const active = Policy(
        askEveryChange: true,
        never: ['install'],
        blockedSites: ['facebook.com'],
      );
      const proposed = Policy(
        askEveryChange: false, // loosen
        askBeforeLooking: true, // tighten
        never: ['delete'], // install removed (loosen), delete added (tighten)
        blockedSites: ['facebook.com', 'tiktok.com'], // site added (tighten)
      );
      expect(diffPolicy(active, proposed), {
        PolicyItems.askEveryChange: PolicyChange.loosen,
        PolicyItems.askBeforeLooking: PolicyChange.tighten,
        PolicyItems.never('install'): PolicyChange.loosen,
        PolicyItems.never('delete'): PolicyChange.tighten,
        PolicyItems.site('tiktok.com'): PolicyChange.tighten,
      });
      expect(diffPolicy(active, active), isEmpty);
    });

    test('pending items clear only when her computer reports them', () {
      const active = Policy(never: ['install']);
      const proposed = Policy(askBeforeLooking: true);
      final edit = PolicyEdit(
        proposed: proposed,
        pending: diffPolicy(active, proposed),
        startedAt: 0,
      );
      // Tightening applied, loosening still waiting.
      final half = edit.after(
        const Policy(askBeforeLooking: true, never: ['install']),
        declined: false,
      )!;
      expect(half.pending, {PolicyItems.never('install'): PolicyChange.loosen});
      // She approves.
      expect(half.after(proposed, declined: false), isNull);
      // Or she keeps the old rule.
      expect(
        half.after(
          const Policy(askBeforeLooking: true, never: ['install']),
          declined: true,
        ),
        isNull,
      );
    });
  });

  group('session', () {
    final shots = ScreenshotStore(
      Directory.systemTemp.createTempSync('octo-p-'),
    );

    late SimulatorLink link;
    late ComputerSession s;

    void connect(FakeAsync async, {Policy policy = const Policy()}) {
      link = SimulatorLink(
        settings: SimulatorSettings(autopilot: false),
        random: Random(9),
      );
      final events = <PairingProgress>[];
      link
          .pair('octo-sim:x', helperName: 'Harsh', deviceLabel: 'p')
          .listen(events.add);
      async.elapse(const Duration(seconds: 1));
      events.whereType<PairingCompareCode>().single.confirm(true);
      async.elapse(const Duration(seconds: 1));
      link.pairingComputer!.momSaysOk();
      async.elapse(const Duration(seconds: 1));
      final id = events.whereType<PairingPaired>().single.computer.computerId;
      link.computer(id)!.policy = policy;
      s = ComputerSession(
        computerId: id,
        link: link,
        store: MemorySessionStore(),
        shots: shots,
      );
      s.open();
      s.connect();
      async.elapse(const Duration(seconds: 2));
    }

    test('a mixed edit: tightened items apply, loosened wait for her', () {
      fakeAsync((async) {
        connect(async, policy: const Policy(never: ['install']));
        PolicySetOutcome? outcome;
        s
            .setPolicy(const Policy(askBeforeLooking: true))
            .then((o) => outcome = o);
        async.flushMicrotasks();
        expect(
          s.data.policyEdit!.pending.length,
          2,
          reason: 'nothing applied optimistically',
        );
        expect(s.data.policy?.askBeforeLooking ?? false, isFalse);

        async.elapse(const Duration(seconds: 1));
        expect(outcome, isA<PolicySent>());
        expect(
          s.data.policy!.askBeforeLooking,
          isTrue,
          reason: 'tightened, reported',
        );
        expect(s.data.policyEdit!.pending, {
          PolicyItems.never('install'): PolicyChange.loosen,
        });

        // A second edit waits for the first.
        PolicySetOutcome? second;
        s.setPolicy(const Policy()).then((o) => second = o);
        async.flushMicrotasks();
        expect(second, isA<PolicyNotSent>());

        link.computer(s.computerId)!.momSaysOk(kind: ConsentKind.policy);
        async.elapse(const Duration(seconds: 1));
        expect(s.data.policyEdit, isNull);
        expect(s.data.policy!.never, isEmpty);
        s.dispose();
        async.flushMicrotasks();
      });
    });

    test('she keeps the old rule', () {
      fakeAsync((async) {
        connect(async);
        s.setPolicy(const Policy(askEveryChange: false));
        async.elapse(const Duration(seconds: 1));
        expect(s.data.policyEdit!.pending.values.single, PolicyChange.loosen);
        link.computer(s.computerId)!.momSaysNo();
        async.elapse(const Duration(seconds: 1));
        expect(s.data.policyEdit, isNull);
        expect(s.data.policy!.askEveryChange, isTrue);
        expect(s.data.policyDeclinedAt, isNotNull);
        s.dispose();
        async.flushMicrotasks();
      });
    });

    test('offline: not sent, nothing pending', () {
      fakeAsync((async) {
        connect(async);
        link.computer(s.computerId)!.goOffline();
        async.flushMicrotasks();
        PolicySetOutcome? outcome;
        s
            .setPolicy(const Policy(askBeforeLooking: true))
            .then((o) => outcome = o);
        async.flushMicrotasks();
        expect(outcome, isA<PolicyOffline>());
        expect(s.data.policyEdit, isNull);
        s.dispose();
        async.flushMicrotasks();
      });
    });
  });
}
