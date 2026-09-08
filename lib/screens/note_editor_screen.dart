import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:abidlife/core/app_theme.dart';
import 'package:abidlife/models/models.dart';
import 'package:abidlife/providers/app_controller.dart';
import 'package:abidlife/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({required this.noteId, super.key});
  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final QuillController _quillController;

  // Keep these alive for the entire editor screen.
  // This prevents the keyboard from losing focus during rebuilds.
  late final FocusNode _editorFocusNode;
  late final ScrollController _editorScrollController;

  Timer? _saveTimer;

  var _saving = false;
  var _closing = false;

  NoteModel get _note => ref.read(appControllerProvider).notes.firstWhere(
        (note) => note.id == widget.noteId,
      );

  @override
  void initState() {
    super.initState();
    _editorFocusNode = FocusNode();
    _editorScrollController = ScrollController();
    final note = ref.read(appControllerProvider).notes.firstWhere(
          (item) => item.id == widget.noteId,
        );
    _titleController = TextEditingController(text: note.title);
    Document document;
    try {
      document = Document.fromJson(jsonDecode(note.deltaJson) as List<dynamic>);
    } on Object {
      document = Document();
    }
    _quillController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _titleController.addListener(_scheduleSave);
    _quillController.addListener(_scheduleSave);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();

    // Only rebuild when saving actually starts.
    // Don't rebuild the entire editor on every keystroke.
    if (mounted && !_saving) {
      setState(() => _saving = true);
    }

    _saveTimer = Timer(const Duration(milliseconds: 650), _save);
  }


  Future<void> _save() async {
    if (_closing && !mounted) return;
    final updated = _note.copyWith(
      title: _titleController.text.trim(),
      deltaJson: jsonEncode(_quillController.document.toDelta().toJson()),
      updatedAt: DateTime.now(),
    );
    await ref.read(appControllerProvider).saveNote(updated);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _saveTimer?.cancel();
    await _save();
    final note = _note;
    if (note.locked) {
      await ref.read(appControllerProvider).relockNoteSession(note.id);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();

    _titleController.dispose();
    _quillController.dispose();

    _editorFocusNode.dispose();
    _editorScrollController.dispose();

    super.dispose();
  }


  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 92);
    if (picked == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final images = Directory(path.join(directory.path, 'note_images'));
    await images.create(recursive: true);
    final target = path.join(
      images.path,
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    String storedPath;
    final compressed = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      target,
      minWidth: 1280,
      minHeight: 1280,
      quality: 82,
      format: CompressFormat.jpeg,
    );
    if (compressed != null) {
      storedPath = compressed.path;
    } else {
      await picked.saveTo(target);
      storedPath = target;
    }
    final index = _quillController.selection.baseOffset.clamp(
      0,
      _quillController.document.length - 1,
    );
    _quillController.replaceText(
      index,
      0,
      BlockEmbed.image(storedPath),
      TextSelection.collapsed(offset: index + 1),
    );
    _scheduleSave();
  }

  Future<void> _imageMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.blue),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.teal),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _more() async {
    final note = _note;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Note color'),
              onTap: () {
                Navigator.pop(sheetContext);
                _chooseColor();
              },
            ),
            ListTile(
              leading: const Icon(Icons.tag_rounded),
              title: const Text('Tags'),
              subtitle: Text(note.tags.isEmpty ? 'Add tags to organize' : note.tags.map((tag) => '#$tag').join('  ')),
              onTap: () {
                Navigator.pop(sheetContext);
                _editTags();
              },
            ),
            ListTile(
              leading: Icon(note.locked ? Icons.lock_open_rounded : Icons.lock_rounded),
              title: Text(note.locked ? 'Remove lock' : 'Lock with PIN'),
              onTap: () {
                Navigator.pop(sheetContext);
                note.locked ? _removeLock(note) : _lock(note);
              },
            ),
            ListTile(
              leading: Icon(note.archived ? Icons.unarchive_rounded : Icons.archive_rounded),
              title: Text(note.archived ? 'Restore note' : 'Archive note'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await _save();
                await ref.read(appControllerProvider).updateNoteMeta(note, archived: !note.archived);
                if (mounted) await _close();
              },
            ),
            ListTile(
              textColor: AppColors.expense,
              iconColor: AppColors.expense,
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete note'),
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

  Future<void> _lock(NoteModel note) async {
    await _save();
    final latest = _note.copyWith(
      title: _titleController.text.trim(),
      deltaJson: jsonEncode(_quillController.document.toDelta().toJson()),
    );
    final result = await showPinGate(
      context,
      title: 'Create a PIN',
      subtitle: 'The body will be encrypted on this device',
      errorMessage: 'Choose a 4-digit PIN.',
      onSubmit: (pin) async {
        if (pin.length != 4) return false;
        await ref.read(appControllerProvider).lockNote(latest, pin);
        return true;
      },
    );
    if (result == true && mounted) Navigator.pop(context);
  }

  Future<void> _removeLock(NoteModel note) async {
    await ref.read(appControllerProvider).removeNoteLock(note);
    if (mounted) showMessage(context, 'Note unlocked');
  }

  Future<void> _delete(NoteModel note) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete this note?',
      message: 'This cannot be undone.',
    );
    if (!confirmed) return;
    await ref.read(appControllerProvider).deleteNote(note.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _chooseColor() async {
    final colors = <String>['default', 'blue', 'purple', 'green', 'yellow', 'pink'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: colors
                .map(
                  (name) => InkWell(
                    onTap: () => Navigator.pop(context, name),
                    borderRadius: BorderRadius.circular(40),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.note(name, Theme.of(context).brightness),
                      child: _note.color == name ? const Icon(Icons.check_rounded) : null,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (selected != null) {
      await ref.read(appControllerProvider).updateNoteMeta(_note, color: selected);
      if (mounted) setState(() {});
    }
  }

  Future<void> _editTags() async {
    final controller = TextEditingController(text: _note.tags.join(', '));
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tags'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'ideas, work, private'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (value != null) {
      final tags = value
          .split(',')
          .map((tag) => tag.trim().toLowerCase())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList();
      await ref.read(appControllerProvider).updateNoteMeta(_note, tags: tags);
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = ref.watch(appControllerProvider).notes.firstWhere(
          (item) => item.id == widget.noteId,
        );
    final background = AppColors.note(note.color, Theme.of(context).brightness);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _close,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              _saving ? 'Saving…' : 'Saved',
              key: ValueKey(_saving),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: _saving ? AppColors.amber : AppColors.green,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              tooltip: note.pinned ? 'Unpin' : 'Pin',
              onPressed: () => ref.read(appControllerProvider).updateNoteMeta(note, pinned: !note.pinned),
              icon: Icon(note.pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
            ),
            IconButton(tooltip: 'More', onPressed: _more, icon: const Icon(Icons.more_horiz_rounded)),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              TextField(
                controller: _titleController,
                maxLines: 2,
                style: Theme.of(context).textTheme.headlineMedium,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                ),
              ),
              SizedBox(
                height: 54,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: QuillSimpleToolbar(
                        controller: _quillController,
                        config: const QuillSimpleToolbarConfig(
                          multiRowsDisplay: false,
                          showFontFamily: false,
                          showFontSize: false,
                          showColorButton: false,
                          showBackgroundColorButton: false,
                          showInlineCode: false,
                          showCodeBlock: false,
                          showQuote: false,
                          showIndent: false,
                          showLink: false,
                          showSearchButton: false,
                          showClearFormat: false,
                          showUndo: true,
                          showRedo: true,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add image',
                      onPressed: _imageMenu,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
              Expanded(
                child: QuillEditor.basic(
                  controller: _quillController,
                  focusNode: _editorFocusNode,
                  scrollController: _editorScrollController,
                  config: QuillEditorConfig(
                    placeholder: 'Start writing…',
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 80),
                    expands: true,
                    scrollable: true,
                    embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
