import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// The single source of truth for ABIDLIFE's visual style.
///
/// `AppTheme.of(context)` resolves to the current [AppColors] based on the
/// platform brightness, so screens can call `AppTheme.of(context).green`,
/// `AppTheme.of(context).surface`, etc. — exactly the same as the original
/// web app's CSS custom properties.
class AppTheme {
  final BuildContext context;
  const AppTheme._(this.context);

  /// The resolved palette for the current [Brightness].
  static AppColors of(BuildContext context) {
    final view = View.of(context);
    return view.platformDispatcher.platformBrightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
  }

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      dividerColor: c.line,
    );

    return base.copyWith(
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.brand,
        onPrimary: Colors.white,
        secondary: c.brand,
        onSecondary: Colors.white,
        error: c.red,
        onError: Colors.white,
        surface: c.surface,
        onSurface: c.ink,
        surfaceContainerHighest: c.surface2,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: c.ink,
        displayColor: c.ink,
      ),
      primaryTextTheme:
          GoogleFonts.plusJakartaSansTextTheme(base.primaryTextTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: c.ink,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: c.line, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        hintStyle: TextStyle(color: c.ink3),
      ),
      iconTheme: IconThemeData(color: c.ink2, size: 22),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.brand,
        selectionColor: c.brand.withValues(alpha: 0.28),
        selectionHandleColor: c.brand,
      ),
      dividerTheme: DividerThemeData(
        color: c.line,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink,
        contentTextStyle: TextStyle(color: c.bg, fontWeight: FontWeight.w700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}

/// Common text styles — chosen to mirror the original web app's tight,
/// extra-bold typographic feel.
class AppText {
  const AppText._();

  static TextStyle h1(BuildContext c) => TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppTheme.of(c).ink,
      );

  static TextStyle h2(BuildContext c) => TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: AppTheme.of(c).ink,
      );

  static TextStyle label(BuildContext c) => TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: AppTheme.of(c).ink3,
      );

  static TextStyle body(BuildContext c) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.of(c).ink2,
        height: 1.5,
      );

  static TextStyle tnum(BuildContext c) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppTheme.of(c).ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
