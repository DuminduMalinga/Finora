import 'package:flutter/material.dart';

import 'screens/add_expense_screen.dart';
import 'screens/budget_overview_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/expense_history_screen.dart';
import 'screens/expense_model.dart';
import 'screens/finora_theme.dart';
import 'screens/monthly_reports_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finora',
      debugShowCheckedModeBanner: false,
      theme: FinoraTheme.theme,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<ExpenseItem> _expenses = List.of(sampleExpenses);
  int _selectedIndex = 0;

  void _openAddExpense() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          onSaved: (expense) => setState(() => _expenses.insert(0, expense)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(expenses: _expenses, onAddExpense: _openAddExpense),
      ExpenseHistoryScreen(expenses: _expenses),
      const BudgetOverviewScreen(),
      CategoriesScreen(expenses: _expenses),
      MonthlyReportsScreen(expenses: _expenses),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpense,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add expense',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
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
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}
