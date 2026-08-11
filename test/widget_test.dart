import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:medscarrier/bloc/splash_bloc.dart';
import 'package:medscarrier/screens/home_screen.dart';
import 'package:medscarrier/screens/splash_screen.dart';

void main() {
  testWidgets('HomeScreen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (context) => SplashBloc(),
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('MedsCarrier'), findsOneWidget);
    expect(find.text('Welcome to MedsCarrier'), findsOneWidget);
    expect(find.text('Flutter BLoC Project'), findsOneWidget);
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
    expect(find.byType(HomeScreen), findsNothing);
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

      // Let the SplashBloc timer finish before disposing the tree
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    }
  });
}
