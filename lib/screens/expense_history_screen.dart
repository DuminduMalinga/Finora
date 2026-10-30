import 'package:flutter/material.dart';

import 'expense_model.dart';
import 'expense_actions.dart';
import 'expense_details_screen.dart';
import 'finora_store.dart';
import 'finora_theme.dart';
import 'monthly_reports_screen.dart';
import 'app_colors.dart';

class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key, required this.expenses});

  final List<ExpenseItem> expenses;

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _categoryFilter;
  String _dateFilter = 'All dates';
  String _amountFilter = 'Any amount';

  /// Month being listed; null shows every month.
  DateTime? _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExpenseItem> get _filteredExpenses {
    return widget.expenses.where((expense) {
      final matchesSearch =
          _query.isEmpty ||
          expense.title.toLowerCase().contains(_query) ||
          expense.category.toLowerCase().contains(_query);
      final matchesCategory =
          _categoryFilter == null || expense.category == _categoryFilter;
      final date = _dateOf(expense);
      final today = DateUtils.dateOnly(DateTime.now());
      final monday = today.subtract(Duration(days: today.weekday - 1));
      final matchesMonth =
          _month == null ||
          (date != null &&
              date.year == _month!.year &&
              date.month == _month!.month);
      final matchesDate = switch (_dateFilter) {
        'Today' => date != null && DateUtils.isSameDay(date, today),
        'This week' =>
          date != null &&
              !DateUtils.dateOnly(date).isBefore(monday) &&
              !DateUtils.dateOnly(date).isAfter(today),
        _ => true,
      };
      final amount = _amountValue(expense.amount);
      final matchesAmount = switch (_amountFilter) {
        'Under LKR 2,000' => amount < 2000,
        'LKR 2,000 - 5,000' => amount >= 2000 && amount <= 5000,
        'Over LKR 5,000' => amount > 5000,
        _ => true,
      };
      return matchesSearch &&
          matchesCategory &&
          matchesMonth &&
          matchesDate &&
          matchesAmount;
    }).toList();
  }

  double get _total {
    return _filteredExpenses.fold(
      0,
      (total, expense) => total + _amountValue(expense.amount),
    );
  }

  DateTime? _dateOf(ExpenseItem expense) =>
      MonthlyReportData.parseDate(expense.date, DateTime.now());

  String get _monthLabel => _month == null
      ? 'All time'
      : '${_monthNames[_month!.month - 1]} ${_month!.year}';

  @override
  Widget build(BuildContext context) {
    // Rebuild when expenses change through the Edit/Delete menu.
    FinoraScope.maybeOf(context);
    final expenses = _filteredExpenses;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
        backgroundColor: context.page,
        foregroundColor: context.ink,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _MonthlyTotal(
            label: _month == null
                ? 'ALL EXPENSES'
                : '${_monthNames[_month!.month - 1].toUpperCase()} EXPENSES',
            total: _total,
            count: expenses.length,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search expenses',
              prefixIcon: Icon(Icons.search_rounded, color: context.ink),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: context.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SelectorButton(
                  icon: Icons.calendar_month_outlined,
                  label: _monthLabel,
                  onTap: () => _selectMonth(context),
                ),
              ),
              const SizedBox(width: 10),
              _FilterButton(
                active: _hasFilters,
                onTap: () => _openFilters(context),
              ),
            ],
          ),
          if (_hasFilters) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_categoryFilter != null)
                    _FilterTag(
                      label: _categoryFilter!,
                      onRemove: () => setState(() => _categoryFilter = null),
                    ),
                  if (_dateFilter != 'All dates')
                    _FilterTag(
                      label: _dateFilter,
                      onRemove: () => setState(() => _dateFilter = 'All dates'),
                    ),
                  if (_amountFilter != 'Any amount')
                    _FilterTag(
                      label: _amountFilter,
                      onRemove: () =>
                          setState(() => _amountFilter = 'Any amount'),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (expenses.isEmpty)
            const _HistoryEmptyState()
          else
            ..._groupedTransactions(expenses).entries.map(
              (entry) => _TransactionGroup(
                title: entry.key,
                expenses: entry.value,
                onExpenseTap: (expense) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExpenseDetailsScreen(
                      expense: expense,
                      onUpdated: (updated) {
                        final original = expense;
                        setState(() {
                          final store = FinoraScope.maybeOf(context);
                          if (store != null) {
                            store.replaceExpense(original, updated);
                          } else {
                            final index = widget.expenses.indexOf(original);
                            if (index >= 0) widget.expenses[index] = updated;
                          }
                          expense = updated;
                        });
                      },
                      onDeleted: () {
                        setState(() {
                          final store = FinoraScope.maybeOf(context);
                          if (store != null) {
                            store.removeExpense(expense);
                          } else {
                            widget.expenses.remove(expense);
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool get _hasFilters =>
      _categoryFilter != null ||
      _dateFilter != 'All dates' ||
      _amountFilter != 'Any amount';

  Map<String, List<ExpenseItem>> _groupedTransactions(
    List<ExpenseItem> expenses,
  ) {
    final groups = <String, List<ExpenseItem>>{};
    for (final expense in expenses) {
      final group = _dateGroup(expense);
      groups.putIfAbsent(group, () => []).add(expense);
    }
    return groups;
  }

  String _dateGroup(ExpenseItem expense) {
    final date = _dateOf(expense);
    if (date == null) return 'Earlier';
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(date);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    final monday = today.subtract(Duration(days: today.weekday - 1));
    if (!day.isBefore(monday)) return 'Earlier this week';
    return '${_monthNames[day.month - 1]} ${day.year}';
  }

  Future<void> _selectMonth(BuildContext context) async {
    final now = DateTime.now();
    final months = <DateTime?>[
      null,
      for (var i = 0; i < 12; i++) DateTime(now.year, now.month - i),
    ];
    final picked = await showModalBottomSheet<(DateTime?,)>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              'Select month',
              style: TextStyle(
                color: context.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            for (final month in months)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  month == null
                      ? 'All time'
                      : '${_monthNames[month.month - 1]} ${month.year}',
                ),
                trailing: month == _month
                    ? const Icon(Icons.check_rounded, color: emerald)
                    : null,
                onTap: () => Navigator.pop(context, (month,)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _month = picked.$1);
  }

  Future<void> _openFilters(BuildContext context) async {
    final categoryNames = {
      ...?FinoraScope.maybeOf(context)?.categories.map((c) => c.name),
      ...widget.expenses.map((e) => e.category),
    }.toList();
    var category = _categoryFilter;
    var date = _dateFilter;
    var amount = _amountFilter;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filter expenses',
                        style: TextStyle(
                          color: context.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setSheetState(() {
                        category = null;
                        date = 'All dates';
                        amount = 'Any amount';
                      }),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Category',
                  style: TextStyle(
                    color: context.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: category,
                  decoration: const InputDecoration(hintText: 'All categories'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All categories'),
                    ),
                    ...categoryNames.map(
                      (item) => DropdownMenuItem<String?>(
                        value: item,
                        child: Text(item),
                      ),
                    ),
                  ],
                  onChanged: (value) => setSheetState(() => category = value),
                ),
                const SizedBox(height: 16),
                Text(
                  'Date range',
                  style: TextStyle(
                    color: context.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['All dates', 'Today', 'This week'].map((item) {
                    return ChoiceChip(
                      label: Text(item),
                      selected: date == item,
                      onSelected: (_) => setSheetState(() => date = item),
                      selectedColor: context.primary,
                      labelStyle: TextStyle(
                        color: date == item ? Colors.white : context.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Amount',
                  style: TextStyle(
                    color: context.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      [
                        'Any amount',
                        'Under LKR 2,000',
                        'LKR 2,000 - 5,000',
                        'Over LKR 5,000',
                      ].map((item) {
                        return ChoiceChip(
                          label: Text(item),
                          selected: amount == item,
                          onSelected: (_) => setSheetState(() => amount = item),
                          selectedColor: context.primary,
                          labelStyle: TextStyle(
                            color: amount == item ? Colors.white : context.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          showCheckmark: false,
                        );
                      }).toList(),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _categoryFilter = category;
                        _dateFilter = date;
                        _amountFilter = amount;
                      });
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: context.primary,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Apply filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthlyTotal extends StatelessWidget {
  const _MonthlyTotal({
    required this.label,
    required this.total,
    required this.count,
  });

  final String label;
  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2214213D),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFB4C0D4),
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'LKR ${_formatAmount(total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$count ${count == 1 ? 'transaction' : 'transactions'}',
                  style: const TextStyle(
                    color: Color(0xFFB4C0D4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x2234D399),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF6EE7B7),
              size: 25,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorButton extends StatelessWidget {
  const _SelectorButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: context.ink),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: context.surface,
        foregroundColor: context.ink,
        side: BorderSide(color: context.line),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.tune_rounded, size: 18),
      label: const Text('Filter'),
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? context.tint : context.surface,
        foregroundColor: context.ink,
        side: BorderSide(color: active ? context.primary : context.line),
        minimumSize: const Size(104, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _FilterTag extends StatelessWidget {
  const _FilterTag({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        onDeleted: onRemove,
        deleteIconColor: context.ink,
        backgroundColor: context.tint,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }
}

class _TransactionGroup extends StatelessWidget {
  const _TransactionGroup({
    required this.title,
    required this.expenses,
    required this.onExpenseTap,
  });

  final String title;
  final List<ExpenseItem> expenses;
  final ValueChanged<ExpenseItem> onExpenseTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              color: context.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 20),
          color: context.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var index = 0; index < expenses.length; index++) ...[
                _HistoryTransactionTile(
                  expense: expenses[index],
                  onTap: () => onExpenseTap(expenses[index]),
                ),
                if (index < expenses.length - 1)
                  const Divider(height: 1, indent: 72, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryTransactionTile extends StatelessWidget {
  const _HistoryTransactionTile({required this.expense, required this.onTap});

  final ExpenseItem expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: expense.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(expense.icon, color: expense.iconColor, size: 20),
      ),
      title: Text(
        expense.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: context.ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${expense.category}  •  ${_shortDate(expense.date)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.faint, fontSize: 11),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LKR ${_formatAmount(_amountValue(expense.amount))}',
            style: TextStyle(
              color: context.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          ExpenseActionsMenu(expense: expense),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.tint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: context.ink,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No expenses found',
            style: TextStyle(
              color: context.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Try changing your search or filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.faint),
          ),
        ],
      ),
    );
  }
}

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

double _amountValue(String amount) {
  return parseAmount(amount) ?? 0;
}

String _formatAmount(double amount) => formatAmount(amount);

/// "Today, 9:42 AM" sits under a "Today" header, so only the time is needed.
String _shortDate(String date) {
  final m = RegExp(r'^(?:Today|Yesterday), (.+)$').firstMatch(date);
  return m == null ? date : m.group(1)!;
}
