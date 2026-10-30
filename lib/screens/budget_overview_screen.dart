import 'package:flutter/material.dart';

import 'finora_theme.dart';

class BudgetOverviewScreen extends StatefulWidget {
  const BudgetOverviewScreen({super.key});

  @override
  State<BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends State<BudgetOverviewScreen> {
  String _month = 'October 2026';
  double _monthlyBudget = 75000;

  final List<_BudgetCategory> _categories = [
    _BudgetCategory(
      name: 'Food & Dining',
      spent: 18240,
      limit: 25000,
      icon: Icons.restaurant_rounded,
      color: Color(0xFFF97316),
      background: Color(0xFFFFE7D6),
    ),
    _BudgetCategory(
      name: 'Transport',
      spent: 9850,
      limit: 15000,
      icon: Icons.directions_car_filled_rounded,
      color: Color(0xFF3B82F6),
      background: paleBlue,
    ),
    _BudgetCategory(
      name: 'Shopping',
      spent: 7460,
      limit: 8000,
      icon: Icons.shopping_bag_rounded,
      color: amber,
      background: Color(0xFFFFF4D6),
    ),
    _BudgetCategory(
      name: 'Bills & Utilities',
      spent: 11200,
      limit: 10000,
      icon: Icons.receipt_long_rounded,
      color: coral,
      background: Color(0xFFFFE4E6),
    ),
  ];

  double get _spent => _categories.fold(0, (total, item) => total + item.spent);
  double get _remaining => _monthlyBudget - _spent;
  double get _usedRatio => (_spent / _monthlyBudget).clamp(0, 1).toDouble();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Overview'),
        backgroundColor: canvas,
        foregroundColor: navy,
        actions: [
          IconButton(
            tooltip: 'Edit budget',
            onPressed: () => _openBudgetEditor(context),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _MonthSelector(month: _month, onTap: () => _selectMonth(context)),
          const SizedBox(height: 18),
          _BudgetSummary(
            monthlyBudget: _monthlyBudget,
            spent: _spent,
            remaining: _remaining,
            usedRatio: _usedRatio,
          ),
          const SizedBox(height: 20),
          _BudgetAlert(remaining: _remaining, usedRatio: _usedRatio),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Category budgets',
                  style: TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openBudgetEditor(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add budget'),
                style: TextButton.styleFrom(foregroundColor: emerald),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._categories.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryBudgetCard(category: category),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const Text(
              'Select month',
              style: TextStyle(
                color: navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...['October 2026', 'September 2026', 'August 2026'].map(
              (month) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(month),
                trailing: month == _month
                    ? const Icon(Icons.check_rounded, color: emerald)
                    : null,
                onTap: () => Navigator.pop(context, month),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _month = selected);
  }

  Future<void> _openBudgetEditor(BuildContext context) async {
    final controller = TextEditingController(
      text: _monthlyBudget.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    final updatedBudget = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit monthly budget',
                style: TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Monthly limit',
                  prefixText: 'LKR ',
                ),
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid budget';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, double.parse(controller.text));
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: navy,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('Save budget'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (updatedBudget != null) setState(() => _monthlyBudget = updatedBudget);
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.month, required this.onTap});

  final String month;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: Colors.white,
        foregroundColor: navy,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, size: 18),
          const SizedBox(width: 10),
          Text(month, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down_rounded),
        ],
      ),
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  const _BudgetSummary({
    required this.monthlyBudget,
    required this.spent,
    required this.remaining,
    required this.usedRatio,
  });

  final double monthlyBudget;
  final double spent;
  final double remaining;
  final double usedRatio;

  @override
  Widget build(BuildContext context) {
    final remainingColor = remaining >= 0 ? emerald : coral;
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MONTHLY BUDGET',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 174,
              width: 174,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 174,
                    width: 174,
                    child: CircularProgressIndicator(
                      value: usedRatio,
                      strokeWidth: 14,
                      backgroundColor: const Color(0xFFE8F5EF),
                      valueColor: AlwaysStoppedAnimation(
                        remaining >= 0 ? emerald : coral,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(usedRatio * 100).round()}%',
                        style: const TextStyle(
                          color: navy,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'used',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _SummaryValue(
                  label: 'Total budget',
                  value: 'LKR ${_formatAmount(monthlyBudget)}',
                  color: navy,
                ),
                _SummaryValue(
                  label: 'Spent',
                  value: 'LKR ${_formatAmount(spent)}',
                  color: coral,
                ),
                _SummaryValue(
                  label: remaining >= 0 ? 'Remaining' : 'Over budget',
                  value: 'LKR ${_formatAmount(remaining.abs())}',
                  color: remainingColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetAlert extends StatelessWidget {
  const _BudgetAlert({required this.remaining, required this.usedRatio});

  final double remaining;
  final double usedRatio;

  @override
  Widget build(BuildContext context) {
    final exceeded = remaining < 0;
    final approaching = !exceeded && usedRatio >= .8;
    final color = exceeded
        ? coral
        : approaching
        ? amber
        : emerald;
    final background = exceeded
        ? const Color(0xFFFFE4E6)
        : approaching
        ? const Color(0xFFFFF4D6)
        : const Color(0xFFE1F9F1);
    final icon = exceeded
        ? Icons.warning_rounded
        : approaching
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    final message = exceeded
        ? 'You are over your monthly budget. Review your category limits.'
        : approaching
        ? 'You are close to your monthly limit. Spend mindfully this week.'
        : 'You are on track. Keep your spending within the green zone.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  const _CategoryBudgetCard({required this.category});

  final _BudgetCategory category;

  @override
  Widget build(BuildContext context) {
    final ratio = category.spent / category.limit;
    final exceeded = ratio > 1;
    final approaching = !exceeded && ratio >= .8;
    final statusColor = exceeded
        ? coral
        : approaching
        ? amber
        : emerald;
    final percent = (ratio * 100).round();
    final remaining = category.limit - category.spent;
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: category.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(category.icon, color: category.color, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'LKR ${_formatAmount(category.spent)} of LKR ${_formatAmount(category.limit)}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: ratio.clamp(0, 1).toDouble(),
                minHeight: 7,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                exceeded
                    ? 'LKR ${_formatAmount(remaining.abs())} over limit'
                    : 'LKR ${_formatAmount(remaining)} remaining',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCategory {
  const _BudgetCategory({
    required this.name,
    required this.spent,
    required this.limit,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String name;
  final double spent;
  final double limit;
  final IconData icon;
  final Color color;
  final Color background;
}

String _formatAmount(double amount) => amount.toStringAsFixed(2);
