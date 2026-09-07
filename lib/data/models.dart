import '../utils/date_utils.dart';

/// Plain Dart models for every entity in the app.
///
/// Mirrors the `Note`, `Task`, `Habit`, `HabitLog`, `Account`, `Txn`
/// interfaces in the original web app's `data.tsx`. Each model knows how
/// to (de)serialize itself to/from the sqflite row format used by
/// [AppDatabase].

enum Tab { insights, notes, tasks, habits, money }

enum FrequencyType { daily, days }

class Frequency {
  final FrequencyType type;
  final List<int> days; // 0 = Sunday … 6 = Saturday (web convention)

  const Frequency({required this.type, this.days = const []});

  Map<String, dynamic> toJson() => {
        'type': type == FrequencyType.daily ? 'daily' : 'days',
        if (type == FrequencyType.days) 'days': days,
      };

  static Frequency fromJson(Map<String, dynamic> json) {
    final t = json['type'] as String? ?? 'daily';
    if (t == 'days') {
      final list = (json['days'] as List?)?.cast<int>() ?? const [];
      return Frequency(type: FrequencyType.days, days: list);
    }
    return const Frequency(type: FrequencyType.daily);
  }

  /// Stored as a JSON string in sqflite.
  String encode() =>
      type == FrequencyType.daily ? '{"type":"daily"}' : '{"type":"days","days":${days.join(',')}}';

  static Frequency decode(String? s) {
    if (s == null || s.isEmpty) return const Frequency(type: FrequencyType.daily);
    // Simple parse — format is controlled.
    if (s.contains('"days"')) {
      final m = RegExp(r'\[(.*?)\]').firstMatch(s);
      if (m != null) {
        final list = m
            .group(1)!
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .map(int.parse)
            .toList();
        return Frequency(type: FrequencyType.days, days: list);
      }
    }
    return const Frequency(type: FrequencyType.daily);
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final String color;
  final List<String> tags;
  final bool pinned;
  final bool archived;
  final bool locked;
  final bool checklist;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.color,
    required this.tags,
    required this.pinned,
    required this.archived,
    required this.locked,
    required this.checklist,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    String? title,
    String? content,
    String? color,
    List<String>? tags,
    bool? pinned,
    bool? archived,
    bool? locked,
    bool? checklist,
    DateTime? updatedAt,
  }) =>
      Note(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        color: color ?? this.color,
        tags: tags ?? this.tags,
        pinned: pinned ?? this.pinned,
        archived: archived ?? this.archived,
        locked: locked ?? this.locked,
        checklist: checklist ?? this.checklist,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory Note.fromRow(Map<String, dynamic> row) => Note(
        id: row['id'] as String,
        title: (row['title'] as String?) ?? '',
        content: (row['content'] as String?) ?? '',
        color: (row['color'] as String?) ?? 'default',
        tags: _decodeTags(row['tags'] as String?),
        pinned: (row['pinned'] as int?) == 1,
        archived: (row['archived'] as int?) == 1,
        locked: (row['locked'] as int?) == 1,
        checklist: (row['checklist'] as int?) == 1,
        createdAt: DateTime.parse(row['createdAt'] as String),
        updatedAt: DateTime.parse(row['updatedAt'] as String),
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'title': title,
        'content': content,
        'color': color,
        'tags': _encodeTags(tags),
        'pinned': pinned ? 1 : 0,
        'archived': archived ? 1 : 0,
        'locked': locked ? 1 : 0,
        'checklist': checklist ? 1 : 0,
        'pinHash': pinHashForStorage,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// The PIN hash is stored on the same row but never exposed to the UI —
  /// `toRow` writes it back via this field when present.
  String? get pinHashForStorage => _pinHash;
  set pinHashForStorage(String? v) => _pinHash = v;
  String? _pinHash;

  static List<String> _decodeTags(String? s) {
    if (s == null || s.isEmpty) return const [];
    return s.split(',').where((e) => e.isNotEmpty).toList();
  }

  static String _encodeTags(List<String> tags) => tags.join(',');
}

class Task {
  final String id;
  final String title;
  final String notes;
  final bool done;
  final String priority; // none | low | medium | high
  final String category;
  final String? dueDate; // YYYY-MM-DD
  final String? dueTime; // HH:mm
  final bool reminder;
  final String recurrence; // none | daily | weekly | monthly
  final List<int> repeatDays; // 0 = Sun … 6 = Sat
  final DateTime? completedAt;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    required this.notes,
    required this.done,
    required this.priority,
    required this.category,
    required this.dueDate,
    required this.dueTime,
    required this.reminder,
    required this.recurrence,
    required this.repeatDays,
    required this.completedAt,
    required this.createdAt,
  });

  Task copyWith({
    String? title,
    String? notes,
    bool? done,
    String? priority,
    String? category,
    String? dueDate,
    String? dueTime,
    bool? reminder,
    String? recurrence,
    List<int>? repeatDays,
    DateTime? completedAt,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        done: done ?? this.done,
        priority: priority ?? this.priority,
        category: category ?? this.category,
        dueDate: dueDate ?? this.dueDate,
        dueTime: dueTime ?? this.dueTime,
        reminder: reminder ?? this.reminder,
        recurrence: recurrence ?? this.recurrence,
        repeatDays: repeatDays ?? this.repeatDays,
        completedAt: completedAt ?? this.completedAt,
        createdAt: createdAt,
      );

  factory Task.fromRow(Map<String, dynamic> row) => Task(
        id: row['id'] as String,
        title: row['title'] as String,
        notes: (row['notes'] as String?) ?? '',
        done: (row['done'] as int?) == 1,
        priority: (row['priority'] as String?) ?? 'none',
        category: (row['category'] as String?) ?? 'Personal',
        dueDate: row['dueDate'] as String?,
        dueTime: row['dueTime'] as String?,
        reminder: (row['reminder'] as int?) == 1,
        recurrence: (row['recurrence'] as String?) ?? 'none',
        repeatDays: _decodeInts(row['repeatDays'] as String?),
        completedAt: (row['completedAt'] as String?) == null
            ? null
            : DateTime.parse(row['completedAt'] as String),
        createdAt: DateTime.parse(row['createdAt'] as String),
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'title': title,
        'notes': notes,
        'done': done ? 1 : 0,
        'priority': priority,
        'category': category,
        'dueDate': dueDate,
        'dueTime': dueTime,
        'reminder': reminder ? 1 : 0,
        'recurrence': recurrence,
        'repeatDays': repeatDays.join(','),
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class Habit {
  final String id;
  final String name;
  final String icon;
  final String color;
  final Frequency frequency;
  final bool reminder;
  final bool archived;
  final DateTime createdAt;

  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.frequency,
    required this.reminder,
    required this.archived,
    required this.createdAt,
  });

  factory Habit.fromRow(Map<String, dynamic> row) => Habit(
        id: row['id'] as String,
        name: row['name'] as String,
        icon: (row['icon'] as String?) ?? 'Sparkles',
        color: (row['color'] as String?) ?? 'green',
        frequency: Frequency.decode(row['frequency'] as String?),
        reminder: (row['reminder'] as int?) == 1,
        archived: (row['archived'] as int?) == 1,
        createdAt: DateTime.parse(row['createdAt'] as String),
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'frequency': frequency.encode(),
        'reminder': reminder ? 1 : 0,
        'archived': archived ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };
}

class HabitLog {
  final String id;
  final String habitId;
  final String date; // YYYY-MM-DD

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
  });

  factory HabitLog.fromRow(Map<String, dynamic> row) => HabitLog(
        id: row['id'] as String,
        habitId: row['habitId'] as String,
        date: row['date'] as String,
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'habitId': habitId,
        'date': date,
      };
}

class Account {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool archived;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.archived,
    required this.createdAt,
  });

  Account copyWith({
    String? name,
    String? icon,
    String? color,
    bool? archived,
  }) =>
      Account(
        id: id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        archived: archived ?? this.archived,
        createdAt: createdAt,
      );

  factory Account.fromRow(Map<String, dynamic> row) => Account(
        id: row['id'] as String,
        name: row['name'] as String,
        icon: (row['icon'] as String?) ?? 'Wallet',
        color: (row['color'] as String?) ?? 'violet',
        archived: (row['archived'] as int?) == 1,
        createdAt: DateTime.parse(row['createdAt'] as String),
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'archived': archived ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
      };
}

enum TxnType { income, expense }

class Txn {
  final String id;
  final String accountId;
  final TxnType type;
  final int amount; // paise
  final String note;
  final String category;
  final DateTime occurredAt;
  final DateTime createdAt;

  const Txn({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.note,
    required this.category,
    required this.occurredAt,
    required this.createdAt,
  });

  Txn copyWith({
    TxnType? type,
    int? amount,
    String? note,
    String? category,
    DateTime? occurredAt,
  }) =>
      Txn(
        id: id,
        accountId: accountId,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        category: category ?? this.category,
        occurredAt: occurredAt ?? this.occurredAt,
        createdAt: createdAt,
      );

  factory Txn.fromRow(Map<String, dynamic> row) => Txn(
        id: row['id'] as String,
        accountId: row['accountId'] as String,
        type: (row['type'] as String) == 'income' ? TxnType.income : TxnType.expense,
        amount: row['amount'] as int,
        note: (row['note'] as String?) ?? '',
        category: (row['category'] as String?) ?? 'Other',
        occurredAt: DateTime.parse(row['occurredAt'] as String),
        createdAt: DateTime.parse(row['createdAt'] as String),
      );

  Map<String, dynamic> toRow() => {
        'id': id,
        'accountId': accountId,
        'type': type == TxnType.income ? 'income' : 'expense',
        'amount': amount,
        'note': note,
        'category': category,
        'occurredAt': occurredAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}

List<int> _decodeInts(String? s) {
  if (s == null || s.isEmpty) return const [];
  return s.split(',').where((e) => e.isNotEmpty).map(int.parse).toList();
}

/// A transient toast message shown by the AppShell.
class Toast {
  final int id;
  final String msg;
  const Toast({required this.id, required this.msg});
}

/// Cross-module quick action (Insights → New note / New task / …).
class QuickAction {
  final Tab tab;
  final String action; // "new" | "search"
  const QuickAction({required this.tab, required this.action});
}
