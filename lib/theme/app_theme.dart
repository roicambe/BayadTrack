import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Builds the ThemeData for both light and dark modes.
/// All Material 3 component themes (cards, nav bar, buttons) are configured here.
abstract class AppTheme {
  static ThemeData lightTheme(bool usePoppins) => _build(Brightness.light, usePoppins);
  static ThemeData darkTheme(bool usePoppins)  => _build(Brightness.dark, usePoppins);

  static ThemeData _build(Brightness brightness, bool usePoppins) {
    final isDark = brightness == Brightness.dark;

    // ── Surface palette for this mode ────────────────────────────────────────
    final bg      = isDark ? AppColors.darkBg      : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface  : AppColors.lightSurface;
    final card    = isDark ? AppColors.darkCard     : AppColors.lightCard;
    final border  = isDark ? AppColors.darkBorder   : AppColors.lightBorder;

    // Primary blue is slightly lighter in dark mode for readability on dark bg
    final primary = isDark ? const Color(0xFF4DA6FF) : AppColors.gcash;

    final textPrimary   = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // ── Base text theme ──────────────────────────────────────────────────────
    final systemTextTheme = ThemeData(brightness: brightness).textTheme;
    final base = usePoppins 
        ? GoogleFonts.poppinsTextTheme(systemTextTheme)
        : systemTextTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,

      // ── Color Scheme ───────────────────────────────────────────────────────
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
      ).copyWith(
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.maya,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: card,
        outline: border,
        error: AppColors.error,
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: card,
        elevation: isDark ? 0 : 3,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark
              ? BorderSide(color: border, width: 1)
              : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Bottom Navigation Bar ──────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: primary.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 28);
          }
          return IconThemeData(color: textSecondary, size: 26);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return usePoppins 
              ? GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? primary : textSecondary,
                )
              : TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? primary : textSecondary,
                );
        }),
      ),

      // ── App Bar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: usePoppins 
            ? GoogleFonts.poppins(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              )
            : TextStyle(
                color: textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // ── Elevated Button ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: usePoppins 
              ? GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                )
              : const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
        ),
      ),

      // ── Text Theme ─────────────────────────────────────────────────────────
      textTheme: base.copyWith(
        displayLarge:   base.displayLarge?.copyWith(color: textPrimary,   fontWeight: FontWeight.w700),
        displayMedium:  base.displayMedium?.copyWith(color: textPrimary,  fontWeight: FontWeight.w700),
        headlineLarge:  base.headlineLarge?.copyWith(color: textPrimary,  fontWeight: FontWeight.w700),
        headlineMedium: base.headlineMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w700),
        headlineSmall:  base.headlineSmall?.copyWith(color: textPrimary,  fontWeight: FontWeight.w600),
        titleLarge:     base.titleLarge?.copyWith(color: textPrimary,     fontWeight: FontWeight.w700),
        titleMedium:    base.titleMedium?.copyWith(color: textPrimary,    fontWeight: FontWeight.w600),
        titleSmall:     base.titleSmall?.copyWith(color: textSecondary,   fontWeight: FontWeight.w500),
        bodyLarge:      base.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium:     base.bodyMedium?.copyWith(color: textPrimary),
        bodySmall:      base.bodySmall?.copyWith(color: textSecondary),
        labelLarge:     base.labelLarge?.copyWith(color: textPrimary,     fontWeight: FontWeight.w600),
        labelMedium:    base.labelMedium?.copyWith(color: textSecondary),
        labelSmall:     base.labelSmall?.copyWith(color: textSecondary),
      ),
    );
  }
}
