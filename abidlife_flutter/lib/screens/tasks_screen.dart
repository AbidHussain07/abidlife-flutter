import 'package:abidlife/core/app_theme.dart';
import 'package:abidlife/core/formatters.dart';
import 'package:abidlife/models/models.dart';
import 'package:abidlife/providers/app_controller.dart';
import 'package:abidlife/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _quickController = TextEditingController();
  var _showCompleted = false;

  @override
  void dispose() {
    _quickController.dispose();
    super.dispose();
  }

  Future<void> _quickAdd() async {
    final title = _quickController.text.trim();
    if (title.isEmpty) return;
    final now = DateTime.now();
    await ref.read(appControllerProvider).saveTask(
          title: title,
          dueAt: DateTime(now.year, now.month, now.day, 18),
        );
    _quickController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final now = DateTime.now();
    final today = dateOnly(now);
    final open = app.tasks.where((task) => !task.done).toList();
    final todayTasks = open.where((task) => task.dueAt != null && sameDay(task.dueAt!, today)).toList();
    final overdue = open.where((task) => task.dueAt != null && dateOnly(task.dueAt!).isBefore(today)).toList();
    final upcoming = open.where((task) => task.dueAt != null && dateOnly(task.dueAt!).isAfter(today)).toList()
      ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));
    final anytime = open.where((task) => task.dueAt == null).toList();
    final completed = app.tasks.where((task) => task.done).toList()
      ..sort((a, b) => (b.completedAt ?? b.createdAt).compareTo(a.completedAt ?? a.createdAt));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(94),
        child: AppPageHeader(
          title: todayTasks.isEmpty && overdue.isEmpty ? 'All clear today.' : "Let's get things done.",
          subtitle: '${greeting(now)} · ${DateFormat('EEEE, d MMM').format(now)}',
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 7),
            child: TextField(
              controller: _quickController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _quickAdd(),
              decoration: InputDecoration(
                hintText: 'Quick add — e.g. Buy groceries',
                prefixIcon: const Icon(Icons.add_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Add for today',
                  onPressed: _quickAdd,
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ),
            ),
          ),
          Expanded(
            child: app.tasks.isEmpty
                ? EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: "You're all caught up 🎉",
                    message: 'Add a task and it will be organized by when it is due.',
                    actionLabel: 'Add a task',
                    onAction: () => _openEditor(),
                    color: AppColors.blue,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 106),
                    children: <Widget>[
                      // Required order: Today, Overdue, Upcoming, Anytime, Completed.
                      _section('Today', todayTasks),
                      _section('Overdue', overdue, color: AppColors.expense),
                      _section('Upcoming', upcoming),
                      _section('Anytime', anytime),
                      if (completed.isNotEmpty) ...<Widget>[
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _showCompleted = !_showCompleted),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
                            child: Row(
                              children: <Widget>[
                                AnimatedRotation(
                                  turns: _showCompleted ? .5 : 0,
                                  duration: const Duration(milliseconds: 180),
                                  child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'COMPLETED · ${completed.length}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 220),
                          crossFadeState: _showCompleted
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: const SizedBox.shrink(),
                          secondChild: Column(
                            children: completed.map(_taskCard).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: app.tasks.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                heroTag: 'tasks_fab',
                backgroundColor: AppColors.blue,
                tooltip: 'New task',
                onPressed: _openEditor,
                child: const Icon(Icons.add_rounded),
              ),
            ),
    );
  }

  Widget _section(String title, List<TaskModel> tasks, {Color? color}) {
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionLabel('$title · ${tasks.length}'),
        ...tasks.map(_taskCard),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _taskCard(TaskModel task) {
    final priorityColor = switch (task.priority) {
      TaskPriority.high => AppColors.expense,
      TaskPriority.medium => AppColors.amber,
      TaskPriority.low => AppColors.blue,
      TaskPriority.none => Theme.of(context).colorScheme.outline,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openEditor(task),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Semantics(
                  button: true,
                  label: task.done ? 'Mark task incomplete' : 'Complete task',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref.read(appControllerProvider).toggleTask(task);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: task.done ? AppColors.green : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.done ? AppColors.green : priorityColor,
                          width: 2,
                        ),
                      ),
                      child: task.done
                          ? const Icon(Icons.check_rounded, size: 17, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: task.done
                                  ? Theme.of(context).colorScheme.onSurfaceVariant
                                  : null,
                              decoration: task.done ? TextDecoration.lineThrough : null,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          if (task.dueAt != null)
                            _meta(
                              task.reminder ? Icons.notifications_rounded : Icons.calendar_today_rounded,
                              '${relativeDay(task.dueAt!)} · ${timeLabel(task.dueAt!)}',
                              color: !task.done && dateOnly(task.dueAt!).isBefore(dateOnly(DateTime.now()))
                                  ? AppColors.expense
                                  : null,
                            ),
                          _meta(Icons.folder_outlined, task.category),
                          if (task.recurrence != RecurrenceType.none)
                            _meta(Icons.repeat_rounded, task.recurrence.name),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String value, {Color? color}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: color ?? Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      );

  Future<void> _openEditor([TaskModel? task]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TaskEditor(task: task),
    );
  }
}

class _TaskEditor extends ConsumerStatefulWidget {
  const _TaskEditor({this.task});
  final TaskModel? task;

  @override
  ConsumerState<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends ConsumerState<_TaskEditor> {
  late final TextEditingController _title;
  late final TextEditingController _details;
  late TaskPriority _priority;
  late String _category;
  late DateTime? _due;
  late bool _reminder;
  late RecurrenceType _recurrence;
  late List<int> _days;

  static const _categories = <String>['Personal', 'Work', 'Shopping', 'Home', 'Bills', 'Travel', 'Health', 'Other'];
  static const _week = <({int day, String short, String full})>[
    (day: 1, short: 'M', full: 'Monday'),
    (day: 2, short: 'T', full: 'Tuesday'),
    (day: 3, short: 'W', full: 'Wednesday'),
    (day: 4, short: 'T', full: 'Thursday'),
    (day: 5, short: 'F', full: 'Friday'),
    (day: 6, short: 'S', full: 'Saturday'),
    (day: 7, short: 'S', full: 'Sunday'),
  ];

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _details = TextEditingController(text: task?.details ?? '');
    _priority = task?.priority ?? TaskPriority.none;
    _category = task?.category ?? 'Personal';
    _due = task?.dueAt;
    _reminder = task?.reminder ?? false;
    _recurrence = task?.recurrence ?? RecurrenceType.none;
    _days = List<int>.from(task?.repeatDays ?? const <int>[]);
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: DateTime(now.year + 10),
      initialDate: _due ?? now,
    );
    if (date == null || !mounted) return;
    final current = _due ?? DateTime(date.year, date.month, date.day, 18);
    setState(() => _due = DateTime(date.year, date.month, date.day, current.hour, current.minute));
  }

  Future<void> _pickTime() async {
    final now = _due ?? DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null) return;
    setState(() {
      final base = _due ?? DateTime.now();
      _due = DateTime(base.year, base.month, base.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    if (_reminder && _due == null) {
      showMessage(context, 'Choose a date and time for the reminder.');
      return;
    }
    await ref.read(appControllerProvider).saveTask(
          id: widget.task?.id,
          title: _title.text,
          details: _details.text,
          priority: _priority,
          category: _category,
          dueAt: _due,
          reminder: _reminder,
          recurrence: _recurrence,
          repeatDays: _recurrence == RecurrenceType.weekly ? _days : const <int>[],
          done: widget.task?.done ?? false,
          completedAt: widget.task?.completedAt,
          createdAt: widget.task?.createdAt,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .92),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      widget.task == null ? 'New task' : 'Edit task',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (widget.task != null)
                    IconButton(
                      tooltip: 'Delete task',
                      color: AppColors.expense,
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              ),
              TextField(
                controller: _title,
                autofocus: widget.task == null,
                style: Theme.of(context).textTheme.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'What needs doing?',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              TextField(
                controller: _details,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Notes (optional)'),
              ),
              const SizedBox(height: 18),
              const SectionLabel('Due'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ActionChip(
                    avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(_due == null ? 'Choose date' : relativeDay(_due!)),
                    onPressed: _pickDate,
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text(_due == null ? 'Choose time' : timeLabel(_due!)),
                    onPressed: _pickTime,
                  ),
                  if (_due != null)
                    ActionChip(
                      avatar: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('No due date'),
                      onPressed: () => setState(() {
                        _due = null;
                        _reminder = false;
                      }),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Local reminder', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Shows an Android notification offline'),
                value: _reminder,
                onChanged: (value) => setState(() => _reminder = value),
              ),
              const SectionLabel('Priority'),
              Wrap(
                spacing: 8,
                children: TaskPriority.values
                    .map(
                      (priority) => ChoiceChip(
                        selected: _priority == priority,
                        label: Text(priority.name[0].toUpperCase() + priority.name.substring(1)),
                        onSelected: (_) => setState(() => _priority = priority),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              const SectionLabel('Category'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _categories
                    .map(
                      (category) => ChoiceChip(
                        selected: _category == category,
                        label: Text(category),
                        onSelected: (_) => setState(() => _category = category),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              const SectionLabel('Repeats'),
              Wrap(
                spacing: 8,
                children: RecurrenceType.values
                    .map(
                      (value) => ChoiceChip(
                        selected: _recurrence == value,
                        label: Text(value == RecurrenceType.none ? "Doesn't repeat" : value.name[0].toUpperCase() + value.name.substring(1)),
                        onSelected: (_) => setState(() => _recurrence = value),
                      ),
                    )
                    .toList(),
              ),
              if (_recurrence == RecurrenceType.weekly) ...<Widget>[
                const SizedBox(height: 13),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _week.map((item) {
                    final selected = _days.contains(item.day);
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: item.full,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () => setState(() {
                          selected ? _days.remove(item.day) : _days.add(item.day);
                          _days.sort();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.teal.withValues(alpha: .14)
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(15),
                            border: selected ? Border.all(color: AppColors.teal) : null,
                          ),
                          child: Text(
                            item.short,
                            style: TextStyle(
                              color: selected ? AppColors.teal : null,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 7),
                Text(
                  _days.isEmpty
                      ? 'No days picked — uses the due date weekday.'
                      : 'Repeats every ${_days.map((day) => _week.firstWhere((item) => item.day == day).full).join(', ')}.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
                  onPressed: _save,
                  child: Text(widget.task == null ? 'Add task' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final task = widget.task;
    if (task == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Delete this task?',
      message: '“${task.title}” will be removed and its reminder cancelled.',
    );
    if (!confirmed) return;
    await ref.read(appControllerProvider).deleteTask(task.id);
    if (mounted) Navigator.pop(context);
  }
}
