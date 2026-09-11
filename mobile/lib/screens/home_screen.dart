import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'all_products_screen.dart';
import 'products_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';

// ── Gold & White theme tokens ─────────────────────────────────────────────
const Color _gold = Color(0xFFB8860B);
const Color _goldDark = Color(0xFF8B6508);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _surfaceBg = Color(0xFFF1F5F9);
const Color _bgColor = Color(0xFFFAFAFC);
const Color _subtext = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);
const Color _textDark = Color(0xFF0F172A);

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
    imgAlignment: Alignment.topCenter,
  ),
  (
    tag: 'BESPOKE CUSTOMISATION',
    title: 'BOOK YOUR\nCUSTOM TEE',
    subtitle: 'PERSONALIZED EMBROIDERY & BULK ORDERS',
    body: 'Personalize colorways, custom embroidery & bulk orders directly from your user dashboard.',
    cta: 'BOOK CUSTOM TEE',
    img: 'assets/images/promo_banner_2.png',
    imgAlignment: Alignment.center,
  ),
  (
    tag: 'VEXA SIGNATURE ESSENTIALS',
    title: '240 GSM\nHEAVYWEIGHT FIT',
    subtitle: 'COMFORT MEETS LUXURY STREETWEAR',
    body: 'Engineered for lasting quality, zero color bleeding, and pre-shrunk combed long-staple luxury cotton.',
    cta: 'SHOP CATALOG',
    img: 'assets/images/hero_luxury_tshirt.png',
    imgAlignment: Alignment.center,
  ),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<ItemModel> _items = ApiService.getFallbackItems(); // show products immediately
  final bool _isLoading = false; // always ready — items pre-loaded from local assets
  final String _selectedCategory = 'All';
  String _searchQuery = '';
  final Set<String> _favoriteIds = {};
  int _currentTabIndex = 0;
  final List<CartItemData> _cartItems = [];

  // Auto-cycle promo banner
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  // Main page scroll controller
  late final ScrollController _mainScrollController;

  // Middle-Out screen & tab transition controller
  late final AnimationController _tabAnimController;

  @override
  void initState() {
    super.initState();
    _mainScrollController = ScrollController();
    ApiConfig.baseUrlNotifier.addListener(_onServerUrlChanged);
    _loadUserAndItems();

    _tabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _tabAnimController.value = 1.0;

    // Start promo banner auto-cycle
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _bannerIndex = (_bannerIndex + 1) % _promoBanners.length);
    });
  }

  @override
  void dispose() {
    ApiConfig.baseUrlNotifier.removeListener(_onServerUrlChanged);
    _bannerTimer?.cancel();
    _mainScrollController.dispose();
    _tabAnimController.dispose();
    super.dispose();
  }

  void _navigateToScreen(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  bool _isRealUser = false;

  void _onServerUrlChanged() {
    if (mounted) _loadUserAndItems();
  }

  Future<void> _loadUserAndItems() async {
    final user = await AuthService.getUser();
    final realUser = user != null && user.id != 'guest_user';
    if (mounted) {
      setState(() {
        _isRealUser = realUser;
      });
    }

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

  List<ItemModel> get _newArrivals {
    final list = _items.where((it) =>
      it.collectionType.toLowerCase().contains('new') ||
      it.collectionType.toLowerCase().contains('drop')
    ).toList();
    if (list.isNotEmpty) return list;
    return _items.take(2).toList();
  }

  List<ItemModel> get _filteredItems {
    return _items.where((item) {
      final cat = item.category.toLowerCase();
      final sel = _selectedCategory.toLowerCase();
      final matchCat = sel == 'all' ||
          cat == sel ||
          (sel == 't-shirts' && (cat == 'oversized' || cat == 'classic' || cat == 'limited' || cat.contains('shirt'))) ||
          (sel == 'tops' && (cat == 'top' || cat == 'oversized' || cat.contains('top'))) ||
          (sel == 'jackets' && cat.contains('jacket')) ||
          (sel == 'pants' && cat.contains('pant'));

      final matchSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.color.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  List<ItemModel> get _featuredItems {
    final filtered = _filteredItems;
    if (_searchQuery.isNotEmpty || _selectedCategory != 'All') {
      return filtered;
    }
    final newArrivalIds = _newArrivals.map((e) => e.id).toSet();
    final featured = filtered.where((e) => !newArrivalIds.contains(e.id)).toList();
    if (featured.isNotEmpty) return featured;
    return filtered;
  }

  void _openProductDetail(ItemModel item) {
    _navigateToScreen(
      ProductDetailScreen(
        item: item,
        onAddToCart: (it, color, size, qty) => _addToCart(it, color, size, qty),
      ),
    );
  }

  void _handleBannerTap(String cta) {
    if (cta.toLowerCase().contains('custom')) {
      _showCustomTeeBottomSheet();
    } else {
      _navigateToScreen(
        AllProductsScreen(
          items: _items,
          onAddToCart: (item, color, size, qty) => _addToCart(item, color, size, qty),
          favoriteIds: _favoriteIds,
          onToggleFavorite: (id) => setState(() => _favoriteIds.contains(id) ? _favoriteIds.remove(id) : _favoriteIds.add(id)),
        ),
      );
    }
  }

  void _showCustomTeeBottomSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final detailsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _subtext.withAlpha(80),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('BESPOKE CUSTOMISATION', style: GoogleFonts.outfit(fontSize: 10, color: _gold, fontWeight: FontWeight.w700, letterSpacing: 2.5)),
              const SizedBox(height: 4),
              Text('Book Your Custom Tee', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
              const SizedBox(height: 4),
              Text('Personalized embroidery, custom colorways & bulk orders.', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: GoogleFonts.outfit(color: _textDark),
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  labelStyle: GoogleFonts.outfit(color: _subtext),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: _gold),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.outfit(color: _textDark),
                decoration: InputDecoration(
                  labelText: 'Phone / WhatsApp Number',
                  labelStyle: GoogleFonts.outfit(color: _subtext),
                  prefixIcon: const Icon(Icons.phone_outlined, color: _gold),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 2,
                style: GoogleFonts.outfit(color: _textDark),
                decoration: InputDecoration(
                  labelText: 'Customization Details (e.g. Embroidery, color, size)',
                  labelStyle: GoogleFonts.outfit(color: _subtext),
                  prefixIcon: const Icon(Icons.edit_note_rounded, color: _gold),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Custom Tee request submitted! We will reach out on WhatsApp shortly.'),
                        backgroundColor: _goldDark,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  child: Text('Submit Custom Order Request', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
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
                controller: _mainScrollController,
                slivers: [
                  // 1. PROMO BANNER CAROUSEL
                  SliverToBoxAdapter(child: _buildPromoBannerCarousel()),

                  // 2. NEW ARRIVALS (horizontal scroll)
                  SliverToBoxAdapter(child: _buildNewArrivalsSection()),

                  // 3. SEARCH + FEATURED CATALOG (Horizontal Side Scroll)
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  SliverToBoxAdapter(child: _buildFeaturedCatalogHeader()),
                  SliverToBoxAdapter(child: _buildFeaturedCatalogHorizontalList()),

                  // 4. FEATURES GRID (Engineered Excellence)
                  SliverToBoxAdapter(child: _buildFeaturesSection()),

                  // 5. SERVICES BAR (WhatsApp Order)
                  SliverToBoxAdapter(child: _buildServicesBar()),

                  // 6. JOIN VEXA CTA (Last)
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
      centerTitle: false,
      titleSpacing: 16,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
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
              Text('WEAR CONFIDENCE', style: GoogleFonts.outfit(fontSize: 7, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: _subtext)),
            ],
          ),
        ],
      ),
      actions: const [],
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
              TextSpan(text: 'Crafted to the ', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
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
              TextSpan(text: 'Promotional ', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
              TextSpan(text: 'Showcase', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: _gold)),
            ]),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: _PromoBannerCard(
              key: ValueKey(_bannerIndex),
              banner: b,
              onTap: () => _handleBannerTap(b.cta),
            ),
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
    final newArrivals = _newArrivals;
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
                    Text('New Arrivals', style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)),
                    GestureDetector(
                      onTap: () {
                        _navigateToScreen(
                          AllProductsScreen(
                            items: _items,
                            onAddToCart: (item, color, size, qty) => _addToCart(item, color, size, qty),
                            favoriteIds: _favoriteIds,
                            onToggleFavorite: (id) => setState(() => _favoriteIds.contains(id) ? _favoriteIds.remove(id) : _favoriteIds.add(id)),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _gold.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _gold.withAlpha(80)),
                        ),
                        child: Row(children: [
                          Text('Explore All', style: GoogleFonts.outfit(fontSize: 11, color: _gold, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: _gold),
                        ]),
                      ),
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
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
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



  Widget _buildFeaturedCatalogHeader() {
    final items = _featuredItems.length > 4 ? _featuredItems.take(4).toList() : _featuredItems;
    final count = items.length;
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
              Text('Featured Collection', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
              Text('$count items', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCatalogHorizontalList() {
    final items = _featuredItems.length > 4 ? _featuredItems.take(4).toList() : _featuredItems;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          const Icon(Icons.checkroom_outlined, size: 60, color: _subtext),
          const SizedBox(height: 16),
          Text('No items found', style: GoogleFonts.outfit(fontSize: 18, color: _textDark, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Try adjusting your search or filter.', style: GoogleFonts.outfit(color: _subtext)),
        ]),
      );
    }
    return SizedBox(
      height: 325,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (_, index) {
          final item = items[index];
          final isFav = _favoriteIds.contains(item.id);
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: SizedBox(
              width: 200,
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
                          GestureDetector(
                            onTap: () => _openProductDetail(item),
                            child: _productImage(
                              item.image,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
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
                          GestureDetector(
                            onTap: () => _openProductDetail(item),
                            child: Text(item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                          ),
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
            ),
          );
        },
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
                              style: GoogleFonts.outfit(fontSize: 11, color: _textDark, fontWeight: FontWeight.w700, letterSpacing: 0.2),
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
                TextSpan(text: 'Join the ', style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)),
                TextSpan(text: 'VEXA', style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.bold, color: _gold)),
                TextSpan(text: ' circle', style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark)),
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
                    onPressed: () => _navigateToScreen(const RegisterScreen()),
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
                    onPressed: () => _navigateToScreen(const LoginScreen()),
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
          ProductsScreen(
            items: _items,
            onAddToCart: (item, color, size, qty) => _addToCart(item, color, size, qty),
            favoriteIds: _favoriteIds,
            onToggleFavorite: (id) => setState(() => _favoriteIds.contains(id) ? _favoriteIds.remove(id) : _favoriteIds.add(id)),
            showBackButton: false,
          ),
          CartScreen(
            cartItems: _cartItems,
            onCartUpdated: () => setState(() {}),
            onNavigateToProducts: () => setState(() => _currentTabIndex = 1),
          ),
          ProfileScreen(
            onNavigateToDiscover: () async {
              final user = await AuthService.getUser();
              final realUser = user != null && user.id != 'guest_user';
              setState(() {
                _currentTabIndex = 0;
                _isRealUser = realUser;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: (_currentTabIndex == 3 && !_isRealUser)
          ? null
          : Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: _border, width: 1))),
              child: BottomNavigationBar(
                currentIndex: _currentTabIndex,
                onTap: (i) async {
                  final user = await AuthService.getUser();
                  final realUser = user != null && user.id != 'guest_user';
                  setState(() {
                    _currentTabIndex = i;
                    _isRealUser = realUser;
                  });
                },
                backgroundColor: _cardBg,
                selectedItemColor: _gold,
                unselectedItemColor: _subtext,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
                items: [
                  const BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore_rounded), label: 'Discover'),
                  const BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), activeIcon: Icon(Icons.grid_view_rounded), label: 'Products'),
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
                    color: _textDark,
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
  Alignment imgAlignment,
});

class _PromoBannerCard extends StatelessWidget {
  final _PromoBannerData banner;
  final VoidCallback? onTap;
  const _PromoBannerCard({super.key, required this.banner, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 235,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Background image with custom alignment so model head & tee options are perfectly centered and framed
            Positioned.fill(
              child: Image.asset(
                banner.img,
                fit: BoxFit.cover,
                alignment: banner.imgAlignment,
              ),
            ),

          // Soft bottom shadow for button visibility
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withAlpha(140),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Only CTA Option Button at the bottom
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _goldDark,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    banner.cta,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

// Typedef alias so SliverWidget compiles without issue
typedef SliverWidget = Widget;
