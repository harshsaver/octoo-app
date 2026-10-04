import 'package:flutter/material.dart';

import 'tokens.dart';

enum TailSide { none, left, right }

/// A Messages bubble: a rounded rect, with the little tail on the last
/// bubble of a group.
class BubbleBorder extends ShapeBorder {
  const BubbleBorder({
    this.tail = TailSide.none,
    this.radius = OctoSpace.bubbleRadius,
  });

  final TailSide tail;
  final double radius;

  /// How far the tail sticks out of the bubble.
  static const tailWidth = 6.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final r = radius.clamp(0.0, rect.shortestSide / 2);
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
    if (tail == TailSide.none) return body;
    final b = rect.bottom;
    final tailPath = Path();
    if (tail == TailSide.right) {
      final x = rect.right;
      tailPath
        ..moveTo(x - r, b)
        ..lineTo(x - 2, b - 6)
        ..quadraticBezierTo(x, b - 2, x + tailWidth, b)
        ..quadraticBezierTo(x - 4, b + 1, x - r - 4, b - 2)
        ..close();
    } else {
      final x = rect.left;
      tailPath
        ..moveTo(x + r, b)
        ..lineTo(x + 2, b - 6)
        ..quadraticBezierTo(x, b - 2, x - tailWidth, b)
        ..quadraticBezierTo(x + 4, b + 1, x + r + 4, b - 2)
        ..close();
    }
    return Path.combine(PathOperation.union, body, tailPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => BubbleBorder(tail: tail, radius: radius * t);
}

/// A bubble with padding and a maximum width of about 75% of the screen.
class Bubble extends StatelessWidget {
  const Bubble({
    super.key,
    required this.color,
    required this.child,
    this.tail = TailSide.none,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  });

  final Color color;
  final Widget child;
  final TailSide tail;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.75;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Material(
        color: color,
        shape: BubbleBorder(tail: tail),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
