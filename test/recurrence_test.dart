import 'package:abidlife/domain/recurrence.dart';
import 'package:abidlife/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

TaskModel task({
  required DateTime due,
  required RecurrenceType recurrence,
  List<int> days = const <int>[],
}) =>
    TaskModel(
      id: 't1',
      title: 'Task',
      details: '',
      done: false,
      priority: TaskPriority.none,
      category: 'Personal',
      dueAt: due,
      reminder: false,
      recurrence: recurrence,
      repeatDays: days,
      completedAt: null,
      createdAt: DateTime(2025),
    );

void main() {
  test('6 daily recurrence advances one day', () {
    final due = DateTime(2025, 1, 1, 19, 30);
    expect(nextTaskOccurrence(task(due: due, recurrence: RecurrenceType.daily)), DateTime(2025, 1, 2, 19, 30));
  });

  test('7 weekly recurrence defaults to original weekday', () {
    final monday = DateTime(2025, 1, 6, 8);
    expect(nextTaskOccurrence(task(due: monday, recurrence: RecurrenceType.weekly)), DateTime(2025, 1, 13, 8));
  });

  test('8 weekly recurrence picks next selected weekday', () {
    final friday = DateTime(2025, 1, 10, 8);
    final next = nextTaskOccurrence(task(
      due: friday,
      recurrence: RecurrenceType.weekly,
      days: const <int>[DateTime.saturday, DateTime.sunday],
    ));
    expect(next, DateTime(2025, 1, 11, 8));
  });

  test('9 weekly recurrence wraps to first selected weekday', () {
    final sunday = DateTime(2025, 1, 12, 8);
    final next = nextTaskOccurrence(task(
      due: sunday,
      recurrence: RecurrenceType.weekly,
      days: const <int>[DateTime.saturday, DateTime.sunday],
    ));
    expect(next, DateTime(2025, 1, 18, 8));
  });

  test('10 monthly recurrence advances calendar month', () {
    final due = DateTime(2025, 1, 15, 12);
    expect(nextTaskOccurrence(task(due: due, recurrence: RecurrenceType.monthly)), DateTime(2025, 2, 15, 12));
  });
}
