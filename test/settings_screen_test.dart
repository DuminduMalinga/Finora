import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/main.dart';
import 'package:finora/screens/expense_model.dart';
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
    await tester.pumpWidget(const MyApp());
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      bar.destinations.whereType<NavigationDestination>().map((e) => e.label),
      ['Home', 'Settings', 'Budgets', 'Categories', 'Reports'],
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
    await reveal(tester, 'Language');
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamil'));
    await tester.pumpAndSettle();
    expect(find.text('Tamil'), findsOneWidget);
    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LKR (Sri Lankan Rupee)').last);
    await tester.pumpAndSettle();
    await reveal(tester, 'Expense Reminders');
    final switches = find.byType(SwitchListTile);
    expect(tester.widget<SwitchListTile>(switches.first).value, isTrue);
    await tester.tap(find.text('Expense Reminders'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(switches.first).value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Clear data and Logout require confirmation; security opens a screen',
    (tester) async {
      await phone(tester);
      final preferences = SettingsPreferences();
      addTearDown(preferences.dispose);
      var cleared = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: FinoraTheme.theme,
          home: SettingsScreen(
            preferences: preferences,
            expenses: sampleExpenses,
            onBack: () {},
            onClearData: () => cleared = true,
            onRestore: (_) {},
          ),
        ),
      );
      await reveal(tester, 'Change Password');
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();
      expect(find.textContaining('authentication service'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await reveal(tester, 'Clear App Data');
      await tester.tap(find.text('Clear App Data'));
      await tester.pumpAndSettle();
      expect(cleared, isFalse);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(cleared, isFalse);
      await tester.tap(find.text('Clear App Data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear Data'));
      await tester.pumpAndSettle();
      expect(cleared, isTrue);
      await reveal(tester, 'Logout');
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(find.text('Log out of Spendly?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Log out of Spendly?'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('CSV export uses transactions and session backup restores them', (
    tester,
  ) async {
    await phone(tester);
    final preferences = SettingsPreferences();
    addTearDown(preferences.dispose);
    final items = List<ExpenseItem>.of(sampleExpenses);
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: FinoraTheme.theme,
        home: SettingsScreen(
          preferences: preferences,
          expenses: items,
          onBack: () {},
          onClearData: items.clear,
          onRestore: (restored) {
            items.clear();
            items.addAll(restored);
          },
        ),
      ),
    );
    await reveal(tester, 'Export Expense Data');
    await tester.tap(find.text('Export Expense Data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy CSV'));
    await tester.pumpAndSettle();
    expect(
      copied,
      startsWith('Title,Category,Amount,Date,Payment method,Notes\r\n'),
    );
    expect(copied, contains('"Rs. 1,250.00"'));
    await reveal(tester, 'Backup & Restore');
    await tester.tap(find.text('Backup & Restore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create session backup'));
    await tester.pumpAndSettle();
    expect(preferences.backup?.length, sampleExpenses.length);
    items.clear();
    await tester.tap(find.text('Restore session backup'));
    await tester.pumpAndSettle();
    expect(items, isEmpty);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(items.length, sampleExpenses.length);
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
