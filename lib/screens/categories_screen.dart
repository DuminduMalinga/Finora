import 'package:flutter/material.dart';

import 'expense_model.dart';
import 'finora_store.dart';
import 'finora_theme.dart';
import 'monthly_reports_screen.dart';
import 'app_colors.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.expenses});

  final List<ExpenseItem> expenses;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final store = FinoraScope.of(context);
    final categories = store.categories;
    final spentByCategory = {
      for (final e in MonthlyReportData(
        widget.expenses,
        DateTime(DateTime.now().year, DateTime.now().month),
      ).categories.entries)
        e.key.toLowerCase(): e.value,
    };
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          children: [
            Row(
              children: [
                if (Navigator.of(context).canPop()) ...[
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      color: dark ? theme.colorScheme.onSurface : context.ink,
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
                    backgroundColor: context.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              'Manage how you organize your spending.',
              style: TextStyle(
                color: dark
                    ? theme.colorScheme.onSurfaceVariant
                    : context.muted,
                fontSize: 13,
                height: 1.5,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 22),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                return _CategoryCard(
                  category: category,
                  spent: spentByCategory[category.name.toLowerCase()] ?? 0,
                  onEdit: () =>
                      _openCategoryEditor(context, category: category),
                  onDelete: () => _confirmDelete(context, category),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCategoryEditor(
    BuildContext context, {
    AppCategory? category,
  }) async {
    final store = FinoraScope.of(context);
    final result = await showDialog<AppCategory>(
      context: context,
      builder: (_) => CategoryEditorDialog(category: category),
    );
    if (result == null) return;
    if (!context.mounted) return;

    final duplicate = store.categories.any(
      (c) => c != category && sameCategory(c.name, result.name),
    );
    if (duplicate) {
      showMessage(context, '${result.name} already exists');
      return;
    }
    if (category == null) {
      store.addCategory(result);
    } else {
      store.updateCategory(category, result);
    }
    showMessage(
      context,
      category == null ? 'Category added' : 'Category updated',
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppCategory category,
  ) async {
    final store = FinoraScope.of(context);
    if (store.hasExpensesIn(category.name)) {
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
    store.removeCategory(category);
    showMessage(context, 'Category deleted');
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.spent,
    required this.onEdit,
    required this.onDelete,
  });

  final AppCategory category;
  final double spent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: dark ? theme.colorScheme.surfaceContainer : context.surface,
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
                  icon: Icon(Icons.more_horiz_rounded, color: context.faint),
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
              style: TextStyle(
                color: dark ? theme.colorScheme.onSurface : context.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'LKR ${spent.toStringAsFixed(2)} this month',
              style: TextStyle(
                color: dark
                    ? theme.colorScheme.onSurfaceVariant
                    : context.muted,
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

class CategoryEditorDialog extends StatefulWidget {
  const CategoryEditorDialog({super.key, this.category});

  final AppCategory? category;

  @override
  State<CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<CategoryEditorDialog> {
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
    (Color(0xFF14B8A6), Color(0xFFCCFBF1)),
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
            Text(
              'Choose an icon',
              style: TextStyle(
                color: context.ink,
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
                      color: selected ? context.primary : context.subtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? context.ink : context.line,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 19,
                      color: selected ? Colors.white : context.ink,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Choose a color',
              style: TextStyle(
                color: context.ink,
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
                        color: selected ? context.ink : Colors.transparent,
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
              AppCategory(name, _icon, _color, _background),
            );
          },
          style: FilledButton.styleFrom(backgroundColor: context.primary),
          child: Text(isEditing ? 'Save changes' : 'Add category'),
        ),
      ],
    );
  }
}
