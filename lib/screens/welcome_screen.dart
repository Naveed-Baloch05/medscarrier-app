import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/welcome_bloc.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WelcomeBloc(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocListener<WelcomeBloc, WelcomeState>(
          listener: (context, state) {
            if (state is NavigateToSignup) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigating to Signup...')),
              );
            } else if (state is NavigateToLogin) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigating to Login...')),
              );
            }
          },
          child: Column(
            children: [
              // --- Upper Hero Image & Text Section ---
              Expanded(
                flex: 55,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Background Hero Image
                    Image.asset(
                      'assets/images/hero_delivery.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0D534D), Color(0xFF00968A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.delivery_dining_rounded,
                            size: 120,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // 2. Subtle Dark Gradient Overlay at Top for Text Visibility
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withValues(alpha: 0.40),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Exact Reference Text (Left Aligned, Big Bold Font, High Position)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 24,
                      right: 24,
                      child: const Text(
                        'Medication\nIs Important\nFor Hea     lth',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 0.95,
                          letterSpacing: -0.8,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black38,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Bottom Branding & Actions Section ---
              Expanded(
                flex: 45,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Spacer(),

                                  // App Logo & Brand Name
                                  Column(
                                    children: [
                                      Image.asset(
                                        'assets/images/logo.png',
                                        height: 90,
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            const Icon(
                                          Icons.health_and_safety_rounded,
                                          size: 80,
                                          color: Color(0xFF00584B),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'MedScarrier',
                                        style: TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00584B),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Expanded(
                                            child: Divider(
                                              indent: 40,
                                              endIndent: 8,
                                              thickness: 1,
                                              color: Color(0xFFB0BEC5),
                                            ),
                                          ),
                                          Icon(
                                            Icons.show_chart,
                                            color: Color(0xFF00584B),
                                            size: 20,
                                          ),
                                          Expanded(
                                            child: Divider(
                                              indent: 8,
                                              endIndent: 40,
                                              thickness: 1,
                                              color: Color(0xFFB0BEC5),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Medicines Delivered,',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2E3E39),
                                        ),
                                      ),
                                      const Text(
                                        'Care Delivered.',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00584B),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const Spacer(),

                                  // Action Buttons
                                  BlocBuilder<WelcomeBloc, WelcomeState>(
                                    builder: (context, state) {
                                      return Row(
                                        children: [
                                          // Signup Button
                                          Expanded(
                                            child: SizedBox(
                                              height: 54,
                                              child: ElevatedButton(
                                                style:
                                                    ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.black,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      27,
                                                    ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  BlocProvider.of<
                                                          WelcomeBloc>(context)
                                                      .add(SignupPressed());
                                                },
                                                child: const Text(
                                                  'Signup',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          // Login Button
                                          Expanded(
                                            child: SizedBox(
                                              height: 54,
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  side: const BorderSide(
                                                    color: Colors.black26,
                                                    width: 1.2,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      27,
                                                    ),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  BlocProvider.of<
                                                          WelcomeBloc>(context)
                                                      .add(LoginPressed());
                                                },
                                                child: const Text(
                                                  'Login',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
