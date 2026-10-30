import 'dart:io';

import 'package:finora/data/finora_database.dart';
import 'package:finora/main.dart';
import 'package:finora/screens/expense_model.dart';
import 'package:finora/screens/finora_store.dart';
import 'package:finora/screens/settings_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

ExpenseItem _expense(String title, String category, String amount) =>
    ExpenseItem(
      title: title,
      category: category,
      amount: amount,
      date: 'Oct 31, 2026',
      icon: Icons.restaurant_rounded,
      iconColor: Colors.orange,
      background: Colors.white,
      notes: 'note',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  late Directory dir;
  late String path;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dir = Directory.systemTemp.createTempSync('finora_test');
    path = '${dir.path}/finora.db';
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<(FinoraStore, FinoraDatabase)> openStore() async {
    final db = await FinoraDatabase.open(path: path, factory: factory);
    final store = FinoraStore(
      database: db,
      prefs: await SharedPreferences.getInstance(),
      onboarded: false,
    );
    await store.load();
    return (store, db);
  }

  test('first launch starts empty with the welcome flow pending', () async {
    final (store, db) = await openStore();
    expect(store.onboarded, isFalse);
    expect(store.expenses, isEmpty);
    expect(store.categories.length, defaultCategories.length);
    await db.close();
  });

  test(
    'profile, budget, categories, limits and expenses survive a restart',
    () async {
      var (store, db) = await openStore();
      store.setProfile('Sam Rivera', 'sam@example.com');
      store.setPhoto(Uint8List.fromList([1, 2, 3, 4]));
      store.setSavingsGoal(200000);
      store.completeSetup(
        budget: 50000,
        categories: const [
          AppCategory(
            'Food',
            Icons.restaurant_rounded,
            Colors.orange,
            Colors.white,
          ),
          AppCategory('Pets', Icons.pets_rounded, Colors.amber, Colors.white),
        ],
        limits: {'Food': 20000, 'Pets': 5000},
      );
      store.addExpense(_expense('Lunch', 'Food', 'LKR 1,250.00'));
      store.addExpense(_expense('Dog food', 'Pets', 'LKR 3,000.00'));
      await store.settled();
      await db.close();

      // "Restart": a brand new store reads everything back.
      (store, db) = await openStore();
      expect(store.onboarded, isTrue);
      expect(store.name, 'Sam Rivera');
      expect(store.email, 'sam@example.com');
      expect(store.photo, [1, 2, 3, 4]);
      expect(store.monthlyBudget, 50000);
      expect(store.savingsGoal, 200000);
      expect(store.categories.map((c) => c.name), ['Food', 'Pets']);
      expect(store.categories.last.icon, Icons.pets_rounded);
      expect(store.limitFor('Food'), 20000);
      expect(store.limitFor('Pets'), 5000);
      // Newest first, same order as before the restart.
      expect(store.expenses.map((e) => e.title), ['Dog food', 'Lunch']);
      expect(store.expenses.first.notes, 'note');
      expect(store.expenses.every((e) => e.id != null), isTrue);
      await db.close();
    },
  );

  test('edits, deletes and category renames are saved', () async {
    var (store, db) = await openStore();
    store.addExpense(_expense('Lunch', 'Food', 'LKR 100.00'));
    store.addExpense(_expense('Taxi', 'Transport', 'LKR 200.00'));
    store.replaceExpense(
      store.expenses.last,
      store.expenses.last.copyWith(title: 'Late lunch', amount: 'LKR 150.00'),
    );
    store.removeExpense(store.expenses.first); // Taxi
    store.updateCategory(
      store.categoryNamed('Food')!,
      const AppCategory(
        'Meals',
        Icons.restaurant_rounded,
        Colors.red,
        Colors.white,
      ),
    );
    await store.settled();
    await db.close();

    (store, db) = await openStore();
    expect(store.expenses.length, 1);
    expect(store.expenses.single.title, 'Late lunch');
    expect(store.expenses.single.amount, 'LKR 150.00');
    expect(store.expenses.single.category, 'Meals');
    expect(store.categoryNamed('Meals'), isNotNull);
    expect(store.categoryNamed('Food'), isNull);

    // A stale reference (the one from before the edit) still finds its row.
    final stale = store.expenses.single.copyWith(title: 'x');
    store.removeExpense(stale);
    await store.settled();
    await db.close();
    (store, db) = await openStore();
    expect(store.expenses, isEmpty);
    await db.close();
  });

  test('app settings are saved and restored', () async {
    var db = await FinoraDatabase.open(path: path, factory: factory);
    final settings = SettingsPreferences()..attach(db, await db.loadSettings());
    settings.update(() {
      settings.themeMode = ThemeMode.dark;
      settings.accent = const Color(0xFF6366F1);
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await db.close();

    db = await FinoraDatabase.open(path: path, factory: factory);
    final restored = SettingsPreferences()..attach(db, await db.loadSettings());
    expect(restored.themeMode, ThemeMode.dark);
    expect(restored.accent, const Color(0xFF6366F1));
    expect(restored.themeMode, ThemeMode.dark);
    await db.close();
  });

  testWidgets('the welcome flow is shown once, then never again', (
    tester,
  ) async {
    await tester.runAsync(() async {});
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // First launch: welcome screen, then finish -> flag saved.
    var store = FinoraStore(prefs: prefs, onboarded: false);
    await store.load();
    expect(store.onboarded, isFalse);
    store.skipSetup();
    expect(prefs.getBool(FinoraStore.onboardedKey), isTrue);

    // Next launch: the saved flag skips the welcome flow entirely.
    store = FinoraStore(prefs: prefs, onboarded: false);
    await store.load();
    expect(store.onboarded, isTrue);

    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MyApp(store: store));
    expect(find.text('Get Started'), findsNothing);
    expect(find.text('Add expense'), findsOneWidget);
  });

  testWidgets('a fresh install shows the welcome screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = FinoraStore(
      prefs: await SharedPreferences.getInstance(),
      onboarded: false,
    );
    await store.load();
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MyApp(store: store));
    expect(find.text('Get Started'), findsOneWidget);
  });
}
