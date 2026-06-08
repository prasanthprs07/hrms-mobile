import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = transaction.type == TransactionType.credit
        ? AppColors.income
        : AppColors.expense;
    final icon = transaction.type == TransactionType.credit
        ? Icons.arrow_downward
        : Icons.arrow_upward;

    final categoryColors = AppConstants.categoryColors;
    final catIndex =
        TransactionCategory.values.indexOf(transaction.category) %
            categoryColors.length;

    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return true;
      },
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: categoryColors[catIndex].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(transaction.category),
                    color: categoryColors[catIndex],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: transaction.type == TransactionType.credit
                                  ? AppColors.income.withOpacity(0.1)
                                  : AppColors.expense.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              transaction.type == TransactionType.credit
                                  ? 'Credit'
                                  : 'Debit',
                              style: TextStyle(
                                fontSize: 11,
                                color: transaction.type == TransactionType.credit
                                    ? AppColors.income
                                    : AppColors.expense,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            transaction.category.label,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            transaction.formattedDate,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '${transaction.type == TransactionType.credit ? '+' : '-'}${Helpers.formatCurrency(transaction.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(TransactionCategory cat) {
    switch (cat) {
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.travel:
        return Icons.directions_car;
      case TransactionCategory.shopping:
        return Icons.shopping_cart;
      case TransactionCategory.bills:
        return Icons.receipt_long;
      case TransactionCategory.medical:
        return Icons.local_hospital;
      case TransactionCategory.others:
        return Icons.more_horiz;
    }
  }
}
