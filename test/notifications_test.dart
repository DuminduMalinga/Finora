import 'package:finora/main.dart';
import 'package:finora/screens/expense_model.dart';
import 'package:finora/screens/finora_store.dart';
import 'package:finora/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/fake_notifications.dart';

ExpenseItem _expense(String category, String amount, String date) =>
    ExpenseItem(
      title: category,
      category: category,
      amount: amount,
      date: date,
      icon: Icons.circle,
      iconColor: Colors.black,
      background: Colors.white,
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

  final now = DateTime(2026, 10, 28);

  List<AppNotification> alerts(
    List<ExpenseItem> expenses, {
    double budget = 1000,
    Map<String, double> limits = const {},
  }) => buildNotifications(
    expenses: expenses,
    monthlyBudget: budget,
    limits: limits,
    now: now,
  );

  group('budget alerts', () {
    test('no alert while spending is comfortably inside the budget', () {
      expect(alerts([_expense('Food', 'LKR 790.00', 'Oct 5, 2026')]), isEmpty);
      expect(alerts([]), isEmpty);
    });

    test('a warning starts at 80% of the monthly budget', () {
      final result = alerts([_expense('Food', 'LKR 800.00', 'Oct 5, 2026')]);
      expect(result.single.level, AlertLevel.warning);
      expect(result.single.title, 'Close to your monthly budget');
      expect(result.single.message, contains('80%'));
      expect(result.single.message, contains('LKR 200 left'));
    });

    test('going over the budget is reported with the amount over', () {
      final result = alerts([_expense('Food', 'LKR 1,250.00', 'Oct 5, 2026')]);
      expect(result.single.level, AlertLevel.over);
      expect(result.single.title, 'Over your monthly budget');
      expect(result.single.message, contains('LKR 1,250'));
      expect(result.single.message, contains('LKR 250 over'));
    });

    test('exactly on the budget is a warning, not over', () {
      final result = alerts([_expense('Food', 'LKR 1,000.00', 'Oct 5, 2026')]);
      expect(result.single.level, AlertLevel.warning);
    });

    test('other months do not count', () {
      expect(
        alerts([
          _expense('Food', 'LKR 5,000.00', 'Sep 20, 2026'),
          _expense('Food', 'LKR 100.00', 'Oct 5, 2026'),
        ]),
        isEmpty,
      );
    });
  });

  group('category limit alerts', () {
    test('warn at 80% and flag over the limit, ignoring name case', () {
      final result = alerts(
        [
          _expense('food', 'LKR 90.00', 'Oct 5, 2026'),
          _expense('Transport', 'LKR 300.00', 'Oct 6, 2026'),
          _expense('Shopping', 'LKR 100.00', 'Oct 7, 2026'),
        ],
        budget: 10000,
        limits: {'Food': 100, 'Transport': 200, 'Shopping': 500},
      );
      expect(result.map((a) => a.title), [
        'Transport is over its limit', // over comes first
        'Food is almost at its limit',
      ]);
      expect(result.first.message, contains('LKR 100 over'));
      expect(result.last.message, contains('90%'));
    });

    test('over alerts are listed before warnings', () {
      final result = alerts(
        [_expense('Food', 'LKR 850.00', 'Oct 5, 2026')],
        limits: {'Food': 800},
      );
      expect(result.map((a) => a.level), [AlertLevel.over, AlertLevel.warning]);
      expect(result.first.title, 'Food is over its limit');
      expect(result.last.title, 'Close to your monthly budget');
    });
  });

  group('notification centre', () {
    void phone(WidgetTester tester) {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('the bell opens an all-caught-up screen when nothing is due', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(MyApp(store: FinoraStore()));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsNothing); // no count badge
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('You’re all caught up'), findsOneWidget);
    });

    testWidgets('the bell shows a count and the alerts behind it', (
      tester,
    ) async {
      phone(tester);
      final store = FinoraStore(
        expenses: [_expense('Food', 'LKR 90,000.00', 'Today, 9:00 AM')],
      )..setCategoryLimit('Food', 50000);
      await tester.pumpWidget(MyApp(store: store));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Notifications (2)'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // the badge

      await tester.tap(find.byTooltip('Notifications (2)'));
      await tester.pumpAndSettle();
      expect(find.text('Over your monthly budget'), findsOneWidget);
      expect(find.text('Food is over its limit'), findsOneWidget);
      expect(find.text('You’re all caught up'), findsNothing);

      // Raising the limits clears the alerts, live.
      store
        ..setMonthlyBudget(500000)
        ..setCategoryLimit('Food', 500000);
      await tester.pumpAndSettle();
      expect(find.text('You’re all caught up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('system notifications', () {
    late FakeNotificationService phone;

    FinoraStore storeWith({
      double budget = 1000,
      bool onboarded = true,
      SharedPreferences? prefs,
    }) {
      final store = FinoraStore(
        notifier: phone,
        onboarded: onboarded,
        prefs: prefs,
      );
      store.monthlyBudget = budget;
      return store;
    }

    setUp(() => phone = FakeNotificationService());

    test('an alert is sent once when it first appears', () {
      final store = storeWith();
      store.addExpense(_expense('Food', 'LKR 500.00', 'Today, 9:00 AM'));
      expect(phone.shown, isEmpty); // 50%: nothing to say yet

      store.addExpense(_expense('Food', 'LKR 300.00', 'Today, 9:05 AM'));
      expect(phone.titles, ['Close to your monthly budget']); // 80%
      expect(phone.shown.single.body, contains('80%'));

      // Still a warning: no repeat.
      store.addExpense(_expense('Food', 'LKR 10.00', 'Today, 9:10 AM'));
      expect(phone.shown.length, 1);

      // Crossing the budget is a new, more serious alert.
      store.addExpense(_expense('Food', 'LKR 300.00', 'Today, 9:15 AM'));
      expect(phone.titles, [
        'Close to your monthly budget',
        'Over your monthly budget',
      ]);
      expect(phone.shown.last.body, contains('LKR 110 over'));
    });

    test('an alert that clears can be sent again later', () {
      final store = storeWith();
      store.addExpense(_expense('Food', 'LKR 900.00', 'Today, 9:00 AM'));
      expect(phone.shown.length, 1);

      store.removeExpense(store.expenses.first); // back under 80%
      expect(phone.shown.length, 1);

      store.addExpense(_expense('Food', 'LKR 900.00', 'Today, 9:30 AM'));
      expect(phone.shown.length, 2);
      expect(phone.titles.last, 'Close to your monthly budget');
    });

    test('category limits notify, and so does lowering the budget', () {
      final store = storeWith(budget: 100000)..setCategoryLimit('Food', 100);
      store.addExpense(_expense('Food', 'LKR 90.00', 'Today, 9:00 AM'));
      expect(phone.titles, ['Food is almost at its limit']);

      store.setMonthlyBudget(85); // now the whole budget is overspent
      expect(phone.titles.last, 'Over your monthly budget');
    });

    test('nothing is sent before setup is finished', () {
      final store = storeWith(onboarded: false);
      store.addExpense(_expense('Food', 'LKR 990.00', 'Today, 9:00 AM'));
      expect(phone.shown, isEmpty);
    });

    test('renaming a category is not a new alert', () {
      final store = storeWith(budget: 100000)..setCategoryLimit('Food', 100);
      store.addExpense(_expense('Food', 'LKR 150.00', 'Today, 9:00 AM'));
      expect(phone.titles, ['Food is over its limit']);

      store.updateCategory(
        store.categoryNamed('Food')!,
        const AppCategory(
          'Meals',
          Icons.restaurant_rounded,
          Colors.red,
          Colors.white,
        ),
      );
      store.addExpense(_expense('Meals', 'LKR 1.00', 'Today, 9:10 AM'));
      expect(phone.shown.length, 1);
    });

    test('permission is requested once, when setup finishes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = storeWith(onboarded: false, prefs: prefs);
      expect(phone.permissionRequests, 0);
      store.completeSetup(
        name: 'Sam',
        budget: 1000,
        categories: const [
          AppCategory(
            'Food',
            Icons.restaurant_rounded,
            Colors.red,
            Colors.white,
          ),
        ],
        limits: const {'Food': 500},
      );
      expect(phone.permissionRequests, 1);

      // Next launch (already onboarded): not asked again.
      final again = storeWith(prefs: prefs);
      await again.load();
      expect(phone.permissionRequests, 1);
    });
  });
}
