import 'package:abidlife/models/models.dart';

int incomeTotal(Iterable<MoneyTransactionModel> transactions) => transactions
    .where((value) => value.type == TransactionType.income)
    .fold(0, (sum, value) => sum + value.amountPaise);

int expenseTotal(Iterable<MoneyTransactionModel> transactions) => transactions
    .where((value) => value.type == TransactionType.expense)
    .fold(0, (sum, value) => sum + value.amountPaise);

int accountBalance(Iterable<MoneyTransactionModel> transactions) =>
    incomeTotal(transactions) - expenseTotal(transactions);
