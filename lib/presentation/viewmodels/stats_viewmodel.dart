import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/repositories/expense_repository.dart';
import '../widgets/donut_chart.dart';
import '../widgets/bar_chart.dart';

/// ViewModel for the Statistics screen.
///
/// Prepares chart data for the donut (category distribution) and
/// bar chart (weekly spending) visualizations.
class StatsViewModel extends ChangeNotifier {
  final ExpenseRepository _repository;

  StatsViewModel(this._repository);

  // ─── State ───
  List<DonutChartData> _categoryData = [];
  List<BarChartData> _weeklyData = [];
  double _monthlyTotal = 0;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedMonth = DateTime.now();

  // ─── Getters ───
  List<DonutChartData> get categoryData => _categoryData;
  List<BarChartData> get weeklyData => _weeklyData;
  double get monthlyTotal => _monthlyTotal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedMonth => _selectedMonth;

  /// Load both category and weekly chart data.
  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load category totals for the donut chart
      final categoryTotals = await _repository.getCategoryTotals(
        _selectedMonth.year,
        _selectedMonth.month,
      );

      _categoryData = categoryTotals.entries.map((entry) {
        return DonutChartData(
          category: entry.key,
          amount: entry.value,
          color: AppConstants.categoryColors[entry.key] ??
              Color(0xFF9E9E9E),
        );
      }).toList();

      _monthlyTotal = categoryTotals.values.fold(0, (sum, v) => sum + v);

      // Load weekly spending for the bar chart
      final weeklyTotals = await _repository.getWeeklyDailyTotals();
      const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      _weeklyData = List.generate(7, (i) {
        return BarChartData(
          label: dayLabels[i],
          value: weeklyTotals[i + 1] ?? 0.0,
        );
      });
    } catch (e) {
      _errorMessage = 'Failed to load statistics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change the selected month and reload stats.
  Future<void> selectMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month);
    await loadStats();
  }
}
