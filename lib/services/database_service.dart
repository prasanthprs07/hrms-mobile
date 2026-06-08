import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../utils/constants.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        smsSource TEXT,
        userId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monthlyLimit REAL NOT NULL,
        currentSpending REAL NOT NULL DEFAULT 0,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        userId TEXT NOT NULL,
        notifyOnLimit INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_date ON transactions(date)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_userId ON transactions(userId)
    ''');

    await db.execute('''
      CREATE INDEX idx_budgets_month_year ON budgets(month, year)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Transaction>> getTransactions(String userId) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getTransactionsByMonth(
      String userId, int month, int year) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = month == 12
        ? '${year + 1}-01-01'
        : '$year-${(month + 1).toString().padLeft(2, '0')}-01';

    final maps = await db.query(
      'transactions',
      where: 'userId = ? AND date >= ? AND date < ?',
      whereArgs: [userId, startDate, endDate],
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> searchTransactions(
      String userId, String query) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where:
          'userId = ? AND (title LIKE ? OR note LIKE ? OR category LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%', '%$query%'],
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getTransactionsByType(
      String userId, TransactionType type) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'userId = ? AND type = ?',
      whereArgs: [userId, type.name],
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<List<Transaction>> getTransactionsByCategory(
      String userId, TransactionCategory category) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'userId = ? AND category = ?',
      whereArgs: [userId, category.name],
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<double> getTotalIncome(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE userId = ? AND type = ?',
      [userId, TransactionType.credit.name],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getTotalExpenses(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE userId = ? AND type = ?',
      [userId, TransactionType.debit.name],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getMonthlyIncome(String userId, int month, int year) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = month == 12
        ? '${year + 1}-01-01'
        : '$year-${(month + 1).toString().padLeft(2, '0')}-01';
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE userId = ? AND type = ? AND date >= ? AND date < ?',
      [userId, TransactionType.credit.name, startDate, endDate],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getMonthlyExpenses(String userId, int month, int year) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = month == 12
        ? '${year + 1}-01-01'
        : '$year-${(month + 1).toString().padLeft(2, '0')}-01';
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE userId = ? AND type = ? AND date >= ? AND date < ?',
      [userId, TransactionType.debit.name, startDate, endDate],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<TransactionCategory, double>> getExpensesByCategory(
      String userId, int month, int year) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = month == 12
        ? '${year + 1}-01-01'
        : '$year-${(month + 1).toString().padLeft(2, '0')}-01';

    final result = await db.rawQuery(
      'SELECT category, COALESCE(SUM(amount), 0) as total FROM transactions WHERE userId = ? AND type = ? AND date >= ? AND date < ? GROUP BY category',
      [userId, TransactionType.debit.name, startDate, endDate],
    );

    final Map<TransactionCategory, double> categoryData = {};
    for (final category in TransactionCategory.values) {
      categoryData[category] = 0.0;
    }
    for (final row in result) {
      final cat = TransactionCategory.values.byName(row['category'] as String);
      categoryData[cat] = (row['total'] as num).toDouble();
    }
    return categoryData;
  }

  Future<List<MapEntry<String, double>>> getMonthlyTrend(
      String userId, int year) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT substr(date, 1, 7) as month, type, SUM(amount) as total FROM transactions WHERE userId = ? AND substr(date, 1, 4) = ? GROUP BY month, type ORDER BY month",
      [userId, year.toString()],
    );

    final Map<String, double> incomeMap = {};
    final Map<String, double> expenseMap = {};

    for (final row in result) {
      final month = row['month'] as String;
      final type = row['type'] as String;
      final total = (row['total'] as num).toDouble();
      if (type == TransactionType.credit.name) {
        incomeMap[month] = total;
      } else {
        expenseMap[month] = total;
      }
    }

    final List<MapEntry<String, double>> trend = [];
    for (int i = 1; i <= 12; i++) {
      final key = '$year-${i.toString().padLeft(2, '0')}';
      trend.add(MapEntry(key, expenseMap[key] ?? 0.0));
    }
    return trend;
  }

  Future<int> insertOrUpdateBudget(Budget budget) async {
    final db = await database;
    final existing = await db.query(
      'budgets',
      where: 'userId = ? AND month = ? AND year = ?',
      whereArgs: [budget.userId, budget.month, budget.year],
    );

    if (existing.isNotEmpty) {
      return await db.update(
        'budgets',
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      return await db.insert('budgets', budget.toMap());
    }
  }

  Future<Budget?> getBudget(String userId, int month, int year) async {
    final db = await database;
    final result = await db.query(
      'budgets',
      where: 'userId = ? AND month = ? AND year = ?',
      whereArgs: [userId, month, year],
    );

    if (result.isNotEmpty) {
      final budget = Budget.fromMap(result.first);
      final expenses = await getMonthlyExpenses(userId, month, year);
      return budget.copyWith(currentSpending: expenses);
    }
    return null;
  }

  Future<void> updateBudgetSpending(String userId, int month, int year) async {
    final db = await database;
    final expenses = await getMonthlyExpenses(userId, month, year);

    await db.rawUpdate(
      'UPDATE budgets SET currentSpending = ? WHERE userId = ? AND month = ? AND year = ?',
      [expenses, userId, month, year],
    );
  }

  Future<int> deleteAllTransactions(String userId) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }
}
