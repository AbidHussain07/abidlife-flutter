import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode preference persisted to `SharedPreferences`.
///
/// Mirrors the web app's `ThemeProvider` — system / light / dark, with the
/// choice stored locally so it survives restarts.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider._(this._prefs);
  static const _key = 'abidlife.themeMode';

  final SharedPreferences _prefs;
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  static Future<ThemeProvider> create() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = ThemeProvider._(prefs);
    final stored = prefs.getString(_key);
    provider._mode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return provider;
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setString(
      _key,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      },
    );
  }
}
