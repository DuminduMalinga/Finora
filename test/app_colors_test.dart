import 'package:finora/main.dart';
import 'package:finora/screens/app_colors.dart';
import 'package:finora/screens/finora_theme.dart';
import 'package:finora/screens/settings_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

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

  Future<BuildContext> contextFor(WidgetTester tester, ThemeMode mode) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: FinoraTheme.theme,
        darkTheme: ThemeData(brightness: Brightness.dark),
        themeMode: mode,
        home: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox();
          },
        ),
      ),
    );
    return captured;
  }

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('palette is readable in ${mode.name} mode', (tester) async {
      final c = await contextFor(tester, mode);
      expect(c.isDark, mode == ThemeMode.dark);
      for (final background in [c.surface, c.page, c.subtle]) {
        expect(contrast(c.ink, background), greaterThan(7), reason: 'ink');
        expect(
          contrast(c.muted, background),
          greaterThan(4.0),
          reason: 'muted',
        );
        expect(
          contrast(emerald, background),
          greaterThan(2.3),
          reason: 'emerald',
        );
        expect(contrast(coral, background), greaterThan(3), reason: 'coral');
      }
      expect(contrast(c.faint, c.surface), greaterThan(2.5), reason: 'faint');
      expect(
        contrast(Colors.white, c.primary),
        greaterThan(4.5),
        reason: 'button text',
      );
      expect(contrast(c.line, c.surface), greaterThan(1.1), reason: 'outlines');
      expect(contrast(c.surface, c.page), greaterThan(1.03), reason: 'cards');
    });
  }

  testWidgets('the app switches to the dark theme', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = SettingsPreferences()..themeMode = ThemeMode.dark;
    await tester.pumpWidget(MyApp(showOnboarding: false, settings: settings));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Theme.of(context).scaffoldBackgroundColor, context.page);
  });
}
