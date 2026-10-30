import 'package:flutter/material.dart';

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

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}
