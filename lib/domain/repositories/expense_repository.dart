import '../entities/expense.dart';

/// Abstract repository interface for expense data operations.
/// Defined in the domain layer so it has no dependency on data sources.
abstract class ExpenseRepository {
  /// Retrieve all expenses, ordered by date descending.
  Future<List<Expense>> getAllExpenses();

  /// Retrieve expenses filtered by month and year.
  Future<List<Expense>> getExpensesByMonth(int year, int month);

  /// Retrieve expenses for the current week (Monday–Sunday).
  Future<List<Expense>> getExpensesThisWeek();

  /// Get total spending grouped by category for a given month.
  Future<Map<String, double>> getCategoryTotals(int year, int month);

  /// Get daily spending totals for the current week.
  Future<Map<int, double>> getWeeklyDailyTotals();

  /// Insert a new expense and return the generated ID.
  Future<int> insertExpense(Expense expense);

  /// Update an existing expense.
  Future<void> updateExpense(Expense expense);

  /// Delete an expense by ID.
  Future<void> deleteExpense(int id);

  /// Get the total amount spent in a given month.
  Future<double> getMonthlyTotal(int year, int month);
}
