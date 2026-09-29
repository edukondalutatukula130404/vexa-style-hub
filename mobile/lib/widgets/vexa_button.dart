import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum VexaButtonState {
  normal,
  pressed,
  disabled,
  loading,
  success,
  error,
}

/// A premium interactive action button component that natively handles all states:
/// Normal, Pressed, Disabled, Loading, Success, Error.
/// Includes automatic tap throttling to prevent duplicate/repeated API calls.
class VexaButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final VexaButtonState state;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color textColor;
  final double height;
  final double borderRadius;
  final double fontSize;
  final bool fullWidth;

  const VexaButton({
    super.key,
    required this.text,
    this.onPressed,
    this.state = VexaButtonState.normal,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.height = 52,
    this.borderRadius = 16,
    this.fontSize = 15,
    this.fullWidth = true,
  });

  @override
  State<VexaButton> createState() => _VexaButtonState();
}

class _VexaButtonState extends State<VexaButton> with SingleTickerProviderStateMixin {
  DateTime? _lastTapTime;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isLoading || widget.isDisabled || widget.onPressed == null) return;
    if (widget.state == VexaButtonState.loading || widget.state == VexaButtonState.disabled) return;

    // Prevent duplicate rapid taps within 600ms
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!).inMilliseconds < 600) {
      return;
    }
    _lastTapTime = now;

    // Play tactile scale animation
    _scaleController.forward().then((_) => _scaleController.reverse());
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFB8860B);
    const darkBg = Color(0xFF0F172A);
    const disabledBg = Color(0xFFCBD5E1);
    const successBg = Color(0xFF10B981);
    const errorBg = Color(0xFFEF4444);

    final currentState = widget.isLoading
        ? VexaButtonState.loading
        : (widget.isDisabled || widget.onPressed == null
            ? VexaButtonState.disabled
            : widget.state);

    Color bg;
    switch (currentState) {
      case VexaButtonState.loading:
        bg = (widget.backgroundColor ?? darkBg).withValues(alpha: 0.85);
        break;
      case VexaButtonState.disabled:
        bg = disabledBg;
        break;
      case VexaButtonState.success:
        bg = successBg;
        break;
      case VexaButtonState.error:
        bg = errorBg;
        break;
      case VexaButtonState.pressed:
      case VexaButtonState.normal:
        bg = widget.backgroundColor ?? darkBg;
        break;
    }

    Widget content;
    switch (currentState) {
      case VexaButtonState.loading:
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Processing...',
              style: GoogleFonts.outfit(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
                color: widget.textColor,
              ),
            ),
          ],
        );
        break;
      case VexaButtonState.success:
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Success!',
              style: GoogleFonts.outfit(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        );
        break;
      case VexaButtonState.error:
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Failed',
              style: GoogleFonts.outfit(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        );
        break;
      case VexaButtonState.disabled:
      case VexaButtonState.pressed:
      case VexaButtonState.normal:
        content = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 20, color: currentState == VexaButtonState.disabled ? const Color(0xFF64748B) : goldColor),
              const SizedBox(width: 10),
            ],
            Text(
              widget.text,
              style: GoogleFonts.outfit(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                color: currentState == VexaButtonState.disabled ? const Color(0xFF64748B) : widget.textColor,
              ),
            ),
          ],
        );
        break;
    }

    final buttonWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.height,
      width: widget.fullWidth ? double.infinity : null,
      padding: widget.fullWidth ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: currentState == VexaButtonState.normal && widget.onPressed != null
            ? [
                BoxShadow(
                  color: bg.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          onTap: currentState == VexaButtonState.disabled || currentState == VexaButtonState.loading ? null : _handleTap,
          child: Center(child: content),
        ),
      ),
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: buttonWidget,
    );
  }
}
