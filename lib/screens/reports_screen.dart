import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _db = DatabaseService();
  DateTime _selectedMonth = DateTime.now();
  Map<TransactionCategory, double> _categoryData = {};
  double _monthlyIncome = 0;
  double _monthlyExpenses = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = context.read<AuthProvider>().userId;

    _monthlyIncome = await _db.getMonthlyIncome(
        userId, _selectedMonth.month, _selectedMonth.year);
    _monthlyExpenses = await _db.getMonthlyExpenses(
        userId, _selectedMonth.month, _selectedMonth.year);
    _categoryData = await _db.getExpensesByCategory(
        userId, _selectedMonth.month, _selectedMonth.year);

    setState(() => _isLoading = false);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadData();
  }

  void _nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (!next.isAfter(DateTime.now())) {
      setState(() => _selectedMonth = next);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMonthSelector(),
                const SizedBox(height: 20),
                _buildSummaryCards(),
                const SizedBox(height: 20),
                _buildCategoryBreakdown(),
              ],
            ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          Text(
            Helpers.formatMonthYear(_selectedMonth),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final savings = _monthlyIncome - _monthlyExpenses;
    final savingsRate =
        _monthlyIncome > 0 ? (savings / _monthlyIncome * 100) : 0;

    return Column(
      children: [
        Row(
          children: [
            _buildSummaryCard(
              'Income',
              _monthlyIncome,
              AppColors.income,
              Icons.arrow_upward,
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              'Expenses',
              _monthlyExpenses,
              AppColors.expense,
              Icons.arrow_downward,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard(
          'Savings',
          savings,
          savings >= 0 ? AppColors.income : AppColors.expense,
          savings >= 0 ? Icons.savings : Icons.trending_down,
          subtitle:
              '${savingsRate.toStringAsFixed(1)}% savings rate',
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon, {
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              Helpers.formatCurrency(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final sortedCategories = _categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Expense Breakdown', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...sortedCategories.map((entry) {
          final percentage =
              _monthlyExpenses > 0 ? (entry.value / _monthlyExpenses * 100) : 0.0;
          return _buildCategoryRow(entry.key, entry.value, percentage);
        }),
      ],
    );
  }

  Widget _buildCategoryRow(
      TransactionCategory category, double amount, double percentage) {
    final colors = AppConstants.categoryColors;
    final colorIndex = TransactionCategory.values.indexOf(category) % colors.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors[colorIndex].withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(category),
              color: colors[colorIndex],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.label,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      Helpers.formatCurrency(amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: colors[colorIndex].withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(colors[colorIndex]),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food: return Icons.restaurant;
      case TransactionCategory.travel: return Icons.directions_car;
      case TransactionCategory.shopping: return Icons.shopping_cart;
      case TransactionCategory.bills: return Icons.receipt_long;
      case TransactionCategory.medical: return Icons.local_hospital;
      case TransactionCategory.others: return Icons.more_horiz;
    }
  }
}
