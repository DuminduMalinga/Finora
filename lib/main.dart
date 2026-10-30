import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/finora_database.dart';
import 'data/notification_service.dart';

import 'screens/add_expense_screen.dart';
import 'screens/app_colors.dart';
import 'screens/budget_overview_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/finora_store.dart';
import 'screens/finora_theme.dart';
import 'screens/monthly_reports_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_preferences.dart';
import 'screens/settings_screen.dart';
import 'screens/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // User data lives in SQLite on phones. Other platforms (desktop, web) run
  // without saving until a database is configured for them.
  FinoraDatabase? database;
  NotificationService? notifier;
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      database = await FinoraDatabase.open();
    } catch (error) {
      debugPrint('Finora: could not open the database ($error)');
    }
    notifier = await LocalNotificationService.create();
  }

  final store = FinoraStore(
    database: database,
    prefs: prefs,
    notifier: notifier,
    onboarded: false,
  );
  await store.load();
  final settings = SettingsPreferences();
  if (database != null) {
    settings.attach(database, await database.loadSettings());
  }
  runApp(MyApp(store: store, settings: settings));
}

class MyApp extends StatefulWidget {
  /// [showOnboarding] false opens straight into the app (used by tests).
  const MyApp({
    super.key,
    this.showOnboarding = true,
    this.store,
    this.settings,
  });

  final bool showOnboarding;

  /// Pre-loaded app state; created here when omitted (used by tests).
  final FinoraStore? store;
  final SettingsPreferences? settings;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _settings = widget.settings ?? SettingsPreferences();
  late final _store =
      widget.store ?? FinoraStore(onboarded: !widget.showOnboarding);

  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final notifier = _store.notifier;
    if (notifier == null) return;
    // Tapping a budget alert in the notification tray opens the alerts list.
    notifier.onOpen = _openNotifications;
    if (notifier.launchedFromNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openNotifications());
    }
  }

  void _openNotifications() {
    if (!_store.onboarded) return;
    _navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  void dispose() {
    _store.notifier?.onOpen = null;
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
          navigatorKey: _navigatorKey,
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
            scaffoldBackgroundColor: const Color(0xFF0B1220),
            colorScheme:
                ColorScheme.fromSeed(
                  seedColor: navy,
                  brightness: Brightness.dark,
                ).copyWith(
                  primary: const Color(0xFF3B5BA9),
                  onPrimary: Colors.white,
                  secondary: _settings.accent,
                  surface: const Color(0xFF162033),
                  onSurface: const Color(0xFFF1F5F9),
                  onSurfaceVariant: const Color(0xFF9AA8BD),
                  outline: const Color(0xFF2C3A56),
                  outlineVariant: const Color(0xFF2C3A56),
                  surfaceContainer: const Color(0xFF1D2A42),
                  surfaceContainerLow: const Color(0xFF1D2A42),
                ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0B1220),
              foregroundColor: Color(0xFFF1F5F9),
              surfaceTintColor: Colors.transparent,
            ),
            cardTheme: const CardThemeData(color: Color(0xFF162033)),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF162033),
              surfaceTintColor: Colors.transparent,
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xFF162033),
              surfaceTintColor: Colors.transparent,
            ),
            dividerTheme: const DividerThemeData(color: Color(0xFF2C3A56)),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF1F5F9),
              ),
            ),
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
        onBack: () => setState(() => _selectedIndex = 0),
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      floatingActionButton: _selectedIndex == 3 || _selectedIndex == 4
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddExpense,
              backgroundColor: context.primary,
              foregroundColor: Colors.white,
              elevation: context.isDark ? 1 : null,
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
