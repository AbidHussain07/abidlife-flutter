import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/data_provider.dart';
import '../../data/data_provider_scope.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';
import '../../utils/date_utils.dart';
import 'account_sheet.dart';
import 'account_view.dart';
import 'txn_keypad.dart';

/// Money screen — accounts list / account detail.
///
/// Mirrors the web app's `MoneyScreen`: home shows the accounts list +
/// recent activity strip + add-account button; tapping an account pushes
/// the per-account dashboard with hero balance, income/expense CTAs,
/// monthly/weekly stats, filter chips, and the grouped transaction list.
class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  String? _accountId;

  void _openAccount(String id) => setState(() => _accountId = id);
  void _closeAccount() => setState(() => _accountId = null);

  @override
  Widget build(BuildContext context) {
    final data = DataProviderScope.of(context);
    final c = AppTheme.of(context);
    final live = data.accounts.where((a) => !a.archived).toList();
    final active = _accountId == null
        ? null
        : live.firstWhere((a) => a.id == _accountId, orElse: () => live.first);

    if (active != null) {
      return AccountView(
        account: active,
        txns: data.txns.where((t) => t.accountId == active.id).toList(),
        onBack: _closeAccount,
        onAdd: (type) => _openKeypad(accountId: active.id, type: type),
        onEdit: (t) => _openKeypad(editTxn: t),
        onSettings: () => _openAccountSheet(active),
      );
    }

    return _MoneyHome(
      accounts: live,
      txns: data.txns,
      onOpen: _openAccount,
      onAddAccount: () => _openAccountSheet(null),
    );
  }

  Future<void> _openKeypad({
    String? accountId,
    TxnType type = TxnType.expense,
    Txn? editTxn,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => TxnKeypad(
        accountId: accountId,
        initialType: type,
        editTxn: editTxn,
      ),
    );
  }

  Future<void> _openAccountSheet(Account? existing) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AccountSheet(account: existing),
    );
  }
}

class _MoneyHome extends StatelessWidget {
  const _MoneyHome({
    required this.accounts,
    required this.txns,
    required this.onOpen,
    required this.onAddAccount,
  });
  final List<Account> accounts;
  final List<Txn> txns;
  final ValueChanged<String> onOpen;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
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
                      'Money',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      accounts.isEmpty
                          ? 'Your accounts'
                          : '${accounts.length} account${accounts.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: accounts.isEmpty
              ? EmptyState(
                  icon: LucideIcons.wallet,
                  color: 'teal',
                  title: 'No accounts yet',
                  sub:
                      'Create one for yourself — or for Mom, Dad, anyone you track money for.',
                  action: 'Add account',
                  onAction: onAddAccount,
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 140 + MediaQuery.viewPaddingOf(context).bottom),
                  children: [
                    SectionLabel('ACCOUNTS'),
                    Container(
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: c.line),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < accounts.length; i++) ...[
                            _AccountRow(
                              account: accounts[i],
                              txns: txns.where((t) => t.accountId == accounts[i].id).toList(),
                              onTap: () => onOpen(accounts[i].id),
                            ),
                            if (i < accounts.length - 1)
                              Divider(height: 1, color: c.line, indent: 16, endIndent: 16),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        buzz(6);
                        onAddAccount();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: c.line,
                            width: 1.6,
                          ),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.plus, size: 16, color: c.ink3),
                            const SizedBox(width: 8),
                            Text(
                              'Add account',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: c.ink3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (txns.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      SectionLabel('RECENT ACTIVITY'),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: c.line),
                        ),
                        child: Column(
                          children: txns.take(5).map((t) {
                            final acc = accounts.firstWhere(
                              (a) => a.id == t.accountId,
                              orElse: () => Account(
                                id: '',
                                name: 'Account',
                                icon: 'Wallet',
                                color: 'teal',
                                archived: false,
                                createdAt: DateTime.now(),
                              ),
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: c.tint(acc.color, 14),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      kAccountIcons[acc.icon] ?? LucideIcons.wallet,
                                      size: 15,
                                      color: c.accent(acc.color),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.note.isEmpty ? t.category : t.note,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: c.ink,
                                          ),
                                        ),
                                        Text(
                                          '${acc.name} · ${AbidDates.dayLabel(t.occurredAt)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: c.ink3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  MoneyText(
                                    paise: t.type == TxnType.income ? t.amount : -t.amount,
                                    sign: true,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: t.type == TxnType.income ? c.income : c.expense,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.txns,
    required this.onTap,
  });
  final Account account;
  final List<Txn> txns;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final bal = txns.fold<int>(
        0, (s, t) => s + (t.type == TxnType.income ? t.amount : -t.amount));
    final lastLabel = txns.isEmpty
        ? 'No activity yet'
        : 'Last activity · ${AbidDates.dayLabel(txns.first.occurredAt)}';
    final icon = kAccountIcons[account.icon] ?? LucideIcons.wallet;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          buzz(6);
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.tint(account.color, 14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 19, color: c.accent(account.color)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    Text(
                      lastLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: c.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  MoneyText(
                    paise: bal,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(LucideIcons.chevronRight, size: 13, color: c.ink3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
