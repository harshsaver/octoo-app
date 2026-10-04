import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:octo_family/protocol/models/screenshot.dart';
import 'package:octo_family/transport/simulator/sample_screen.dart';

Uint8List _pngHeader(int width, int height) {
  final b = BytesBuilder()
    ..add([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
    ..add([0, 0, 0, 13])
    ..add(ascii.encode('IHDR'));
  final dims = ByteData(8)
    ..setUint32(0, width)
    ..setUint32(4, height);
  b
    ..add(dims.buffer.asUint8List())
    ..add([8, 6, 0, 0, 0]);
  return b.toBytes();
}

String _dataUri(String mime, List<int> bytes) =>
    'data:$mime;base64,${base64.encode(bytes)}';

void main() {
  test('inline PNG decodes with its size', () {
    final s = WireScreenshot.fromWire(sampleScreenDataUri);
    expect(s, isA<InlineScreenshot>());
    final inline = s! as InlineScreenshot;
    expect(inline.mimeType, 'image/png');
    expect((inline.width, inline.height), (480, 300));
    expect(inline.toWire(), sampleScreenDataUri);
  });

  test('the sniffed format wins over the declared one', () {
    final s = WireScreenshot.fromWire(
      _dataUri('image/jpeg', _pngHeader(10, 20)),
    );
    expect((s! as InlineScreenshot).mimeType, 'image/png');
  });

  test('JPEG, GIF and WebP sizes are read from their headers', () {
    final jpeg = <int>[
      0xff, 0xd8, //
      0xff, 0xe0, 0x00, 0x04, 0x00, 0x00, // APP0, length 4
      0xff,
      0xc0,
      0x00,
      0x11,
      0x08,
      0x01,
      0x2c,
      0x01,
      0xe0,
      0x03, // SOF0 300×480
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ];
    final j =
        WireScreenshot.fromWire(_dataUri('image/jpeg', jpeg))!
            as InlineScreenshot;
    expect((j.mimeType, j.width, j.height), ('image/jpeg', 480, 300));

    final gif = [...ascii.encode('GIF89a'), 0x40, 0x01, 0xc8, 0x00];
    final g =
        WireScreenshot.fromWire(_dataUri('image/gif', gif))!
            as InlineScreenshot;
    expect((g.width, g.height), (320, 200));

    final webp = <int>[
      ...ascii.encode('RIFF'), 0, 0, 0, 0, ...ascii.encode('WEBP'),
      ...ascii.encode('VP8X'), 10, 0, 0, 0, 0, 0, 0, 0,
      0x3f, 0x01, 0x00, // width-1 = 319
      0xc7, 0x00, 0x00, // height-1 = 199
    ];
    final w =
        WireScreenshot.fromWire(_dataUri('image/webp', webp))!
            as InlineScreenshot;
    expect((w.width, w.height), (320, 200));
  });

  test('over 4096 px on a side is rejected', () {
    expect(
      WireScreenshot.fromWire(_dataUri('image/png', _pngHeader(4097, 10))),
      const RejectedScreenshot(ScreenshotRejection.tooLarge),
    );
    expect(
      WireScreenshot.fromWire(_dataUri('image/png', _pngHeader(4096, 4096))),
      isA<InlineScreenshot>(),
    );
  });

  test('over 8 MB of base64 is rejected without decoding', () {
    final huge =
        'data:image/png;base64,${'A' * (maxScreenshotBase64Length + 4)}';
    expect(
      WireScreenshot.fromWire(huge),
      const RejectedScreenshot(ScreenshotRejection.tooLarge),
    );
  });

  test('bad data is rejected, never thrown', () {
    const undecodable = RejectedScreenshot(ScreenshotRejection.undecodable);
    expect(WireScreenshot.fromWire('data:image/png;base64,@@@'), undecodable);
    expect(
      WireScreenshot.fromWire(_dataUri('image/png', [1, 2, 3])),
      undecodable,
    );
    expect(WireScreenshot.fromWire('data:text/html;base64,PGI+'), undecodable);
    expect(WireScreenshot.fromWire('data:image/svg+xml,<svg/>'), undecodable);
    expect(
      const RejectedScreenshot(ScreenshotRejection.tooLarge).toWire(),
      isNull,
    );
  });

  test('a path on her computer is kept as a host path, never as a file', () {
    final s = WireScreenshot.fromWire(r'C:\Users\Mom\AppData\Octo\shot.png');
    expect(s, isA<HostPathScreenshot>());
    expect(s!.toWire(), r'C:\Users\Mom\AppData\Octo\shot.png');
  });

  test('null and empty mean no screenshot', () {
    expect(WireScreenshot.fromWire(null), isNull);
    expect(WireScreenshot.fromWire(''), isNull);
  });
}
