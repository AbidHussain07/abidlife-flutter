import 'package:abidlife/core/app_theme.dart';
import 'package:abidlife/screens/habits_screen.dart';
import 'package:abidlife/screens/insights_screen.dart';
import 'package:abidlife/screens/money_screen.dart';
import 'package:abidlife/screens/notes_screen.dart';
import 'package:abidlife/screens/tasks_screen.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _index = 4;

  static const _screens = <Widget>[
    NotesScreen(),
    TasksScreen(),
    HabitsScreen(),
    MoneyScreen(),
    InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.sticky_note_2_outlined),
        selectedIcon: Icon(Icons.sticky_note_2_rounded, color: AppColors.amber),
        label: 'Notes',
      ),
      const NavigationDestination(
        icon: Icon(Icons.check_circle_outline_rounded),
        selectedIcon: Icon(Icons.check_circle_rounded, color: AppColors.blue),
        label: 'Tasks',
      ),
      const NavigationDestination(
        icon: Icon(Icons.local_fire_department_outlined),
        selectedIcon: Icon(Icons.local_fire_department_rounded, color: AppColors.green),
        label: 'Habits',
      ),
      const NavigationDestination(
        icon: Icon(Icons.account_balance_wallet_outlined),
        selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.teal),
        label: 'Money',
      ),
      const NavigationDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        selectedIcon: Icon(Icons.auto_awesome_rounded, color: AppColors.brand),
        label: 'Insights',
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: NavigationBar(
              selectedIndex: _index,
              destinations: destinations,
              onDestinationSelected: (value) => setState(() => _index = value),
            ),
          ),
        ),
      ),
    );
  }
}
