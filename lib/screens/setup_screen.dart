import 'package:flutter/material.dart';

import 'finora_store.dart';
import 'finora_theme.dart';
import 'app_colors.dart';

/// Extra suggestions revealed by the "Other" button.
const _otherCategories = [
  AppCategory(
    'Groceries',
    Icons.shopping_cart_rounded,
    Color(0xFF10B981),
    Color(0xFFE1F9F1),
  ),
  AppCategory('Home & Rent', Icons.home_rounded, Color(0xFF3B82F6), paleBlue),
  AppCategory(
    'Travel',
    Icons.flight_rounded,
    Color(0xFF0EA5E9),
    Color(0xFFE0F4FE),
  ),
  AppCategory(
    'Subscriptions',
    Icons.subscriptions_rounded,
    Color(0xFFA855F7),
    Color(0xFFF3E8FF),
  ),
  AppCategory(
    'Phone & Internet',
    Icons.phone_android_rounded,
    Color(0xFF6366F1),
    Color(0xFFE0E7FF),
  ),
  AppCategory(
    'Fitness',
    Icons.fitness_center_rounded,
    Color(0xFFF97316),
    Color(0xFFFFE7D6),
  ),
  AppCategory(
    'Gifts',
    Icons.card_giftcard_rounded,
    Color(0xFFEC4899),
    Color(0xFFFCE7F3),
  ),
  AppCategory('Pets', Icons.pets_rounded, Color(0xFFF59E0B), Color(0xFFFFF4D6)),
  AppCategory(
    'Savings',
    Icons.savings_rounded,
    Color(0xFF14B8A6),
    Color(0xFFCCFBF1),
  ),
  AppCategory(
    'Miscellaneous',
    Icons.more_horiz_rounded,
    Color(0xFF64748B),
    Color(0xFFE2E8F0),
  ),
];

String _lkr(double amount) {
  final whole = amount
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return 'LKR $whole';
}

double? _parse(String? text) =>
    double.tryParse((text ?? '').replaceAll(',', '').trim());

/// First-run setup: monthly budget, favourite categories and a spending
/// limit for each of them this month. Saves everything into [FinoraStore].
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _budget = TextEditingController();
  final _savings = TextEditingController();
  // The categories we suggest first; "Other" reveals more, and the user can
  // add their own. Every list below ends up in [_options].
  final _main = defaultCategories.where((c) => c.name != 'Other').toList();
  final _others = List<AppCategory>.of(_otherCategories);
  bool _showOther = false;
  List<AppCategory> get _options => [..._main, ..._others];
  final _selected = <String>{};
  final _limits = <String, TextEditingController>{};
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _budget.dispose();
    _savings.dispose();
    for (final controller in _limits.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<AppCategory> get _chosen => [
    for (final c in _options)
      if (_selected.contains(c.name)) c,
  ];

  double get _allocated =>
      _chosen.fold(0, (sum, c) => sum + (_parse(_limits[c.name]?.text) ?? 0));

  void _toggle(AppCategory category, bool on) => setState(() {
    _error = null;
    if (on) {
      _selected.add(category.name);
      _limits.putIfAbsent(category.name, TextEditingController.new);
    } else {
      _selected.remove(category.name);
    }
  });

  Future<void> _addCategory() async {
    final created = await showDialog<AppCategory>(
      context: context,
      builder: (_) => _AddCategoryDialog(
        taken: _options.map((c) => c.name).toList(),
        colorIndex: _others.length,
      ),
    );
    if (created == null) return;
    _others.add(created);
    _toggle(created, true);
  }

  void _finish() {
    final valid = _formKey.currentState!.validate();
    final budget = _parse(_budget.text) ?? 0;
    if (_chosen.isEmpty) {
      setState(() => _error = 'Choose at least one category.');
      return;
    }
    if (!valid) return;
    if (_allocated > budget) {
      setState(
        () => _error =
            'Your category limits (${_lkr(_allocated)}) are more than your '
            'monthly budget (${_lkr(budget)}).',
      );
      return;
    }
    FinoraScope.of(context).completeSetup(
      name: _name.text,
      email: _email.text,
      budget: budget,
      savingsGoal: _parse(_savings.text),
      categories: _chosen,
      limits: {for (final c in _chosen) c.name: _parse(_limits[c.name]!.text)!},
    );
    // The root now shows the app; drop the welcome flow above it.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: 'LKR ',
    filled: true,
    fillColor: context.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: context.line),
    ),
  );

  Widget _categoryChip(AppCategory category) {
    final selected = _selected.contains(category.name);
    return FilterChip(
      avatar: Icon(
        category.icon,
        size: 18,
        color: selected ? Colors.white : category.color,
      ),
      label: Text(category.name),
      selected: selected,
      showCheckmark: false,
      selectedColor: context.primary,
      backgroundColor: context.surface,
      side: BorderSide(color: selected ? context.primary : context.line),
      labelStyle: TextStyle(
        color: selected ? Colors.white : context.ink,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (on) => _toggle(category, on),
    );
  }

  InputDecoration _plainDecoration(String label) =>
      _decoration(label).copyWith(prefixText: null);

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: context.ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(color: context.muted, fontSize: 12.5)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final budget = _parse(_budget.text) ?? 0;
    final remaining = budget - _allocated;
    return Scaffold(
      backgroundColor: context.page,
      appBar: AppBar(
        backgroundColor: context.page,
        foregroundColor: context.ink,
        title: const Text('Set up your budget'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              _heading('1. About you', 'So Finora can greet you by name.'),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: _plainDecoration('Your name'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _plainDecoration('Email (optional)'),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return null;
                  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
                      ? null
                      : 'Enter a valid email';
                },
              ),
              const SizedBox(height: 26),
              _heading(
                '2. Budget and savings goal',
                'The most you plan to spend this month, and what you want to save.',
              ),
              TextFormField(
                controller: _budget,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration('Monthly budget limit', hint: '75000'),
                onChanged: (_) => setState(() => _error = null),
                validator: (value) {
                  final amount = _parse(value);
                  return amount == null || !amount.isFinite || amount <= 0
                      ? 'Enter a budget greater than 0'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _savings,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration(
                  'Savings goal (optional)',
                  hint: '10000',
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) return null;
                  final amount = _parse(value);
                  return amount == null || !amount.isFinite || amount <= 0
                      ? 'Enter a goal greater than 0'
                      : null;
                },
              ),
              const SizedBox(height: 26),
              _heading(
                '3. Favourite categories',
                'Pick the ones you spend on, or add your own.',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in _main) _categoryChip(category),
                  ActionChip(
                    avatar: Icon(
                      _showOther
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                    ),
                    label: const Text('Other'),
                    backgroundColor: context.tint,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: context.ink,
                      fontWeight: FontWeight.w600,
                    ),
                    onPressed: () => setState(() => _showOther = !_showOther),
                  ),
                ],
              ),
              if (_showOther) ...[
                const SizedBox(height: 16),
                Text(
                  'Other categories',
                  style: TextStyle(
                    color: context.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in _others) _categoryChip(category),
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add category'),
                      backgroundColor: context.tint,
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: context.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      onPressed: _addCategory,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 26),
              _heading(
                '4. Spending limit for this month',
                'How much can you spend on each category?',
              ),
              if (_chosen.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Choose categories above to set their limits.',
                    style: TextStyle(color: context.muted, fontSize: 13),
                  ),
                )
              else
                for (final category in _chosen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: category.background,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(
                            category.icon,
                            color: category.color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _limits[category.name],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _decoration(category.name),
                            onChanged: (_) => setState(() => _error = null),
                            validator: (value) {
                              final amount = _parse(value);
                              return amount == null ||
                                      !amount.isFinite ||
                                      amount <= 0
                                  ? 'Enter a limit for ${category.name}'
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              if (_chosen.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: remaining < 0
                        ? coral.withValues(alpha: 0.14)
                        : emerald.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Allocated ${_lkr(_allocated)} of ${_lkr(budget)}',
                          style: TextStyle(
                            color: context.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        remaining < 0
                            ? '${_lkr(-remaining)} over'
                            : '${_lkr(remaining)} left',
                        style: TextStyle(
                          color: remaining < 0 ? coral : emerald,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: coral,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _finish,
                style: FilledButton.styleFrom(
                  backgroundColor: emerald,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Finish setup',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog({required this.taken, required this.colorIndex});

  final List<String> taken;
  final int colorIndex;

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  static const _icons = [
    Icons.home_rounded,
    Icons.flight_rounded,
    Icons.pets_rounded,
    Icons.phone_android_rounded,
    Icons.fitness_center_rounded,
    Icons.local_cafe_rounded,
    Icons.card_giftcard_rounded,
    Icons.savings_rounded,
  ];
  static const _palette = [
    (Color(0xFF10B981), Color(0xFFE1F9F1)),
    (Color(0xFF3B82F6), paleBlue),
    (Color(0xFFF97316), Color(0xFFFFE7D6)),
    (Color(0xFFA855F7), Color(0xFFF3E8FF)),
    (Color(0xFFEC4899), Color(0xFFFCE7F3)),
  ];

  final _name = TextEditingController();
  IconData _icon = _icons.first;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a category name');
      return;
    }
    if (widget.taken.any((t) => sameCategory(t, name))) {
      setState(() => _error = '$name already exists');
      return;
    }
    final colors = _palette[widget.colorIndex % _palette.length];
    Navigator.pop(context, AppCategory(name, _icon, colors.$1, colors.$2));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add category'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Category name',
                hintText: 'e.g. Subscriptions',
                errorText: _error,
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
            Text(
              'Icon',
              style: TextStyle(color: context.ink, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in _icons)
                  InkWell(
                    onTap: () => setState(() => _icon = icon),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: icon == _icon ? context.primary : context.subtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: icon == _icon ? context.ink : context.line,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 19,
                        color: icon == _icon ? Colors.white : context.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }
}
