import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';

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
  bool _dropAlertsEnabled = true;
  String _selectedCurrency = 'India (INR ₹)';

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

    if (widget.onNavigateToDiscover != null) {
      widget.onNavigateToDiscover!();
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _gold.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _gold.withAlpha(80)),
                  ),
                  child: Text('V', style: GoogleFonts.cinzel(color: _goldDark, fontWeight: FontWeight.w900, fontSize: 20)),
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
              automaticallyImplyLeading: false,
              centerTitle: false,
              titleSpacing: 20,
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
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _gold.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.checkroom_rounded, color: _goldDark, size: 18),
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

  // 1. Edit Profile Modal
  void _showEditProfileModal() {
    final nameCtrl = TextEditingController(text: _currentUser?.name ?? '');
    final emailCtrl = TextEditingController(text: _currentUser?.email ?? '');
    final phoneCtrl = TextEditingController(text: '+91 98765 43210');
    String selectedAvatar = _currentUser?.avatarUrl ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'EDIT ACCOUNT PROFILE',
                        style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: _subtext, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Avatar Preview with camera action badge
                  Center(
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
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _gold.withAlpha(25),
                                  border: Border.all(color: _gold, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _gold.withAlpha(30),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: _buildAvatarWidget(selectedAvatar, nameCtrl.text, size: 80, fontSize: 32),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _goldDark,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Change Photo Action Button
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _surfaceBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.photo_camera_rounded, size: 14, color: _goldDark),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Change Photo',
                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Crop Image Action Button
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _gold.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _gold.withAlpha(100)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.crop_rounded, size: 14, color: _goldDark),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Crop Image',
                                      style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _goldDark),
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
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: GoogleFonts.outfit(color: _subtext),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: _gold),
                      filled: true,
                      fillColor: _surfaceBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: GoogleFonts.outfit(color: _subtext),
                      prefixIcon: const Icon(Icons.email_outlined, color: _gold),
                      filled: true,
                      fillColor: _surfaceBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: GoogleFonts.outfit(color: _subtext),
                      prefixIcon: const Icon(Icons.phone_outlined, color: _gold),
                      filled: true,
                      fillColor: _surfaceBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _goldDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final updatedUser = UserModel(
                          id: _currentUser?.id ?? 'user_1',
                          name: nameCtrl.text.trim(),
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
                                Text('Profile picture & details updated!', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            backgroundColor: _successGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Text('SAVE CHANGES', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
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

  // 2. Orders Modal
  void _showOrdersModal() {
    final List<Map<String, dynamic>> orders = [
      {
        'id': '#VX-8834',
        'title': 'Urban Silhouette 240 GSM Heavyweight Tee',
        'status': 'Out for Delivery',
        'statusColor': _goldDark,
        'date': '18 Sep 2026',
        'price': '₹2,499',
        'image': 'assets/images/promo_banner_1.png',
        'items': '1 Item · Size L',
      },
      {
        'id': '#VX-7412',
        'title': 'Bespoke Embroidered Heavyweight Hoodie',
        'status': 'Delivered',
        'statusColor': _successGreen,
        'date': '12 Sep 2026',
        'price': '₹3,899',
        'image': 'assets/images/promo_banner_2.png',
        'items': '1 Item · Size XL',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
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
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                itemBuilder: (ctx, i) {
                  final order = orders[i];
                  final orderId = order['id'] as String;
                  final statusText = order['status'] as String;
                  final imgPath = order['image'] as String;
                  final titleText = order['title'] as String;
                  final itemsText = order['items'] as String;
                  final dateText = order['date'] as String;
                  final priceText = order['price'] as String;
                  final statusColor = order['statusColor'] as Color;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(orderId, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14, color: _textDark)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withAlpha(80)),
                              ),
                              child: Text(
                                statusText,
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                imgPath,
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(width: 54, height: 54, color: _surfaceBg, child: const Icon(Icons.checkroom)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(titleText, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('$itemsText · $dateText', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                  const SizedBox(height: 4),
                                  Text(priceText, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: _goldDark)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _gold),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Order $orderId package tracking updates active!'),
                                  backgroundColor: _goldDark,
                                ),
                              );
                            },
                            icon: const Icon(Icons.local_shipping_outlined, size: 16, color: _goldDark),
                            label: Text('Track Package Live', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _goldDark)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Wishlist Modal
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
          ],
        ),
      ),
    );
  }

  // 4. Coupons Modal
  void _showCouponsModal() {
    final coupons = [
      {
        'code': 'VEXA30',
        'title': 'Flat 30% OFF Storewide',
        'desc': 'Valid on all 240 GSM drops & bespoke embroidered tees.',
        'exp': 'Expires 30 Sep 2026',
      },
      {
        'code': 'WELCOME100',
        'title': 'Flat ₹100 OFF First Order',
        'desc': 'Instant discount on your first VEXA purchase.',
        'exp': 'Expires 15 Oct 2026',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.55,
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
                      child: const Icon(Icons.confirmation_number_outlined, color: _goldDark, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('VIP COUPONS & OFFERS', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: coupons.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final c = coupons[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gold.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _gold.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: _goldDark, borderRadius: BorderRadius.circular(6)),
                                child: Text(c['code']!, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
                              ),
                              const SizedBox(height: 8),
                              Text(c['title']!, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
                              Text(c['desc']!, style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                              const SizedBox(height: 4),
                              Text(c['exp']!, style: GoogleFonts.outfit(fontSize: 10, color: _goldDark, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _goldDark),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: c['code']!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Copied coupon code "${c['code']}" to clipboard!'),
                                backgroundColor: _goldDark,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Text('Copy', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _goldDark)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Addresses Modal
  void _showAddressesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.55,
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
                      child: const Icon(Icons.location_on_outlined, color: _goldDark, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('SHIPPING ADDRESSES', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _gold, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Home (Default)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _gold.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                        child: Text('DEFAULT', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: _goldDark)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_currentUser?.name ?? 'Tatukula Edukondalu', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: _textDark)),
                  Text('Flat 402, Luxury Heights, Jubilee Hills\nHyderabad, Telangana - 500033\nPhone: +91 98765 43210', style: GoogleFonts.outfit(fontSize: 12, color: _subtext, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _goldDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address management ready!'), backgroundColor: _goldDark),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('ADD NEW ADDRESS', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 6. Payments Modal
  void _showPaymentsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.55,
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
                      child: const Icon(Icons.credit_card_rounded, color: _goldDark, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text('PAYMENT METHODS', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.account_balance_wallet_outlined, color: _goldDark),
              ),
              title: Text('Google Pay / PhonePe UPI', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: _textDark)),
              subtitle: Text('tatukulaedukondalu@okaxis · Verified ✓', style: GoogleFonts.outfit(fontSize: 11, color: _successGreen)),
              trailing: const Icon(Icons.check_circle, color: _goldDark),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.credit_card, color: _goldDark),
              ),
              title: Text('HDFC Bank Visa Credit Card', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: _textDark)),
              subtitle: Text('•••• •••• •••• 4242 · Exp 08/28', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.currency_rupee, color: _goldDark),
              ),
              title: Text('Cash on Delivery (COD)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13.5, color: _textDark)),
              subtitle: Text('Available on orders up to ₹15,000', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
            ),
          ],
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
                          child: Text(
                            _currentUser?.name ?? 'Guest Collector',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
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
                    const SizedBox(height: 2),
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
      (icon: Icons.inventory_2_outlined, title: 'My Orders', badge: 'Active', onTap: _showOrdersModal),
      (icon: Icons.favorite_border_rounded, title: 'Wishlist', badge: '2 items', onTap: _showWishlistModal),
      (icon: Icons.confirmation_number_outlined, title: 'Coupons', badge: 'VIP Offers', onTap: _showCouponsModal),
      (icon: Icons.location_on_outlined, title: 'Addresses', badge: 'Default', onTap: _showAddressesModal),
      (icon: Icons.credit_card_rounded, title: 'Payments', badge: 'UPI & Cards', onTap: _showPaymentsModal),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.1,
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
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _surfaceBg,
                    borderRadius: BorderRadius.circular(10),
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
                        style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: _textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.badge,
                        style: GoogleFonts.outfit(fontSize: 10, color: _subtext),
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
                const Divider(color: _border, height: 1),
                _buildPreferenceTile(
                  icon: Icons.explore_outlined,
                  title: 'Revisit Onboarding Tour',
                  subtitle: 'View luxury features & app walkthrough',
                  trailing: const Icon(Icons.chevron_right_rounded, color: _subtext),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    );
                  },
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
