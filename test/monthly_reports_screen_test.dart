import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/main.dart';
import 'package:finora/screens/expense_model.dart';
import 'package:finora/screens/finora_theme.dart';
import 'package:finora/screens/monthly_reports_screen.dart';

ExpenseItem expense(String category, String amount, String date) => ExpenseItem(
  title: category,
  category: category,
  amount: amount,
  date: date,
  icon: Icons.receipt,
  iconColor: navy,
  background: paleBlue,
);

void main() {
  test(
    'Totals, rankings, weekly buckets and December comparison are accurate',
    () {
      final report = MonthlyReportData([
        expense('Food', 'LKR 1,250.50', 'Jan 1, 2026'),
        expense('Food', 'LKR 249.50', 'Jan 8, 2026'),
        expense('Shopping', 'Rs. 2,000.00', 'Jan 31, 2026'),
        expense('Bills', 'LKR 500.00', 'Dec 31, 2025'),
        expense('Food', 'invalid', 'Jan 10, 2026'),
        expense('Food', 'LKR 99.00', 'Feb 1, 2026'),
      ], DateTime(2026, 1));
      expect(report.total, 3500);
      expect(report.previousTotal, 500);
      expect(report.count, 3);
      expect(report.ranked.first.key, 'Shopping');
      expect(report.categories['Food'], 1500);
      expect(report.weeks, [1250.5, 249.5, 0, 0, 2000]);
      expect(report.weeks.reduce((a, b) => a + b), report.total);
    },
  );

  test(
    'Relative dates use today across month boundaries and leap days work',
    () {
      final items = [
        expense('Food', '100', 'Today, 9:42 AM'),
        expense('Food', '200', 'Yesterday, 8:15 AM'),
        expense('Food', '300', 'Feb 29, 2024'),
        expense('Food', '999', 'Feb 30, 2024'),
      ];
      final report = MonthlyReportData(
        items,
        DateTime(2024, 3),
        today: DateTime(2024, 3, 1),
      );
      expect(report.total, 100);
      expect(report.previousTotal, 500);
      final earlier = MonthlyReportData(
        items,
        DateTime(2024, 2),
        today: DateTime(2024, 3, 1),
      );
      expect(earlier.total, 500);
      expect(earlier.weeks.last, 500);
    },
  );

  testWidgets(
    'Reports fit a narrow phone and month navigation shows an empty state',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: FinoraTheme.theme,
          home: MonthlyReportsScreen(
            initialMonth: DateTime(2026, 10),
            expenses: [
              expense('Food & Dining', 'LKR 1,500.00', 'Oct 8, 2026'),
              expense('Shopping', 'LKR 4,500.00', 'Oct 28, 2026'),
            ],
          ),
        ),
      );
      expect(find.text('LKR 6,000.00'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Weekly spending'), 250);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Spending insight'), 250);
      expect(find.text('Highest spending: Shopping'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.byTooltip('Next month'), -400);
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('LKR 0.00'), findsOneWidget);
      expect(find.text('A fresh page for your spending'), findsOneWidget);
      expect(find.text('Spending by category'), findsNothing);
      await tester.tap(find.text('November 2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oct'));
      await tester.pumpAndSettle();
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('LKR 6,000.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Reports tab opens monthly reports and transaction history', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly Reports'), findsOneWidget);
    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();
    expect(find.text('Expense History'), findsOneWidget);
  });
}
