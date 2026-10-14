import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/vexa_button.dart';
import '../widgets/server_config_dialog.dart';
import 'terms_screen.dart';

const Color _goldDark = Color(0xFF8B6508);

enum LoginStep {
  identifier, // Step 1: Input "Phone number or email"
  password,   // Step 2A: Email entered -> Input Password -> Login
  otp,        // Step 2B: Mobile entered -> Input 6-Digit OTP -> Login
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  LoginStep _currentStep = LoginStep.identifier;

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  String? _errorMessage;

  int _resendCountdown = 0;
  Timer? _resendTimer;

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _agreeToTerms = false;
    _termsRecognizer = TapGestureRecognizer()..onTap = _openTermsPage;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _openPrivacyPolicyPage;
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 30;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown <= 1) {
        timer.cancel();
        setState(() {
          _resendCountdown = 0;
        });
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  Future<void> _openTermsPage() async {
    final agreed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsScreen(isPrivacyPolicy: false),
      ),
    );
    if (agreed == true && mounted) {
      setState(() {
        _agreeToTerms = true;
      });
    }
  }

  Future<void> _openPrivacyPolicyPage() async {
    final agreed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsScreen(isPrivacyPolicy: true),
      ),
    );
    if (agreed == true && mounted) {
      setState(() {
        _agreeToTerms = true;
      });
    }
  }

  bool _isEmailInput(String input) {
    final clean = input.trim();
    return clean.contains('@') || RegExp(r'[a-zA-Z]').hasMatch(clean);
  }

  String _cleanPhoneNumber(String input) {
    var raw = input.trim().replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (raw.startsWith('91') && raw.length > 10) {
      raw = raw.substring(2);
    }
    return raw;
  }

  // ── STEP 1: VERIFY IDENTIFIER & ADVANCE TO PASSWORD OR OTP ────────────────
  Future<void> _handleIdentifierContinue() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final input = _identifierController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_isEmailInput(input)) {
      // Input is Email -> Check if registered -> Advance to Password Screen
      final email = input.toLowerCase();
      final isRegistered = await ApiService.isAccountRegistered(email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (!isRegistered) {
        setState(() {
          _errorMessage = 'Mail not registered. Please enter a registered email.';
        });
        return;
      }

      setState(() {
        _currentStep = LoginStep.password;
        _errorMessage = null;
      });
    } else {
      // Input is Mobile Number -> Check if registered -> Send OTP -> Advance to OTP Screen
      final phone = _cleanPhoneNumber(input);
      final isRegistered = await ApiService.isAccountRegistered(phone);

      if (!isRegistered) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Mobile number not registered';
        });
        return;
      }

      // Request 6-digit OTP
      final result = await ApiService.sendMobileOtp(phone);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        final otpCode = result['otp'];
        if (otpCode != null) {
          _otpController.text = otpCode.toString();
        }
        _startResendTimer();
        setState(() {
          _currentStep = LoginStep.otp;
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '6-digit OTP sent to your registered mobile/email'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Mobile number not registered';
        });
      }
    }
  }

  // ── STEP 2A: PASSWORD VERIFICATION & LOGIN ────────────────────────────────
  Future<void> _handlePasswordLogin() async {
    if (!_agreeToTerms) {
      _showTermsNotice();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _identifierController.text.trim();
    final password = _passwordController.text;

    final result = await ApiService.login(email, password);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      await _completeLoginSuccess(result['user'], result['token']);
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Invalid password. Please try again.';
      });
    }
  }

  // ── STEP 2B: OTP VERIFICATION & LOGIN ─────────────────────────────────────
  Future<void> _handleOtpLogin() async {
    if (!_agreeToTerms) {
      _showTermsNotice();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final phone = _cleanPhoneNumber(_identifierController.text);
    final otp = _otpController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.verifyMobileOtp(phone, otp);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      await _completeLoginSuccess(result['user'], result['token']);
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Invalid or expired OTP. Please try again.';
      });
    }
  }

  void _showTermsNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Please agree to the Terms & Conditions and Privacy Policy to continue.',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _completeLoginSuccess(dynamic user, dynamic token) async {
    OrderService.clearLocalSession();
    NotificationService.clearAll();
    await AuthService.saveSession(user, token ?? 'mock_token');
    await AuthService.setOnboardingSeen();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Welcome back, ${user.name}!'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _handleGuestAccess() async {
    final guestUser = UserModel(
      id: 'guest_user',
      name: 'Guest Collector',
      email: 'guest@vexa.app',
      role: 'guest',
    );
    OrderService.clearLocalSession();
    NotificationService.clearAll();
    await AuthService.saveSession(guestUser, 'guest_token');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  bool _onBackPressed() {
    if (_currentStep != LoginStep.identifier) {
      setState(() {
        _currentStep = LoginStep.identifier;
        _errorMessage = null;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return PopScope(
      canPop: _currentStep == LoginStep.identifier,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onBackPressed();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ── HERO TOP HEADER REGION ───────────────────────────
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: 250.0 + topPadding,
                          ),
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
                                      if (!_onBackPressed()) return;
                                      if (Navigator.canPop(context)) {
                                        Navigator.pop(context);
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
                                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
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
                                    const SizedBox(height: 16),
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
                      ),

                      // ── BOTTOM ROUNDED SHEET CONTAINER ──────────────────
                      Transform.translate(
                        offset: const Offset(0, -22),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 16,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.fromLTRB(24, 18, 24, 28 + bottomPadding + 22),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Handle bar
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

                                // Error Banner if any
                                if (_errorMessage != null) ...[
                                  InkWell(
                                    onTap: () {
                                      ServerConfigDialog.show(context).then((_) {
                                        if (mounted) setState(() { _errorMessage = null; });
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.errorColor.withAlpha(15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppTheme.errorColor.withAlpha(60)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: GoogleFonts.outfit(
                                                color: AppTheme.errorColor,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.tune_rounded, size: 16, color: _goldDark),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Active Step Body
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: _buildCurrentStepContent(),
                                ),

                                const SizedBox(height: 22),

                                // Register Link
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
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case LoginStep.identifier:
        return _buildStep1Identifier();
      case LoginStep.password:
        return _buildStep2Password();
      case LoginStep.otp:
        return _buildStep2Otp();
    }
  }

  // ── STEP 1: PHONE NUMBER OR EMAIL ─────────────────────────────────────────
  Widget _buildStep1Identifier() {
    return Column(
      key: const ValueKey('step_identifier'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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

        // Input Field: Phone number or email
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
          controller: _identifierController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w500),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your registered email or phone number';
            }
            return null;
          },
          decoration: _inputDecoration(
            hintText: 'name@example.com · 9876...',
            prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF64748B), size: 20),
          ),
        ),
        const SizedBox(height: 22),

        // Continue Button
        SizedBox(
          width: double.infinity,
          child: VexaButton(
            text: 'Continue',
            isLoading: _isLoading,
            isDisabled: _isLoading,
            onPressed: _handleIdentifierContinue,
            backgroundColor: _goldDark,
            borderRadius: 14,
            height: 52,
          ),
        ),
      ],
    );
  }

  // ── STEP 2A: PASSWORD SCREEN (FOR EMAIL) ──────────────────────────────────
  Widget _buildStep2Password() {
    final email = _identifierController.text.trim();

    return Column(
      key: const ValueKey('step_password'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENTER PASSWORD',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: _goldDark,
          ),
        ),
        const SizedBox(height: 10),

        // Selected Email Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mark_email_read_rounded, size: 18, color: _goldDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  email,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

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
              return 'Please enter your password';
            }
            return null;
          },
          decoration: _inputDecoration(
            hintText: '••••••••',
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
          ),
        ),

        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forget'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
        const SizedBox(height: 12),

        // Terms Agreement Checkbox
        _buildTermsRow(),
        const SizedBox(height: 18),

        // Sign In Button
        SizedBox(
          width: double.infinity,
          child: VexaButton(
            text: 'Sign In',
            isLoading: _isLoading,
            isDisabled: _isLoading,
            onPressed: _handlePasswordLogin,
            backgroundColor: _goldDark,
            borderRadius: 14,
            height: 52,
          ),
        ),
      ],
    );
  }

  // ── STEP 2B: OTP SCREEN (FOR MOBILE NUMBER) ───────────────────────────────
  Widget _buildStep2Otp() {
    final phone = _cleanPhoneNumber(_identifierController.text);

    return Column(
      key: const ValueKey('step_otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENTER 6-DIGIT OTP',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: _goldDark,
          ),
        ),
        const SizedBox(height: 10),

        // Selected Phone Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 18, color: _goldDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '+91 $phone',
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // OTP Field
        Text(
          'Verification Code (OTP)',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontSize: 20,
            letterSpacing: 6,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          validator: (value) {
            if (value == null || value.trim().length != 6) {
              return 'Please enter 6-digit OTP code';
            }
            return null;
          },
          decoration: _inputDecoration(
            hintText: '••••••',
            prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF64748B), size: 20),
          ),
        ),

        // Resend OTP Countdown
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _resendCountdown > 0 ? null : _handleIdentifierContinue,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _resendCountdown > 0 ? 'Resend OTP in ${_resendCountdown}s' : 'Resend OTP',
              style: GoogleFonts.outfit(
                color: _resendCountdown > 0 ? const Color(0xFF94A3B8) : _goldDark,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Terms Agreement Checkbox
        _buildTermsRow(),
        const SizedBox(height: 18),

        // Verify & Login Button
        SizedBox(
          width: double.infinity,
          child: VexaButton(
            text: 'Verify & Login',
            isLoading: _isLoading,
            isDisabled: _isLoading,
            onPressed: _handleOtpLogin,
            backgroundColor: _goldDark,
            borderRadius: 14,
            height: 52,
          ),
        ),
      ],
    );
  }

  // ── TERMS & CONDITIONS CHECKBOX ROW ───────────────────────────────────────
  Widget _buildTermsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _agreeToTerms = !_agreeToTerms;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 9, top: 4, bottom: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: _agreeToTerms ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _agreeToTerms ? Colors.black : const Color(0xFF94A3B8),
                    width: 1.6,
                  ),
                ),
                child: _agreeToTerms
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  color: const Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: 'Terms & Conditions',
                    recognizer: _termsRecognizer,
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationThickness: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: ' and ',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(
                    text: 'Privacy Policy',
                    recognizer: _privacyRecognizer,
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationThickness: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
