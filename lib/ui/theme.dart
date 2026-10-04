import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Gives widgets the [OctoColors] for the current brightness.
class OctoTheme extends ThemeExtension<OctoTheme> {
  const OctoTheme(this.colors);

  final OctoColors colors;

  static OctoColors of(BuildContext context) =>
      Theme.of(context).extension<OctoTheme>()!.colors;

  @override
  OctoTheme copyWith({OctoColors? colors}) => OctoTheme(colors ?? this.colors);

  @override
  OctoTheme lerp(OctoTheme? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

ThemeData octoLightTheme() => _theme(Brightness.light, OctoColors.light);

ThemeData octoDarkTheme() => _theme(Brightness.dark, OctoColors.dark);

ThemeData _theme(Brightness brightness, OctoColors c) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: OctoColors.octoOrange,
        brightness: brightness,
      ).copyWith(
        primary: c.accentText,
        // White on the darker light-mode orange; black on the lighter dark one.
        onPrimary: brightness == Brightness.light ? Colors.white : Colors.black,
        surface: c.background,
        onSurface: c.label,
        onSurfaceVariant: c.secondaryLabel,
        error: c.needsYou,
        outlineVariant: c.separator,
      );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    extensions: [OctoTheme(c)],
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.label,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    // Sheets and bars stay plain white (or black), not tinted by the seed.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.background,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: c.background,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: DividerThemeData(
      color: c.separator,
      thickness: 0.5,
      space: 0,
    ),
    textTheme: base.textTheme.apply(bodyColor: c.label, displayColor: c.label),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
