import 'package:flutter/material.dart';

import 'screens/add_expense_screen.dart';
import 'screens/budget_overview_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/finora_store.dart';
import 'screens/finora_theme.dart';
import 'screens/monthly_reports_screen.dart';
import 'screens/settings_preferences.dart';
import 'screens/settings_screen.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  /// [showOnboarding] false opens straight into the app (used by tests).
  const MyApp({super.key, this.showOnboarding = true});

  final bool showOnboarding;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _settings = SettingsPreferences();
  late final _store = FinoraStore(onboarded: !widget.showOnboarding);

  @override
  void dispose() {
    _settings.dispose();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => FinoraScope(
        store: _store,
        child: MaterialApp(
          title: 'Finora',
          debugShowCheckedModeBanner: false,
          theme: FinoraTheme.theme.copyWith(
            colorScheme: FinoraTheme.theme.colorScheme.copyWith(
              secondary: _settings.accent,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            fontFamily: 'Inter',
            colorScheme: ColorScheme.fromSeed(
              seedColor: navy,
              brightness: Brightness.dark,
            ).copyWith(secondary: _settings.accent),
          ),
          themeMode: _settings.themeMode,
          home: _Root(settings: _settings),
        ),
      ),
    );
  }
}

/// Shows the welcome/setup flow until the user has configured the app.
class _Root extends StatelessWidget {
  const _Root({required this.settings});

  final SettingsPreferences settings;

  @override
  Widget build(BuildContext context) => FinoraScope.of(context).onboarded
      ? HomePage(settings: settings)
      : const WelcomeScreen();
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.settings});
  final SettingsPreferences settings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _openAddExpense() {
    final store = FinoraScope.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(onSaved: store.addExpense),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = FinoraScope.of(context);
    final expenses = store.expenses;
    final pages = [
      DashboardScreen(expenses: expenses, onAddExpense: _openAddExpense),
      const BudgetOverviewScreen(),
      CategoriesScreen(expenses: expenses),
      MonthlyReportsScreen(expenses: expenses),
      SettingsScreen(
        preferences: widget.settings,
        expenses: expenses,
        onBack: () => setState(() => _selectedIndex = 0),
        onClearData: () => store.replaceAllExpenses(const []),
        onRestore: store.replaceAllExpenses,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      floatingActionButton: _selectedIndex == 3 || _selectedIndex == 4
          ? null
          : FloatingActionButton.extended(
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).brightness == Brightness.dark
            ? widget.settings.accent.withValues(alpha: 0.25)
            : _selectedIndex == 3 || _selectedIndex == 4
            ? const Color(0xFFECFDF5)
            : paleBlue,
        height: 72,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
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
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
