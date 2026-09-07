import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final root = await getDatabasesPath();
    return openDatabase(
      path.join(root, 'abidlife.db'),
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL DEFAULT '',
            content_delta TEXT NOT NULL,
            color TEXT NOT NULL DEFAULT 'default',
            tags TEXT NOT NULL DEFAULT '[]',
            pinned INTEGER NOT NULL DEFAULT 0,
            archived INTEGER NOT NULL DEFAULT 0,
            locked INTEGER NOT NULL DEFAULT 0,
            pin_salt TEXT,
            pin_hash TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX notes_updated_idx ON notes(pinned DESC, updated_at DESC)',
        );

        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            details TEXT NOT NULL DEFAULT '',
            done INTEGER NOT NULL DEFAULT 0,
            priority TEXT NOT NULL DEFAULT 'none',
            category TEXT NOT NULL DEFAULT 'Personal',
            due_at INTEGER,
            reminder INTEGER NOT NULL DEFAULT 0,
            recurrence TEXT NOT NULL DEFAULT 'none',
            repeat_days TEXT NOT NULL DEFAULT '[]',
            completed_at INTEGER,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX tasks_due_idx ON tasks(done, due_at)');

        await db.execute('''
          CREATE TABLE habits (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL DEFAULT 'sparkles',
            color TEXT NOT NULL DEFAULT 'green',
            frequency TEXT NOT NULL DEFAULT 'daily',
            repeat_days TEXT NOT NULL DEFAULT '[]',
            weekly_goal INTEGER NOT NULL DEFAULT 7,
            reminder INTEGER NOT NULL DEFAULT 0,
            reminder_hour INTEGER NOT NULL DEFAULT 20,
            reminder_minute INTEGER NOT NULL DEFAULT 0,
            start_date INTEGER NOT NULL,
            archived INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE habit_logs (
            id TEXT PRIMARY KEY,
            habit_id TEXT NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
            date TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'completed',
            UNIQUE(habit_id, date)
          )
        ''');
        await db.execute(
          'CREATE INDEX habit_logs_lookup_idx ON habit_logs(habit_id, date)',
        );

        await db.execute('''
          CREATE TABLE money_accounts (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            icon TEXT NOT NULL DEFAULT 'wallet',
            color TEXT NOT NULL DEFAULT 'violet',
            archived INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE money_transactions (
            id TEXT PRIMARY KEY,
            account_id TEXT NOT NULL REFERENCES money_accounts(id) ON DELETE CASCADE,
            type TEXT NOT NULL,
            amount_paise INTEGER NOT NULL CHECK(amount_paise > 0),
            note TEXT NOT NULL DEFAULT '',
            category TEXT NOT NULL DEFAULT 'Other',
            occurred_at INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX money_txn_account_date_idx
          ON money_transactions(account_id, occurred_at DESC)
        ''');
      },
    );
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    await db?.close();
  }
}
