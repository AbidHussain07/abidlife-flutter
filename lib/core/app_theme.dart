import 'package:flutter/material.dart';

abstract final class AppColors {
  static const brand = Color(0xFF6E5BFF);
  static const blue = Color(0xFF3E8BFF);
  static const green = Color(0xFF28BD6E);
  static const teal = Color(0xFF11A598);
  static const amber = Color(0xFFF0A32F);
  static const orange = Color(0xFFFF7A45);
  static const pink = Color(0xFFEF5DA8);
  static const violet = brand;
  static const expense = Color(0xFFEF5546);
  static const income = Color(0xFF0DA673);
  static const lightBackground = Color(0xFFF5F5F7);
  static const darkBackground = Color(0xFF0A0C11);
  static const darkSurface = Color(0xFF141720);

  static Color habit(String name) => <String, Color>{
        'green': green,
        'blue': blue,
        'violet': brand,
        'orange': orange,
        'teal': teal,
        'pink': pink,
      }[name] ?? green;

  static Color note(String name, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return <String, Color>{
          'default': dark ? const Color(0xFF171B26) : Colors.white,
          'blue': dark ? const Color(0xFF172231) : const Color(0xFFE9F1FF),
          'purple': dark ? const Color(0xFF201C33) : const Color(0xFFF0EBFF),
          'green': dark ? const Color(0xFF182620) : const Color(0xFFE9F7EE),
          'yellow': dark ? const Color(0xFF29220F) : const Color(0xFFFFF3D9),
          'pink': dark ? const Color(0xFF2C1A24) : const Color(0xFFFDEAF3),
        }[name] ??
        (dark ? const Color(0xFF171B26) : Colors.white);
  }
}

abstract final class AppTheme {
  static ThemeData light() => _theme(Brightness.light);
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      surface: dark ? AppColors.darkSurface : Colors.white,
      error: AppColors.expense,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'PlusJakartaSans',
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? AppColors.darkBackground : AppColors.lightBackground,
      cardColor: dark ? AppColors.darkSurface : Colors.white,
      dividerColor: dark ? Colors.white.withValues(alpha: .07) : Colors.black.withValues(alpha: .07),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontFamily: 'PlusJakartaSans',
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: dark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: .08),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1A1E2A) : const Color(0xFFEEF0F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? AppColors.darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? AppColors.darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF151821) : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brand.withValues(alpha: .13),
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      textTheme: ThemeData(brightness: brightness).textTheme.copyWith(
            headlineMedium: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
              color: scheme.onSurface,
            ),
            titleLarge: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
            titleMedium: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
            bodyMedium: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
            labelLarge: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w800,
            ),
          ),
    );
  }
}
