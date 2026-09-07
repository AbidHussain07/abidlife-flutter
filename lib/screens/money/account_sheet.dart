import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/data_provider.dart';
import '../../data/data_provider_scope.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../../ui/ui.dart';

/// Create / edit / delete an account.
///
/// Mirrors the web app's `AccountSheet`: name field, icon grid,
/// color picker, save button, and (in edit mode) a destructive
/// "Delete account & transactions" action with confirmation.
class AccountSheet extends StatefulWidget {
  const AccountSheet({super.key, this.account});
  final Account? account;

  @override
  State<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends State<AccountSheet> {
  late final TextEditingController _nameCtrl;
  late String _icon;
  late String _color;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.account?.name ?? '');
    _icon = widget.account?.icon ?? 'Wallet';
    _color = widget.account?.color ?? 'violet';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _nameCtrl.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_valid) return;
    buzz(10);
    final data = DataProviderScope.of(context);
    if (widget.account != null) {
      await data.updateAccount(widget.account!.id, {
        'name': _nameCtrl.text.trim(),
        'icon': _icon,
        'color': _color,
      });
    } else {
      await data.addAccount({
        'name': _nameCtrl.text.trim(),
        'icon': _icon,
        'color': _color,
      });
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  Future<void> _delete() async {
    final data = DataProviderScope.of(context);
    await data.deleteAccount(widget.account!.id);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final editing = widget.account != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: c.surface3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                editing ? 'Edit account' : 'New account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                autofocus: !editing,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. My Account, Mom, Savings…',
                  hintStyle: TextStyle(color: c.ink3),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 16),
              Text('ICON',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: c.ink3,
                  )),
              const SizedBox(height: 10),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
                children: kAccountIcons.keys.map((k) {
                  final selected = _icon == k;
                  final icon = kAccountIcons[k]!;
                  return GestureDetector(
                    onTap: () {
                      buzz(5);
                      setState(() => _icon = k);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? c.tint(_color, 16) : c.surface2,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        size: 19,
                        color: selected ? c.accent(_color) : c.ink3,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('COLOR',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: c.ink3,
                  )),
              const SizedBox(height: 10),
              ColorRow(
                value: _color,
                onChanged: (v) => setState(() => _color = v),
                colors: kPaletteNames.where((c) => c != 'red').toList(),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _valid ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: c.surface3,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  editing ? 'Save changes' : 'Create account',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              if (editing) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    ConfirmSheet.show(
                      context,
                      title: 'Delete this account?',
                      sub:
                          '"${widget.account!.name}" and all its transactions will be removed.',
                      confirmLabel: 'Delete',
                      onConfirm: _delete,
                    );
                  },
                  icon: Icon(LucideIcons.trash2, size: 16, color: c.expense),
                  label: Text(
                    'Delete account & transactions',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: c.expense,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
