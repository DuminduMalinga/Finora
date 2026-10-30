import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/main.dart';
import 'package:finora/screens/categories_screen.dart';
import 'package:finora/screens/expense_model.dart';
import 'package:finora/screens/finora_store.dart';
import 'package:finora/screens/finora_theme.dart';

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

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'Categories opened from Profile has a Material surface and normal typography',
    (tester) async {
      phone(tester);
      await tester.pumpWidget(const MyApp(showOnboarding: false));
      await tester.tap(find.byTooltip('Open profile'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('My Categories'), 200);
      await Scrollable.ensureVisible(
        tester.element(find.text('My Categories')),
        alignment: 0.4,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Categories'));
      await tester.pumpAndSettle();
      final subtitle = find.text('Manage how you organize your spending.');
      expect(
        find.ancestor(of: subtitle, matching: find.byType(Scaffold)),
        findsOneWidget,
      );
      final richText = tester.widget<RichText>(
        find.descendant(of: subtitle, matching: find.byType(RichText)),
      );
      expect(richText.text.style?.fontSize, 13);
      expect(richText.text.style?.decoration, TextDecoration.none);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(MyApp),
        matchesGoldenFile('goldens/categories_screen.png'),
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('My Categories'), findsOneWidget);
      expect(find.byType(CategoriesScreen), findsNothing);
    },
  );

  testWidgets('Categories remains readable in dark mode', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      FinoraScope(
        store: FinoraStore(expenses: List.of(sampleExpenses)),
        child: MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            fontFamily: 'Inter',
          ),
          home: const CategoriesScreen(expenses: sampleExpenses),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final header = tester.widget<Text>(find.text('Categories'));
    expect(header.style?.color, isNot(navy));
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/categories_dark.png'),
    );
  });
}
