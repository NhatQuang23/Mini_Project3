import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/date_formatter.dart';
import '../viewmodels/stats_viewmodel.dart';
import '../widgets/donut_chart.dart';
import '../widgets/bar_chart.dart';

/// Statistics dashboard screen displaying spending visualizations.
///
/// Contains:
/// - Monthly category distribution donut chart
/// - Weekly spending bar chart
/// - Summary cards with key metrics
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: Consumer<StatsViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  Text(vm.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: vm.loadStats,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: vm.loadStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Month Header ───
                  Center(
                    child: Text(
                      DateFormatter.toMonthYear(vm.selectedMonth),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Category Distribution Card ───
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Spending by Category',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 20),
                          if (vm.categoryData.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Text('No data for this month'),
                            )
                          else
                            DonutChart(
                              data: vm.categoryData,
                              totalAmount: vm.monthlyTotal,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Weekly Spending Card ───
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'This Week\'s Spending',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 20),
                          if (vm.weeklyData.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Text('No data this week'),
                            )
                          else
                            WeeklyBarChart(
                              data: vm.weeklyData,
                              highlightIndex: DateTime.now().weekday - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Summary Cards ───
                  _SummaryCards(vm: vm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Summary metric cards showing quick stats.
class _SummaryCards extends StatelessWidget {
  final StatsViewModel vm;

  const _SummaryCards({required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalTransactions = vm.categoryData.length;
    final avgPerCategory = totalTransactions > 0
        ? vm.monthlyTotal / totalTransactions
        : 0.0;

    // Find highest spending category
    String topCategory = 'N/A';
    if (vm.categoryData.isNotEmpty) {
      vm.categoryData.sort((a, b) => b.amount.compareTo(a.amount));
      topCategory = vm.categoryData.first.category;
    }

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Top Category',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topCategory,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.category,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Categories',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalTransactions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
