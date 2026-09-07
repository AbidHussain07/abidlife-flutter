import 'package:abidlife/core/formatters.dart';
import 'package:abidlife/data/app_database.dart';
import 'package:abidlife/data/repositories.dart';
import 'package:abidlife/domain/recurrence.dart';
import 'package:abidlife/models/models.dart';
import 'package:abidlife/services/notification_service.dart';
import 'package:abidlife/services/security_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final appControllerProvider = ChangeNotifierProvider<AppController>((ref) {
  return AppController();
});

class AppController extends ChangeNotifier {
  AppController()
      : _notesRepository = NotesRepository(AppDatabase.instance, SecurityService()),
        _tasksRepository = TasksRepository(AppDatabase.instance),
        _habitsRepository = HabitsRepository(AppDatabase.instance),
        _moneyRepository = MoneyRepository(AppDatabase.instance);

  final NotesRepository _notesRepository;
  final TasksRepository _tasksRepository;
  final HabitsRepository _habitsRepository;
  final MoneyRepository _moneyRepository;
  final NotificationService notifications = NotificationService();
  final Uuid _uuid = const Uuid();

  bool initialized = false;
  bool onboardingComplete = false;
  ThemeMode themeMode = ThemeMode.system;
  List<NoteModel> notes = <NoteModel>[];
  List<TaskModel> tasks = <TaskModel>[];
  List<HabitModel> habits = <HabitModel>[];
  List<HabitLogModel> habitLogs = <HabitLogModel>[];
  List<MoneyAccountModel> accounts = <MoneyAccountModel>[];
  List<MoneyTransactionModel> transactions = <MoneyTransactionModel>[];

  Future<void> initialize() async {
    if (initialized) return;
    final prefs = await SharedPreferences.getInstance();
    onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    themeMode = switch (prefs.getString('theme_mode')) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    await notifications.initialize();
    await reload();
    initialized = true;
    notifyListeners();
  }

  Future<void> reload() async {
    final values = await Future.wait<Object>(<Future<Object>>[
      _notesRepository.all(),
      _tasksRepository.all(),
      _habitsRepository.habits(),
      _habitsRepository.logs(),
      _moneyRepository.accounts(),
      _moneyRepository.transactions(),
    ]);
    notes = values[0] as List<NoteModel>;
    tasks = values[1] as List<TaskModel>;
    habits = values[2] as List<HabitModel>;
    habitLogs = values[3] as List<HabitLogModel>;
    accounts = values[4] as List<MoneyAccountModel>;
    transactions = values[5] as List<MoneyTransactionModel>;
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    onboardingComplete = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  Future<void> replayOnboarding() async {
    onboardingComplete = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', false);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }

  // Notes -------------------------------------------------------------------

  Future<NoteModel> createNote({bool checklist = false}) async {
    final note = await _notesRepository.create(checklist: checklist);
    notes = <NoteModel>[note, ...notes];
    notifyListeners();
    return note;
  }

  Future<void> saveNote(NoteModel note) async {
    final saved = note.copyWith(updatedAt: DateTime.now());
    await _notesRepository.save(saved);
    notes = notes.map((item) => item.id == saved.id ? saved : item).toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    notifyListeners();
  }

  Future<void> updateNoteMeta(
    NoteModel note, {
    bool? pinned,
    bool? archived,
    String? color,
    List<String>? tags,
  }) async {
    final changed = note.copyWith(
      pinned: pinned,
      archived: archived,
      color: color,
      tags: tags,
      updatedAt: DateTime.now(),
    );
    await _notesRepository.updateMeta(changed);
    notes = notes.map((item) => item.id == changed.id ? changed : item).toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    notifyListeners();
  }

  Future<void> lockNote(NoteModel note, String pin) async {
    final locked = await _notesRepository.lock(note, pin);
    notes = notes.map((item) => item.id == note.id ? locked : item).toList();
    notifyListeners();
  }

  Future<NoteModel?> unlockNote(String id, String pin) async {
    final open = await _notesRepository.unlock(id, pin);
    if (open == null) return null;
    notes = notes.map((item) => item.id == id ? open : item).toList();
    notifyListeners();
    return open;
  }

  Future<void> removeNoteLock(NoteModel openNote) async {
    final plain = await _notesRepository.removeLock(openNote);
    notes = notes.map((item) => item.id == plain.id ? plain : item).toList();
    notifyListeners();
  }

  Future<void> relockNoteSession(String id) async {
    await _notesRepository.relockSession(id);
    notes = await _notesRepository.all();
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    await _notesRepository.delete(id);
    notes = notes.where((item) => item.id != id).toList();
    notifyListeners();
  }

  // Tasks -------------------------------------------------------------------

  Future<TaskModel> saveTask({
    String? id,
    required String title,
    String details = '',
    TaskPriority priority = TaskPriority.none,
    String category = 'Personal',
    DateTime? dueAt,
    bool reminder = false,
    RecurrenceType recurrence = RecurrenceType.none,
    List<int> repeatDays = const <int>[],
    bool done = false,
    DateTime? completedAt,
    DateTime? createdAt,
  }) async {
    final task = TaskModel(
      id: id ?? _uuid.v4(),
      title: title.trim(),
      details: details.trim(),
      done: done,
      priority: priority,
      category: category,
      dueAt: dueAt,
      reminder: reminder,
      recurrence: recurrence,
      repeatDays: repeatDays,
      completedAt: completedAt,
      createdAt: createdAt ?? DateTime.now(),
    );
    await _tasksRepository.save(task);
    if (reminder) {
      await notifications.requestPermission();
      await notifications.scheduleTask(task);
    } else {
      await notifications.cancelTask(task.id);
    }
    tasks = <TaskModel>[task, ...tasks.where((item) => item.id != task.id)];
    notifyListeners();
    return task;
  }

  Future<void> toggleTask(TaskModel task) async {
    final completing = !task.done;
    final changed = task.copyWith(
      done: completing,
      completedAt: completing ? DateTime.now() : null,
      clearCompletedAt: !completing,
    );
    await _tasksRepository.save(changed);
    if (completing) {
      await notifications.cancelTask(task.id);
      final next = nextTaskOccurrence(task);
      final duplicate = next != null &&
          tasks.any(
            (item) =>
                !item.done &&
                item.title == task.title &&
                item.dueAt == next,
          );
      if (next != null && !duplicate) {
        await saveTask(
          title: task.title,
          details: task.details,
          priority: task.priority,
          category: task.category,
          dueAt: next,
          reminder: task.reminder,
          recurrence: task.recurrence,
          repeatDays: task.repeatDays,
        );
      }
    } else if (task.reminder) {
      await notifications.scheduleTask(changed);
    }
    tasks = tasks.map((item) => item.id == task.id ? changed : item).toList();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await notifications.cancelTask(id);
    await _tasksRepository.delete(id);
    tasks = tasks.where((item) => item.id != id).toList();
    notifyListeners();
  }

  // Habits ------------------------------------------------------------------

  Future<void> createHabit({
    required String name,
    required String icon,
    required String color,
    required HabitFrequency frequency,
    List<int> repeatDays = const <int>[],
    int weeklyGoal = 7,
    bool reminder = false,
    int reminderHour = 9,
    int reminderMinute = 0,
  }) async {
    final now = DateTime.now();
    final habit = HabitModel(
      id: _uuid.v4(),
      name: name.trim(),
      icon: icon,
      color: color,
      frequency: frequency,
      repeatDays: repeatDays,
      weeklyGoal: weeklyGoal,
      reminder: reminder,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      startDate: dateOnly(now),
      archived: false,
      createdAt: now,
    );
    await _habitsRepository.save(habit);
    habits = <HabitModel>[...habits, habit];
    notifyListeners();
  }

  Future<void> toggleHabitToday(String habitId) async {
    await _habitsRepository.toggleToday(habitId, dayKey(DateTime.now()));
    habitLogs = await _habitsRepository.logs();
    notifyListeners();
  }

  Future<void> deleteHabit(String id) async {
    await _habitsRepository.delete(id);
    habits = habits.where((item) => item.id != id).toList();
    habitLogs = habitLogs.where((item) => item.habitId != id).toList();
    notifyListeners();
  }

  // Money -------------------------------------------------------------------

  Future<void> saveAccount({
    String? id,
    required String name,
    required String icon,
    required String color,
    bool archived = false,
    DateTime? createdAt,
  }) async {
    final account = MoneyAccountModel(
      id: id ?? _uuid.v4(),
      name: name.trim(),
      icon: icon,
      color: color,
      archived: archived,
      createdAt: createdAt ?? DateTime.now(),
    );
    await _moneyRepository.saveAccount(account);
    accounts = <MoneyAccountModel>[
      ...accounts.where((item) => item.id != account.id),
      account,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();
  }

  Future<void> deleteAccount(String id) async {
    await _moneyRepository.deleteAccount(id);
    accounts = accounts.where((item) => item.id != id).toList();
    transactions = transactions.where((item) => item.accountId != id).toList();
    notifyListeners();
  }

  Future<void> saveTransaction({
    String? id,
    required String accountId,
    required TransactionType type,
    required int amountPaise,
    required String note,
    required String category,
    required DateTime occurredAt,
    DateTime? createdAt,
  }) async {
    final transaction = MoneyTransactionModel(
      id: id ?? _uuid.v4(),
      accountId: accountId,
      type: type,
      amountPaise: amountPaise,
      note: note.trim(),
      category: category,
      occurredAt: occurredAt,
      createdAt: createdAt ?? DateTime.now(),
    );
    await _moneyRepository.saveTransaction(transaction);
    transactions = <MoneyTransactionModel>[
      transaction,
      ...transactions.where((item) => item.id != transaction.id),
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _moneyRepository.deleteTransaction(id);
    transactions = transactions.where((item) => item.id != id).toList();
    notifyListeners();
  }
}
