import 'package:flutter/material.dart';
import 'support/sample_expenses.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/main.dart';
import 'package:finora/screens/finora_theme.dart';
import 'package:finora/screens/monthly_reports_screen.dart';
import 'package:finora/screens/settings_preferences.dart';
import 'package:finora/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> reveal(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text(label)),
      alignment: 0.4,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Settings replaces History and matches the phone layout', (
    tester,
  ) async {
    await phone(tester);
    await tester.pumpWidget(const MyApp(showOnboarding: false));
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      bar.destinations.whereType<NavigationDestination>().map((e) => e.label),
      ['Home', 'Budgets', 'Categories', 'Reports', 'Settings'],
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MyApp),
      matchesGoldenFile('goldens/settings_screen.png'),
    );
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final settingContext = tester.element(find.byType(SettingsScreen));
    expect(Theme.of(settingContext).brightness, Brightness.dark);
    await tester.tap(find.byTooltip('Indigo'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(settingContext).colorScheme.secondary,
      const Color(0xFF6366F1),
    );
    await expectLater(
      find.byType(MyApp),
      matchesGoldenFile('goldens/settings_dark.png'),
    );
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(Theme.of(settingContext).brightness, Brightness.light);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings only has Appearance and About', (tester) async {
    await phone(tester);
    final preferences = SettingsPreferences();
    addTearDown(preferences.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: FinoraTheme.theme,
        home: SettingsScreen(preferences: preferences, onBack: () {}),
      ),
    );
    await reveal(tester, 'App Version');
    expect(find.text('About Finora'), findsOneWidget);
    for (final removed in [
      'Preferences',
      'Currency',
      'Language',
      'Notifications',
      'Security',
      'Data Management',
      'Backup & Restore',
      'Clear App Data',
      'Privacy Policy',
      'Terms & Conditions',
      'Send Feedback',
      'Logout',
      'Delete Account',
    ]) {
      expect(find.text(removed), findsNothing, reason: removed);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reports opens transaction history', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: FinoraTheme.theme,
        home: MonthlyReportsScreen(expenses: sampleExpenses),
      ),
    );
    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();
    expect(find.text('Expense History'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
