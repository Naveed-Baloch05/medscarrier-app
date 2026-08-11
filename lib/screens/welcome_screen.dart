import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/welcome_bloc.dart';
import '../bloc/welcome_event.dart';
import '../bloc/welcome_state.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WelcomeBloc(),
      child: Scaffold(
        body: BlocListener<WelcomeBloc, WelcomeState>(
          listener: (context, state) {
            if (state is NavigateToSignupState) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              );
            } else if (state is NavigateToLoginState) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Full Screen Background Image
              Image.asset(
                'assets/images/3rd image.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
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

              // 2. Dark Gradient Overlay at Top for High Text Contrast
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Top Heading Text ("Fitness Is Important As More")
              Positioned(
                top: MediaQuery.of(context).padding.top + 30,
                left: 28,
                right: 28,
                child: const Text(
                  'A Smarter Way to Get Your Prescriptions.',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.3,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        blurRadius: 12,
                        color: Colors.black45,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Bottom Action Buttons (Signup & Login floating over background)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 20,
                right: 20,
                child: BlocBuilder<WelcomeBloc, WelcomeState>(
                  builder: (context, state) {
                    return Row(
                      children: [
                        // Signup Button (Dark/Black)
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              onPressed: () {
                                BlocProvider.of<WelcomeBloc>(context)
                                    .add(SignupButtonPressed());
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
                        // Login Button (White)
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              onPressed: () {
                                BlocProvider.of<WelcomeBloc>(context)
                                    .add(LoginButtonPressed());
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
