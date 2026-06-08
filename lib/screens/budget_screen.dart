import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/budget_provider.dart';
import '../models/budget.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _limitController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  void _loadBudget() {
    final userId = context.read<AuthProvider>().userId;
    context.read<BudgetProvider>().loadBudget(userId);
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  void _startEditing() {
    final budget = context.read<BudgetProvider>().currentBudget;
    _limitController.text =
        budget?.monthlyLimit.toStringAsFixed(0) ?? '';
    setState(() => _isEditing = true);
  }

  Future<void> _saveBudget() async {
    final text = _limitController.text.trim();
    if (text.isEmpty) return;

    final limit = double.tryParse(text);
    if (limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    final userId = context.read<AuthProvider>().userId;
    final now = DateTime.now();
    final success = await context.read<BudgetProvider>().setBudget(
          userId: userId,
          monthlyLimit: limit,
          month: now.month,
          year: now.year,
        );

    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: Consumer<BudgetProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final budget = provider.currentBudget;
          final now = DateTime.now();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCurrentMonthCard(now),
              const SizedBox(height: 20),
              if (_isEditing)
                _buildEditForm()
              else
                _buildBudgetStatus(budget),
              const SizedBox(height: 20),
              if (budget != null) _buildSpendingDetails(budget),
              const SizedBox(height: 20),
              _buildTips(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentMonthCard(DateTime now) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Budget',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            Helpers.formatMonthYear(now),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Set a monthly spending limit to stay on track',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStatus(Budget? budget) {
    if (budget == null) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.monetization_on_outlined,
                    size: 48,
                    color: AppColors.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 12),
                const Text(
                  'No budget set',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set a monthly limit to control your spending',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _startEditing,
            icon: const Icon(Icons.add),
            label: const Text('Set Budget'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: budget.isLimitReached
                ? AppColors.danger.withOpacity(0.1)
                : budget.isWarningZone
                    ? AppColors.warning.withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monthly Limit',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    Helpers.formatCurrency(budget.monthlyLimit),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (budget.percentageUsed / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    budget.isLimitReached
                        ? AppColors.danger
                        : budget.isWarningZone
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                  minHeight: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${Helpers.formatCurrency(budget.currentSpending)} spent',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '${Helpers.formatCurrency(budget.remaining)} left',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
              if (budget.isLimitReached)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: AppColors.danger, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Budget limit reached!',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (budget.isWarningZone && !budget.isLimitReached)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Warning: ${budget.percentageUsed.toStringAsFixed(0)}% of budget used',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _startEditing,
          icon: const Icon(Icons.edit),
          label: const Text('Update Budget'),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Set Monthly Limit',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _limitController,
            decoration: const InputDecoration(
              labelText: 'Monthly Limit (₹)',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveBudget,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingDetails(Budget budget) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending Details',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _buildDetailRow(
              'Total Spent', Helpers.formatCurrency(budget.currentSpending)),
          const Divider(height: 24),
          _buildDetailRow(
              'Remaining', Helpers.formatCurrency(budget.remaining)),
          const Divider(height: 24),
          _buildDetailRow(
              'Usage',
              '${budget.percentageUsed.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline,
              color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budget Tips',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Try the 50/30/20 rule: 50% needs, 30% wants, 20% savings',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
