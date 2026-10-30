import 'package:flutter/material.dart';

import 'expense_model.dart';
import 'expense_details_screen.dart';
import 'finora_theme.dart';

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
      final group = _dateGroup(expense.date);
      final matchesDate = switch (_dateFilter) {
        'Today' => group == 'Today',
        'This week' =>
          group == 'Today' ||
              group == 'Yesterday' ||
              group == 'Earlier this week',
        _ => true,
      };
      final amount = _amountValue(expense.amount);
      final matchesAmount = switch (_amountFilter) {
        'Under LKR 2,000' => amount < 2000,
        'LKR 2,000 - 5,000' => amount >= 2000 && amount <= 5000,
        'Over LKR 5,000' => amount > 5000,
        _ => true,
      };
      return matchesSearch && matchesCategory && matchesDate && matchesAmount;
    }).toList();
  }

  double get _total {
    return _filteredExpenses.fold(
      0,
      (total, expense) => total + _amountValue(expense.amount),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _filteredExpenses;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
        backgroundColor: canvas,
        foregroundColor: navy,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _MonthlyTotal(total: _total, count: expenses.length),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search expenses',
              prefixIcon: const Icon(Icons.search_rounded, color: navy),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
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
                  label: 'October 2026',
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
                      onUpdated: (updated) => setState(() {
                        final index = widget.expenses.indexOf(expense);
                        if (index >= 0) widget.expenses[index] = updated;
                        expense = updated;
                      }),
                      onDeleted: () => setState(() {
                        widget.expenses.remove(expense);
                      }),
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
      final group = _dateGroup(expense.date);
      groups.putIfAbsent(group, () => []).add(expense);
    }
    return groups;
  }

  String _dateGroup(String date) {
    if (date.startsWith('Today')) return 'Today';
    if (date.startsWith('Yesterday')) return 'Yesterday';
    return 'Earlier this week';
  }

  Future<void> _selectMonth(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select month',
                style: TextStyle(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ...['October 2026', 'September 2026', 'August 2026'].map(
                (month) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(month),
                  trailing: month == 'October 2026'
                      ? const Icon(Icons.check_rounded, color: emerald)
                      : null,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFilters(BuildContext context) async {
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
                    const Expanded(
                      child: Text(
                        'Filter expenses',
                        style: TextStyle(
                          color: navy,
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
                const Text(
                  'Category',
                  style: TextStyle(color: navy, fontWeight: FontWeight.w700),
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
                    ..._categories.map(
                      (item) => DropdownMenuItem<String?>(
                        value: item,
                        child: Text(item),
                      ),
                    ),
                  ],
                  onChanged: (value) => setSheetState(() => category = value),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Date range',
                  style: TextStyle(color: navy, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['All dates', 'Today', 'This week'].map((item) {
                    return ChoiceChip(
                      label: Text(item),
                      selected: date == item,
                      onSelected: (_) => setSheetState(() => date = item),
                      selectedColor: navy,
                      labelStyle: TextStyle(
                        color: date == item ? Colors.white : navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Amount',
                  style: TextStyle(color: navy, fontWeight: FontWeight.w700),
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
                          selectedColor: navy,
                          labelStyle: TextStyle(
                            color: amount == item ? Colors.white : navy,
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
                      backgroundColor: navy,
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
  const _MonthlyTotal({required this.total, required this.count});

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: navy,
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
                const Text(
                  'OCTOBER EXPENSES',
                  style: TextStyle(
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
                  '$count ${count == 1 ? 'transaction' : 'transactions'} this month',
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
      icon: Icon(icon, size: 18, color: navy),
      label: Text(label, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: Colors.white,
        foregroundColor: navy,
        side: const BorderSide(color: Color(0xFFE2E8F0)),
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
        backgroundColor: active ? paleBlue : Colors.white,
        foregroundColor: navy,
        side: BorderSide(color: active ? navy : const Color(0xFFE2E8F0)),
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
        deleteIconColor: navy,
        backgroundColor: paleBlue,
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
            style: const TextStyle(
              color: navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 20),
          color: Colors.white,
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
        style: const TextStyle(
          color: navy,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${expense.category}  •  ${expense.date}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
      ),
      trailing: Text(
        'LKR ${_formatAmount(_amountValue(expense.amount))}',
        style: const TextStyle(
          color: navy,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
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
            decoration: const BoxDecoration(
              color: paleBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: navy,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No expenses found',
            style: TextStyle(
              color: navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Try changing your search or filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

const _categories = [
  'Food & Dining',
  'Transport',
  'Shopping',
  'Bills & Utilities',
  'Education',
  'Health',
  'Entertainment',
];

double _amountValue(String amount) {
  return double.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
}

String _formatAmount(double amount) {
  return amount.toStringAsFixed(2);
}
