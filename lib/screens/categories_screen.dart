import 'package:flutter/material.dart';

import 'expense_model.dart';
import 'finora_theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.expenses});

  final List<ExpenseItem> expenses;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final List<_ManagedCategory> _categories = [
    _ManagedCategory(
      name: 'Food',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFF97316),
      background: Color(0xFFFFE7D6),
      total: 18240,
    ),
    _ManagedCategory(
      name: 'Transport',
      icon: Icons.directions_car_filled_rounded,
      color: Color(0xFF3B82F6),
      background: paleBlue,
      total: 9850,
    ),
    _ManagedCategory(
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFA855F7),
      background: Color(0xFFF3E8FF),
      total: 7460,
    ),
    _ManagedCategory(
      name: 'Bills',
      icon: Icons.receipt_long_rounded,
      color: amber,
      background: Color(0xFFFFF4D6),
      total: 11200,
    ),
    _ManagedCategory(
      name: 'Education',
      icon: Icons.school_rounded,
      color: Color(0xFF6366F1),
      background: Color(0xFFE0E7FF),
      total: 4200,
    ),
    _ManagedCategory(
      name: 'Health',
      icon: Icons.favorite_rounded,
      color: coral,
      background: Color(0xFFFFE4E6),
      total: 2800,
    ),
    _ManagedCategory(
      name: 'Entertainment',
      icon: Icons.movie_rounded,
      color: Color(0xFF7C3AED),
      background: Color(0xFFEDE9FE),
      total: 3650,
    ),
    _ManagedCategory(
      name: 'Other',
      icon: Icons.more_horiz_rounded,
      color: Color(0xFF64748B),
      background: Color(0xFFF1F5F9),
      total: 1200,
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
            FilledButton.icon(
              onPressed: () => _openCategoryEditor(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                backgroundColor: navy,
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Manage how you organize your spending.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 22),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final category = _categories[index];
            return _CategoryCard(
              category: category,
              onEdit: () => _openCategoryEditor(context, category: category),
              onDelete: () => _confirmDelete(context, category),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openCategoryEditor(
    BuildContext context, {
    _ManagedCategory? category,
  }) async {
    final result = await showDialog<_ManagedCategory>(
      context: context,
      builder: (_) => _CategoryEditorDialog(category: category),
    );
    if (result == null) return;
    if (!context.mounted) return;

    setState(() {
      if (category == null) {
        _categories.add(result);
      } else {
        final index = _categories.indexOf(category);
        _categories[index] = result;
      }
    });
    showMessage(
      context,
      category == null ? 'Category added' : 'Category updated',
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    _ManagedCategory category,
  ) async {
    final hasExpenses = widget.expenses.any(
      (expense) => expense.category.toLowerCase().startsWith(
        category.name.toLowerCase(),
      ),
    );
    if (hasExpenses) {
      showMessage(
        context,
        '${category.name} has existing expenses. Move them before deleting.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${category.name}?'),
        content: const Text(
          'This category will be removed from your category list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: coral),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    setState(() => _categories.remove(category));
    showMessage(context, 'Category deleted');
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final _ManagedCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: category.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(category.icon, color: category.color, size: 21),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Category options',
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit category')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete category'),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: navy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'LKR ${category.total.toStringAsFixed(2)} spent',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({this.category});

  final _ManagedCategory? category;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late IconData _icon;
  late Color _color;
  late Color _background;

  static const _icons = [
    Icons.restaurant_rounded,
    Icons.directions_car_filled_rounded,
    Icons.shopping_bag_rounded,
    Icons.receipt_long_rounded,
    Icons.school_rounded,
    Icons.favorite_rounded,
    Icons.movie_rounded,
    Icons.more_horiz_rounded,
    Icons.home_rounded,
    Icons.flight_rounded,
    Icons.pets_rounded,
    Icons.phone_android_rounded,
  ];

  static const _colors = [
    (Color(0xFF10B981), Color(0xFFE1F9F1)),
    (Color(0xFF3B82F6), paleBlue),
    (Color(0xFFF97316), Color(0xFFFFE7D6)),
    (Color(0xFFF59E0B), Color(0xFFFFF4D6)),
    (Color(0xFFEF4444), Color(0xFFFFE4E6)),
    (Color(0xFFA855F7), Color(0xFFF3E8FF)),
    (Color(0xFF14213D), Color(0xFFE2E8F0)),
  ];

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name);
    _icon = category?.icon ?? Icons.more_horiz_rounded;
    _color = category?.color ?? emerald;
    _background = category?.background ?? const Color(0xFFE1F9F1);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit category' : 'Add category'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: !isEditing,
              decoration: const InputDecoration(
                labelText: 'Category name',
                hintText: 'e.g. Subscriptions',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose an icon',
              style: TextStyle(
                color: navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((icon) {
                final selected = icon == _icon;
                return InkWell(
                  onTap: () => setState(() => _icon = icon),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected ? navy : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? navy : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 19,
                      color: selected ? Colors.white : navy,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose a color',
              style: TextStyle(
                color: navy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _colors.map((color) {
                final selected = color.$1 == _color;
                return InkWell(
                  onTap: () => setState(() {
                    _color = color.$1;
                    _background = color.$2;
                  }),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? navy : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: color.$1,
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(
              context,
              _ManagedCategory(
                name: name,
                icon: _icon,
                color: _color,
                background: _background,
                total: widget.category?.total ?? 0,
              ),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: navy),
          child: Text(isEditing ? 'Save changes' : 'Add category'),
        ),
      ],
    );
  }
}

class _ManagedCategory {
  _ManagedCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.background,
    required this.total,
  });

  final String name;
  final IconData icon;
  final Color color;
  final Color background;
  final double total;
}
