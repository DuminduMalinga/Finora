import 'package:flutter/material.dart';
import 'support/sample_expenses.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/screens/expense_details_screen.dart';
import 'package:finora/screens/expense_model.dart';
import 'package:finora/screens/finora_theme.dart';

void main() {
  testWidgets('Prefills a formatted amount and updates the details on save', (
    tester,
  ) async {
    ExpenseItem? updated;
    await tester.pumpWidget(
      MaterialApp(
        theme: FinoraTheme.theme,
        home: ExpenseDetailsScreen(
          expense: sampleExpenses.first,
          onUpdated: (value) => updated = value,
        ),
      ),
    );
    expect(find.text('LKR 1,250.00'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit expense'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '1250.00'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '2750.50');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Lunch in Colombo',
    );
    await tester.scrollUntilVisible(
      find.text('Save Changes'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(updated?.amount, 'LKR 2,750.50');
    expect(find.text('Lunch in Colombo'), findsOneWidget);
    expect(find.text('LKR 2,750.50'), findsOneWidget);
    expect(find.text('Expense updated successfully'), findsOneWidget);
  });

  testWidgets('Delete requires confirmation and Cancel preserves the expense', (
    tester,
  ) async {
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: FinoraTheme.theme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ExpenseDetailsScreen(
                    expense: sampleExpenses.first,
                    onDeleted: () => deleted = true,
                  ),
                ),
              ),
              child: const Text('Open expense'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deleted, isFalse);
    expect(find.text('Expense Details'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete expense'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
    expect(find.text('Open expense'), findsOneWidget);
    expect(find.text('Expense deleted successfully'), findsOneWidget);
  });
}
