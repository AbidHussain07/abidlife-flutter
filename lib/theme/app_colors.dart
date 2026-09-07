import 'package:flutter/material.dart';

/// ABIDLIFE color palette.
///
/// Mirrors the CSS custom-property palette in the original web app:
/// `--brand`, `--amber`, `--blue`, `--green`, `--teal`, `--orange`,
/// `--pink`, `--red`, `--income`, `--expense`, plus the surface and ink
/// tokens.
///
/// `AppColors.light` and `AppColors.dark` are the two resolved palettes;
/// `AppColors.tint(name, intensity)` mirrors the JS `tint()` helper used by
/// the bottom-nav pill, cards, and accent surfaces.
class AppColors {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color line;
  final Color ink;
  final Color ink2;
  final Color ink3;

  final Color brand;
  final Color amber;
  final Color blue;
  final Color green;
  final Color teal;
  final Color orange;
  final Color pink;
  final Color red;
  final Color income;
  final Color expense;

  const AppColors._({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.brand,
    required this.amber,
    required this.blue,
    required this.green,
    required this.teal,
    required this.orange,
    required this.pink,
    required this.red,
    required this.income,
    required this.expense,
  });

  static const AppColors light = AppColors._(
    bg: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEF0F4),
    surface3: Color(0xFFE5E8EF),
    line: Color(0x14141620),
    ink: Color(0xFF14161F),
    ink2: Color(0xFF555B6E),
    ink3: Color(0xFF8B91A4),
    brand: Color(0xFF6E5BFF),
    amber: Color(0xFFF0A32F),
    blue: Color(0xFF3E8BFF),
    green: Color(0xFF28BD6E),
    teal: Color(0xFF11A598),
    orange: Color(0xFFFF7A45),
    pink: Color(0xFFEF5DA8),
    red: Color(0xFFEF4444),
    income: Color(0xFF0DA673),
    expense: Color(0xFFF1503F),
  );

  static const AppColors dark = AppColors._(
    bg: Color(0xFF0A0C11),
    surface: Color(0xFF13161F),
    surface2: Color(0xFF1A1E2A),
    surface3: Color(0xFF232839),
    line: Color(0x14FFFFFF),
    ink: Color(0xFFF1F3FA),
    ink2: Color(0xFFA3AABD),
    ink3: Color(0xFF676E85),
    brand: Color(0xFF8B7CFF),
    amber: Color(0xFFF5B04B),
    blue: Color(0xFF62A1FF),
    green: Color(0xFF3FD68A),
    teal: Color(0xFF2CCCC0),
    orange: Color(0xFFFF8F63),
    pink: Color(0xFFF67FB8),
    red: Color(0xFFF87171),
    income: Color(0xFF34D896),
    expense: Color(0xFFFF7266),
  );

  /// Resolve a named accent (`"green"`, `"blue"`, etc.) to its [Color].
  Color accent(String name) {
    switch (name) {
      case 'amber':
        return amber;
      case 'blue':
        return blue;
      case 'green':
        return green;
      case 'teal':
        return teal;
      case 'orange':
        return orange;
      case 'pink':
        return pink;
      case 'red':
        return red;
      case 'violet':
      case 'brand':
        return brand;
      default:
        return ink2;
    }
  }

  /// Soft tinted background for a given accent, at the given intensity (0–100).
  /// Mirrors the CSS `color-mix(in srgb, accent X%, surface)` pattern.
  Color tint(String name, int intensity) {
    final base = accent(name);
    final i = intensity.clamp(0, 100) / 100.0;
    return Color.lerp(surface, base, i)!;
  }
}

/// Note card colorways (default, blue, purple, green, yellow, pink).
Color noteColor(String name, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  switch (name) {
    case 'blue':
      return dark ? const Color(0xFF172231) : const Color(0xFFE9F1FF);
    case 'purple':
      return dark ? const Color(0xFF201C33) : const Color(0xFFF0EBFF);
    case 'green':
      return dark ? const Color(0xFF182620) : const Color(0xFFE9F7EE);
    case 'yellow':
      return dark ? const Color(0xFF29220F) : const Color(0xFFFFF3D9);
    case 'pink':
      return dark ? const Color(0xFF2C1A24) : const Color(0xFFFDEAF3);
    case 'default':
    default:
      return dark ? const Color(0xFF171B26) : const Color(0xFFFFFFFF);
  }
}

const List<String> kPaletteNames = <String>[
  'amber',
  'blue',
  'green',
  'teal',
  'orange',
  'pink',
  'violet',
  'red',
];

const List<String> kNoteColors = <String>[
  'default',
  'blue',
  'purple',
  'green',
  'yellow',
  'pink',
];
