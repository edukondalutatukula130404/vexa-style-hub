import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

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
  final List<String> highlights;

  OnboardingPageData({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.imagePath,
    required this.highlights,
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
      subtitle: 'Sculpted from 240 GSM bio-washed heavy cotton with double-stitched collar reinforcement for structural fit.',
      icon: Icons.checkroom_rounded,
      imagePath: 'assets/images/hero_luxury_tshirt.png',
      highlights: ['240 GSM Heavyweight', 'Bio-Washed Cotton', 'Double Stitched Collar'],
    ),
    OnboardingPageData(
      tag: 'BESPOKE CUSTOMISATION',
      title: 'Personalized Embroidery\n& Custom Fits',
      subtitle: 'Tailor custom colorways, bespoke embroidery badges, and bulk custom tee orders matched to your aesthetic.',
      icon: Icons.auto_awesome_rounded,
      imagePath: 'assets/images/promo_banner_2.png',
      highlights: ['Custom Embroidery', 'Bespoke Colorways', 'Bulk Orders'],
    ),
    OnboardingPageData(
      tag: 'EXPRESS DISPATCH & COD',
      title: 'Seamless Shopping\n& Fast Delivery',
      subtitle: 'Enjoy 2–4 day express delivery across India, Cash on Delivery support, and hassle-free 30-day returns.',
      icon: Icons.local_shipping_rounded,
      imagePath: 'assets/images/promo_banner_1.png',
      highlights: ['2–4 Day Delivery', 'Cash on Delivery', '30-Day Easy Returns'],
    ),
  ];

  Future<void> _completeOnboarding() async {
    await AuthService.setOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
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
            // Top App Bar Controls (Back Button, Logo Emblem & Skip Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset(
                            'assets/images/vexa_logo.png',
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'V E X A',
                            style: GoogleFonts.cinzel(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              fontSize: 16,
                              color: _gold,
                            ),
                          ),
                          Text(
                            'WEAR CONFIDENCE',
                            style: GoogleFonts.outfit(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.8,
                              color: _subtext,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
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
                ],
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
                  return SingleChildScrollView(
                    child: Padding(
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
                          const SizedBox(height: 24),

                          // Image Preview Card
                          Container(
                            height: 270,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: _border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(18),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
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
                                    alignment: Alignment.topCenter,
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
                                          Colors.black.withAlpha(100),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _goldDark,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(60),
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
                          const SizedBox(height: 24),

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
                          const SizedBox(height: 10),
                          Text(
                            page.subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              color: _subtext,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Highlight Chips
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: page.highlights.map((h) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(8),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 14, color: _goldDark),
                                    const SizedBox(width: 6),
                                    Text(
                                      h,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: _textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
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
                        width: _currentPage == index ? 28 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _goldDark
                              : _subtext.withAlpha(60),
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
