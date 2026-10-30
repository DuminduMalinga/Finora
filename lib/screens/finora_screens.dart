import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'finora_theme.dart';

class FinoraShell extends StatefulWidget {
  const FinoraShell({super.key});

  @override
  State<FinoraShell> createState() => _FinoraShellState();
}

class _FinoraShellState extends State<FinoraShell> {
  int _tab = 0;
  final List<ExpenseItem> _expenses = List.of(sampleExpenses);

  void _openAddExpense() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          onSaved: (expense) {
            setState(() => _expenses.insert(0, expense));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(expenses: _expenses, onAddExpense: _openAddExpense),
      HistoryScreen(expenses: _expenses),
      const BudgetScreen(),
      const CategoriesScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      floatingActionButton: _tab < 2
          ? FloatingActionButton.extended(
              onPressed: _openAddExpense,
              backgroundColor: navy,
              foregroundColor: Colors.white,
              elevation: 5,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add expense',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        backgroundColor: Colors.white,
        indicatorColor: paleBlue,
        height: 72,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Categories',
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.expenses});
  final List<ExpenseItem> expenses;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = widget.expenses
        .where(
          (e) =>
              e.title.toLowerCase().contains(query.toLowerCase()) ||
              e.category.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        const Text(
          'Expense history',
          style: TextStyle(
            color: navy,
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Keep an eye on every purchase.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 22),
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: InputDecoration(
            hintText: 'Search expenses',
            prefixIcon: const Icon(Icons.search_rounded, color: navy),
            suffixIcon: IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
              ),
              icon: const Icon(Icons.tune_rounded, color: navy),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'October 2026',
          style: TextStyle(
            color: navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No expenses found',
            message: 'Try a different search term.',
          )
        else
          ...filtered.map(
            (expense) => ExpenseTile(
              expense: expense,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ExpenseDetailsScreen(expense: expense),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Budgets',
                style: TextStyle(
                  color: navy,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditBudgetScreen()),
              ),
              icon: const Icon(Icons.add_rounded, color: navy),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'Plan your month with confidence.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
        const BalanceCard(),
        const SizedBox(height: 24),
        const Text(
          'Category budgets',
          style: TextStyle(
            color: navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          (
            'Food & Dining',
            'Rs. 18,240 / Rs. 25,000',
            .73,
            Icons.restaurant_rounded,
            const Color(0xFFF97316),
          ),
          (
            'Transport',
            'Rs. 9,850 / Rs. 15,000',
            .65,
            Icons.directions_car_filled_rounded,
            const Color(0xFF3B82F6),
          ),
          (
            'Entertainment',
            'Rs. 3,200 / Rs. 8,000',
            .4,
            Icons.movie_rounded,
            const Color(0xFFA855F7),
          ),
        ].map(
          (item) => _BudgetTile(
            title: item.$1,
            value: item.$2,
            progress: item.$3,
            icon: item.$4,
            color: item.$5,
          ),
        ),
      ],
    );
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.title,
    required this.value,
    required this.progress,
    required this.icon,
    required this.color,
  });
  final String title;
  final String value;
  final double progress;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                value,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    ),
  );
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
            onPressed: () => _showAddCategory(context),
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
      ...[
        (
          'Food & Dining',
          '12 transactions',
          Icons.restaurant_rounded,
          const Color(0xFFFFE7D6),
          const Color(0xFFF97316),
        ),
        (
          'Transport',
          '8 transactions',
          Icons.directions_car_filled_rounded,
          paleBlue,
          const Color(0xFF3B82F6),
        ),
        (
          'Shopping',
          '6 transactions',
          Icons.shopping_bag_rounded,
          const Color(0xFFF3E8FF),
          const Color(0xFFA855F7),
        ),
        (
          'Bills & Utilities',
          '4 transactions',
          Icons.receipt_long_rounded,
          const Color(0xFFFFF4D6),
          amber,
        ),
        (
          'Entertainment',
          '3 transactions',
          Icons.movie_rounded,
          const Color(0xFFE1F9F1),
          emerald,
        ),
      ].map(
        (item) => Card(
          elevation: 0,
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.$4,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.$3, color: item.$5),
            ),
            title: Text(
              item.$1,
              style: const TextStyle(color: navy, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(item.$2),
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

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.onSaved});
  final ValueChanged<ExpenseItem> onSaved;
  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  String category = 'Food & Dining';
  @override
  Widget build(BuildContext context) => _ExpenseForm(
    titleController: titleController,
    amountController: amountController,
    category: category,
    onCategoryChanged: (value) => setState(() => category = value),
    onSubmit: () {
      if (titleController.text.trim().isEmpty ||
          amountController.text.trim().isEmpty) {
        showMessage(context, 'Please enter a title and amount');
        return;
      }
      widget.onSaved(
        ExpenseItem(
          title: titleController.text.trim(),
          category: category,
          amount: 'Rs. ${amountController.text.trim()}',
          date: 'Today',
          icon: Icons.receipt_long_rounded,
          iconColor: emerald,
          background: const Color(0xFFE1F9F1),
        ),
      );
      Navigator.pop(context);
      showMessage(context, 'Expense added successfully');
    },
  );
}

class _ExpenseForm extends StatelessWidget {
  const _ExpenseForm({
    required this.titleController,
    required this.amountController,
    required this.category,
    required this.onCategoryChanged,
    required this.onSubmit,
  });
  final TextEditingController titleController;
  final TextEditingController amountController;
  final String category;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Add expense'),
      backgroundColor: canvas,
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: paleBlue,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How much did you spend?',
                style: TextStyle(color: navy, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Add the details and keep your budget on track.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _InputLabel(
          label: 'Amount',
          child: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixText: 'Rs. ',
              hintText: '0.00',
            ),
          ),
        ),
        const SizedBox(height: 18),
        _InputLabel(
          label: 'What did you spend on?',
          child: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: 'e.g. Lunch with friends',
            ),
          ),
        ),
        const SizedBox(height: 18),
        _InputLabel(
          label: 'Category',
          child: DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(),
            items:
                [
                      'Food & Dining',
                      'Transport',
                      'Shopping',
                      'Bills & Utilities',
                      'Entertainment',
                    ]
                    .map(
                      (value) =>
                          DropdownMenuItem(value: value, child: Text(value)),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) onCategoryChanged(value);
            },
          ),
        ),
        const SizedBox(height: 18),
        _InputLabel(
          label: 'Payment method',
          child: DropdownButtonFormField<String>(
            initialValue: 'Card',
            decoration: const InputDecoration(),
            items: ['Card', 'Cash', 'Bank transfer', 'Mobile wallet']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (_) {},
          ),
        ),
        const SizedBox(height: 18),
        _InputLabel(
          label: 'Notes (optional)',
          child: TextField(
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Add a note...'),
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: onSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Save expense',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: navy,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class ExpenseDetailsScreen extends StatelessWidget {
  const ExpenseDetailsScreen({super.key, required this.expense});
  final ExpenseItem expense;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Expense details'),
      backgroundColor: canvas,
      foregroundColor: navy,
      actions: [
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditExpenseScreen(expense: expense),
            ),
          ),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          onPressed: () => _confirmDelete(context),
          icon: const Icon(Icons.delete_outline_rounded, color: coral),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: expense.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(expense.icon, color: expense.iconColor, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                expense.title,
                style: const TextStyle(
                  color: navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '- ${expense.amount}',
                style: const TextStyle(
                  color: coral,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                expense.date,
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: Colors.white,
          child: Column(
            children: [
              _DetailRow(
                label: 'Category',
                value: expense.category,
                icon: Icons.grid_view_rounded,
              ),
              const Divider(height: 1),
              const _DetailRow(
                label: 'Payment method',
                value: 'Visa •••• 4832',
                icon: Icons.credit_card_rounded,
              ),
              const Divider(height: 1),
              const _DetailRow(
                label: 'Notes',
                value: 'Personal expense',
                icon: Icons.notes_rounded,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: navy, size: 20),
    title: Text(
      label,
      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(
        color: navy,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class EditBudgetScreen extends StatelessWidget {
  const EditBudgetScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Add budget'),
      backgroundColor: canvas,
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _InputLabel(
          label: 'Budget name',
          child: TextField(
            decoration: InputDecoration(hintText: 'e.g. Monthly spending'),
          ),
        ),
        const SizedBox(height: 18),
        const _InputLabel(
          label: 'Monthly limit',
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(prefixText: 'Rs. ', hintText: '75,000'),
          ),
        ),
        const SizedBox(height: 18),
        const _InputLabel(
          label: 'Start date',
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.calendar_today_outlined),
              hintText: '01 October 2026',
            ),
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            showMessage(context, 'Budget saved');
          },
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            minimumSize: const Size.fromHeight(54),
          ),
          child: const Text('Save budget'),
        ),
      ],
    ),
  );
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Monthly report'),
      backgroundColor: canvas,
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const BalanceCard(),
        const SizedBox(height: 24),
        const Text(
          'October summary',
          style: TextStyle(
            color: navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        const CategoryBreakdown(),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A healthier month',
                  style: TextStyle(
                    color: navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'You spent 8.4% less than last month. Keep it up!',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.trending_down_rounded, color: emerald),
                    const SizedBox(width: 8),
                    const Text(
                      'Rs. 4,120 saved',
                      style: TextStyle(
                        color: emerald,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 70),
    child: Column(
      children: [
        Icon(icon, size: 46, color: const Color(0xFFCBD5E1)),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(message, style: const TextStyle(color: Color(0xFF94A3B8))),
      ],
    ),
  );
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: navy,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_rounded, color: emerald, size: 58),
          SizedBox(height: 16),
          Text(
            'Finora',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Spend smarter. Live better.',
            style: TextStyle(color: Color(0xFFB4C0D4)),
          ),
        ],
      ),
    ),
  );
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(34),
              decoration: BoxDecoration(
                color: paleBlue,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(Icons.insights_rounded, color: navy, size: 72),
            ),
            const SizedBox(height: 36),
            const Text(
              'Your money, made simple.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: navy,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Track everyday spending, set goals, and build better money habits in one calm place.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: navy,
                minimumSize: const Size.fromHeight(54),
              ),
              child: const Text('Get started'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Private by design • Your data stays yours',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}

class EditExpenseScreen extends StatelessWidget {
  const EditExpenseScreen({super.key, required this.expense});
  final ExpenseItem expense;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Edit expense'),
      backgroundColor: canvas,
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _InputLabel(
          label: 'Amount',
          child: TextField(
            controller: TextEditingController(
              text: expense.amount.replaceFirst('Rs. ', ''),
            ),
            decoration: const InputDecoration(prefixText: 'Rs. '),
          ),
        ),
        const SizedBox(height: 18),
        _InputLabel(
          label: 'Title',
          child: TextField(
            controller: TextEditingController(text: expense.title),
            decoration: const InputDecoration(),
          ),
        ),
        const SizedBox(height: 18),
        _InputLabel(
          label: 'Category',
          child: TextField(
            controller: TextEditingController(text: expense.category),
            decoration: const InputDecoration(),
          ),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            showMessage(context, 'Expense updated');
          },
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            minimumSize: const Size.fromHeight(54),
          ),
          child: const Text('Save changes'),
        ),
      ],
    ),
  );
}

class SearchFilterScreen extends StatelessWidget {
  const SearchFilterScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Search & filter'),
      backgroundColor: canvas,
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Search by title or note',
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Category',
          style: TextStyle(color: navy, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['All', 'Food & Dining', 'Transport', 'Shopping', 'Bills']
              .map(
                (item) => FilterChip(
                  label: Text(item),
                  selected: item == 'All',
                  onSelected: (_) {},
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Payment method',
          style: TextStyle(color: navy, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        const Wrap(
          spacing: 8,
          children: [
            ChoiceChip(label: Text('Any'), selected: true, onSelected: null),
            ChoiceChip(label: Text('Card'), selected: false, onSelected: null),
            ChoiceChip(label: Text('Cash'), selected: false, onSelected: null),
          ],
        ),
        const SizedBox(height: 30),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            showMessage(context, 'Filters applied');
          },
          style: FilledButton.styleFrom(
            backgroundColor: navy,
            minimumSize: const Size.fromHeight(54),
          ),
          child: const Text('Apply filters'),
        ),
      ],
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Settings'),
      backgroundColor: canvas,
      foregroundColor: navy,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      children: [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFDCEBFF),
            child: Text(
              'AS',
              style: TextStyle(color: navy, fontWeight: FontWeight.w800),
            ),
          ),
          title: Text(
            'Alex Silva',
            style: TextStyle(color: navy, fontWeight: FontWeight.w800),
          ),
          subtitle: Text('alex.silva@email.com'),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: Colors.white,
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.person_outline_rounded,
                title: 'Profile & preferences',
              ),
              _SettingRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
              ),
              _SettingRow(
                icon: Icons.lock_outline_rounded,
                title: 'Privacy & security',
              ),
              _SettingRow(
                icon: Icons.help_outline_rounded,
                title: 'Help center',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Finora v1.0.0',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: navy),
    title: Text(
      title,
      style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
    ),
    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
  );
}

class ExpenseItem {
  const ExpenseItem({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
    required this.iconColor,
    required this.background,
  });
  final String title;
  final String category;
  final String amount;
  final String date;
  final IconData icon;
  final Color iconColor;
  final Color background;
}

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

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

void _showAddCategory(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New category'),
      content: const TextField(
        decoration: InputDecoration(hintText: 'Category name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            showMessage(context, 'Category added');
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}

void _confirmDelete(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete expense?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: coral),
          onPressed: () {
            Navigator.pop(context);
            showMessage(context, 'Expense deleted');
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
