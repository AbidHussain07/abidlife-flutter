import 'package:abidlife/core/app_theme.dart';
import 'package:abidlife/core/brand_mark.dart';
import 'package:abidlife/core/formatters.dart';
import 'package:abidlife/domain/money_math.dart';
import 'package:abidlife/domain/streaks.dart';
import 'package:abidlife/models/models.dart';
import 'package:abidlife/providers/app_controller.dart';
import 'package:abidlife/widgets/app_icons.dart';
import 'package:abidlife/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final now = DateTime.now();
    final openTasks = app.tasks.where((task) => !task.done).length;
    final activeHabits = app.habits.where((habit) => !habit.archived).toList();
    final scheduled = activeHabits.where((habit) => isHabitScheduled(habit, now)).toList();
    final doneHabits = scheduled.where(
      (habit) => app.habitLogs.any(
        (log) => log.habitId == habit.id && log.date == dayKey(now),
      ),
    ).length;
    final liveNotes = app.notes.where((note) => !note.archived).toList();
    final liveAccounts = app.accounts.where((account) => !account.archived).toList();
    final totalBalance = accountBalance(app.transactions);
    final monthSpent = app.transactions
        .where(
          (transaction) =>
              transaction.type == TransactionType.expense &&
              transaction.occurredAt.year == now.year &&
              transaction.occurredAt.month == now.month,
        )
        .fold(0, (sum, transaction) => sum + transaction.amountPaise);

    final best = activeHabits.fold<({String name, int streak})>(
      (name: '', streak: 0),
      (current, habit) {
        final streak = calculateStreaks(habit, app.habitLogs).current;
        return streak > current.streak ? (name: habit.name, streak: streak) : current;
      },
    );
    final insights = <({IconData icon, Color color, String text})>[];
    if (best.streak >= 3) {
      insights.add((
        icon: Icons.local_fire_department_rounded,
        color: AppColors.orange,
        text: "You're on a ${best.streak}-day ${best.name.toLowerCase()} streak. Protect it today.",
      ));
    }
    final weekStart = dateOnly(now).subtract(Duration(days: now.weekday - 1));
    final weekTasks = app.tasks.where((task) => task.dueAt != null && !dateOnly(task.dueAt!).isBefore(weekStart) && dateOnly(task.dueAt!).isBefore(weekStart.add(const Duration(days: 7)))).toList();
    if (weekTasks.isNotEmpty) {
      final percentage = (weekTasks.where((task) => task.done).length * 100 / weekTasks.length).round();
      insights.add((
        icon: Icons.task_alt_rounded,
        color: AppColors.blue,
        text: 'You completed $percentage% of tasks due this week.',
      ));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(98),
        child: AppPageHeader(
          title: "Here's your day.",
          subtitle: '${greeting(now)} · ${DateFormat('EEEE, d MMMM').format(now)}',
          actions: <Widget>[
            IconButton.filledTonal(
              tooltip: 'Settings',
              onPressed: () => _settings(context, ref),
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 106),
        children: <Widget>[
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 11,
            crossAxisSpacing: 11,
            childAspectRatio: 1.28,
            children: <Widget>[
              _stat(
                context,
                icon: Icons.local_fire_department_rounded,
                color: AppColors.green,
                label: 'Habits',
                value: activeHabits.isEmpty ? '—' : '$doneHabits/${scheduled.length}',
                caption: activeHabits.isEmpty
                    ? 'Create your first habit'
                    : best.streak > 0
                        ? '${best.streak} day streak'
                        : 'No streak yet',
              ),
              _stat(
                context,
                icon: Icons.task_alt_rounded,
                color: AppColors.blue,
                label: 'Tasks',
                value: app.tasks.isEmpty ? '—' : '$openTasks',
                caption: app.tasks.isEmpty
                    ? 'Add your first task'
                    : openTasks == 0
                        ? 'All caught up'
                        : '$openTasks remaining',
              ),
              _stat(
                context,
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.teal,
                label: 'Money',
                value: liveAccounts.isEmpty ? '—' : formatMoney(totalBalance),
                caption: liveAccounts.isEmpty
                    ? 'Add your first account'
                    : monthSpent == 0
                        ? 'No spending this month'
                        : '${formatMoney(monthSpent)} spent this month',
                small: true,
              ),
              _stat(
                context,
                icon: Icons.sticky_note_2_rounded,
                color: AppColors.amber,
                label: 'Notes',
                value: liveNotes.isEmpty ? '—' : '${liveNotes.length}',
                caption: liveNotes.isEmpty ? 'Capture your first idea' : '${liveNotes.length} saved notes',
              ),
            ],
          ),
          if (insights.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            const SectionLabel('Smart insights'),
            ...insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: SoftCard(
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: insight.color.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(insight.icon, color: insight.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(insight.text, style: Theme.of(context).textTheme.bodyMedium)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (activeHabits.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            const SectionLabel('This week · habits'),
            SoftCard(
              child: Column(
                children: activeHabits.map((habit) {
                  final color = AppColors.habit(habit.color);
                  final week = List<DateTime>.generate(
                    7,
                    (index) => dateOnly(now).subtract(Duration(days: 6 - index)),
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 76,
                          child: Text(habit.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
                        ),
                        for (final date in week)
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: app.habitLogs.any((log) => log.habitId == habit.id && log.date == dayKey(date))
                                      ? color
                                      : isHabitScheduled(habit, date)
                                          ? color.withValues(alpha: .14)
                                          : Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (liveNotes.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            const SectionLabel('Recent notes'),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: liveNotes.take(5).length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final note = liveNotes[index];
                  return Container(
                    width: 142,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.note(note.color, Theme.of(context).brightness),
                      borderRadius: BorderRadius.circular(21),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (note.locked) const Icon(Icons.lock_rounded, size: 15, color: AppColors.brand),
                        Text(
                          note.title.isEmpty ? 'Untitled' : note.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        Text(relativeDay(note.updatedAt), style: Theme.of(context).textTheme.labelSmall),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (liveAccounts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            const SectionLabel('Accounts'),
            SoftCard(
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 102,
                    child: Stack(
                      children: List<Widget>.generate(
                        liveAccounts.take(4).length,
                        (index) {
                          final account = liveAccounts[index];
                          return Positioned(
                            left: index * 23,
                            child: CircleAvatar(
                              backgroundColor: AppColors.habit(account.color).withValues(alpha: .18),
                              foregroundColor: AppColors.habit(account.color),
                              child: Icon(accountIcons[account.icon] ?? Icons.wallet_rounded, size: 17),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('${liveAccounts.length} account${liveAccounts.length == 1 ? '' : 's'}', style: Theme.of(context).textTheme.titleMedium),
                        Text('Combined ${formatMoney(totalBalance)}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String caption,
    bool small = false,
  }) {
    return SoftCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: .8)),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: small ? 20 : 27, fontWeight: FontWeight.w800, letterSpacing: -.7),
          ),
          Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Future<void> _settings(BuildContext context, WidgetRef ref) async {
    final app = ref.read(appControllerProvider);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                BrandMark(size: 40),
                SizedBox(width: 11),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('ABIDLIFE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('Everything you need, in one place', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SectionLabel('Appearance'),
            SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_android_rounded), label: Text('System')),
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
              ],
              selected: <ThemeMode>{app.themeMode},
              onSelectionChanged: (value) => ref.read(appControllerProvider).setThemeMode(value.first),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.replay_rounded),
              title: const Text('Replay onboarding'),
              onTap: () {
                Navigator.pop(context);
                ref.read(appControllerProvider).replayOnboarding();
              },
            ),
            const Center(child: Text('Offline-first · Your data stays with you · v1.0', style: TextStyle(fontSize: 10))),
          ],
        ),
      ),
    );
  }
}
