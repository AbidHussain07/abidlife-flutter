import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';
import 'schema.dart';

/// ABIDLIFE local-first database.
///
/// A thin wrapper around sqflite. Every method is async and returns plain
/// model objects — no streams, no codegen, no drift. The schema is created
/// in a single pass on first launch and never migrated in v1.
class AppDatabase {
  Database? _db;

  Future<Database> _open() async {
    if (_db != null && _db!.isOpen) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, Schema.dbFile);
    _db = await openDatabase(
      path,
      version: Schema.dbVersion,
      onCreate: (db, _) async {
        await db.execute(Schema.createNotes);
        await db.execute(Schema.createTasks);
        await db.execute(Schema.createHabits);
        await db.execute(Schema.createHabitLogs);
        await db.execute(Schema.createAccounts);
        await db.execute(Schema.createTransactions);
      },
    );
    return _db!;
  }

  /* --------------------------------- Notes -------------------------------- */

  Future<List<Note>> fetchNotes() async {
    final db = await _open();
    final rows = await db.query(Schema.notes, orderBy: 'updatedAt DESC');
    return rows.map(Note.fromRow).toList();
  }

  Future<Note> insertNote({String color = 'default', bool checklist = false}) async {
    final db = await _open();
    final now = DateTime.now().toIso8601String();
    final id = _uuid();
    final row = {
      'id': id,
      'title': '',
      'content': '',
      'color': color,
      'tags': '',
      'pinned': 0,
      'archived': 0,
      'locked': 0,
      'checklist': checklist ? 1 : 0,
      'createdAt': now,
      'updatedAt': now,
    };
    await db.insert(Schema.notes, row);
    return Note(
      id: id,
      title: '',
      content: '',
      color: color,
      tags: const [],
      pinned: false,
      archived: false,
      locked: false,
      checklist: checklist,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<Note> updateNote(String id, Map<String, dynamic> patch) async {
    final db = await _open();
    final row = <String, dynamic>{'updatedAt': DateTime.now().toIso8601String()};
    if (patch.containsKey('title')) row['title'] = patch['title'] as String;
    if (patch.containsKey('content')) row['content'] = patch['content'] as String;
    if (patch.containsKey('color')) row['color'] = patch['color'] as String;
    if (patch.containsKey('pinned')) row['pinned'] = (patch['pinned'] as bool) ? 1 : 0;
    if (patch.containsKey('archived')) row['archived'] = (patch['archived'] as bool) ? 1 : 0;
    if (patch.containsKey('checklist')) row['checklist'] = (patch['checklist'] as bool) ? 1 : 0;
    if (patch.containsKey('tags')) {
      final tags = (patch['tags'] as List).cast<String>();
      row['tags'] = tags.join(',');
    }
    if (patch['lock'] == true) {
      row['locked'] = 1;
      row['pinHash'] = _hashPin(patch['pin'] as String);
    }
    if (patch['lock'] == false) {
      row['locked'] = 0;
      row['pinHash'] = null;
    }
    await db.update(Schema.notes, row, where: 'id = ?', whereArgs: [id]);
    final fresh = await db.query(Schema.notes, where: 'id = ?', whereArgs: [id], limit: 1);
    return Note.fromRow(fresh.first);
  }

  Future<void> deleteNote(String id) async {
    final db = await _open();
    await db.delete(Schema.notes, where: 'id = ?', whereArgs: [id]);
  }

  /// Verify the PIN for a locked note and return the unlocked note on success.
  Future<Note?> verifyNotePin(String id, String pin) async {
    final db = await _open();
    final rows = await db.query(Schema.notes, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final locked = (row['locked'] as int?) == 1;
    final hash = row['pinHash'] as String?;
    if (!locked || hash == null) return Note.fromRow(row);
    if (_hashPin(pin) != hash) return null;
    return Note.fromRow(row);
  }

  /* --------------------------------- Tasks -------------------------------- */

  Future<List<Task>> fetchTasks() async {
    final db = await _open();
    final rows = await db.query(Schema.tasks, orderBy: 'createdAt DESC');
    return rows.map(Task.fromRow).toList();
  }

  Future<Task> insertTask(Map<String, dynamic> input) async {
    final db = await _open();
    final id = _uuid();
    final now = DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      'id': id,
      'title': (input['title'] as String?)?.trim() ?? '',
      'notes': input['notes'] as String? ?? '',
      'done': 0,
      'priority': _priority(input['priority']),
      'category': input['category'] as String? ?? 'Personal',
      'dueDate': input['dueDate'] as String?,
      'dueTime': input['dueTime'] as String?,
      'reminder': (input['reminder'] as bool? ?? false) ? 1 : 0,
      'recurrence': _recurrence(input['recurrence']),
      'repeatDays': _encodeInts(input['repeatDays'] as List<int>?),
      'completedAt': null,
      'createdAt': now,
    };
    await db.insert(Schema.tasks, row);
    return Task(
      id: id,
      title: row['title'] as String,
      notes: row['notes'] as String,
      done: false,
      priority: row['priority'] as String,
      category: row['category'] as String,
      dueDate: row['dueDate'] as String?,
      dueTime: row['dueTime'] as String?,
      reminder: (row['reminder'] as int) == 1,
      recurrence: row['recurrence'] as String,
      repeatDays: input['repeatDays'] as List<int>? ?? const [],
      completedAt: null,
      createdAt: DateTime.now(),
    );
  }

  Future<Task?> updateTask(String id, Map<String, dynamic> patch) async {
    final db = await _open();
    final row = <String, dynamic>{};
    if (patch.containsKey('title')) row['title'] = patch['title'] as String;
    if (patch.containsKey('notes')) row['notes'] = patch['notes'] as String;
    if (patch.containsKey('priority')) row['priority'] = _priority(patch['priority']);
    if (patch.containsKey('category')) row['category'] = patch['category'] as String;
    if (patch.containsKey('dueDate')) row['dueDate'] = patch['dueDate'] as String?;
    if (patch.containsKey('dueTime')) row['dueTime'] = patch['dueTime'] as String?;
    if (patch.containsKey('reminder')) row['reminder'] = (patch['reminder'] as bool) ? 1 : 0;
    if (patch.containsKey('recurrence')) row['recurrence'] = _recurrence(patch['recurrence']);
    if (patch.containsKey('repeatDays')) {
      row['repeatDays'] = _encodeInts(patch['repeatDays'] as List<int>?);
    }
    if (patch.containsKey('done')) {
      final done = patch['done'] as bool;
      row['done'] = done ? 1 : 0;
      row['completedAt'] = done ? DateTime.now().toIso8601String() : null;
    }
    if (row.isEmpty) return null;
    await db.update(Schema.tasks, row, where: 'id = ?', whereArgs: [id]);
    final fresh = await db.query(Schema.tasks, where: 'id = ?', whereArgs: [id], limit: 1);
    return fresh.isEmpty ? null : Task.fromRow(fresh.first);
  }

  Future<void> deleteTask(String id) async {
    final db = await _open();
    await db.delete(Schema.tasks, where: 'id = ?', whereArgs: [id]);
  }

  /* --------------------------------- Habits ------------------------------- */

  Future<List<Habit>> fetchHabits() async {
    final db = await _open();
    final rows = await db.query(Schema.habits, orderBy: 'createdAt ASC');
    return rows.map(Habit.fromRow).toList();
  }

  Future<Habit> insertHabit(Map<String, dynamic> input) async {
    final db = await _open();
    final id = _uuid();
    final now = DateTime.now().toIso8601String();
    final freq = (input['frequency'] as Frequency?) ?? const Frequency(type: FrequencyType.daily);
    final row = <String, dynamic>{
      'id': id,
      'name': (input['name'] as String?)?.trim() ?? '',
      'icon': input['icon'] as String? ?? 'Sparkles',
      'color': input['color'] as String? ?? 'green',
      'frequency': freq.encode(),
      'reminder': (input['reminder'] as bool? ?? false) ? 1 : 0,
      'archived': 0,
      'createdAt': now,
    };
    await db.insert(Schema.habits, row);
    return Habit(
      id: id,
      name: row['name'] as String,
      icon: row['icon'] as String,
      color: row['color'] as String,
      frequency: freq,
      reminder: (row['reminder'] as int) == 1,
      archived: false,
      createdAt: DateTime.now(),
    );
  }

  Future<void> deleteHabit(String id) async {
    final db = await _open();
    await db.delete(Schema.habits, where: 'id = ?', whereArgs: [id]);
    await db.delete(Schema.habitLogs, where: 'habitId = ?', whereArgs: [id]);
  }

  /// Toggle today's check-in for [habitId]. Returns true if the habit is now
  /// completed for [date], false if it was un-completed.
  Future<bool> toggleHabit(String habitId, String date) async {
    final db = await _open();
    final existing = await db.query(
      Schema.habitLogs,
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, date],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      await db.delete(Schema.habitLogs,
          where: 'id = ?', whereArgs: [existing.first['id']]);
      return false;
    }
    await db.insert(Schema.habitLogs, {
      'id': _uuid(),
      'habitId': habitId,
      'date': date,
    });
    return true;
  }

  Future<List<HabitLog>> fetchLogs() async {
    final db = await _open();
    final rows = await db.query(Schema.habitLogs);
    return rows.map(HabitLog.fromRow).toList();
  }

  /* -------------------------------- Accounts ------------------------------ */

  Future<List<Account>> fetchAccounts() async {
    final db = await _open();
    final rows = await db.query(Schema.accounts, orderBy: 'createdAt ASC');
    return rows.map(Account.fromRow).toList();
  }

  Future<Account> insertAccount(Map<String, dynamic> input) async {
    final db = await _open();
    final id = _uuid();
    final now = DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      'id': id,
      'name': (input['name'] as String?)?.trim() ?? '',
      'icon': input['icon'] as String? ?? 'Wallet',
      'color': input['color'] as String? ?? 'violet',
      'archived': 0,
      'createdAt': now,
    };
    await db.insert(Schema.accounts, row);
    return Account(
      id: id,
      name: row['name'] as String,
      icon: row['icon'] as String,
      color: row['color'] as String,
      archived: false,
      createdAt: DateTime.now(),
    );
  }

  Future<Account?> updateAccount(String id, Map<String, dynamic> patch) async {
    final db = await _open();
    final row = <String, dynamic>{};
    if (patch.containsKey('name')) row['name'] = patch['name'] as String;
    if (patch.containsKey('icon')) row['icon'] = patch['icon'] as String;
    if (patch.containsKey('color')) row['color'] = patch['color'] as String;
    if (patch.containsKey('archived')) row['archived'] = (patch['archived'] as bool) ? 1 : 0;
    if (row.isEmpty) return null;
    await db.update(Schema.accounts, row, where: 'id = ?', whereArgs: [id]);
    final fresh = await db.query(Schema.accounts, where: 'id = ?', whereArgs: [id], limit: 1);
    return fresh.isEmpty ? null : Account.fromRow(fresh.first);
  }

  Future<void> deleteAccount(String id) async {
    final db = await _open();
    await db.delete(Schema.accounts, where: 'id = ?', whereArgs: [id]);
    await db.delete(Schema.transactions, where: 'accountId = ?', whereArgs: [id]);
  }

  /* ------------------------------ Transactions ---------------------------- */

  Future<List<Txn>> fetchTransactions() async {
    final db = await _open();
    final rows = await db.query(Schema.transactions, orderBy: 'occurredAt DESC');
    return rows.map(Txn.fromRow).toList();
  }

  Future<Txn> insertTxn(Map<String, dynamic> input) async {
    final db = await _open();
    final id = _uuid();
    final now = DateTime.now().toIso8601String();
    final occurredAt = (input['occurredAt'] as DateTime?) ?? DateTime.now();
    final row = <String, dynamic>{
      'id': id,
      'accountId': input['accountId'] as String,
      'type': (input['type'] as TxnType) == TxnType.income ? 'income' : 'expense',
      'amount': input['amount'] as int,
      'note': input['note'] as String? ?? '',
      'category': input['category'] as String? ?? 'Other',
      'occurredAt': occurredAt.toIso8601String(),
      'createdAt': now,
    };
    await db.insert(Schema.transactions, row);
    return Txn(
      id: id,
      accountId: row['accountId'] as String,
      type: input['type'] as TxnType,
      amount: row['amount'] as int,
      note: row['note'] as String,
      category: row['category'] as String,
      occurredAt: occurredAt,
      createdAt: DateTime.now(),
    );
  }

  Future<Txn?> updateTxn(String id, Map<String, dynamic> patch) async {
    final db = await _open();
    final row = <String, dynamic>{};
    if (patch.containsKey('type')) {
      row['type'] = (patch['type'] as TxnType) == TxnType.income ? 'income' : 'expense';
    }
    if (patch.containsKey('amount')) row['amount'] = patch['amount'] as int;
    if (patch.containsKey('note')) row['note'] = patch['note'] as String;
    if (patch.containsKey('category')) row['category'] = patch['category'] as String;
    if (patch.containsKey('occurredAt')) {
      row['occurredAt'] = (patch['occurredAt'] as DateTime).toIso8601String();
    }
    if (row.isEmpty) return null;
    await db.update(Schema.transactions, row, where: 'id = ?', whereArgs: [id]);
    final fresh = await db.query(Schema.transactions, where: 'id = ?', whereArgs: [id], limit: 1);
    return fresh.isEmpty ? null : Txn.fromRow(fresh.first);
  }

  Future<void> deleteTxn(String id) async {
    final db = await _open();
    await db.delete(Schema.transactions, where: 'id = ?', whereArgs: [id]);
  }

  /* --------------------------------- Helpers ------------------------------ */

  static String _uuid() {
    // Simple RFC-4122 v4 generator. Avoids pulling in the `uuid` package at
    // the database layer so tests can stub the clock deterministically.
    final r = DateTime.now().microsecondsSinceEpoch;
    final rand = List<int>.generate(16, (_) => DateTime.now().microsecond ^ (r % 256));
    rand[6] = (rand[6] & 0x0F) | 0x40;
    rand[8] = (rand[8] & 0x3F) | 0x80;
    final hex = rand.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static String _hashPin(String pin) {
    // Lightweight hash — sufficient for a 4-digit PIN lock on a local device.
    // For a stronger scheme swap in `package:crypto`'s sha256.
    var h = 0x811c9dc5;
    for (final c in pin.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  static String _priority(dynamic p) {
    if (p is String && {'none', 'low', 'medium', 'high'}.contains(p)) return p;
    return 'none';
  }

  static String _recurrence(dynamic r) {
    if (r is String && {'none', 'daily', 'weekly', 'monthly'}.contains(r)) return r;
    return 'none';
  }

  static String _encodeInts(List<int>? xs) =>
      (xs ?? const []).where((e) => e >= 0 && e <= 6).join(',');
}
