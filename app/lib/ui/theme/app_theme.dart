// =============================================================================
// الثيم العام (جدول 4-2 في الوثيقة):
// - الخط: IBM Plex Sans Arabic (مضمَّن، يدعم العربية واللاتينية).
// - البطاقات بزوايا 18، الأزرار 16 وارتفاع 50، شبكة مسافات من مضاعفات 4 و 8.
// - مساحة لمس لا تقل عن 44 نقطة.
// =============================================================================

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// ثوابت المسافات والزوايا — استخدمها بدل الأرقام المباشرة.
abstract final class Insets {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// الهامش الجانبي للشاشات.
  static const screen = 16.0;
}

abstract final class Radii {
  static const card = 18.0;
  static const button = 16.0;
  static const chip = 12.0;
  static const sheet = 24.0;
}

abstract final class AppTheme {
  static const fontFamily = 'IBMPlexSansArabic';

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
      primary: c.primary,
      error: c.expense,
      surface: c.surface,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: c.background,
      extensions: [c],
    );
    final text = base.textTheme.apply(
      bodyColor: c.textPrimary,
      displayColor: c.textPrimary,
    );

    return base.copyWith(
      textTheme: text.copyWith(
        // العناوين 21 نقطة، النص 13–15، الأرقام الكبيرة 30–38 عريضة.
        titleLarge: text.titleLarge?.copyWith(fontSize: 21, fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 15),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: text.bodySmall?.copyWith(fontSize: 12.5, color: c.textSecondary),
        displaySmall: text.displaySmall?.copyWith(fontSize: 34, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: c.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: c.primary,
          foregroundColor: brightness == Brightness.light ? Colors.white : c.background,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.button)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          foregroundColor: c.textPrimary,
          side: BorderSide(color: c.border),
          backgroundColor: c.surface,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.button)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          minimumSize: const Size(44, 44),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.button),
          borderSide: BorderSide(color: c.expense),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: c.surface,
        selectedColor: c.primary,
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.chip)),
        labelStyle: TextStyle(fontFamily: fontFamily, color: c.textPrimary),
        secondaryLabelStyle: const TextStyle(fontFamily: fontFamily, color: Colors.white),
        showCheckmark: false,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: TextStyle(fontFamily: fontFamily, color: c.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.chip)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : null,
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        minTileHeight: 56,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? c.primary : c.textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? c.primary : c.textSecondary,
          ),
        ),
      ),
    );
  }
}
