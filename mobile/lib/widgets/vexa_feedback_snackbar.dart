import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Utility helper class for lightweight feedback toasts, snackbars, and success banners
class VexaFeedback {
  /// General Success SnackBar
  static void showSuccess(BuildContext context, String message, {String? actionLabel, VoidCallback? onActionTap}) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF10B981), // Emerald green
      actionLabel: actionLabel,
      onActionTap: onActionTap,
    );
  }

  /// General Error SnackBar
  static void showError(BuildContext context, String message) {
    _showCustomSnackBar(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: const Color(0xFFEF4444), // Crimson red
    );
  }

  /// Added to Cart Success Banner
  static void showAddToCartSuccess(BuildContext context, {required String productName, VoidCallback? onViewCart}) {
    _showCustomSnackBar(
      context,
      message: '"$productName" added to cart',
      icon: Icons.shopping_bag_rounded,
      backgroundColor: const Color(0xFF0F172A),
      iconColor: const Color(0xFFB8860B),
      actionLabel: 'VIEW CART',
      onActionTap: onViewCart,
    );
  }

  /// Wishlist Updated Banner
  static void showWishlistSuccess(BuildContext context, {required bool isAdded, required String productName}) {
    _showCustomSnackBar(
      context,
      message: isAdded ? '"$productName" saved to Wishlist' : 'Removed from Wishlist',
      icon: isAdded ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      backgroundColor: isAdded ? const Color(0xFF8B5CF6) : const Color(0xFF64748B),
      iconColor: Colors.white,
    );
  }

  /// Order Placed Dialog / Toast
  static void showOrderPlacedSuccess(BuildContext context, {required String orderId}) {
    _showCustomSnackBar(
      context,
      message: 'Order $orderId placed successfully!',
      icon: Icons.verified_rounded,
      backgroundColor: const Color(0xFF10B981),
      iconColor: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// Payment Success Feedback
  static void showPaymentSuccess(BuildContext context, {required String paymentId}) {
    _showCustomSnackBar(
      context,
      message: 'Payment Successful! (Ref: $paymentId)',
      icon: Icons.task_alt_rounded,
      backgroundColor: const Color(0xFF10B981),
      iconColor: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  static void _showCustomSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    Color iconColor = Colors.white,
    String? actionLabel,
    VoidCallback? onActionTap,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: backgroundColor,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actionLabel != null && onActionTap != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onActionTap();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  backgroundColor: const Color(0xFFB8860B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
