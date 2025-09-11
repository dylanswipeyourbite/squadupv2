import 'package:flutter/material.dart';

/// Utility class to provide simplified theme access for chat widgets
class SquadUpTheme {
  final ColorScheme colors;
  final TextTheme textTheme;

  SquadUpTheme({required this.colors, required this.textTheme});

  // Factory constructor for convenient access
  static SquadUpTheme of(BuildContext context) {
    final theme = Theme.of(context);
    return SquadUpTheme(colors: theme.colorScheme, textTheme: theme.textTheme);
  }

  // Colors
  Color get primary => colors.primary;
  Color get onPrimary => colors.onPrimary;
  Color get surface => colors.surface;
  Color get background => colors.surface;
  Color get onSurface => colors.onSurface;
  Color get onSurfaceSecondary => colors.onSurfaceVariant;
  Color get surfaceContainer => colors.surfaceContainerHighest;
  Color get error => colors.error;

  // Text styles
  TextStyle get h1 => textTheme.displaySmall ?? const TextStyle();
  TextStyle get h2 => textTheme.headlineSmall ?? const TextStyle();
  TextStyle get h3 => textTheme.titleLarge ?? const TextStyle();
  TextStyle get body1 => textTheme.bodyLarge ?? const TextStyle();
  TextStyle get body2 => textTheme.bodySmall ?? const TextStyle();
  TextStyle get caption => textTheme.bodySmall ?? const TextStyle();
}
