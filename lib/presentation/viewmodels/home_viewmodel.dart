import 'package:flutter/foundation.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';

/// ViewModel for the Home screen.
///
/// Manages the list of expenses, filtering by month, and CRUD operations.
/// Uses [ChangeNotifier] for reactive state updates via Provider.
class HomeViewModel extends ChangeNotifier {
  final ExpenseRepository _repository;

  HomeViewModel(this._repository);

  // ─── State ───
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedMonth = DateTime.now();
  double _monthlyTotal = 0;

  // ─── Getters ───
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedMonth => _selectedMonth;
  double get monthlyTotal => _monthlyTotal;
  bool get isEmpty => _expenses.isEmpty && !_isLoading;

  /// Load expenses for the currently selected month.
  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _repository.getExpensesByMonth(
        _selectedMonth.year,
        _selectedMonth.month,
      );
      _monthlyTotal = await _repository.getMonthlyTotal(
        _selectedMonth.year,
        _selectedMonth.month,
      );
    } catch (e) {
      _errorMessage = 'Failed to load expenses: $e';
      _expenses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change the selected month and reload data.
  Future<void> selectMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month);
    await loadExpenses();
  }

  /// Navigate to the previous month.
  Future<void> previousMonth() async {
    await selectMonth(
      DateTime(_selectedMonth.year, _selectedMonth.month - 1),
    );
  }

  /// Navigate to the next month.
  Future<void> nextMonth() async {
    await selectMonth(
      DateTime(_selectedMonth.year, _selectedMonth.month + 1),
    );
  }

  /// Delete an expense by ID and refresh the list.
  Future<void> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      await loadExpenses();
    } catch (e) {
      _errorMessage = 'Failed to delete expense: $e';
      notifyListeners();
    }
  }

  /// Add a new expense and refresh the list.
  Future<void> addExpense(Expense expense) async {
    try {
      await _repository.insertExpense(expense);
      // Switch to the month of the new expense so user sees it
      _selectedMonth = DateTime(expense.date.year, expense.date.month);
      await loadExpenses();
    } catch (e) {
      _errorMessage = 'Failed to add expense: $e';
      notifyListeners();
    }
  }
}
