import 'package:flutter/material.dart';

import 'data_provider.dart';

/// InheritedNotifier wrapper around [DataProvider] so descendants can call
/// `DataProviderScope.of(context)` to read and react to state changes.
///
/// This is functionally equivalent to `Provider.of<DataProvider>(context)`
/// but without pulling in the `provider` package as a hard dependency for
/// every widget file.
class DataProviderScope extends InheritedNotifier<DataProvider> {
  DataProviderScope({
    super.key,
    required this.data,
    required super.child,
  }) : super(notifier: data);

  final DataProvider data;

  /// Look up the nearest [DataProviderScope] ancestor.
  static DataProvider of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<DataProviderScope>();
    assert(w != null, 'DataProviderScope not found in ancestor tree');
    return w!.data;
  }
}
