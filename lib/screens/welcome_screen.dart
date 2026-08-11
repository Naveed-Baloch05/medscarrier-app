import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/welcome_bloc.dart';
import '../bloc/welcome_event.dart';
import '../bloc/welcome_state.dart';

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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigating to Signup...')),
              );
            } else if (state is NavigateToLoginState) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigating to Login...')),
              );
            }
          },
          child: Stack(
            children: [
              // 1. Fullscreen Background City Image
              Positioned.fill(
                child: Image.asset(
                  'assets/images/city_background.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF00584B),
                    child: const Center(
                      child: Icon(
                        Icons.location_city_rounded,
                        size: 120,
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Headline Overlay Text
              Positioned(
                top: 80,
                left: 24,
                right: 24,
                child: Text(
                  'Fitness Is\nImportant\nAs More',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: 6.0,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Rider Asset Placed in the Center
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 100.0, // Adjust offset as needed
                  ),
                  child: Image.asset(
                    'assets/images/rider.png',
                    width: MediaQuery.of(context).size.width * 0.75,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(
                      Icons.delivery_dining_rounded,
                      size: 140,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // 4. Bottom Action Buttons (Signup & Login)
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Builder(
                  builder: (blocContext) {
                    return Row(
                      children: [
                        // Signup Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              blocContext
                                  .read<WelcomeBloc>()
                                  .add(SignupButtonPressed());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Signup',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Login Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              blocContext
                                  .read<WelcomeBloc>()
                                  .add(LoginButtonPressed());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
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
