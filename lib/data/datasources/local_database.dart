import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

/// Manages the SQLite database lifecycle: creation, migration, and access.
///
/// Uses the singleton pattern internally to ensure a single database
/// connection is reused throughout the app.
class LocalDatabase {
  Database? _database;

  /// Returns the active database instance.
  /// Throws if [initialize] has not been called yet.
  Database get database {
    if (_database == null) {
      throw StateError(
        'Database not initialized. Call initialize() before accessing the database.',
      );
    }
    return _database!;
  }

  /// Initialize (open or create) the SQLite database.
  ///
  /// This must be called once during app startup, before any DB operations.
  Future<void> initialize() async {
    if (_database != null) return; // Already initialized

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    _database = await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creates the expenses table on first run.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.expenseTable} (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant_name TEXT    NOT NULL DEFAULT 'Unknown',
        total_amount  REAL    NOT NULL,
        currency      TEXT    NOT NULL DEFAULT 'VND',
        category      TEXT    NOT NULL DEFAULT 'Food',
        date          TEXT    NOT NULL,
        notes         TEXT,
        image_path    TEXT,
        raw_ocr_text  TEXT,
        created_at    TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Index on date for fast month/week queries
    await db.execute('''
      CREATE INDEX idx_expense_date 
      ON ${AppConstants.expenseTable} (date)
    ''');

    // Index on category for aggregation queries
    await db.execute('''
      CREATE INDEX idx_expense_category 
      ON ${AppConstants.expenseTable} (category)
    ''');
  }

  /// Handle schema migrations for future versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here:
    // if (oldVersion < 2) { ... }
  }

  /// Close the database connection. Call during app teardown if needed.
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
