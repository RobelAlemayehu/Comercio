
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'storage.dart';

abstract class AppColors {

  static const Color primary        = Color(0xFF1E3A5F); 
  static const Color primaryLight   = Color(0xFF2B4A70); 
  static const Color primaryDark    = Color(0xFF122438); 
  static const Color secondary      = Color(0xFFF5A623); 
  static const Color secondaryLight = Color(0xFFFFBD45); 

  static const Color backgroundLight    = Color(0xFFF8F9FA);
  static const Color surfaceLight       = Color(0xFFFFFFFF);
  static const Color cardLight          = Color(0xFFFFFFFF);
  static const Color textPrimaryLight   = Color(0xFF1C1C1C);
  static const Color textSecondaryLight = Color(0xFF5A6D82);
  static const Color borderLight        = Color(0xFFDDE3EA);
  static const Color dividerLight       = Color(0xFFEEF1F5);

  static const Color backgroundDark    = Color(0xFF0E1E30);
  static const Color surfaceDark       = Color(0xFF1A2D42);
  static const Color cardDark          = Color(0xFF1A2D42);
  static const Color textPrimaryDark   = Color(0xFFF0F4F8);
  static const Color textSecondaryDark = Color(0xFF8FA8C0);
  static const Color borderDark        = Color(0xFF2A4060);
  static const Color dividerDark       = Color(0xFF1A2D42);

  static const Color error   = Color(0xFFD32F2F);
  static const Color onError = Colors.white;
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info    = Color(0xFF2563EB);

  static const Color ratingStar            = Color(0xFFF5A623);
  static const Color priceTag              = Color(0xFF1E3A5F);
  static const Color discountBadge         = Color(0xFFD32F2F);
  static const Color shimmerBaseLight      = Color(0xFFDDE3EA);
  static const Color shimmerHighlightLight = Color(0xFFEEF1F5);
  static const Color shimmerBaseDark       = Color(0xFF2A4060);
  static const Color shimmerHighlightDark  = Color(0xFF3A5070);
}

abstract class AppRadius {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double full = 999.0;

  static const BorderRadius borderXs   = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm   = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd   = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg   = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl   = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderFull = BorderRadius.all(Radius.circular(full));
}

abstract class AppSpacing {
  static const double xxxs = 2.0;
  static const double xxs  = 4.0;
  static const double xs   = 8.0;
  static const double sm   = 12.0;
  static const double md   = 16.0;
  static const double lg   = 24.0;
  static const double xl   = 32.0;
  static const double xxl  = 48.0;
  static const double xxxl = 64.0;
}

abstract class AppTypography {
  static TextTheme textTheme(Color primaryTextColor, Color secondaryTextColor) {
    return TextTheme(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: primaryTextColor),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: primaryTextColor),
      displaySmall: GoogleFonts.outfit(
        fontSize: 24, fontWeight: FontWeight.w600, color: primaryTextColor),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20, fontWeight: FontWeight.w600, color: primaryTextColor),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.w600, color: primaryTextColor),
      titleMedium: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w600, color: primaryTextColor),
      titleSmall: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: primaryTextColor),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: secondaryTextColor),
      bodySmall: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: secondaryTextColor),
      labelLarge: GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w600, color: primaryTextColor),
      labelMedium: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: secondaryTextColor),
      labelSmall: GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w500, color: secondaryTextColor),
    );
  }
}

abstract class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        onError: AppColors.onError,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: AppTypography.textTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
        color: AppColors.cardLight,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        border: OutlineInputBorder(borderRadius: AppRadius.borderMd, borderSide: const BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.borderMd, borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.borderMd, borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: AppRadius.borderMd, borderSide: const BorderSide(color: AppColors.error)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.dividerLight, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.secondary),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.secondaryLight,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
        onPrimary: AppColors.primaryDark,
        onSecondary: AppColors.primaryDark,
        onSurface: AppColors.textPrimaryDark,
        onError: AppColors.onError,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: AppTypography.textTheme(AppColors.textPrimaryDark, AppColors.textSecondaryDark),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.primaryDark,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.secondaryLight),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.secondaryLight),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
        color: AppColors.cardDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        border: OutlineInputBorder(borderRadius: AppRadius.borderMd, borderSide: const BorderSide(color: AppColors.borderDark)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.borderMd, borderSide: const BorderSide(color: AppColors.borderDark)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.borderMd, borderSide: const BorderSide(color: AppColors.secondaryLight, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: AppRadius.borderMd, borderSide: const BorderSide(color: AppColors.error)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondaryLight,
          side: const BorderSide(color: AppColors.secondaryLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondaryLight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.dividerDark, thickness: 1, space: 1),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.secondaryLight),
    );
  }
}

const _themeModeKey = 'theme_mode';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._storage) : super(_loadThemeMode(_storage));

  final LocalStorageService _storage;

  static ThemeMode _loadThemeMode(LocalStorageService storage) {
    return themeModeFromStorage(storage.getString(_themeModeKey));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.saveString(_themeModeKey, themeModeToStorage(mode));
  }
}

ThemeMode themeModeFromStorage(String? value) {
  switch (value) {
    case 'light': return ThemeMode.light;
    case 'dark':  return ThemeMode.dark;
    default:      return ThemeMode.system;
  }
}

String themeModeToStorage(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:  return 'light';
    case ThemeMode.dark:   return 'dark';
    case ThemeMode.system: return 'system';
  }
}

String themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:  return 'Light';
    case ThemeMode.dark:   return 'Dark';
    case ThemeMode.system: return 'System Default';
  }
}
