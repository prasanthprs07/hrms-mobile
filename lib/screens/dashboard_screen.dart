import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../models/budget.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isNotEmpty) {
      context.read<TransactionProvider>().loadTransactions(userId);
      context.read<BudgetProvider>().loadBudget(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<TransactionProvider, BudgetProvider>(
        builder: (context, txProvider, budgetProvider, _) {
          if (txProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final recentTransactions = txProvider.allTransactions.take(5).toList();
          final totalIncome = txProvider.totalIncome;
          final totalExpenses = txProvider.totalExpenses;
          final balance = txProvider.balance;
          final budget = budgetProvider.currentBudget;

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildGreeting(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: BalanceCard(
                        title: 'Total Income',
                        amount: totalIncome,
                        icon: Icons.arrow_upward_rounded,
                        color: AppColors.income,
                        gradient: AppColors.incomeGradient,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BalanceCard(
                        title: 'Total Expenses',
                        amount: totalExpenses,
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.expense,
                        gradient: AppColors.expenseGradient,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildBalanceCard(balance),
                const SizedBox(height: 20),
                if (budget != null) _buildBudgetIndicator(budget),
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  'Recent Transactions',
                  onSeeAll: () =>
                      Navigator.pushNamed(context, '/transactions'),
                ),
                const SizedBox(height: 8),
                if (recentTransactions.isEmpty)
                  _buildEmptyState()
                else
                  ...recentTransactions.map(
                    (tx) => TransactionTile(
                      transaction: tx,
                      onTap: () => _editTransaction(tx),
                      onDelete: () => _deleteTransaction(tx),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final user = context.read<AuthProvider>().userProfile;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.displayName ?? 'User',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ],
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.person, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Current Balance',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            Helpers.formatCurrency(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBalanceChange(
                  Icons.arrow_upward, 'Income', 'INR', Colors.greenAccent),
              const SizedBox(width: 24),
              _buildBalanceChange(
                  Icons.arrow_downward, 'Expenses', 'INR', Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceChange(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  Widget _buildBudgetIndicator(Budget budget) {
    final percentage = budget.percentageUsed.clamp(0, 100);
    final isWarning = budget.isWarningZone;
    final isExceeded = budget.isLimitReached;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExceeded
            ? AppColors.danger.withOpacity(0.1)
            : isWarning
                ? AppColors.warning.withOpacity(0.1)
                : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExceeded
              ? AppColors.danger.withOpacity(0.3)
              : isWarning
                  ? AppColors.warning.withOpacity(0.3)
                  : AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Budget',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${percentage.round()}% used',
                style: TextStyle(
                  color: isExceeded
                      ? AppColors.danger
                      : isWarning
                          ? AppColors.warning
                          : AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded
                    ? AppColors.danger
                    : isWarning
                        ? AppColors.warning
                        : AppColors.success,
              ),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${Helpers.formatCurrency(budget.currentSpending)} / ${Helpers.formatCurrency(budget.monthlyLimit)}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (isExceeded)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.danger),
                  SizedBox(width: 4),
                  Text(
                    'Budget limit reached!',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.add_circle_outline,
          label: 'Add Income',
          color: AppColors.income,
          onTap: () => Navigator.pushNamed(context, '/add-transaction',
              arguments: TransactionType.credit),
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.remove_circle_outline,
          label: 'Add Expense',
          color: AppColors.expense,
          onTap: () => Navigator.pushNamed(context, '/add-transaction',
              arguments: TransactionType.debit),
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          icon: Icons.pie_chart_outline,
          label: 'Analytics',
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, '/analytics'),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add your first transaction',
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _editTransaction(Transaction tx) {
    Navigator.pushNamed(context, '/add-transaction', arguments: tx);
  }

  void _deleteTransaction(Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Delete "${tx.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<TransactionProvider>().deleteTransaction(tx.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
