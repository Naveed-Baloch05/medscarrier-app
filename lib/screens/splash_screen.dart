import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/splash/splash_bloc.dart';
import '../bloc/splash/splash_event.dart';
import '../bloc/splash/splash_state.dart';
import '../bloc/admin_login/admin_login_bloc.dart';
import '../bloc/admin_login/admin_login_event.dart';
import '../bloc/admin_login/admin_login_state.dart';
import '../bloc/admin_dashboard/admin_dashboard_bloc.dart';
import 'welcome_screen.dart';
import '../admin/screens/admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const Color primaryGreen = Color(0xFF0F7253);
  static const Color darkGreen = Color(0xFF0F7253);
  static const Color darkAccentGreen = Color(0xFF32C787);
  static const Color lightMint = Color(0xFFE6F5ED);
  static const Color backgroundWhite = Color(0xFFF2F5F3);
  static const Color backgroundDark = Color(0xFF0C1310);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    // --------------------------------------------------------
    // Check if admin is already signed in (keep-me-signed-in)
    // --------------------------------------------------------
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<AdminLoginBloc>().add(
              const AdminLoginLoadRequested(),
            );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final shortestSide = screenSize.shortestSide;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandFontSize = (shortestSide * 0.088).clamp(24.0, 40.0);
    final logoHeight = (shortestSide * 0.21).clamp(54.0, 110.0);

    return BlocProvider(
      create: (_) => SplashBloc()..add(AppStarted()),
      child: MultiBlocListener(
      listeners: [
        // --------------------------------------------------
        // Splash timer → navigate to WelcomeScreen
        // --------------------------------------------------
        BlocListener<SplashBloc, SplashState>(
          listener: (context, state) {
            if (state is SplashNavigated) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const WelcomeScreen(),
                ),
              );
            }
          },
        ),
        // --------------------------------------------------
        // Admin auto-login → navigate to AdminDashboard
        // --------------------------------------------------
        BlocListener<AdminLoginBloc, AdminLoginState>(
          listener: (context, state) {
            if (state is AdminLoginSuccess) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => AdminDashboardBloc(),
                    child: const AdminDashboardScreen(),
                  ),
                ),
              );
            }
            // AdminLoginUnauthorized → ignore, let splash timer handle
            // AdminLoginError → ignore, let splash timer handle
          },
        ),
      ],
      child: BlocBuilder<SplashBloc, SplashState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor:
                isDark ? SplashScreen.backgroundDark : SplashScreen.backgroundWhite,
            body: Stack(
              children: [
                _buildBackgroundCircles(screenSize, isDark),
                Positioned(
                  top: screenSize.height * 0.12,
                  left: screenSize.width * 0.1,
                  child: _buildMedicalCross(size: 16, opacity: 0.35),
                ),
                Positioned(
                  top: screenSize.height * 0.16,
                  right: screenSize.width * 0.08,
                  child: _buildMedicalCross(size: 22, opacity: 0.45),
                ),
                SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 12),
                          _buildBrandHeader(isDark, brandFontSize, logoHeight),
                          Flexible(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 420,
                                  maxHeight: 420,
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1.1,
                                  child: Image.asset(
                                    'assets/images/rider_scooter.png',
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildRiderPlaceholder(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 36.0),
                            child: _buildAnimatedProgressBar(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }

  Widget _buildBackgroundCircles(Size screenSize, bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: -screenSize.width * 0.15,
          left: -screenSize.width * 0.2,
          child: Container(
            width: screenSize.width * 0.55,
            height: screenSize.width * 0.55,
            decoration: BoxDecoration(
              color: SplashScreen.primaryGreen.withValues(
                alpha: isDark ? 0.08 : 0.12,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -screenSize.width * 0.1,
          left: -screenSize.width * 0.15,
          child: Container(
            width: screenSize.width * 0.45,
            height: screenSize.width * 0.45,
            decoration: BoxDecoration(
              color: SplashScreen.primaryGreen.withValues(
                alpha: isDark ? 0.05 : 0.08,
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandHeader(bool isDark, double fontSize, double logoHeight) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: logoHeight,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                _buildLogoPlaceholder(),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'MedScarrier',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : SplashScreen.darkGreen,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 1.5,
              color: SplashScreen.primaryGreen.withValues(alpha: 0.3),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.0),
              child: Icon(
                Icons.show_chart_rounded,
                size: 20,
                color: SplashScreen.primaryGreen,
              ),
            ),
            Container(
              width: 32,
              height: 1.5,
              color: SplashScreen.primaryGreen.withValues(alpha: 0.3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedProgressBar() {
    return SizedBox(
      width: 72,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: const LinearProgressIndicator(
          value: 1.0,
          backgroundColor: Color(0xFFE2E8E5),
          valueColor: AlwaysStoppedAnimation<Color>(SplashScreen.primaryGreen),
        ),
      ),
    );
  }

  Widget _buildMedicalCross({required double size, required double opacity}) {
    return Icon(
      Icons.add_rounded,
      size: size,
      color: SplashScreen.primaryGreen.withValues(alpha: opacity),
    );
  }

  Widget _buildLogoPlaceholder() {
    return const Icon(
      Icons.health_and_safety_rounded,
      size: 64,
      color: SplashScreen.primaryGreen,
    );
  }

  Widget _buildRiderPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: SplashScreen.lightMint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Icon(
          Icons.delivery_dining_rounded,
          size: 100,
          color: SplashScreen.primaryGreen,
        ),
      ),
    );
  }
}
