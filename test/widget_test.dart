import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finora/main.dart';

void main() {
  testWidgets('Dashboard opens Add Expense and validates input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp(showOnboarding: false));

    expect(find.text('Good morning,'), findsOneWidget);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Save Expense'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text('Enter a title'), findsOneWidget);
    expect(find.text('Select a category'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
  });
}
