import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/local_database.dart';
import '../models/expense_model.dart';

/// Concrete implementation of [ExpenseRepository] backed by SQLite.
///
/// All database operations are performed through [LocalDatabase].
class ExpenseRepositoryImpl implements ExpenseRepository {
  final LocalDatabase _localDatabase;

  ExpenseRepositoryImpl(this._localDatabase);

  Database get _db => _localDatabase.database;
  String get _table => AppConstants.expenseTable;

  @override
  Future<List<Expense>> getAllExpenses() async {
    final maps = await _db.query(
      _table,
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((m) => ExpenseModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<List<Expense>> getExpensesByMonth(int year, int month) async {
    // Build start/end date strings for the month range
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final maps = await _db.query(
      _table,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
    return maps.map((m) => ExpenseModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<List<Expense>> getExpensesThisWeek() async {
    final now = DateTime.now();
    // Find Monday of current week
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfWeek
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    final maps = await _db.query(
      _table,
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        startOfWeek.toIso8601String(),
        endOfWeek.toIso8601String(),
      ],
      orderBy: 'date ASC',
    );
    return maps.map((m) => ExpenseModel.fromMap(m).toEntity()).toList();
  }

  @override
  Future<Map<String, double>> getCategoryTotals(int year, int month) async {
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await _db.rawQuery('''
      SELECT category, SUM(total_amount) as total
      FROM $_table
      WHERE date >= ? AND date <= ?
      GROUP BY category
      ORDER BY total DESC
    ''', [startDate, endDate]);

    final Map<String, double> totals = {};
    for (final row in result) {
      final category = row['category'] as String;
      final total = (row['total'] as num).toDouble();
      totals[category] = total;
    }
    return totals;
  }

  @override
  Future<Map<int, double>> getWeeklyDailyTotals() async {
    final expenses = await getExpensesThisWeek();

    // Initialize all 7 days (1=Monday ... 7=Sunday) to 0
    final Map<int, double> dailyTotals = {
      for (int i = 1; i <= 7; i++) i: 0.0,
    };

    for (final expense in expenses) {
      final weekday = expense.date.weekday; // 1=Mon, 7=Sun
      dailyTotals[weekday] = (dailyTotals[weekday] ?? 0) + expense.totalAmount;
    }
    return dailyTotals;
  }

  @override
  Future<int> insertExpense(Expense expense) async {
    final model = ExpenseModel.fromEntity(expense);
    return await _db.insert(
      _table,
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) {
      throw ArgumentError('Cannot update an expense without an ID.');
    }
    final model = ExpenseModel.fromEntity(expense);
    await _db.update(
      _table,
      model.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  @override
  Future<void> deleteExpense(int id) async {
    await _db.delete(
      _table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<double> getMonthlyTotal(int year, int month) async {
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await _db.rawQuery('''
      SELECT COALESCE(SUM(total_amount), 0) as total
      FROM $_table
      WHERE date >= ? AND date <= ?
    ''', [startDate, endDate]);

    return (result.first['total'] as num).toDouble();
  }
}
