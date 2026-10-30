import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/finora_database.dart';
import '../data/notification_service.dart';
import 'budget_alerts.dart';
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

/// Every icon a category or expense can use. Icons are saved by code point
/// and restored from this list so release builds can still tree-shake the
/// icon font (a non-constant IconData would break that).
const knownIcons = <IconData>[
  Icons.restaurant_rounded,
  Icons.directions_car_filled_rounded,
  Icons.shopping_bag_rounded,
  Icons.receipt_long_rounded,
  Icons.school_rounded,
  Icons.favorite_rounded,
  Icons.movie_rounded,
  Icons.more_horiz_rounded,
  Icons.home_rounded,
  Icons.flight_rounded,
  Icons.pets_rounded,
  Icons.phone_android_rounded,
  Icons.fitness_center_rounded,
  Icons.local_cafe_rounded,
  Icons.card_giftcard_rounded,
  Icons.savings_rounded,
  Icons.shopping_cart_rounded,
  Icons.subscriptions_rounded,
];

IconData iconFromCode(int codePoint) => knownIcons.firstWhere(
  (icon) => icon.codePoint == codePoint,
  orElse: () => Icons.category_rounded,
);

/// Parses a stored amount such as `LKR 1,250.00` or `Rs. 860.00`.
double? parseAmount(String value) => double.tryParse(
  value.replaceFirst(RegExp(r'^(LKR|Rs\.)\s*'), '').replaceAll(',', '').trim(),
);

/// Formats an amount with thousands separators: `1250` -> `1,250.00`.
String formatAmount(double amount, {int decimals = 2}) {
  final parts = amount.toStringAsFixed(decimals).split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return parts.length > 1 ? '$whole.${parts.last}' : whole;
}

bool sameCategory(String a, String b) => a.toLowerCase() == b.toLowerCase();

/// Single source of truth for everything the screens show and edit.
class FinoraStore extends ChangeNotifier {
  FinoraStore({
    List<ExpenseItem>? expenses,
    this.onboarded = true,
    FinoraDatabase? database,
    SharedPreferences? prefs,
    this.notifier,
  }) : expenses = expenses ?? <ExpenseItem>[],
       _db = database,
       _prefs = prefs;

  /// SharedPreferences key remembering that the welcome flow has been done.
  static const onboardedKey = 'onboarded';

  final FinoraDatabase? _db;
  final SharedPreferences? _prefs;

  /// Shows alerts in the phone's notification tray (null = in-app only).
  final NotificationService? notifier;
  int _lastId = 0;

  /// False until the user finishes (or skips) the first-run setup.
  bool onboarded;

  final List<ExpenseItem> expenses;
  final List<AppCategory> categories = List.of(defaultCategories);
  final Map<String, double> categoryLimits = {};
  double monthlyBudget = 75000;
  double savingsGoal = 10000;
  String name = 'Guest';
  String email = '';

  /// Profile picture bytes; null falls back to the user's initials.
  Uint8List? photo;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  // --- Persistence -------------------------------------------------------

  /// Reads the saved profile, budgets, categories and expenses (and whether
  /// the welcome flow was already completed) into memory.
  Future<void> load() async {
    final prefs = _prefs;
    if (prefs != null) onboarded = prefs.getBool(onboardedKey) ?? false;
    final db = _db;
    if (db != null) {
      final data = await db.load();
      name = data.name ?? name;
      email = data.email ?? email;
      photo = data.photo;
      monthlyBudget = data.monthlyBudget ?? monthlyBudget;
      savingsGoal = data.savingsGoal ?? savingsGoal;
      if (data.categories != null) {
        categories
          ..clear()
          ..addAll(data.categories!);
      }
      categoryLimits
        ..clear()
        ..addAll(data.limits);
      expenses
        ..clear()
        ..addAll(data.expenses);
      for (final e in expenses) {
        if (e.id != null && e.id! > _lastId) _lastId = e.id!;
      }
      _restoreAnnounced(data.settings[_announcedKey]);
    }
    if (onboarded) _askForNotificationPermissionOnce();
    notifyListeners();
  }

  // --- System notifications ---------------------------------------------

  static const _announcedKey = 'announced_alerts';
  static const _askedKey = 'asked_notifications';
  final Set<String> _announced = {};
  String _announcedMonth = '';

  static String _monthKey(DateTime d) => '${d.year}-${d.month}';

  void _restoreAnnounced(String? stored) {
    _announced.clear();
    _announcedMonth = '';
    if (stored == null) return;
    try {
      final data = jsonDecode(stored) as Map<String, dynamic>;
      if (data['month'] == _monthKey(DateTime.now())) {
        _announcedMonth = data['month'] as String;
        _announced.addAll((data['keys'] as List).cast<String>());
      }
    } catch (_) {
      // Unreadable record: start fresh rather than fail.
    }
  }

  /// Sends a system notification for every budget alert that is new this
  /// month, and forgets alerts that no longer apply so they can fire again.
  void _announceNewAlerts({bool silent = false}) {
    final service = notifier;
    if (service == null || !onboarded) return;
    final now = DateTime.now();
    final month = _monthKey(now);
    var changed = false;
    if (_announcedMonth != month) {
      _announced.clear();
      _announcedMonth = month;
      changed = true;
    }
    final alerts = buildNotifications(
      expenses: expenses,
      monthlyBudget: monthlyBudget,
      limits: categoryLimits,
      now: now,
    );
    final current = {for (final a in alerts) a.key};
    final before = _announced.length;
    _announced.removeWhere((key) => !current.contains(key));
    if (_announced.length != before) changed = true;
    for (final alert in alerts) {
      if (_announced.add(alert.key)) {
        changed = true;
        if (silent) continue;
        unawaited(
          service.show(
            id: alert.key.hashCode & 0x7fffffff,
            title: alert.title,
            body: alert.message,
          ),
        );
      }
    }
    if (changed) {
      final record = jsonEncode({'month': month, 'keys': _announced.toList()});
      _save((db) => db.saveSettings({_announcedKey: record}));
    }
  }

  void _askForNotificationPermissionOnce() {
    final service = notifier;
    if (service == null) return;
    final prefs = _prefs;
    if (prefs != null) {
      if (prefs.getBool(_askedKey) ?? false) return;
      prefs.setBool(_askedKey, true);
    }
    unawaited(service.requestPermission());
  }

  Future<void> _writes = Future.value();

  /// Queues a database write: it runs after earlier writes, never blocks the
  /// UI, and a failure is logged instead of breaking later saves.
  void _save(Future<void> Function(FinoraDatabase db) job) {
    final db = _db;
    if (db == null) return;
    _writes = _writes.then((_) => job(db)).catchError((
      Object error,
      StackTrace stack,
    ) {
      debugPrint('Finora: could not save data ($error)');
    });
  }

  /// Completes once every queued database write has finished.
  Future<void> settled() => _writes;

  void _saveProfile() => _save(
    (db) => db.saveProfile(
      name: name,
      email: email,
      photo: photo,
      monthlyBudget: monthlyBudget,
      savingsGoal: savingsGoal,
    ),
  );

  void _saveCategories() => _save(
    (db) => db.saveCategories(List.of(categories), Map.of(categoryLimits)),
  );

  void _saveAllExpenses() =>
      _save((db) => db.replaceExpenses(List.of(expenses)));

  void _markOnboarded() {
    onboarded = true;
    _prefs?.setBool(onboardedKey, true);
  }

  int _newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _lastId = now > _lastId ? now : _lastId + 1;
    return _lastId;
  }

  ExpenseItem _withId(ExpenseItem item) =>
      item.id == null ? item.copyWith(id: _newId()) : item;

  // --- Expenses ----------------------------------------------------------

  void addExpense(ExpenseItem item) {
    final saved = _withId(item);
    expenses.insert(0, saved);
    _save((db) => db.insertExpense(saved));
    _announceNewAlerts();
    notifyListeners();
  }

  void replaceExpense(ExpenseItem old, ExpenseItem updated) {
    final index = expenses.indexOf(old);
    if (index < 0) return;
    final saved = updated.copyWith(id: old.id ?? updated.id ?? _newId());
    expenses[index] = saved;
    _save((db) => db.updateExpense(saved));
    _announceNewAlerts();
    notifyListeners();
  }

  void removeExpense(ExpenseItem item) {
    expenses.remove(item);
    final id = item.id;
    if (id != null) _save((db) => db.deleteExpense(id));
    _announceNewAlerts();
    notifyListeners();
  }

  /// Puts a deleted expense back where it was (the Undo after a delete).
  void restoreExpense(ExpenseItem item, int index) {
    expenses.insert(index.clamp(0, expenses.length), item);
    _saveAllExpenses();
    _announceNewAlerts();
    notifyListeners();
  }

  // --- Setup, profile and budget ----------------------------------------

  /// Applies the first-run setup: name, budget, optional savings goal, chosen
  /// categories and their limits.
  void completeSetup({
    String? name,
    String? email,
    required double budget,
    double? savingsGoal,
    required List<AppCategory> categories,
    required Map<String, double> limits,
  }) {
    if (name != null && name.trim().isNotEmpty) this.name = name.trim();
    this.email = (email ?? this.email).trim();
    monthlyBudget = budget;
    if (savingsGoal != null) this.savingsGoal = savingsGoal;
    this.categories
      ..clear()
      ..addAll(categories);
    categoryLimits
      ..clear()
      ..addAll(limits);
    _markOnboarded();
    _saveProfile();
    _saveCategories();
    _askForNotificationPermissionOnce();
    _announceNewAlerts();
    notifyListeners();
  }

  /// Leaves the default categories and budget in place.
  void skipSetup() {
    _markOnboarded();
    _saveProfile();
    _saveCategories();
    _askForNotificationPermissionOnce();
    notifyListeners();
  }

  void setProfile(String newName, String newEmail) {
    name = newName;
    email = newEmail;
    _saveProfile();
    notifyListeners();
  }

  void setPhoto(Uint8List? bytes) {
    photo = bytes;
    _saveProfile();
    notifyListeners();
  }

  void setMonthlyBudget(double value) {
    monthlyBudget = value;
    _saveProfile();
    _announceNewAlerts();
    notifyListeners();
  }

  void setSavingsGoal(double value) {
    savingsGoal = value;
    _saveProfile();
    notifyListeners();
  }

  // --- Categories --------------------------------------------------------

  void setCategoryLimit(String category, double? limit) {
    categoryLimits.removeWhere((key, _) => sameCategory(key, category));
    if (limit != null) categoryLimits[category] = limit;
    _saveCategories();
    _announceNewAlerts();
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
    _saveCategories();
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
    _saveCategories();
    _saveAllExpenses();
    _announceNewAlerts(silent: true); // a rename is not a new alert
    notifyListeners();
  }

  bool hasExpensesIn(String category) =>
      expenses.any((e) => sameCategory(e.category, category));

  void removeCategory(AppCategory category) {
    categories.remove(category);
    categoryLimits.removeWhere((key, _) => sameCategory(key, category.name));
    _saveCategories();
    _announceNewAlerts(silent: true);
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
