import 'dart:convert';

import 'package:abidlife/data/app_database.dart';
import 'package:abidlife/models/models.dart';
import 'package:abidlife/services/security_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
const emptyQuillDelta = '[{"insert":"\\n"}]';

class NotesRepository {
  NotesRepository(this._database, this._security);

  final AppDatabase _database;
  final SecurityService _security;

  Future<List<NoteModel>> all() async {
    final db = await _database.database;
    final rows = await db.query(
      'notes',
      orderBy: 'pinned DESC, updated_at DESC',
    );
    return rows.map(NoteModel.fromMap).toList(growable: false);
  }

  Future<NoteModel> create({bool checklist = false}) async {
    final now = DateTime.now();
    final delta = checklist
        ? '[{"insert":"First item"},{"attributes":{"list":"unchecked"},"insert":"\\n"}]'
        : emptyQuillDelta;
    final note = NoteModel(
      id: _uuid.v4(),
      title: '',
      deltaJson: delta,
      color: 'default',
      tags: const <String>[],
      pinned: false,
      archived: false,
      locked: false,
      createdAt: now,
      updatedAt: now,
    );
    final db = await _database.database;
    await db.insert('notes', note.toMap());
    return note;
  }

  Future<void> save(NoteModel note) async {
    final db = await _database.database;
    final body = note.locked
        ? await _security.encryptForOpenSession(note.id, note.deltaJson)
        : note.deltaJson;
    await db.update(
      'notes',
      note.copyWith(updatedAt: DateTime.now()).toMap(persistedContent: body),
      where: 'id = ?',
      whereArgs: <Object>[note.id],
    );
  }

  /// Metadata can be changed from a locked card without loading or rewriting
  /// its encrypted body.
  Future<void> updateMeta(NoteModel note) async {
    final db = await _database.database;
    await db.update(
      'notes',
      <String, Object?>{
        'title': note.title,
        'color': note.color,
        'tags': jsonEncode(note.tags),
        'pinned': note.pinned ? 1 : 0,
        'archived': note.archived ? 1 : 0,
        'updated_at': note.updatedAt.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: <Object>[note.id],
    );
  }

  Future<NoteModel> lock(NoteModel note, String pin) async {
    final secured = await _security.lock(note.id, note.deltaJson, pin);
    final db = await _database.database;
    await db.update(
      'notes',
      <String, Object?>{
        ...note.copyWith(locked: true, updatedAt: DateTime.now()).toMap(
              persistedContent: secured.cipherText,
            ),
        'pin_salt': secured.pinSalt,
        'pin_hash': secured.pinHash,
      },
      where: 'id = ?',
      whereArgs: <Object>[note.id],
    );
    _security.forget(note.id);
    return note.copyWith(
      locked: true,
      deltaJson: '',
      sessionUnlocked: false,
      updatedAt: DateTime.now(),
    );
  }

  Future<NoteModel?> unlock(String id, String pin) async {
    final db = await _database.database;
    final rows = await db.query('notes', where: 'id = ?', whereArgs: <Object>[id]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    final clear = await _security.unlock(
      noteId: id,
      encryptedBody: row['content_delta'] as String,
      pin: pin,
      salt: row['pin_salt'] as String,
      expectedHash: row['pin_hash'] as String,
    );
    if (clear == null) return null;
    return NoteModel.fromMap(
      <String, Object?>{...row, 'content_delta': clear},
      exposeBody: true,
    );
  }

  Future<NoteModel> removeLock(NoteModel openNote) async {
    final db = await _database.database;
    await db.update(
      'notes',
      <String, Object?>{
        ...openNote.copyWith(
          locked: false,
          sessionUnlocked: false,
          updatedAt: DateTime.now(),
        ).toMap(),
        'pin_salt': null,
        'pin_hash': null,
      },
      where: 'id = ?',
      whereArgs: <Object>[openNote.id],
    );
    _security.forget(openNote.id);
    return openNote.copyWith(
      locked: false,
      sessionUnlocked: false,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> relockSession(String id) async => _security.forget(id);

  Future<void> delete(String id) async {
    _security.forget(id);
    final db = await _database.database;
    await db.delete('notes', where: 'id = ?', whereArgs: <Object>[id]);
  }
}

class TasksRepository {
  TasksRepository(this._database);
  final AppDatabase _database;

  Future<List<TaskModel>> all() async {
    final db = await _database.database;
    return (await db.query('tasks', orderBy: 'created_at DESC'))
        .map(TaskModel.fromMap)
        .toList(growable: false);
  }

  Future<void> save(TaskModel task) async {
    final db = await _database.database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _database.database;
    await db.delete('tasks', where: 'id = ?', whereArgs: <Object>[id]);
  }
}

class HabitsRepository {
  HabitsRepository(this._database);
  final AppDatabase _database;

  Future<List<HabitModel>> habits() async {
    final db = await _database.database;
    return (await db.query('habits', orderBy: 'created_at ASC'))
        .map(HabitModel.fromMap)
        .toList(growable: false);
  }

  Future<List<HabitLogModel>> logs() async {
    final db = await _database.database;
    return (await db.query('habit_logs'))
        .map(HabitLogModel.fromMap)
        .toList(growable: false);
  }

  Future<void> save(HabitModel habit) async {
    final db = await _database.database;
    await db.insert(
      'habits',
      habit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> toggleToday(String habitId, String date) async {
    final db = await _database.database;
    final rows = await db.query(
      'habit_logs',
      where: 'habit_id = ? AND date = ?',
      whereArgs: <Object>[habitId, date],
    );
    if (rows.isNotEmpty) {
      await db.delete(
        'habit_logs',
        where: 'habit_id = ? AND date = ?',
        whereArgs: <Object>[habitId, date],
      );
    } else {
      await db.insert(
        'habit_logs',
        HabitLogModel(
          id: _uuid.v4(),
          habitId: habitId,
          date: date,
          status: HabitLogStatus.completed,
        ).toMap(),
      );
    }
  }

  Future<void> delete(String id) async {
    final db = await _database.database;
    await db.delete('habits', where: 'id = ?', whereArgs: <Object>[id]);
  }
}

class MoneyRepository {
  MoneyRepository(this._database);
  final AppDatabase _database;

  Future<List<MoneyAccountModel>> accounts() async {
    final db = await _database.database;
    return (await db.query('money_accounts', orderBy: 'created_at ASC'))
        .map(MoneyAccountModel.fromMap)
        .toList(growable: false);
  }

  Future<List<MoneyTransactionModel>> transactions() async {
    final db = await _database.database;
    return (await db.query(
      'money_transactions',
      orderBy: 'occurred_at DESC',
    ))
        .map(MoneyTransactionModel.fromMap)
        .toList(growable: false);
  }

  Future<void> saveAccount(MoneyAccountModel account) async {
    final db = await _database.database;
    await db.insert(
      'money_accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await _database.database;
    await db.delete('money_accounts', where: 'id = ?', whereArgs: <Object>[id]);
  }

  Future<void> saveTransaction(MoneyTransactionModel transaction) async {
    final db = await _database.database;
    await db.insert(
      'money_transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _database.database;
    await db.delete(
      'money_transactions',
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }
}
