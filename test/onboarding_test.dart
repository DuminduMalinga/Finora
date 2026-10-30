import 'package:finora/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> openSetup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    expect(
      find.textContaining('Take Control', findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Set up your budget'), findsOneWidget);
  }

  testWidgets('only the money fields carry the LKR prefix', (tester) async {
    await openSetup(tester);
    String? prefix(String label) => tester
        .widget<TextField>(
          find.descendant(of: field(label), matching: find.byType(TextField)),
        )
        .decoration
        ?.prefixText;
    expect(prefix('Your name'), isNull);
    expect(prefix('Email (optional)'), isNull);
    expect(prefix('Monthly budget limit'), 'LKR ');
    expect(prefix('Savings goal (optional)'), 'LKR ');
  });

  testWidgets('setup saves the budget, categories and limits into the app', (
    tester,
  ) async {
    await openSetup(tester);
    await tester.enterText(field('Your name'), 'Sam Rivera');
    await tester.enterText(field('Email (optional)'), 'sam@example.com');
    await tester.enterText(field('Monthly budget limit'), '50000');
    await tester.enterText(field('Savings goal (optional)'), '200000');
    await tester.tap(find.text('Food'));
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();

    // "Other" reveals more categories; the user can also add their own.
    expect(find.text('Travel'), findsNothing);
    await tester.tap(find.text('Other'));
    await tester.pumpAndSettle();
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Subscriptions'), findsOneWidget);
    await tester.tap(find.text('Travel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'Hobbies',
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Food'), '20000');
    await tester.enterText(field('Transport'), '10000');
    await tester.enterText(field('Travel'), '3000');
    await tester.enterText(field('Hobbies'), '2000');
    await tester.pumpAndSettle();
    expect(find.text('Allocated LKR 35,000 of LKR 50,000'), findsOneWidget);
    expect(find.text('LKR 15,000 left'), findsOneWidget);

    await tester.tap(find.text('Finish setup'));
    await tester.pumpAndSettle();

    // Home is configured with the entered budget.
    expect(find.text('Set up your budget'), findsNothing);
    expect(find.text('LKR 50,000'), findsOneWidget);
    expect(find.text('Sam Rivera'), findsOneWidget); // the Home greeting

    // The profile shows what was entered during setup.
    await tester.tap(find.byTooltip('Open profile'));
    await tester.pumpAndSettle();
    expect(find.text('Sam Rivera'), findsOneWidget);
    expect(find.text('sam@example.com'), findsOneWidget);
    expect(find.text('LKR 200,000'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to dashboard'));
    await tester.pumpAndSettle();

    // Budgets show the chosen categories with their limits.
    await tester.tap(find.text('Budgets'));
    await tester.pumpAndSettle();
    expect(find.text('LKR 0.00 of LKR 20,000.00'), findsOneWidget);
    expect(find.text('LKR 0.00 of LKR 10,000.00'), findsOneWidget);
    expect(find.text('LKR 0.00 of LKR 3,000.00'), findsOneWidget);
    expect(find.text('LKR 0.00 of LKR 2,000.00'), findsOneWidget);

    // Categories lists only the chosen ones (plus the custom one).
    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Hobbies'), findsOneWidget);
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Education'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('setup rejects limits above the budget and missing categories', (
    tester,
  ) async {
    await openSetup(tester);
    await tester.enterText(field('Monthly budget limit'), '10000');
    await tester.ensureVisible(find.text('Finish setup'));
    await tester.tap(find.text('Finish setup'));
    await tester.pumpAndSettle();
    expect(find.text('Choose at least one category.'), findsOneWidget);
    expect(find.text('Enter your name'), findsOneWidget);
    await tester.enterText(field('Your name'), 'Sam');

    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Food'), '20000');
    await tester.ensureVisible(find.text('Finish setup'));
    await tester.tap(find.text('Finish setup'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('more than your monthly budget'),
      findsOneWidget,
    );
    expect(find.text('Set up your budget'), findsOneWidget);
  });

  testWidgets('an empty savings goal keeps the LKR 10,000 default', (
    tester,
  ) async {
    await openSetup(tester);
    await tester.enterText(field('Your name'), 'Sam');
    await tester.enterText(field('Monthly budget limit'), '50000');
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Food'), '20000');
    await tester.ensureVisible(find.text('Finish setup'));
    await tester.tap(find.text('Finish setup'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open profile'));
    await tester.pumpAndSettle();
    expect(find.text('LKR 10,000'), findsOneWidget);
  });

  testWidgets('Skip for now opens the app with the default categories', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(find.text('LKR 75,000'), findsOneWidget);
  });

  testWidgets('welcome screen lays out on a 393 x 852 phone', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    expect(find.text('Finora'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
