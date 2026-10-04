import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'octo_looks.dart';
import 'tokens.dart';

/// How the avatar moves (brief §5.6: used sparingly).
enum OctoMood {
  idle,

  /// A tiny pulse ring: a task is running.
  working,

  /// A gentle bob: waiting for her.
  waiting,

  /// Desaturated with closed eyes: the computer is offline.
  sleepy,
}

/// An Octo in its look on a soft circle. Readable at 40 dp. Motion stops
/// when the system asks for reduced motion.
class OctoAvatar extends StatefulWidget {
  const OctoAvatar({
    super.key,
    this.look = OctoLook.orange,
    this.size = OctoSpace.avatarSize,
    this.mood = OctoMood.idle,
    this.semanticLabel,
    this.celebrateKey,
  });

  final OctoLook look;
  final double size;
  final OctoMood mood;
  final String? semanticLabel;

  /// When this changes to a new non-null value, the Octo gives a quick
  /// wiggle (a task finished).
  final String? celebrateKey;

  static const asset = 'assets/octo/octo.png';

  @override
  State<OctoAvatar> createState() => _OctoAvatarState();
}

class _OctoAvatarState extends State<OctoAvatar> with TickerProviderStateMixin {
  AnimationController? _motion;
  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  bool get _animates =>
      widget.mood == OctoMood.working || widget.mood == OctoMood.waiting;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(OctoAvatar old) {
    super.didUpdateWidget(old);
    _syncMotion();
    final key = widget.celebrateKey;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (key != null &&
        old.celebrateKey != null &&
        key != old.celebrateKey &&
        !reduce) {
      _wiggle.forward(from: 0);
    }
  }

  void _syncMotion() {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_animates && !reduce) {
      _motion ??= AnimationController(
        vsync: this,
        duration: widget.mood == OctoMood.waiting
            ? const Duration(milliseconds: 1800)
            : const Duration(milliseconds: 1400),
      )..repeat(reverse: widget.mood == OctoMood.waiting);
    } else {
      _motion?.dispose();
      _motion = null;
    }
  }

  @override
  void dispose() {
    _wiggle.dispose();
    _motion?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final sleepy = widget.mood == OctoMood.sleepy;
    // Tint only the mascot; the accessory keeps its own colours.
    Widget image = Image.asset(
      OctoAvatar.asset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
    final hue = widget.look.hueMatrix;
    if (hue != null) {
      image = ColorFiltered(colorFilter: ColorFilter.matrix(hue), child: image);
    }
    Widget octo = SizedBox(
      width: size * 0.8,
      height: size * 0.8 * 101 / 120,
      child: CustomPaint(
        foregroundPainter: OctoAccessoryPainter(
          widget.look.accessory,
          sleepy: sleepy,
        ),
        child: image,
      ),
    );
    if (sleepy) {
      octo = ColorFiltered(
        colorFilter: const ColorFilter.matrix(sleepyMatrix),
        child: octo,
      );
    }

    final motion = _motion;
    if (motion != null && widget.mood == OctoMood.waiting) {
      octo = AnimatedBuilder(
        animation: motion,
        builder: (context, child) => Transform.translate(
          offset: Offset(
            0,
            -size * 0.05 * Curves.easeInOut.transform(motion.value),
          ),
          child: child,
        ),
        child: octo,
      );
    }

    octo = AnimatedBuilder(
      animation: _wiggle,
      builder: (context, child) {
        final t = _wiggle.value;
        if (t == 0 || t == 1) return child!;
        // A few quick turns that die away.
        final angle = 0.18 * (1 - t) * math.sin(t * math.pi * 6);
        return Transform.rotate(angle: angle, child: child);
      },
      child: octo,
    );

    Widget circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (sleepy ? Colors.grey : OctoColors.octoOrange).withValues(
          alpha: 0.12,
        ),
      ),
      child: octo,
    );

    if (motion != null && widget.mood == OctoMood.working) {
      final ring = OctoColors.light.working;
      circle = AnimatedBuilder(
        animation: motion,
        builder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ring.withValues(alpha: 0.35 * (1 - motion.value)),
                spreadRadius: size * 0.08 * motion.value,
              ),
            ],
          ),
          child: child,
        ),
        child: circle,
      );
    }

    return Semantics(
      label: widget.semanticLabel,
      image: widget.semanticLabel != null,
      excludeSemantics: true,
      child: circle,
    );
  }
}
