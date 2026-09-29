import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Error Component for API, Network, or Server Failures.
class VexaErrorWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool isCompact;
  final bool isDark;

  const VexaErrorWidget({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'Unable to load data. Please check your internet connection and try again.',
    this.onRetry,
    this.icon = Icons.cloud_off_rounded,
    this.isCompact = false,
    this.isDark = false,
  });

  /// Preset constructor for product loading errors
  factory VexaErrorWidget.products({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return VexaErrorWidget(
      title: 'Unable to load products',
      message: customMessage ?? 'Please check your internet connection and try again.',
      icon: Icons.storefront_outlined,
      onRetry: onRetry,
    );
  }

  /// Preset constructor for order loading errors
  factory VexaErrorWidget.orders({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return VexaErrorWidget(
      title: 'Unable to load orders',
      message: customMessage ?? 'We encountered an error fetching your orders. Please try again.',
      icon: Icons.receipt_long_outlined,
      onRetry: onRetry,
    );
  }

  /// Preset constructor for profile/user errors
  factory VexaErrorWidget.profile({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return VexaErrorWidget(
      title: 'Failed to load profile',
      message: customMessage ?? 'Could not fetch profile details. Please try again.',
      icon: Icons.person_off_outlined,
      onRetry: onRetry,
    );
  }

  /// Preset constructor for network/connectivity errors
  factory VexaErrorWidget.noInternet({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return VexaErrorWidget(
      title: 'No Internet Connection',
      message: customMessage ?? 'Please check your internet connection and try again.',
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
    );
  }

  /// Preset constructor for cart errors
  factory VexaErrorWidget.cart({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return VexaErrorWidget(
      title: 'Unable to update cart',
      message: customMessage ?? 'We encountered an error syncing your cart. Please try again.',
      icon: Icons.shopping_bag_outlined,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFB8860B);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF4444).withAlpha(60)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, color: goldColor),
                tooltip: 'Try Again',
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Error Illustration Circle Badge
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEF2F2),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withAlpha(30),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 46,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Helpful explanation message
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: subtextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),

            // Try Again / Retry Button
            if (onRetry != null)
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: goldColor),
                  label: Text(
                    'Try Again',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
