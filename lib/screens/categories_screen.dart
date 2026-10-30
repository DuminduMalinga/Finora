import 'package:flutter/material.dart';

import 'finora_theme.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const _categories = [
    (
      'Food & Dining',
      '12 transactions',
      Icons.restaurant_rounded,
      Color(0xFFF97316),
      Color(0xFFFFE7D6),
    ),
    (
      'Transport',
      '8 transactions',
      Icons.directions_car_filled_rounded,
      Color(0xFF3B82F6),
      paleBlue,
    ),
    (
      'Shopping',
      '6 transactions',
      Icons.shopping_bag_rounded,
      Color(0xFFA855F7),
      Color(0xFFF3E8FF),
    ),
    (
      'Bills & Utilities',
      '4 transactions',
      Icons.receipt_long_rounded,
      amber,
      Color(0xFFFFF4D6),
    ),
    (
      'Education',
      '3 transactions',
      Icons.school_rounded,
      Color(0xFF6366F1),
      Color(0xFFE0E7FF),
    ),
    (
      'Health',
      '2 transactions',
      Icons.favorite_rounded,
      coral,
      Color(0xFFFFE4E6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Categories',
                style: TextStyle(
                  color: navy,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Add category',
              onPressed: () => _addCategory(context),
              icon: const Icon(Icons.add_rounded, color: navy),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Organize your spending your way.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
        ..._categories.map(
          (category) => Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: category.$5,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category.$3, color: category.$4),
              ),
              title: Text(
                category.$1,
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(category.$2),
              trailing: const Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _addCategory(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Category added'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }
}
