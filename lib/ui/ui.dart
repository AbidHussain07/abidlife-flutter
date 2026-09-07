import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Shared UI helpers — mirrors the original web app's `ui.tsx` module.
///
/// Exposes:
/// - [buzz] for haptic feedback
/// - [AppPalette] named accent colors
/// - [SectionLabel] header label
/// - [EmptyState] empty placeholder
/// - [Toggle] switch
/// - [ChipButton] selectable chip
/// - [ColorRow] color picker row
/// - [RowButton] settings row button
/// - [ConfirmSheet] destructive-action confirmation modal
/// - [PinPad] 4-digit PIN entry
/// - [MoneyText] INR-formatted text widget

/* --------------------------------- Haptics -------------------------------- */

const _light = HapticFeedback.lightImpact;
const _medium = HapticFeedback.mediumImpact;
const _heavy = HapticFeedback.heavyImpact;
const _selection = HapticFeedback.selectionClick;

/// Mirrors `buzz(intensity)` from the web app. Intensity 0-15.
Future<void> buzz([int intensity = 5]) async {
  if (intensity <= 0) return;
  if (intensity <= 4) {
    await _selection;
  } else if (intensity <= 8) {
    await _light;
  } else if (intensity <= 12) {
    await _medium;
  } else {
    await _heavy;
  }
}

/* --------------------------------- Sections ------------------------------- */

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
          color: c.ink3,
        ),
      ),
    );
  }
}

/* --------------------------------- Empty ---------------------------------- */

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String color;
  final String title;
  final String sub;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final accent = c.accent(color);
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.tint(color, 14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: c.ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: c.ink3,
              height: 1.5,
            ),
          ),
          if (action != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                buzz(8);
                onAction!();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                action!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/* --------------------------------- Toggle --------------------------------- */

class Toggle extends StatelessWidget {
  const Toggle({super.key, required this.on, required this.onChange});
  final bool on;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        buzz(6);
        onChange();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: on ? c.green : c.surface3,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------------------------- Chip ---------------------------------- */

class ChipButton extends StatelessWidget {
  const ChipButton({
    super.key,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });
  final String label;
  final String color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final accent = c.accent(color);
    return GestureDetector(
      onTap: () {
        buzz(5);
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? c.tint(color, 15) : c.surface2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: active ? accent : c.ink2,
          ),
        ),
      ),
    );
  }
}

/* -------------------------------- ColorRow -------------------------------- */

class ColorRow extends StatelessWidget {
  const ColorRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.colors = kPaletteNames,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> colors;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((name) {
        final selected = value == name;
        return GestureDetector(
          onTap: () {
            buzz(5);
            onChanged(name);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.accent(name),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? c.bg : Colors.transparent,
                width: 2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: c.accent(name).withValues(alpha: 0.45),
                        blurRadius: 0,
                        spreadRadius: 3.5,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/* -------------------------------- RowButton ------------------------------- */

class RowButton extends StatelessWidget {
  const RowButton({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    this.sub,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String color;
  final String label;
  final String? sub;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final accent = danger ? c.expense : c.accent(color);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          buzz(6);
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: danger ? c.expense.withValues(alpha: 0.12) : c.tint(color, 13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: danger ? c.expense : c.ink,
                      ),
                    ),
                    if (sub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sub!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: c.ink3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------------------------- ConfirmSheet ----------------------------- */

class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    super.key,
    required this.title,
    required this.sub,
    required this.confirmLabel,
    required this.onConfirm,
  });
  final String title;
  final String sub;
  final String confirmLabel;
  final VoidCallback onConfirm;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String sub,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ConfirmSheet(
        title: title,
        sub: sub,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.surface3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c.ink,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sub,
              style: TextStyle(
                fontSize: 13.5,
                color: c.ink3,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () {
                buzz(10);
                onConfirm();
                Navigator.of(context).maybePop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.expense,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                confirmLabel,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                buzz(5);
                Navigator.of(context).maybePop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.ink2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* --------------------------------- PinPad --------------------------------- */

class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.sub,
    required this.onComplete,
    this.onCancel,
  });
  final String title;
  final String sub;
  final ValueChanged<String> onComplete;
  final VoidCallback? onCancel;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';

  void _press(String k) {
    buzz(6);
    if (k == 'back') {
      if (_pin.isEmpty) return;
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
      return;
    }
    if (_pin.length >= 4) return;
    setState(() => _pin = _pin + k);
    if (_pin.length == 4) {
      buzz(10);
      final pin = _pin;
      // Defer to next frame so the user sees the 4th dot fill.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete(pin);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.sub,
              style: TextStyle(fontSize: 12.5, color: c.ink3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: filled ? c.brand : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: filled ? c.brand : c.surface3,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.4,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              physics: const NeverScrollableScrollPhysics(),
              children: keys.map((k) {
                if (k.isEmpty) return const SizedBox.shrink();
                return InkWell(
                  onTap: k.isEmpty ? null : () => _press(k),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    alignment: Alignment.center,
                    child: k == 'back'
                        ? Icon(LucideIcons.delete, size: 22, color: c.ink2)
                        : Text(
                            k,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: c.ink,
                            ),
                          ),
                  ),
                );
              }).toList(),
            ),
            if (widget.onCancel != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.ink3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* -------------------------------- MoneyText ------------------------------- */

class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.paise,
    this.sign = false,
    this.style,
  });
  final int paise;
  final bool sign;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final neg = paise < 0;
    final abs = paise.abs();
    final hasPaise = abs % 100 != 0;
    final value = abs / 100.0;
    final f = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: hasPaise ? 2 : 0,
    );
    final numStr = f.format(value);
    final prefix = neg ? '−' : (sign ? '+' : '');
    return Text(
      '$prefix₹$numStr',
      style: (style ?? const TextStyle()).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/* -------------------------------- Icons ----------------------------------- */

/// Icons used for habit + account pickers. Keys mirror the web app.
const Map<String, IconData> kHabitIcons = {
  'Sparkles': LucideIcons.sparkles,
  'Flame': LucideIcons.flame,
  'Heart': LucideIcons.heart,
  'Bolt': LucideIcons.zap,
  'Moon': LucideIcons.moon,
  'Sun': LucideIcons.sun,
  'Star': LucideIcons.star,
  'Target': LucideIcons.target,
  'BookOpen': LucideIcons.bookOpen,
  'Dumbbell': LucideIcons.dumbbell,
  'Coffee': LucideIcons.coffee,
  'Apple': LucideIcons.apple,
  'Droplet': LucideIcons.droplet,
  'Footprints': LucideIcons.footprints,
  'Brain': LucideIcons.brain,
};

const Map<String, IconData> kAccountIcons = {
  'Wallet': LucideIcons.wallet,
  'CreditCard': LucideIcons.creditCard,
  'Banknote': LucideIcons.banknote,
  'PiggyBank': LucideIcons.piggyBank,
  'Building': LucideIcons.building2,
  'Home': LucideIcons.home,
  'User': LucideIcons.user,
  'Users': LucideIcons.users,
  'Briefcase': LucideIcons.briefcase,
  'Gift': LucideIcons.gift,
};

const Map<String, IconData> kCategoryIcons = {
  'Food': LucideIcons.utensils,
  'Transport': LucideIcons.car,
  'Shopping': LucideIcons.shoppingBag,
  'Bills': LucideIcons.receipt,
  'Health': LucideIcons.heartPulse,
  'Entertainment': LucideIcons.film,
  'Travel': LucideIcons.plane,
  'Education': LucideIcons.graduationCap,
  'Salary': LucideIcons.banknote,
  'Investment': LucideIcons.trendingUp,
  'Gift': LucideIcons.gift,
  'Other': LucideIcons.circleDot,
};

const List<String> kMoneyCategories = [
  'Food',
  'Transport',
  'Shopping',
  'Bills',
  'Health',
  'Entertainment',
  'Travel',
  'Education',
  'Salary',
  'Investment',
  'Gift',
  'Other',
];

const List<String> kTaskCategories = [
  'Personal',
  'Work',
  'Home',
  'Health',
  'Finance',
  'Learning',
  'Errands',
];
