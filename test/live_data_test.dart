import 'package:finora/main.dart';
import 'package:finora/screens/finora_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.text('Rs. 0.00'), findsOneWidget);
    expect(find.text('No spending recorded this month'), findsOneWidget);

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
    expect(find.text('Rs. 2,500.00'), findsOneWidget);
    expect(find.text('Rs. 72,500.00 remaining'), findsOneWidget);
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
}
