import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/data_provider.dart';
import '../data/data_provider_scope.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../theme/theme_provider_scope.dart';
import '../ui/ui.dart';
import '../ui/widgets/logo.dart';
import '../utils/date_utils.dart';
import '../utils/format.dart';
import '../utils/habit_utils.dart';

/// Insights dashboard — the default landing tab.
///
/// Mirrors the web app's `InsightsScreen`: greeting + date header, 2×2 stat
/// grid, horizontal quick-action chips, smart insights (streak / week task %
/// / spending MoM / note activity), this-week habits heatmap, recent notes
/// carousel, accounts strip, and a settings sheet with theme picker.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  Widget build(BuildContext context) {
    final data = DataProviderScope.of(context);
    final c = AppTheme.of(context);
    final now = DateTime.now();
    final hour = now.hour;
    final tStr = AbidDates.todayStr();

    final scheduledToday =
        data.habits.where((h) => !h.archived && HabitUtils.scheduledOn(h, now)).toList();
    final habitsDone = scheduledToday
        .where((h) => data.logs.any((l) => l.habitId == h.id && l.date == tStr))
        .length;
    var bestStreak = (current: 0, name: '');
    for (final h in data.habits) {
      if (h.archived) continue;
      final dates = data.logs
          .where((l) => l.habitId == h.id)
          .map((l) => l.date)
          .toSet();
      final s = HabitUtils.getStreaks(h, dates);
      if (s.current > bestStreak.current) {
        bestStreak = (current: s.current, name: h.name);
      }
    }

    final openTasks = data.tasks.where((t) => !t.done).toList();
    final dueToday = openTasks.where((t) => t.dueDate != null && t.dueDate!.compareTo(tStr) <= 0).length;
    final weekDue = data.tasks.where((t) =>
        t.dueDate != null &&
        AbidDates.isSameWeek(AbidDates.parseD(t.dueDate!), now)).toList();
    final weekPct = weekDue.isEmpty
        ? null
        : ((weekDue.where((t) => t.done).length / weekDue.length) * 100).round();

    final balanceAll = data.txns.fold<int>(
        0, (s, t) => s + (t.type == TxnType.income ? t.amount : -t.amount));
    final monthOut = data.txns
        .where((t) =>
            t.type == TxnType.expense &&
            AbidDates.isSameMonth(t.occurredAt, now))
        .fold<int>(0, (s, t) => s + t.amount);
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthOut = data.txns
        .where((t) =>
            t.type == TxnType.expense &&
            AbidDates.isSameMonth(t.occurredAt, lastMonth))
        .fold<int>(0, (s, t) => s + t.amount);
    final momDelta = (lastMonthOut > 0 && monthOut > 0)
        ? ((monthOut - lastMonthOut) / lastMonthOut * 100).round()
        : null;

    final notesLive = data.notes.where((n) => !n.archived).toList();
    final notesThisWeek = notesLive
        .where((n) => AbidDates.isSameWeek(n.updatedAt, now))
        .length;
    final recentNotes = [...notesLive]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final insights = <_Insight>[];
    if (bestStreak.current >= 3) {
      insights.add(_Insight(
        icon: LucideIcons.flame,
        color: 'orange',
        text:
            "You're on a ${bestStreak.current}-day ${bestStreak.name.toLowerCase()} streak. Protect it today.",
      ));
    }
    if (weekPct != null) {
      insights.add(_Insight(
        icon: LucideIcons.checkCircle2,
        color: 'blue',
        text:
            "You've completed $weekPct% of this week's tasks${weekPct >= 80 ? ' — excellent pace' : ''}.",
      ));
    }
    if (momDelta != null && momDelta.abs() >= 5) {
      insights.add(_Insight(
        icon: momDelta <= 0 ? LucideIcons.trendingDown : LucideIcons.trendingUp,
        color: momDelta <= 0 ? 'green' : 'pink',
        text: momDelta <= 0
            ? 'Your spending is ${momDelta.abs()}% lower than last month.'
            : 'Your spending is $momDelta% higher than last month.',
      ));
    }
    if (notesThisWeek >= 2) {
      insights.add(_Insight(
        icon: LucideIcons.notebookPen,
        color: 'amber',
        text: '$notesThisWeek notes touched this week — your second brain is active.',
      ));
    }

    final weekDays = List.generate(7, (i) {
      final d = AbidDates.addDays(now, i - 6);
      return AbidDates.dateStr(d);
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_greetingIcon(hour), size: 17, color: c.amber),
                        const SizedBox(width: 6),
                        Text(
                          AbidDates.greeting(hour),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.ink2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Here's your day.",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AbidDates.longDate(now),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showSettings(context),
                icon: Icon(LucideIcons.settings2, size: 18, color: c.ink2),
                style: IconButton.styleFrom(
                  backgroundColor: c.surface,
                  side: BorderSide(color: c.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 120 + MediaQuery.viewPaddingOf(context).bottom),
            children: [
              // Stat grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  _StatCard(
                    color: 'green',
                    icon: LucideIcons.flame,
                    label: 'Habits',
                    big: data.habits.isEmpty
                        ? '—'
                        : '$habitsDone/${scheduledToday.length}',
                    sub: data.habits.isEmpty
                        ? 'Create your first habit'
                        : bestStreak.current > 0
                            ? '${bestStreak.current} day streak'
                            : 'No streak yet',
                    onTap: () => data.setTab(Tab.habits),
                  ),
                  _StatCard(
                    color: 'blue',
                    icon: LucideIcons.checkCircle2,
                    label: 'Tasks',
                    big: '$dueToday',
                    sub: dueToday == 0
                        ? 'Nothing due today'
                        : 'task${dueToday == 1 ? '' : 's'} left today',
                    onTap: () => data.setTab(Tab.tasks),
                  ),
                  _StatCard(
                    color: 'teal',
                    icon: LucideIcons.wallet,
                    label: 'Money',
                    big: data.accounts.isEmpty ? '—' : Fmt.inr(balanceAll),
                    sub: data.accounts.isEmpty
                        ? 'Add your first account'
                        : monthOut > 0
                            ? '${Fmt.inr(monthOut)} spent in ${AbidDates.shortDate(now).split(' ').last}'
                            : 'No spending yet',
                    onTap: () => data.setTab(Tab.money),
                    small: true,
                  ),
                  _StatCard(
                    color: 'amber',
                    icon: LucideIcons.notebookPen,
                    label: 'Notes',
                    big: '${notesLive.length}',
                    sub: notesThisWeek > 0
                        ? '$notesThisWeek updated this week'
                        : 'Capture an idea',
                    onTap: () => data.setTab(Tab.notes),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Quick actions
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _QuickChip(
                      icon: LucideIcons.notebookPen,
                      label: 'New note',
                      onTap: () => data.requestQuick(Tab.notes, 'new'),
                    ),
                    _QuickChip(
                      icon: LucideIcons.listPlus,
                      label: 'New task',
                      onTap: () => data.requestQuick(Tab.tasks, 'new'),
                    ),
                    _QuickChip(
                      icon: LucideIcons.plus,
                      label: 'New habit',
                      onTap: () => data.requestQuick(Tab.habits, 'new'),
                    ),
                    _QuickChip(
                      icon: LucideIcons.search,
                      label: 'Find note',
                      onTap: () => data.requestQuick(Tab.notes, 'search'),
                    ),
                  ],
                ),
              ),
              if (insights.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(LucideIcons.lightbulb, size: 13, color: c.amber),
                    const SizedBox(width: 6),
                    Text('SMART INSIGHTS',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: c.ink3,
                        )),
                  ],
                ),
                const SizedBox(height: 10),
                ...insights.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _InsightCard(insight: i),
                    )),
              ],
              if (data.habits.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('THIS WEEK · HABITS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: c.ink3,
                    )),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: c.line),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 52, right: 4, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: weekDays
                              .map((d) => Text(
                                    AbidDates.weekdayShort(AbidDates.parseD(d).weekday),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: c.ink3,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      ...data.habits.where((h) => !h.archived).map((h) {
                        final dates = data.logs
                            .where((l) => l.habitId == h.id)
                            .map((l) => l.date)
                            .toSet();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 52,
                                child: Text(
                                  h.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: c.ink2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: weekDays.map((d) {
                                    final done = dates.contains(d);
                                    final isFuture = d.compareTo(tStr) > 0;
                                    final scheduled =
                                        HabitUtils.scheduledOn(h, AbidDates.parseD(d));
                                    final color = done
                                        ? c.accent(h.color)
                                        : (isFuture || !scheduled)
                                            ? c.surface2
                                            : c.tint(h.color, 20);
                                    return Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              if (recentNotes.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RECENT NOTES',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: c.ink3,
                        )),
                    GestureDetector(
                      onTap: () => data.setTab(Tab.notes),
                      child: Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: c.brand,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentNotes.length > 4 ? 4 : recentNotes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final n = recentNotes[i];
                      return GestureDetector(
                        onTap: () => data.setTab(Tab.notes),
                        child: Container(
                          width: 132,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: noteColor(n.color, Theme.of(context).brightness),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: c.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.locked ? 'Private note' : (n.title.isEmpty ? 'Untitled' : n.title),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: c.ink,
                                  height: 1.3,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                AbidDates.shortDate(n.updatedAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: c.ink3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (data.accounts.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('ACCOUNTS',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: c.ink3,
                    )),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => data.setTab(Tab.money),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: c.line),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 36 + (data.accounts.length > 1 ? 18 : 0),
                          child: Stack(
                            children: data.accounts
                                .where((a) => !a.archived)
                                .take(4)
                                .toList()
                                .asMap()
                                .entries
                                .map((e) {
                              final a = e.value;
                              final icon = kAccountIcons[a.icon] ?? LucideIcons.wallet;
                              return Transform.translate(
                                offset: Offset(e.key * 18.0, 0),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: c.tint(a.color, 14),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: c.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(icon, size: 14, color: c.accent(a.color)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.accounts
                                    .where((a) => !a.archived)
                                    .map((a) => a.name)
                                    .join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: c.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Combined balance ',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: c.ink3,
                                      ),
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: MoneyText(
                                        paise: balanceAll,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: c.ink2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  IconData _greetingIcon(int hour) {
    if (hour >= 5 && hour < 12) return LucideIcons.sunrise;
    if (hour >= 12 && hour < 17) return LucideIcons.sun;
    if (hour >= 17 && hour < 21) return LucideIcons.sunset;
    return LucideIcons.moonStar;
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _SettingsSheet(),
    );
  }
}

/* ------------------------------- Sub-widgets ------------------------------ */

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.big,
    required this.sub,
    required this.onTap,
    this.small = false,
  });
  final String color;
  final IconData icon;
  final String label;
  final String big;
  final String sub;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        buzz(6);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: c.accent(color)),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: c.ink3,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              big,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: small ? 21 : 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: c.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: c.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          buzz(7);
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Icon(icon, size: 13.5, color: c.brand),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: c.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Insight {
  final IconData icon;
  final String color;
  final String text;
  const _Insight({required this.icon, required this.color, required this.text});
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final accent = c.accent(insight.color);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.tint(insight.color, 13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(insight.icon, size: 16, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight.text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.ink2,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final theme = ThemeProviderScope.of(context);
    final options = [
      (ThemeMode.system, 'System', LucideIcons.monitor),
      (ThemeMode.light, 'Light', LucideIcons.sun),
      (ThemeMode.dark, 'Dark', LucideIcons.moonStar),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.surface3,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const LumaLogo(size: 34),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ABIDLIFE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      'Everything you need, in one place',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('APPEARANCE',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: c.ink3,
                )),
            const SizedBox(height: 10),
            Row(
              children: options.map((o) {
                final selected = theme.mode == o.$1;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () {
                        buzz(7);
                        theme.setMode(o.$1);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? c.tint('violet', 10) : c.surface2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? c.brand : c.line,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(o.$3,
                                size: 18,
                                color: selected ? c.brand : c.ink2),
                            const SizedBox(height: 6),
                            Text(
                              o.$2,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: selected ? c.brand : c.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () async {
                buzz(8);
                Navigator.of(context).maybePop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('abidlife.onboarded', false);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.rotateCcw, size: 15, color: c.ink2),
                    const SizedBox(width: 12),
                    Text(
                      'Replay onboarding',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: c.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Local-first · Your data stays with you · v1.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: c.ink3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
