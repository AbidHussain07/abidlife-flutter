import 'package:flutter/material.dart';

import 'theme_provider.dart';

/// InheritedNotifier wrapper around [ThemeProvider] — same pattern as
/// [DataProviderScope]. Allows descendants to read and react to the user's
/// system / light / dark preference.
class ThemeProviderScope extends InheritedNotifier<ThemeProvider> {
  ThemeProviderScope({
    super.key,
    required this.theme,
    required super.child,
  }) : super(notifier: theme);

  final ThemeProvider theme;

  static ThemeProvider of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<ThemeProviderScope>();
    assert(w != null, 'ThemeProviderScope not found in ancestor tree');
    return w!.theme;
  }
}
