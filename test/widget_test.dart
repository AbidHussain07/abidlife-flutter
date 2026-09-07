import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:abidlife/ui/ui.dart';

void main() {
  group('MoneyText', () {
    testWidgets('renders whole-rupee amounts without decimals',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MoneyText(paise: 10000),
          ),
        ),
      );
      expect(find.text('₹100'), findsOneWidget);
    });

    testWidgets('renders paise when present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MoneyText(paise: 150),
          ),
        ),
      );
      expect(find.text('₹1.50'), findsOneWidget);
    });

    testWidgets('renders + prefix when sign=true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MoneyText(paise: 500, sign: true),
          ),
        ),
      );
      expect(find.text('+₹5'), findsOneWidget);
    });

    testWidgets('renders − prefix for negative amounts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MoneyText(paise: -500),
          ),
        ),
      );
      expect(find.text('−₹5'), findsOneWidget);
    });
  });
}
