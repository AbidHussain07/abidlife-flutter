import 'package:abidlife/core/app_theme.dart';
import 'package:abidlife/core/formatters.dart';
import 'package:abidlife/models/models.dart';
import 'package:abidlife/providers/app_controller.dart';
import 'package:abidlife/widgets/app_icons.dart';
import 'package:abidlife/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionEditorScreen extends ConsumerStatefulWidget {
  const TransactionEditorScreen({
    required this.account,
    required this.initialType,
    this.existing,
    super.key,
  });

  final MoneyAccountModel account;
  final TransactionType initialType;
  final MoneyTransactionModel? existing;

  @override
  ConsumerState<TransactionEditorScreen> createState() => _TransactionEditorScreenState();
}

class _TransactionEditorScreenState extends ConsumerState<TransactionEditorScreen> {
  late TransactionType _type;
  late String _amount;
  late final TextEditingController _note;
  late String _category;
  late DateTime _date;
  var _saving = false;

  static const _keys = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'back'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? widget.initialType;
    final amount = (existing?.amountPaise ?? 0) / 100;
    _amount = amount == 0
        ? '0'
        : amount == amount.roundToDouble()
            ? amount.toInt().toString()
            : amount.toStringAsFixed(2);
    _note = TextEditingController(text: existing?.note ?? '');
    _category = existing?.category ?? 'Other';
    _date = existing?.occurredAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _paise => ((double.tryParse(_amount) ?? 0) * 100).round();

  void _press(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == 'back') {
        _amount = _amount.length <= 1 ? '0' : _amount.substring(0, _amount.length - 1);
        return;
      }
      if (key == '.') {
        if (!_amount.contains('.')) _amount += '.';
        return;
      }
      final parts = _amount.split('.');
      if (parts.length == 2 && parts.last.length >= 2) return;
      if (parts.first.length >= 7 && parts.length == 1) return;
      _amount = _amount == '0' ? key : '$_amount$key';
    });
  }

  Future<void> _save() async {
    if (_paise <= 0 || _saving) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final occurred = DateTime(
      _date.year,
      _date.month,
      _date.day,
      widget.existing?.occurredAt.hour ?? now.hour,
      widget.existing?.occurredAt.minute ?? now.minute,
    );
    try {
      await ref.read(appControllerProvider).saveTransaction(
            id: widget.existing?.id,
            accountId: widget.account.id,
            type: _type,
            amountPaise: _paise,
            note: _note.text,
            category: _category,
            occurredAt: occurred,
            createdAt: widget.existing?.createdAt,
          );
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, 'Unable to save this transaction. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final color = _type == TransactionType.income ? AppColors.income : AppColors.expense;
    final number = _amount.endsWith('.') ? '${_amount}0' : _amount;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add transaction' : 'Edit transaction'),
        actions: <Widget>[
          if (widget.existing != null)
            IconButton(
              tooltip: 'Delete transaction',
              color: AppColors.expense,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
              child: IntrinsicHeight(
                child: Column(
                  children: <Widget>[
                    SegmentedButton<TransactionType>(
                      segments: const <ButtonSegment<TransactionType>>[
                        ButtonSegment(value: TransactionType.expense, label: Text('− Expense')),
                        ButtonSegment(value: TransactionType.income, label: Text('+ Income')),
                      ],
                      selected: <TransactionType>{_type},
                      onSelectionChanged: (value) => setState(() => _type = value.first),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '₹${_groupIndian(number)}',
                      style: TextStyle(
                        color: color,
                        fontSize: keyboardOpen ? 34 : 46,
                        height: 1,
                        letterSpacing: -1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _note,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _save(),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.edit_note_rounded),
                        hintText: 'What was this for?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 69,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: moneyCategories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = moneyCategories[index];
                          final selected = _category == category;
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setState(() => _category = category),
                            child: Container(
                              width: 64,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? color.withValues(alpha: .12)
                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: selected ? Border.all(color: color) : null,
                              ),
                              child: Column(
                                children: <Widget>[
                                  Icon(categoryIcons[category], size: 20, color: selected ? color : null),
                                  const SizedBox(height: 3),
                                  Text(category, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        ChoiceChip(
                          selected: sameDay(_date, DateTime.now()),
                          label: const Text('Today'),
                          onSelected: (_) => setState(() => _date = DateTime.now()),
                        ),
                        ChoiceChip(
                          selected: sameDay(_date, DateTime.now().subtract(const Duration(days: 1))),
                          label: const Text('Yesterday'),
                          onSelected: (_) => setState(() => _date = DateTime.now().subtract(const Duration(days: 1))),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.calendar_today_rounded, size: 15),
                          label: Text(
                            sameDay(_date, DateTime.now()) ||
                                    sameDay(_date, DateTime.now().subtract(const Duration(days: 1)))
                                ? 'Pick date'
                                : relativeDay(_date),
                          ),
                          onPressed: _pickDate,
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!keyboardOpen) ...<Widget>[
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.15,
                        mainAxisSpacing: 3,
                        crossAxisSpacing: 3,
                        children: _keys
                            .map(
                              (key) => InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _press(key),
                                child: Center(
                                  child: key == 'back'
                                      ? const Icon(Icons.backspace_outlined)
                                      : Text(key, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: color),
                        onPressed: _paise > 0 && !_saving ? _save : null,
                        icon: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.arrow_forward_rounded),
                        iconAlignment: IconAlignment.end,
                        label: Text(_saving ? 'Saving…' : 'Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _groupIndian(String value) {
    final parts = value.split('.');
    var whole = parts.first;
    if (whole.length > 3) {
      final last = whole.substring(whole.length - 3);
      var rest = whole.substring(0, whole.length - 3);
      final groups = <String>[];
      while (rest.length > 2) {
        groups.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) groups.insert(0, rest);
      whole = '${groups.join(',')},$last';
    }
    return parts.length == 2 ? '$whole.${parts.last}' : whole;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _delete() async {
    final transaction = widget.existing;
    if (transaction == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Delete this transaction?',
      message: '${formatMoney(transaction.amountPaise)} will be removed from ${widget.account.name}.',
    );
    if (!confirmed) return;
    await ref.read(appControllerProvider).deleteTransaction(transaction.id);
    if (mounted) Navigator.pop(context);
  }
}
