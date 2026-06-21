import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system for the Study Tracker mobile app.
///
/// Palette:  dark warm (#0D0D0D bg, #111716 surface), emerald accent.
/// Typography:  Space Grotesk (display) · Inter (body) · JetBrains Mono (data).
/// Radii:  16 cards, 12 buttons, 14 inputs, 8 chips.
class AppTheme {
  // ── Surfaces ───────────────────────────────────────────────
  static const Color bg = Color(0xFF0D0D0D);
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardHigher = Color(0xFF252525);

  // Warmer variant used by the profile screen
  static const Color bgWarm = Color(0xFF090D0C);
  static const Color surfaceWarm = Color(0xFF111716);
  static const Color surfaceWarm2 = Color(0xFF161E1C);

  // ── Borders ────────────────────────────────────────────────
  static const Color border = Color(0xFF2A2A2A);
  static const Color navBarBorder = Color(0xFF1F1F1F);

  // Profile-style border (slightly deeper green-black)
  static const Color borderWarm = Color(0xFF222B28);

  // ── Bottom nav ─────────────────────────────────────────────
  static const Color navBarBg = Color(0xF2121212); // rgba(18,18,18,0.95)

  // ── Text ───────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Profile-style warmer text
  static const Color textPrimaryWarm = Color(0xFFF2F7F5);
  static const Color textSecondaryWarm = Color(0xFF86A09A);
  static const Color textTertiaryWarm = Color(0xFF4D5B57);

  // ── Accent (emerald) ───────────────────────────────────────
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color primaryGreenDark = Color(0xFF059669);
  static const Color primaryGreenLight = Color(0xFF34D399);
  static const Color primaryGreenLighter = Color(0xFF6EE7B7);

  // Warmer / brighter emerald for hero accents (profile screen)
  static const Color emeraldBright = Color(0xFF00C896);
  static const Color emeraldBright2 = Color(0xFF2ECC71);

  // ── Functional ─────────────────────────────────────────────
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorRedWarm = Color(0xFFFF4757);
  static const Color successGreen = Color(0xFF22C55E);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color accentGold = Color(0xFFF59E0B);

  // ── Compat aliases ─────────────────────────────────────────
  static const Color surfaceDark = bg;
  static const Color surfaceElevated = card;
  static const Color surfaceHigher = cardHigher;
  static const Color borderColor = border;
  static const Color borderSubtle = navBarBorder;

  // ── Radii ──────────────────────────────────────────────────
  static const double radiusCard = 16;
  static const double radiusButton = 12;
  static const double radiusInput = 14;
  static const double radiusChip = 8;

  // ── Gradients ──────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldBrightGradient = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Animated progress bar fill (left → right).
  static const LinearGradient progressGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Start-exam CTA (135° emerald).
  static const LinearGradient startExamGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dark-green share card (135°).
  static const LinearGradient shareGradient = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF065F46)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Bar chart bar fill (top → bottom).
  static const LinearGradient chartBarGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF065F46)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1F1F1F), Color(0xFF181818)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Typography helpers ─────────────────────────────────────
  /// Display / heading face — Space Grotesk.
  static TextStyle display(double size,
          {FontWeight weight = FontWeight.w700, Color? color}) =>
      GoogleFonts.spaceGrotesk(
          fontSize: size, fontWeight: weight, color: color ?? textPrimary);

  /// Body face — Inter.
  static TextStyle body(double size,
          {FontWeight weight = FontWeight.w400, Color? color}) =>
      GoogleFonts.inter(
          fontSize: size, fontWeight: weight, color: color ?? textPrimary);

  /// Mono / data face — JetBrains Mono.
  static TextStyle mono(double size,
          {FontWeight weight = FontWeight.w500, Color? color}) =>
      GoogleFonts.jetBrainsMono(
          fontSize: size, fontWeight: weight, color: color ?? textPrimary);

  /// Build the full text theme using the three-typeface system.
  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.8,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.jetBrainsMono(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textTertiary,
        letterSpacing: 0.3,
      ),
    );
  }

  /// The app's dark theme — every screen inherits the typed text scale,
  /// consistent radii, and dark emerald palette.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        onPrimary: Colors.white,
        secondary: accentGold,
        onSecondary: Colors.white,
        surface: bg,
        onSurface: textPrimary,
        surfaceContainerHighest: card,
        error: errorRed,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: border, width: 0.5),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          side: const BorderSide(color: border, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: navBarBorder,
        thickness: 0.5,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardHigher,
        contentTextStyle:
            GoogleFonts.inter(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusButton),
        ),
        behavior: SnackBarBehavior.floating,
        actionTextColor: primaryGreen,
      ),
      iconTheme: const IconThemeData(color: textPrimary, size: 22),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
        linearTrackColor: border,
        circularTrackColor: border,
      ),
      textTheme: _textTheme,
    );
  }
}