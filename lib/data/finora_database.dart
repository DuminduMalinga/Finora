import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../screens/expense_model.dart';
import '../screens/finora_store.dart';

/// Everything saved for the user, as read at start-up.
class StoredData {
  const StoredData({
    this.name,
    this.email,
    this.photo,
    this.monthlyBudget,
    this.savingsGoal,
    this.categories,
    this.limits = const {},
    this.expenses = const [],
    this.settings = const {},
  });

  final String? name;
  final String? email;
  final Uint8List? photo;
  final double? monthlyBudget;
  final double? savingsGoal;

  /// Null until the user has saved a category list (so defaults apply).
  final List<AppCategory>? categories;
  final Map<String, double> limits;
  final List<ExpenseItem> expenses;
  final Map<String, String> settings;
}

/// SQLite storage for the user's profile, settings, categories, budgets and
/// expenses. All writes are small and awaited in order by sqflite.
class FinoraDatabase {
  FinoraDatabase._(this._db);

  final Database _db;

  static const _categoriesSavedKey = 'categories_saved';

  /// Opens (and creates, on first run) the database. Pass [path] to choose a
  /// location, or `inMemoryDatabasePath` in tests.
  static Future<FinoraDatabase> open({
    String? path,
    DatabaseFactory? factory,
  }) async {
    final f = factory ?? databaseFactory;
    final location = path ?? p.join(await f.getDatabasesPath(), 'finora.db');
    final db = await f.openDatabase(
      location,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE user_profile (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              name TEXT NOT NULL,
              email TEXT NOT NULL,
              photo BLOB,
              monthly_budget REAL NOT NULL,
              savings_goal REAL NOT NULL
            )''');
          await db.execute('''
            CREATE TABLE settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )''');
          await db.execute('''
            CREATE TABLE categories (
              name TEXT PRIMARY KEY COLLATE NOCASE,
              icon_code INTEGER NOT NULL,
              color INTEGER NOT NULL,
              background INTEGER NOT NULL,
              position INTEGER NOT NULL,
              monthly_limit REAL
            )''');
          await db.execute('''
            CREATE TABLE expenses (
              id INTEGER PRIMARY KEY,
              title TEXT NOT NULL,
              category TEXT NOT NULL,
              amount TEXT NOT NULL,
              date TEXT NOT NULL,
              icon_code INTEGER NOT NULL,
              icon_color INTEGER NOT NULL,
              background INTEGER NOT NULL,
              notes TEXT NOT NULL,
              sort_key INTEGER NOT NULL
            )''');
        },
      ),
    );
    return FinoraDatabase._(db);
  }

  Future<void> close() => _db.close();

  Future<StoredData> load() async {
    final profile = await _db.query('user_profile', limit: 1);
    final settingRows = await _db.query('settings');
    final settings = {
      for (final row in settingRows)
        row['key'] as String: row['value'] as String,
    };

    List<AppCategory>? categories;
    final limits = <String, double>{};
    if (settings[_categoriesSavedKey] == '1') {
      final rows = await _db.query('categories', orderBy: 'position ASC');
      categories = [
        for (final row in rows)
          AppCategory(
            row['name'] as String,
            iconFromCode(row['icon_code'] as int),
            Color(row['color'] as int),
            Color(row['background'] as int),
          ),
      ];
      for (final row in rows) {
        final limit = row['monthly_limit'];
        if (limit != null) {
          limits[row['name'] as String] = (limit as num).toDouble();
        }
      }
    }

    final expenseRows = await _db.query('expenses', orderBy: 'sort_key DESC');
    final expenses = [
      for (final row in expenseRows)
        ExpenseItem(
          id: row['id'] as int,
          title: row['title'] as String,
          category: row['category'] as String,
          amount: row['amount'] as String,
          date: row['date'] as String,
          icon: iconFromCode(row['icon_code'] as int),
          iconColor: Color(row['icon_color'] as int),
          background: Color(row['background'] as int),
          notes: row['notes'] as String,
        ),
    ];

    final user = profile.isEmpty ? null : profile.first;
    return StoredData(
      name: user?['name'] as String?,
      email: user?['email'] as String?,
      photo: user?['photo'] as Uint8List?,
      monthlyBudget: (user?['monthly_budget'] as num?)?.toDouble(),
      savingsGoal: (user?['savings_goal'] as num?)?.toDouble(),
      categories: categories,
      limits: limits,
      expenses: expenses,
      settings: settings,
    );
  }

  Future<Map<String, String>> loadSettings() async => {
    for (final row in await _db.query('settings'))
      row['key'] as String: row['value'] as String,
  };

  // --- Profile -----------------------------------------------------------

  Future<void> saveProfile({
    required String name,
    required String email,
    required Uint8List? photo,
    required double monthlyBudget,
    required double savingsGoal,
  }) => _db.insert('user_profile', {
    'id': 1,
    'name': name,
    'email': email,
    'photo': photo,
    'monthly_budget': monthlyBudget,
    'savings_goal': savingsGoal,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  // --- Settings ----------------------------------------------------------

  Future<void> saveSettings(Map<String, String> values) async {
    final batch = _db.batch();
    values.forEach((key, value) {
      batch.insert('settings', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await batch.commit(noResult: true);
  }

  // --- Categories and their monthly limits ------------------------------

  Future<void> saveCategories(
    List<AppCategory> categories,
    Map<String, double> limits,
  ) => _db.transaction((txn) async {
    await txn.delete('categories');
    for (var i = 0; i < categories.length; i++) {
      final c = categories[i];
      double? limit;
      for (final entry in limits.entries) {
        if (sameCategory(entry.key, c.name)) limit = entry.value;
      }
      await txn.insert('categories', {
        'name': c.name,
        'icon_code': c.icon.codePoint,
        'color': c.color.toARGB32(),
        'background': c.background.toARGB32(),
        'position': i,
        'monthly_limit': limit,
      });
    }
    await txn.insert('settings', {
      'key': _categoriesSavedKey,
      'value': '1',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  });

  // --- Expenses ----------------------------------------------------------

  Map<String, Object?> _expenseRow(ExpenseItem e, int sortKey) => {
    'id': e.id,
    'title': e.title,
    'category': e.category,
    'amount': e.amount,
    'date': e.date,
    'icon_code': e.icon.codePoint,
    'icon_color': e.iconColor.toARGB32(),
    'background': e.background.toARGB32(),
    'notes': e.notes,
    'sort_key': sortKey,
  };

  /// Adds a new expense above all existing ones.
  Future<void> insertExpense(ExpenseItem e) async {
    final top = Sqflite.firstIntValue(
      await _db.rawQuery('SELECT COALESCE(MAX(sort_key), 0) FROM expenses'),
    )!;
    await _db.insert(
      'expenses',
      _expenseRow(e, top + 1),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Rewrites one expense in place, keeping its position in the list.
  Future<void> updateExpense(ExpenseItem e) async {
    final row = _expenseRow(e, 0)..remove('sort_key');
    final changed = await _db.update(
      'expenses',
      row,
      where: 'id = ?',
      whereArgs: [e.id],
    );
    if (changed == 0) await insertExpense(e);
  }

  Future<void> deleteExpense(int id) =>
      _db.delete('expenses', where: 'id = ?', whereArgs: [id]);

  /// Replaces every expense, keeping the order of [items] (newest first).
  Future<void> replaceExpenses(List<ExpenseItem> items) =>
      _db.transaction((txn) async {
        await txn.delete('expenses');
        for (var i = 0; i < items.length; i++) {
          await txn.insert('expenses', _expenseRow(items[i], items.length - i));
        }
      });
}
