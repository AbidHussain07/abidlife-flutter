import 'package:intl/intl.dart';

String dayKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String greeting([DateTime? value]) {
  final hour = (value ?? DateTime.now()).hour;
  if (hour >= 5 && hour < 12) return 'Good Morning ☀️';
  if (hour >= 12 && hour < 17) return 'Good Afternoon 🌤️';
  if (hour >= 17 && hour < 21) return 'Good Evening 🌙';
  return 'Good Night 🌌';
}

String formatMoney(int paise, {bool signed = false}) {
  final amount = paise.abs() / 100;
  final whole = paise.abs() % 100 == 0;
  final number = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: whole ? 0 : 2,
  ).format(amount);
  if (paise < 0) return '−$number';
  if (signed) return '+$number';
  return number;
}

String relativeDay(DateTime value, [DateTime? now]) {
  final today = dateOnly(now ?? DateTime.now());
  final day = dateOnly(value);
  final difference = today.difference(day).inDays;
  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  if (difference == -1) return 'Tomorrow';
  return DateFormat('d MMM').format(value);
}

String timeLabel(DateTime value) => DateFormat('h:mm a').format(value);
