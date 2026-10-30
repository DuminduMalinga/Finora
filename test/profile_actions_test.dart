import 'dart:convert';

import 'package:finora/screens/finora_store.dart';
import 'package:finora/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

// A valid 1x1 PNG.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

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

  Future<FinoraStore> openProfile(
    WidgetTester tester, {
    PhotoPicker? pick,
    double topInset = 0,
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = FinoraStore();
    await tester.pumpWidget(
      FinoraScope(
        store: store,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: EdgeInsets.only(top: topInset),
              viewPadding: EdgeInsets.only(top: topInset),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => pick == null
                        ? const ProfileScreen(expenses: [])
                        : ProfileScreen(expenses: const [], pickPhoto: pick),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('back button sits below the status bar and returns', (
    tester,
  ) async {
    await openProfile(tester, topInset: 48);
    final back = find.byTooltip('Back to dashboard');
    expect(tester.getTopLeft(back).dy, greaterThanOrEqualTo(48));
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('My Profile'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('the notification icon is gone from the profile header', (
    tester,
  ) async {
    await openProfile(tester);
    expect(find.byTooltip('Notifications'), findsNothing);
    expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
  });

  testWidgets('profile picture offers only camera and gallery', (tester) async {
    final sources = <ImageSource>[];
    final store = await openProfile(
      tester,
      pick: (source) async {
        sources.add(source);
        return Uint8List.fromList(_png);
      },
    );
    await tester.tap(find.byTooltip('Edit profile picture'));
    await tester.pumpAndSettle();
    expect(find.text('Take a photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(ListTile),
      ),
      findsNWidgets(2),
    );

    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
    expect(sources, [ImageSource.gallery]);
    expect(store.photo, isNotNull);
    expect(find.text('Profile picture updated'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit profile picture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(sources, [ImageSource.gallery, ImageSource.camera]);
  });

  testWidgets('an unavailable camera shows a message instead of crashing', (
    tester,
  ) async {
    final store = await openProfile(
      tester,
      pick: (_) async => throw PlatformException(code: 'no_camera'),
    );
    await tester.tap(find.byTooltip('Edit profile picture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();
    expect(
      find.text('The camera is not available on this device'),
      findsOneWidget,
    );
    expect(store.photo, isNull);
  });
}
