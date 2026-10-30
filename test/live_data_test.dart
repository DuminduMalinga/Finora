import 'package:finora/main.dart';
import 'package:finora/screens/finora_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/sample_expenses.dart';

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

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('a new expense flows into Home, Budgets and Categories', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(const MyApp(showOnboarding: false));

    // Nothing is pre-filled.
    expect(find.text('LKR 0.00'), findsOneWidget);
    expect(find.text('No spending recorded this month'), findsOneWidget);
    expect(find.text('No expenses yet'), findsOneWidget);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '2500');
    await tester.enterText(find.byType(TextFormField).at(1), 'Lunch');
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Expense'));
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    // Home totals follow the expense list.
    expect(find.text('LKR 2,500.00'), findsOneWidget);
    expect(find.text('LKR 72,500.00 remaining'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);

    // Budgets: the month total and the category card are live.
    await tester.tap(find.text('Budgets'));
    await tester.pumpAndSettle();
    expect(find.text('LKR 2500.00 spent • No limit set'), findsOneWidget);
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '10000');
    await tester.tap(find.text('Save limit'));
    await tester.pumpAndSettle();
    expect(find.text('LKR 2500.00 of LKR 10000.00'), findsOneWidget);
    expect(find.text('25%'), findsWidgets);

    // Categories show this month's spend.
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('LKR 2500.00 this month'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing the profile and budget updates Home', (tester) async {
    phone(tester);
    final store = FinoraStore()
      ..setProfile('Sam Rivera', 'sam@example.com')
      ..setMonthlyBudget(10000);
    await tester.pumpWidget(
      FinoraScope(store: store, child: const SizedBox.shrink()),
    );
    expect(store.initials, 'SR');
    expect(store.monthlyBudget, 10000);
  });

  testWidgets('a category can be created from the Add Expense screen', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(const MyApp(showOnboarding: false));
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Gym',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add category'));
    await tester.pumpAndSettle();
    expect(find.text('Gym'), findsOneWidget); // new tile, already selected

    await tester.enterText(find.byType(TextFormField).at(0), '1500');
    await tester.enterText(find.byType(TextFormField).at(1), 'Monthly pass');
    await tester.ensureVisible(find.text('Save Expense'));
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly pass'), findsOneWidget);

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('LKR 1500.00 this month'), findsOneWidget);
  });

  testWidgets('every expense row has an Edit / Delete menu', (tester) async {
    phone(tester);
    final store = FinoraStore(expenses: List.of(sampleExpenses.take(2)));
    await tester.pumpWidget(MyApp(store: store));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Expense actions'), findsNWidgets(2));

    // Edit straight from the list.
    await tester.tap(find.byTooltip('Expense actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Cafe latte');
    await tester.scrollUntilVisible(
      find.text('Save Changes'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Cafe latte'), findsOneWidget);
    expect(store.expenses.first.title, 'Cafe latte');

    // Delete with a confirmation, then change your mind with Undo.
    await tester.tap(find.byTooltip('Expense actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Cafe latte'), findsNothing);
    expect(store.expenses.length, 1);
    expect(find.text('Expense deleted'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Cafe latte'), findsOneWidget);
    expect(store.expenses.length, 2);
    expect(store.expenses.first.title, 'Cafe latte'); // back in its place

    // The same menu is in the History list.
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Expense actions'), findsWidgets);
    await tester.tap(find.byTooltip('Expense actions').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
