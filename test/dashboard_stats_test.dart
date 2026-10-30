import 'package:finora/screens/dashboard_screen.dart';
import 'package:finora/screens/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ExpenseItem _item(String category, String amount, String date) => ExpenseItem(
  title: category,
  category: category,
  amount: amount,
  date: date,
  icon: Icons.circle,
  iconColor: Colors.black,
  background: Colors.white,
);

void main() {
  test('totals, week buckets and top categories come from expenses', () {
    final now = DateTime(2026, 10, 28); // Wednesday
    final stats = DashboardStats(
      [
        _item('Food', 'Rs. 1,000.00', 'Today, 9:00 AM'),
        _item('Food', 'LKR 500.00', 'Oct 26, 6:00 PM'),
        _item('Transport', 'Rs. 200.00', 'Oct 20, 8:00 AM'),
        _item('Bills', 'Rs. 100.00', 'Sep 15, 8:00 AM'),
      ],
      monthlyBudget: 75000,
      now: now,
    );

    expect(stats.monthTotal, 1700);
    expect(stats.previousMonthTotal, 100);
    expect(stats.week[0], 500); // Mon Oct 26
    expect(stats.week[2], 1000); // Wed Oct 28
    expect(stats.previousWeekTotal, 200); // Oct 20 is in Oct 19-25
    expect(stats.todayIndex, 2);
    expect(stats.topCategories.first.$1, 'Food');
    expect(stats.topCategories.first.$2, 1500);
  });

  test('change is null without a baseline', () {
    expect(DashboardStats.change(100, 0), isNull);
    expect(DashboardStats.change(150, 100), 50);
  });
}
