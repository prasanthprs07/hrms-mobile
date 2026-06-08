import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../services/sms_service.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final SmsService _smsService = SmsService();

  List<Transaction> _transactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  TransactionType? _filterType;
  TransactionCategory? _filterCategory;
  bool _smsAutoRead = false;

  List<Transaction> get transactions => _filteredTransactions;
  List<Transaction> get allTransactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  TransactionType? get filterType => _filterType;
  TransactionCategory? get filterCategory => _filterCategory;
  bool get smsAutoRead => _smsAutoRead;

  Future<void> loadTransactions(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _databaseService.getTransactions(userId);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load transactions.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTransaction(Transaction transaction) async {
    try {
      final id = await _databaseService.insertTransaction(transaction);
      final newTransaction = transaction.copyWith(id: id);
      _transactions.insert(0, newTransaction);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to add transaction.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    try {
      await _databaseService.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
      }
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update transaction.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      await _databaseService.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete transaction.';
      notifyListeners();
      return false;
    }
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByType(TransactionType? type) {
    _filterType = type;
    _applyFilters();
  }

  void filterByCategory(TransactionCategory? category) {
    _filterCategory = category;
    _applyFilters();
  }

  void clearFilters() {
    _filterType = null;
    _filterCategory = null;
    _searchQuery = '';
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = _transactions;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return t.title.toLowerCase().contains(query) ||
            t.note?.toLowerCase().contains(query) == true ||
            t.category.label.toLowerCase().contains(query);
      }).toList();
    }

    if (_filterType != null) {
      filtered = filtered.where((t) => t.type == _filterType).toList();
    }

    if (_filterCategory != null) {
      filtered =
          filtered.where((t) => t.category == _filterCategory).toList();
    }

    _filteredTransactions = filtered;
    notifyListeners();
  }

  double get totalIncome {
    return _transactions
        .where((t) => t.type == TransactionType.credit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpenses {
    return _transactions
        .where((t) => t.type == TransactionType.debit)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpenses;

  SmsTransactionResult? parseSmsMessage(String message, String userId) {
    return _smsService.parseSms(message, userId);
  }

  Future<bool> addTransactionFromSms(
      SmsTransactionResult result, String userId) async {
    if (result.success && result.transaction != null) {
      return await addTransaction(result.transaction!);
    }
    return false;
  }

  void setSmsAutoRead(bool value) {
    _smsAutoRead = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
