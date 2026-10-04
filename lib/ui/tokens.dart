import 'package:flutter/material.dart';

/// Design tokens (brief §6). Colours come in light and dark pairs; read them
/// through `OctoTheme.of(context)`.
@immutable
class OctoColors {
  const OctoColors({
    required this.background,
    required this.label,
    required this.secondaryLabel,
    required this.accent,
    required this.accentText,
    required this.myBubble,
    required this.onMyBubble,
    required this.otherBubble,
    required this.onOtherBubble,
    required this.working,
    required this.needsYou,
    required this.helpTint,
    required this.separator,
    required this.tellBubble,
  });

  /// Octo orange `#D2601A`: the +, the send button, icons.
  static const octoOrange = Color(0xFFD2601A);

  static const light = OctoColors(
    background: Color(0xFFFFFFFF),
    label: Color(0xFF000000),
    secondaryLabel: Color(0xFF6C6C70),
    accent: octoOrange,
    // #D2601A on white is 3.9:1, below AA for body text. Text drawn in the
    // accent, and your bubbles (white text), use this darker orange (4.9:1).
    accentText: Color(0xFFB8520F),
    myBubble: Color(0xFFB8520F),
    onMyBubble: Color(0xFFFFFFFF),
    otherBubble: Color(0xFFE9E9EB),
    onOtherBubble: Color(0xFF000000),
    working: Color(0xFF0F6E78),
    needsYou: Color(0xFFD70015),
    helpTint: Color(0xFFFDECEC),
    separator: Color(0xFFE5E5EA),
    tellBubble: Color(0xFF33658A),
  );

  static const dark = OctoColors(
    background: Color(0xFF000000),
    label: Color(0xFFFFFFFF),
    secondaryLabel: Color(0xFF98989F),
    accent: octoOrange,
    accentText: Color(0xFFF08A4B),
    myBubble: Color(0xFFB8520F),
    onMyBubble: Color(0xFFFFFFFF),
    otherBubble: Color(0xFF26252A),
    onOtherBubble: Color(0xFFFFFFFF),
    // #0F6E78 is too dark to read on black; a lighter teal keeps 8:1.
    working: Color(0xFF4FB3BF),
    needsYou: Color(0xFFFF6961),
    helpTint: Color(0xFF3A1D1D),
    separator: Color(0xFF38383A),
    tellBubble: Color(0xFF3B6E94),
  );

  final Color background;
  final Color label;
  final Color secondaryLabel;
  final Color accent;
  final Color accentText;
  final Color myBubble;
  final Color onMyBubble;
  final Color otherBubble;
  final Color onOtherBubble;

  /// Teal, only for "working".
  final Color working;

  /// Red, only for "needs you".
  final Color needsYou;

  /// The soft red behind Mom's "Can you take a look?" bubble.
  final Color helpTint;
  final Color separator;

  /// Your messages to her (Tell Mom), so they never look like tasks.
  final Color tellBubble;
}

/// Spacing, radii and motion.
abstract final class OctoSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Minimum touch target (brief §6: at least 48 dp).
  static const minTarget = 48.0;

  static const bubbleRadius = 18.0;
  static const avatarSize = 40.0;
}

abstract final class OctoMotion {
  static const short = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 350);

  /// The soft spring bubbles slide in with.
  static const bubbleSpring = Curves.easeOutBack;
}
