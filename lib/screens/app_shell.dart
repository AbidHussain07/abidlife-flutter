import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/data_provider.dart';
import '../data/data_provider_scope.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../ui/ui.dart';
import '../ui/widgets/bottom_nav.dart';
import '../ui/widgets/logo.dart';
import 'habits/habits_screen.dart';
import 'insights_screen.dart';
import 'money/money_screen.dart';
import 'notes/notes_screen.dart';
import 'onboarding.dart';
import 'tasks/tasks_screen.dart';

/// Root scaffold.
///
/// Mirrors the web app's `AppShell` — manages onboarding state, the splash
/// screen during initial load, the active screen body, the bottom nav, and
/// the toast stack at the top of the screen.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool? _onboarded;

  @override
  void initState() {
    super.initState();
    _loadOnboarding();
  }

  Future<void> _loadOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _onboarded = prefs.getBool('abidlife.onboarded') ?? false);
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('abidlife.onboarded', true);
    setState(() => _onboarded = true);
  }

  @override
  Widget build(BuildContext context) {
    final data = DataProviderScope.of(context);

    if (_onboarded == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    if (_onboarded == false) {
      return Onboarding(onDone: _finishOnboarding);
    }
    if (data.loading) {
      return const _Splash();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const _ActiveScreen(),
          const BottomNav(),
          const _ToastStack(),
        ],
      ),
    );
  }
}

class _ActiveScreen extends StatelessWidget {
  const _ActiveScreen();

  @override
  Widget build(BuildContext context) {
    final tab = DataProviderScope.of(context).tab;
    final screen = switch (tab) {
      Tab.insights => const InsightsScreen(),
      Tab.notes => const NotesScreen(),
      Tab.tasks => const TasksScreen(),
      Tab.habits => const HabitsScreen(),
      Tab.money => const MoneyScreen(),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(tab),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.viewPaddingOf(context).top,
            ),
            child: screen,
          ),
        ),
      ),
    );
  }
}

class _ToastStack extends StatelessWidget {
  const _ToastStack();

  @override
  Widget build(BuildContext context) {
    final data = DataProviderScope.of(context);
    final c = AppTheme.of(context);
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        return Positioned(
          top: 16 + MediaQuery.viewPaddingOf(context).top,
          left: 24,
          right: 24,
          child: Column(
            children: data.toasts
                .map((t) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: c.line),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: c.green),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              t.msg,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: c.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Container(
      color: c.bg,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LumaLogo(size: 64),
          const SizedBox(height: 16),
          Text(
            'ABIDLIFE',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Everything you need, in one place',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: c.ink3,
            ),
          ),
        ],
      ),
    );
  }
}
