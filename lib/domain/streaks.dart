import 'package:abidlife/core/formatters.dart';
import 'package:abidlife/models/models.dart';

bool isHabitScheduled(HabitModel habit, DateTime date) {
  if (dateOnly(date).isBefore(dateOnly(habit.startDate))) return false;
  return switch (habit.frequency) {
    HabitFrequency.daily => true,
    HabitFrequency.selectedDays => habit.repeatDays.contains(date.weekday),
    HabitFrequency.weeklyGoal => true,
  };
}

({int current, int best}) calculateStreaks(
  HabitModel habit,
  Iterable<HabitLogModel> logs, {
  DateTime? now,
}) {
  final today = dateOnly(now ?? DateTime.now());
  final completed = logs
      .where(
        (log) =>
            log.habitId == habit.id &&
            log.status == HabitLogStatus.completed,
      )
      .map((log) => log.date)
      .toSet();

  if (habit.frequency == HabitFrequency.weeklyGoal) {
    return _weeklyGoalStreak(habit, completed, today);
  }

  var cursor = today;
  if (isHabitScheduled(habit, cursor) && !completed.contains(dayKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  var current = 0;
  var guard = 0;
  while (guard++ < 3660 && !cursor.isBefore(dateOnly(habit.startDate))) {
    if (!isHabitScheduled(habit, cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      continue;
    }
    if (!completed.contains(dayKey(cursor))) break;
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  var best = 0;
  var run = 0;
  cursor = dateOnly(habit.startDate);
  guard = 0;
  while (!cursor.isAfter(today) && guard++ < 3660) {
    if (isHabitScheduled(habit, cursor)) {
      if (completed.contains(dayKey(cursor))) {
        run++;
        if (run > best) best = run;
      } else {
        run = 0;
      }
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return (current: current, best: best < current ? current : best);
}

({int current, int best}) _weeklyGoalStreak(
  HabitModel habit,
  Set<String> completed,
  DateTime today,
) {
  DateTime weekStart(DateTime value) =>
      dateOnly(value).subtract(Duration(days: value.weekday - 1));
  final firstWeek = weekStart(habit.startDate);
  final thisWeek = weekStart(today);
  var current = 0;
  var best = 0;
  var run = 0;
  var cursor = firstWeek;
  while (!cursor.isAfter(thisWeek)) {
    final end = cursor.add(const Duration(days: 6));
    final count = completed.where((key) {
      final date = DateTime.parse(key);
      return !date.isBefore(cursor) && !date.isAfter(end);
    }).length;
    final complete = count >= habit.weeklyGoal;
    if (complete) {
      run++;
      if (run > best) best = run;
    } else if (cursor != thisWeek) {
      run = 0;
    }
    cursor = cursor.add(const Duration(days: 7));
  }
  current = run;
  return (current: current, best: best);
}

int completionRate(
  HabitModel habit,
  Iterable<HabitLogModel> logs, {
  int days = 30,
  DateTime? now,
}) {
  final today = dateOnly(now ?? DateTime.now());
  final completed = logs
      .where(
        (log) =>
            log.habitId == habit.id &&
            log.status == HabitLogStatus.completed,
      )
      .map((log) => log.date)
      .toSet();
  var due = 0;
  var done = 0;
  for (var i = 0; i < days; i++) {
    final date = today.subtract(Duration(days: i));
    if (!isHabitScheduled(habit, date)) continue;
    due++;
    if (completed.contains(dayKey(date))) done++;
  }
  return due == 0 ? 0 : (done * 100 / due).round();
}
