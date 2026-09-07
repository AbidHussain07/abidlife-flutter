import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/data_provider.dart';
import 'data/data_provider_scope.dart';
import 'screens/app_shell.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'theme/theme_provider_scope.dart';

/// Entry point.
///
/// Bootstraps the [DataProvider] (sqflite + local notifications) and the
/// [ThemeProvider] (persisted SharedPreferences) before runApp, so the
/// first frame has data ready.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final data = DataProvider();
  await data.bootstrap();
  await data.initNotifications();

  final theme = await ThemeProvider.create();

  runApp(AbidLifeApp(data: data, theme: theme));
}

class AbidLifeApp extends StatelessWidget {
  const AbidLifeApp({super.key, required this.data, required this.theme});

  final DataProvider data;
  final ThemeProvider theme;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        return MaterialApp(
          title: 'ABIDLIFE',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.mode,
          builder: (context, child) {
            return ThemeProviderScope(
              theme: theme,
              child: DataProviderScope(
                data: data,
                child: child!,
              ),
            );
          },
          home: const AppShell(),
        );
      },
    );
  }
}
