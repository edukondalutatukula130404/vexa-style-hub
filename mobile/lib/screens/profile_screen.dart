import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import 'cart_screen.dart';
import 'order_tracking_screen.dart';


// ── Gold & White Luxury Theme Tokens ───────────────────────────────────────
const Color _gold = Color(0xFFB8860B);
const Color _goldDark = Color(0xFF8B6508);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _surfaceBg = Color(0xFFF1F5F9);
const Color _bgColor = Color(0xFFFAFAFC);
const Color _subtext = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);
const Color _textDark = Color(0xFF0F172A);
const Color _successGreen = Color(0xFF10B981);
const Color _errorRed = Color(0xFFEF4444);

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDiscover;
  const ProfileScreen({super.key, this.onNavigateToDiscover});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoadingUser = true;
  double _walletBalance = 2500.0;
  bool _dropAlertsEnabled = true;
  String _selectedCurrency = 'India (INR ₹)';
  final List<Map<String, dynamic>> _walletTransactions = [
    {
      'title': 'Wallet Top-up via GPay UPI',
      'sub': '22 Sep 2026 · 10:45 AM',
      'amount': '+₹2,000',
      'isCredit': true,
    },
    {
      'title': 'Cashback Reward #VEXA-8942',
      'sub': '18 Sep 2026 · 04:20 PM',
      'amount': '+₹500',
      'isCredit': true,
    },
  ];

  // Login Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoggingIn = false;
  String? _loginError;

  bool get _isRealUser => _currentUser != null && _currentUser!.id != 'guest_user';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _handleInlineLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoggingIn = true;
      _loginError = null;
    });

    final result = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'] as UserModel;
      final token = (result['token'] as String?) ?? 'mock_token';
      await AuthService.saveSession(user, token);
      await AuthService.setOnboardingSeen();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${user.name}!'),
          backgroundColor: _successGreen,
        ),
      );
      setState(() {
        _currentUser = user;
        _isLoggingIn = false;
        _emailController.clear();
        _passwordController.clear();
      });

      if (widget.onNavigateToDiscover != null) {
        widget.onNavigateToDiscover!();
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } else {
      setState(() {
        _isLoggingIn = false;
        _loginError = result['message'] ?? 'Sign in failed. Check your credentials.';
      });
    }
  }

  Future<void> _handleGuestAccess() async {
    final guestUser = UserModel(
      id: 'guest_user',
      name: 'Guest Collector',
      email: 'guest@vexa.app',
      role: 'guest',
    );
    await AuthService.saveSession(guestUser, 'guest_token');
    if (!mounted) return;
    setState(() {
      _currentUser = guestUser;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'Browsing as Guest Collector!',
              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: _goldDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );

    Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _cardBg,
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: _errorRed, size: 22),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your VEXA Style Hub account?',
          style: GoogleFonts.outfit(color: _subtext, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: _subtext, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              await AuthService.clearSession();
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() {
                _currentUser = null;
              });
            },
            child: Text('Log Out', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBrandStoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/vexa_logo.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VEXA STYLE HUB', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 2)),
                    Text('WEAR CONFIDENCE • EST. 2026', style: GoogleFonts.outfit(fontSize: 10, color: _subtext, letterSpacing: 1.5)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Engineered for those who appreciate heavyweight luxury streetwear. Every garment is crafted from 240 GSM combed long-staple cotton, pre-shrunk, bio-washed, and tailored with double-stitched collar reinforcement.',
              style: GoogleFonts.outfit(fontSize: 13, color: _subtext, height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _goldDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('CLOSE', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _isRealUser
          ? AppBar(
              backgroundColor: _bgColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
                onPressed: () {
                  if (widget.onNavigateToDiscover != null) {
                    widget.onNavigateToDiscover!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
              ),
              centerTitle: false,
              titleSpacing: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _gold.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _gold.withAlpha(80)),
                    ),
                    child: const Icon(Icons.person_outline_rounded, color: _goldDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROFILE & SETTINGS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cinzel(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 1.5,
                            color: _textDark,
                          ),
                        ),
                        Text(
                          'Manage account & preferences',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 10.5, color: _subtext),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : _isRealUser
              ? SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildLoggedInProfileContent(),
                    ),
                  ),
                )
              : _buildReferenceLoginForm(),
    );
  }

  // ── REFERENCE IMAGE MATCHED LOGIN VIEW (VEXA LUXURY THEME) ────────────────
  Widget _buildReferenceLoginForm() {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── HERO TOP HEADER REGION ──────────────────────────────────────
          Container(
            width: double.infinity,
            height: 270 + topPadding,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF2E241B),
                  Color(0xFF5C431F),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background Luxury Image Overlay
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/hero_luxury_tshirt.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0F172A).withAlpha(220),
                          const Color(0xFF1E293B).withAlpha(180),
                          const Color(0xFF3D2C1B).withAlpha(160),
                        ],
                      ),
                    ),
                  ),
                ),

                // Top Left Back Button
                Positioned(
                  top: topPadding + 12,
                  left: 20,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (widget.onNavigateToDiscover != null) {
                          widget.onNavigateToDiscover!();
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacementNamed(context, '/home');
                        }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(200), width: 1.2),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ),

                // Top Right Guest Pill Button
                Positioned(
                  top: topPadding + 12,
                  right: 20,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleGuestAccess,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(35),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withAlpha(200), width: 1.2),
                        ),
                        child: Text(
                          'Guest',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Centered Floating Logo Card & Welcome Back Text
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: topPadding),
                      // Floating Brand Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/vexa_logo.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'VEXA STYLE HUB',
                              style: GoogleFonts.cinzel(
                                color: _goldDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── BOTTOM ROUNDED SHEET CONTAINER ──────────────────────────────
          Transform.translate(
            offset: const Offset(0, -24),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Handle Indicator
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section Title
                    Text(
                      'SIGN IN TO YOUR ACCOUNT',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: _goldDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your registered phone number or email to continue.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Error Box if any
                    if (_loginError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _errorRed.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _errorRed.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: _errorRed, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _loginError!,
                                style: GoogleFonts.outfit(color: _errorRed, fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Input Field: Email or Phone
                    Text(
                      'Phone number or email',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email or phone number';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'name@example.com · 9876...',
                        hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13.5),
                        prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF64748B), size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _goldDark, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    Text(
                      'Password',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: const Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _goldDark, width: 1.5),
                        ),
                      ),
                    ),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/forget'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.outfit(
                            color: _goldDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Primary Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _goldDark,
                          elevation: 3,
                          shadowColor: _goldDark.withAlpha(60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isLoggingIn ? null : _handleInlineLogin,
                        child: _isLoggingIn
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                'Continue',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Register Prompt Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13.5),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/register'),
                          child: Text(
                            'Register',
                            style: GoogleFonts.outfit(
                              color: _goldDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LOGGED-IN PROFILE VIEW CONTENT ────────────────────────────────────────
  Widget _buildLoggedInProfileContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Luxury User Hero Card
        _buildUserHeroCard(),

        const SizedBox(height: 20),

        // 2. Quick Action Shortcuts Grid
        _buildShortcutsGrid(),

        const SizedBox(height: 20),

        // 3. Preferences & Settings List Card
        _buildPreferencesCard(),

        const SizedBox(height: 24),

        // 4. Log Out Action Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _errorRed, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: _errorRed, size: 18),
            label: Text(
              'LOG OUT ACCOUNT',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1, color: _errorRed),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 5. Brand Footer
        Center(
          child: Column(
            children: [
              Text(
                '✦  VEXA STYLE HUB  ✦',
                style: GoogleFonts.cinzel(fontSize: 10, letterSpacing: 3, color: _goldDark, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 1.0.0 (Production Build)',
                style: GoogleFonts.outfit(fontSize: 10, color: _subtext),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAvatarWidget(String? avatarUrl, String name, {double size = 64, double fontSize = 26}) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('assets/')) {
        return ClipOval(
          child: Image.asset(
            avatarUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Center(
              child: Text(
                initial,
                style: GoogleFonts.cinzel(fontSize: fontSize, fontWeight: FontWeight.bold, color: _goldDark),
              ),
            ),
          ),
        );
      } else if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
        return ClipOval(
          child: Image.network(
            avatarUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Center(
              child: Text(
                initial,
                style: GoogleFonts.cinzel(fontSize: fontSize, fontWeight: FontWeight.bold, color: _goldDark),
              ),
            ),
          ),
        );
      } else {
        try {
          final file = File(avatarUrl);
          if (file.existsSync()) {
            return ClipOval(
              child: Image.file(
                file,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.cinzel(fontSize: fontSize, fontWeight: FontWeight.bold, color: _goldDark),
                  ),
                ),
              ),
            );
          }
        } catch (_) {}
      }
    }
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.cinzel(fontSize: fontSize, fontWeight: FontWeight.bold, color: _goldDark),
      ),
    );
  }

  Future<void> _updateProfileAvatar(String newAvatarUrl) async {
    final user = _currentUser ?? UserModel(id: 'user_1', name: 'User', email: 'user@vexa.app', role: 'user');
    final updated = UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      avatarUrl: newAvatarUrl,
    );
    await AuthService.saveSession(updated, 'user_token');
    if (mounted) {
      setState(() {
        _currentUser = updated;
      });
    }
  }

  Future<void> _pickImage(ImageSource source, Function(String) onSelected, BuildContext modalCtx) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picker = ImagePicker();
      // pickImage explicitly filters for static image types only (excludes videos)
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (image != null) {
        final pathLower = image.path.toLowerCase();
        // Guard against any video extensions if passed by file system intents
        if (pathLower.endsWith('.mp4') ||
            pathLower.endsWith('.mov') ||
            pathLower.endsWith('.avi') ||
            pathLower.endsWith('.mkv') ||
            pathLower.endsWith('.webm') ||
            pathLower.endsWith('.3gp')) {
          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  'Please select a photo image file (videos are not allowed for profile pictures).',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: _errorRed,
              ),
            );
          }
          return;
        }
        if (modalCtx.mounted) Navigator.pop(modalCtx);
        onSelected(image.path);
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Could not open photo selector: $e'),
            backgroundColor: _errorRed,
          ),
        );
      }
    }
  }

  void _showAvatarPickerModal(Function(String) onAvatarSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 42, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(
              'CHOOSE PROFILE PICTURE',
              style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            Text(
              'Select photo source: Device Gallery, Camera capture, or Google Photos.',
              style: GoogleFonts.outfit(fontSize: 12, color: _subtext),
            ),
            const SizedBox(height: 20),

            // ── 3 PRIMARY ACTION CARDS: GALLERY, CAMERA, GOOGLE PHOTOS ─────────────
            Row(
              children: [
                // 1. Device Gallery (Images Only)
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImage(ImageSource.gallery, onAvatarSelected, ctx),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _surfaceBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB), size: 24),
                          ),
                          const SizedBox(height: 10),
                          Text('Gallery', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                          const SizedBox(height: 2),
                          Text('Device Photos', style: GoogleFonts.outfit(fontSize: 9.5, color: _subtext)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Camera Capture (Photo Only)
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImage(ImageSource.camera, onAvatarSelected, ctx),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _surfaceBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF10B981), size: 24),
                          ),
                          const SizedBox(height: 10),
                          Text('Camera', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                          const SizedBox(height: 2),
                          Text('Take Photo', style: GoogleFonts.outfit(fontSize: 9.5, color: _subtext)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 3. Google Photos Option (Cloud Photos / Albums)
                Expanded(
                  child: InkWell(
                    onTap: () => _pickImage(ImageSource.gallery, onAvatarSelected, ctx),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _surfaceBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFEA4335).withAlpha(100), width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA4335).withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.collections_bookmark_rounded, color: Color(0xFFEA4335), size: 24),
                          ),
                          const SizedBox(height: 10),
                          Text('Google Photos', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: _textDark)),
                          const SizedBox(height: 2),
                          Text('Cloud Photos', style: GoogleFonts.outfit(fontSize: 9.5, color: _subtext, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showCropImageModal(String imagePath, Function(String) onCropped) {
    if (imagePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please choose a profile photo first to crop.',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: _errorRed,
        ),
      );
      return;
    }

    const double canvasW = 300.0;
    const double canvasH = 300.0;
    const double minBoxSize = 70.0;

    double cropLeft = 35.0;
    double cropTop = 35.0;
    double cropW = 230.0;
    double cropH = 230.0;
    int rotationDegrees = 0;
    String selectedAspect = '1:1';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (cropCtx) {
        return StatefulBuilder(
          builder: (context, setCropState) {
            Widget buildCornerHandle(double x, double y, Function(DragUpdateDetails) onPan) {
              return Positioned(
                left: x - 14,
                top: y - 14,
                child: GestureDetector(
                  onPanUpdate: onPan,
                  child: Container(
                    width: 28,
                    height: 28,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _goldDark, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(60),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            Widget buildEdgeHandle(double x, double y, bool isHorizontal, Function(DragUpdateDetails) onPan) {
              return Positioned(
                left: x - (isHorizontal ? 16 : 8),
                top: y - (isHorizontal ? 8 : 16),
                child: GestureDetector(
                  onPanUpdate: onPan,
                  child: Container(
                    width: isHorizontal ? 32 : 16,
                    height: isHorizontal ? 16 : 32,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: isHorizontal ? 22 : 6,
                        height: isHorizontal ? 6 : 22,
                        decoration: BoxDecoration(
                          color: _goldDark,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(50),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return Container(
              height: MediaQuery.of(cropCtx).size.height * 0.86,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Center(
                    child: Container(width: 42, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: _gold.withAlpha(25), shape: BoxShape.circle),
                              child: const Icon(Icons.crop_rounded, color: _goldDark, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CROP PHOTO EDGES',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1),
                                  ),
                                  Text(
                                    'Drag corner and edge handles to adjust crop rectangle',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(fontSize: 11, color: _subtext),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: _subtext),
                        onPressed: () => Navigator.pop(cropCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── INTERACTIVE CANVAS WITH EDGE CROP BOX & HANDLES ──────────
                  Expanded(
                    child: Center(
                      child: Container(
                        width: canvasW,
                        height: canvasH,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // 1. Base Rotatable Image
                              Positioned.fill(
                                child: Center(
                                  child: Transform.rotate(
                                    angle: rotationDegrees * (3.1415926535897932 / 180),
                                    child: _buildAvatarWidget(imagePath, _currentUser?.name ?? 'User', size: canvasW, fontSize: 80),
                                  ),
                                ),
                              ),

                              // 2. Dimmed Mask Outside Crop Area
                              // Top Dim
                              Positioned(
                                top: 0,
                                left: 0,
                                width: canvasW,
                                height: cropTop,
                                child: Container(color: Colors.black.withAlpha(160)),
                              ),
                              // Bottom Dim
                              Positioned(
                                top: cropTop + cropH,
                                left: 0,
                                width: canvasW,
                                height: (canvasH - (cropTop + cropH)).clamp(0.0, canvasH),
                                child: Container(color: Colors.black.withAlpha(160)),
                              ),
                              // Left Dim
                              Positioned(
                                top: cropTop,
                                left: 0,
                                width: cropLeft,
                                height: cropH,
                                child: Container(color: Colors.black.withAlpha(160)),
                              ),
                              // Right Dim
                              Positioned(
                                top: cropTop,
                                left: cropLeft + cropW,
                                width: (canvasW - (cropLeft + cropW)).clamp(0.0, canvasW),
                                height: cropH,
                                child: Container(color: Colors.black.withAlpha(160)),
                              ),

                              // 3. Draggable Center Body
                              Positioned(
                                left: cropLeft,
                                top: cropTop,
                                width: cropW,
                                height: cropH,
                                child: GestureDetector(
                                  onPanUpdate: (d) {
                                    setCropState(() {
                                      cropLeft = (cropLeft + d.delta.dx).clamp(0.0, canvasW - cropW);
                                      cropTop = (cropTop + d.delta.dy).clamp(0.0, canvasH - cropH);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: _goldDark, width: 2),
                                      color: Colors.transparent,
                                    ),
                                    child: Stack(
                                      children: [
                                        // Gridlines 3x3
                                        Column(
                                          children: [
                                            Expanded(child: Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withAlpha(60), width: 1))))),
                                            Expanded(child: Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withAlpha(60), width: 1))))),
                                            const Expanded(child: SizedBox()),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Expanded(child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withAlpha(60), width: 1))))),
                                            Expanded(child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white.withAlpha(60), width: 1))))),
                                            const Expanded(child: SizedBox()),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // 4. Corner Drag Handles
                              // Top-Left
                              buildCornerHandle(cropLeft, cropTop, (d) {
                                setCropState(() {
                                  double nLeft = (cropLeft + d.delta.dx).clamp(0.0, cropLeft + cropW - minBoxSize);
                                  double nTop = (cropTop + d.delta.dy).clamp(0.0, cropTop + cropH - minBoxSize);
                                  cropW += (cropLeft - nLeft);
                                  cropH += (cropTop - nTop);
                                  cropLeft = nLeft;
                                  cropTop = nTop;
                                });
                              }),
                              // Top-Right
                              buildCornerHandle(cropLeft + cropW, cropTop, (d) {
                                setCropState(() {
                                  double nRight = (cropLeft + cropW + d.delta.dx).clamp(cropLeft + minBoxSize, canvasW);
                                  double nTop = (cropTop + d.delta.dy).clamp(0.0, cropTop + cropH - minBoxSize);
                                  cropW = nRight - cropLeft;
                                  cropH += (cropTop - nTop);
                                  cropTop = nTop;
                                });
                              }),
                              // Bottom-Left
                              buildCornerHandle(cropLeft, cropTop + cropH, (d) {
                                setCropState(() {
                                  double nLeft = (cropLeft + d.delta.dx).clamp(0.0, cropLeft + cropW - minBoxSize);
                                  double nBottom = (cropTop + cropH + d.delta.dy).clamp(cropTop + minBoxSize, canvasH);
                                  cropW += (cropLeft - nLeft);
                                  cropLeft = nLeft;
                                  cropH = nBottom - cropTop;
                                });
                              }),
                              // Bottom-Right
                              buildCornerHandle(cropLeft + cropW, cropTop + cropH, (d) {
                                setCropState(() {
                                  double nRight = (cropLeft + cropW + d.delta.dx).clamp(cropLeft + minBoxSize, canvasW);
                                  double nBottom = (cropTop + cropH + d.delta.dy).clamp(cropTop + minBoxSize, canvasH);
                                  cropW = nRight - cropLeft;
                                  cropH = nBottom - cropTop;
                                });
                              }),

                              // 5. Edge Midpoint Handles
                              // Top Edge
                              buildEdgeHandle(cropLeft + (cropW / 2), cropTop, true, (d) {
                                setCropState(() {
                                  double nTop = (cropTop + d.delta.dy).clamp(0.0, cropTop + cropH - minBoxSize);
                                  cropH += (cropTop - nTop);
                                  cropTop = nTop;
                                });
                              }),
                              // Bottom Edge
                              buildEdgeHandle(cropLeft + (cropW / 2), cropTop + cropH, true, (d) {
                                setCropState(() {
                                  double nBottom = (cropTop + cropH + d.delta.dy).clamp(cropTop + minBoxSize, canvasH);
                                  cropH = nBottom - cropTop;
                                });
                              }),
                              // Left Edge
                              buildEdgeHandle(cropLeft, cropTop + (cropH / 2), false, (d) {
                                setCropState(() {
                                  double nLeft = (cropLeft + d.delta.dx).clamp(0.0, cropLeft + cropW - minBoxSize);
                                  cropW += (cropLeft - nLeft);
                                  cropLeft = nLeft;
                                });
                              }),
                              // Right Edge
                              buildEdgeHandle(cropLeft + cropW, cropTop + (cropH / 2), false, (d) {
                                setCropState(() {
                                  double nRight = (cropLeft + cropW + d.delta.dx).clamp(cropLeft + minBoxSize, canvasW);
                                  cropW = nRight - cropLeft;
                                });
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── ASPECT RATIO SELECTION CHIPS ─────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ('1:1 Profile', 220.0, 220.0),
                        ('Free Edge', 240.0, 200.0),
                        ('4:3', 240.0, 180.0),
                        ('16:9', 260.0, 146.0),
                      ].map((asp) {
                        final title = asp.$1;
                        final w = asp.$2;
                        final h = asp.$3;
                        final isSelected = selectedAspect == title;

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : _textDark,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: _goldDark,
                            backgroundColor: _surfaceBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: isSelected ? _goldDark : _border),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setCropState(() {
                                  selectedAspect = title;
                                  cropW = w.clamp(minBoxSize, canvasW);
                                  cropH = h.clamp(minBoxSize, canvasH);
                                  cropLeft = ((canvasW - cropW) / 2).clamp(0.0, canvasW);
                                  cropTop = ((canvasH - cropH) / 2).clamp(0.0, canvasH);
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── TOOLBAR: ROTATE & RESET ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () {
                          setCropState(() {
                            rotationDegrees = (rotationDegrees + 90) % 360;
                          });
                        },
                        icon: const Icon(Icons.rotate_right_rounded, size: 16, color: _goldDark),
                        label: Text('Rotate 90°', style: GoogleFonts.outfit(fontSize: 12, color: _textDark, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () {
                          setCropState(() {
                            cropLeft = 35.0;
                            cropTop = 35.0;
                            cropW = 230.0;
                            cropH = 230.0;
                            rotationDegrees = 0;
                            selectedAspect = '1:1 Profile';
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: _subtext),
                        label: Text('Reset Edges', style: GoogleFonts.outfit(fontSize: 12, color: _subtext, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── APPLY CROP BUTTON ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _goldDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        onCropped(imagePath);
                        Navigator.pop(cropCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.crop_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text('Edge crop applied successfully!', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            backgroundColor: _successGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                      label: Text(
                        'APPLY CROP',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 1. Edit Profile Full Screen View
  void _showEditProfileModal() {
    final nameCtrl = TextEditingController(text: _currentUser?.name ?? '');
    final companyCtrl = TextEditingController(text: _currentUser?.companyName ?? 'VEXA Style Hub');
    final emailCtrl = TextEditingController(text: _currentUser?.email ?? '');
    final phoneCtrl = TextEditingController(text: '+91 98765 43210');
    final cityCtrl = TextEditingController(text: 'Hyderabad, Telangana');
    String selectedAvatar = _currentUser?.avatarUrl ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModalState) => Scaffold(
            backgroundColor: _bgColor,
            appBar: AppBar(
              backgroundColor: _cardBg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: _textDark),
                onPressed: () => Navigator.pop(ctx),
              ),
              title: Text(
                'EDIT ACCOUNT PROFILE',
                style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _showAvatarPickerModal((newUrl) {
                              _updateProfileAvatar(newUrl);
                              setModalState(() {
                                selectedAvatar = newUrl;
                              });
                              _showCropImageModal(newUrl, (croppedUrl) {
                                _updateProfileAvatar(croppedUrl);
                                setModalState(() {
                                  selectedAvatar = croppedUrl;
                                });
                              });
                            });
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _gold.withAlpha(25),
                                  border: Border.all(color: _gold, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _gold.withAlpha(40),
                                      blurRadius: 14,
                                    ),
                                  ],
                                ),
                                child: _buildAvatarWidget(selectedAvatar, nameCtrl.text, size: 90, fontSize: 36),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: _goldDark,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            InkWell(
                              onTap: () {
                                _showAvatarPickerModal((newUrl) {
                                  _updateProfileAvatar(newUrl);
                                  setModalState(() {
                                    selectedAvatar = newUrl;
                                  });
                                  _showCropImageModal(newUrl, (croppedUrl) {
                                    _updateProfileAvatar(croppedUrl);
                                    setModalState(() {
                                      selectedAvatar = croppedUrl;
                                    });
                                  });
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _surfaceBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.photo_camera_rounded, size: 15, color: _goldDark),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Change Photo',
                                      style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: _textDark),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () {
                                _showCropImageModal(selectedAvatar, (croppedUrl) {
                                  _updateProfileAvatar(croppedUrl);
                                  setModalState(() {
                                    selectedAvatar = croppedUrl;
                                  });
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _gold.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _gold.withAlpha(100)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.crop_rounded, size: 15, color: _goldDark),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Crop Image',
                                      style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: _goldDark),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'PERSONAL INFORMATION',
                    style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nameCtrl,
                    style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: GoogleFonts.outfit(color: _subtext),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: _goldDark),
                      filled: true,
                      fillColor: _cardBg,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _goldDark, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: companyCtrl,
                    style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Company Name',
                      labelStyle: GoogleFonts.outfit(color: _subtext),
                      prefixIcon: const Icon(Icons.business_rounded, color: _goldDark),
                      filled: true,
                      fillColor: _cardBg,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _goldDark, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: emailCtrl,
                    style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: GoogleFonts.outfit(color: _subtext),
                      prefixIcon: const Icon(Icons.email_outlined, color: _goldDark),
                      filled: true,
                      fillColor: _cardBg,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _goldDark, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: phoneCtrl,
                    style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: GoogleFonts.outfit(color: _subtext),
                      prefixIcon: const Icon(Icons.phone_outlined, color: _goldDark),
                      filled: true,
                      fillColor: _cardBg,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _goldDark, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: cityCtrl,
                    style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Primary Location',
                      labelStyle: GoogleFonts.outfit(color: _subtext),
                      prefixIcon: const Icon(Icons.location_city_outlined, color: _goldDark),
                      filled: true,
                      fillColor: _cardBg,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _goldDark, width: 1.5)),
                    ),
                  ),

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _goldDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final updatedUser = UserModel(
                          id: _currentUser?.id ?? 'user_1',
                          name: nameCtrl.text.trim(),
                          companyName: companyCtrl.text.trim().isNotEmpty ? companyCtrl.text.trim() : 'VEXA Style Hub',
                          email: emailCtrl.text.trim(),
                          role: _currentUser?.role ?? 'user',
                          avatarUrl: selectedAvatar,
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        await AuthService.saveSession(updatedUser, 'user_token');
                        if (!mounted) return;
                        setState(() {
                          _currentUser = updatedUser;
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text('Profile details saved successfully!', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            backgroundColor: _successGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: Text(
                        'SAVE PROFILE CHANGES',
                        style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 2. Orders Modal & Dynamic Live Tracking Flow
  // ignore: unused_element
  void _showOrdersModal() {
    var ordersFuture = OrderService.getOrders(email: _currentUser?.email);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          Future<void> refreshOrdersModal() async {
            final f = OrderService.getOrders(email: _currentUser?.email);
            if (modalCtx.mounted) {
              setModalState(() {
                ordersFuture = f;
              });
            }
            await f;
          }

          return Container(
            height: MediaQuery.of(ctx).size.height * 0.78,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 42, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: _gold.withAlpha(25), shape: BoxShape.circle),
                          child: const Icon(Icons.inventory_2_outlined, color: _goldDark, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text('MY ORDERS', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: RefreshIndicator(
                    color: _goldDark,
                    onRefresh: refreshOrdersModal,
                    child: FutureBuilder<List<OrderModel>>(
                      future: ordersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: _goldDark, strokeWidth: 2.5),
                        );
                      }

                      final orders = snapshot.data ?? [];
                      if (orders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(color: _surfaceBg, shape: BoxShape.circle),
                                child: const Icon(Icons.shopping_bag_outlined, color: _subtext, size: 42),
                              ),
                              const SizedBox(height: 16),
                              Text('No Orders Placed Yet', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
                              const SizedBox(height: 6),
                              Text('When you order products, your purchases and live shipment tracking will appear here.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _goldDark,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  if (widget.onNavigateToDiscover != null) {
                                    widget.onNavigateToDiscover!();
                                  }
                                },
                                child: Text('EXPLORE CATALOG', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                        itemBuilder: (ctx, i) {
                          final order = orders[i];
                          final firstItem = order.items.isNotEmpty ? order.items.first : null;
                          final titleText = firstItem != null ? firstItem.name : 'VEXA Order';
                          final itemsCount = order.items.fold(0, (sum, item) => sum + item.quantity);
                          final itemsSummary = itemsCount == 1 ? '1 Item' : '$itemsCount Items';
                          final sizeSummary = firstItem != null ? 'Size ${firstItem.size}' : '';
                          final detailsSubtitle = sizeSummary.isNotEmpty ? '$itemsSummary · $sizeSummary' : itemsSummary;

                          return GestureDetector(
                            onTap: () => _showOrderDetailSheet(context, order, () {
                              setModalState(() {});
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _bgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _border),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 6, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(order.id, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14, color: _textDark)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _surfaceBg,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              order.paymentMethod,
                                              style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w600, color: _subtext),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: order.statusColor.withAlpha(25),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: order.statusColor.withAlpha(80)),
                                        ),
                                        child: Text(
                                          order.status,
                                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: order.statusColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: firstItem != null
                                            ? (firstItem.image.startsWith('assets/')
                                                ? Image.asset(firstItem.image, width: 54, height: 54, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 54, height: 54, color: _surfaceBg, child: const Icon(Icons.checkroom)))
                                                : Image.network(firstItem.image, width: 54, height: 54, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 54, height: 54, color: _surfaceBg, child: const Icon(Icons.checkroom))))
                                            : Container(width: 54, height: 54, color: _surfaceBg, child: const Icon(Icons.checkroom)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(titleText, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 2),
                                            Text('$detailsSubtitle · ${order.formattedDate}', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('₹${order.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: _goldDark)),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: _goldDark,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    elevation: 1,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.alt_route_rounded, size: 13, color: Colors.white),
                                                  label: Text('Track Order', style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  // Live Order Details & Tracking Sheet (100% FULL SCREEN)
  void _showOrderDetailSheet(BuildContext parentContext, OrderModel order, VoidCallback onRefreshParent) {
    Navigator.push(
      parentContext,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setSheetState) {
              final isCancelled = order.status.toLowerCase() == 'cancelled';
              final isDelivered = order.status.toLowerCase() == 'delivered';
              final isShipped = order.status.toLowerCase() == 'shipped' || order.status.toLowerCase() == 'out for delivery';

              return Scaffold(
                backgroundColor: _bgColor,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0.8,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  titleSpacing: 0,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: _gold.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _gold.withAlpha(60)),
                        ),
                        child: const Icon(Icons.inventory_2_rounded, color: _goldDark, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'ORDER ${order.id}',
                                    style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: order.statusColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: order.statusColor.withAlpha(90)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(width: 5, height: 5, decoration: BoxDecoration(color: order.statusColor, shape: BoxShape.circle)),
                                      const SizedBox(width: 4),
                                      Text(
                                        order.status.toUpperCase(),
                                        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: order.statusColor, letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 11, color: _subtext),
                                const SizedBox(width: 4),
                                Text('Placed on ${order.formattedDate}', style: GoogleFonts.outfit(fontSize: 10, color: _subtext)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                body: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Cancellation Banner (If Cancelled)
                    if (isCancelled) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _errorRed.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _errorRed.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cancel_outlined, color: _errorRed, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Order Cancelled: ${order.cancelReason ?? "Cancelled by user"}',
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _errorRed),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // 2. Shipping Address & Contact info
                    Text('SHIPPING DESTINATION', style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: _goldDark),
                              const SizedBox(width: 6),
                              Text(order.customerName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(order.shippingAddress, style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: _subtext),
                              const SizedBox(width: 6),
                              Text(order.phone, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Items Purchased
                    Text('ITEMS IN ORDER (${order.items.length})', style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    ...order.items.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.image.startsWith('assets/')
                                  ? Image.asset(item.image, width: 48, height: 48, fit: BoxFit.cover)
                                  : Image.network(item.image, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 48, height: 48, color: _surfaceBg, child: const Icon(Icons.checkroom))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(6)),
                                        child: Text('Size ${item.size}', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: _textDark)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text('Qty: ${item.quantity}', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _goldDark)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // 4. PAYMENT & RECEIPT SUMMARY CARD
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _surfaceBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.payment_rounded, size: 16, color: _subtext),
                                  const SizedBox(width: 6),
                                  Text('Payment Method', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
                                  child: Text(
                                    order.paymentMethod,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _textDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                  Text('Shipping Fee', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
                                ],
                              ),
                              Text('FREE Express', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: _border),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Amount Paid', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _goldDark,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [BoxShadow(color: _goldDark.withAlpha(60), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Text('₹${order.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions: Cancel Order or Download Invoice
                    if (!isCancelled && !isDelivered) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _errorRed),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            _confirmCancelOrder(parentContext, order, () {
                              setSheetState(() {});
                              onRefreshParent();
                            });
                          },
                          icon: const Icon(Icons.cancel_outlined, color: _errorRed, size: 18),
                          label: Text('CANCEL THIS ORDER', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _errorRed)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _goldDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                        onPressed: () {
                          _showInvoiceModal(ctx, order, autoStartDownload: true);
                        },
                        icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 18),
                        label: Text('DOWNLOAD E-INVOICE (PDF)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }



  Future<String?> _saveInvoiceFileToDisk(String invoiceNo, OrderModel order) async {
    try {
      String? downloadsPath;
      if (Platform.isAndroid) {
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) {
          downloadsPath = dir.path;
        }
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          downloadsPath = '$userProfile\\Downloads';
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          downloadsPath = '$home/Downloads';
        }
      }

      downloadsPath ??= Directory.systemTemp.path;

      final file = File('$downloadsPath/$invoiceNo.pdf');
      final content = '''
============================================================
                  VEXA LUXURY WEAR - TAX E-INVOICE
                   Vexa Style Hub Pvt. Ltd.
        100ft Road, Indiranagar, Bengaluru - 560038
         GSTIN: 29AAACV9812F1Z4 | CIN: U74999KA2026PTC
============================================================

INVOICE NO   : $invoiceNo
DATE         : ${order.formattedDate}
ORDER ID     : ${order.id}
PAYMENT      : ${order.paymentMethod}
STATUS       : PAID

BILLED TO:
Name    : ${order.customerName}
Address : ${order.shippingAddress}
Phone   : ${order.phone}

------------------------------------------------------------
ITEMS PURCHASED:
------------------------------------------------------------
${order.items.map((i) => '${i.name.padRight(28)} Size:${i.size} Qty:${i.quantity} Price:₹${i.price} Total:₹${(i.price * i.quantity).toStringAsFixed(0)}').join('\n')}

------------------------------------------------------------
TAX BREAKDOWN:
Subtotal (Taxable Value) : ₹${(order.totalAmount / 1.18).toStringAsFixed(2)}
CGST (9%)               : ₹${((order.totalAmount - (order.totalAmount / 1.18)) / 2).toStringAsFixed(2)}
SGST (9%)               : ₹${((order.totalAmount - (order.totalAmount / 1.18)) / 2).toStringAsFixed(2)}
------------------------------------------------------------
TOTAL AMOUNT PAID        : ₹${order.totalAmount.toStringAsFixed(0)}
============================================================
      Thank you for shopping with VEXA Luxury Wear!
============================================================
''';

      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      debugPrint('Error saving invoice file: $e');
      return null;
    }
  }

  // ── TAX E-INVOICE GENERATOR & PREVIEW SCREEN (100% FULL SCREEN) ──────────
  void _showInvoiceModal(BuildContext context, OrderModel order, {bool autoStartDownload = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          bool isDownloading = false;
          bool isDownloaded = false;
          bool hasAutoTriggered = false;

          return StatefulBuilder(
            builder: (modalCtx, setInvoiceState) {
              final invoiceNo = 'INV-2026-${order.id.replaceAll('#', '').replaceAll('-', '')}';
              final totalAmt = order.totalAmount > 0 ? order.totalAmount : 1699.0;
              final subtotal = totalAmt / 1.18;
              final gstTotal = totalAmt - subtotal;
              final cgst = gstTotal / 2;
              final sgst = gstTotal / 2;

              void triggerDownload() async {
                if (isDownloading || isDownloaded) return;
                setInvoiceState(() => isDownloading = true);
                
                // Save actual file to disk
                final savedPath = await _saveInvoiceFileToDisk(invoiceNo, order);

                if (modalCtx.mounted) {
                  setInvoiceState(() {
                    isDownloading = false;
                    isDownloaded = true;
                  });

                  ScaffoldMessenger.of(modalCtx).clearSnackBars();
                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              savedPath != null
                                  ? 'Saved $invoiceNo.pdf to Downloads!'
                                  : 'Tax E-Invoice $invoiceNo downloaded & saved!',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: _successGreen,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  // Auto-reset green saved banner after 2 seconds
                  await Future.delayed(const Duration(seconds: 2));
                  if (modalCtx.mounted) {
                    setInvoiceState(() {
                      isDownloaded = false;
                    });
                  }
                }
              }

              if (autoStartDownload && !hasAutoTriggered && !isDownloaded && !isDownloading) {
                hasAutoTriggered = true;
                Future.microtask(() => triggerDownload());
              }

              return Scaffold(
                backgroundColor: _bgColor,
                appBar: AppBar(
                  backgroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                  titleSpacing: 0,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: _gold.withAlpha(50), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: _gold, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TAX E-INVOICE', style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                          Text(invoiceNo, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    // Invoice Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Brand & GSTIN
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('VEXA LUXURY WEAR', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.w900, color: _goldDark, letterSpacing: 1.5)),
                                      const SizedBox(height: 2),
                                      Text('Vexa Style Hub Pvt. Ltd.', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _textDark)),
                                      Text('100ft Road, Indiranagar, Bengaluru - 560038', style: GoogleFonts.outfit(fontSize: 10, color: _subtext)),
                                      Text('GSTIN: 29AAACV9812F1Z4 | CIN: U74999KA2026PTC', style: GoogleFonts.outfit(fontSize: 10, color: _subtext)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _successGreen.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _successGreen.withAlpha(80)),
                                    ),
                                    child: Text('PAID', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: _successGreen, letterSpacing: 1)),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              // Customer & Order Info
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('BILLED TO:', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _subtext, letterSpacing: 1)),
                                        const SizedBox(height: 4),
                                        Text(order.customerName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                                        Text(order.shippingAddress, style: GoogleFonts.outfit(fontSize: 11, color: _subtext, height: 1.3)),
                                        Text('Contact: ${order.phone}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('INVOICE DETAILS:', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _subtext, letterSpacing: 1)),
                                      const SizedBox(height: 4),
                                      Text('Date: ${order.formattedDate}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      Text('Order ID: ${order.id}', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _goldDark)),
                                      Text('Payment: ${order.paymentMethod}', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Items Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    Expanded(flex: 4, child: Text('ITEM DESCRIPTION', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                    Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                    Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                    Expanded(flex: 2, child: Text('AMOUNT', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Items Rows
                              ...order.items.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 0.8))),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.name, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _textDark)),
                                            Text('Size: ${item.size} · Color: ${item.color} | HSN: 610910', style: GoogleFonts.outfit(fontSize: 9, color: _subtext)),
                                          ],
                                        ),
                                      ),
                                      Expanded(flex: 1, child: Text('${item.quantity}', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, color: _textDark))),
                                      Expanded(flex: 2, child: Text('₹${item.price.toStringAsFixed(0)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 11, color: _textDark))),
                                      Expanded(flex: 2, child: Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _textDark))),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 14),

                              // Tax & Totals Breakdown
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Taxable Value', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                        Text('₹${subtotal.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('CGST (9%)', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                        Text('₹${cgst.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('SGST (9%)', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                        Text('₹${sgst.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      ],
                                    ),
                                    const Divider(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('GRAND TOTAL (INCL. GST)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark)),
                                        Text('₹${totalAmt.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: _goldDark)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Footer verification stamp
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.qr_code_2_rounded, size: 40, color: _textDark),
                                      const SizedBox(width: 8),
                                      Text('Scan QR for Digital\nE-Invoice Verification', style: GoogleFonts.outfit(fontSize: 9, color: _subtext, height: 1.2)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('For VEXA STYLE HUB PVT LTD', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: _textDark)),
                                      const SizedBox(height: 16),
                                      Text('Authorized Signatory', style: GoogleFonts.outfit(fontSize: 9, color: _subtext, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Action Button / Progress
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: _border)),
                      ),
                      child: isDownloaded
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _successGreen.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _successGreen),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: _successGreen, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Invoice Saved to Downloads ($invoiceNo.pdf)',
                                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _successGreen),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _goldDark,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: isDownloading ? null : () => triggerDownload(),
                                icon: isDownloading
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                                label: Text(
                                  isDownloading ? 'GENERATING E-INVOICE PDF...' : 'SAVE E-INVOICE TO DEVICE (PDF)',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStepRow(IconData icon, String stepNum, String title, String subtitle, bool isCompleted, bool isCurrent, bool isLast) {
    final activeColor = isCurrent ? const Color(0xFF2563EB) : _goldDark;
    final stepBg = isCompleted
        ? _goldDark
        : isCurrent
            ? activeColor
            : _surfaceBg;
    final stepIconColor = isCompleted || isCurrent ? Colors.white : _subtext;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: stepBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? _goldDark : isCurrent ? activeColor : _border,
                  width: isCurrent ? 3 : 1.5,
                ),
                boxShadow: isCurrent
                    ? [BoxShadow(color: activeColor.withAlpha(80), blurRadius: 8, spreadRadius: 1)]
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                    : Icon(icon, color: stepIconColor, size: 13),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                decoration: BoxDecoration(
                  color: isCompleted ? _goldDark : _border,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: isCompleted || isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCompleted || isCurrent ? _textDark : _subtext,
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: activeColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'IN PROGRESS',
                          style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w800, color: activeColor),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(fontSize: 11, color: _subtext),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmCancelOrder(BuildContext context, OrderModel order, VoidCallback onCancelled) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cancel Order ${order.id}?', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Are you sure you want to cancel this order? Any payments will be refunded to source within 24 hours.', style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('KEEP ORDER', style: GoogleFonts.outfit(color: _subtext, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _errorRed),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await OrderService.cancelOrder(order.id, 'Cancelled by user request');
              onCancelled();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order ${order.id} has been cancelled successfully.'),
                    backgroundColor: _errorRed,
                  ),
                );
              }
            },
            child: Text('YES, CANCEL', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 3. Wishlist Modal
  // ignore: unused_element
  void _showWishlistModal() {
    final wishlist = [
      {
        'name': 'Urban Silhouette Oversized Tee',
        'category': '240 GSM Cotton',
        'price': '₹2,499',
        'image': 'assets/images/hero_luxury_tshirt.png',
      },
      {
        'name': 'Bespoke Embroidered Hoodie',
        'category': 'Heavyweight Fit',
        'price': '₹3,899',
        'image': 'assets/images/promo_banner_2.png',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.65,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 42, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: _gold.withAlpha(25), shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('SAVED WISHLIST ITEMS', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: wishlist.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final item = wishlist[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            item['image']!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: _surfaceBg, child: const Icon(Icons.image)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name']!, style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: _textDark)),
                              Text(item['category']!, style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                              const SizedBox(height: 4),
                              Text(item['price']!, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: _goldDark)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _goldDark,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Moved ${item['name']} to cart!'),
                                backgroundColor: _goldDark,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Text('Add to Cart', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _goldDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartScreen(
                        cartItems: const [],
                        onCartUpdated: () => setState(() {}),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFFFD700), size: 20),
                label: Text('View Cart', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3b. VEXA Wallet Real-Time Interactive View
  void _showWalletModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setWalletState) => Scaffold(
            backgroundColor: _bgColor,
            appBar: AppBar(
              backgroundColor: _cardBg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: _textDark),
                onPressed: () => Navigator.pop(ctx),
              ),
              title: Text(
                'VEXA PAY WALLET',
                style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B), _goldDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_rounded, color: _gold, size: 24),
                                const SizedBox(width: 10),
                                Text(
                                  'VEXA CASH BALANCE',
                                  style: GoogleFonts.cinzel(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _gold.withAlpha(40),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _gold.withAlpha(80)),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: GoogleFonts.outfit(color: _gold, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '₹${_walletBalance.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          'Instant 1-Click Checkout Available',
                          style: GoogleFonts.outfit(color: Colors.white.withAlpha(200), fontSize: 12),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _goldDark,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _showAddMoneySheet(ctx, setWalletState),
                                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                label: Text('ADD MONEY', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _showTransferMoneySheet(ctx, setWalletState),
                                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                                label: Text('TRANSFER', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'WALLET ADVANTAGES',
                    style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: _gold.withAlpha(25), shape: BoxShape.circle),
                              child: const Icon(Icons.bolt_rounded, color: _goldDark, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Zero Delay Refunds', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: _textDark)),
                                  Text('Order cancellation refunds credited instantly within seconds', style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: _gold.withAlpha(25), shape: BoxShape.circle),
                              child: const Icon(Icons.card_giftcard_rounded, color: _goldDark, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Exclusive Cashback Boosts', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: _textDark)),
                                  Text('Earn up to 10% extra wallet cashback on luxury drops', style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TRANSACTION HISTORY',
                        style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
                      ),
                      Text(
                        '${_walletTransactions.length} Transactions',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: _subtext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _walletTransactions.length,
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final tx = _walletTransactions[i];
                        final isCredit = tx['isCredit'] == true;
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isCredit ? Colors.green.withAlpha(20) : Colors.redAccent.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              color: isCredit ? Colors.green[700] : Colors.redAccent,
                              size: 18,
                            ),
                          ),
                          title: Text(tx['title']!, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: _textDark)),
                          subtitle: Text(tx['sub']!, style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                          trailing: Text(
                            tx['amount']!,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isCredit ? Colors.green[700] : Colors.redAccent,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMoneySheet(BuildContext modalCtx, StateSetter setWalletState) {
    final amountCtrl = TextEditingController(text: '1000');
    final presetAmounts = [500, 1000, 2000, 5000];
    String selectedGateway = 'Razorpay Gateway';

    Navigator.push(
      modalCtx,
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (c, setSheetState) => Scaffold(
            backgroundColor: _bgColor,
            appBar: AppBar(
              backgroundColor: _cardBg,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: _textDark),
                onPressed: () => Navigator.pop(ctx),
              ),
              title: Text(
                'TOP-UP VEXA WALLET',
                style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Banner Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B), _goldDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(30),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _gold.withAlpha(30), shape: BoxShape.circle),
                          child: const Icon(Icons.add_card_rounded, color: _gold, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Instant Wallet Top-Up', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Add funds securely via Razorpay 256-Bit Gateway', style: GoogleFonts.outfit(color: Colors.white.withAlpha(200), fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('SELECT QUICK TOP-UP AMOUNT', style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: presetAmounts.map((amt) {
                      final isSel = amountCtrl.text == amt.toString();
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () {
                              setSheetState(() {
                                amountCtrl.text = amt.toString();
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSel ? _goldDark : _cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSel ? _goldDark : _border),
                                boxShadow: isSel ? [BoxShadow(color: _goldDark.withAlpha(40), blurRadius: 8)] : [],
                              ),
                              child: Center(
                                child: Text(
                                  '+₹$amt',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? Colors.white : _textDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.w700, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: 'Enter Custom Amount (₹)',
                      labelStyle: GoogleFonts.outfit(color: _subtext, fontSize: 13),
                      prefixIcon: const Icon(Icons.currency_rupee_rounded, color: _goldDark),
                      filled: true,
                      fillColor: _cardBg,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _goldDark, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('SELECT PAYMENT METHOD', style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedGateway = 'Razorpay Gateway'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedGateway == 'Razorpay Gateway' ? const Color(0xFF0C2340).withAlpha(15) : _cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedGateway == 'Razorpay Gateway' ? const Color(0xFF0C2340) : _border,
                                width: selectedGateway == 'Razorpay Gateway' ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(color: const Color(0xFF0C2340), borderRadius: BorderRadius.circular(5)),
                                  child: Text('Razorpay', style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Razorpay Gateway',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: _textDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedGateway = 'Direct UPI'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: selectedGateway == 'Direct UPI' ? _gold.withAlpha(20) : _cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedGateway == 'Direct UPI' ? _goldDark : _border,
                                width: selectedGateway == 'Direct UPI' ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code_scanner_rounded, size: 18, color: _goldDark),
                                const SizedBox(width: 6),
                                Text(
                                  'Direct UPI / GPay',
                                  style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: _textDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedGateway == 'Razorpay Gateway' ? const Color(0xFF0C2340) : _goldDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      onPressed: () {
                        final addAmt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                        if (addAmt <= 0) return;

                        Navigator.pop(ctx);

                        if (selectedGateway == 'Razorpay Gateway') {
                          _showRazorpayWalletGatewayModal(modalCtx, addAmt, setWalletState);
                        } else {
                          setState(() {
                            _walletBalance += addAmt;
                            _walletTransactions.insert(0, {
                              'title': 'Wallet Top-up via Direct UPI',
                              'sub': 'Just now · Instant Credit',
                              'amount': '+₹${addAmt.toStringAsFixed(0)}',
                              'isCredit': true,
                            });
                          });
                          setWalletState(() {});

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('₹${addAmt.toStringAsFixed(0)} added to VEXA Wallet in real-time!'),
                              backgroundColor: _successGreen,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                      label: Text(
                        selectedGateway == 'Razorpay Gateway' ? 'PAY VIA RAZORPAY GATEWAY' : 'PAY & ADD TO WALLET',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRazorpayWalletGatewayModal(
    BuildContext context,
    double amount,
    StateSetter setWalletState,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) {
          int step = 0; // 0: Select Gateway Method, 1: Processing, 2: Success
          String selectedMode = 'Razorpay UPI (GPay / PhonePe)';
          String currentPaymentId = 'pay_RZP_${DateTime.now().millisecondsSinceEpoch}';

          return StatefulBuilder(
            builder: (ctx, setGateState) {
              return Scaffold(
                backgroundColor: Colors.white,
                body: SafeArea(
                  child: Column(
                    children: [
                      // Razorpay Header Bar (Dark Navy Razorpay Theme)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        color: const Color(0xFF0C2340),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                                      onPressed: step == 1 ? null : () => Navigator.pop(ctx),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withAlpha(50),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.blueAccent.withAlpha(100)),
                                      ),
                                      child: Text('Razorpay', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(4)),
                                      child: Text('LIVE GATEWAY', style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                                  onPressed: step == 1 ? null : () => Navigator.pop(ctx),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('VEXA WALLET TOP-UP', style: GoogleFonts.cinzel(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text('Top-Up ID #RZP-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('TOP-UP AMOUNT', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                    Text('₹${amount.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: const Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 22)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Modal Body
                      Expanded(
                        child: step == 0
                            ? Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Choose Razorpay Payment Channel:',
                                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark),
                                    ),
                                    const SizedBox(height: 16),
                                    ...[
                                      (id: 'Razorpay UPI (GPay / PhonePe)', name: 'Razorpay Instant UPI', desc: 'Google Pay, PhonePe, Paytm, BHIM, CRED', icon: Icons.qr_code_scanner_rounded),
                                      (id: 'Razorpay Debit / Credit Card', name: 'Razorpay Card Checkout', desc: 'Visa, Mastercard, RuPay, Diners, Amex', icon: Icons.credit_card_rounded),
                                      (id: 'Razorpay NetBanking', name: 'Razorpay NetBanking', desc: 'HDFC, ICICI, SBI, Axis, Kotak, 50+ Banks', icon: Icons.account_balance_rounded),
                                    ].map((channel) {
                                      final isSel = selectedMode == channel.id;
                                      return GestureDetector(
                                        onTap: () => setGateState(() => selectedMode = channel.id),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isSel ? const Color(0xFF0C2340).withAlpha(12) : _surfaceBg,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: isSel ? const Color(0xFF0C2340) : _border, width: isSel ? 1.5 : 1.0),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isSel ? const Color(0xFF0C2340) : Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(channel.icon, color: isSel ? Colors.white : const Color(0xFF0C2340), size: 22),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(channel.name, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
                                                    const SizedBox(height: 2),
                                                    Text(channel.desc, style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext)),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                                color: isSel ? const Color(0xFF0C2340) : _subtext,
                                                size: 22,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.security_rounded, size: 16, color: _subtext),
                                        const SizedBox(width: 6),
                                        Text('256-Bit SSL PCI-DSS Compliant Razorpay Gateway', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0C2340),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          elevation: 3,
                                        ),
                                        onPressed: () async {
                                          setGateState(() => step = 1);
                                          await Future.delayed(const Duration(milliseconds: 1500));
                                          if (ctx.mounted) setGateState(() => step = 2);

                                          await Future.delayed(const Duration(milliseconds: 1400));
                                          if (ctx.mounted) {
                                            Navigator.pop(ctx);
                                            setState(() {
                                              _walletBalance += amount;
                                              _walletTransactions.insert(0, {
                                                'title': 'Razorpay Wallet Top-Up',
                                                'sub': 'Txn ID: $currentPaymentId · Instant Credit',
                                                'amount': '+₹${amount.toStringAsFixed(0)}',
                                                'isCredit': true,
                                              });
                                            });
                                            setWalletState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('₹${amount.toStringAsFixed(0)} credited via Razorpay Gateway in real-time!'),
                                                backgroundColor: _successGreen,
                                                duration: const Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        },
                                        child: Text(
                                          'PROCEED TO PAY • ₹${amount.toStringAsFixed(0)}',
                                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : step == 1
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 60,
                                            height: 60,
                                            child: CircularProgressIndicator(color: Color(0xFF0C2340), strokeWidth: 3.5),
                                          ),
                                          const SizedBox(height: 28),
                                          Text(
                                            'Connecting Razorpay Gateway...',
                                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Authorizing top-up via $selectedMode.\nPlease do not refresh or close.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.outfit(fontSize: 13, color: _subtext, height: 1.4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: const BoxDecoration(color: _successGreen, shape: BoxShape.circle),
                                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 54),
                                          ),
                                          const SizedBox(height: 24),
                                          Text(
                                            'WALLET TOP-UP SUCCESSFUL!',
                                            style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Razorpay Txn ID: $currentPaymentId',
                                            style: GoogleFonts.outfit(fontSize: 12, color: _goldDark, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '₹${amount.toStringAsFixed(0)} added to VEXA Wallet',
                                            style: GoogleFonts.outfit(fontSize: 13.5, color: _subtext),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showTransferMoneySheet(BuildContext modalCtx, StateSetter setWalletState) {
    final upiCtrl = TextEditingController(text: 'tatukulaedukondalu@okaxis');
    final amountCtrl = TextEditingController(text: '500');

    showModalBottomSheet(
      context: modalCtx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 42, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _gold.withAlpha(25), shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: _goldDark, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('TRANSFER TO BANK', style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetCtx)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: upiCtrl,
              style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Recipient UPI ID / Bank A/C',
                labelStyle: GoogleFonts.outfit(color: _subtext),
                prefixIcon: const Icon(Icons.account_balance_rounded, color: _goldDark),
                filled: true,
                fillColor: _surfaceBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.w700, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Transfer Amount (₹)',
                labelStyle: GoogleFonts.outfit(color: _subtext, fontSize: 13),
                prefixIcon: const Icon(Icons.currency_rupee_rounded, color: _goldDark),
                filled: true,
                fillColor: _surfaceBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
              ),
            ),
            const SizedBox(height: 8),
            Text('Available Balance: ₹${_walletBalance.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: _goldDark)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _goldDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final transferAmt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                  if (transferAmt <= 0) return;

                  if (transferAmt > _walletBalance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Insufficient Wallet Balance for transfer!'),
                        backgroundColor: _errorRed,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _walletBalance -= transferAmt;
                    _walletTransactions.insert(0, {
                      'title': 'Bank Transfer to UPI',
                      'sub': 'Just now · Sent to ${upiCtrl.text.trim()}',
                      'amount': '-₹${transferAmt.toStringAsFixed(0)}',
                      'isCredit': false,
                    });
                  });
                  setWalletState(() {});
                  Navigator.pop(sheetCtx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('₹${transferAmt.toStringAsFixed(0)} transferred to bank in real-time!'),
                      backgroundColor: _successGreen,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: Text('CONFIRM REAL-TIME TRANSFER', style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Coupons Full Screen View
  void _showCouponsModal() {
    final coupons = [
      {
        'code': 'VEXA30',
        'title': 'Flat 30% OFF Storewide',
        'desc': 'Valid on all 240 GSM drops & bespoke embroidered tees.',
        'exp': 'Expires 30 Sep 2026',
        'minOrder': 'Min. order ₹1,999',
        'category': 'STOREWIDE',
      },
      {
        'code': 'WELCOME100',
        'title': 'Flat ₹100 OFF First Order',
        'desc': 'Instant discount on your first VEXA purchase.',
        'exp': 'Expires 15 Oct 2026',
        'minOrder': 'No min. order',
        'category': 'NEW USER',
      },
      {
        'code': 'BESPOKE20',
        'title': 'Flat 20% OFF Custom Drops',
        'desc': 'Special privilege discount on custom embroidered drops.',
        'exp': 'Expires 31 Dec 2026',
        'minOrder': 'Min. order ₹2,499',
        'category': 'VIP EXCLUSIVE',
      },
      {
        'code': 'FREESHIP',
        'title': 'Free Express Delivery',
        'desc': 'Complimentary luxury courier delivery to your doorstep.',
        'exp': 'Expires 31 Oct 2026',
        'minOrder': 'Min. order ₹999',
        'category': 'SHIPPING',
      },
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            backgroundColor: _cardBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _textDark),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Text(
              'VIP COUPONS & OFFERS',
              style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_goldDark, Color(0xFFC5A059), _gold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _goldDark.withAlpha(50),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Exclusive Member Perks',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '4 Coupons Available for Redemption',
                              style: GoogleFonts.outfit(color: Colors.white.withAlpha(220), fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'AVAILABLE PROMO CODES',
                  style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: coupons.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 14),
                  itemBuilder: (c, i) {
                    final item = coupons[i];
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _gold.withAlpha(80)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: _goldDark, borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  item['code']!,
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: _gold.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                  item['category']!,
                                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _goldDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(item['title']!, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: _textDark)),
                          const SizedBox(height: 4),
                          Text(item['desc']!, style: GoogleFonts.outfit(fontSize: 12, color: _subtext, height: 1.3)),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['minOrder']!, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: _subtext)),
                                  Text(item['exp']!, style: GoogleFonts.outfit(fontSize: 11, color: _goldDark, fontWeight: FontWeight.w700)),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _goldDark,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: item['code']!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Copied coupon code "${item['code']}" to clipboard!'),
                                      backgroundColor: _goldDark,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                                label: Text('COPY CODE', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                              ),
                            ],
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
    );
  }

  // 5. Addresses Full Screen View
  void _showAddressesModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            backgroundColor: _cardBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _textDark),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Text(
              'SAVED ADDRESSES',
              style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _gold.withAlpha(25), shape: BoxShape.circle),
                        child: const Icon(Icons.location_on_outlined, color: _goldDark, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delivery Destinations', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5, color: _textDark)),
                            Text('Manage your saved shipping locations for fast 1-click checkout', style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'YOUR ADDRESSES',
                  style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _gold, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withAlpha(20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.home_rounded, color: _goldDark, size: 20),
                              const SizedBox(width: 8),
                              Text('Home (Primary)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: _textDark)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: _gold.withAlpha(30), borderRadius: BorderRadius.circular(6)),
                            child: Text('DEFAULT', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: _goldDark)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_currentUser?.name ?? 'Tatukula Edukondalu', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: _textDark)),
                      const SizedBox(height: 4),
                      Text(
                        'Flat 402, Luxury Heights, Jubilee Hills Road No. 36\nHyderabad, Telangana - 500033\nIndia',
                        style: GoogleFonts.outfit(fontSize: 12.5, color: _subtext, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: _subtext),
                          const SizedBox(width: 6),
                          Text('+91 98765 43210', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Editing home address...'), backgroundColor: _goldDark),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16, color: _goldDark),
                            label: Text('Edit', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _goldDark)),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cannot delete default address'), backgroundColor: _goldDark),
                              );
                            },
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                            label: Text('Remove', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.business_rounded, color: _textDark, size: 20),
                              const SizedBox(width: 8),
                              Text('VEXA Design Studio (Work)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: _textDark)),
                            ],
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              side: const BorderSide(color: _border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Set Work address as default'), backgroundColor: _goldDark),
                              );
                            },
                            child: Text('Set Default', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _textDark)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(_currentUser?.name ?? 'Tatukula Edukondalu', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14, color: _textDark)),
                      const SizedBox(height: 4),
                      Text(
                        'Floor 5, Cyber Towers, HITEC City, Phase 2\nHyderabad, Telangana - 500081\nIndia',
                        style: GoogleFonts.outfit(fontSize: 12.5, color: _subtext, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 14, color: _subtext),
                          const SizedBox(width: 6),
                          Text('+91 98765 43210', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Editing work address...'), backgroundColor: _goldDark),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16, color: _goldDark),
                            label: Text('Edit', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _goldDark)),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Removed work address'), backgroundColor: _goldDark),
                              );
                            },
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            label: Text('Remove', style: GoogleFonts.outfit(fontSize: 12, color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _goldDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Address form feature ready!'), backgroundColor: _goldDark),
                      );
                    },
                    icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
                    label: Text('ADD NEW ADDRESS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, letterSpacing: 1.5, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 6. Payments Full Screen View
  void _showPaymentsModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            backgroundColor: _cardBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _textDark),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Text(
              'PAYMENT METHODS',
              style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _gold.withAlpha(25), shape: BoxShape.circle),
                        child: const Icon(Icons.security_rounded, color: _goldDark, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Encrypted & Secure Payments', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5, color: _textDark)),
                            Text('256-bit SSL PCI-DSS compliant checkout protection', style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'SAVED PAYMENT MODES',
                  style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF0C2340), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF0C2340), borderRadius: BorderRadius.circular(6)),
                        child: Text('Razorpay', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Razorpay Payment Gateway', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: _successGreen.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                  child: Text('PRIMARY', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: _successGreen)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Instant UPI, Cards, NetBanking & Wallets', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified_rounded, color: Color(0xFF0C2340), size: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _gold, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _gold.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: _goldDark, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Google Pay / PhonePe UPI', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: _successGreen.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                  child: Text('DEFAULT', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: _successGreen)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('tatukulaedukondalu@okaxis', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded, color: _goldDark, size: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.credit_card_rounded, color: _goldDark, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HDFC Bank Visa Credit Card', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
                            const SizedBox(height: 4),
                            Text('•••• •••• •••• 4242 · Expires 08/28', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Card settings opened'), backgroundColor: _goldDark),
                          );
                        },
                        child: Text('Manage', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _goldDark)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.currency_rupee_rounded, color: _goldDark, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cash on Delivery (COD)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
                            const SizedBox(height: 4),
                            Text('Available on orders up to ₹15,000', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.green.withAlpha(20), borderRadius: BorderRadius.circular(6)),
                        child: Text('ACTIVE', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green[700])),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _goldDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Add payment method modal ready'), backgroundColor: _goldDark),
                      );
                    },
                    icon: const Icon(Icons.add_card_rounded, color: Colors.white),
                    label: Text('ADD NEW PAYMENT METHOD', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, letterSpacing: 1.5, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 6b. Rewards Full Screen View
  void _showRewardsModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: _bgColor,
          appBar: AppBar(
            backgroundColor: _cardBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: _textDark),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Text(
              'VIP REWARDS & POINTS',
              style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_goldDark, Color(0xFFC5A059), _gold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _goldDark.withAlpha(60),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
                              const SizedBox(width: 10),
                              Text('VIP GOLD MEMBER', style: GoogleFonts.cinzel(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black.withAlpha(40), borderRadius: BorderRadius.circular(20)),
                            child: Text('TIER 2', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('AVAILABLE REWARD BALANCE', style: GoogleFonts.outfit(color: Colors.white.withAlpha(200), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('150', style: GoogleFonts.cinzel(color: Colors.white, fontSize: 38, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text('VEXA Points', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: 0.6,
                          backgroundColor: Colors.white.withAlpha(60),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Earn 100 more points to reach Platinum Black Tier', style: GoogleFonts.outfit(color: Colors.white.withAlpha(220), fontSize: 11.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'HOW REWARDS WORK',
                  style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: _gold.withAlpha(20), shape: BoxShape.circle),
                            child: const Icon(Icons.shopping_bag_outlined, color: _goldDark, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Shop 240 GSM Drops', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: _textDark)),
                                Text('Earn 1 point for every ₹100 spent', style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: _gold.withAlpha(20), shape: BoxShape.circle),
                            child: const Icon(Icons.card_giftcard_rounded, color: _goldDark, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Redeem at Checkout', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: _textDark)),
                                Text('1 Point = ₹1 Instant discount', style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'POINTS HISTORY',
                  style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.add_circle, color: Colors.green),
                        title: Text('Welcome VIP Bonus', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: _textDark)),
                        subtitle: Text('15 Sep 2026', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                        trailing: Text('+100 Pts', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green[700])),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.add_circle, color: Colors.green),
                        title: Text('Order #VEXA-8942 Purchase', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: _textDark)),
                        subtitle: Text('18 Sep 2026', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                        trailing: Text('+50 Pts', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green[700])),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 7. Currency Modal
  void _showCurrencyModal() {
    final currencies = [
      'India (INR ₹)',
      'United States (USD \$)',
      'United Kingdom (GBP £)',
      'United Arab Emirates (AED)',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 42, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('CURRENCY & REGION', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            ...currencies.map((c) => ListTile(
              title: Text(c, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: _textDark)),
              trailing: _selectedCurrency == c ? const Icon(Icons.check_circle, color: _goldDark) : null,
              onTap: () {
                setState(() {
                  _selectedCurrency = c;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Region set to $c'), backgroundColor: _goldDark),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  // ── 1. USER HERO CARD ───────────────────────────────────────────────────
  Widget _buildUserHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _goldDark.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Glowing Avatar Circle with Edit Icon
              GestureDetector(
                onTap: _showEditProfileModal,
                child: Stack(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _gold.withAlpha(25),
                        border: Border.all(color: _gold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withAlpha(40),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: _buildAvatarWidget(_currentUser?.avatarUrl, _currentUser?.name ?? 'Guest Collector', size: 64, fontSize: 26),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _goldDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.edit, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser?.name ?? 'Guest Collector',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _currentUser?.companyName ?? 'VEXA Style Hub',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _goldDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _showEditProfileModal,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _gold.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _gold.withAlpha(80)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 12, color: _goldDark),
                                const SizedBox(width: 4),
                                Text(
                                  'Edit Profile',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _goldDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser?.email ?? 'guest@vexa.app',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: _subtext,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. SHORTCUTS GRID ───────────────────────────────────────────────────
  Widget _buildShortcutsGrid() {
    final shortcuts = [
      (icon: Icons.account_balance_wallet_outlined, title: 'VEXA Wallet', badge: '₹${_walletBalance.toStringAsFixed(0)}', onTap: _showWalletModal),
      (icon: Icons.confirmation_number_outlined, title: 'Coupons', badge: 'VIP Offers', onTap: _showCouponsModal),
      (icon: Icons.location_on_outlined, title: 'Addresses', badge: 'Default', onTap: _showAddressesModal),
      (icon: Icons.credit_card_rounded, title: 'Payments', badge: 'UPI & Cards', onTap: _showPaymentsModal),
      (icon: Icons.workspace_premium_outlined, title: 'VIP Rewards', badge: '150 Pts', onTap: _showRewardsModal),
      (icon: Icons.favorite_border_rounded, title: 'Wishlist', badge: 'Saved Items', onTap: _showWishlistModal),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.15,
      ),
      itemCount: shortcuts.length,
      itemBuilder: (context, index) {
        final s = shortcuts[index];
        return InkWell(
          onTap: s.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _gold.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _gold.withAlpha(60)),
                  ),
                  child: Icon(s.icon, color: _goldDark, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 10.5, color: _subtext, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 3. PREFERENCES CARD ─────────────────────────────────────────────────
  Widget _buildPreferencesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCOUNT PREFERENCES',
          style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: _textDark),
        ),
        const SizedBox(height: 8),
        Material(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                _buildPreferenceTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Drop Alerts & Offers',
                  subtitle: 'Get notified about limited 240 GSM drops',
                  trailing: Switch.adaptive(
                    value: _dropAlertsEnabled,
                    activeTrackColor: _goldDark,
                    onChanged: (val) {
                      setState(() {
                        _dropAlertsEnabled = val;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(val ? 'Drop alerts enabled!' : 'Drop alerts disabled'),
                          backgroundColor: _goldDark,
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(color: _border, height: 1),
                _buildPreferenceTile(
                  icon: Icons.language_rounded,
                  title: 'Currency & Region',
                  subtitle: _selectedCurrency,
                  trailing: const Icon(Icons.chevron_right_rounded, color: _subtext),
                  onTap: _showCurrencyModal,
                ),
                const Divider(color: _border, height: 1),
                _buildPreferenceTile(
                  icon: Icons.headset_mic_outlined,
                  title: '24/7 VIP Customer Support',
                  subtitle: 'Contact support@vexa.app or WhatsApp',
                  trailing: const Icon(Icons.chevron_right_rounded, color: _subtext),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        backgroundColor: _cardBg,
                        title: Text('Customer Concierge', style: GoogleFonts.cinzel(fontWeight: FontWeight.bold, fontSize: 16)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need assistance with custom sizing, orders, or delivery?',
                              style: GoogleFonts.outfit(color: _subtext, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.chat, color: Colors.green),
                              title: Text('WhatsApp Support', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('+91 98765 43210', style: GoogleFonts.outfit(fontSize: 11)),
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening WhatsApp Support chat...'), backgroundColor: _goldDark),
                                );
                              },
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.email, color: _goldDark),
                              title: Text('Email Concierge', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('support@vexa.app', style: GoogleFonts.outfit(fontSize: 11)),
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening Email Concierge...'), backgroundColor: _goldDark),
                                );
                              },
                            ),
                          ],
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: _goldDark),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Close', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(color: _border, height: 1),
                _buildPreferenceTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'About VEXA Brand Story',
                  subtitle: 'Discover our design philosophy',
                  trailing: const Icon(Icons.chevron_right_rounded, color: _subtext),
                  onTap: _showBrandStoryModal,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _surfaceBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _textDark, size: 18),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: _textDark),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(fontSize: 11, color: _subtext),
        ),
        trailing: trailing,
      ),
    );
  }
}
