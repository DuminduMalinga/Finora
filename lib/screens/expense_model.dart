import 'package:flutter/material.dart';

import 'finora_theme.dart';

class ExpenseItem {
  const ExpenseItem({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
    required this.iconColor,
    required this.background,
    this.notes = '',
  });

  ExpenseItem copyWith({
    int? id,
    String? title,
    String? category,
    String? amount,
    String? date,
    IconData? icon,
    Color? iconColor,
    Color? background,
    String? notes,
  }) => ExpenseItem(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    icon: icon ?? this.icon,
    iconColor: iconColor ?? this.iconColor,
    background: background ?? this.background,
    notes: notes ?? this.notes,
  );

  /// Database key; assigned by the store when the expense is saved.
  final int? id;
  final String title;
  final String category;
  final String amount;
  final String date;
  final IconData icon;
  final Color iconColor;
  final Color background;
  final String notes;

  /// Saved expenses are the same expense when their ids match, so a stale
  /// reference (for example after an edit) still finds its row.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseItem && id != null && other.id == id);

  @override
  int get hashCode => id?.hashCode ?? identityHashCode(this);
}

/// Fixture data for tests; the app itself starts with no transactions.
const sampleExpenses = [
  ExpenseItem(
    title: 'Café Mocha & Croissant',
    category: 'Food & Dining',
    amount: 'Rs. 1,250.00',
    date: 'Today, 9:42 AM',
    icon: Icons.local_cafe_rounded,
    iconColor: Color(0xFFF97316),
    background: Color(0xFFFFE7D6),
  ),
  ExpenseItem(
    title: 'Uber ride to office',
    category: 'Transport',
    amount: 'Rs. 860.00',
    date: 'Yesterday, 8:15 AM',
    icon: Icons.directions_car_filled_rounded,
    iconColor: Color(0xFF3B82F6),
    background: paleBlue,
  ),
  ExpenseItem(
    title: 'Grocery shopping',
    category: 'Shopping',
    amount: 'Rs. 4,680.00',
    date: 'Oct 26, 6:20 PM',
    icon: Icons.shopping_bag_rounded,
    iconColor: Color(0xFFA855F7),
    background: Color(0xFFF3E8FF),
  ),
  ExpenseItem(
    title: 'Electricity bill',
    category: 'Bills & Utilities',
    amount: 'Rs. 3,200.00',
    date: 'Oct 25, 10:00 AM',
    icon: Icons.receipt_long_rounded,
    iconColor: amber,
    background: Color(0xFFFFF4D6),
  ),
];

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
