import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medscarrier/screens/splash_screen.dart';
import 'package:medscarrier/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('Fitness Is\nImportant\nAs More'), findsOneWidget);
    expect(find.text('Signup'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('WelcomeScreen Signup button dispatches bloc event',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    await tester.tap(find.text('Signup'));
    await tester.pump();
    expect(find.text('Navigating to Signup...'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('WelcomeScreen Login button dispatches bloc event',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    await tester.tap(find.text('Login'));
    await tester.pump();
    expect(find.text('Navigating to Login...'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('SplashScreen stays visible and does not navigate',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('MedScarrier'), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsNothing);
  });

  testWidgets('SplashScreen is responsive across Android screen sizes',
      (WidgetTester tester) async {
    // Portrait phone sizes in logical pixels for common Android devices
    const sizes = <Size>[
      Size(320, 568), // small phone
      Size(360, 640), // small Android
      Size(360, 800), // common Android
      Size(412, 915), // large phone
      Size(600, 960), // small tablet
      Size(800, 1280), // tablet
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SplashScreen), findsOneWidget,
          reason: 'Splash overflowed or failed to build at $size');

      // Let the SplashBloc timer finish (and navigation settle) before
      // disposing the tree
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    }
  });
}
