import 'package:intl/intl.dart';

/// INR money formatting.
///
/// The original web app stores every transaction amount as integer paise
/// (1 INR = 100 paise) to avoid floating-point drift. This file mirrors
/// the `fmtINR(paise, sign)` helper, including the en-IN digit grouping
/// (e.g. ₹1,00,000) and only showing paise when the amount has a fractional
/// component.
class Fmt {
  const Fmt._();

  /// Format [paise] as an INR string.
  ///
  /// - Negative amounts are rendered with a leading "−".
  /// - If [sign] is true and [paise] is positive, a leading "+" is shown.
  /// - Fractional paise are shown only when present.
  static String inr(int paise, {bool sign = false}) {
    final neg = paise < 0;
    final abs = paise.abs();
    final hasPaise = abs % 100 != 0;
    final value = abs / 100.0;
    final numStr = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: hasPaise ? 2 : 0,
    ).format(value);
    if (neg) return '−$numStr';
    if (sign) return '+$numStr';
    return numStr;
  }

  /// Format an integer (no currency symbol) using en-IN grouping.
  static String intINR(int n) => NumberFormat.decimalPattern('en_IN').format(n);

  /// Format a [DateTime] as an ISO-8601 string compatible with the original
  /// web app's storage (e.g. `2024-08-05T13:45:00.000Z`).
  static String iso(DateTime d) => d.toIso8601String();
}
