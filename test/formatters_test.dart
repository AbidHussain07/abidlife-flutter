import 'package:abidlife/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('15 day keys are stable local calendar keys', () {
    expect(dayKey(DateTime(2025, 3, 7, 23, 59)), '2025-03-07');
  });

  test('16 sameDay ignores time', () {
    expect(
      sameDay(DateTime(2025, 4, 2, 1), DateTime(2025, 4, 2, 23)),
      isTrue,
    );
  });

  test('17 greeting follows local time boundaries', () {
    expect(greeting(DateTime(2025, 1, 1, 7)), contains('Morning'));
    expect(greeting(DateTime(2025, 1, 1, 19)), contains('Evening'));
  });
}
