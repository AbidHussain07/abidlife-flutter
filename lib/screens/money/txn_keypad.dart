import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/data_provider.dart';
import '../../data/data_provider_scope.dart';
import '../../data/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../../utils/date_utils.dart';

/// Transaction keypad — add or edit an income / expense.
///
/// Mirrors the web app's `TxnKeypad`: header with type toggle (expense /
/// income), big amount display, note input, horizontal category strip,
/// date quick-pick (Today / Yesterday / Pick…), numeric keypad, and a
/// Continue CTA that turns into an "Added ✓" success state.
class TxnKeypad extends StatefulWidget {
  const TxnKeypad({
    super.key,
    this.accountId,
    this.initialType = TxnType.expense,
    this.editTxn,
  });
  final String? accountId;
  final TxnType initialType;
  final Txn? editTxn;

  @override
  State<TxnKeypad> createState() => _TxnKeypadState();
}

class _TxnKeypadState extends State<TxnKeypad> {
  late TxnType _type;
  String _amount = '0';
  late final TextEditingController _noteCtrl;
  late String _category;
  late String _date;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editTxn;
    _type = e?.type ?? widget.initialType;
    if (e != null) {
      final r = e.amount / 100;
      _amount = r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(2);
    }
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _category = e?.category ?? 'Other';
    _date = e != null
        ? AbidDates.dateStr(e.occurredAt)
        : AbidDates.todayStr();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  int get _paise => (_parseAmount(_amount) * 100).round();
  bool get _valid => _paise > 0;

  double _parseAmount(String s) {
    if (s.isEmpty) return 0;
    return double.tryParse(s) ?? 0;
  }

  void _press(String k) {
    buzz(6);
    setState(() {
      if (k == 'back') {
        final next = _amount.substring(0, _amount.length - 1);
        _amount = next.isEmpty ? '0' : next;
        return;
      }
      if (k == '.') {
        if (_amount.contains('.')) return;
        _amount = '$_amount.';
        return;
      }
      final parts = _amount.split('.');
      final dec = parts.length > 1 ? parts[1] : null;
      if (dec != null && dec.length >= 2) return;
      if (parts[0].length >= 7) return;
      _amount = _amount == '0' ? k : '$_amount$k';
    });
  }

  String _displayInt() {
    final intPart = _amount.split('.').first;
    final n = int.tryParse(intPart.isEmpty ? '0' : intPart) ?? 0;
    return NumberFormat.decimalPattern('en_IN').format(n);
  }

  String _displayDec() {
    final parts = _amount.split('.');
    return parts.length > 1 ? '.${parts[1]}' : '';
  }

  Future<void> _save() async {
    if (!_valid || _saved) return;
    buzz(14);
    setState(() => _saved = true);
    try {
      final now = DateTime.now();
      DateTime occurredAt;
      if (_date == AbidDates.todayStr()) {
        occurredAt = now;
      } else {
        final d = AbidDates.parseD(_date);
        occurredAt = DateTime(d.year, d.month, d.day, now.hour, now.minute);
      }
      final payload = <String, dynamic>{
        'type': _type,
        'amount': _paise,
        'note': _noteCtrl.text.trim(),
        'category': _category,
        'occurredAt': occurredAt,
      };
      final data = DataProviderScope.of(context);
      if (widget.editTxn != null) {
        await data.updateTxn(widget.editTxn!.id, payload);
      } else {
        await data.addTxn({
          ...payload,
          'accountId': widget.accountId,
        });
      }
      await Future<void>.delayed(const Duration(milliseconds: 480));
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) setState(() => _saved = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final color = _type == TxnType.income ? c.income : c.expense;
    final title = widget.editTxn != null
        ? 'Edit transaction'
        : _type == TxnType.income
            ? 'Add income'
            : 'Add expense';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(LucideIcons.x, size: 20, color: c.ink2),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TypeButton(
                              label: '− Expense',
                              active: _type == TxnType.expense,
                              color: c.expense,
                              onTap: () {
                                buzz(6);
                                setState(() => _type = TxnType.expense);
                              },
                            ),
                            _TypeButton(
                              label: '+ Income',
                              active: _type == TxnType.income,
                              color: c.income,
                              onTap: () {
                                buzz(6);
                                setState(() => _type = TxnType.income);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Amount
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: c.ink3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '₹${_displayInt()}',
                          style: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: color,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        TextSpan(
                          text: _displayDec(),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: color,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_valid)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: MoneyText(
                        paise: _type == TxnType.income ? _paise : -_paise,
                        sign: true,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.ink3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Note
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _noteCtrl,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'What was this for?',
                  hintStyle: TextStyle(color: c.ink3),
                  filled: true,
                  fillColor: c.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.line),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Categories
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: kMoneyCategories.map((cat) {
                  final selected = _category == cat;
                  final icon = kCategoryIcons[cat]!;
                  return GestureDetector(
                    onTap: () {
                      buzz(5);
                      setState(() => _category = cat);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 56,
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected
                                  ? color.withValues(alpha: 0.14)
                                  : c.surface2,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected ? color : Colors.transparent,
                                width: 1.6,
                              ),
                            ),
                            child: Icon(icon,
                                size: 18,
                                color: selected ? color : c.ink3),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: selected ? color : c.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Date quick-picks
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _DateChip(
                    label: 'Today',
                    active: _date == AbidDates.todayStr(),
                    onTap: () {
                      buzz(5);
                      setState(() => _date = AbidDates.todayStr());
                    },
                    c: c,
                  ),
                  const SizedBox(width: 8),
                  _DateChip(
                    label: 'Yesterday',
                    active: _date ==
                        AbidDates.dateStr(DateTime.now().subtract(const Duration(days: 1))),
                    onTap: () {
                      buzz(5);
                      setState(() => _date = AbidDates.dateStr(
                          DateTime.now().subtract(const Duration(days: 1))));
                    },
                    c: c,
                  ),
                  const SizedBox(width: 8),
                  Builder(builder: (context) {
                    final isCustom = _date != AbidDates.todayStr() &&
                        _date !=
                            AbidDates.dateStr(DateTime.now().subtract(const Duration(days: 1)));
                    return _DateChip(
                      label: isCustom
                          ? AbidDates.shortDate(AbidDates.parseD(_date))
                          : 'Pick…',
                      active: isCustom,
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: AbidDates.parseD(_date),
                          firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) {
                          setState(() => _date = AbidDates.dateStr(d));
                        }
                      },
                      c: c,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Keypad
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 2.2,
                children: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'back']
                    .map((k) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _press(k),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        alignment: Alignment.center,
                        child: k == 'back'
                            ? Icon(LucideIcons.delete, size: 22, color: c.ink2)
                            : Text(
                                k,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: c.ink,
                                ),
                              ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _valid ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _saved ? c.green : color,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: c.surface3,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saved
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 19),
                            SizedBox(width: 8),
                            Text('Added',
                                style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800)),
                          ],
                        )
                      : const Text('Continue',
                          style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: active ? color : c.ink3,
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.active,
    required this.onTap,
    required this.c,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c.ink : c.surface2,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? c.bg : c.ink2,
          ),
        ),
      ),
    );
  }
}
