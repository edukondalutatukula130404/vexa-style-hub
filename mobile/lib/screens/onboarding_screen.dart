import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

const Color _gold = Color(0xFFB8860B);
const Color _goldDark = Color(0xFF8B6508);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _bgColor = Color(0xFFFAFAFC);
const Color _subtext = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);
const Color _textDark = Color(0xFF0F172A);

class OnboardingPageData {
  final String tag;
  final String title;
  final String subtitle;
  final IconData icon;
  final String imagePath;

  OnboardingPageData({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imagePath,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      tag: 'HAUTE COUTURE 2026',
      title: 'Discover Luxury\nOversized Apparel',
      subtitle: 'Sculpted from 240 GSM bio-washed heavy cotton with double-stitched collar reinforcement.',
      icon: Icons.checkroom_rounded,
      imagePath: 'assets/images/hero_luxury_tshirt.png',
    ),
    OnboardingPageData(
      tag: 'BESPOKE CUSTOMISATION',
      title: 'Personalized Embroidery\n& Custom Fits',
      subtitle: 'Tailor colorways, custom embroidery, and bulk orders tailored directly to your aesthetic.',
      icon: Icons.auto_awesome_rounded,
      imagePath: 'assets/images/promo_banner_2.png',
    ),
    OnboardingPageData(
      tag: 'EXPRESS DISPATCH & COD',
      title: 'Seamless Shopping\n& Fast Shipping',
      subtitle: 'Enjoy 2–4 day express delivery, Cash on Delivery support, and hassle-free 30-day returns.',
      icon: Icons.local_shipping_rounded,
      imagePath: 'assets/images/promo_banner_1.png',
    ),
  ];

  Future<void> _completeOnboarding() async {
    await AuthService.setOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Right Standalone Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.outfit(
                      color: _subtext,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // PageView Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Tag Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _gold.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _gold.withAlpha(80)),
                          ),
                          child: Text(
                            page.tag,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: _goldDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Image Preview Card
                        Container(
                          height: 240,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: _goldDark.withAlpha(25),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  page.imagePath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withAlpha(120),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _goldDark,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(80),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    page.icon,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                            letterSpacing: 1,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            color: _subtext,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Controls (Page Indicators + Next/Get Started)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: _currentPage == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _goldDark
                              : _subtext.withAlpha(80),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  // Next / Get Started Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _goldDark,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1 ? 'GET STARTED' : 'NEXT',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
