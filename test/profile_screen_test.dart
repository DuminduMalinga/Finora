import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finora/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  Future<void> openProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('Open profile'));
    await tester.pumpAndSettle();
  }

  testWidgets('Profile matches the 393 by 852 design', (tester) async {
    await openProfile(tester);
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Alex Morgan'), findsOneWidget);
    expect(find.text('LKR 75,000'), findsOneWidget);
    expect(find.text('Add expense'), findsNothing);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(MyApp),
      matchesGoldenFile('goldens/profile_screen.png'),
    );
  });

  testWidgets(
    'Profile edits update the card and account preferences are reachable',
    (tester) async {
      await openProfile(tester);
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Alex Morgan'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Alex Perera');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Alex Perera'), findsOneWidget);
      expect(find.text('Profile updated successfully'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Notification Preferences'),
        250,
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -220));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notification Preferences'));
      await tester.pumpAndSettle();
      final alert = find.byType(SwitchListTile).first;
      expect(tester.widget<SwitchListTile>(alert).value, isTrue);
      await tester.tap(alert);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(alert).value, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
}
