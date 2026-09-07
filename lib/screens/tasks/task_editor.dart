import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/data_provider.dart';
import '../../data/data_provider_scope.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../../utils/date_utils.dart';

/// Bottom sheet for creating / editing a task.
///
/// Mirrors the web app's task form: title, notes, priority (none/low/medium/
/// high), category chips, due date + due time pickers, recurrence picker
/// (none/daily/weekly/monthly) with weekday selector for weekly, and a
/// reminder toggle. The recurrence rule's next-occurrence logic lives in
/// [HabitUtils.nextOccurrenceDate] and is invoked by the data layer when a
/// task is toggled done (auto-rescheduling).
class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, this.existing});
  final Task? existing;

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;
  late String _priority;
  late String _category;
  String? _dueDate;
  String? _dueTime;
  late bool _reminder;
  late String _recurrence;
  late List<int> _repeatDays;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _notesCtrl = TextEditingController(text: t?.notes ?? '');
    _priority = t?.priority ?? 'none';
    _category = t?.category ?? 'Personal';
    _dueDate = t?.dueDate;
    _dueTime = t?.dueTime;
    _reminder = t?.reminder ?? false;
    _recurrence = t?.recurrence ?? 'none';
    _repeatDays = List<int>.from(t?.repeatDays ?? const []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _titleCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_valid) return;
    buzz(10);
    final data = DataProviderScope.of(context);
    final payload = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
      'priority': _priority,
      'category': _category,
      'dueDate': _dueDate,
      'dueTime': _dueTime,
      'reminder': _reminder,
      'recurrence': _recurrence,
      'repeatDays': _repeatDays,
    };
    if (widget.existing != null) {
      await data.updateTask(widget.existing!.id, payload);
    } else {
      await data.addTask(payload);
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    final data = DataProviderScope.of(context);
    await data.deleteTask(widget.existing!.id);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
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
              TextField(
                controller: _titleCtrl,
                autofocus: widget.existing == null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                  letterSpacing: -0.2,
                ),
                decoration: InputDecoration(
                  hintText: 'Task name',
                  hintStyle: TextStyle(color: c.ink3),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 14, color: c.ink2),
                decoration: InputDecoration(
                  hintText: 'Notes (optional)',
                  hintStyle: TextStyle(color: c.ink3),
                  filled: true,
                  fillColor: c.surface2,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('PRIORITY',
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
                  ('none', 'None', c.ink3),
                  ('low', 'Low', c.blue),
                  ('medium', 'Medium', c.amber),
                  ('high', 'High', c.red),
                ].map((e) {
                  final selected = _priority == e.$1;
                  return ChipButton(
                    label: e.$2,
                    color: switch (e.$1) {
                      'low' => 'blue',
                      'medium' => 'amber',
                      'high' => 'red',
                      _ => 'violet',
                    },
                    active: selected,
                    onTap: () => setState(() => _priority = e.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Text('CATEGORY',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: c.ink3,
                  )),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kTaskCategories.map((cat) {
                  return ChipButton(
                    label: cat,
                    color: 'violet',
                    active: _category == cat,
                    onTap: () => setState(() => _category = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _DateChip(
                      label: _dueDate == null
                          ? 'No date'
                          : _dueDate == AbidDates.todayStr()
                              ? 'Today'
                              : AbidDates.shortDate(AbidDates.parseD(_dueDate!)),
                      icon: LucideIcons.calendar,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _dueDate != null
                              ? AbidDates.parseD(_dueDate!)
                              : DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (d != null) {
                          setState(() => _dueDate = AbidDates.dateStr(d));
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateChip(
                      label: _dueTime ?? 'No time',
                      icon: LucideIcons.clock,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _dueTime != null
                              ? _parseTime(_dueTime!)
                              : TimeOfDay.now(),
                        );
                        if (t != null) {
                          setState(() => _dueTime =
                              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('RECURRENCE',
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
                  ('none', 'One-time'),
                  ('daily', 'Daily'),
                  ('weekly', 'Weekly'),
                  ('monthly', 'Monthly'),
                ].map((e) {
                  return ChipButton(
                    label: e.$2,
                    color: 'blue',
                    active: _recurrence == e.$1,
                    onTap: () => setState(() => _recurrence = e.$1),
                  );
                }).toList(),
              ),
              if (_recurrence == 'weekly') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (i) {
                    // i = 0..6 → Sun..Sat (web convention)
                    final selected = _repeatDays.contains(i);
                    final labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                    return GestureDetector(
                      onTap: () {
                        buzz(5);
                        setState(() {
                          if (selected) {
                            _repeatDays.remove(i);
                          } else {
                            _repeatDays.add(i);
                          }
                        });
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? c.tint('blue', 16) : c.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: selected ? c.blue : c.ink3,
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
                        'Reminder at due time',
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
                onPressed: _valid
                    ? () {
                        buzz(10);
                        _save();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: c.surface3,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  widget.existing == null ? 'Create task' : 'Save changes',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              if (widget.existing != null) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    ConfirmSheet.show(
                      context,
                      title: 'Delete this task?',
                      sub: '"${widget.existing!.title}" will be permanently removed.',
                      confirmLabel: 'Delete',
                      onConfirm: _delete,
                    );
                  },
                  icon: Icon(LucideIcons.trash2, size: 16, color: c.expense),
                  label: Text(
                    'Delete task',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: c.expense,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return GestureDetector(
      onTap: () {
        buzz(5);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.surface2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: c.ink2),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: c.ink2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
