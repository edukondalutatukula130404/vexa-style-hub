import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/server_config_dialog.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

// ── Gold colour tokens ─────────────────────────────────────────────────────
const Color _gold = Color(0xFFD4AF37);
const Color _goldDark = Color(0xFF966F1E);
const Color _cream = Color(0xFFF4EFE6);
const Color _cardBg = Color(0xFF1A1814);
const Color _surfaceBg = Color(0xFF22201D);
const Color _bgColor = Color(0xFF0F0E0C);
const Color _subtext = Color(0xFFB0A89C);
const Color _border = Color(0xFF2E2B27);

// ── Smart image loader: asset path → Image.asset, URL → Image.network ───────
Widget _productImage(
  String src, {
  double? height,
  double? width,
  BoxFit fit = BoxFit.cover,
}) {
  if (src.startsWith('assets/')) {
    return Image.asset(src, height: height, width: width, fit: fit);
  }
  return Image.network(
    src,
    height: height,
    width: width,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => Container(
      height: height,
      width: width,
      color: _surfaceBg,
      child: const Center(child: Icon(Icons.image_outlined, color: _subtext, size: 32)),
    ),
  );
}

// ── Static feature data (mirrors web) ─────────────────────────────────────
const _features = [
  (icon: Icons.checkroom_rounded, title: 'Premium Cotton Fabric', body: '240 GSM combed long-staple cotton.'),
  (icon: Icons.straighten_rounded, title: 'Oversized Modern Fit', body: 'Drop shoulder, sculpted drape.'),
  (icon: Icons.air_rounded, title: 'Soft & Breathable', body: 'Bio-washed for all-day comfort.'),
  (icon: Icons.verified_rounded, title: 'Wrinkle Resistant', body: 'Holds its shape wash after wash.'),
];

const _services = [
  (icon: Icons.chat_bubble_outline_rounded, title: 'WhatsApp Order', body: 'Order in one message'),
  (icon: Icons.local_shipping_outlined, title: 'Fast Delivery', body: '2–4 day dispatch'),
  (icon: Icons.currency_rupee_rounded, title: 'Cash on Delivery', body: 'Pay when it arrives'),
  (icon: Icons.shield_outlined, title: 'Quality Guarantee', body: '30-day easy returns'),
];

const _promoBanners = [
  (
    tag: 'LIMITED EDITION DROP',
    title: 'URBAN SILHOUETTE\nCOLLECTION',
    subtitle: 'FLAT 30% OFF STOREWIDE',
    body: 'Sculpted from 240 GSM bio-washed heavy cotton with double-stitched collar reinforcement.',
    cta: 'EXPLORE COLLECTION',
    img: 'assets/images/promo_banner_1.png',
  ),
  (
    tag: 'BESPOKE CUSTOMISATION',
    title: 'BOOK YOUR\nCUSTOM TEE',
    subtitle: 'PERSONALIZED EMBROIDERY & BULK ORDERS',
    body: 'Personalize colorways, custom embroidery & bulk orders directly from your user dashboard.',
    cta: 'BOOK CUSTOM TEE',
    img: 'assets/images/promo_banner_2.png',
  ),
  (
    tag: 'VEXA SIGNATURE ESSENTIALS',
    title: '240 GSM\nHEAVYWEIGHT FIT',
    subtitle: 'COMFORT MEETS LUXURY STREETWEAR',
    body: 'Engineered for lasting quality, zero color bleeding, and pre-shrunk combed long-staple luxury cotton.',
    cta: 'SHOP CATALOG',
    img: 'assets/images/hero_luxury_tshirt.png',
  ),
];

const _marqueeItems = [
  'FREE SHIPPING OVER ₹1999',
  'PREMIUM COTTON',
  'OVERSIZED FIT',
  'CASH ON DELIVERY',
  '30-DAY RETURNS',
  'LIMITED DROPS',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  UserModel? _currentUser;
  List<ItemModel> _items = ApiService.getFallbackItems(); // show products immediately
  final bool _isLoading = false; // always ready — items pre-loaded from local assets
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final Set<String> _favoriteIds = {};
  int _currentTabIndex = 0;
  final List<CartItemData> _cartItems = [];

  // Auto-cycle promo banner
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  // Marquee scroll
  late final ScrollController _marqueeController;
  Timer? _marqueeTimer;

  final List<String> _categories = ['All', 'T-Shirts', 'Tops', 'Jackets', 'Pants'];

  @override
  void initState() {
    super.initState();
    ApiConfig.baseUrlNotifier.addListener(_onServerUrlChanged);
    _loadUserAndItems();

    // Start promo banner auto-cycle
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _bannerIndex = (_bannerIndex + 1) % _promoBanners.length);
    });

    // Marquee scroll controller
    _marqueeController = ScrollController();
    Future.delayed(const Duration(milliseconds: 600), _startMarquee);
  }

  void _startMarquee() {
    if (!mounted || !_marqueeController.hasClients) return;
    _marqueeTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted || !_marqueeController.hasClients) return;
      final max = _marqueeController.position.maxScrollExtent;
      final pos = _marqueeController.offset;
      if (pos >= max) {
        _marqueeController.jumpTo(0);
      } else {
        _marqueeController.animateTo(
          pos + 1.5,
          duration: const Duration(milliseconds: 30),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  void dispose() {
    ApiConfig.baseUrlNotifier.removeListener(_onServerUrlChanged);
    _bannerTimer?.cancel();
    _marqueeTimer?.cancel();
    _marqueeController.dispose();
    super.dispose();
  }

  void _onServerUrlChanged() {
    if (mounted) _loadUserAndItems();
  }

  Future<void> _loadUserAndItems() async {
    // Load user session (fast — local storage)
    final user = await AuthService.getUser();
    if (!mounted) return;
    setState(() => _currentUser = user);

    // Fetch from API in background — UI already shows fallback items
    try {
      final items = await ApiService.getItems();
      if (!mounted) return;
      if (items.isNotEmpty) {
        setState(() => _items = items);
      }
    } catch (_) {
      // Keep showing the pre-loaded fallback items
    }
  }

  void _addToCart(ItemModel item, String color, String size, int quantity) {
    setState(() {
      final idx = _cartItems.indexWhere((c) => c.item.id == item.id && c.selectedColor == color && c.selectedSize == size);
      if (idx >= 0) {
        _cartItems[idx].quantity += quantity;
      } else {
        _cartItems.add(CartItemData(item: item, selectedColor: color, selectedSize: size, quantity: quantity));
      }
    });
  }

  int get _totalCartCount => _cartItems.fold(0, (s, c) => s + c.quantity);

  List<ItemModel> get _filteredItems {
    return _items.where((item) {
      final matchCat = _selectedCategory == 'All' || item.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  void _openProductDetail(ItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          item: item,
          onAddToCart: (it, color, size, qty) => _addToCart(it, color, size, qty),
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text('Log Out', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out of VEXA Style Hub?', style: GoogleFonts.outfit(color: _subtext)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              final nav = Navigator.of(context);
              await AuthService.clearSession();
              if (!mounted) return;
              nav.pop();
              nav.pushReplacementNamed('/login');
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD DISCOVER TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDiscoverTab() {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : RefreshIndicator(
              onRefresh: _loadUserAndItems,
              color: _gold,
              child: CustomScrollView(
                slivers: [
                  // 1. HERO BANNER
                  SliverToBoxAdapter(child: _buildHero()),

                  // 2. MARQUEE TICKER
                  SliverToBoxAdapter(child: _buildMarquee()),

                  // 3. FEATURES GRID
                  SliverToBoxAdapter(child: _buildFeaturesSection()),

                  // 4. PROMO BANNER CAROUSEL
                  SliverToBoxAdapter(child: _buildPromoBannerCarousel()),

                  // 5. NEW ARRIVALS (horizontal scroll)
                  SliverToBoxAdapter(child: _buildNewArrivalsSection()),

                  // 6. SEARCH + CATEGORY PILLS + FEATURED CATALOG
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildCategoryPills()),
                  SliverToBoxAdapter(child: _buildFeaturedCatalogHeader()),
                  _buildCatalogGrid(),

                  // 7. SERVICES BAR
                  SliverToBoxAdapter(child: _buildServicesBar()),

                  // 8. JOIN VEXA CTA
                  SliverToBoxAdapter(child: _buildJoinCta()),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _bgColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _goldDark.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _gold.withAlpha(120)),
            ),
            child: Text('V', style: GoogleFonts.cinzel(color: _gold, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('VEXA', style: GoogleFonts.cinzel(fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 16, color: _gold)),
              Text('WEAR CONFIDENCE', style: GoogleFonts.outfit(fontSize: 7, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: Colors.white60)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.dns_rounded, color: _gold, size: 20),
          tooltip: 'Server Settings',
          onPressed: () => ServerConfigDialog.show(context),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
              onPressed: () => setState(() => _currentTabIndex = 1),
            ),
            if (_totalCartCount > 0)
              Positioned(
                right: 2,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: _goldDark, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text('$_totalCartCount',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
          ],
        ),
        if (_currentUser == null)
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 4),
            child: SizedBox(
              height: 32,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _goldDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => Navigator.pushNamed(context, '/login'),
                icon: const Icon(Icons.lock_outline_rounded, size: 12),
                label: Text('LOGIN', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
              ),
            ),
          )
        else
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.logout_rounded, color: _subtext, size: 20),
            onPressed: _handleLogout,
            tooltip: 'Log Out',
          ),
      ],
    );
  }

  // ── 1. HERO ────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _goldDark.withAlpha(80)),
          boxShadow: [BoxShadow(color: _goldDark.withAlpha(30), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tag pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _gold.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gold.withAlpha(80)),
              ),
              child: Text('Elevate your everyday style',
                  style: GoogleFonts.outfit(fontSize: 10, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 14),
            // Title
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: 'PREMIUM\nT-SHIRT\n',
                  style: GoogleFonts.cinzel(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: 1.2, color: _cream),
                ),
                TextSpan(
                  text: 'COLLECTION',
                  style: GoogleFonts.cinzel(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: 1.2, color: _gold),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Text(
              'Engineered in 240 GSM heavyweight cotton, finished by hand, and cut for the modern oversized silhouette. This is VEXA — wear confidence, wear style.',
              style: GoogleFonts.outfit(fontSize: 12.5, color: _subtext, height: 1.5),
            ),
            const SizedBox(height: 20),
            // CTA Buttons
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldDark,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => setState(() => _selectedCategory = 'All'),
                  child: FittedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('SHOP THE DROP',
                            style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.white)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _cream),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/onboarding'),
                  child: FittedBox(
                    child: Text('OUR STORY',
                        style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: _cream)),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // Featured product card preview
            if (_items.isNotEmpty) _buildHeroProductCard(_items.first),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroProductCard(ItemModel item) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _goldDark.withAlpha(100)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Always show the same hero image as mobile responsive website
              Image.asset(
                'assets/images/hero_luxury_tshirt.png',
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _goldDark),
                  ),
                  child: Text('SIGNATURE DROP',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: const Color(0xFF1C1917))),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _goldDark, borderRadius: BorderRadius.circular(6)),
                  child: Text('30% Off',
                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('₹${item.price.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: _gold)),
                        if (item.oldPrice != null) ...[
                          const SizedBox(width: 8),
                          Text('₹${item.oldPrice!.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(fontSize: 12, color: _subtext, decoration: TextDecoration.lineThrough)),
                        ],
                      ]),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: () => _openProductDetail(item),
                  child: Text('View', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. MARQUEE TICKER ─────────────────────────────────────────────────
  Widget _buildMarquee() {
    final items = [..._marqueeItems, ..._marqueeItems];
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: _border, width: 1)),
      ),
      height: 40,
      child: ListView.builder(
        controller: _marqueeController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            '✦  ${items[i]}',
            style: GoogleFonts.outfit(fontSize: 10, letterSpacing: 2, color: _subtext, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  // ── 3. FEATURES GRID ──────────────────────────────────────────────────
  Widget _buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Engineered Excellence',
              style: GoogleFonts.outfit(fontSize: 10, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 3)),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(text: 'Crafted to the ', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: 'last stitch', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: _gold)),
            ]),
          ),
          const SizedBox(height: 4),
          Container(height: 1, width: 120, color: _gold.withAlpha(60)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: _features
                .map((f) => _FeatureCard(icon: f.icon, title: f.title, body: f.body))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── 4. PROMO BANNER CAROUSEL ──────────────────────────────────────────
  Widget _buildPromoBannerCarousel() {
    final b = _promoBanners[_bannerIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Featured Highlights',
              style: GoogleFonts.outfit(fontSize: 10, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 3)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(children: [
              TextSpan(text: 'Promotional ', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: 'Showcase', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: _gold)),
            ]),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: _PromoBannerCard(key: ValueKey(_bannerIndex), banner: b),
          ),
          // Dot indicators
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_promoBanners.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _bannerIndex ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _bannerIndex ? _gold : _subtext.withAlpha(80),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── 5. NEW ARRIVALS ────────────────────────────────────────────────────
  Widget _buildNewArrivalsSection() {
    final newArrivals = _items.take(4).toList();
    if (newArrivals.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LATEST DROPS',
                    style: GoogleFonts.outfit(fontSize: 10, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 3)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('New Arrivals', style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    GestureDetector(
                      onTap: () => setState(() => _selectedCategory = 'All'),
                      child: Row(children: [
                        Text('Explore All', style: GoogleFonts.outfit(fontSize: 11, color: _gold, fontWeight: FontWeight.w600)),
                        const Icon(Icons.arrow_forward_rounded, size: 14, color: _gold),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: newArrivals.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 14),
                child: SizedBox(width: 190, child: _buildHorizontalProductCard(newArrivals[i])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProductCard(ItemModel item) {
    final isFav = _favoriteIds.contains(item.id);
    return GestureDetector(
      onTap: () => _openProductDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  _productImage(
                    item.image,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => isFav ? _favoriteIds.remove(item.id) : _favoriteIds.add(item.id)),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black.withAlpha(140),
                        child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? const Color(0xFFFF4757) : Colors.white, size: 16),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black.withAlpha(160), borderRadius: BorderRadius.circular(6)),
                      child: Text(item.category, style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('₹${item.price.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: _gold)),
                    if (item.oldPrice != null) ...[
                      const SizedBox(width: 6),
                      Text('₹${item.oldPrice!.toStringAsFixed(0)}',
                          style: GoogleFonts.outfit(fontSize: 11, color: _subtext, decoration: TextDecoration.lineThrough)),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 6. SEARCH + CATEGORIES + CATALOG ──────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.outfit(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search tees, tops, jackets...',
          prefixIcon: const Icon(Icons.search_rounded, color: _subtext),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(icon: const Icon(Icons.close_rounded, color: _subtext), onPressed: () => setState(() => _searchQuery = ''))
              : null,
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final sel = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: sel,
              onSelected: (_) => setState(() => _selectedCategory = cat),
              selectedColor: _goldDark,
              backgroundColor: _cardBg,
              checkmarkColor: Colors.white,
              labelStyle: GoogleFonts.outfit(color: sel ? Colors.white : _subtext, fontWeight: sel ? FontWeight.bold : FontWeight.normal, fontSize: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: sel ? _gold : _border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCatalogHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Explore the catalog', style: GoogleFonts.outfit(fontSize: 10, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 3)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Featured Collection', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('${_filteredItems.length} items', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
            ],
          ),
        ],
      ),
    );
  }

  SliverWidget _buildCatalogGrid() {
    if (_filteredItems.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(children: [
            const Icon(Icons.checkroom_outlined, size: 60, color: _subtext),
            const SizedBox(height: 16),
            Text('No items found', style: GoogleFonts.outfit(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Try adjusting your search or filter.', style: GoogleFonts.outfit(color: _subtext)),
          ]),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.62,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _filteredItems[index];
            final isFav = _favoriteIds.contains(item.id);
            return GestureDetector(
              onTap: () => _openProductDetail(item),
              child: Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          _productImage(
                            item.image,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => isFav ? _favoriteIds.remove(item.id) : _favoriteIds.add(item.id)),
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.black.withAlpha(130),
                                child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFav ? const Color(0xFFFF4757) : Colors.white, size: 17),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(color: Colors.black.withAlpha(160), borderRadius: BorderRadius.circular(7)),
                              child: Text(item.category, style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 3),
                          Row(children: [
                            Text('₹${item.price.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: _gold)),
                            if (item.oldPrice != null) ...[
                              const SizedBox(width: 6),
                              Text('₹${item.oldPrice!.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(fontSize: 11, color: _subtext, decoration: TextDecoration.lineThrough)),
                            ],
                          ]),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 32,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _goldDark,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                _addToCart(item, item.color, 'M', 1);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Added ${item.name} to cart'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: _goldDark,
                                ));
                              },
                              child: Text('Add to Cart', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: _filteredItems.length,
        ),
      ),
    );
  }

  // ── 7. SERVICES BAR ────────────────────────────────────────────────────
  Widget _buildServicesBar() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: _border)),
        color: _cardBg,
      ),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 3.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 16,
        children: _services
            .map((s) => Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _gold.withAlpha(100)),
                      ),
                      child: Icon(s.icon, color: _gold, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(s.title,
                              style: GoogleFonts.outfit(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(s.body, style: GoogleFonts.outfit(fontSize: 10, color: _subtext), maxLines: 1),
                        ],
                      ),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  // ── 8. JOIN VEXA CTA ────────────────────────────────────────────────────
  Widget _buildJoinCta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_goldDark.withAlpha(40), _gold.withAlpha(15), _goldDark.withAlpha(40)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gold.withAlpha(80)),
        ),
        child: Column(
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(children: [
                TextSpan(text: 'Join the ', style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                TextSpan(text: 'VEXA', style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.bold, color: _gold)),
                TextSpan(text: ' circle', style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 12),
            Text(
              'Create an account for early access to limited drops, member pricing and free express shipping.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12.5, color: _subtext, height: 1.5),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _goldDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text('Create Account',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _gold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: Text('Sign In',
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: _gold, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ROOT BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildDiscoverTab(),
          CartScreen(cartItems: _cartItems, onCartUpdated: () => setState(() {})),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: _border, width: 1))),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (i) => setState(() => _currentTabIndex = i),
          backgroundColor: _cardBg,
          selectedItemColor: _gold,
          unselectedItemColor: _subtext,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore_rounded), label: 'Discover'),
            BottomNavigationBarItem(
              icon: Badge(label: Text('$_totalCartCount'), isLabelVisible: _totalCartCount > 0, backgroundColor: _goldDark, child: const Icon(Icons.shopping_bag_outlined)),
              activeIcon: Badge(label: Text('$_totalCartCount'), isLabelVisible: _totalCartCount > 0, backgroundColor: _goldDark, child: const Icon(Icons.shopping_bag_rounded)),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withAlpha(60)),
        boxShadow: [BoxShadow(color: _gold.withAlpha(10), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _gold.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _gold.withAlpha(80)),
            ),
            child: Icon(icon, color: _gold, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 9, color: _subtext, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

typedef _PromoBannerData = ({
  String tag,
  String title,
  String subtitle,
  String body,
  String cta,
  String img,
});

class _PromoBannerCard extends StatelessWidget {
  final _PromoBannerData banner;
  const _PromoBannerCard({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withAlpha(80)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              banner.img,
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xEA0F0E0C), Color(0x880F0E0C), Color(0x000F0E0C)],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _cream,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withAlpha(100)),
                  ),
                  child: Text(banner.tag,
                      style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: const Color(0xFF1C1917))),
                ),
                const SizedBox(height: 10),
                Text(banner.title,
                    style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                const SizedBox(height: 6),
                Text('✨ ${banner.subtitle} ✨',
                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _gold, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Text(banner.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 11, color: _subtext, height: 1.4)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _goldDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(banner.cta,
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Typedef alias so SliverWidget compiles without issue
typedef SliverWidget = Widget;
