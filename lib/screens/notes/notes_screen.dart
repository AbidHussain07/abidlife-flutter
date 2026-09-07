import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/data_provider.dart';
import '../../data/data_provider_scope.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../../utils/date_utils.dart';
import 'note_editor.dart';

/// Notes grid screen.
///
/// Mirrors the web app's `NotesScreen`: masonry-style grid of cards grouped
/// by pinned / others / archived, with a search field, a "New note" FAB,
/// and tap-to-open behavior. Locked notes show only their title; opening
/// them prompts for the PIN.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _query = '';
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = DataProviderScope.of(context);
    if (data.quick?.tab == Tab.notes) {
      final action = data.quick!.action;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (action == 'search') {
          setState(() => _searching = true);
        } else if (action == 'new') {
          _createNote();
        }
        data.consumeQuick();
      });
    }
  }

  Future<void> _createNote({bool checklist = false}) async {
    final data = DataProviderScope.of(context);
    final note = await data.addNote(checklist: checklist);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditor(noteId: note.id),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _openNote(Note note) async {
    final data = DataProviderScope.of(context);
    if (note.locked) {
      // PIN prompt
      final ok = await _promptPin(note);
      if (!ok) {
        data.toast("Wrong PIN");
        return;
      }
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NoteEditor(noteId: note.id),
        fullscreenDialog: true,
      ),
    );
  }

  Future<bool> _promptPin(Note note) async {
    final data = DataProviderScope.of(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => PinPad(
        title: 'Unlock note',
        sub: 'Enter the 4-digit PIN for this note',
        onCancel: () => Navigator.of(context).maybePop(),
        onComplete: (pin) async {
          final ok = await data.verifyUnlock(note.id, pin);
          if (ok) {
            Navigator.of(context).pop(pin);
          } else {
            Navigator.of(context).pop('');
          }
        },
      ),
    );
    return result != null && result.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final data = DataProviderScope.of(context);
    final c = AppTheme.of(context);

    final live = data.notes.where((n) => !n.archived).toList();
    final filtered = _query.isEmpty
        ? live
        : live
            .where((n) =>
                n.title.toLowerCase().contains(_query.toLowerCase()) ||
                n.tags.any((t) => t.toLowerCase().contains(_query.toLowerCase())))
            .toList();

    final pinned = filtered.where((n) => n.pinned).toList();
    final others = filtered.where((n) => !n.pinned).toList();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: c.ink,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  buzz(6);
                  setState(() => _searching = !_searching);
                  if (!_searching) {
                    _searchController.clear();
                    _query = '';
                  }
                },
                icon: Icon(_searching ? LucideIcons.x : LucideIcons.search,
                    size: 20, color: c.ink2),
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
        if (_searching)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by title or #tag…',
                hintStyle: TextStyle(color: c.ink3, fontSize: 14),
                filled: true,
                fillColor: c.surface2,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        Expanded(
          child: live.isEmpty
              ? EmptyState(
                  icon: LucideIcons.notebookPen,
                  color: 'amber',
                  title: 'Capture your first note',
                  sub: 'Ideas, lists, journals — all in one place, with rich text and images.',
                  action: 'New note',
                  onAction: () => _createNote(),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 140 + MediaQuery.viewPaddingOf(context).bottom),
                  children: [
                    if (pinned.isNotEmpty) ...[
                      SectionLabel('PINNED'),
                      _Masonry(notes: pinned, onTap: _openNote),
                      const SizedBox(height: 12),
                    ],
                    if (others.isNotEmpty) ...[
                      if (pinned.isNotEmpty) SectionLabel('OTHERS'),
                      _Masonry(notes: others, onTap: _openNote),
                    ],
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'No notes match "$_query".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.ink3, fontSize: 13),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Masonry extends StatelessWidget {
  const _Masonry({required this.notes, required this.onTap});
  final List<Note> notes;
  final ValueChanged<Note> onTap;

  @override
  Widget build(BuildContext context) {
    // Two-column masonry via staggered column split.
    final left = <Note>[];
    final right = <Note>[];
    for (var i = 0; i < notes.length; i++) {
      (i.isEven ? left : right).add(notes[i]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left.map((n) => _NoteCard(note: n, onTap: onTap)).toList())),
        const SizedBox(width: 10),
        Expanded(child: Column(children: right.map((n) => _NoteCard(note: n, onTap: onTap)).toList())),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap});
  final Note note;
  final ValueChanged<Note> onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final bg = noteColor(note.color, Theme.of(context).brightness);
    final body = note.locked ? 'Private note — tap to unlock' : note.content;
    return GestureDetector(
      onTap: () {
        buzz(5);
        onTap(note);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (note.pinned)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(LucideIcons.pin, size: 12, color: c.brand),
                  ),
                if (note.locked)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(LucideIcons.lock, size: 12, color: c.ink3),
                  ),
                Expanded(
                  child: Text(
                    note.locked ? 'Private note' : (note.title.isEmpty ? 'Untitled' : note.title),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            if (!note.locked && body.isNotEmpty) ...[
              const SizedBox(height: 6),
              MarkdownBody(
                data: body,
                shrinkWrap: true,
                fitContent: false,
                selectable: false,
                extensionSet: ExtensionSet.commonMark,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: c.ink2,
                  ),
                  h2: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                  listBullet: TextStyle(color: c.ink3),
                  code: TextStyle(color: c.brand),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (note.tags.isNotEmpty)
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: note.tags
                          .map((t) => Text(
                                '#$t',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: c.blue,
                                ),
                              ))
                          .toList(),
                    ),
                  )
                else
                  const Spacer(),
                Text(
                  AbidDates.shortDate(note.updatedAt),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: c.ink3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
