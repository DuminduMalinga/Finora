import 'package:finora/screens/expense_model.dart';
import 'package:finora/screens/finora_theme.dart';
import 'package:flutter/material.dart';

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
