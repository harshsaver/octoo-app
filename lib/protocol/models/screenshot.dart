import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

/// Largest accepted base64 payload of an inline screenshot.
const int maxScreenshotBase64Length = 8 * 1024 * 1024;

/// Largest accepted width or height of an inline screenshot, in pixels.
const int maxScreenshotSide = 4096;

final _dataUri = RegExp(r'^data:image/[A-Za-z0-9.+-]+;base64,');

/// A screenshot as it arrives on the wire (brief §7.2 `ScreenshotRef`).
///
/// Over the relay a screenshot is inline image data. The local host API used
/// a path on her computer instead; that form is kept so the app can say
/// "Screenshot on her computer" but it is never opened as a phone file.
sealed class WireScreenshot {
  const WireScreenshot();

  /// Decodes a wire value. Returns null for null or an empty string; never
  /// throws.
  static WireScreenshot? fromWire(String? value) {
    if (value == null || value.isEmpty) return null;
    final match = _dataUri.firstMatch(value);
    if (match == null) {
      if (value.startsWith('data:')) {
        return const RejectedScreenshot(ScreenshotRejection.undecodable);
      }
      return HostPathScreenshot(value);
    }
    final payload = value.substring(match.end);
    if (payload.length > maxScreenshotBase64Length) {
      return const RejectedScreenshot(ScreenshotRejection.tooLarge);
    }
    final Uint8List bytes;
    try {
      bytes = base64.decode(payload.replaceAll(RegExp(r'\s'), ''));
    } on FormatException {
      return const RejectedScreenshot(ScreenshotRejection.undecodable);
    }
    final info = sniffImage(bytes);
    if (info == null) {
      return const RejectedScreenshot(ScreenshotRejection.undecodable);
    }
    if (info.width > maxScreenshotSide || info.height > maxScreenshotSide) {
      return const RejectedScreenshot(ScreenshotRejection.tooLarge);
    }
    return InlineScreenshot(
      bytes: bytes,
      mimeType: info.mimeType,
      width: info.width,
      height: info.height,
    );
  }

  /// The wire form, or null when there is nothing worth sending back.
  String? toWire();
}

/// Image bytes sent inline as a `data:image/*;base64,` URI.
final class InlineScreenshot extends WireScreenshot {
  const InlineScreenshot({
    required this.bytes,
    required this.mimeType,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final String mimeType;
  final int width;
  final int height;

  @override
  String toWire() => 'data:$mimeType;base64,${base64.encode(bytes)}';

  @override
  bool operator ==(Object other) =>
      other is InlineScreenshot &&
      other.mimeType == mimeType &&
      _bytesEqual(other.bytes, bytes);

  @override
  int get hashCode => Object.hash(mimeType, bytes.length, width, height);
}

/// A path on her computer. Shown as "Screenshot on her computer"; never opened.
final class HostPathScreenshot extends WireScreenshot {
  const HostPathScreenshot(this.path);

  final String path;

  @override
  String toWire() => path;

  @override
  bool operator ==(Object other) =>
      other is HostPathScreenshot && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

enum ScreenshotRejection { tooLarge, undecodable }

/// A screenshot that arrived but can't be shown (too big or not an image).
final class RejectedScreenshot extends WireScreenshot {
  const RejectedScreenshot(this.reason);

  final ScreenshotRejection reason;

  @override
  String? toWire() => null;

  @override
  bool operator ==(Object other) =>
      other is RejectedScreenshot && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

/// json_serializable converter for screenshot-bearing fields.
class ScreenshotConverter implements JsonConverter<WireScreenshot?, String?> {
  const ScreenshotConverter();

  @override
  WireScreenshot? fromJson(String? json) => WireScreenshot.fromWire(json);

  @override
  String? toJson(WireScreenshot? object) => object?.toWire();
}

typedef SniffedImage = ({String mimeType, int width, int height});

/// Reads the format and pixel size from an image header (PNG, JPEG, GIF,
/// WebP) without decoding it. Returns null when the bytes aren't one of those.
SniffedImage? sniffImage(Uint8List b) {
  int be16(int i) => (b[i] << 8) | b[i + 1];
  int le16(int i) => b[i] | (b[i + 1] << 8);
  int be32(int i) =>
      (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
  bool ascii(int i, String s) {
    if (b.length < i + s.length) return false;
    for (var k = 0; k < s.length; k++) {
      if (b[i + k] != s.codeUnitAt(k)) return false;
    }
    return true;
  }

  // PNG: signature, then the IHDR chunk.
  if (b.length >= 24 && b[0] == 0x89 && ascii(1, 'PNG') && ascii(12, 'IHDR')) {
    return (mimeType: 'image/png', width: be32(16), height: be32(20));
  }
  // GIF: logical screen size.
  if (b.length >= 10 && (ascii(0, 'GIF87a') || ascii(0, 'GIF89a'))) {
    return (mimeType: 'image/gif', width: le16(6), height: le16(8));
  }
  // WebP: RIFF container with a VP8, VP8L or VP8X chunk.
  if (b.length >= 30 && ascii(0, 'RIFF') && ascii(8, 'WEBP')) {
    if (ascii(12, 'VP8 ')) {
      return (
        mimeType: 'image/webp',
        width: le16(26) & 0x3fff,
        height: le16(28) & 0x3fff,
      );
    }
    if (ascii(12, 'VP8L') && b[20] == 0x2f) {
      final bits = b[21] | (b[22] << 8) | (b[23] << 16) | (b[24] << 24);
      return (
        mimeType: 'image/webp',
        width: (bits & 0x3fff) + 1,
        height: ((bits >> 14) & 0x3fff) + 1,
      );
    }
    if (ascii(12, 'VP8X')) {
      return (
        mimeType: 'image/webp',
        width: (b[24] | (b[25] << 8) | (b[26] << 16)) + 1,
        height: (b[27] | (b[28] << 8) | (b[29] << 16)) + 1,
      );
    }
    return null;
  }
  // JPEG: walk the segments to the first start-of-frame marker.
  if (b.length >= 4 && b[0] == 0xff && b[1] == 0xd8) {
    var i = 2;
    while (i + 9 < b.length) {
      if (b[i] != 0xff) return null;
      final marker = b[i + 1];
      if (marker == 0xff) {
        i++;
        continue;
      }
      final isSof =
          marker >= 0xc0 &&
          marker <= 0xcf &&
          marker != 0xc4 &&
          marker != 0xc8 &&
          marker != 0xcc;
      if (isSof) {
        return (
          mimeType: 'image/jpeg',
          width: be16(i + 7),
          height: be16(i + 5),
        );
      }
      if (marker == 0xd9 || marker == 0xda) return null;
      i += 2 + be16(i + 2);
    }
    return null;
  }
  return null;
}

bool _bytesEqual(Uint8List a, Uint8List b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
