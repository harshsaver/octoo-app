import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

/// Writes build/steps.timeline_summary.json (frame build and raster times
/// while 50 steps stream in) and prints the time to the list.
Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final timeline = driver.Timeline.fromJson(data['steps_timeline']! as Map<String, dynamic>);
    await driver.TimelineSummary.summarize(timeline).writeTimelineToFile('steps', pretty: true);
    // ignore: avoid_print
    print('list_ms: ${data['list_ms']}');
  },
);
