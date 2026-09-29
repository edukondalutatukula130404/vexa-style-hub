import 'package:flutter/material.dart';

/// Animated Shimmer Effect Widget that sweeps a light highlight across content placeholders
class VexaShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const VexaShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE2E8F0),
    this.highlightColor = const Color(0xFFF8FAFC),
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<VexaShimmer> createState() => _VexaShimmerState();
}

class _VexaShimmerState extends State<VexaShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final double value = _controller.value;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 3 - 1), 0, 0);
  }
}

/// Generic Shimmer Box Placeholder
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final Color? color;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. PRODUCT CARD SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return VexaShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder with discount badge placeholder
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                  ),
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: ShimmerBox(width: 48, height: 20, borderRadius: 6),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collection tag placeholder
                  const ShimmerBox(width: 60, height: 10, borderRadius: 4),
                  const SizedBox(height: 6),
                  // Product name placeholder (2 lines)
                  const ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
                  const SizedBox(height: 4),
                  const ShimmerBox(width: 100, height: 14, borderRadius: 4),
                  const SizedBox(height: 10),
                  // Price & rating row placeholder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 65, height: 16, borderRadius: 4),
                      ShimmerBox(width: 45, height: 14, borderRadius: 4),
                    ],
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

class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;

  const ProductGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.64,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ProductCardSkeleton(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. PRODUCT DETAIL SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class ProductDetailSkeleton extends StatelessWidget {
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return VexaShimmer(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Image Carousel Banner
            const ShimmerBox(
              width: double.infinity,
              height: 380,
              borderRadius: 0,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category pill
                  const ShimmerBox(width: 80, height: 12, borderRadius: 4),
                  const SizedBox(height: 10),
                  // Product title
                  const ShimmerBox(width: 260, height: 22, borderRadius: 6),
                  const SizedBox(height: 6),
                  const ShimmerBox(width: 180, height: 22, borderRadius: 6),
                  const SizedBox(height: 16),
                  // Price and rating row
                  Row(
                    children: const [
                      ShimmerBox(width: 90, height: 26, borderRadius: 6),
                      SizedBox(width: 12),
                      ShimmerBox(width: 60, height: 18, borderRadius: 6),
                      Spacer(),
                      ShimmerBox(width: 70, height: 18, borderRadius: 6),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  // Size Options Label & Pills
                  const ShimmerBox(width: 70, height: 14, borderRadius: 4),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                      5,
                      (index) => const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: ShimmerBox(width: 48, height: 40, borderRadius: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Color Options Label & Pills
                  const ShimmerBox(width: 80, height: 14, borderRadius: 4),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                      4,
                      (index) => const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: ShimmerBox(width: 36, height: 36, borderRadius: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description Label & Text Lines
                  const ShimmerBox(width: 100, height: 16, borderRadius: 4),
                  const SizedBox(height: 12),
                  const ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 220, height: 12, borderRadius: 4),
                  const SizedBox(height: 36),
                  // Bottom Add to Cart Button Placeholder
                  Row(
                    children: const [
                      ShimmerBox(width: 54, height: 54, borderRadius: 16),
                      SizedBox(width: 12),
                      Expanded(child: ShimmerBox(height: 54, borderRadius: 16)),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. CART SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class CartItemSkeleton extends StatelessWidget {
  const CartItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return VexaShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const ShimmerBox(width: 80, height: 80, borderRadius: 12),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 160, height: 14, borderRadius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: 90, height: 12, borderRadius: 4),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(width: 70, height: 16, borderRadius: 4),
                      ShimmerBox(width: 80, height: 28, borderRadius: 8),
                    ],
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

class CartSkeleton extends StatelessWidget {
  const CartSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return VexaShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CartItemSkeleton(),
            const CartItemSkeleton(),
            const CartItemSkeleton(),
            const SizedBox(height: 20),
            // Coupon Box Shimmer
            const ShimmerBox(width: double.infinity, height: 56, borderRadius: 16),
            const SizedBox(height: 20),
            // Summary Card Shimmer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: const [
                  ShimmerBox(width: double.infinity, height: 16, borderRadius: 4),
                  SizedBox(height: 12),
                  ShimmerBox(width: double.infinity, height: 16, borderRadius: 4),
                  SizedBox(height: 12),
                  ShimmerBox(width: double.infinity, height: 16, borderRadius: 4),
                  Divider(height: 24),
                  ShimmerBox(width: double.infinity, height: 22, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. WISHLIST SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class WishlistSkeleton extends StatelessWidget {
  const WishlistSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProductGridSkeleton(itemCount: 4);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. CATEGORIES & HERO SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class CategorySkeleton extends StatelessWidget {
  const CategorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return VexaShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Shimmer
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerBox(width: double.infinity, height: 160, borderRadius: 20),
          ),
          const SizedBox(height: 24),
          // Horizontal category chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: 10),
                child: ShimmerBox(width: 90, height: 40, borderRadius: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. PROFILE SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return VexaShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const ShimmerBox(width: 70, height: 70, borderRadius: 35),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: 140, height: 18, borderRadius: 4),
                        SizedBox(height: 8),
                        ShimmerBox(width: 180, height: 14, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Quick Stat Badges Row
            Row(
              children: const [
                Expanded(child: ShimmerBox(height: 80, borderRadius: 16)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 80, borderRadius: 16)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 80, borderRadius: 16)),
              ],
            ),
            const SizedBox(height: 24),
            // Quick Actions List Placeholder
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: List.generate(
                  4,
                  (index) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: ShimmerBox(width: double.infinity, height: 24, borderRadius: 6),
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

// ─────────────────────────────────────────────────────────────────────────────
// 7. ORDER CARD & LIST SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return VexaShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 100, height: 16, borderRadius: 4),
                ShimmerBox(width: 80, height: 22, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 12),
            const ShimmerBox(width: 140, height: 12, borderRadius: 4),
            const SizedBox(height: 16),
            Row(
              children: const [
                ShimmerBox(width: 50, height: 50, borderRadius: 10),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 140, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 80, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                ShimmerBox(width: 60, height: 16, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderListSkeleton extends StatelessWidget {
  const OrderListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => const OrderCardSkeleton(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. SEARCH RESULTS SKELETON
// ─────────────────────────────────────────────────────────────────────────────
class SearchResultsSkeleton extends StatelessWidget {
  const SearchResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return VexaShimmer(
      child: Column(
        children: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: ShimmerBox(width: double.infinity, height: 50, borderRadius: 16),
          ),
          Expanded(child: ProductGridSkeleton(itemCount: 4)),
        ],
      ),
    );
  }
}
