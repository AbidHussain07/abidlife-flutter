import 'package:abidlife/core/app_theme.dart';
import 'package:abidlife/core/formatters.dart';
import 'package:abidlife/domain/streaks.dart';
import 'package:abidlife/models/models.dart';
import 'package:abidlife/providers/app_controller.dart';
import 'package:abidlife/widgets/app_icons.dart';
import 'package:abidlife/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final active = app.habits.where((habit) => !habit.archived).toList();
    final now = DateTime.now();
    final today = dayKey(now);
    final scheduled = active.where((habit) => isHabitScheduled(habit, now)).toList();
    final done = scheduled.where(
      (habit) => app.habitLogs.any(
        (log) =>
            log.habitId == habit.id &&
            log.date == today &&
            log.status == HabitLogStatus.completed,
      ),
    ).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(94),
        child: AppPageHeader(
          title: "Today's habits",
          subtitle: '${greeting(now)} · ${DateFormat('EEEE, d MMM').format(now)}',
        ),
      ),
      body: active.isEmpty
          ? EmptyState(
              icon: Icons.local_fire_department_rounded,
              title: 'Start your first habit',
              message: 'Small steps, every day. Build a streak that feels worth protecting.',
              actionLabel: 'Create habit',
              onAction: () => _openCreate(context),
              color: AppColors.green,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 106),
              children: <Widget>[
                SoftCard(
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 74,
                        height: 74,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            CircularProgressIndicator(
                              value: scheduled.isEmpty ? 0 : done / scheduled.length,
                              strokeWidth: 7,
                              strokeCap: StrokeCap.round,
                              color: AppColors.green,
                              backgroundColor: Theme.of(context).dividerColor,
                            ),
                            Text(
                              '$done/${scheduled.length}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              done == scheduled.length && scheduled.isNotEmpty
                                  ? 'Perfect day — all done'
                                  : done == 0
                                      ? 'Fresh start — check in'
                                      : 'Nice momentum, keep going',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${scheduled.length - done} remaining today',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionLabel('${active.length} habits'),
                ...active.map(
                  (habit) => _HabitCard(
                    habit: habit,
                    logs: app.habitLogs,
                    onOpen: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => HabitDetailScreen(habitId: habit.id),
                      ),
                    ),
                    onToggle: () {
                      HapticFeedback.mediumImpact();
                      ref.read(appControllerProvider).toggleHabitToday(habit.id);
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: active.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton(
                heroTag: 'habits_fab',
                tooltip: 'New habit',
                backgroundColor: AppColors.green,
                onPressed: () => _openCreate(context),
                child: const Icon(Icons.add_rounded),
              ),
            ),
    );
  }

  Future<void> _openCreate(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const _HabitEditor(),
      );
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.logs,
    required this.onOpen,
    required this.onToggle,
  });

  final HabitModel habit;
  final List<HabitLogModel> logs;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.habit(habit.color);
    final streak = calculateStreaks(habit, logs);
    final today = DateTime.now();
    final complete = logs.any(
      (log) =>
          log.habitId == habit.id &&
          log.date == dayKey(today) &&
          log.status == HabitLogStatus.completed,
    );
    final scheduledToday = isHabitScheduled(habit, today);
    final week = List<DateTime>.generate(
      7,
      (index) => dateOnly(today).subtract(Duration(days: 6 - index)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(habitIcons[habit.icon] ?? Icons.auto_awesome_rounded, color: color),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(habit.name, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            '🔥 ${streak.current} day${streak.current == 1 ? '' : 's'} · ${_frequencyLabel(habit)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (scheduledToday)
                      Semantics(
                        button: true,
                        label: complete ? 'Uncheck ${habit.name}' : 'Complete ${habit.name}',
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onToggle,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: complete ? color : Colors.transparent,
                              border: Border.all(
                                color: complete ? color : Theme.of(context).dividerColor,
                                width: 2,
                              ),
                            ),
                            child: complete
                                ? const Icon(Icons.check_rounded, color: Colors.white)
                                : null,
                          ),
                        ),
                      )
                    else
                      const Chip(label: Text('Rest day')),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: week.map((date) {
                    final done = logs.any(
                      (log) =>
                          log.habitId == habit.id &&
                          log.date == dayKey(date) &&
                          log.status == HabitLogStatus.completed,
                    );
                    final scheduled = isHabitScheduled(habit, date);
                    return Column(
                      children: <Widget>[
                        Text(
                          sameDay(date, today) ? 'Now' : DateFormat('EEEEE').format(date),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: sameDay(date, today) ? 13 : 10,
                          height: sameDay(date, today) ? 13 : 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done
                                ? color
                                : scheduled
                                    ? color.withValues(alpha: .18)
                                    : Theme.of(context).dividerColor,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _frequencyLabel(HabitModel habit) => switch (habit.frequency) {
        HabitFrequency.daily => 'Daily',
        HabitFrequency.selectedDays => '${habit.repeatDays.length}x a week',
        HabitFrequency.weeklyGoal => '${habit.weeklyGoal}x weekly goal',
      };
}

class _HabitEditor extends ConsumerStatefulWidget {
  const _HabitEditor();

  @override
  ConsumerState<_HabitEditor> createState() => _HabitEditorState();
}

class _HabitEditorState extends ConsumerState<_HabitEditor> {
  final _name = TextEditingController();
  var _icon = 'sparkles';
  var _color = 'green';
  var _frequency = HabitFrequency.daily;
  var _days = <int>[1, 3, 5];
  var _weeklyGoal = 3;
  var _reminder = false;
  var _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    await ref.read(appControllerProvider).createHabit(
          name: _name.text,
          icon: _icon,
          color: _color,
          frequency: _frequency,
          repeatDays: _frequency == HabitFrequency.selectedDays ? _days : const <int>[],
          weeklyGoal: _weeklyGoal,
          reminder: _reminder,
          reminderHour: _reminderTime.hour,
          reminderMinute: _reminderTime.minute,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const colors = <String>['green', 'blue', 'violet', 'orange', 'teal', 'pink'];
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .92),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('New habit', style: Theme.of(context).textTheme.titleLarge),
              TextField(
                controller: _name,
                autofocus: true,
                style: Theme.of(context).textTheme.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'e.g. Drink Water',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              const SectionLabel('Icon'),
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: habitIcons.entries
                    .map(
                      (entry) => InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _icon = entry.key),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _icon == entry.key
                                ? AppColors.habit(_color).withValues(alpha: .14)
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            entry.value,
                            color: _icon == entry.key ? AppColors.habit(_color) : null,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              const SectionLabel('Color'),
              Wrap(
                spacing: 12,
                children: colors
                    .map(
                      (name) => InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _color = name),
                        child: CircleAvatar(
                          radius: 21,
                          backgroundColor: AppColors.habit(name),
                          child: _color == name ? const Icon(Icons.check_rounded, color: Colors.white) : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              const SectionLabel('Frequency'),
              Wrap(
                spacing: 8,
                children: HabitFrequency.values
                    .map(
                      (value) => ChoiceChip(
                        selected: _frequency == value,
                        label: Text(switch (value) {
                          HabitFrequency.daily => 'Every day',
                          HabitFrequency.selectedDays => 'Specific days',
                          HabitFrequency.weeklyGoal => 'Weekly goal',
                        }),
                        onSelected: (_) => setState(() => _frequency = value),
                      ),
                    )
                    .toList(),
              ),
              if (_frequency == HabitFrequency.selectedDays) ...<Widget>[
                const SizedBox(height: 12),
                _WeekdayPicker(
                  selected: _days,
                  onChanged: (days) => setState(() => _days = days),
                ),
              ],
              if (_frequency == HabitFrequency.weeklyGoal) ...<Widget>[
                const SizedBox(height: 8),
                Text('$_weeklyGoal times per week', style: Theme.of(context).textTheme.titleMedium),
                Slider(
                  value: _weeklyGoal.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  label: '$_weeklyGoal',
                  onChanged: (value) => setState(() => _weeklyGoal = value.round()),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  _reminder
                      ? 'Every scheduled day at ${_reminderTime.format(context)}'
                      : 'Off',
                ),
                value: _reminder,
                onChanged: (value) => setState(() => _reminder = value),
              ),
              if (_reminder)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ActionChip(
                    avatar: const Icon(Icons.schedule_rounded, size: 17),
                    label: Text(_reminderTime.format(context)),
                    onPressed: () async {
                      final selected = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                      );
                      if (selected != null && mounted) {
                        setState(() => _reminderTime = selected);
                      }
                    },
                  ),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.green),
                  onPressed: _save,
                  child: const Text('Start habit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.selected, required this.onChanged});
  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(7, (index) {
        final day = index + 1;
        final active = selected.contains(day);
        return InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            final values = List<int>.from(selected);
            active ? values.remove(day) : values.add(day);
            values.sort();
            onChanged(values);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.green.withValues(alpha: .14)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(15),
              border: active ? Border.all(color: AppColors.green) : null,
            ),
            child: Text(labels[index], style: TextStyle(color: active ? AppColors.green : null, fontWeight: FontWeight.w800)),
          ),
        );
      }),
    );
  }
}

class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({required this.habitId, super.key});
  final String habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  var _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final habit = app.habits.firstWhere((item) => item.id == widget.habitId);
    final logs = app.habitLogs.where((log) => log.habitId == habit.id).toList();
    final streak = calculateStreaks(habit, logs);
    final rate = completionRate(habit, logs);
    final color = AppColors.habit(habit.color);
    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: <Widget>[
          IconButton(
            tooltip: 'Delete habit',
            color: AppColors.expense,
            onPressed: () => _delete(habit),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _stat(context, 'Current', '${streak.current}', 'days', Icons.local_fire_department_rounded, color)),
              const SizedBox(width: 9),
              Expanded(child: _stat(context, 'Best', '${streak.best}', 'days', Icons.emoji_events_rounded, AppColors.amber)),
              const SizedBox(width: 9),
              Expanded(child: _stat(context, '30 days', '$rate', '%', Icons.insights_rounded, AppColors.blue)),
            ],
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy').format(_month),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    for (final day in <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                      Expanded(child: Center(child: Text(day, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)))),
                  ],
                ),
                const SizedBox(height: 7),
                _calendar(habit, logs, color),
                const SizedBox(height: 10),
                const Row(
                  children: <Widget>[
                    _Legend(color: AppColors.green, text: 'Done'),
                    SizedBox(width: 14),
                    _Legend(color: AppColors.expense, text: 'Missed'),
                    SizedBox(width: 14),
                    _Legend(color: Colors.grey, text: 'Rest'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.info_outline_rounded, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Past dates are read-only so streaks stay honest. Only today can be checked or unchecked.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value, String suffix, IconData icon, Color color) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 7),
          Text.rich(
            TextSpan(
              text: value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              children: <InlineSpan>[
                TextSpan(text: ' $suffix', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _calendar(HabitModel habit, List<HabitLogModel> logs, Color color) {
    final first = DateTime(_month.year, _month.month);
    final offset = first.weekday - 1;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = offset + days;
    final rows = (cells / 7).ceil();
    final today = dateOnly(DateTime.now());
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
      itemCount: rows * 7,
      itemBuilder: (context, index) {
        if (index < offset || index >= offset + days) return const SizedBox.shrink();
        final date = DateTime(_month.year, _month.month, index - offset + 1);
        final scheduled = isHabitScheduled(habit, date);
        final done = logs.any(
          (log) => log.date == dayKey(date) && log.status == HabitLogStatus.completed,
        );
        final missed = scheduled && date.isBefore(today) && !done;
        return InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () {
            if (sameDay(date, today) && scheduled) {
              ref.read(appControllerProvider).toggleHabitToday(habit.id);
            } else {
              showMessage(
                context,
                !scheduled
                    ? 'Rest day'
                    : done
                        ? 'Completed'
                        : date.isAfter(today)
                            ? 'Coming up'
                            : 'Missed',
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done
                  ? color
                  : missed
                      ? AppColors.expense.withValues(alpha: .12)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              border: sameDay(date, today) ? Border.all(color: color, width: 2) : null,
            ),
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: done
                    ? Colors.white
                    : missed
                        ? AppColors.expense
                        : scheduled
                            ? null
                            : Theme.of(context).disabledColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _delete(HabitModel habit) async {
    final confirmed = await confirmAction(
      context,
      title: 'Remove this habit?',
      message: '“${habit.name}” and its streak history will be deleted.',
      confirmLabel: 'Remove',
    );
    if (!confirmed) return;
    await ref.read(appControllerProvider).deleteHabit(habit.id);
    if (mounted) Navigator.pop(context);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(text, style: Theme.of(context).textTheme.labelSmall),
        ],
      );
}
