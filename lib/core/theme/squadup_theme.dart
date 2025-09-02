import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom theme extension for SquadUp-specific properties that don't fit in ColorScheme
@immutable
class SquadUpThemeExtension extends ThemeExtension<SquadUpThemeExtension> {
  final Color sufferColor;
  final Color successColor;
  final Color warningColor;
  final LinearGradient primaryGradient;
  final LinearGradient raceGradient;
  final BoxDecoration messageDecoration;
  final BoxDecoration ownMessageDecoration;
  final BoxDecoration checkInCardDecoration;
  final BoxDecoration squadCardDecoration;

  const SquadUpThemeExtension({
    required this.sufferColor,
    required this.successColor,
    required this.warningColor,
    required this.primaryGradient,
    required this.raceGradient,
    required this.messageDecoration,
    required this.ownMessageDecoration,
    required this.checkInCardDecoration,
    required this.squadCardDecoration,
  });

  @override
  SquadUpThemeExtension copyWith({
    Color? sufferColor,
    Color? successColor,
    Color? warningColor,
    LinearGradient? primaryGradient,
    LinearGradient? raceGradient,
    BoxDecoration? messageDecoration,
    BoxDecoration? ownMessageDecoration,
    BoxDecoration? checkInCardDecoration,
    BoxDecoration? squadCardDecoration,
  }) {
    return SquadUpThemeExtension(
      sufferColor: sufferColor ?? this.sufferColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      raceGradient: raceGradient ?? this.raceGradient,
      messageDecoration: messageDecoration ?? this.messageDecoration,
      ownMessageDecoration: ownMessageDecoration ?? this.ownMessageDecoration,
      checkInCardDecoration:
          checkInCardDecoration ?? this.checkInCardDecoration,
      squadCardDecoration: squadCardDecoration ?? this.squadCardDecoration,
    );
  }

  @override
  SquadUpThemeExtension lerp(SquadUpThemeExtension? other, double t) {
    if (other is! SquadUpThemeExtension) return this;

    return SquadUpThemeExtension(
      sufferColor: Color.lerp(sufferColor, other.sufferColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      primaryGradient: LinearGradient.lerp(
        primaryGradient,
        other.primaryGradient,
        t,
      )!,
      raceGradient: LinearGradient.lerp(raceGradient, other.raceGradient, t)!,
      messageDecoration: t < 0.5 ? messageDecoration : other.messageDecoration,
      ownMessageDecoration: t < 0.5
          ? ownMessageDecoration
          : other.ownMessageDecoration,
      checkInCardDecoration: t < 0.5
          ? checkInCardDecoration
          : other.checkInCardDecoration,
      squadCardDecoration: t < 0.5
          ? squadCardDecoration
          : other.squadCardDecoration,
    );
  }
}

class SquadUpTheme {
  SquadUpTheme._();

  // ============================================
  // CORE COLOR DEFINITIONS
  // These are the actual color values used throughout the app
  // ============================================

  static const Color _primaryColor = Color(0xFF667EEA); // Squad Purple
  static const Color _sufferColor = Color(0xFFFF6B6B); // Suffer Red
  static const Color _backgroundColor = Color(0xFF0A0A0A); // Pre-Dawn Black
  static const Color _surfaceColor = Color(0xFF1A1A2E); // Dawn Blue
  static const Color _borderColor = Color(0xFF2A2A3E); // Subtle Divide
  static const Color _successColor = Color(0xFF4CAF50); // PR Green
  static const Color _warningColor = Color(0xFFFFA726); // Warning Orange

  // Text colors
  static const Color _textPrimary = Color(0xFFE0E0E0);
  static const Color _textSecondary = Color(0xFF888888);
  static const Color _textMuted = Color(0xFF666666);

  // ============================================
  // DARK THEME DEFINITION
  // ============================================

  static ThemeData get darkTheme {
    // ----------------------------------------
    // 1. COLOR SCHEME
    // This is where all standard Material colors are defined
    // Access via: Theme.of(context).colorScheme.primary
    // ----------------------------------------
    const colorScheme = ColorScheme.dark(
      // Primary colors - Main brand color (Squad Purple)
      primary: _primaryColor, // Main actions, highlights
      onPrimary: Colors.white, // Text/icons on primary color
      primaryContainer: Color(0xFF4C5CBF), // Darker shade for containers
      onPrimaryContainer: Colors.white, // Text/icons on primary containers
      // Secondary colors - Accent color (Suffer Red)
      secondary: _sufferColor, // Secondary actions
      onSecondary: Colors.white, // Text/icons on secondary
      secondaryContainer: Color(0xFFCC5555), // Darker shade for containers
      onSecondaryContainer: Colors.white, // Text/icons on secondary containers
      // Tertiary colors - Additional accent (Success Green)
      tertiary: _successColor, // Success states, achievements
      onTertiary: Colors.white, // Text/icons on tertiary
      tertiaryContainer: Color(0xFF388E3C), // Darker shade for containers
      onTertiaryContainer: Colors.white, // Text/icons on tertiary containers
      // Error colors
      error: _sufferColor, // Error states
      onError: Colors.white, // Text/icons on error
      errorContainer: Color(0xFFCC5555), // Error container background
      onErrorContainer: Colors.white, // Text/icons on background
      // Surface colors
      surface: _surfaceColor, // Cards, sheets (Dawn Blue)
      onSurface: _textPrimary, // Text/icons on surfaces
      surfaceContainerHighest:
          _borderColor, // Alternative surface (borders, dividers)
      onSurfaceVariant: _textSecondary, // Text/icons on surface variants
      // Other colors
      outline: _borderColor, // Borders, dividers
      outlineVariant: Color(0xFF1F1F2E), // Subtle borders
      shadow: Colors.black, // Shadow color
      scrim: Colors.black54, // Scrim for modals
      inverseSurface: Colors.white, // Inverse surface
      onInverseSurface: _backgroundColor, // Text on inverse surface
      inversePrimary: _primaryColor, // Inverse primary
    );

    // ----------------------------------------
    // 2. THEME EXTENSION
    // Custom properties specific to SquadUp
    // Access via: context.squadUpTheme.sufferColor
    // ----------------------------------------
    final themeExtension = SquadUpThemeExtension(
      sufferColor: _sufferColor,
      successColor: _successColor,
      warningColor: _warningColor,
      primaryGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_primaryColor, Color(0xFF764BA2)],
      ),
      raceGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_primaryColor, _sufferColor],
      ),
      messageDecoration: BoxDecoration(
        color: const Color(0xFF0F0F23),
        borderRadius: BorderRadius.circular(18),
      ),
      ownMessageDecoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      checkInCardDecoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: _primaryColor, width: 3)),
      ),
      squadCardDecoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
    );

    // ----------------------------------------
    // 3. THEME DATA
    // Combines everything into a complete theme
    // ----------------------------------------
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      extensions: [themeExtension],
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: colorScheme.surface,

      // ----------------------------------------
      // COMPONENT THEMES
      // Default styling for Material widgets
      // ----------------------------------------

      // AppBar styling
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          fontFamily: GoogleFonts.inter().fontFamily,
        ),
      ),

      // Button styling
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Input field styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F0F23),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: TextStyle(color: _textMuted),
        labelStyle: TextStyle(color: _textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),

      // Card styling
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Chip styling
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        secondaryLabelStyle: TextStyle(color: colorScheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // ListTile styling
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),

      // Text styling
      textTheme: TextTheme(
        // Display styles
        displayLarge: TextStyle(color: colorScheme.onSurface),
        displayMedium: TextStyle(color: colorScheme.onSurface),
        displaySmall: TextStyle(color: colorScheme.onSurface),

        // Headline styles
        headlineLarge: TextStyle(color: colorScheme.onSurface),
        headlineMedium: TextStyle(color: colorScheme.onSurface),
        headlineSmall: TextStyle(color: colorScheme.onSurface),

        // Title styles
        titleLarge: TextStyle(color: colorScheme.onSurface),
        titleMedium: TextStyle(color: colorScheme.onSurface),
        titleSmall: TextStyle(color: colorScheme.onSurface),

        // Body styles
        bodyLarge: TextStyle(color: colorScheme.onSurface),
        bodyMedium: TextStyle(color: colorScheme.onSurface),
        bodySmall: TextStyle(color: colorScheme.onSurfaceVariant),

        // Label styles
        labelLarge: TextStyle(color: colorScheme.onSurface),
        labelMedium: TextStyle(color: colorScheme.onSurfaceVariant),
        labelSmall: TextStyle(color: _textMuted),
      ),
    );
  }

  // ============================================
  // STATIC CONSTANTS (for backward compatibility)
  // Prefer using Theme.of(context).colorScheme instead
  // ============================================

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 20.0;
  static const double radiusButton = 25.0;
}

// ============================================
// EXTENSION FOR EASY ACCESS
// ============================================

extension ThemeExtensions on BuildContext {
  /// Access custom theme properties
  /// Example: context.squadUpTheme.sufferColor
  SquadUpThemeExtension get squadUpTheme =>
      Theme.of(this).extension<SquadUpThemeExtension>()!;

  /// Quick access to theme
  /// Example: context.theme.colorScheme.primary
  ThemeData get theme => Theme.of(this);

  /// Quick access to color scheme
  /// Example: context.colors.primary
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Quick access to text theme
  /// Example: context.textTheme.headlineSmall
  TextTheme get textTheme => Theme.of(this).textTheme;
}
