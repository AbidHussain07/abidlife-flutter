import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/data_provider.dart';
import '../../data/data_provider_scope.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../../utils/date_utils.dart';
import '../../utils/habit_utils.dart';

/// Full-screen habit detail view with calendar + streak stats.
///
/// Mirrors the web app's `HabitDetail`: header (icon + name + frequency +
/// delete), 3-up stat grid (current / best / 30-day rate), monthly calendar
/// with done/missed/rest/today states, legend, and a status info row.
class HabitDetail extends StatefulWidget {
  const HabitDetail({super.key, required this.habitId});
  final String habitId;

  @override
  State<HabitDetail> createState() => _HabitDetailState();
}

class _HabitDetailState extends State<HabitDetail> {
  DateTime _cursor = DateTime(DateTime.now().year, DateTime.now().month);
  String? _status;

  Habit? get _habit {
    final data = DataProviderScope.of(context);
    for (final h in data.habits) {
      if (h.id == widget.habitId) return h;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = DataProviderScope.of(context);
    final c = AppTheme.of(context);
    final habit = _habit;
    if (habit == null) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }
    final dates = data.logs
        .where((l) => l.habitId == habit.id)
        .map((l) => l.date)
        .toSet();
    final streaks = HabitUtils.getStreaks(habit, dates);
    final rate = HabitUtils.completionRate(habit, dates);
    final tStr = AbidDates.todayStr();
    final accent = c.accent(habit.color);
    final icon = kHabitIcons[habit.icon] ?? LucideIcons.sparkles;

    final monthStart = AbidDates.startOfMonth(_cursor);
    final monthEnd = AbidDates.endOfMonth(_cursor);
    // Week starts on Monday (weekday = 1).
    final gridStart = monthStart.subtract(Duration(days: (monthStart.weekday - 1) % 7));
    final gridEnd = monthEnd.add(Duration(days: 7 - monthEnd.weekday));

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(LucideIcons.chevronLeft, size: 22, color: c.ink2),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.tint(habit.color, 14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 20, color: accent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  Text(
                    habit.frequency.type == FrequencyType.daily
                        ? 'Every day'
                        : '${habit.frequency.days.length} days a week',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: c.ink3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ConfirmSheet.show(
                context,
                title: 'Remove this habit?',
                sub:
                    '"${habit.name}" and its ${streaks.current}-day streak history will be deleted.',
                confirmLabel: 'Remove',
                onConfirm: () {
                  data.deleteHabit(habit.id);
                  Navigator.of(context).maybePop();
                },
              );
            },
            icon: Icon(LucideIcons.trash2, size: 17, color: c.expense),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 40 + MediaQuery.viewPaddingOf(context).bottom),
        children: [
          // Stats
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Current streak',
                  value: '${streaks.current}',
                  suffix: streaks.current == 1 ? 'day' : 'days',
                  icon: LucideIcons.flame,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  label: 'Best streak',
                  value: '${streaks.best}',
                  suffix: streaks.best == 1 ? 'day' : 'days',
                  icon: LucideIcons.trophy,
                  color: c.amber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  label: '30-day rate',
                  value: '$rate',
                  suffix: '%',
                  icon: LucideIcons.calendarDays,
                  color: c.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Calendar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.line),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        buzz(5);
                        setState(() => _cursor = AbidDates.addMonths(_cursor, -1));
                      },
                      icon: Icon(LucideIcons.chevronLeft, size: 17, color: c.ink2),
                    ),
                    Text(
                      AbidDates.monthYear(_cursor),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        buzz(5);
                        setState(() => _cursor = AbidDates.addMonths(_cursor, 1));
                      },
                      icon: Icon(LucideIcons.chevronRight, size: 17, color: c.ink2),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: 7 + gridEnd.difference(gridStart).inDays + 1,
                  itemBuilder: (context, i) {
                    if (i < 7) {
                      // Weekday header row (M T W T F S S)
                      final wd = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      return Center(
                        child: Text(
                          wd[i],
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: c.ink3,
                          ),
                        ),
                      );
                    }
                    final d = gridStart.add(Duration(days: i - 7));
                    final ds = AbidDates.dateStr(d);
                    final inMonth = d.month == _cursor.month;
                    final sched = HabitUtils.scheduledOn(habit, d);
                    final done = dates.contains(ds);
                    final today = ds == tStr;
                    final past = ds.compareTo(tStr) < 0;
                    final missed = sched && past && !done && inMonth;

                    return GestureDetector(
                      onTap: () {
                        if (today && sched) {
                          buzz(10);
                          data.toggleHabitToday(habit.id);
                          setState(() => _status = done ? 'Unchecked' : 'Checked — streak going');
                        } else if (inMonth) {
                          buzz(5);
                          setState(() => _status =
                              '${AbidDates.shortDate(d)} — ${_describe(habit, d, dates, tStr)}');
                        }
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: done
                              ? accent
                              : missed
                                  ? c.expense.withValues(alpha: 0.12)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: today
                              ? Border.all(color: accent, width: 2)
                              : Border.all(color: Colors.transparent, width: 2),
                        ),
                        child: Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: done
                                ? Colors.white
                                : missed
                                    ? c.expense
                                    : !inMonth
                                        ? c.ink3.withValues(alpha: 0.4)
                                        : sched
                                            ? c.ink
                                            : c.ink3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Legend(swatch: accent, label: 'Done'),
                    const SizedBox(width: 16),
                    _Legend(swatch: c.expense.withValues(alpha: 0.5), label: 'Missed'),
                    const SizedBox(width: 16),
                    _Legend(swatch: c.surface3, label: 'Rest'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.info, size: 15, color: c.ink3),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _status ??
                        "Only today can be checked off — your streak stays honest. Tap a day to see its status.",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: c.ink3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _describe(Habit habit, DateTime d, Set<String> dates, String tStr) {
    final ds = AbidDates.dateStr(d);
    final today = DateTime.now();
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);
    if (!HabitUtils.scheduledOn(habit, d)) return 'Not scheduled — rest day';
    if (dates.contains(ds)) return 'Completed. Nice work.';
    if (ds == tStr) return 'Scheduled today — tap again to check off';
    if (d.isAfter(todayEnd)) return 'Coming up';
    return 'Missed';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final String suffix;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label.split(' ')[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: c.ink3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: suffix,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c.ink3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: c.ink3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.swatch, required this.label});
  final Color swatch;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: swatch, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: c.ink3,
          ),
        ),
      ],
    );
  }
}
