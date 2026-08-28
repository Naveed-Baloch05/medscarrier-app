import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medscarrier/bloc/admin_login/admin_login_bloc.dart';

import 'package:medscarrier/widgets/home_content.dart';
import 'package:medscarrier/screens/free_trial_screen.dart';
import 'package:medscarrier/screens/signup_screen.dart';
import 'package:medscarrier/screens/pharmacy_signup_screen.dart';
import 'package:medscarrier/screens/pharmacy_login_screen.dart';
import 'package:medscarrier/screens/rider_login_screen.dart';
import 'package:medscarrier/screens/rider_home_screen.dart';
import 'package:medscarrier/screens/rider_signup_screen.dart';
import 'package:medscarrier/screens/splash_screen.dart';
import 'package:medscarrier/screens/welcome_screen.dart';

void main() {
  testWidgets('WelcomeScreen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(
      find.text('A Smarter Way\nto Get Your\nPrescriptions.'),
      findsOneWidget,
    );
    expect(find.text('Signup'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('WelcomeScreen Signup button opens account type sheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    await tester.tap(find.text('Signup'));
    await tester.pumpAndSettle();

    expect(find.text('Pharmacy'), findsOneWidget);
    expect(find.text('Rider'), findsOneWidget);
  });

  testWidgets('WelcomeScreen Login button opens login type sheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Pharmacy'), findsOneWidget);
    expect(find.text('Rider'), findsOneWidget);
  });

  testWidgets('SignupScreen is responsive across Android screen sizes',
      (WidgetTester tester) async {
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

      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SignupScreen), findsOneWidget,
          reason: 'SignupScreen overflowed or failed to build at $size');

      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('FreeTrialScreen is responsive across Android screen sizes',
      (WidgetTester tester) async {
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

      await tester.pumpWidget(const MaterialApp(
        home: FreeTrialScreen(userId: 'test-user', email: 'test@example.com'),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(FreeTrialScreen), findsOneWidget,
          reason: 'FreeTrialScreen overflowed or failed to build at $size');

      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('HomeScreen content is responsive across Android screen sizes',
      (WidgetTester tester) async {
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

      // Active trial state
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HomeContent(remainingDays: 6)),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(HomeContent), findsOneWidget,
          reason: 'Active HomeContent overflowed or failed to build at $size');

      await tester.pumpWidget(const SizedBox());

      // Expired trial state
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: HomeContent(expired: true)),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(HomeContent), findsOneWidget,
          reason: 'Expired HomeContent overflowed or failed to build at $size');

      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('RiderSignupScreen is responsive across Android screen sizes',
      (WidgetTester tester) async {
    const sizes = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(360, 800),
      Size(412, 915),
      Size(600, 960),
      Size(800, 1280),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: RiderSignupScreen())));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RiderSignupScreen), findsOneWidget,
          reason: 'RiderSignupScreen overflowed or failed to build at $size');

      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('PharmacySignupScreen is responsive across Android screen sizes',
      (WidgetTester tester) async {
    const sizes = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(360, 800),
      Size(412, 915),
      Size(600, 960),
      Size(800, 1280),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(body: PharmacySignupScreen())));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PharmacySignupScreen), findsOneWidget,
          reason:
              'PharmacySignupScreen overflowed or failed to build at $size');

      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('PharmacyLoginScreen is responsive across Android screen sizes',
      (WidgetTester tester) async {
    const sizes = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(360, 800),
      Size(412, 915),
      Size(600, 960),
      Size(800, 1280),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(body: PharmacyLoginScreen())));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PharmacyLoginScreen), findsOneWidget,
          reason:
              'PharmacyLoginScreen overflowed or failed to build at $size');

      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('RiderLoginScreen is responsive across Android screen sizes',
      (WidgetTester tester) async {
    const sizes = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(360, 800),
      Size(412, 915),
      Size(600, 960),
      Size(800, 1280),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(body: RiderLoginScreen())));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RiderLoginScreen), findsOneWidget,
          reason:
              'RiderLoginScreen overflowed or failed to build at $size');

      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('RiderHomeScreen is responsive across Android screen sizes',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        const MaterialApp(home: RiderHomeScreen(riderId: 'test-rider')));
    await tester.pump();

    expect(find.byType(RiderHomeScreen), findsOneWidget);
  });

  testWidgets('SplashScreen navigates to WelcomeScreen via bloc',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: BlocProvider(
        create: (_) => AdminLoginBloc(),
        child: const SplashScreen(),
      ),
    ));
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
