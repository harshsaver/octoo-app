import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/bubble_gallery.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'every bubble kind and end status renders (${brightness.name})',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 12000);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(galleryHost(galleryThread(), brightness: brightness));
        await tester.pump(const Duration(milliseconds: 100));

        // Requests and their states.
        expect(find.text('Not sent yet'), findsOneWidget);
        expect(
          find.textContaining("Couldn't confirm it reached Mom's computer"),
          findsOneWidget,
        );
        expect(find.text('Try again'), findsOneWidget);
        expect(find.text('Waiting its turn'), findsOneWidget);
        expect(find.text('Waiting for Mom to say OK'), findsOneWidget);
        expect(find.text('Priya → Octo'), findsOneWidget);
        // The live bubble.
        expect(find.text('Opening the invite'), findsNWidgets(2));
        expect(find.text('Stop'), findsNWidgets(2));
        // Each end, in plain sentences; never "done" for an unknown status.
        expect(find.text("Joined. She's in the call."), findsOneWidget);
        expect(
          find.text("I couldn't finish this. It's back with you."),
          findsOneWidget,
        );
        expect(
          find.text('I stopped because of a safety rule.'),
          findsOneWidget,
        );
        expect(find.text("Your rules don't allow this."), findsOneWidget);
        expect(find.text('Mom said no.'), findsOneWidget);
        expect(find.text("Mom didn't answer."), findsOneWidget);
        expect(find.text('Stopped by Priya.'), findsOneWidget);
        expect(find.text("That didn't work."), findsOneWidget);
        expect(
          find.text(
            "Octo sent an update this app can't show yet. Update the app.",
          ),
          findsOneWidget,
        );
        // Screenshots that can't be shown say so.
        expect(find.text('Screenshot on her computer'), findsOneWidget);
        expect(find.text('Screenshot no longer available'), findsOneWidget);
        // From Mom.
        expect(find.text('Is this email real?'), findsOneWidget);
        expect(
          find.text('Octo told her: It looks like a scam.'),
          findsOneWidget,
        );
        expect(find.text('Reply'), findsOneWidget);
        expect(find.text('Octo, do it'), findsOneWidget);
        expect(find.textContaining('Can you take a look?'), findsOneWidget);
        expect(find.text('See her screen'), findsOneWidget);
        // Centre lines.
        expect(find.text('Asked Mom to show her screen'), findsOneWidget);
        expect(find.text('Mom said no to showing her screen'), findsOneWidget);
        expect(find.text("Harsh's iPhone was added"), findsOneWidget);
        // Tell Mom.
        expect(find.text('Calling you in 5 minutes!'), findsOneWidget);

        final handle = tester.ensureSemantics();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        expect(
          find.bySemanticsLabel(
            RegExp(r"^Octo, .*: Joined\. She's in the call\.$"),
          ),
          findsOneWidget,
          reason: 'screen-reader label on every bubble',
        );
        handle.dispose();
      },
    );
  }

  testWidgets('the thread at the largest text size', (tester) async {
    tester.view.physicalSize = const Size(1080, 40000);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(galleryHost(galleryThread()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
