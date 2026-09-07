import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/data_provider.dart';
import '../../data/data_provider_scope.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../../utils/date_utils.dart';
import 'task_editor.dart';

/// Tasks screen — a single flat list grouped by status.
///
/// Mirrors the web app's `TasksScreen`: today / upcoming / completed
/// sections, a swipeable "create task" sheet, tap-to-toggle, swipe-to-delete,
/// tap-to-edit. Supports the cross-module `requestQuick(Tab.tasks, 'new')`
/// handshake so the Insights quick-action opens the editor.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = DataProviderScope.of(context);
    if (data.quick?.tab == Tab.tasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openEditor();
        data.consumeQuick();
      });
    }
  }

  Future<void> _openEditor([Task? existing]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => TaskEditor(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = DataProviderScope.of(context);
    final c = AppTheme.of(context);
    final today = AbidDates.todayStr();

    final open = data.tasks.where((t) => !t.done).toList();
    final done = data.tasks.where((t) => t.done).toList();
    final dueToday = open.where((t) => t.dueDate != null && t.dueDate!.compareTo(today) <= 0).toList();
    final upcoming = open.where((t) => t.dueDate == null || t.dueDate!.compareTo(today) > 0).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.tasks.isEmpty
                          ? 'Your tasks'
                          : '${dueToday.length} due today · ${open.length} open',
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
                onPressed: () => _openEditor(),
                icon: Icon(LucideIcons.plus, size: 22, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: c.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(44, 44),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: data.tasks.isEmpty
              ? EmptyState(
                  icon: LucideIcons.checkCircle2,
                  color: 'blue',
                  title: 'Add your first task',
                  sub: 'Track what to do — with priorities, due dates, reminders and repeats.',
                  action: 'New task',
                  onAction: () => _openEditor(),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 140 + MediaQuery.viewPaddingOf(context).bottom),
                  children: [
                    if (dueToday.isNotEmpty) ...[
                      SectionLabel('TODAY'),
                      ...dueToday.map((t) => _TaskTile(
                            task: t,
                            onToggle: () => data.toggleTask(t.id),
                            onEdit: () => _openEditor(t),
                            onDelete: () => ConfirmSheet.show(
                              context,
                              title: 'Delete this task?',
                              sub: '"${t.title}" will be permanently removed.',
                              confirmLabel: 'Delete',
                              onConfirm: () => data.deleteTask(t.id),
                            ),
                          )),
                      const SizedBox(height: 12),
                    ],
                    if (upcoming.isNotEmpty) ...[
                      SectionLabel('UPCOMING'),
                      ...upcoming.map((t) => _TaskTile(
                            task: t,
                            onToggle: () => data.toggleTask(t.id),
                            onEdit: () => _openEditor(t),
                            onDelete: () => ConfirmSheet.show(
                              context,
                              title: 'Delete this task?',
                              sub: '"${t.title}" will be permanently removed.',
                              confirmLabel: 'Delete',
                              onConfirm: () => data.deleteTask(t.id),
                            ),
                          )),
                      const SizedBox(height: 12),
                    ],
                    if (done.isNotEmpty) ...[
                      SectionLabel('COMPLETED'),
                      ...done.map((t) => _TaskTile(
                            task: t,
                            onToggle: () => data.toggleTask(t.id),
                            onEdit: () => _openEditor(t),
                            onDelete: () => ConfirmSheet.show(
                              context,
                              title: 'Delete this task?',
                              sub: '"${t.title}" will be permanently removed.',
                              confirmLabel: 'Delete',
                              onConfirm: () => data.deleteTask(t.id),
                            ),
                          )),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final dueLabel = task.dueDate == null
        ? null
        : task.dueDate == AbidDates.todayStr()
            ? 'Today'
            : AbidDates.shortDate(AbidDates.parseD(task.dueDate!));
    final overdue = task.dueDate != null &&
        task.dueDate!.compareTo(AbidDates.todayStr()) < 0 &&
        !task.done;

    final priorityColor = switch (task.priority) {
      'high' => c.red,
      'medium' => c.amber,
      'low' => c.blue,
      _ => c.ink3,
    };

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: c.expense.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(LucideIcons.trash2, color: c.expense, size: 20),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              buzz(5);
              onEdit();
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      buzz(task.done ? 6 : 14);
                      onToggle();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: task.done ? c.green : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: task.done ? c.green : c.surface3,
                          width: 2,
                        ),
                      ),
                      child: task.done
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (task.priority != 'none') ...[
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: priorityColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                task.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: task.done ? c.ink3 : c.ink,
                                  decoration:
                                      task.done ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (dueLabel != null)
                              _Meta(
                                icon: LucideIcons.calendar,
                                text: dueLabel,
                                color: overdue ? c.expense : c.ink3,
                              ),
                            if (task.dueTime != null)
                              _Meta(
                                icon: LucideIcons.clock,
                                text: task.dueTime!,
                                color: c.ink3,
                              ),
                            if (task.reminder)
                              _Meta(
                                icon: LucideIcons.bell,
                                text: 'Reminder',
                                color: c.amber,
                              ),
                            if (task.recurrence != 'none')
                              _Meta(
                                icon: LucideIcons.repeat,
                                text: task.recurrence,
                                color: c.ink3,
                              ),
                            _Meta(
                              icon: LucideIcons.folder,
                              text: task.category,
                              color: c.ink3,
                            ),
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
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10.5, color: color),
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
