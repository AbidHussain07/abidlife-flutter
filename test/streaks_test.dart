import 'package:abidlife/core/formatters.dart';
import 'package:abidlife/domain/streaks.dart';
import 'package:abidlife/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

HabitModel habit({
  HabitFrequency frequency = HabitFrequency.daily,
  List<int> days = const <int>[],
}) =>
    HabitModel(
      id: 'h1',
      name: 'Read',
      icon: 'read',
      color: 'green',
      frequency: frequency,
      repeatDays: days,
      weeklyGoal: 3,
      reminder: false,
      reminderHour: 20,
      reminderMinute: 0,
      startDate: DateTime(2025),
      archived: false,
      createdAt: DateTime(2025),
    );

HabitLogModel log(DateTime date) => HabitLogModel(
      id: dayKey(date),
      habitId: 'h1',
      date: dayKey(date),
      status: HabitLogStatus.completed,
    );

void main() {
  final now = DateTime(2025, 1, 10);

  test('1 daily consecutive completions build a streak', () {
    final logs = <HabitLogModel>[log(now), log(now.subtract(const Duration(days: 1)))];
    expect(calculateStreaks(habit(), logs, now: now).current, 2);
  });

  test('2 missed required day resets current streak', () {
    final logs = <HabitLogModel>[log(now), log(now.subtract(const Duration(days: 2)))];
    expect(calculateStreaks(habit(), logs, now: now).current, 1);
  });

  test('3 best streak survives a later reset', () {
    final logs = <HabitLogModel>[
      log(now),
      for (var i = 3; i <= 7; i++) log(now.subtract(Duration(days: i))),
    ];
    expect(calculateStreaks(habit(), logs, now: now).best, 5);
  });

  test('4 non-scheduled weekdays do not break selected-day streak', () {
    final selected = habit(
      frequency: HabitFrequency.selectedDays,
      days: const <int>[DateTime.monday, DateTime.friday],
    );
    final friday = DateTime(2025, 1, 10);
    final monday = DateTime(2025, 1, 6);
    expect(calculateStreaks(selected, <HabitLogModel>[log(friday), log(monday)], now: friday).current, 2);
  });

  test('5 completion rate only counts scheduled days', () {
    final selected = habit(
      frequency: HabitFrequency.selectedDays,
      days: <int>[now.weekday],
    );
    expect(completionRate(selected, <HabitLogModel>[log(now)], days: 1, now: now), 100);
  });
}
