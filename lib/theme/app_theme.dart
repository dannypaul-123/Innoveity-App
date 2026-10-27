import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static bool get _isTestEnvironment {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  static TextTheme _buildBaseTextTheme([TextTheme? base]) {
    final defaultBase = base ?? ThemeData.light().textTheme;
    if (_isTestEnvironment) {
      return defaultBase;
    }
    try {
      return GoogleFonts.interTextTheme(defaultBase);
    } catch (_) {
      return defaultBase;
    }
  }

  static TextTheme _buildHeadlineTextTheme([TextTheme? base]) {
    final defaultBase = base ?? ThemeData.light().textTheme;
    if (_isTestEnvironment) {
      return defaultBase;
    }
    try {
      return GoogleFonts.plusJakartaSansTextTheme(defaultBase);
    } catch (_) {
      return defaultBase;
    }
  }

  static ThemeData get lightTheme {
    final baseTextTheme = _buildBaseTextTheme();
    final headlineTextTheme = _buildHeadlineTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPine,
        primary: AppColors.primaryPine,
        surface: AppColors.surfaceContainerLowest,
        onSurface: AppColors.textDark,
        onSurfaceVariant: AppColors.textMuted,
        error: AppColors.alertText,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        iconTheme: IconThemeData(color: AppColors.primaryPine),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.background,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryPine,
        unselectedItemColor: AppColors.textMuted,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primaryPine,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primaryPine,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPine,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryPine),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryPine, width: 1.5),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.textDark,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      iconTheme: const IconThemeData(color: AppColors.textDark),
      textTheme: baseTextTheme.copyWith(
        displayLarge: headlineTextTheme.displayLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        displayMedium: headlineTextTheme.displayMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        displaySmall: headlineTextTheme.displaySmall?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        headlineLarge: headlineTextTheme.headlineLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        headlineMedium: headlineTextTheme.headlineMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        headlineSmall: headlineTextTheme.headlineSmall?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        titleLarge: headlineTextTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        titleMedium: headlineTextTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        titleSmall: headlineTextTheme.titleSmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16,
          color: AppColors.textDark,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          color: AppColors.textDark,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
        labelLarge: headlineTextTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        labelMedium: headlineTextTheme.labelMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        labelSmall: headlineTextTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseDarkTextTheme = ThemeData.dark().textTheme;
    final baseTextTheme = _buildBaseTextTheme(baseDarkTextTheme).apply(
      bodyColor: AppColors.textLight,
      displayColor: AppColors.textLight,
      decorationColor: AppColors.textLight,
    );
    final headlineTextTheme = _buildHeadlineTextTheme(baseDarkTextTheme).apply(
      bodyColor: AppColors.textLight,
      displayColor: AppColors.textLight,
      decorationColor: AppColors.textLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surfaceDarkBody,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.primaryPine,
        primary: AppColors.vibrantEmerald,
        surface: AppColors.cardDark,
        onSurface: AppColors.textLight,
        onSurfaceVariant: AppColors.textLightMuted,
        onPrimary: AppColors.headerDarkPine,
        error: AppColors.alertText,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderCardDark, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.headerDarkPine,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: AppColors.vibrantEmerald),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.headerDarkPine,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.headerDarkPine,
        selectedItemColor: AppColors.vibrantEmerald,
        unselectedItemColor: AppColors.textLightMuted,
        elevation: 8,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.vibrantEmerald,
        unselectedLabelColor: AppColors.textLightMuted,
        indicatorColor: AppColors.vibrantEmerald,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.vibrantEmerald,
          foregroundColor: AppColors.headerDarkPine,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        labelStyle: const TextStyle(color: AppColors.textLightMuted),
        hintStyle: const TextStyle(color: AppColors.textLightMuted),
        floatingLabelStyle: const TextStyle(color: AppColors.vibrantEmerald),
        prefixIconColor: AppColors.textLightMuted,
        suffixIconColor: AppColors.textLightMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderCardDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderCardDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.vibrantEmerald, width: 1.5),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.cardDark,
        titleTextStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.textLight,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardDark,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.cardDark,
        contentTextStyle: TextStyle(color: AppColors.textLight),
      ),
      iconTheme: const IconThemeData(color: AppColors.textLight),
      textTheme: baseTextTheme.copyWith(
        displayLarge: headlineTextTheme.displayLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
        displayMedium: headlineTextTheme.displayMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
        displaySmall: headlineTextTheme.displaySmall?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
        headlineLarge: headlineTextTheme.headlineLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
        headlineMedium: headlineTextTheme.headlineMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
        headlineSmall: headlineTextTheme.headlineSmall?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        titleLarge: headlineTextTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
        titleMedium: headlineTextTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        titleSmall: headlineTextTheme.titleSmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16,
          color: AppColors.textLight,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          color: AppColors.textLight,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: AppColors.textLightMuted,
        ),
        labelLarge: headlineTextTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        labelMedium: headlineTextTheme.labelMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
        labelSmall: headlineTextTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textLightMuted,
        ),
      ),
    );
  }
}
