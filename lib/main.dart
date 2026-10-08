import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'data/datasources/local_database.dart';
import 'data/repositories/expense_repository_impl.dart';
import 'domain/repositories/expense_repository.dart';
import 'presentation/viewmodels/home_viewmodel.dart';
import 'presentation/viewmodels/stats_viewmodel.dart';

void main() async {
  // Ensure Flutter bindings are initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the local SQLite database
  final database = LocalDatabase();
  await database.initialize();

  // Create repository with the initialized database
  final ExpenseRepository repository = ExpenseRepositoryImpl(database);

  runApp(
    /// Wrap the app with MultiProvider to inject dependencies
    /// down the widget tree using the Provider pattern.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => HomeViewModel(repository)..loadExpenses(),
        ),
        ChangeNotifierProvider(
          create: (_) => StatsViewModel(repository)..loadStats(),
        ),
      ],
      child: const ExpenseTrackerApp(),
    ),
  );
}
