import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../utils/helpers.dart';

class BudgetProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  Budget? _currentBudget;
  bool _isLoading = false;
  String? _error;

  Budget? get currentBudget => _currentBudget;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasBudget => _currentBudget != null;

  Future<void> loadBudget(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      _currentBudget =
          await _databaseService.getBudget(userId, now.month, now.year);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load budget.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setBudget({
    required String userId,
    required double monthlyLimit,
    int? month,
    int? year,
    bool notifyOnLimit = true,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final budgetMonth = month ?? now.month;
      final budgetYear = year ?? now.year;

      final expenses =
          await _databaseService.getMonthlyExpenses(userId, budgetMonth, budgetYear);

      final budget = Budget(
        monthlyLimit: monthlyLimit,
        currentSpending: expenses,
        month: budgetMonth,
        year: budgetYear,
        userId: userId,
        notifyOnLimit: notifyOnLimit,
      );

      await _databaseService.insertOrUpdateBudget(budget);
      _currentBudget = budget;
      _isLoading = false;
      notifyListeners();

      if (budget.isLimitReached || budget.isWarningZone) {
        _showBudgetWarning(budget);
      }

      return true;
    } catch (e) {
      _error = 'Failed to set budget.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> checkBudgetLimit({
    required String userId,
    required int month,
    required int year,
  }) async {
    if (_currentBudget == null) return;

    final expenses =
        await _databaseService.getMonthlyExpenses(userId, month, year);
    final updatedBudget =
        _currentBudget!.copyWith(currentSpending: expenses);
    _currentBudget = updatedBudget;
    notifyListeners();

    await _databaseService.updateBudgetSpending(userId, month, year);

    if (updatedBudget.isLimitReached || updatedBudget.isWarningZone) {
      _showBudgetWarning(updatedBudget);
    }
  }

  void _showBudgetWarning(Budget budget) {
    _notificationService.showBudgetLimitWarning(
      limit: budget.monthlyLimit,
      spending: budget.currentSpending,
      month: Helpers.getMonthName(budget.month),
    );
  }

  void clearBudget() {
    _currentBudget = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
