import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'expense_model.dart';
import 'finora_theme.dart';

class AppCategory {
  const AppCategory(this.name, this.icon, this.color, this.background);

  final String name;
  final IconData icon;
  final Color color;
  final Color background;
}

const defaultCategories = [
  AppCategory(
    'Food',
    Icons.restaurant_rounded,
    Color(0xFFF97316),
    Color(0xFFFFE7D6),
  ),
  AppCategory(
    'Transport',
    Icons.directions_car_filled_rounded,
    Color(0xFF3B82F6),
    paleBlue,
  ),
  AppCategory(
    'Shopping',
    Icons.shopping_bag_rounded,
    Color(0xFFA855F7),
    Color(0xFFF3E8FF),
  ),
  AppCategory('Bills', Icons.receipt_long_rounded, amber, Color(0xFFFFF4D6)),
  AppCategory(
    'Education',
    Icons.school_rounded,
    Color(0xFF6366F1),
    Color(0xFFE0E7FF),
  ),
  AppCategory('Health', Icons.favorite_rounded, coral, Color(0xFFFEE2E2)),
  AppCategory(
    'Entertainment',
    Icons.movie_rounded,
    Color(0xFFEC4899),
    Color(0xFFFCE7F3),
  ),
  AppCategory(
    'Other',
    Icons.more_horiz_rounded,
    Color(0xFF64748B),
    Color(0xFFE2E8F0),
  ),
];

/// Parses a stored amount such as `LKR 1,250.00` or `Rs. 860.00`.
double? parseAmount(String value) => double.tryParse(
  value.replaceFirst(RegExp(r'^(LKR|Rs\.)\s*'), '').replaceAll(',', '').trim(),
);

bool sameCategory(String a, String b) => a.toLowerCase() == b.toLowerCase();

/// Single source of truth for everything the screens show and edit.
class FinoraStore extends ChangeNotifier {
  FinoraStore({List<ExpenseItem>? expenses})
    : expenses = expenses ?? <ExpenseItem>[];

  final List<ExpenseItem> expenses;
  final List<AppCategory> categories = List.of(defaultCategories);
  final Map<String, double> categoryLimits = {};
  double monthlyBudget = 75000;
  double savingsGoal = 150000;
  String name = 'Alex Morgan';
  String email = 'alex.morgan@email.com';

  /// Profile picture bytes; null falls back to the user's initials.
  Uint8List? photo;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  /// Call after mutating [expenses] directly so listeners rebuild.
  void touch() => notifyListeners();

  void addExpense(ExpenseItem item) {
    expenses.insert(0, item);
    notifyListeners();
  }

  void replaceExpense(ExpenseItem old, ExpenseItem updated) {
    final index = expenses.indexOf(old);
    if (index < 0) return;
    expenses[index] = updated;
    notifyListeners();
  }

  void removeExpense(ExpenseItem item) {
    expenses.remove(item);
    notifyListeners();
  }

  void replaceAllExpenses(Iterable<ExpenseItem> items) {
    expenses
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  void setProfile(String newName, String newEmail) {
    name = newName;
    email = newEmail;
    notifyListeners();
  }

  void setPhoto(Uint8List? bytes) {
    photo = bytes;
    notifyListeners();
  }

  void setMonthlyBudget(double value) {
    monthlyBudget = value;
    notifyListeners();
  }

  void setSavingsGoal(double value) {
    savingsGoal = value;
    notifyListeners();
  }

  void setCategoryLimit(String category, double? limit) {
    categoryLimits.removeWhere((key, _) => sameCategory(key, category));
    if (limit != null) categoryLimits[category] = limit;
    notifyListeners();
  }

  double? limitFor(String category) {
    for (final entry in categoryLimits.entries) {
      if (sameCategory(entry.key, category)) return entry.value;
    }
    return null;
  }

  AppCategory? categoryNamed(String name) {
    for (final category in categories) {
      if (sameCategory(category.name, name)) return category;
    }
    return null;
  }

  void addCategory(AppCategory category) {
    categories.add(category);
    notifyListeners();
  }

  /// Replaces [old]; expenses and limits follow a rename so totals stay live.
  void updateCategory(AppCategory old, AppCategory updated) {
    final index = categories.indexOf(old);
    if (index < 0) return;
    categories[index] = updated;
    if (!sameCategory(old.name, updated.name)) {
      for (var i = 0; i < expenses.length; i++) {
        final e = expenses[i];
        if (sameCategory(e.category, old.name)) {
          expenses[i] = e.copyWith(category: updated.name);
        }
      }
      final limit = limitFor(old.name);
      categoryLimits.removeWhere((key, _) => sameCategory(key, old.name));
      if (limit != null) categoryLimits[updated.name] = limit;
    }
    for (var i = 0; i < expenses.length; i++) {
      final e = expenses[i];
      if (sameCategory(e.category, updated.name)) {
        expenses[i] = e.copyWith(
          icon: updated.icon,
          iconColor: updated.color,
          background: updated.background,
        );
      }
    }
    notifyListeners();
  }

  bool hasExpensesIn(String category) =>
      expenses.any((e) => sameCategory(e.category, category));

  void removeCategory(AppCategory category) {
    categories.remove(category);
    categoryLimits.removeWhere((key, _) => sameCategory(key, category.name));
    notifyListeners();
  }
}

class FinoraScope extends InheritedNotifier<FinoraStore> {
  const FinoraScope({
    super.key,
    required FinoraStore store,
    required super.child,
  }) : super(notifier: store);

  static FinoraStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FinoraScope>()?.notifier;

  static FinoraStore of(BuildContext context) {
    final store = maybeOf(context);
    assert(store != null, 'No FinoraScope found above this context');
    return store!;
  }
}
