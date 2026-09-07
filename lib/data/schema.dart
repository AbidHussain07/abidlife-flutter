/// Table + column name constants for the ABIDLIFE sqflite schema.
///
/// Keeping them in one place makes migrations trivial and prevents
/// string-typo bugs.
class Schema {
  const Schema._();

  static const String dbFile = 'abidlife.db';
  static const int dbVersion = 1;

  static const String notes = 'notes';
  static const String tasks = 'tasks';
  static const String habits = 'habits';
  static const String habitLogs = 'habitLogs';
  static const String accounts = 'accounts';
  static const String transactions = 'transactions';

  static const String createNotes = '''
    CREATE TABLE ${Schema.notes} (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL DEFAULT '',
      content TEXT NOT NULL DEFAULT '',
      color TEXT NOT NULL DEFAULT 'default',
      tags TEXT NOT NULL DEFAULT '',
      pinned INTEGER NOT NULL DEFAULT 0,
      archived INTEGER NOT NULL DEFAULT 0,
      locked INTEGER NOT NULL DEFAULT 0,
      checklist INTEGER NOT NULL DEFAULT 0,
      pinHash TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );
  ''';

  static const String createTasks = '''
    CREATE TABLE ${Schema.tasks} (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      notes TEXT NOT NULL DEFAULT '',
      done INTEGER NOT NULL DEFAULT 0,
      priority TEXT NOT NULL DEFAULT 'none',
      category TEXT NOT NULL DEFAULT 'Personal',
      dueDate TEXT,
      dueTime TEXT,
      reminder INTEGER NOT NULL DEFAULT 0,
      recurrence TEXT NOT NULL DEFAULT 'none',
      repeatDays TEXT NOT NULL DEFAULT '',
      completedAt TEXT,
      createdAt TEXT NOT NULL
    );
  ''';

  static const String createHabits = '''
    CREATE TABLE ${Schema.habits} (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      icon TEXT NOT NULL DEFAULT 'Sparkles',
      color TEXT NOT NULL DEFAULT 'green',
      frequency TEXT NOT NULL DEFAULT '{"type":"daily"}',
      reminder INTEGER NOT NULL DEFAULT 0,
      archived INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );
  ''';

  static const String createHabitLogs = '''
    CREATE TABLE ${Schema.habitLogs} (
      id TEXT PRIMARY KEY,
      habitId TEXT NOT NULL,
      date TEXT NOT NULL,
      UNIQUE(habitId, date)
    );
  ''';

  static const String createAccounts = '''
    CREATE TABLE ${Schema.accounts} (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      icon TEXT NOT NULL DEFAULT 'Wallet',
      color TEXT NOT NULL DEFAULT 'violet',
      archived INTEGER NOT NULL DEFAULT 0,
      createdAt TEXT NOT NULL
    );
  ''';

  static const String createTransactions = '''
    CREATE TABLE ${Schema.transactions} (
      id TEXT PRIMARY KEY,
      accountId TEXT NOT NULL,
      type TEXT NOT NULL,
      amount INTEGER NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      category TEXT NOT NULL DEFAULT 'Other',
      occurredAt TEXT NOT NULL,
      createdAt TEXT NOT NULL
    );
  ''';
}
