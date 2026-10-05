import 'dart:io';

import 'package:flutter/services.dart';

/// Real Roboto and Material Icons for goldens (Flutter's own copies, Apache
/// 2.0, in test/goldens/fonts), so text renders as glyphs instead of the
/// test font's boxes, the same on every Linux machine. Call from setUpAll:
/// file reads don't complete under a widget test's fake time.
Future<void> loadGoldenFonts() async {
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('test/goldens/fonts/$name').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    roboto.addFont(read('Roboto-$weight.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(read('MaterialIcons-Regular.otf'))).load();
}
