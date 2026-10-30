import 'package:flutter/material.dart';

import 'finora_store.dart';
import 'finora_theme.dart';
import 'monthly_reports_screen.dart';
import 'app_colors.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _monthLabel(DateTime month) =>
    '${_monthNames[month.month - 1]} ${month.year}';

class BudgetOverviewScreen extends StatefulWidget {
  const BudgetOverviewScreen({super.key});

  @override
  State<BudgetOverviewScreen> createState() => _BudgetOverviewScreenState();
}

class _BudgetOverviewScreenState extends State<BudgetOverviewScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final store = FinoraScope.of(context);
    final report = MonthlyReportData(store.expenses, _month);
    final spentByCategory = {
      for (final e in report.categories.entries) e.key.toLowerCase(): e.value,
    };
    final monthlyBudget = store.monthlyBudget;
    final spent = report.total;
    final remaining = monthlyBudget - spent;
    final usedRatio = (spent / monthlyBudget).clamp(0, 1).toDouble();
    final cards = [
      for (final category in store.categories)
        if (store.limitFor(category.name) != null ||
            (spentByCategory[category.name.toLowerCase()] ?? 0) > 0)
          _CategoryBudgetCard(
            category: category,
            spent: spentByCategory[category.name.toLowerCase()] ?? 0,
            limit: store.limitFor(category.name),
            onTap: () => _openLimitEditor(context, category: category),
          ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Overview'),
        backgroundColor: context.page,
        foregroundColor: context.ink,
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
          _MonthSelector(
            month: _monthLabel(_month),
            onTap: () => _selectMonth(context),
          ),
          const SizedBox(height: 18),
          _BudgetSummary(
            monthlyBudget: monthlyBudget,
            spent: spent,
            remaining: remaining,
            usedRatio: usedRatio,
          ),
          const SizedBox(height: 20),
          _BudgetAlert(remaining: remaining, usedRatio: usedRatio),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Category budgets',
                  style: TextStyle(
                    color: context.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openLimitEditor(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add budget'),
                style: TextButton.styleFrom(foregroundColor: emerald),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (cards.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No spending or category limits for this month yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.faint, fontSize: 13),
                ),
              ),
            )
          else
            for (final card in cards)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: card),
        ],
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final now = DateTime.now();
    final months = [
      for (var i = 0; i < 6; i++) DateTime(now.year, now.month - i),
    ];
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(
              'Select month',
              style: TextStyle(
                color: context.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            for (final month in months)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_monthLabel(month)),
                trailing: month == _month
                    ? const Icon(Icons.check_rounded, color: emerald)
                    : null,
                onTap: () => Navigator.pop(context, month),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _month = selected);
  }

  Future<void> _openBudgetEditor(BuildContext context) async {
    final store = FinoraScope.of(context);
    final updated = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AmountSheet(
        title: 'Edit monthly budget',
        label: 'Monthly limit',
        invalid: 'Enter a valid budget',
        action: 'Save budget',
        initial: store.monthlyBudget.toStringAsFixed(0),
      ),
    );
    if (updated != null) store.setMonthlyBudget(updated);
  }

  /// Sets (or clears) the monthly spending limit of one category.
  Future<void> _openLimitEditor(
    BuildContext context, {
    AppCategory? category,
  }) async {
    final store = FinoraScope.of(context);
    final result = await showModalBottomSheet<(String, double?)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LimitSheet(
        categories: store.categories,
        initial: category ?? store.categories.first,
        fixed: category != null,
        currentLimit: store.limitFor,
      ),
    );
    if (result != null) store.setCategoryLimit(result.$1, result.$2);
  }
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.label,
    required this.invalid,
    required this.action,
    this.initial,
  });

  final String title;
  final String label;
  final String invalid;
  final String action;
  final String? initial;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: context.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: widget.label,
                prefixText: 'LKR ',
              ),
              validator: (value) {
                final amount = double.tryParse(
                  (value ?? '').replaceAll(',', ''),
                );
                if (amount == null || !amount.isFinite || amount <= 0) {
                  return widget.invalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(
                      context,
                      double.parse(_controller.text.replaceAll(',', '')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: context.primary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(widget.action),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitSheet extends StatefulWidget {
  const _LimitSheet({
    required this.categories,
    required this.initial,
    required this.fixed,
    required this.currentLimit,
  });

  final List<AppCategory> categories;
  final AppCategory initial;
  final bool fixed;
  final double? Function(String name) currentLimit;

  @override
  State<_LimitSheet> createState() => _LimitSheetState();
}

class _LimitSheetState extends State<_LimitSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late AppCategory _category = widget.initial;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _text(_category));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _text(AppCategory category) {
    final limit = widget.currentLimit(category.name);
    return limit == null ? '' : limit.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fixed ? '${_category.name} limit' : 'Add category budget',
              style: TextStyle(
                color: context.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            if (!widget.fixed) ...[
              DropdownButtonFormField<AppCategory>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in widget.categories)
                    DropdownMenuItem(value: c, child: Text(c.name)),
                ],
                onChanged: (value) => setState(() {
                  _category = value!;
                  _controller.text = _text(_category);
                }),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _controller,
              autofocus: widget.fixed,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monthly limit',
                prefixText: 'LKR ',
              ),
              validator: (value) {
                final amount = double.tryParse(
                  (value ?? '').replaceAll(',', ''),
                );
                if (amount == null || !amount.isFinite || amount <= 0) {
                  return 'Enter a valid limit';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, (
                      _category.name,
                      double.parse(_controller.text.replaceAll(',', '')),
                    ));
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: context.primary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Save limit'),
              ),
            ),
            if (widget.currentLimit(_category.name) != null)
              TextButton(
                onPressed: () => Navigator.pop(context, (_category.name, null)),
                child: const Text('Remove limit'),
              ),
          ],
        ),
      ),
    );
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
        backgroundColor: context.surface,
        foregroundColor: context.ink,
        side: BorderSide(color: context.line),
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
      color: context.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MONTHLY BUDGET',
                style: TextStyle(
                  color: context.muted,
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
                      backgroundColor: context.subtle,
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
                        style: TextStyle(
                          color: context.ink,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'used',
                        style: TextStyle(color: context.muted, fontSize: 12),
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
                  color: context.ink,
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
          Text(label, style: TextStyle(color: context.faint, fontSize: 10)),
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
        ? coral.withValues(alpha: 0.14)
        : approaching
        ? amber.withValues(alpha: 0.16)
        : emerald.withValues(alpha: 0.14);
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
  const _CategoryBudgetCard({
    required this.category,
    required this.spent,
    required this.limit,
    required this.onTap,
  });

  final AppCategory category;
  final double spent;
  final double? limit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final limit = this.limit;
    final ratio = limit == null ? 0.0 : spent / limit;
    final exceeded = ratio > 1;
    final approaching = !exceeded && ratio >= .8;
    final statusColor = exceeded
        ? coral
        : approaching
        ? amber
        : emerald;
    final percent = (ratio * 100).round();
    final remaining = (limit ?? 0) - spent;
    return Card(
      elevation: 0,
      color: context.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                          style: TextStyle(
                            color: context.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          limit == null
                              ? 'LKR ${_formatAmount(spent)} spent • No limit set'
                              : 'LKR ${_formatAmount(spent)} of LKR ${_formatAmount(limit)}',
                          style: TextStyle(color: context.faint, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    limit == null ? 'Set limit' : '$percent%',
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
                  backgroundColor: context.subtle,
                  valueColor: AlwaysStoppedAnimation(statusColor),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  limit == null
                      ? 'Tap to set a monthly limit'
                      : exceeded
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
      ),
    );
  }
}

String _formatAmount(double amount) => formatAmount(amount);
