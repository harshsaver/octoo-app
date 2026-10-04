import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The six Octo looks (brief §5.6). Until the art arrives, each is the base
/// mascot tinted by hue with a small accessory drawn on top. [id] is what the
/// backend stores (`PATCH {octo}`).
enum OctoLook {
  orange('orange', 'Orange', 0, OctoAccessory.none),
  oceanGlasses('ocean-glasses', 'Ocean blue', 185, OctoAccessory.glasses),
  lavenderSunhat('lavender-sunhat', 'Lavender', 250, OctoAccessory.sunHat),
  mintHeadphones('mint-headphones', 'Mint', 125, OctoAccessory.headphones),
  roseBow('rose-bow', 'Rose', -28, OctoAccessory.bow),
  sunshineScarf('sunshine-scarf', 'Sunshine', 24, OctoAccessory.scarf);

  const OctoLook(this.id, this.label, this.hueDegrees, this.accessory);

  final String id;
  final String label;
  final double hueDegrees;
  final OctoAccessory accessory;

  /// Unknown or missing ids fall back to the classic orange Octo.
  static OctoLook fromId(String? id) {
    for (final l in values) {
      if (l.id == id) return l;
    }
    return orange;
  }

  /// A `ColorFilter.matrix` that rotates hue by [hueDegrees].
  List<double>? get hueMatrix =>
      hueDegrees == 0 ? null : hueRotation(hueDegrees);
}

enum OctoAccessory { none, glasses, sunHat, headphones, bow, scarf }

/// The CSS `hue-rotate()` matrix.
List<double> hueRotation(double degrees) {
  final r = degrees * math.pi / 180;
  final c = math.cos(r);
  final s = math.sin(r);
  return <double>[
    0.213 + c * 0.787 - s * 0.213,
    0.715 - c * 0.715 - s * 0.715,
    0.072 - c * 0.072 + s * 0.928,
    0,
    0, //
    0.213 - c * 0.213 + s * 0.143,
    0.715 + c * 0.285 + s * 0.140,
    0.072 - c * 0.072 - s * 0.283,
    0,
    0,
    0.213 - c * 0.213 - s * 0.787,
    0.715 - c * 0.715 + s * 0.715,
    0.072 + c * 0.928 + s * 0.072,
    0,
    0,
    0, 0, 0, 1, 0,
  ];
}

/// Greyscale at 70% opacity, for a sleepy (offline) Octo.
const List<double> sleepyMatrix = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 0.75, 0,
];

/// Draws a look's accessory (and closed eyelids when sleepy) over the base
/// mascot. Coordinates are in the 120×101 space of `assets/octo/octo.png`.
class OctoAccessoryPainter extends CustomPainter {
  const OctoAccessoryPainter(this.accessory, {this.sleepy = false});

  final OctoAccessory accessory;
  final bool sleepy;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 101);
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (accessory) {
      case OctoAccessory.none:
        break;
      case OctoAccessory.glasses:
        stroke
          ..color = const Color(0xFF1F2933)
          ..strokeWidth = 3.2;
        canvas.drawCircle(const Offset(45, 42), 9.5, stroke);
        canvas.drawCircle(const Offset(73, 42), 9.5, stroke);
        canvas.drawLine(const Offset(54.5, 41), const Offset(63.5, 41), stroke);
      case OctoAccessory.sunHat:
        fill.color = const Color(0xFFE9C46A);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(60, 15), width: 96, height: 16),
          fill,
        );
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(60, 15), width: 52, height: 34),
          math.pi,
          math.pi,
          true,
          fill,
        );
        fill.color = const Color(0xFFB5838D);
        canvas.drawRect(const Rect.fromLTWH(35, 9, 50, 5), fill);
      case OctoAccessory.headphones:
        stroke
          ..color = const Color(0xFF2F3437)
          ..strokeWidth = 5;
        canvas.drawArc(
          Rect.fromCenter(center: const Offset(60, 38), width: 92, height: 76),
          math.pi * 1.05,
          math.pi * 0.9,
          false,
          stroke,
        );
        fill.color = const Color(0xFF2F3437);
        final cups = [
          const Rect.fromLTWH(7, 32, 14, 22),
          const Rect.fromLTWH(99, 32, 14, 22),
        ];
        for (final r in cups) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(6)),
            fill,
          );
        }
        fill.color = const Color(0xFF7FDBCA);
        for (final r in cups) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(r.deflate(3), const Radius.circular(4)),
            fill,
          );
        }
      case OctoAccessory.bow:
        fill.color = const Color(0xFFE63973);
        final left = Path()
          ..moveTo(86, 12)
          ..lineTo(72, 3)
          ..lineTo(73, 21)
          ..close();
        final right = Path()
          ..moveTo(86, 12)
          ..lineTo(100, 3)
          ..lineTo(99, 21)
          ..close();
        canvas.drawPath(left, fill);
        canvas.drawPath(right, fill);
        fill.color = const Color(0xFFB82457);
        canvas.drawCircle(const Offset(86, 12), 4, fill);
      case OctoAccessory.scarf:
        fill.color = const Color(0xFF2A9D8F);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(20, 54, 80, 10),
            const Radius.circular(5),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(76, 58, 10, 22),
            const Radius.circular(4),
          ),
          fill,
        );
        stroke
          ..color = const Color(0xFF1F7A6F)
          ..strokeWidth = 1.5;
        for (var x = 26.0; x < 98; x += 8) {
          canvas.drawLine(Offset(x, 56), Offset(x, 62), stroke);
        }
    }

    if (sleepy) {
      // Closed eyes: lids over the eyes.
      fill.color = const Color(0xFF8E8E93);
      for (final c in const [Offset(45, 42), Offset(73, 42)]) {
        canvas.drawArc(
          Rect.fromCenter(center: c, width: 15, height: 15),
          math.pi,
          math.pi,
          true,
          fill,
        );
      }
      stroke
        ..color = const Color(0xFF3A3A3C)
        ..strokeWidth = 1.8;
      for (final c in const [Offset(45, 42), Offset(73, 42)]) {
        canvas.drawArc(
          Rect.fromCenter(center: c, width: 12, height: 8),
          0.15,
          math.pi - 0.3,
          false,
          stroke,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(OctoAccessoryPainter old) =>
      old.accessory != accessory || old.sleepy != sleepy;
}
