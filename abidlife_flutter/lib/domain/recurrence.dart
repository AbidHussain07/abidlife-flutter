import 'package:abidlife/models/models.dart';

DateTime? nextTaskOccurrence(TaskModel task) {
  final due = task.dueAt;
  if (due == null || task.recurrence == RecurrenceType.none) return null;
  return switch (task.recurrence) {
    RecurrenceType.daily => due.add(const Duration(days: 1)),
    RecurrenceType.monthly => DateTime(
        due.month == 12 ? due.year + 1 : due.year,
        due.month == 12 ? 1 : due.month + 1,
        due.day,
        due.hour,
        due.minute,
      ),
    RecurrenceType.weekly => _nextSelectedWeekday(due, task.repeatDays),
    RecurrenceType.none => null,
  };
}

DateTime _nextSelectedWeekday(DateTime due, List<int> selected) {
  final days = selected.isEmpty ? <int>[due.weekday] : selected;
  for (var offset = 1; offset <= 7; offset++) {
    final candidate = due.add(Duration(days: offset));
    if (days.contains(candidate.weekday)) return candidate;
  }
  return due.add(const Duration(days: 7));
}
