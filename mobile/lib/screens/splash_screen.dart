import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _centerOpenController;
  late AnimationController _entryController;
  late AnimationController _pulseController;

  late Animation<double> _centerOpenAnimation;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _titleOffset;
  late Animation<double> _titleFade;
  late Animation<Offset> _subtitleOffset;
  late Animation<double> _subtitleFade;
  late Animation<double> _badgeScale;
  late Animation<double> _glowPulse;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // 1. Middle-out screen opening animation controller (1100ms)
    _centerOpenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // 2. Logo & text entry controller (1200ms)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // 3. Continuous breathing glow pulse controller (2000ms)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Center-out iris expand animation (starts at 0 in center and expands outward)
    _centerOpenAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _centerOpenController,
        curve: Curves.easeOutQuart,
      ),
    );

    // Logo scale: pop and settle from center
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // VEXA Title slide-up
    _titleOffset = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.25, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
      ),
    );

    // STYLE HUB Subtitle slide-up
    _subtitleOffset = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
      ),
    );

    // Badge scale & fade
    _badgeScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.55, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Continuous radial glow pulse
    _glowPulse = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Start middle-out open animation immediately on launch
    _centerOpenController.forward();
    _entryController.forward();
    _initializeAndNavigate();
  }

  void _navigateToNextScreen(Widget targetScreen) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 900),
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnim = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return AnimatedBuilder(
            animation: curvedAnim,
            builder: (context, child) {
              return ClipPath(
                clipper: _CenterOpenClipper(curvedAnim.value),
                child: child,
              );
            },
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _initializeAndNavigate() async {
    ApiConfig.autoDiscoverBackend();
    await Future.delayed(const Duration(milliseconds: 2600));
    await _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final user = await AuthService.getUser();
    if (!mounted) return;
    if (user != null && user.id != 'guest_user') {
      _navigateToNextScreen(const HomeScreen());
    } else if (user != null && user.id == 'guest_user') {
      final seen = await AuthService.isOnboardingSeen();
      if (seen) {
        _navigateToNextScreen(const HomeScreen());
      } else {
        _navigateToNextScreen(const OnboardingScreen());
      }
    } else {
      _navigateToNextScreen(const LoginScreen());
    }
  }

  @override
  void dispose() {
    _centerOpenController.dispose();
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          _checkAuthAndNavigate();
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _centerOpenAnimation,
          builder: (context, child) {
            return ClipPath(
              clipper: _CenterOpenClipper(_centerOpenAnimation.value),
              child: Container(
                color: AppTheme.backgroundColor,
                child: Stack(
                  children: [
                    // 1. Continuous Breathing Radial Glow
                    AnimatedBuilder(
                      animation: _glowPulse,
                      builder: (context, child) {
                        return Center(
                          child: Container(
                            width: 280 * _glowPulse.value,
                            height: 280 * _glowPulse.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFD4AF37).withAlpha((35 * _glowPulse.value).clamp(20, 50).toInt()),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withAlpha((60 * _glowPulse.value).clamp(30, 80).toInt()),
                                  blurRadius: 130 * _glowPulse.value,
                                  spreadRadius: 10 * _glowPulse.value,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // 2. Animated Brand Logo & Typography Center Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo Emblem (Scale + Fade Pop) - Sleek Black Box with Gold 'V'
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: const Color(0xFFB8860B).withAlpha(160), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFB8860B).withAlpha(100),
                                      blurRadius: 36,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withAlpha(200),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset(
                                    'assets/images/vexa_logo.png',
                                    width: 92,
                                    height: 92,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // VEXA Brand Title (Slide-Up + Fade)
                          SlideTransition(
                            position: _titleOffset,
                            child: FadeTransition(
                              opacity: _titleFade,
                              child: Text(
                                'V E X A',
                                style: GoogleFonts.cinzel(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 10,
                                  color: const Color(0xFFB8860B),
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFFB8860B).withAlpha(140),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // WEAR CONFIDENCE Tagline Subtitle (Slide-Up + Fade)
                          SlideTransition(
                            position: _subtitleOffset,
                            child: FadeTransition(
                              opacity: _subtitleFade,
                              child: Text(
                                'WEAR CONFIDENCE',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 5.5,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Luxury Badge (Staggered Scale)
                          ScaleTransition(
                            scale: _badgeScale,
                            child: FadeTransition(
                              opacity: _subtitleFade,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  border: Border.all(color: const Color(0xFFB8860B).withAlpha(160)),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFB8860B).withAlpha(40),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'LUXURY HEAVYWEIGHT ATTIRE • EST. 2026',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2.2,
                                    color: const Color(0xFFB8860B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom Clipper for Middle-Out Expanding Iris Circle Animation
class _CenterOpenClipper extends CustomClipper<Path> {
  final double progress;
  _CenterOpenClipper(this.progress);

  @override
  Path getClip(Size size) {
    if (progress >= 0.99) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final currentRadius = maxRadius * progress.clamp(0.0, 1.0);
    return Path()..addOval(Rect.fromCircle(center: center, radius: currentRadius));
  }

  @override
  bool shouldReclip(covariant _CenterOpenClipper oldClipper) => oldClipper.progress != progress;
}
