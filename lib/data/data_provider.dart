import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../utils/date_utils.dart';
import 'database.dart';
import 'models.dart';

/// The single source of truth for the ABIDLIFE app.
///
/// Mirrors the original web app's `DataProvider` — exposes the same lists
/// (notes, tasks, habits, logs, accounts, txns), the same `addX` / `updateX`
/// / `deleteX` API, the toast queue, the cross-module `requestQuick` /
/// `consumeQuick` handshake, and re-arms local notifications when tasks
/// change.
///
/// Differences from the web version:
/// - Backed by [AppDatabase] (sqflite) instead of an HTTP API.
/// - Uses [ChangeNotifier] instead of React context.
/// - Notifications use `flutter_local_notifications` instead of the browser
///   `Notification` API.
class DataProvider extends ChangeNotifier {
  DataProvider({AppDatabase? db}) : _db = db ?? AppDatabase();

  final AppDatabase _db;

  /* ----------------------------- Public state ----------------------------- */

  bool _loading = true;
  bool get loading => _loading;

  Tab _tab = Tab.insights;
  Tab get tab => _tab;
  void setTab(Tab t) {
    if (_tab == t) return;
    _tab = t;
    notifyListeners();
  }

  List<Note> _notes = const [];
  List<Note> get notes => _notes;

  List<Task> _tasks = const [];
  List<Task> get tasks => _tasks;

  List<Habit> _habits = const [];
  List<Habit> get habits => _habits;

  List<HabitLog> _logs = const [];
  List<HabitLog> get logs => _logs;

  List<Account> _accounts = const [];
  List<Account> get accounts => _accounts;

  List<Txn> _txns = const [];
  List<Txn> get txns => _txns;

  List<Toast> _toasts = const [];
  List<Toast> get toasts => _toasts;

  QuickAction? _quick;
  QuickAction? get quick => _quick;

  /* --------------------------------- Init --------------------------------- */

  Future<void> bootstrap() async {
    try {
      final results = await Future.wait([
        _db.fetchNotes(),
        _db.fetchTasks(),
        _db.fetchHabits(),
        _db.fetchLogs(),
        _db.fetchAccounts(),
        _db.fetchTransactions(),
      ]);
      _notes = results[0] as List<Note>;
      _tasks = results[1] as List<Task>;
      _habits = results[2] as List<Habit>;
      _logs = results[3] as List<HabitLog>;
      _accounts = results[4] as List<Account>;
      _txns = results[5] as List<Txn>;
    } catch (e) {
      debugPrint('bootstrap failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /* --------------------------------- Toasts ------------------------------- */

  int _toastId = 0;
  Timer? _toastTimer;
  void toast(String msg) {
    final id = ++_toastId;
    _toasts = [..._toasts.skip(_toasts.length > 2 ? _toasts.length - 2 : 0), Toast(id: id, msg: msg)];
    notifyListeners();
    Timer(const Duration(milliseconds: 2600), () {
      _toasts = _toasts.where((t) => t.id != id).toList();
      notifyListeners();
    });
  }

  /* --------------------------------- Notes -------------------------------- */

  Future<Note> addNote({String color = 'default', bool checklist = false}) async {
    try {
      final row = await _db.insertNote(color: color, checklist: checklist);
      _notes = [row, ..._notes];
      notifyListeners();
      return row;
    } catch (e) {
      debugPrint('addNote failed: $e');
      toast("Your note couldn't be created. Try again.");
      rethrow;
    }
  }

  Future<void> updateNote(String id, Map<String, dynamic> patch) async {
    Note? prev;
    final next = _notes.map((n) {
      if (n.id == id) {
        prev = n;
        return _applyNotePatch(n, patch);
      }
      return n;
    }).toList();
    _notes = next;
    notifyListeners();
    try {
      final fresh = await _db.updateNote(id, patch);
      _notes = _notes.map((n) => n.id == id ? fresh : n).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('updateNote failed: $e');
      if (prev != null) {
        _notes = _notes.map((n) => n.id == id ? prev! : n).toList();
        notifyListeners();
      }
      toast("Your note couldn't be saved. Try again.");
    }
  }

  Future<void> deleteNote(String id) async {
    final prev = _notes;
    _notes = _notes.where((n) => n.id != id).toList();
    notifyListeners();
    try {
      await _db.deleteNote(id);
      toast('Note deleted');
    } catch (e) {
      debugPrint('deleteNote failed: $e');
      _notes = prev;
      notifyListeners();
      toast("Couldn't delete this note. Try again.");
    }
  }

  Future<bool> verifyUnlock(String id, String pin) async {
    try {
      final fresh = await _db.verifyNotePin(id, pin);
      if (fresh != null) {
        _notes = _notes.map((n) => n.id == id ? fresh : n).toList();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('verifyUnlock failed: $e');
      return false;
    }
  }

  Note _applyNotePatch(Note n, Map<String, dynamic> patch) {
    return n.copyWith(
      title: patch['title'] as String?,
      content: patch['content'] as String?,
      color: patch['color'] as String?,
      tags: (patch['tags'] as List?)?.cast<String>(),
      pinned: patch['pinned'] as bool?,
      archived: patch['archived'] as bool?,
      checklist: patch['checklist'] as bool?,
      locked: patch['lock'] == true ? true : (patch['lock'] == false ? false : null),
      updatedAt: DateTime.now(),
    );
  }

  /* --------------------------------- Tasks -------------------------------- */

  Future<void> addTask(Map<String, dynamic> input) async {
    if (input['reminder'] == true) {
      await _ensureNotificationPermission();
    }
    try {
      final row = await _db.insertTask(input);
      _tasks = [row, ..._tasks];
      notifyListeners();
      _rearmReminders();
    } catch (e) {
      debugPrint('addTask failed: $e');
      toast("Couldn't add this task. Try again.");
    }
  }

  Future<void> toggleTask(String id) async {
    Task? prev;
    final next = _tasks.map((t) {
      if (t.id == id) {
        prev = t;
        return t.copyWith(
          done: !t.done,
          completedAt: !t.done ? DateTime.now() : null,
        );
      }
      return t;
    }).toList();
    _tasks = next;
    notifyListeners();
    try {
      if (prev != null) {
        await _db.updateTask(id, {'done': !prev!.done});
      }
      _rearmReminders();
    } catch (e) {
      debugPrint('toggleTask failed: $e');
      if (prev != null) {
        _tasks = _tasks.map((t) => t.id == id ? prev! : t).toList();
        notifyListeners();
      }
      toast("Couldn't update this task. Try again.");
    }
  }

  Future<void> updateTask(String id, Map<String, dynamic> patch) async {
    if (patch['reminder'] == true) {
      await _ensureNotificationPermission();
    }
    Task? prev;
    final next = _tasks.map((t) {
      if (t.id == id) {
        prev = t;
        return _applyTaskPatch(t, patch);
      }
      return t;
    }).toList();
    _tasks = next;
    notifyListeners();
    try {
      final fresh = await _db.updateTask(id, patch);
      if (fresh != null) {
        _tasks = _tasks.map((t) => t.id == id ? fresh! : t).toList();
        notifyListeners();
      }
      _rearmReminders();
    } catch (e) {
      debugPrint('updateTask failed: $e');
      if (prev != null) {
        _tasks = _tasks.map((t) => t.id == id ? prev! : t).toList();
        notifyListeners();
      }
      toast("Couldn't update this task. Try again.");
    }
  }

  Future<void> deleteTask(String id) async {
    final prev = _tasks;
    _tasks = _tasks.where((t) => t.id != id).toList();
    notifyListeners();
    try {
      await _db.deleteTask(id);
      toast('Task deleted');
      _rearmReminders();
    } catch (e) {
      debugPrint('deleteTask failed: $e');
      _tasks = prev;
      notifyListeners();
      toast("Couldn't delete this task. Try again.");
    }
  }

  Task _applyTaskPatch(Task t, Map<String, dynamic> patch) {
    return t.copyWith(
      title: patch['title'] as String?,
      notes: patch['notes'] as String?,
      priority: patch['priority'] as String?,
      category: patch['category'] as String?,
      dueDate: patch['dueDate'] as String?,
      dueTime: patch['dueTime'] as String?,
      reminder: patch['reminder'] as bool?,
      recurrence: patch['recurrence'] as String?,
      repeatDays: (patch['repeatDays'] as List?)?.cast<int>(),
      done: patch['done'] as bool?,
      completedAt: patch['done'] == true ? DateTime.now() : null,
    );
  }

  /* --------------------------------- Habits ------------------------------- */

  Future<void> addHabit(Map<String, dynamic> input) async {
    try {
      final row = await _db.insertHabit(input);
      _habits = [..._habits, row];
      notifyListeners();
    } catch (e) {
      debugPrint('addHabit failed: $e');
      toast("Couldn't create this habit. Try again.");
    }
  }

  Future<void> deleteHabit(String id) async {
    final prevH = _habits;
    final prevL = _logs;
    _habits = _habits.where((h) => h.id != id).toList();
    _logs = _logs.where((l) => l.habitId != id).toList();
    notifyListeners();
    try {
      await _db.deleteHabit(id);
      toast('Habit removed');
    } catch (e) {
      debugPrint('deleteHabit failed: $e');
      _habits = prevH;
      _logs = prevL;
      notifyListeners();
      toast("Couldn't remove this habit. Try again.");
    }
  }

  Future<void> toggleHabitToday(String id) async {
    final today = AbidDates.todayStr();
    final existing = _logs.firstWhere(
      (l) => l.habitId == id && l.date == today,
      orElse: () => HabitLog(id: 'temp-$today-$id', habitId: id, date: today),
    );
    if (existing.id.startsWith('temp-')) {
      // not yet completed → optimistically add
      _logs = [..._logs, existing];
    } else {
      // already completed → optimistically remove
      _logs = _logs.where((l) => l.id != existing.id).toList();
    }
    notifyListeners();
    try {
      final completed = await _db.toggleHabit(id, today);
      // Reconcile with server response.
      _logs = _logs.where((l) => !(l.habitId == id && l.date == today && l.id.startsWith('temp-'))).toList();
      final has = _logs.any((l) => l.habitId == id && l.date == today);
      if (completed && !has) {
        _logs = [..._logs, HabitLog(id: 'srv-$today-$id', habitId: id, date: today)];
      } else if (!completed) {
        _logs = _logs.where((l) => !(l.habitId == id && l.date == today)).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('toggleHabitToday failed: $e');
      // Rollback to previous state.
      if (existing.id.startsWith('temp-')) {
        _logs = _logs.where((l) => l.id != existing.id).toList();
      } else {
        _logs = [..._logs, existing];
      }
      notifyListeners();
      toast("Couldn't update this habit. Try again.");
    }
  }

  /* --------------------------------- Money -------------------------------- */

  Future<void> addAccount(Map<String, dynamic> input) async {
    try {
      final row = await _db.insertAccount(input);
      _accounts = [..._accounts, row];
      notifyListeners();
    } catch (e) {
      debugPrint('addAccount failed: $e');
      toast("Couldn't create this account. Try again.");
    }
  }

  Future<void> updateAccount(String id, Map<String, dynamic> patch) async {
    Account? prev;
    final next = _accounts.map((a) {
      if (a.id == id) {
        prev = a;
        return a.copyWith(
          name: patch['name'] as String?,
          icon: patch['icon'] as String?,
          color: patch['color'] as String?,
          archived: patch['archived'] as bool?,
        );
      }
      return a;
    }).toList();
    _accounts = next;
    notifyListeners();
    try {
      final fresh = await _db.updateAccount(id, patch);
      if (fresh != null) {
        _accounts = _accounts.map((a) => a.id == id ? fresh! : a).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('updateAccount failed: $e');
      if (prev != null) {
        _accounts = _accounts.map((a) => a.id == id ? prev! : a).toList();
        notifyListeners();
      }
      toast("Couldn't update this account. Try again.");
    }
  }

  Future<void> deleteAccount(String id) async {
    final prevA = _accounts;
    final prevT = _txns;
    _accounts = _accounts.where((a) => a.id != id).toList();
    _txns = _txns.where((t) => t.accountId != id).toList();
    notifyListeners();
    try {
      await _db.deleteAccount(id);
      toast('Account deleted');
    } catch (e) {
      debugPrint('deleteAccount failed: $e');
      _accounts = prevA;
      _txns = prevT;
      notifyListeners();
      toast("Couldn't delete this account. Try again.");
    }
  }

  Future<void> addTxn(Map<String, dynamic> input) async {
    try {
      final row = await _db.insertTxn(input);
      _txns = [..._txns, row]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      notifyListeners();
    } catch (e) {
      debugPrint('addTxn failed: $e');
      toast("Unable to save this transaction. Try again.");
      rethrow;
    }
  }

  Future<void> updateTxn(String id, Map<String, dynamic> patch) async {
    Txn? prev;
    final next = _txns.map((t) {
      if (t.id == id) {
        prev = t;
        return t.copyWith(
          type: patch['type'] as TxnType?,
          amount: patch['amount'] as int?,
          note: patch['note'] as String?,
          category: patch['category'] as String?,
          occurredAt: patch['occurredAt'] as DateTime?,
        );
      }
      return t;
    }).toList();
    _txns = next;
    notifyListeners();
    try {
      final fresh = await _db.updateTxn(id, patch);
      if (fresh != null) {
        _txns = _txns.map((t) => t.id == id ? fresh! : t).toList()..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('updateTxn failed: $e');
      if (prev != null) {
        _txns = _txns.map((t) => t.id == id ? prev! : t).toList();
        notifyListeners();
      }
      toast("Unable to save this transaction. Try again.");
      rethrow;
    }
  }

  Future<void> deleteTxn(String id) async {
    final prev = _txns;
    _txns = _txns.where((t) => t.id != id).toList();
    notifyListeners();
    try {
      await _db.deleteTxn(id);
      toast('Transaction deleted');
    } catch (e) {
      debugPrint('deleteTxn failed: $e');
      _txns = prev;
      notifyListeners();
      toast("Couldn't delete this transaction. Try again.");
    }
  }

  /* --------------------------- Cross-module quick ------------------------- */

  void requestQuick(Tab t, String action) {
    _tab = t;
    _quick = QuickAction(tab: t, action: action);
    notifyListeners();
  }

  void consumeQuick() {
    _quick = null;
    notifyListeners();
  }

  /* ----------------------------- Notifications ---------------------------- */

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _notificationsReady = false;
  final Map<String, int> _activeReminders = {};

  Future<void> initNotifications() async {
    if (_notificationsReady) return;
    tz_data.initializeTimeZones();
    // Use the device's local timezone so scheduled times match what the user
    // sees on the clock.
    try {
      final name = DateTime.now().timeZoneName;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to UTC if the platform timezone name is unrecognized.
    }
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(init);
    _notificationsReady = true;
  }

  Future<void> _ensureNotificationPermission() async {
    await initNotifications();
    final android = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }
  }

  /// Re-arm local notifications for every pending task reminder.
  ///
  /// Mirrors the web app's `useEffect([tasks])` that cleared and re-armed
  /// `window.setTimeout`s whenever the task list changed. We use the
  /// platform's scheduled-notification API so reminders fire even when the
  /// app is closed.
  void _rearmReminders() {
    if (!_notificationsReady) return;
    final now = DateTime.now();
    final today = AbidDates.todayStr();
    for (final t in _tasks) {
      if (t.done || !t.reminder || t.dueDate != today || t.dueTime == null) continue;
      final parts = t.dueTime!.split(':');
      final dt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      final delay = dt.difference(now);
      if (delay.inSeconds <= 0 || delay.inHours > 24) continue;
      final id = t.id.hashCode & 0x7FFFFFFF;
      _notifications.zonedSchedule(
        id,
        'Task reminder',
        t.title,
        tz.TZDateTime.from(dt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'abidlife.tasks',
            'Task reminders',
            channelDescription: 'Reminders for tasks due today',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _activeReminders[t.id] = id;
    }
  }
}
