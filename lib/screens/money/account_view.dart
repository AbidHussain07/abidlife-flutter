import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/data_provider.dart';
import '../../data/data_provider_scope.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../../utils/date_utils.dart';

/// Per-account dashboard.
///
/// Mirrors the web app's `AccountView` — header (back + icon + name +
/// edit), hero balance card with income/expense CTAs, mini stats
/// (this-month income/expense + spent this week), filter chips
/// (all/income/expense), and the grouped transaction list.
class AccountView extends StatelessWidget {
  const AccountView({
    super.key,
    required this.account,
    required this.txns,
    required this.onBack,
    required this.onAdd,
    required this.onEdit,
    required this.onSettings,
  });

  final Account account;
  final List<Txn> txns;
  final VoidCallback onBack;
  final void Function(TxnType type) onAdd;
  final void Function(Txn) onEdit;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final icon = kAccountIcons[account.icon] ?? LucideIcons.wallet;
    final bal = txns.fold<int>(
        0, (s, t) => s + (t.type == TxnType.income ? t.amount : -t.amount));
    final now = DateTime.now();
    final month = txns.where((t) => AbidDates.isSameMonth(t.occurredAt, now));
    final monthIncome = month.where((t) => t.type == TxnType.income).fold<int>(0, (s, t) => s + t.amount);
    final monthExpense = month.where((t) => t.type == TxnType.expense).fold<int>(0, (s, t) => s + t.amount);
    final weekExpense = txns
        .where((t) =>
            t.type == TxnType.expense &&
            AbidDates.isSameWeek(t.occurredAt, now))
        .fold<int>(0, (s, t) => s + t.amount);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(LucideIcons.chevronLeft, size: 22, color: c.ink2),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.tint(account.color, 14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 18, color: c.accent(account.color)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
              IconButton(
                onPressed: onSettings,
                icon: Icon(LucideIcons.pencil, size: 16, color: c.ink2),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 140 + MediaQuery.viewPaddingOf(context).bottom),
            children: [
              // Balance hero
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL BALANCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: c.ink3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    MoneyText(
                      paise: bal,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              buzz(8);
                              onAdd(TxnType.income);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.income,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.plus, size: 16),
                                const SizedBox(width: 6),
                                const Text('Income',
                                    style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              buzz(8);
                              onAdd(TxnType.expense);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.expense,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('− Expense',
                                style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Mini stats
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'This month',
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        children: [
                          MoneyText(
                            paise: monthIncome,
                            sign: true,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: c.income,
                            ),
                          ),
                          const SizedBox(width: 8),
                          MoneyText(
                            paise: -monthExpense,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: c.ink3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniStat(
                      label: 'Spent this week',
                      child: MoneyText(
                        paise: weekExpense,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _TxnList(
                txns: txns,
                onTap: (t) {
                  buzz(5);
                  onEdit(t);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: c.ink3,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _TxnList extends StatefulWidget {
  const _TxnList({required this.txns, required this.onTap});
  final List<Txn> txns;
  final ValueChanged<Txn> onTap;

  @override
  State<_TxnList> createState() => _TxnListState();
}

class _TxnListState extends State<_TxnList> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final filtered = widget.txns.where((t) {
      if (_filter == 'all') return true;
      return t.type.name == _filter;
    }).toList();

    // Group by day label.
    final groups = <String, List<Txn>>{};
    for (final t in filtered) {
      final label = AbidDates.dayLabel(t.occurredAt);
      groups.putIfAbsent(label, () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ('all', 'All'),
            ('income', 'Income'),
            ('expense', 'Expense'),
          ].map((e) {
            final selected = _filter == e.$1;
            return GestureDetector(
              onTap: () {
                buzz(5);
                setState(() => _filter = e.$1);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? c.ink : c.surface2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  e.$2,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? c.bg : c.ink2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          EmptyState(
            icon: LucideIcons.wallet,
            color: 'teal',
            title: 'No transactions yet',
            sub: 'Start tracking your money — add an income or expense above.',
          )
        else
          ...groups.entries.map((e) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 0, 6),
                  child: Text(
                    e.key.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: c.ink3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: c.line),
                  ),
                  child: Column(
                    children: e.value.map((t) => _TxnRow(txn: t, onTap: widget.onTap)).toList(),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            );
          }),
      ],
    );
  }
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn, required this.onTap});
  final Txn txn;
  final ValueChanged<Txn> onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final income = txn.type == TxnType.income;
    final icon = kCategoryIcons[txn.category] ?? LucideIcons.circleDot;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(txn),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: income
                      ? c.income.withValues(alpha: 0.12)
                      : c.surface2,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon,
                    size: 17,
                    color: income ? c.income : c.ink2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.note.isEmpty ? txn.category : txn.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      '${txn.category} · ${AbidDates.time(txn.occurredAt)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              MoneyText(
                paise: income ? txn.amount : -txn.amount,
                sign: true,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: income ? c.income : c.expense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
