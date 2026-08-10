import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/splash_bloc.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Detects whether the device is currently in Dark Mode or Light Mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Responsive screen dimensions
    final screenSize = MediaQuery.sizeOf(context);
    final screenHeight = screenSize.height;
    final shortestSide = screenSize.shortestSide;
    // Separate design per orientation: portrait image in portrait,
    // landscape image in landscape - both fill the screen edge-to-edge
    final isLandscape = screenSize.width > screenSize.height;
    final splashImage = isLandscape
        ? 'assets/images/splash_bg_landscape.png'
        : 'assets/images/splash_bg.png';

    // Loading indicator scales with the screen, clamped for sanity
    final indicatorSize = (shortestSide * 0.07).clamp(24.0, 40.0);
    final indicatorBottom = (screenHeight * 0.05).clamp(24.0, 60.0);

    return BlocProvider(
      create: (context) => SplashBloc(),
      child: Scaffold(
        // Automatically adapt background color based on active theme
        backgroundColor: isDarkMode ? const Color(0xFF10191B) : Colors.white,
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Splash Background Graphic - uses the matching design per
              // orientation so it always fills the screen edge-to-edge
              Image.asset(
                splashImage,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),

              // Bottom Loading Indicator - positioned proportionally
              Positioned(
                bottom: indicatorBottom,
                child: SizedBox(
                  width: indicatorSize,
                  height: indicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
