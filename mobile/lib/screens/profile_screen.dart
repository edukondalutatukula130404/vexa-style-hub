import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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
              // Glowing Avatar Circle
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
                child: Center(
                  child: Text(
                    _currentUser?.name.isNotEmpty == true ? _currentUser!.name[0].toUpperCase() : 'G',
                    style: GoogleFonts.cinzel(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _goldDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser?.name ?? 'Guest Collector',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentUser?.email ?? 'guest@vexa.app',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: _subtext,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // VIP Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _gold.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _gold.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: _goldDark),
                          const SizedBox(width: 4),
                          Text(
                            _currentUser != null && _currentUser!.id != 'guest_user' ? 'VIP MEMBER' : 'GUEST ACCESS',
                            style: GoogleFonts.outfit(
                              color: _goldDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: _border, height: 28),

          // User Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Orders', '0'),
              Container(height: 24, width: 1, color: _border),
              _buildStatItem('Wishlist', '2'),
              Container(height: 24, width: 1, color: _border),
              _buildStatItem('Coupons', '2'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: _goldDark),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11, color: _subtext, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ── 2. SHORTCUTS GRID ───────────────────────────────────────────────────
  Widget _buildShortcutsGrid() {
    final shortcuts = [
      (icon: Icons.inventory_2_outlined, title: 'My Orders', badge: 'Active'),
      (icon: Icons.favorite_border_rounded, title: 'Saved Items', badge: '2 items'),
      (icon: Icons.location_on_outlined, title: 'Addresses', badge: 'Default'),
      (icon: Icons.credit_card_rounded, title: 'Payments', badge: 'UPI & Cards'),
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
        return Container(
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
                    value: true,
                    activeTrackColor: _goldDark,
                    onChanged: (val) {},
                  ),
                ),
                const Divider(color: _border, height: 1),
                _buildPreferenceTile(
                  icon: Icons.language_rounded,
                  title: 'Currency & Region',
                  subtitle: 'India (INR ₹)',
                  trailing: const Icon(Icons.chevron_right_rounded, color: _subtext),
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
                        content: Text(
                          'Need assistance with custom sizing, orders, or delivery?\n\nEmail: support@vexa.app\nPhone: +91 98765 43210',
                          style: GoogleFonts.outfit(color: _subtext, fontSize: 13, height: 1.5),
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: _goldDark),
                            onPressed: () => Navigator.pop(context),
                            child: Text('OK', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
