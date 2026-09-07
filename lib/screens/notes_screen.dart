import 'dart:convert';

import 'package:abidlife/core/app_theme.dart';
import 'package:abidlife/core/formatters.dart';
import 'package:abidlife/models/models.dart';
import 'package:abidlife/providers/app_controller.dart';
import 'package:abidlife/screens/note_editor_screen.dart';
import 'package:abidlife/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  var _query = '';
  var _filter = 'All';
  var _archived = false;
  var _sort = 'Updated';

  List<NoteModel> _visible(List<NoteModel> notes) {
    final query = _query.trim().toLowerCase();
    final filtered = notes.where((note) {
      if (note.archived != _archived) return false;
      if (_filter == 'Pinned' && !note.pinned) return false;
      if (_filter == 'Locked' && !note.locked) return false;
      if (query.isEmpty) return true;
      return note.title.toLowerCase().contains(query) ||
          (!note.locked && _plainText(note.deltaJson).toLowerCase().contains(query)) ||
          (!note.locked && note.tags.any((tag) => tag.toLowerCase().contains(query)));
    }).toList();
    filtered.sort((a, b) {
      if (a.pinned != b.pinned && !_archived) return a.pinned ? -1 : 1;
      return switch (_sort) {
        'Created' => b.createdAt.compareTo(a.createdAt),
        'A–Z' => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        _ => b.updatedAt.compareTo(a.updatedAt),
      };
    });
    return filtered;
  }

  String _plainText(String delta) {
    if (delta.isEmpty) return '';
    try {
      final operations = jsonDecode(delta) as List<dynamic>;
      return operations
          .map((item) => (item as Map<String, dynamic>)['insert'])
          .whereType<String>()
          .join(' ')
          .replaceAll('\n', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    } on Object {
      return '';
    }
  }

  Future<void> _create({bool checklist = false}) async {
    final note = await ref.read(appControllerProvider).createNote(checklist: checklist);
    if (!mounted) return;
    await _openEditor(note);
  }

  Future<void> _open(NoteModel note) async {
    var open = note;
    if (note.locked && !note.sessionUnlocked) {
      final accepted = await showPinGate(
        context,
        title: 'Enter PIN',
        subtitle: note.title.isEmpty ? 'This note is private' : note.title,
        onSubmit: (pin) async {
          final unlocked = await ref.read(appControllerProvider).unlockNote(note.id, pin);
          if (unlocked != null) open = unlocked;
          return unlocked != null;
        },
      );
      if (accepted != true || !mounted) return;
    }
    await _openEditor(open);
  }

  Future<void> _openEditor(NoteModel note) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => NoteEditorScreen(noteId: note.id)),
    );
  }

  Future<void> _actionMenu(NoteModel note) async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Note actions'),
            ),
            ListTile(
              leading: Icon(note.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded),
              title: Text(note.pinned ? 'Unpin note' : 'Pin note'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await ref.read(appControllerProvider).updateNoteMeta(
                      note,
                      pinned: !note.pinned,
                    );
              },
            ),
            ListTile(
              leading: Icon(note.locked ? Icons.lock_open_rounded : Icons.lock_rounded),
              title: Text(note.locked ? 'Unlock note' : 'Lock with PIN'),
              onTap: () {
                Navigator.pop(sheetContext);
                note.locked ? _unlockFromMenu(note) : _lockFromMenu(note);
              },
            ),
            ListTile(
              leading: Icon(note.archived ? Icons.unarchive_rounded : Icons.archive_rounded),
              title: Text(note.archived ? 'Restore note' : 'Archive note'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await ref.read(appControllerProvider).updateNoteMeta(
                      note,
                      archived: !note.archived,
                    );
              },
            ),
            ListTile(
              textColor: AppColors.expense,
              iconColor: AppColors.expense,
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(sheetContext);
                _delete(note);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _lockFromMenu(NoteModel note) async {
    await showPinGate(
      context,
      title: 'Create a PIN',
      subtitle: 'Use 4 digits to protect this note',
      errorMessage: 'Choose a 4-digit PIN.',
      onSubmit: (pin) async {
        if (pin.length != 4) return false;
        await ref.read(appControllerProvider).lockNote(note, pin);
        return true;
      },
    );
  }

  Future<void> _unlockFromMenu(NoteModel note) async {
    NoteModel? unlocked;
    final accepted = await showPinGate(
      context,
      title: 'Enter PIN to unlock',
      subtitle: note.title.isEmpty ? 'Private note' : note.title,
      onSubmit: (pin) async {
        unlocked = await ref.read(appControllerProvider).unlockNote(note.id, pin);
        return unlocked != null;
      },
    );
    if (accepted == true && unlocked != null) {
      await ref.read(appControllerProvider).removeNoteLock(unlocked!);
    }
  }

  Future<void> _delete(NoteModel note) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete this note?',
      message: '“${note.title.isEmpty ? 'Untitled' : note.title}” will be permanently removed.',
    );
    if (confirmed) await ref.read(appControllerProvider).deleteNote(note.id);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final notes = _visible(app.notes);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: AppPageHeader(
          title: 'Notes',
          subtitle: '${app.notes.where((note) => !note.archived).length} notes · ${app.notes.where((note) => note.pinned && !note.archived).length} pinned',
          actions: <Widget>[
            IconButton.filledTonal(
              tooltip: 'Sort notes',
              onPressed: () => _showSort(),
              icon: const Icon(Icons.swap_vert_rounded),
            ),
            IconButton.filledTonal(
              tooltip: 'Search notes',
              onPressed: _showSearch,
              icon: const Icon(Icons.search_rounded),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: <Widget>[
                _chip('All'),
                _chip('Pinned'),
                _chip('Locked'),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _archived,
                  onSelected: (value) => setState(() => _archived = value),
                  avatar: const Icon(Icons.archive_outlined, size: 16),
                  label: const Text('Archived'),
                ),
              ],
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? EmptyState(
                    icon: _archived ? Icons.archive_outlined : Icons.sticky_note_2_outlined,
                    title: _archived ? 'No archived notes' : 'Nothing here yet',
                    message: _archived
                        ? 'Notes you archive will rest here, out of the way.'
                        : 'Capture an idea before you forget it.',
                    actionLabel: _archived ? null : 'Create note',
                    onAction: _archived ? null : _create,
                    color: AppColors.amber,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 720 ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 104),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: columns == 3 ? .96 : .82,
                        ),
                        itemCount: notes.length,
                        itemBuilder: (context, index) => _NoteCard(
                          note: notes[index],
                          preview: _plainText(notes[index].deltaJson),
                          onTap: () => _open(notes[index]),
                          onLongPress: () => _actionMenu(notes[index]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: SafeArea(
        minimum: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton(
          heroTag: 'notes_fab',
          tooltip: 'Create note',
          onPressed: _showCreateMenu,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
    );
  }

  Widget _chip(String label) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          selected: _filter == label && !_archived,
          onSelected: (_) => setState(() {
            _archived = false;
            _filter = label;
          }),
          label: Text(label),
        ),
      );

  Future<void> _showCreateMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.sticky_note_2_rounded, color: AppColors.amber),
              title: const Text('New note'),
              subtitle: const Text('A blank canvas for anything'),
              onTap: () {
                Navigator.pop(context);
                _create();
              },
            ),
            ListTile(
              leading: const Icon(Icons.checklist_rounded, color: AppColors.green),
              title: const Text('New checklist'),
              subtitle: const Text('A list you can tick off'),
              onTap: () {
                Navigator.pop(context);
                _create(checklist: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSort() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ListTile(title: Text('Sort by', style: TextStyle(fontWeight: FontWeight.w800))),
            for (final item in <String>['Updated', 'Created', 'A–Z'])
              RadioListTile<String>(
                value: item,
                groupValue: _sort,
                title: Text(item == 'Updated' ? 'Recently updated' : item == 'Created' ? 'Recently created' : 'Alphabetical'),
                onChanged: (value) => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (result != null) setState(() => _sort = result);
  }

  Future<void> _showSearch() async {
    final controller = TextEditingController(text: _query);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 6, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Search titles, content and tags',
            suffixIcon: IconButton(
              onPressed: () => controller.clear(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
      ),
    );
    controller.dispose();
    if (result != null) setState(() => _query = result);
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.preview,
    required this.onTap,
    required this.onLongPress,
  });

  final NoteModel note;
  final String preview;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: note.locked
          ? '${note.title.isEmpty ? 'Untitled' : note.title}, private note'
          : note.title,
      onLongPressHint: 'Show note actions',
      child: Material(
        color: AppColors.note(note.color, Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (note.pinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.push_pin_rounded, size: 14, color: AppColors.brand),
                      ),
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Untitled' : note.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (note.locked) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.lock_rounded, size: 13, color: AppColors.brand),
                        SizedBox(width: 5),
                        Text(
                          'Private note',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final width in <double>[1, .72, .88])
                    FractionallySizedBox(
                      widthFactor: width,
                      child: Container(
                        height: 8,
                        margin: const EdgeInsets.only(bottom: 9),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ] else
                  Expanded(
                    child: Text(
                      preview.isEmpty ? 'No content yet' : preview,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.55),
                    ),
                  ),
                const Spacer(),
                Row(
                  children: <Widget>[
                    if (!note.locked && note.tags.isNotEmpty)
                      Expanded(
                        child: Text(
                          '#${note.tags.first}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.blue,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    Text(
                      relativeDay(note.updatedAt),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
