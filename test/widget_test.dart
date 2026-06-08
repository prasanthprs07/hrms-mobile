import 'package:flutter_test/flutter_test.dart';
import 'package:expense_manager/models/transaction.dart';
import 'package:expense_manager/models/budget.dart' as budget_model;

void main() {
  group('Transaction Model Tests', () {
    test('transaction toMap and fromMap', () {
      final tx = Transaction(
        title: 'Test',
        amount: 100,
        type: TransactionType.debit,
        category: TransactionCategory.food,
        date: DateTime(2024, 1, 15),
        userId: 'test123',
      );

      final map = tx.toMap();
      final restored = Transaction.fromMap(map);

      expect(restored.title, tx.title);
      expect(restored.amount, tx.amount);
      expect(restored.type, tx.type);
      expect(restored.category, tx.category);
    });

    test('formatted amount uses rupee symbol', () {
      final tx = Transaction(
        title: 'Test',
        amount: 1500,
        type: TransactionType.credit,
        category: TransactionCategory.others,
        date: DateTime.now(),
        userId: 'test123',
      );

      expect(tx.formattedAmount, contains('\u20B9'));
    });

    test('transaction types enum values', () {
      expect(TransactionType.values.length, 2);
      expect(TransactionType.credit.name, 'credit');
      expect(TransactionType.debit.name, 'debit');
    });

    test('transaction categories count', () {
      expect(TransactionCategory.values.length, 6);
    });
  });

  group('Budget Model Tests', () {
    test('budget calculations', () {
      final budget = budget_model.Budget(
        monthlyLimit: 10000,
        currentSpending: 7500,
        month: 1,
        year: 2024,
        userId: 'test123',
      );

      expect(budget.remaining, 2500);
      expect(budget.percentageUsed, 75.0);
      expect(budget.isLimitReached, false);
      expect(budget.isWarningZone, false);
    });

    test('budget limit reached', () {
      final budget = budget_model.Budget(
        monthlyLimit: 10000,
        currentSpending: 10000,
        month: 1,
        year: 2024,
        userId: 'test123',
      );

      expect(budget.isLimitReached, true);
    });

    test('budget warning zone', () {
      final budget = budget_model.Budget(
        monthlyLimit: 10000,
        currentSpending: 8000,
        month: 1,
        year: 2024,
        userId: 'test123',
      );

      expect(budget.isWarningZone, true);
      expect(budget.isLimitReached, false);
    });
  });
}
