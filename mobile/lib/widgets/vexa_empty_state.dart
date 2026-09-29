import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable Empty State Component for screens/lists with zero items or no search results.
class VexaEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Color? iconColor;

  const VexaEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onActionTap,
    this.iconColor,
  });

  /// 1. Empty Cart Factory
  factory VexaEmptyState.cart({VoidCallback? onStartShopping}) {
    return VexaEmptyState(
      title: 'Your cart is empty',
      message: 'Looks like you haven\'t added any items to your luxury cart yet.',
      icon: Icons.shopping_bag_outlined,
      actionLabel: 'Start Shopping',
      onActionTap: onStartShopping,
      iconColor: const Color(0xFFB8860B),
    );
  }

  /// 2. Empty Wishlist Factory
  factory VexaEmptyState.wishlist({VoidCallback? onExplore}) {
    return VexaEmptyState(
      title: 'Your wishlist is empty',
      message: 'Save your favorite luxury streetwear items to access them anytime.',
      icon: Icons.favorite_border_rounded,
      actionLabel: 'Explore Items',
      onActionTap: onExplore,
      iconColor: const Color(0xFFEC4899),
    );
  }

  /// 3. No Search Results Factory
  factory VexaEmptyState.searchResults({VoidCallback? onClearSearch}) {
    return VexaEmptyState(
      title: 'No products found',
      message: 'We couldn\'t find any products matching your search criteria. Try checking spelling or resetting filters.',
      icon: Icons.search_off_rounded,
      actionLabel: 'Clear Filters',
      onActionTap: onClearSearch,
      iconColor: const Color(0xFF64748B),
    );
  }

  /// 4. No Orders Factory
  factory VexaEmptyState.orders({VoidCallback? onStartShopping}) {
    return VexaEmptyState(
      title: 'You haven\'t placed any orders yet',
      message: 'When you purchase luxury tees or custom apparel, your orders will appear here.',
      icon: Icons.local_shipping_outlined,
      actionLabel: 'Start Shopping',
      onActionTap: onStartShopping,
      iconColor: const Color(0xFF3B82F6),
    );
  }

  /// 5. No Notifications Factory
  factory VexaEmptyState.notifications({VoidCallback? onRefresh}) {
    return VexaEmptyState(
      title: 'No notifications yet',
      message: 'You\'re all caught up! Order status updates and exclusive drops will show here.',
      icon: Icons.notifications_off_outlined,
      actionLabel: 'Refresh',
      onActionTap: onRefresh,
      iconColor: const Color(0xFF6366F1),
    );
  }

  /// 6. Empty Products Factory
  factory VexaEmptyState.products({VoidCallback? onReset}) {
    return VexaEmptyState(
      title: 'No products available',
      message: 'There are currently no products matching your selected criteria.',
      icon: Icons.checkroom_outlined,
      actionLabel: 'Reset Filters',
      onActionTap: onReset,
      iconColor: const Color(0xFFB8860B),
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Color(0xFFB8860B);
    const textColor = Color(0xFF0F172A);
    const subtextColor = Color(0xFF64748B);
    final themeIconColor = iconColor ?? goldColor;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Decorative Illustration Badge
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeIconColor.withAlpha(20),
                border: Border.all(color: themeIconColor.withAlpha(50), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: themeIconColor.withAlpha(25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 50,
                  color: themeIconColor,
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

            // Message Body
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: subtextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Action Button
            if (actionLabel != null && onActionTap != null)
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onActionTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: goldColor),
                  label: Text(
                    actionLabel!,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
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
