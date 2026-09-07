import 'dart:math';

import 'package:abidlife/models/models.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  var _initialized = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'abidlife_tasks',
      'Task reminders',
      channelDescription: 'Reminders for tasks you create in ABIDLIFE',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    ),
  );

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final current = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(current));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;
  }

  int _baseId(String taskId) => taskId.hashCode.abs() % 100000000;

  Future<void> cancelTask(String taskId) async {
    await initialize();
    final base = _baseId(taskId);
    for (var offset = 0; offset < 8; offset++) {
      await _plugin.cancel(base + offset);
    }
  }

  Future<void> scheduleTask(TaskModel task) async {
    await cancelTask(task.id);
    if (!task.reminder || task.done || task.dueAt == null) return;

    final due = task.dueAt!;
    final base = _baseId(task.id);
    if (task.recurrence == RecurrenceType.weekly) {
      final days = task.repeatDays.isEmpty ? <int>[due.weekday] : task.repeatDays;
      for (var index = 0; index < days.length; index++) {
        final scheduled = _nextWeekdayTime(days[index], due.hour, due.minute);
        await _schedule(
          base + index,
          task,
          scheduled,
          match: DateTimeComponents.dayOfWeekAndTime,
        );
      }
      return;
    }

    var scheduled = tz.TZDateTime.from(due, tz.local);
    DateTimeComponents? match;
    if (task.recurrence == RecurrenceType.daily) {
      match = DateTimeComponents.time;
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    } else if (task.recurrence == RecurrenceType.monthly) {
      match = DateTimeComponents.dayOfMonthAndTime;
      if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
        scheduled = _nextMonth(scheduled);
      }
    } else if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }
    await _schedule(base, task, scheduled, match: match);
  }

  Future<void> _schedule(
    int id,
    TaskModel task,
    tz.TZDateTime when, {
    DateTimeComponents? match,
  }) async {
    await _plugin.zonedSchedule(
      id,
      'ABIDLIFE reminder',
      task.title,
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: match,
      payload: 'task:${task.id}',
    );
  }

  tz.TZDateTime _nextWeekdayTime(int weekday, int hour, int minute) {
    var candidate = tz.TZDateTime.now(tz.local);
    candidate = tz.TZDateTime(
      tz.local,
      candidate.year,
      candidate.month,
      candidate.day,
      hour,
      minute,
    );
    for (var guard = 0; guard < 8; guard++) {
      if (candidate.weekday == weekday &&
          candidate.isAfter(tz.TZDateTime.now(tz.local))) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  Future<void> cancelHabit(String habitId) async {
    await initialize();
    final base = 'habit:$habitId'.hashCode.abs() % 100000000;
    for (var offset = 0; offset < 8; offset++) {
      await _plugin.cancel(base + offset);
    }
  }

  Future<void> scheduleHabit(HabitModel habit) async {
    await cancelHabit(habit.id);
    if (!habit.reminder || habit.archived) return;
    final base = 'habit:${habit.id}'.hashCode.abs() % 100000000;
    final days = habit.frequency == HabitFrequency.selectedDays
        ? habit.repeatDays
        : const <int>[];
    if (days.isNotEmpty) {
      for (var index = 0; index < days.length; index++) {
        await _plugin.zonedSchedule(
          base + index,
          'ABIDLIFE habit',
          'Time for ${habit.name}',
          _nextWeekdayTime(
            days[index],
            habit.reminderHour,
            habit.reminderMinute,
          ),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'habit:${habit.id}',
        );
      }
      return;
    }
    var when = tz.TZDateTime(
      tz.local,
      tz.TZDateTime.now(tz.local).year,
      tz.TZDateTime.now(tz.local).month,
      tz.TZDateTime.now(tz.local).day,
      habit.reminderHour,
      habit.reminderMinute,
    );
    if (when.isBefore(tz.TZDateTime.now(tz.local))) {
      when = when.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      base,
      'ABIDLIFE habit',
      'Time for ${habit.name}',
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'habit:${habit.id}',
    );
  }

  tz.TZDateTime _nextMonth(tz.TZDateTime date) {
    final nextMonth = date.month == 12 ? 1 : date.month + 1;
    final nextYear = date.month == 12 ? date.year + 1 : date.year;
    final lastDay = DateTime(nextYear, nextMonth + 1, 0).day;
    return tz.TZDateTime(
      tz.local,
      nextYear,
      nextMonth,
      min(date.day, lastDay),
      date.hour,
      date.minute,
    );
  }
}
