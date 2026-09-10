import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/server_config_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _serverStatusText = 'Connecting to backend...';
  bool _isServerConnected = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)),
    );

    _controller.forward();

    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Probe backend server health
    final activeServer = await ApiConfig.autoDiscoverBackend();
    if (mounted) {
      setState(() {
        if (activeServer != null) {
          _isServerConnected = true;
          _serverStatusText = 'Connected to $activeServer';
        } else {
          _isServerConnected = false;
          _serverStatusText = 'Offline mode (Cannot reach ${ApiConfig.baseUrl})';
        }
      });
    }

    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background Gradient Glow
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withAlpha(40),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withAlpha(60),
                    blurRadius: 120,
                  ),
                ],
              ),
            ),
          ),
          // Top Bar Actions
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.settings_ethernet_rounded, color: AppTheme.accentColor, size: 24),
              tooltip: 'Server Connection Settings',
              onPressed: () => ServerConfigDialog.show(context),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Logo Icon Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.accentColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withAlpha(120),
                            blurRadius: 35,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.checkroom_rounded,
                        size: 58,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'VEXA',
                      style: GoogleFonts.outfit(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'STYLE HUB',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Loading Indicator
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.accentColor.withAlpha(220),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Live Server Connection Status Pill
                    ValueListenableBuilder<String>(
                      valueListenable: ApiConfig.baseUrlNotifier,
                      builder: (context, currentUrl, _) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isServerConnected
                                  ? AppTheme.successColor.withAlpha(100)
                                  : AppTheme.accentColor.withAlpha(60),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isServerConnected ? Icons.wifi_rounded : Icons.sync_rounded,
                                size: 14,
                                color: _isServerConnected ? AppTheme.successColor : AppTheme.accentColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _serverStatusText,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Footer text
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Luxury Fashion Redefined',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppTheme.subtextColor.withAlpha(160),
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
