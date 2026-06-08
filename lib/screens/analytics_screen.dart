import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final DatabaseService _db = DatabaseService();
  Map<TransactionCategory, double> _categoryData = {};
  List<MapEntry<String, double>> _monthlyTrend = [];
  double _totalExpenses = 0;
  bool _isLoading = true;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userId = context.read<AuthProvider>().userId;
    final now = DateTime.now();

    _categoryData = await _db.getExpensesByCategory(
        userId, now.month, now.year);
    _totalExpenses = _categoryData.values.fold(0.0, (a, b) => a + b);
    _monthlyTrend = await _db.getMonthlyTrend(userId, _selectedYear);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPieChartSection(),
                const SizedBox(height: 24),
                _buildTrendChartSection(),
              ],
            ),
    );
  }

  Widget _buildPieChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Expenses by Category',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            Helpers.formatMonthYear(DateTime.now()),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: _totalExpenses > 0
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: _buildPieSections(),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            Helpers.formatCurrency(_totalExpenses),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : const Center(
                    child: Text('No expense data',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
          ),
          const SizedBox(height: 16),
          ..._buildLegend(),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final colors = AppConstants.categoryColors;
    return _categoryData.entries.where((e) => e.value > 0).map((entry) {
      final index = TransactionCategory.values.indexOf(entry.key) % colors.length;
      final percentage =
          ((entry.value / _totalExpenses) * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: colors[index],
        value: entry.value,
        title: '$percentage%',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildLegend() {
    final colors = AppConstants.categoryColors;
    final data = _categoryData.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return data.map((entry) {
      final index = TransactionCategory.values.indexOf(entry.key) % colors.length;
      final percentage =
          ((entry.value / _totalExpenses) * 100).toStringAsFixed(1);

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[index],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(entry.key.label,
                  style: const TextStyle(fontSize: 13)),
            ),
            Text(
              '${Helpers.formatCurrency(entry.value)} ($percentage%)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTrendChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Spending Trend',
                  style: Theme.of(context).textTheme.titleLarge),
              Text('$yearStr', style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: _monthlyTrend.any((e) => e.value > 0)
                ? BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final month = _monthlyTrend[group.x.toInt()].key;
                            final monthName = DateFormat('MMM')
                                .format(DateTime.parse('$month-01'));
                            return BarTooltipItem(
                              '$monthName\n${Helpers.formatCurrency(rod.toY)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < _monthlyTrend.length) {
                                final month = _monthlyTrend[value.toInt()].key;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat('MMM')
                                        .format(DateTime.parse('$month-01')),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                '₹${(value / 1000).toInt()}k',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getMaxY() / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: AppColors.borderLight,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _buildBarGroups(),
                    ),
                  )
                : const Center(
                    child: Text('No data for this year',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return _monthlyTrend.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value,
            color: AppColors.primary,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY() {
    final max = _monthlyTrend.fold<double>(
        0, (prev, e) => e.value > prev ? e.value : prev);
    return max > 0 ? max * 1.3 : 1000;
  }

  String get yearStr => _selectedYear.toString();
}
