import 'package:flutter_test/flutter_test.dart';

import 'package:finora/main.dart';

void main() {
  testWidgets('Finora dashboard renders and navigation works', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('Rs. 45,000.00'), findsOneWidget);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Expense history'), findsOneWidget);
    expect(find.text('Search expenses'), findsOneWidget);
  });
}
