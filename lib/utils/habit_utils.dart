import '../data/models.dart';
import 'date_utils.dart';

/// Habit computation helpers — streaks, completion rate, scheduling.
///
/// Ported verbatim from the original web app's `getStreaks`,
/// `completionRate`, `scheduledOn` and `nextOccurrenceDate` functions so
/// the Flutter build behaves identically.
class HabitUtils {
  const HabitUtils._();

  /// True if the habit is scheduled on [d] based on its frequency.
  static bool scheduledOn(Habit habit, DateTime d) {
    if (habit.frequency.type == FrequencyType.days) {
      // Dart: weekday is 1..7 (Mon..Sun). Web: getDay() is 0..6 (Sun..Sat).
      // Convert to the web convention (0 = Sunday).
      final webDay = d.weekday % 7;
      return habit.frequency.days.contains(webDay);
    }
    return true;
  }

  /// Current + best streak for [habit] given the set of completed date
  /// strings.
  static Streaks getStreaks(
    Habit habit,
    Set<String> dates, {
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    var current = 0;
    var d = DateTime(n.year, n.month, n.day);
    var guard = 0;

    // If today is scheduled but not done, start counting from yesterday.
    if (scheduledOn(habit, d) && !dates.contains(AbidDates.dateStr(d))) {
      d = AbidDates.addDays(d, -1);
    }
    while (guard++ < 2000) {
      if (!scheduledOn(habit, d)) {
        d = AbidDates.addDays(d, -1);
        continue;
      }
      if (!dates.contains(AbidDates.dateStr(d))) break;
      current++;
      d = AbidDates.addDays(d, -1);
    }

    // Best streak: walk from creation (or first log) to now.
    final start = DateTime(
      habit.createdAt.year,
      habit.createdAt.month,
      habit.createdAt.day,
    );
    var run = 0;
    var best = 0;
    var cursor = start;
    final end = DateTime(n.year, n.month, n.day);
    guard = 0;
    while (!cursor.isAfter(end) && guard++ < 4000) {
      if (scheduledOn(habit, cursor)) {
        if (dates.contains(AbidDates.dateStr(cursor))) {
          run++;
          if (run > best) best = run;
        } else {
          run = 0;
        }
      }
      cursor = AbidDates.addDays(cursor, 1);
    }
    if (current > best) best = current;
    return Streaks(current: current, best: best);
  }

  /// Completion rate over the last [days] days.
  static int completionRate(
    Habit habit,
    Set<String> dates, {
    int days = 30,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    var scheduled = 0;
    var done = 0;
    for (var i = 0; i < days; i++) {
      final d = AbidDates.addDays(n, -i);
      if (d.isBefore(habit.createdAt)) continue;
      if (!scheduledOn(habit, d)) continue;
      scheduled++;
      if (dates.contains(AbidDates.dateStr(d))) done++;
    }
    return scheduled == 0 ? 0 : ((done / scheduled) * 100).round();
  }

  /// Next occurrence after the task's current due date, based on its
  /// recurrence rule.
  static String nextOccurrenceDate({
    required String dueDate,
    required String recurrence,
    required List<int> repeatDays,
  }) {
    final due = AbidDates.parseD(dueDate);
    if (recurrence == 'daily') {
      return AbidDates.dateStr(AbidDates.addDays(due, 1));
    }
    if (recurrence == 'monthly') {
      return AbidDates.dateStr(AbidDates.addMonths(due, 1));
    }
    if (recurrence == 'weekly') {
      final days = repeatDays.isNotEmpty
          ? (List<int>.from(repeatDays)..sort())
          : [due.weekday % 7];
      for (var i = 1; i <= 7; i++) {
        final cand = AbidDates.addDays(due, i);
        if (days.contains(cand.weekday % 7)) {
          return AbidDates.dateStr(cand);
        }
      }
    }
    return dueDate;
  }
}

class Streaks {
  final int current;
  final int best;
  const Streaks({required this.current, required this.best});
}
