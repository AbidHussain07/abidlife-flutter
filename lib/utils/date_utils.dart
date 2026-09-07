import 'package:intl/intl.dart';

/// Date helpers shared across all screens.
///
/// Mirrors the original web app's `dateStr`, `todayStr`, `parseD`, `greeting`
/// helpers, plus a few extra formatters the Flutter UI needs.
class AbidDates {
  const AbidDates._();

  /// `YYYY-MM-DD` (the format used for habit logs and task due dates).
  static String dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String todayStr() => dateStr(DateTime.now());

  /// Parse a `YYYY-MM-DD` string into a [DateTime] at local midnight.
  static DateTime parseD(String s) {
    final parts = s.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1] - 1, parts[2]);
  }

  /// True if [a] and [b] are the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  /// ISO-week (Monday-start) check.
  static bool isSameWeek(DateTime a, DateTime b, {int weekStartsOn = 1}) {
    final aStart = _weekStart(a, weekStartsOn);
    final bStart = _weekStart(b, weekStartsOn);
    return isSameDay(aStart, bStart);
  }

  static DateTime _weekStart(DateTime d, int weekStartsOn) {
    final diff = (d.weekday - weekStartsOn + 7) % 7;
    return DateTime(d.year, d.month, d.day - diff);
  }

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);
  static DateTime endOfMonth(DateTime d) =>
      DateTime(d.year, d.month + 1, 0, 23, 59, 59);

  static DateTime addMonths(DateTime d, int n) =>
      DateTime(d.year, d.month + n, d.day);

  static DateTime addDays(DateTime d, int n) => DateTime(
        d.year,
        d.month,
        d.day + n,
        d.hour,
        d.minute,
        d.second,
      );

  /// "Today" / "Yesterday" / "EEEE, d MMM" (e.g. "Monday, 5 Aug").
  static String dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEEE, d MMM').format(d);
  }

  /// "EEEE, d MMMM yyyy" (e.g. "Monday, 5 August 2024").
  static String longDate(DateTime d) => DateFormat('EEEE, d MMMM yyyy').format(d);

  /// "d MMM yyyy" (e.g. "5 Aug 2024").
  static String mediumDate(DateTime d) => DateFormat('d MMM yyyy').format(d);

  /// "d MMM" (e.g. "5 Aug").
  static String shortDate(DateTime d) => DateFormat('d MMM').format(d);

  /// "h:mm a" (e.g. "3:45 PM").
  static String time(DateTime d) => DateFormat('h:mm a').format(d);

  /// Single-letter weekday (M T W T F S S) using the [weekday] index 1..7
  /// (Dart's DateTime.weekday, where Monday = 1).
  static String weekdayShort(int weekday) {
    const labels = <String>['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[weekday];
  }

  /// Greeting based on the hour of day.
  static String greeting(int hour) {
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  /// "MMMM yyyy" (e.g. "August 2024").
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
}
