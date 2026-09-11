import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/server_config_dialog.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  int _currentStep = 1; // 1: Email Request, 2: Reset Code & New Password
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _message;
  bool _isSuccessMessage = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await ApiService.forgotPassword(_emailController.text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      setState(() {
        _isSuccessMessage = true;
        _message = result['message'] ?? 'Reset instructions sent to your email!';
        _currentStep = 2;
      });
    } else {
      setState(() {
        _isSuccessMessage = false;
        _message = result['message'] ?? 'Failed to send reset link.';
      });
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    final result = await ApiService.resetPassword(
      email: _emailController.text,
      password: _newPasswordController.text,
      code: _codeController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      if (result['user'] != null && result['token'] != null) {
        await AuthService.saveSession(result['user'], result['token']);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Please sign in.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      setState(() {
        _isSuccessMessage = false;
        _message = result['message'] ?? 'Failed to reset password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textColor, size: 20),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() {
                _currentStep = 1;
                _message = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded, color: AppTheme.accentColor),
            tooltip: 'Server Connection Settings',
            onPressed: () {
              ServerConfigDialog.show(context).then((_) {
                if (mounted) setState(() { _message = null; });
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 40,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _currentStep == 1 ? 'Forgot Password? 🔑' : 'Reset Your Password 🔒',
                  style: GoogleFonts.outfit(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentStep == 1
                      ? "Enter your account email and we'll send you instructions to reset your password."
                      : "Enter the reset code sent to your email along with your new password.",
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: AppTheme.subtextColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Status Message Card
                if (_message != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (_isSuccessMessage ? AppTheme.successColor : AppTheme.errorColor).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_isSuccessMessage ? AppTheme.successColor : AppTheme.errorColor).withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSuccessMessage ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                          color: _isSuccessMessage ? AppTheme.successColor : AppTheme.errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _message!,
                            style: GoogleFonts.outfit(
                              color: _isSuccessMessage ? AppTheme.successColor : AppTheme.errorColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Step 1 Form: Email
                Text(
                  'Email Address',
                  style: GoogleFonts.outfit(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  enabled: _currentStep == 1,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.outfit(color: AppTheme.textColor),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'alex.smith@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppTheme.subtextColor),
                  ),
                ),
                const SizedBox(height: 20),

                // Step 2 Form: Code and New Password
                if (_currentStep == 2) ...[
                  Text(
                    'Reset Code',
                    style: GoogleFonts.outfit(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(color: AppTheme.textColor),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter reset code';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      hintText: '123456',
                      prefixIcon: Icon(Icons.pin_rounded, color: AppTheme.subtextColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'New Password',
                    style: GoogleFonts.outfit(color: AppTheme.textColor, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.outfit(color: AppTheme.textColor),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.subtextColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppTheme.subtextColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 16),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_currentStep == 1 ? _handleRequestReset : _handleResetPassword),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == 1 ? 'Send Reset Link' : 'Confirm New Password',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // Back to Login Link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back_rounded, color: AppTheme.subtextColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Back to Sign In',
                          style: GoogleFonts.outfit(
                            color: AppTheme.subtextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
