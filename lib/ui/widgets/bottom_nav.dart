import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../data/data_provider.dart';
import '../../data/data_provider_scope.dart';
import '../../data/models.dart';
import '../../theme/app_theme.dart';
import '../ui.dart';

/// Bottom navigation bar with 5 tabs.
///
/// Mirrors the web app's `BottomNav` — a floating, glass-like bar with a
/// sliding accent pill behind the active tab. Tab labels are hidden until
/// the tab is active.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key});
  static const _items = <_NavItem>[
    _NavItem(tab: Tab.notes, label: 'Notes', icon: LucideIcons.notebookPen, color: 'amber'),
    _NavItem(tab: Tab.tasks, label: 'Tasks', icon: LucideIcons.checkCircle2, color: 'blue'),
    _NavItem(tab: Tab.habits, label: 'Habits', icon: LucideIcons.flame, color: 'green'),
    _NavItem(tab: Tab.money, label: 'Money', icon: LucideIcons.wallet, color: 'teal'),
    _NavItem(tab: Tab.insights, label: 'Insights', icon: LucideIcons.sparkles, color: 'violet'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    final tab = DataProviderScope.of(context).tab;
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12 + MediaQuery.viewPaddingOf(context).bottom,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: c.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: c.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: _items.map((it) {
            final active = tab == it.tab;
            final accent = c.accent(it.color);
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  buzz(7);
                  DataProviderScope.of(context).setTab(it.tab);
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                  height: 48,
                  decoration: BoxDecoration(
                    color: active ? c.tint(it.color, 15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        it.icon,
                        size: 20,
                        color: active ? accent : c.ink3,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 6 : 0,
                      ),
                      if (active) ...[
                        Text(
                          it.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final Tab tab;
  final String label;
  final IconData icon;
  final String color;
  const _NavItem({
    required this.tab,
    required this.label,
    required this.icon,
    required this.color,
  });
}
