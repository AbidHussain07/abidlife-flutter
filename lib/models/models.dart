import 'dart:convert';

T enumValue<T extends Enum>(Iterable<T> values, String? name, T fallback) {
  return values.where((value) => value.name == name).firstOrNull ?? fallback;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

List<String> stringList(Object? value) {
  if (value == null || value == '') return <String>[];
  return (jsonDecode(value as String) as List<dynamic>).cast<String>();
}

List<int> intList(Object? value) {
  if (value == null || value == '') return <int>[];
  return (jsonDecode(value as String) as List<dynamic>).cast<int>();
}

DateTime? dateTimeOrNull(Object? value) =>
    value == null ? null : DateTime.fromMillisecondsSinceEpoch(value as int);

class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    required this.deltaJson,
    required this.color,
    required this.tags,
    required this.pinned,
    required this.archived,
    required this.locked,
    required this.createdAt,
    required this.updatedAt,
    this.sessionUnlocked = false,
  });

  final String id;
  final String title;
  final String deltaJson;
  final String color;
  final List<String> tags;
  final bool pinned;
  final bool archived;
  final bool locked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool sessionUnlocked;

  factory NoteModel.fromMap(Map<String, Object?> map, {bool exposeBody = false}) {
    final locked = (map['locked'] as int) == 1;
    return NoteModel(
      id: map['id'] as String,
      title: map['title'] as String,
      deltaJson: locked && !exposeBody ? '' : map['content_delta'] as String,
      color: map['color'] as String,
      tags: stringList(map['tags']),
      pinned: (map['pinned'] as int) == 1,
      archived: (map['archived'] as int) == 1,
      locked: locked,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      sessionUnlocked: locked && exposeBody,
    );
  }

  Map<String, Object?> toMap({String? persistedContent}) => <String, Object?>{
        'id': id,
        'title': title,
        'content_delta': persistedContent ?? deltaJson,
        'color': color,
        'tags': jsonEncode(tags),
        'pinned': pinned ? 1 : 0,
        'archived': archived ? 1 : 0,
        'locked': locked ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  NoteModel copyWith({
    String? title,
    String? deltaJson,
    String? color,
    List<String>? tags,
    bool? pinned,
    bool? archived,
    bool? locked,
    DateTime? updatedAt,
    bool? sessionUnlocked,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      deltaJson: deltaJson ?? this.deltaJson,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
      locked: locked ?? this.locked,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionUnlocked: sessionUnlocked ?? this.sessionUnlocked,
    );
  }
}

enum TaskPriority { none, low, medium, high }
enum RecurrenceType { none, daily, weekly, monthly }

class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.details,
    required this.done,
    required this.priority,
    required this.category,
    required this.dueAt,
    required this.reminder,
    required this.recurrence,
    required this.repeatDays,
    required this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String details;
  final bool done;
  final TaskPriority priority;
  final String category;
  final DateTime? dueAt;
  final bool reminder;
  final RecurrenceType recurrence;
  /// ISO weekdays: Monday = 1, Sunday = 7.
  final List<int> repeatDays;
  final DateTime? completedAt;
  final DateTime createdAt;

  factory TaskModel.fromMap(Map<String, Object?> map) => TaskModel(
        id: map['id'] as String,
        title: map['title'] as String,
        details: map['details'] as String,
        done: (map['done'] as int) == 1,
        priority: enumValue(TaskPriority.values, map['priority'] as String?, TaskPriority.none),
        category: map['category'] as String,
        dueAt: dateTimeOrNull(map['due_at']),
        reminder: (map['reminder'] as int) == 1,
        recurrence: enumValue(
          RecurrenceType.values,
          map['recurrence'] as String?,
          RecurrenceType.none,
        ),
        repeatDays: intList(map['repeat_days']),
        completedAt: dateTimeOrNull(map['completed_at']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'title': title,
        'details': details,
        'done': done ? 1 : 0,
        'priority': priority.name,
        'category': category,
        'due_at': dueAt?.millisecondsSinceEpoch,
        'reminder': reminder ? 1 : 0,
        'recurrence': recurrence.name,
        'repeat_days': jsonEncode(repeatDays),
        'completed_at': completedAt?.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  TaskModel copyWith({
    String? title,
    String? details,
    bool? done,
    TaskPriority? priority,
    String? category,
    DateTime? dueAt,
    bool clearDueAt = false,
    bool? reminder,
    RecurrenceType? recurrence,
    List<int>? repeatDays,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      details: details ?? this.details,
      done: done ?? this.done,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueAt: clearDueAt ? null : dueAt ?? this.dueAt,
      reminder: reminder ?? this.reminder,
      recurrence: recurrence ?? this.recurrence,
      repeatDays: repeatDays ?? this.repeatDays,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      createdAt: createdAt,
    );
  }
}

enum HabitFrequency { daily, selectedDays, weeklyGoal }
enum HabitLogStatus { completed, skipped, rest }

class HabitModel {
  const HabitModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.frequency,
    required this.repeatDays,
    required this.weeklyGoal,
    required this.reminder,
    required this.reminderHour,
    required this.reminderMinute,
    required this.startDate,
    required this.archived,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final HabitFrequency frequency;
  final List<int> repeatDays;
  final int weeklyGoal;
  final bool reminder;
  final int reminderHour;
  final int reminderMinute;
  final DateTime startDate;
  final bool archived;
  final DateTime createdAt;

  factory HabitModel.fromMap(Map<String, Object?> map) => HabitModel(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String,
        color: map['color'] as String,
        frequency: enumValue(
          HabitFrequency.values,
          map['frequency'] as String?,
          HabitFrequency.daily,
        ),
        repeatDays: intList(map['repeat_days']),
        weeklyGoal: map['weekly_goal'] as int,
        reminder: (map['reminder'] as int) == 1,
        reminderHour: map['reminder_hour'] as int,
        reminderMinute: map['reminder_minute'] as int,
        startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
        archived: (map['archived'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'frequency': frequency.name,
        'repeat_days': jsonEncode(repeatDays),
        'weekly_goal': weeklyGoal,
        'reminder': reminder ? 1 : 0,
        'reminder_hour': reminderHour,
        'reminder_minute': reminderMinute,
        'start_date': startDate.millisecondsSinceEpoch,
        'archived': archived ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}

class HabitLogModel {
  const HabitLogModel({
    required this.id,
    required this.habitId,
    required this.date,
    required this.status,
  });

  final String id;
  final String habitId;
  final String date;
  final HabitLogStatus status;

  factory HabitLogModel.fromMap(Map<String, Object?> map) => HabitLogModel(
        id: map['id'] as String,
        habitId: map['habit_id'] as String,
        date: map['date'] as String,
        status: enumValue(
          HabitLogStatus.values,
          map['status'] as String?,
          HabitLogStatus.completed,
        ),
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'habit_id': habitId,
        'date': date,
        'status': status.name,
      };
}

class MoneyAccountModel {
  const MoneyAccountModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.archived,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final bool archived;
  final DateTime createdAt;

  factory MoneyAccountModel.fromMap(Map<String, Object?> map) => MoneyAccountModel(
        id: map['id'] as String,
        name: map['name'] as String,
        icon: map['icon'] as String,
        color: map['color'] as String,
        archived: (map['archived'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'archived': archived ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}

enum TransactionType { income, expense }

class MoneyTransactionModel {
  const MoneyTransactionModel({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amountPaise,
    required this.note,
    required this.category,
    required this.occurredAt,
    required this.createdAt,
  });

  final String id;
  final String accountId;
  final TransactionType type;
  final int amountPaise;
  final String note;
  final String category;
  final DateTime occurredAt;
  final DateTime createdAt;

  factory MoneyTransactionModel.fromMap(Map<String, Object?> map) =>
      MoneyTransactionModel(
        id: map['id'] as String,
        accountId: map['account_id'] as String,
        type: enumValue(
          TransactionType.values,
          map['type'] as String?,
          TransactionType.expense,
        ),
        amountPaise: map['amount_paise'] as int,
        note: map['note'] as String,
        category: map['category'] as String,
        occurredAt: DateTime.fromMillisecondsSinceEpoch(map['occurred_at'] as int),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'account_id': accountId,
        'type': type.name,
        'amount_paise': amountPaise,
        'note': note,
        'category': category,
        'occurred_at': occurredAt.millisecondsSinceEpoch,
        'created_at': createdAt.millisecondsSinceEpoch,
      };
}
