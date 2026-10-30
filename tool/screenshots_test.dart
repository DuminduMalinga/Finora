// Generates the README screenshots in docs/screenshots.
//
// Run from the project root:
//   flutter test tool/screenshots_test.dart --update-goldens
//
// The pictures use realistic sample data relative to today's date, so this
// file lives outside test/ and is not part of the normal test run.
import 'package:finora/main.dart';
import 'package:finora/screens/expense_model.dart';
import 'package:finora/screens/finora_store.dart';
import 'package:finora/screens/settings_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _date(int daysAgo, String time) {
  if (daysAgo == 0) return 'Today, $time';
  if (daysAgo == 1) return 'Yesterday, $time';
  final d = DateTime.now().subtract(Duration(days: daysAgo));
  return '${_months[d.month - 1]} ${d.day}, ${d.year}';
}

/// A month of believable spending for "Sam Rivera".
FinoraStore _sampleStore() {
  final store = FinoraStore()
    ..setProfile('Sam Rivera', 'sam.rivera@example.com')
    ..setMonthlyBudget(30000)
    ..setSavingsGoal(50000)
    ..setCategoryLimit('Food', 8000)
    ..setCategoryLimit('Transport', 6000)
    ..setCategoryLimit('Shopping', 6000)
    ..setCategoryLimit('Bills', 8000)
    ..setCategoryLimit('Entertainment', 2000);
  void add(
    String title,
    String category,
    double amount,
    int daysAgo, {
    String time = '9:42 AM',
    String notes = '',
  }) {
    final c = store.categoryNamed(category)!;
    store.addExpense(
      ExpenseItem(
        title: title,
        category: category,
        amount: 'LKR ${formatAmount(amount)}',
        date: _date(daysAgo, time),
        icon: c.icon,
        iconColor: c.color,
        background: c.background,
        notes: notes,
      ),
    );
  }

  // Oldest first, so the newest ends up on top.
  add('Internet bill', 'Bills', 2500, 15, time: '10:00 AM');
  add('Bus pass', 'Transport', 600, 12, time: '7:30 AM');
  add('Dinner out', 'Food', 2300, 9, time: '8:10 PM');
  add('Running shoes', 'Shopping', 5500, 8, time: '4:25 PM');
  add('Fuel', 'Transport', 3000, 6, time: '6:50 PM');
  add('Electricity bill', 'Bills', 3200, 5, time: '10:00 AM');
  add('Movie tickets', 'Entertainment', 1200, 4, time: '7:45 PM');
  add(
    'Groceries',
    'Food',
    4680,
    3,
    time: '6:20 PM',
    notes: 'Weekly shop at the supermarket',
  );
  add('Lunch with the team', 'Food', 1800, 2, time: '12:40 PM');
  add('Uber ride to office', 'Transport', 860, 1, time: '8:15 AM');
  add('Café Mocha & Croissant', 'Food', 1250, 0);
  return store;
}

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

  /// Like testWidgets, but draws real shadows. Flutter's test mode renders
  /// them as hard black outlines, and the test binding wants the default put
  /// back before the test ends.
  void screenshotTest(
    String name,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(name, (tester) async {
      debugDisableShadows = false;
      try {
        await body(tester);
      } finally {
        debugDisableShadows = true;
      }
    });
  }

  void screen(WidgetTester tester, {double height = 852}) {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = Size(393 * 2, height * 2);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> shot(WidgetTester tester, String name) => expectLater(
    find.byType(MyApp),
    matchesGoldenFile('../docs/screenshots/$name.png'),
  );

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    final byTooltip = find.byTooltip('Back');
    await tester.tap(
      byTooltip.evaluate().isNotEmpty
          ? byTooltip.first
          : find.byIcon(Icons.arrow_back_rounded).first,
    );
    await tester.pumpAndSettle();
  }

  screenshotTest('first launch: welcome and setup', (tester) async {
    screen(tester);
    await tester.pumpWidget(MyApp(store: FinoraStore(onboarded: false)));
    await tester.pumpAndSettle();
    await shot(tester, '01_welcome');

    screen(tester, height: 1330);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    Finder field(String label) => find.widgetWithText(TextFormField, label);
    await tester.enterText(field('Your name'), 'Sam Rivera');
    await tester.enterText(field('Email (optional)'), 'sam.rivera@example.com');
    await tester.enterText(field('Monthly budget limit'), '30000');
    await tester.enterText(field('Savings goal (optional)'), '50000');
    for (final c in ['Food', 'Transport', 'Shopping', 'Bills']) {
      await tester.tap(find.text(c));
    }
    await tester.pumpAndSettle();
    await tester.enterText(field('Food'), '8000');
    await tester.enterText(field('Transport'), '6000');
    await tester.enterText(field('Shopping'), '6000');
    await tester.enterText(field('Bills'), '8000');
    await tester.pumpAndSettle();
    await shot(tester, '02_setup');
  });

  screenshotTest('light theme tour', (tester) async {
    screen(tester, height: 900);
    final store = _sampleStore();
    await tester.pumpWidget(MyApp(store: store));
    await tester.pumpAndSettle();
    await shot(tester, '03_home');

    // Add expense, filled in.
    screen(tester);
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '2400');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Dinner at Ocean View',
    );
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await shot(tester, '04_add_expense');
    await back(tester);

    // History: open an expense, then show the Edit / Delete menu.
    await tapText(tester, 'Reports');
    await tapText(tester, 'View History');
    await tapText(tester, 'Groceries');
    await shot(tester, '05_expense_details');
    await back(tester);
    await tester.tap(find.byTooltip('Expense actions').first);
    await tester.pumpAndSettle();
    await shot(tester, '06_history_menu');
    await tester.tapAt(const Offset(10, 300));
    await tester.pumpAndSettle();
    await back(tester);
    await shot(tester, '07_reports');

    await tapText(tester, 'Budgets');
    await shot(tester, '08_budgets');
    await tapText(tester, 'Categories');
    await shot(tester, '09_categories');
    await tapText(tester, 'Settings');
    await shot(tester, '10_settings');

    await tapText(tester, 'Home');
    await tester.tap(find.byTooltip('Open profile'));
    await tester.pumpAndSettle();
    await shot(tester, '11_profile');
    await tester.tap(find.byTooltip('Back to dashboard'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifications (3)'));
    await tester.pumpAndSettle();
    await shot(tester, '12_notifications');
  });

  screenshotTest('dark theme', (tester) async {
    screen(tester, height: 900);
    final settings = SettingsPreferences()..themeMode = ThemeMode.dark;
    await tester.pumpWidget(MyApp(store: _sampleStore(), settings: settings));
    await tester.pumpAndSettle();
    await shot(tester, '13_home_dark');
    screen(tester);
    await tapText(tester, 'Budgets');
    await shot(tester, '14_budgets_dark');
    await tapText(tester, 'Reports');
    await shot(tester, '15_reports_dark');
  });
}
