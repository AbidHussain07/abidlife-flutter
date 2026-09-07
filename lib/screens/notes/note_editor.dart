import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/data_provider.dart';
import '../../data/data_provider_scope.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../../utils/date_utils.dart';

/// Markdown note editor with toolbar.
///
/// Mirrors the web app's `NoteEditor` — a full-screen editor with:
/// - Title field
/// - Body field (markdown syntax — rendered live)
/// - Toolbar: Bold, Italic, Heading, Bullet list, Numbered list, Checklist, Image
/// - Header: back / pin / more
/// - More sheet: pin, tags, color, lock with PIN, archive, delete
/// - Autosave (debounced 700ms)
///
/// The web app used `contentEditable` with HTML. For Flutter we use markdown
/// — simpler, more reliable, and renders cleanly with `flutter_markdown`.
class NoteEditor extends StatefulWidget {
  const NoteEditor({super.key, required this.noteId});
  final String noteId;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final FocusNode _titleFocus;
  late final FocusNode _bodyFocus;
  bool _saving = false;
  bool _saved = true;
  bool _preview = false;

  Timer? _saveTimer;

  Note? get _note {
    final data = DataProviderScope.of(context);
    for (final n in data.notes) {
      if (n.id == widget.noteId) return n;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _titleFocus = FocusNode();
    _bodyFocus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  void _hydrate() {
    final n = _note;
    _titleCtrl.text = n.title;
    _bodyCtrl.text = n.content;
    _saved = true;
    setState(() {});
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _titleFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  void _persist({bool immediate = false}) {
    if (_note == null) return;
    setState(() {
      _saving = true;
      _saved = false;
    });
    _saveTimer?.cancel();
    final run = () async {
      final data = DataProviderScope.of(context);
      await data.updateNote(widget.noteId, {
        'title': _titleCtrl.text,
        'content': _bodyCtrl.text,
      });
      if (mounted) setState(() => _saving = false);
    };
    if (immediate) {
      run();
    } else {
      _saveTimer = Timer(const Duration(milliseconds: 700), run);
    }
    // Mark saved slightly after to debounce the UI flicker.
    Timer(const Duration(milliseconds: 750), () {
      if (mounted && !_saving) {
        setState(() => _saved = true);
      }
    });
  }

  void _wrapSelection(String prefix, [String? suffix]) {
    final s = suffix ?? prefix;
    final sel = _bodyCtrl.selection;
    final text = _bodyCtrl.text;
    if (!sel.isValid || sel.start == sel.end) {
      // No selection: just insert the marker pair and place cursor in middle.
      final pos = sel.baseOffset;
      final newText =
          '${text.substring(0, pos)}$prefix$s${text.substring(pos)}';
      _bodyCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + prefix.length),
      );
    } else {
      final start = sel.start;
      final end = sel.end;
      final selected = text.substring(start, end);
      final newText =
          '${text.substring(0, start)}$prefix$selected$s${text.substring(end)}';
      _bodyCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: start + prefix.length,
          extentOffset: end + prefix.length,
        ),
      );
    }
    _persist();
  }

  void _prefixLines(String prefix) {
    final sel = _bodyCtrl.selection;
    final text = _bodyCtrl.text;
    if (!sel.isValid) return;
    // Find line start.
    var lineStart = sel.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    final newText =
        '${text.substring(0, lineStart)}$prefix${text.substring(lineStart)}';
    _bodyCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + prefix.length),
    );
    _persist();
  }

  Future<void> _insertImage({bool camera = false}) async {
    final picker = ImagePicker();
    try {
      final x = await picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 82,
      );
      if (x == null) return;
      final data = DataProviderScope.of(context);
      // Embed as a markdown image with the file path.
      final md = '![image](${x.path})\n';
      final sel = _bodyCtrl.selection;
      final text = _bodyCtrl.text;
      final pos = sel.baseOffset;
      final newText = '${text.substring(0, pos)}$md${text.substring(pos)}';
      _bodyCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + md.length),
      );
      _persist(immediate: true);
      data.toast('Image added');
    } catch (e) {
      DataProviderScope.of(context).toast("Couldn't add this image. Try another.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final note = _note;
    if (note == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bg = noteColor(note.color, Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            _persist(immediate: true);
            Navigator.of(context).maybePop();
          },
          icon: Icon(LucideIcons.chevronLeft, size: 22, color: c.ink2),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _saving ? c.amber : c.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _saving ? 'SAVING…' : 'SAVED',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: c.ink3,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              buzz(6);
              DataProviderScope.of(context).updateNote(note.id, {
                'pinned': !note.pinned,
              });
            },
            icon: Icon(
              LucideIcons.pin,
              size: 19,
              color: note.pinned ? c.brand : c.ink3,
            ),
          ),
          IconButton(
            onPressed: _preview
                ? () {
                    buzz(5);
                    setState(() => _preview = false);
                  }
                : () {
                    buzz(5);
                    setState(() => _preview = true);
                  },
            icon: Icon(
              _preview ? LucideIcons.edit : LucideIcons.eye,
              size: 18,
              color: c.ink3,
            ),
          ),
          IconButton(
            onPressed: () => _showMore(context, note),
            icon: Icon(LucideIcons.moreHorizontal, size: 20, color: c.ink2),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_preview) ...[
              // Toolbar
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _Tool(icon: LucideIcons.bold, label: 'Bold', onTap: () => _wrapSelection('**')),
                    _Tool(icon: LucideIcons.italic, label: 'Italic', onTap: () => _wrapSelection('*')),
                    _Tool(icon: LucideIcons.heading, label: 'Heading', onTap: () => _prefixLines('## ')),
                    _Tool(icon: LucideIcons.list, label: 'Bullet list', onTap: () => _prefixLines('- ')),
                    _Tool(icon: LucideIcons.listOrdered, label: 'Numbered list', onTap: () => _prefixLines('1. ')),
                    _Tool(icon: LucideIcons.listChecks, label: 'Checklist', onTap: () => _prefixLines('- [ ] ')),
                    _Tool(icon: LucideIcons.imagePlus, label: 'Add image', onTap: () => _showImageMenu(context)),
                  ],
                ),
              ),
              Divider(height: 1, color: c.line),
            ],
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  TextField(
                    controller: _titleCtrl,
                    focusNode: _titleFocus,
                    onChanged: (_) => _persist(),
                    onSubmitted: (_) => _bodyFocus.requestFocus(),
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: c.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      hintStyle: TextStyle(color: c.ink3),
                      border: InputBorder.none,
                    ),
                  ),
                  if (_preview)
                    MarkdownBody(
                      data: _bodyCtrl.text.isEmpty ? 'Nothing to preview yet.' : _bodyCtrl.text,
                      extensionSet: ExtensionSet.gitHubWeb,
                      imageBuilder: (uri, title, alt) {
                        if (uri.scheme == 'file' || uri.path.startsWith('/')) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(File(uri.path)),
                          );
                        }
                        return Image.network(uri.toString());
                      },
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontSize: 15, height: 1.7, color: c.ink2),
                        h2: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink),
                        listBullet: TextStyle(color: c.ink3),
                        code: TextStyle(
                          backgroundColor: c.surface2,
                          color: c.brand,
                          fontSize: 13,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: c.brand, width: 3)),
                        ),
                      ),
                    )
                  else
                    TextField(
                      controller: _bodyCtrl,
                      focusNode: _bodyFocus,
                      onChanged: (_) => _persist(),
                      maxLines: null,
                      minLines: 20,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: c.ink2,
                      ),
                      decoration: InputDecoration(
                        hintText: note.checklist
                            ? '- [ ] First item\n- [ ] Second item'
                            : 'Start writing…',
                        hintStyle: TextStyle(color: c.ink3),
                        border: InputBorder.none,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Edited ${AbidDates.shortDate(note.updatedAt)} · ${AbidDates.time(note.updatedAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.ink3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMore(BuildContext context, Note note) {
    final c = AppTheme.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _MoreSheet(note: note, onPickColor: (color) {
        DataProviderScope.of(context).updateNote(note.id, {'color': color});
      }),
    );
  }

  void _showImageMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Text(
                  'Add an image',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
              RowButton(
                icon: LucideIcons.image,
                color: 'blue',
                label: 'Choose from gallery',
                sub: 'Pick an existing photo',
                onTap: () {
                  Navigator.of(context).maybePop();
                  _insertImage(camera: false);
                },
              ),
              RowButton(
                icon: LucideIcons.camera,
                color: 'teal',
                label: 'Take a photo',
                sub: 'Opens the camera',
                onTap: () {
                  Navigator.of(context).maybePop();
                  _insertImage(camera: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return IconButton(
      onPressed: () {
        buzz(5);
        onTap();
      },
      icon: Icon(icon, size: 17, color: c.ink2),
      tooltip: label,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _MoreSheet extends StatelessWidget {
  const _MoreSheet({required this.note, required this.onPickColor});
  final Note note;
  final ValueChanged<String> onPickColor;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final data = DataProviderScope.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RowButton(
              icon: LucideIcons.pin,
              color: 'violet',
              label: note.pinned ? 'Unpin note' : 'Pin note',
              sub: 'Pinned notes stay on top',
              onTap: () {
                Navigator.of(context).maybePop();
                data.updateNote(note.id, {'pinned': !note.pinned});
              },
            ),
            RowButton(
              icon: LucideIcons.hash,
              color: 'blue',
              label: 'Tags',
              sub: note.tags.isEmpty
                  ? 'Add tags to organize'
                  : note.tags.map((t) => '#$t').join('  '),
              onTap: () {
                Navigator.of(context).maybePop();
                _showTagsSheet(context, note);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COLOR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: c.ink3,
                      )),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: kNoteColors.map((color) {
                      final selected = note.color == color;
                      return GestureDetector(
                        onTap: () {
                          buzz(6);
                          onPickColor(color);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: noteColor(color, Theme.of(context).brightness),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? c.brand : c.line,
                              width: selected ? 2.5 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            RowButton(
              icon: note.locked ? LucideIcons.lockOpen : LucideIcons.lock,
              color: 'pink',
              label: note.locked ? 'Remove lock' : 'Lock with PIN',
              sub: note.locked ? 'Anyone can open this note' : 'Hide this note behind a PIN',
              onTap: () {
                Navigator.of(context).maybePop();
                if (note.locked) {
                  data.updateNote(note.id, {'lock': false}).then((_) {
                    data.toast('Lock removed');
                  });
                } else {
                  _promptCreatePin(context, note);
                }
              },
            ),
            RowButton(
              icon: note.archived ? LucideIcons.archiveRestore : LucideIcons.archive,
              color: 'teal',
              label: note.archived ? 'Restore note' : 'Archive note',
              sub: 'Archived notes hide from your grid',
              onTap: () {
                Navigator.of(context).maybePop();
                data.updateNote(note.id, {'archived': !note.archived}).then((_) {
                  data.toast(note.archived ? 'Note restored' : 'Note archived');
                  if (!note.archived) Navigator.of(context).maybePop();
                });
              },
            ),
            RowButton(
              icon: LucideIcons.trash2,
              color: 'red',
              label: 'Delete note',
              sub: "This can't be undone",
              danger: true,
              onTap: () {
                Navigator.of(context).maybePop();
                ConfirmSheet.show(
                  context,
                  title: 'Delete this note?',
                  sub: '"${note.title.isEmpty ? 'Untitled' : note.title}" will be permanently removed.',
                  confirmLabel: 'Delete',
                  onConfirm: () {
                    data.deleteNote(note.id);
                    Navigator.of(context).maybePop();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTagsSheet(BuildContext context, Note note) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _TagsSheet(note: note),
    );
  }

  void _promptCreatePin(BuildContext context, Note note) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => PinPad(
        title: 'Create a PIN',
        sub: '4 digits — needed to open this note',
        onCancel: () => Navigator.of(context).maybePop(),
        onComplete: (pin) async {
          await DataProviderScope.of(context)
              .updateNote(note.id, {'lock': true, 'pin': pin});
          DataProviderScope.of(context).toast('Note locked');
          if (Navigator.of(context).canPop()) Navigator.of(context).maybePop();
          if (Navigator.of(context).canPop()) Navigator.of(context).maybePop();
        },
      ),
    );
  }
}

class _TagsSheet extends StatefulWidget {
  const _TagsSheet({required this.note});
  final Note note;

  @override
  State<_TagsSheet> createState() => _TagsSheetState();
}

class _TagsSheetState extends State<_TagsSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final data = DataProviderScope.of(context);
    return SafeArea(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tags',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.note.tags.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.tint('blue', 13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$t',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: c.blue,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          buzz(5);
                          data.updateNote(widget.note.id, {
                            'tags': widget.note.tags.where((x) => x != t).toList(),
                          });
                        },
                        child: Icon(LucideIcons.x, size: 13, color: c.blue),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (widget.note.tags.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('No tags yet.',
                    style: TextStyle(color: c.ink3, fontSize: 13)),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Add a tag and press enter',
                hintStyle: TextStyle(color: c.ink3, fontSize: 14),
                filled: true,
                fillColor: c.surface2,
                prefixIcon: Icon(LucideIcons.hash, size: 16, color: c.ink3),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) {
                final t = v.trim().toLowerCase().replaceAll(RegExp(r'\s'), '');
                if (t.isEmpty) return;
                if (widget.note.tags.contains(t)) {
                  _ctrl.clear();
                  return;
                }
                data.updateNote(widget.note.id, {
                  'tags': [...widget.note.tags, t],
                });
                _ctrl.clear();
              },
            ),
          ],
        ),
      ),
    );
  }
}
