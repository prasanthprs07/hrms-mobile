import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    final userId = context.read<AuthProvider>().userId;
    if (userId.isNotEmpty) {
      context.read<TransactionProvider>().loadTransactions(userId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilters) _buildFilters(),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = provider.transactions;

                if (transactions.isEmpty) {
                  return _buildEmptyState(provider);
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadTransactions(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return TransactionTile(
                        transaction: tx,
                        onTap: () => _editTransaction(tx),
                        onDelete: () => _deleteTransaction(tx),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search transactions...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<TransactionProvider>().search('');
                  },
                )
              : null,
        ),
        onChanged: (query) {
          context.read<TransactionProvider>().search(query);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildFilters() {
    final provider = context.watch<TransactionProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildFilterChip(
                label: 'All',
                selected: provider.filterType == null && provider.filterCategory == null,
                onSelected: () => provider.clearFilters(),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Credit',
                selected: provider.filterType == TransactionType.credit,
                onSelected: () => provider.filterByType(TransactionType.credit),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Debit',
                selected: provider.filterType == TransactionType.debit,
                onSelected: () => provider.filterByType(TransactionType.debit),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: TransactionCategory.values.map((cat) {
              return _buildFilterChip(
                label: cat.label,
                selected: provider.filterCategory == cat,
                onSelected: () {
                  provider.filterByCategory(
                    provider.filterCategory == cat ? null : cat,
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary.withOpacity(0.15),
      checkmarkColor: AppColors.primary,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEmptyState(TransactionProvider provider) {
    final hasFilters = provider.searchQuery.isNotEmpty ||
        provider.filterType != null ||
        provider.filterCategory != null;

    if (hasFilters) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64,
                color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No matching transactions',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                provider.clearFilters();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64,
              color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No transactions yet',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/add-transaction'),
            icon: const Icon(Icons.add),
            label: const Text('Add Transaction'),
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
        title: const Text('Delete'),
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
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
