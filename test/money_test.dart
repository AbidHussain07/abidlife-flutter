import 'package:abidlife/domain/money_math.dart';
import 'package:abidlife/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

MoneyTransactionModel txn(TransactionType type, int paise) => MoneyTransactionModel(
      id: '$type-$paise',
      accountId: 'a1',
      type: type,
      amountPaise: paise,
      note: '',
      category: 'Other',
      occurredAt: DateTime(2025),
      createdAt: DateTime(2025),
    );

void main() {
  final values = <MoneyTransactionModel>[
    txn(TransactionType.income, 7500000),
    txn(TransactionType.expense, 3250000),
  ];

  test('11 income total uses integer paise', () {
    expect(incomeTotal(values), 7500000);
  });

  test('12 expense total uses integer paise', () {
    expect(expenseTotal(values), 3250000);
  });

  test('13 account balance is income minus expense', () {
    expect(accountBalance(values), 4250000);
  });

  test('14 empty account has zero balance', () {
    expect(accountBalance(const <MoneyTransactionModel>[]), 0);
  });
}
