import 'package:abidlife/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const <Widget>[],
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
        child: Row(
          children: <Widget>[
            if (leading != null) ...<Widget>[leading!, const SizedBox(width: 8)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.headlineMedium),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color = AppColors.brand,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 6, 3, 9),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({required this.child, this.padding = const EdgeInsets.all(16), super.key});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: AppColors.expense)
                  : null,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}

Future<bool?> showPinGate(
  BuildContext context, {
  required String title,
  required String subtitle,
  required Future<bool> Function(String pin) onSubmit,
  String errorMessage = 'Incorrect PIN. Try again.',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PinGate(
      title: title,
      subtitle: subtitle,
      onSubmit: onSubmit,
      errorMessage: errorMessage,
    ),
  );
}

class _PinGate extends StatefulWidget {
  const _PinGate({
    required this.title,
    required this.subtitle,
    required this.onSubmit,
    required this.errorMessage,
  });

  final String title;
  final String subtitle;
  final Future<bool> Function(String) onSubmit;
  final String errorMessage;

  @override
  State<_PinGate> createState() => _PinGateState();
}

class _PinGateState extends State<_PinGate> {
  String _pin = '';
  String? _error;
  bool _submitting = false;

  Future<void> _press(String value) async {
    if (_submitting) return;
    HapticFeedback.selectionClick();
    if (value == 'back') {
      setState(() {
        _pin = _pin.isEmpty ? '' : _pin.substring(0, _pin.length - 1);
        _error = null;
      });
      return;
    }
    if (_pin.length == 4) return;
    setState(() {
      _pin += value;
      _error = null;
    });
    if (_pin.length != 4) return;
    setState(() => _submitting = true);
    final accepted = await widget.onSubmit(_pin);
    if (!mounted) return;
    if (accepted) {
      Navigator.pop(context, true);
      return;
    }
    // Critical retry behavior: every failure clears all digits immediately,
    // keeps the sheet open, and is ready for another complete attempt.
    HapticFeedback.heavyImpact();
    setState(() {
      _pin = '';
      _error = widget.errorMessage;
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keys = <String>['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        28,
        4,
        28,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(widget.subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(
              4,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < _pin.length
                      ? AppColors.brand
                      : Theme.of(context).dividerColor,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: Center(
              child: Text(
                _error ?? '',
                style: const TextStyle(
                  color: AppColors.expense,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.35,
              children: keys.map((key) {
                if (key.isEmpty) return const SizedBox.shrink();
                return Semantics(
                  button: true,
                  label: key == 'back' ? 'Backspace' : key,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _press(key),
                    child: Center(
                      child: key == 'back'
                          ? const Icon(Icons.backspace_outlined)
                          : Text(
                              key,
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

void showMessage(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
