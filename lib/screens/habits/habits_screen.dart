import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/data_provider.dart';
import '../../data/data_provider_scope.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../../utils/date_utils.dart';
import '../../utils/habit_utils.dart';
import 'habit_detail.dart';

/// Habits screen — today's check-in summary + list of habit cards.
///
/// Mirrors the web app's `HabitsScreen`: greeting + date header, today
/// progress ring, habit cards with a 7-day strip and a check-off button,
/// and a "New habit" bottom sheet.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = DataProviderScope.of(context);
    if (data.quick?.tab == Tab.habits) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openCreate();
        data.consumeQuick();
      });
    }
  }

  Future<void> _openCreate() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _CreateHabitSheet(),
    );
  }

  Future<void> _openDetail(Habit habit) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HabitDetail(habitId: habit.id),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = DataProviderScope.of(context);
    final c = AppTheme.of(context);
    final now = DateTime.now();
    final hour = now.hour;
    final tStr = AbidDates.todayStr();

    final active = data.habits.where((h) => !h.archived).toList();
    final scheduledToday = active.where((h) => HabitUtils.scheduledOn(h, now)).toList();
    final doneToday = scheduledToday
        .where((h) => data.logs.any((l) => l.habitId == h.id && l.date == tStr))
        .length;
    final pct = scheduledToday.isEmpty ? 0.0 : doneToday / scheduledToday.length;

    var bestCurrent = 0;
    for (final h in active) {
      final dates = data.logs
          .where((l) => l.habitId == h.id)
          .map((l) => l.date)
          .toSet();
      final s = HabitUtils.getStreaks(h, dates);
      if (s.current > bestCurrent) bestCurrent = s.current;
    }

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_greetingIcon(hour), size: 17, color: c.amber),
                      const SizedBox(width: 6),
                      Text(
                        '${AbidDates.greeting(hour)} — ${AbidDates.shortDate(now)}',
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
                    "Today's habits",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: c.ink,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: active.isEmpty
                  ? EmptyState(
                      icon: LucideIcons.flame,
                      color: 'green',
                      title: 'Start your first habit',
                      sub:
                          "Small steps, every day. Streaks keep you honest — and motivated.",
                      action: 'Create habit',
                      onAction: _openCreate,
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(20, 4, 20, 140 + MediaQuery.viewPaddingOf(context).bottom),
                      children: [
                        _TodaySummary(
                          done: doneToday,
                          total: scheduledToday.length,
                          pct: pct,
                          bestStreak: bestCurrent,
                        ),
                        const SizedBox(height: 16),
                        SectionLabel('${active.length} habit${active.length == 1 ? '' : 's'}'),
                        ...active.map((h) => _HabitCard(habit: h, onOpen: _openDetail)),
                      ],
                    ),
            ),
          ],
        ),
        if (active.isNotEmpty)
          Positioned(
            right: 20,
            bottom: 92 + MediaQuery.viewPaddingOf(context).bottom,
            child: FloatingActionButton(
              heroTag: 'new-habit',
              backgroundColor: c.green,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                buzz(10);
                _openCreate();
              },
              child: const Icon(LucideIcons.plus, size: 24),
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
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({
    required this.done,
    required this.total,
    required this.pct,
    required this.bestStreak,
  });
  final int done;
  final int total;
  final double pct;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    const size = 76.0;
    const stroke = 7.0;
    const r = 30.0;
    final circ = 2 * 3.141592653589793 * r;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: -3.141592653589793 / 2,
                  child: CustomPaint(
                    size: const Size(size, size),
                    painter: _RingPainter(
                      progress: pct,
                      bgColor: c.surface3,
                      fgColor: c.green,
                      strokeWidth: stroke,
                      radius: r,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$done/$total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      'DONE',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pct == 1
                      ? 'Perfect day — all done'
                      : done == 0
                          ? 'Fresh start — tap to check in'
                          : 'Nice momentum, keep going',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.flame,
                        size: 13,
                        color: bestStreak > 0 ? c.orange : c.ink3),
                    const SizedBox(width: 4),
                    Text(
                      'Longest active streak: $bestStreak day${bestStreak == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: bestStreak > 0 ? c.orange : c.ink3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.bgColor,
    required this.fgColor,
    required this.strokeWidth,
    required this.radius,
  });
  final double progress;
  final Color bgColor;
  final Color fgColor;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * 3.141592653589793 * progress,
      false,
      Paint()
        ..color = fgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.bgColor != bgColor ||
      old.fgColor != fgColor;
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.habit, required this.onOpen});
  final Habit habit;
  final ValueChanged<Habit> onOpen;

  @override
  Widget build(BuildContext context) {
    final data = DataProviderScope.of(context);
    final c = AppTheme.of(context);
    final dates = data.logs
        .where((l) => l.habitId == habit.id)
        .map((l) => l.date)
        .toSet();
    final tStr = AbidDates.todayStr();
    final scheduledToday = HabitUtils.scheduledOn(habit, DateTime.now());
    final doneToday = dates.contains(tStr);
    final streaks = HabitUtils.getStreaks(habit, dates);
    final accent = c.accent(habit.color);
    final icon = kHabitIcons[habit.icon] ?? LucideIcons.sparkles;

    final week = List.generate(7, (i) {
      final d = AbidDates.addDays(DateTime.now(), i - 6);
      final ds = AbidDates.dateStr(d);
      return (
        ds: ds,
        sched: HabitUtils.scheduledOn(habit, d),
        done: dates.contains(ds),
        today: ds == tStr,
        future: ds.compareTo(tStr) > 0,
      );
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    buzz(5);
                    onOpen(habit);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: c.tint(habit.color, 14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(icon, size: 22, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: c.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(LucideIcons.flame,
                                    size: 12.5,
                                    color: streaks.current > 0 ? c.orange : c.ink3),
                                const SizedBox(width: 3),
                                Text(
                                  '${streaks.current} day${streaks.current == 1 ? '' : 's'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: streaks.current > 0 ? c.orange : c.ink3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  habit.frequency.type == FrequencyType.daily
                                      ? 'Daily'
                                      : '${habit.frequency.days.length}x a week',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: c.ink3,
                                  ),
                                ),
                                if (habit.reminder) ...[
                                  const SizedBox(width: 6),
                                  Icon(LucideIcons.bell, size: 11, color: c.ink3),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (scheduledToday)
                GestureDetector(
                  onTap: () {
                    buzz(doneToday ? 6 : 14);
                    data.toggleHabitToday(habit.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: doneToday ? accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: doneToday ? accent : c.surface3,
                        width: 2,
                      ),
                    ),
                    child: doneToday
                        ? const Icon(Icons.check, size: 17, color: Colors.white)
                        : null,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Rest day',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: c.ink3,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: week.map((w) {
              return Column(
                children: [
                  Text(
                    w.today ? 'Now' : AbidDates.weekdayShort(AbidDates.parseD(w.ds).weekday),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: w.today ? accent : c.ink3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: w.done
                          ? accent
                          : (w.sched && !w.future)
                              ? c.tint(habit.color, 22)
                              : c.surface3,
                      shape: BoxShape.circle,
                      border: w.today ? Border.all(color: c.tint(habit.color, 18), width: 3) : null,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CreateHabitSheet extends StatefulWidget {
  const _CreateHabitSheet();

  @override
  State<_CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends State<_CreateHabitSheet> {
  final _nameCtrl = TextEditingController();
  String _icon = 'Sparkles';
  String _color = 'green';
  String _mode = 'daily';
  List<int> _days = [1, 3, 5];
  bool _reminder = false;

  static const _suggestions = [
    'Drink Water', 'Read', 'Exercise', 'Meditation', 'Study', 'Walk', 'Sleep Early', 'No Sugar'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      (_mode == 'daily' || _days.isNotEmpty);

  Future<void> _save() async {
    if (!_valid) return;
    buzz(10);
    final data = DataProviderScope.of(context);
    await data.addHabit({
      'name': _nameCtrl.text.trim(),
      'icon': _icon,
      'color': _color,
      'frequency': _mode == 'daily'
          ? const Frequency(type: FrequencyType.daily)
          : Frequency(type: FrequencyType.days, days: [..._days]..sort()),
      'reminder': _reminder,
    });
    data.toast('Habit created — day one starts now');
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
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
              Text(
                'New habit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Drink Water',
                  hintStyle: TextStyle(color: c.ink3),
                  border: InputBorder.none,
                ),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _suggestions.map((s) {
                  return GestureDetector(
                    onTap: () {
                      buzz(5);
                      setState(() => _nameCtrl.text = s);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.surface2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: c.ink2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('ICON',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: c.ink3,
                  )),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
                children: kHabitIcons.keys.map((k) {
                  final selected = _icon == k;
                  final icon = kHabitIcons[k]!;
                  return GestureDetector(
                    onTap: () {
                      buzz(5);
                      setState(() => _icon = k);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? c.tint(_color, 16) : c.surface2,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        size: 19,
                        color: selected ? c.accent(_color) : c.ink3,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('COLOR',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: c.ink3,
                  )),
              const SizedBox(height: 10),
              ColorRow(
                value: _color,
                onChanged: (v) => setState(() => _color = v),
                colors: kPaletteNames.where((c) => c != 'red').toList(),
              ),
              const SizedBox(height: 20),
              Text('FREQUENCY',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: c.ink3,
                  )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChipButton(
                    label: 'Every day',
                    color: 'green',
                    active: _mode == 'daily',
                    onTap: () => setState(() => _mode = 'daily'),
                  ),
                  ChipButton(
                    label: 'Specific days',
                    color: 'green',
                    active: _mode == 'days',
                    onTap: () => setState(() => _mode = 'days'),
                  ),
                ],
              ),
              if (_mode == 'days') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    // i = 0..6 → Sun..Sat
                    final selected = _days.contains(i);
                    final labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                    return GestureDetector(
                      onTap: () {
                        buzz(5);
                        setState(() {
                          if (selected) {
                            _days.remove(i);
                          } else {
                            _days.add(i);
                          }
                        });
                      },
                      child: Container(
                        width: 38,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? c.tint(_color, 16) : c.surface2,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: selected ? c.accent(_color) : c.ink3,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.bell, size: 16, color: c.ink2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Daily reminder',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: c.ink2,
                        ),
                      ),
                    ),
                    Toggle(
                      on: _reminder,
                      onChange: () => setState(() => _reminder = !_reminder),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _valid ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: c.surface3,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Start habit',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
