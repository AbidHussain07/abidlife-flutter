import 'package:abidlife/core/app_theme.dart';
import 'package:abidlife/core/formatters.dart';
import 'package:abidlife/domain/money_math.dart';
import 'package:abidlife/models/models.dart';
import 'package:abidlife/providers/app_controller.dart';
import 'package:abidlife/screens/transaction_editor_screen.dart';
import 'package:abidlife/widgets/app_icons.dart';
import 'package:abidlife/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MoneyScreen extends ConsumerWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final accounts = app.accounts.where((account) => !account.archived).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(78),
        child: AppPageHeader(
          title: 'Money',
          subtitle: accounts.isEmpty ? 'Your accounts' : '${accounts.length} account${accounts.length == 1 ? '' : 's'}',
        ),
      ),
      body: accounts.isEmpty
          ? EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No accounts yet',
              message: 'Create an account for yourself or someone whose money you track.',
              actionLabel: 'Add account',
              onAction: () => _editAccount(context, ref),
              color: AppColors.teal,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 106),
              children: <Widget>[
                const SectionLabel('Accounts'),
                Card(
                  child: Column(
                    children: accounts.map((account) {
                      final txns = app.transactions.where((transaction) => transaction.accountId == account.id).toList();
                      final latest = txns.isEmpty ? null : txns.first.occurredAt;
                      return InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => AccountDashboardScreen(accountId: account.id),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.habit(account.color).withValues(alpha: .13),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  accountIcons[account.icon] ?? Icons.account_balance_wallet_rounded,
                                  color: AppColors.habit(account.color),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(account.name, style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 4),
                                    Text(
                                      latest == null ? 'No activity yet' : 'Last activity · ${relativeDay(latest)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    formatMoney(accountBalance(txns)),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, size: 18),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _editAccount(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add account'),
                ),
              ],
            ),
      floatingActionButton: accounts.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.small(
                heroTag: 'money_fab',
                tooltip: 'Add account',
                backgroundColor: AppColors.teal,
                onPressed: () => _editAccount(context, ref),
                child: const Icon(Icons.add_rounded),
              ),
            ),
    );
  }

  Future<void> _editAccount(
    BuildContext context,
    WidgetRef ref, [
    MoneyAccountModel? account,
  ]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _AccountEditor(account: account),
    );
  }
}

class _AccountEditor extends ConsumerStatefulWidget {
  const _AccountEditor({this.account});
  final MoneyAccountModel? account;

  @override
  ConsumerState<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends ConsumerState<_AccountEditor> {
  late final TextEditingController _name;
  late String _icon;
  late String _color;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.account?.name ?? '');
    _icon = widget.account?.icon ?? 'wallet';
    _color = widget.account?.color ?? 'violet';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = <String>['violet', 'blue', 'green', 'teal', 'orange', 'pink'];
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(widget.account == null ? 'New account' : 'Edit account', style: Theme.of(context).textTheme.titleLarge),
            TextField(
              controller: _name,
              autofocus: widget.account == null,
              style: Theme.of(context).textTheme.titleLarge,
              decoration: const InputDecoration(
                hintText: 'e.g. My Account, Savings…',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            const SectionLabel('Icon'),
            GridView.count(
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: accountIcons.entries
                  .map(
                    (entry) => InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _icon = entry.key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _icon == entry.key
                              ? AppColors.habit(_color).withValues(alpha: .14)
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(entry.value, color: _icon == entry.key ? AppColors.habit(_color) : null),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            const SectionLabel('Color'),
            Wrap(
              spacing: 12,
              children: colors
                  .map(
                    (name) => InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _color = name),
                      child: CircleAvatar(
                        radius: 21,
                        backgroundColor: AppColors.habit(name),
                        child: _color == name ? const Icon(Icons.check_rounded, color: Colors.white) : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                onPressed: _save,
                child: Text(widget.account == null ? 'Create account' : 'Save changes'),
              ),
            ),
            if (widget.account != null)
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppColors.expense),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete account & transactions'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return;
    await ref.read(appControllerProvider).saveAccount(
          id: widget.account?.id,
          name: _name.text,
          icon: _icon,
          color: _color,
          archived: widget.account?.archived ?? false,
          createdAt: widget.account?.createdAt,
        );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final account = widget.account;
    if (account == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Delete this account?',
      message: '“${account.name}” and every transaction in it will be removed.',
    );
    if (!confirmed) return;
    await ref.read(appControllerProvider).deleteAccount(account.id);
    if (mounted) Navigator.pop(context);
  }
}

class AccountDashboardScreen extends ConsumerStatefulWidget {
  const AccountDashboardScreen({required this.accountId, super.key});
  final String accountId;

  @override
  ConsumerState<AccountDashboardScreen> createState() => _AccountDashboardScreenState();
}

class _AccountDashboardScreenState extends ConsumerState<AccountDashboardScreen> {
  var _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    final account = app.accounts.where((value) => value.id == widget.accountId).firstOrNull;
    if (account == null) {
      return const Scaffold(body: Center(child: Text('Account no longer exists.')));
    }
    final all = app.transactions.where((transaction) => transaction.accountId == account.id).toList();
    final filtered = all.where((transaction) => _filter == 'all' || transaction.type.name == _filter).toList();
    final groups = <String, List<MoneyTransactionModel>>{};
    for (final transaction in filtered) {
      groups.putIfAbsent(relativeDay(transaction.occurredAt), () => <MoneyTransactionModel>[]).add(transaction);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: <Widget>[
          IconButton(
            tooltip: 'Edit account',
            onPressed: () async {
              await showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => _AccountEditor(account: account),
              );
              if (mounted && !ref.read(appControllerProvider).accounts.any((value) => value.id == account.id)) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 34),
        children: <Widget>[
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('TOTAL BALANCE', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.3, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(formatMoney(accountBalance(all)), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1)),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _moneyAction(
                        context,
                        label: 'Income',
                        value: incomeTotal(all),
                        color: AppColors.income,
                        icon: Icons.add_rounded,
                        onTap: () => _transaction(context, account, TransactionType.income),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _moneyAction(
                        context,
                        label: 'Expense',
                        value: expenseTotal(all),
                        color: AppColors.expense,
                        icon: Icons.remove_rounded,
                        onTap: () => _transaction(context, account, TransactionType.expense),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: <String>['all', 'income', 'expense']
                .map(
                  (value) => ChoiceChip(
                    selected: _filter == value,
                    label: Text(value == 'all' ? 'All' : value[0].toUpperCase() + value.substring(1)),
                    onSelected: (_) => setState(() => _filter = value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          if (filtered.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              message: 'Add income or an expense to start tracking this account.',
              color: AppColors.teal,
            )
          else
            for (final group in groups.entries) ...<Widget>[
              SectionLabel(group.key),
              Card(
                child: Column(
                  children: group.value
                      .map(
                        (transaction) => _transactionRow(context, account, transaction),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 6),
            ],
          // Deliberately no spending-breakdown section. Categories remain on transactions.
        ],
      ),
    );
  }

  Widget _moneyAction(
    BuildContext context, {
    required String label,
    required int value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: <Widget>[
              CircleAvatar(radius: 16, backgroundColor: color, foregroundColor: Colors.white, child: Icon(icon, size: 18)),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
                    Text(formatMoney(value), overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _transactionRow(
    BuildContext context,
    MoneyAccountModel account,
    MoneyTransactionModel transaction,
  ) {
    final income = transaction.type == TransactionType.income;
    final color = income ? AppColors.income : AppColors.expense;
    return ListTile(
      onTap: () => _transaction(context, account, transaction.type, existing: transaction),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .11),
        foregroundColor: color,
        child: Icon(categoryIcons[transaction.category] ?? Icons.category_rounded, size: 19),
      ),
      title: Text(transaction.note.isEmpty ? transaction.category : transaction.note, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${transaction.category} · ${DateFormat('h:mm a').format(transaction.occurredAt)}'),
      trailing: Text(
        formatMoney(income ? transaction.amountPaise : -transaction.amountPaise, signed: true),
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }

  Future<void> _transaction(
    BuildContext context,
    MoneyAccountModel account,
    TransactionType type, {
    MoneyTransactionModel? existing,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TransactionEditorScreen(
          account: account,
          initialType: type,
          existing: existing,
        ),
      ),
    );
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
