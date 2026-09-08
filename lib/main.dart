import 'package:abidlife/core/app_theme.dart';
import 'package:abidlife/providers/app_controller.dart';
import 'package:abidlife/screens/app_shell.dart';
import 'package:abidlife/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ProviderScope(child: AbidLifeApp()));
}

class AbidLifeApp extends ConsumerStatefulWidget {
  const AbidLifeApp({super.key});

  @override
  ConsumerState<AbidLifeApp> createState() => _AbidLifeAppState();
}

class _AbidLifeAppState extends ConsumerState<AbidLifeApp> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(ref.read(appControllerProvider).initialize);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifeDeck',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: app.themeMode,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('en')],
      home: !app.initialized
          ? const _SplashScreen()
          : app.onboardingComplete
              ? const AppShell()
              : const OnboardingScreen(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 58,
              height: 58,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 20),
            Text(
              'LifeDeck',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text('Everything you need, in one place'),
          ],
        ),
      ),
    );
  }
}
