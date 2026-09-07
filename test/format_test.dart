import 'package:flutter_test/flutter_test.dart';
import 'package:abidlife/utils/format.dart';

void main() {
  group('Fmt.inr', () {
    test('formats whole-rupee amounts without decimals', () {
      expect(Fmt.inr(100), '₹1');
      expect(Fmt.inr(10000), '₹100');
      expect(Fmt.inr(100000), '₹1,000');
      expect(Fmt.inr(10000000), '₹1,00,000');
    });

    test('shows paise when present', () {
      expect(Fmt.inr(150), '₹1.50');
      expect(Fmt.inr(199), '₹1.99');
      expect(Fmt.inr(1050), '₹10.50');
    });

    test('handles negative amounts with − prefix', () {
      expect(Fmt.inr(-100), '−₹1');
      expect(Fmt.inr(-150), '−₹1.50');
    });

    test('shows + prefix when sign=true and amount positive', () {
      expect(Fmt.inr(500, sign: true), '+₹5');
      expect(Fmt.inr(-500, sign: true), '−₹5');
    });

    test('groups using en-IN convention (lakhs / crores)', () {
      // 1,00,000.00 INR = 1,00,00,000 paise = 10 million paise = ₹1,00,000
      expect(Fmt.inr(10000000), '₹1,00,000');
      // 12,34,567.89 INR = 12,34,56,789 paise
      expect(Fmt.inr(123456789), '₹12,34,567.89');
    });

    test('zero renders as ₹0', () {
      expect(Fmt.inr(0), '₹0');
    });
  });
}
