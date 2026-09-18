import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
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
    _navigateToNextScreen(const OnboardingScreen());
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
          _navigateToNextScreen(const OnboardingScreen());
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
                          // Logo Emblem (Scale + Fade Pop)
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8B6508), Color(0xFFD4AF37), Color(0xFFB8860B)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4AF37).withAlpha(150),
                                      blurRadius: 36,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.checkroom_rounded,
                                  size: 64,
                                  color: Colors.black,
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
                                'VEXA',
                                style: GoogleFonts.cinzel(
                                  fontSize: 58,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 12,
                                  color: const Color(0xFFD4AF37),
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFFD4AF37).withAlpha(120),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // STYLE HUB Subtitle (Slide-Up + Fade)
                          SlideTransition(
                            position: _subtitleOffset,
                            child: FadeTransition(
                              opacity: _subtitleFade,
                              child: Text(
                                'STYLE HUB',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 6,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Luxury Badge (Staggered Scale)
                          ScaleTransition(
                            scale: _badgeScale,
                            child: FadeTransition(
                              opacity: _subtitleFade,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(140),
                                  border: Border.all(color: const Color(0xFFD4AF37).withAlpha(160)),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4AF37).withAlpha(30),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'LUXURY HEAVYWEIGHT ATTIRE',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.5,
                                    color: const Color(0xFFD4AF37),
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
