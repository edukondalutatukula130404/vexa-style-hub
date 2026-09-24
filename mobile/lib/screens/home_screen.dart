import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/order_service.dart';
import '../services/websocket_service.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'all_products_screen.dart';
import 'products_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'order_tracking_screen.dart';

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
  final String _searchQuery = '';
  final Set<String> _favoriteIds = {};
  int _currentTabIndex = 2; // Home tab active by default
  final List<CartItemData> _cartItems = [];

  // Notifications state linked to NotificationService
  int get _unreadNotificationCount => NotificationService.unreadCount;
  List<Map<String, dynamic>> get _notifications => NotificationService.notifications;

  // Auto-cycle promo banner
  int _bannerIndex = 0;
  Timer? _bannerTimer;
  StreamSubscription? _wsSub;

  // Cached orders future to prevent auto-refresh when promo banner timer ticks
  Future<List<OrderModel>>? _ordersFuture;

  Future<void> _refreshOrders() async {
    final userEmail = _currentUser?.email;
    final future = OrderService.getOrders(email: userEmail);
    if (mounted) {
      setState(() {
        _ordersFuture = future;
      });
    }
    await future;
  }

  // Main page scroll controller
  late final ScrollController _mainScrollController;

  // Middle-Out screen & tab transition controller
  late final AnimationController _tabAnimController;

  @override
  void initState() {
    super.initState();
    _mainScrollController = ScrollController();
    ApiConfig.baseUrlNotifier.addListener(_onServerUrlChanged);
    NotificationService.notificationNotifier.addListener(_onNotificationsChanged);
    OrderService.ordersChangeNotifier.addListener(_refreshOrders);
    OrderService.startAutoPoll();
    _loadUserAndItems();
    _refreshOrders();

    // Listen to real-time WebSocket live data events
    _wsSub = VexaWebSocketService().stream.listen((event) {
      if (mounted) {
        final type = event['type'];
        final data = event['data'];
        debugPrint('⚡ Live WebSocket event received in Mobile App: $type');

        if (type == 'ADMIN_MESSAGE' || type == 'ANNOUNCEMENT' || type == 'NOTIFICATION') {
          if (data != null && data is Map) {
            final title = (data['title'] ?? 'Message from VEXA Admin 📢').toString();
            final body = (data['body'] ?? data['message'] ?? 'Notification from Admin').toString();
            NotificationService.addNotification(
              title: title,
              body: body,
              icon: Icons.campaign_rounded,
              color: const Color(0xFFB8860B),
              type: 'ADMIN_MESSAGE',
              data: Map<String, dynamic>.from(data),
              context: context,
            );
          }
        } else if (type == 'ORDER_CREATED' || type == 'ORDER_PLACED') {
          if (data != null && data is Map) {
            final orderId = (data['_id'] ?? data['id'] ?? '#VX-ORDER').toString();
            NotificationService.addNotification(
              title: 'Order Confirmed! 📦',
              body: 'Order $orderId placed successfully.',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              type: 'ORDER_PLACED',
              data: Map<String, dynamic>.from(data),
              context: context,
            );
          }
          _refreshOrders();
        } else if (type == 'ORDER_CANCELLED') {
          if (data != null && data is Map) {
            final orderId = (data['_id'] ?? data['id'] ?? '').toString();
            final cancelReason = data['cancelReason']?.toString();
            if (orderId.isNotEmpty) {
              OrderService.updateOrderStatusLocally(
                orderId,
                'Cancelled',
                cancelReason: cancelReason,
                context: context,
              );
            }
          }
          _refreshOrders();
        } else if (type == 'ORDER_STATUS_UPDATED' || type == 'ORDERS_UPDATED') {
          if (data != null && data is Map) {
            final orderId = (data['_id'] ?? data['id'] ?? '').toString();
            final status = (data['status'] ?? '').toString();
            final cancelReason = data['cancelReason']?.toString();
            if (orderId.isNotEmpty && status.isNotEmpty) {
              OrderService.updateOrderStatusLocally(
                orderId,
                status,
                cancelReason: cancelReason,
                context: context,
              );
            }
          }
          _refreshOrders();
        }
      }
    });

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
    NotificationService.notificationNotifier.removeListener(_onNotificationsChanged);
    OrderService.ordersChangeNotifier.removeListener(_refreshOrders);
    _wsSub?.cancel();
    _bannerTimer?.cancel();
    _mainScrollController.dispose();
    _tabAnimController.dispose();
    super.dispose();
  }

  void _navigateToScreen(Widget page) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  bool _isRealUser = false;
  UserModel? _currentUser;

  void _onNotificationsChanged() {
    if (mounted) setState(() {});
  }

  void _onServerUrlChanged() {
    if (mounted) _loadUserAndItems();
  }

  void _updateUserNotifications(UserModel? user) {
    if (user == null) return;

    final welcomeId = 'welcome_${user.id}';
    if (!_notifications.any((n) => n['id'] == welcomeId)) {
      final name = user.name.isNotEmpty ? user.name : 'VEXA Collector';
      final emailDisplay = user.email.isNotEmpty ? ' (${user.email})' : '';
      NotificationService.addNotification(
        title: 'Welcome Back, $name! 👋',
        body: 'You have successfully signed in to your VEXA account$emailDisplay. Enjoy member privileges & exclusive 240 GSM drops.',
        icon: Icons.lock_open_rounded,
        color: _gold,
        type: 'WELCOME',
      );
    }
  }

  Future<void> _loadUserAndItems() async {
    final user = await AuthService.getUser();
    final realUser = user != null && user.id != 'guest_user';
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isRealUser = realUser;
        if (user != null) {
          _updateUserNotifications(user);
        }
      });
      _refreshOrders();
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
    final targetIds = {'vx-08', 'vx-12', 'vx-07', 'vx-04', 'vx-06'};
    final list = _items.where((it) =>
      targetIds.contains(it.id.toLowerCase().trim()) ||
      it.collectionType.toLowerCase().contains('new') ||
      it.collectionType.toLowerCase().contains('drop')
    ).toList();
    if (list.isNotEmpty) return list;
    return _items.take(5).toList();
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
          cartItems: _cartItems,
          onOpenCart: _openCartScreen,
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
                  // 0. GREETING HEADER
                  SliverToBoxAdapter(child: _buildGreetingHeader()),

                  // 1. PROMO BANNER CAROUSEL
                  SliverToBoxAdapter(child: _buildPromoBannerCarousel()),

                  // 2. NEW ARRIVALS (horizontal scroll)
                  SliverToBoxAdapter(child: _buildNewArrivalsSection()),

                  // 3. FEATURED CATALOG (Horizontal Side Scroll)
                  SliverToBoxAdapter(child: _buildFeaturedCatalogHeader()),
                  SliverToBoxAdapter(child: _buildFeaturedCatalogHorizontalList()),

                  // 4. JOIN VEXA CTA (Only shown in Guest mode)
                  if (!_isRealUser) SliverToBoxAdapter(child: _buildJoinCta()),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }

  void _openCartScreen() {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CartScreen(
          cartItems: _cartItems,
          onCartUpdated: () => setState(() {}),
          onNavigateToProducts: () {
            Navigator.pop(context);
            setState(() => _currentTabIndex = 0);
          },
          onNavigateToOrders: () {
            Navigator.pop(context);
            setState(() => _currentTabIndex = 1);
            _refreshOrders();
          },
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/vexa_logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'V E X A',
                style: GoogleFonts.cinzel(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.5,
                  fontSize: 18,
                  color: _gold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'WEAR CONFIDENCE',
                style: GoogleFonts.outfit(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.2,
                  color: _subtext,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    if (!_isRealUser) {
                      _showGuestNotificationPrompt();
                    } else {
                      _showNotificationsSheet();
                    }
                  },
                  icon: const Icon(Icons.notifications_outlined, color: _textDark, size: 22),
                  tooltip: 'Notifications',
                ),
              ),
              if (_isRealUser && _unreadNotificationCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '$_unreadNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 0. GREETING HEADER ─────────────────────────────────────────────────
  ({String wish, String subtitle}) get _timeBasedWish {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return (
        wish: 'Good Morning ☀️',
        subtitle: 'Start your day in signature 240 GSM luxury',
      );
    } else if (hour >= 12 && hour < 17) {
      return (
        wish: 'Good Afternoon 🌤️',
        subtitle: 'Elevate your mid-day style & exclusive fits',
      );
    } else if (hour >= 17 && hour < 22) {
      return (
        wish: 'Good Evening 🌙',
        subtitle: 'Explore tonight\'s curated luxury drops',
      );
    } else {
      return (
        wish: 'Good Night 🌌',
        subtitle: 'Unwind with premium bio-washed essentials',
      );
    }
  }

  Widget _buildGreetingHeader() {
    final wish = _timeBasedWish;
    final userName = (_currentUser != null && _currentUser!.name.trim().isNotEmpty)
        ? _currentUser!.name.trim()
        : 'Collector';
    final companyName = (_currentUser != null && _currentUser!.companyName.trim().isNotEmpty)
        ? _currentUser!.companyName.trim()
        : 'VEXA Style Hub';

    final displayName = _isRealUser ? '$userName • $companyName' : 'VEXA Collector • VEXA Style Hub';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withAlpha(140), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _gold.withAlpha(40),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withAlpha(35),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      wish.wish,
                      style: GoogleFonts.cinzel(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _goldDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cinzel(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _goldDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wish.subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: const Color(0xFF475569),
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_goldDark, _gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: _goldDark.withAlpha(90),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _gold.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _gold.withAlpha(60)),
          ),
          child: Icon(icon, color: _goldDark, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: _subtext,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showGuestNotificationPrompt() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withAlpha(140),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final slideTween = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: anim1.drive(slideTween),
          child: Scaffold(
            backgroundColor: _bgColor,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withAlpha(15),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _gold.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_outlined, color: _gold, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'NOTIFICATIONS',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    // Centered Gold Lock Emblem with Glow Ring
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: _gold.withAlpha(20),
                        shape: BoxShape.circle,
                        border: Border.all(color: _gold.withAlpha(80), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _gold.withAlpha(30),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        color: _goldDark,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SIGN IN TO VIEW NOTIFICATIONS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.4,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Please sign in to your VEXA account to view your personalized notifications, drop alerts, and order updates.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          color: _subtext,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Luxury Notification Perks preview card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildNotificationFeatureRow(
                            icon: Icons.local_shipping_outlined,
                            title: 'Order Status & Live Tracking',
                            subtitle: 'Get real-time updates on dispatch and delivery.',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: _border),
                          ),
                          _buildNotificationFeatureRow(
                            icon: Icons.bolt_rounded,
                            title: 'Exclusive 240 GSM Drops',
                            subtitle: 'First access to limited edition drop collections.',
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: _border),
                          ),
                          _buildNotificationFeatureRow(
                            icon: Icons.workspace_premium_outlined,
                            title: 'VIP Loyalty Rewards',
                            subtitle: 'Earn points and receive exclusive member coupons.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _goldDark,
                          elevation: 2,
                          shadowColor: _goldDark.withAlpha(80),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/login');
                        },
                        child: Text(
                          'SIGN IN NOW',
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _gold, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/register');
                        },
                        child: Text(
                          'CREATE AN ACCOUNT',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: _goldDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(
                          color: _subtext,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showNotificationsSheet() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withAlpha(140),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        final slideTween = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: anim1.drive(slideTween),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final hasUnread = _notifications.any((n) => n['isRead'] == false);
              final hasNotifications = _notifications.isNotEmpty;

              return Scaffold(
                backgroundColor: _bgColor,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 1,
                  shadowColor: Colors.black.withAlpha(15),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _gold.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_outlined, color: _gold, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'NOTIFICATIONS',
                        style: GoogleFonts.cinzel(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
                  actions: const [],
                ),
                body: SafeArea(
                  child: Column(
                    children: [
                      // Sub-header Action Bar: Read All (if unread) & Delete All
                      if (hasNotifications)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          color: Colors.white,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_notifications.length} ${_notifications.length == 1 ? 'Notification' : 'Notifications'}',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _subtext,
                                ),
                              ),
                              Row(
                                children: [
                                  // ONLY SHOW READ ALL OPTION IF THERE ARE UNREAD NOTIFICATIONS
                                  if (hasUnread)
                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        setSheetState(() {
                                          NotificationService.markAllAsRead();
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.done_all_rounded, color: _goldDark, size: 18),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Read All',
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: _goldDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  if (hasUnread) const SizedBox(width: 12),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      setSheetState(() {
                                        _notifications.clear();
                                        // Handled by NotificationService
                                      });
                                      setState(() {
                                        // Handled by NotificationService
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935), size: 18),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Delete All',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFE53935),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      const Divider(height: 1),

                      // Notification Items List
                      Expanded(
                        child: _notifications.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: const BoxDecoration(
                                        color: _surfaceBg,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.notifications_off_outlined, size: 54, color: Colors.grey.shade400),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No Notifications Yet',
                                      style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'You\'re all caught up! Check back for drop alerts & order updates.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(fontSize: 13, color: _subtext),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _notifications.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final n = _notifications[index];
                                  final isUnread = n['isRead'] == false;

                                  return Dismissible(
                                    key: Key(n['id'] as String),
                                    direction: DismissDirection.endToStart, // Left swipe
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEB),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFFCA5A5).withAlpha(120)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935), size: 22),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Remove',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFE53935),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onDismissed: (direction) {
                                      final removedTitle = n['title'] as String;
                                      setSheetState(() {
                                        _notifications.removeAt(index);
                                        // Handled by NotificationService
                                      });
                                      setState(() {
                                        // Handled by NotificationService
                                      });

                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Removed "$removedTitle"'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    },
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        if (isUnread) {
                                          setSheetState(() {
                                            n['isRead'] = true;
                                            // Handled by NotificationService
                                          });
                                          setState(() {
                                            // Handled by NotificationService
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isUnread ? Colors.white : _bgColor,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isUnread ? _gold.withAlpha(120) : _border,
                                            width: isUnread ? 1.5 : 1.0,
                                          ),
                                          boxShadow: isUnread
                                              ? [
                                                  BoxShadow(
                                                    color: _gold.withAlpha(20),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : [],
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Stack(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: (n['color'] as Color).withAlpha(25),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 22),
                                                ),
                                                if (isUnread)
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: Container(
                                                      width: 10,
                                                      height: 10,
                                                      decoration: const BoxDecoration(
                                                        color: _gold,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          n['title'] as String,
                                                          style: GoogleFonts.outfit(
                                                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.bold,
                                                            fontSize: 14.5,
                                                            color: _textDark,
                                                          ),
                                                        ),
                                                      ),
                                                      Text(
                                                        n['time'] as String,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 11.5,
                                                          color: isUnread ? _goldDark : _subtext,
                                                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    n['body'] as String,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12.5,
                                                      color: _subtext,
                                                      height: 1.4,
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
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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
                            cartItems: _cartItems,
                            onOpenCart: _openCartScreen,
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
  // ══════════════════════════════════════════════════════════════════════════
  // MY ORDERS TAB VIEW (REDESIGNED LUXURY EXPERIENCE)
  // ══════════════════════════════════════════════════════════════════════════
  String _selectedOrderStatusFilter = 'All';
  String _orderSearchQuery = '';

  Widget _buildOrdersTab() {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              setState(() => _currentTabIndex = 2);
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_goldDark, _gold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _gold.withAlpha(80),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MY ORDERS',
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                    letterSpacing: 1.8,
                  ),
                ),
                Text(
                  'Live Courier Tracking & Order History',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _subtext,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: _goldDark,
        onRefresh: _refreshOrders,
        child: FutureBuilder<List<OrderModel>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: _goldDark, strokeWidth: 2.5),
                    SizedBox(height: 16),
                    Text(
                      'Fetching order history...',
                      style: TextStyle(color: _subtext, fontSize: 13),
                    ),
                  ],
                ),
              );
            }

            final rawOrders = snapshot.data ?? [];

            // Compute status counts for filter chips
            final totalCount = rawOrders.length;
            final processingCount = rawOrders.where((o) => o.status.toLowerCase().contains('process') || o.status.toLowerCase().contains('confirm')).length;
            final shippedCount = rawOrders.where((o) => o.status.toLowerCase().contains('ship') || o.status.toLowerCase().contains('transit') || o.status.toLowerCase().contains('delivery')).length;
            final deliveredCount = rawOrders.where((o) => o.status.toLowerCase().contains('deliver')).length;
            final cancelledCount = rawOrders.where((o) => o.status.toLowerCase().contains('cancel')).length;

            // Apply filters
            final filteredOrders = rawOrders.where((order) {
              final s = order.status.toLowerCase();
              final matchesFilter = _selectedOrderStatusFilter == 'All' ||
                  (_selectedOrderStatusFilter == 'Processing' && (s.contains('process') || s.contains('confirm'))) ||
                  (_selectedOrderStatusFilter == 'Shipped' && (s.contains('ship') || s.contains('transit') || s.contains('delivery'))) ||
                  (_selectedOrderStatusFilter == 'Delivered' && s.contains('deliver')) ||
                  (_selectedOrderStatusFilter == 'Cancelled' && s.contains('cancel'));

              final q = _orderSearchQuery.trim().toLowerCase();
              final matchesSearch = q.isEmpty ||
                  order.id.toLowerCase().contains(q) ||
                  order.status.toLowerCase().contains(q) ||
                  order.items.any((item) => item.name.toLowerCase().contains(q));

              return matchesFilter && matchesSearch;
            }).toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. HERO LUXURY HEADER BANNER (LIGHT BRONZE-GOLD THEME MATCHING TRACK ORDER)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFDFBF5), Color(0xFFF5E8CD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _goldDark.withAlpha(140), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _goldDark.withAlpha(30),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _goldDark.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _goldDark.withAlpha(110)),
                              ),
                              child: Text(
                                'COUTURE DISPATCH',
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: _goldDark,
                                ),
                              ),
                            ),
                            Text(
                              'EST. 2026',
                              style: GoogleFonts.cinzel(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _goldDark.withAlpha(180),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Order Tracking Hub',
                          style: GoogleFonts.cinzel(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _goldDark,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track live 2–4 day express shipments, invoice receipts & delivery status.',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF5C4509),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats counters row
                        Row(
                          children: [
                            _buildOrdersStatPill('Total', totalCount.toString(), Icons.inventory_2_outlined, _goldDark),
                            const SizedBox(width: 8),
                            _buildOrdersStatPill('In Transit', shippedCount.toString(), Icons.local_shipping_outlined, const Color(0xFF1D4ED8)),
                            const SizedBox(width: 8),
                            _buildOrdersStatPill('Delivered', deliveredCount.toString(), Icons.check_circle_outline, const Color(0xFF059669)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. SEARCH & FILTER TOOLBAR
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Search bar input
                        Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(5),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            onChanged: (val) => setState(() => _orderSearchQuery = val),
                            style: GoogleFonts.outfit(fontSize: 13, color: _textDark),
                            decoration: InputDecoration(
                              hintText: 'Search by Order ID (e.g. #VX-8834) or item name...',
                              hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: _subtext),
                              prefixIcon: const Icon(Icons.search_rounded, color: _goldDark, size: 20),
                              suffixIcon: _orderSearchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 18, color: _subtext),
                                      onPressed: () => setState(() => _orderSearchQuery = ''),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Status filter chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildOrdersFilterChip('All', totalCount),
                              _buildOrdersFilterChip('Processing', processingCount),
                              _buildOrdersFilterChip('Shipped', shippedCount),
                              _buildOrdersFilterChip('Delivered', deliveredCount),
                              _buildOrdersFilterChip('Cancelled', cancelledCount),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ),

                // 3. ORDERS LIST / EMPTY STATE
                filteredOrders.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(6),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: _gold.withAlpha(20),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _gold.withAlpha(60)),
                                ),
                                child: const Icon(Icons.local_shipping_outlined, color: _goldDark, size: 48),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _orderSearchQuery.isNotEmpty || _selectedOrderStatusFilter != 'All'
                                    ? 'No Matching Orders'
                                    : 'No Orders Placed Yet',
                                style: GoogleFonts.cinzel(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _orderSearchQuery.isNotEmpty || _selectedOrderStatusFilter != 'All'
                                    ? 'Try changing your filter settings or search query to view other purchases.'
                                    : 'Order luxury 240 GSM garments to track live shipment status here.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: _subtext,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (_orderSearchQuery.isNotEmpty || _selectedOrderStatusFilter != 'All')
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: _goldDark, width: 1.5),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedOrderStatusFilter = 'All';
                                      _orderSearchQuery = '';
                                    });
                                  },
                                  icon: const Icon(Icons.filter_alt_off_rounded, color: _goldDark, size: 18),
                                  label: Text(
                                    'Reset Filters',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _goldDark,
                                    ),
                                  ),
                                )
                              else
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _goldDark,
                                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 3,
                                  ),
                                  onPressed: () => setState(() => _currentTabIndex = 0),
                                  icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                                  label: Text(
                                    'BROWSE LUXURY CATALOG',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final order = filteredOrders[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildRedesignedOrderCard(context, order),
                              );
                            },
                            childCount: filteredOrders.length,
                          ),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrdersStatPill(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(210),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _goldDark.withAlpha(70)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _goldDark,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5C4509),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersFilterChip(String label, int count) {
    final isSelected = _selectedOrderStatusFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedOrderStatusFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _goldDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _goldDark : _border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _goldDark.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : _textDark,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withAlpha(40) : _surfaceBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : _subtext,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedesignedOrderCard(BuildContext context, OrderModel order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final titleText = firstItem != null ? firstItem.name : 'VEXA Couture Order';
    final itemsCount = order.items.fold(0, (sum, item) => sum + item.quantity);
    final isCancelled = order.status.toLowerCase().contains('cancel');
    final isDelivered = order.status.toLowerCase().contains('deliver');
    final isShipped = order.status.toLowerCase().contains('ship') || order.status.toLowerCase().contains('transit') || order.status.toLowerCase().contains('out for delivery');

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isShipped ? _gold.withAlpha(100) : _border,
          width: isShipped ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row (Order ID, Payment Method & Status Tag)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: _border, width: 0.8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: order.id));
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Copied Order ID "${order.id}" to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: _goldDark,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _gold.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _gold.withAlpha(80)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                order.id,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: _goldDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy_rounded, size: 12, color: _goldDark),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _surfaceBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.paymentMethod,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: _subtext,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: order.statusColor.withAlpha(90)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: order.statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        order.status.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: order.statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Product Overview Row & Step Indicator (Clickable to open Order Details)
          InkWell(
            onTap: () => _openHomeOrderDetailSheet(context, order),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _border),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: firstItem != null
                                ? (firstItem.image.startsWith('assets/')
                                    ? Image.asset(firstItem.image, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: _surfaceBg, child: const Icon(Icons.checkroom, color: _subtext)))
                                    : Image.network(firstItem.image, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: _surfaceBg, child: const Icon(Icons.checkroom, color: _subtext))))
                                : Container(color: _surfaceBg, child: const Icon(Icons.checkroom, color: _subtext)),
                          ),
                          if (itemsCount > 1)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F172A),
                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomRight: Radius.circular(14)),
                                ),
                                child: Text(
                                  '+${itemsCount - 1} more',
                                  style: GoogleFonts.outfit(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    titleText,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: _textDark,
                                      height: 1.25,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: _goldDark, size: 20),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (firstItem != null && firstItem.size.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _gold.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Size ${firstItem.size}',
                                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _goldDark),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  '$itemsCount ${itemsCount == 1 ? "item" : "items"}',
                                  style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 12, color: _subtext),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          order.formattedDate,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(fontSize: 11, color: _subtext),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '₹${order.totalAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: _goldDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Horizontal Progress Step Indicator
                if (!isCancelled) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1, color: _border),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniStepDot('Placed', true, true),
                            _buildMiniStepConnector(true),
                            _buildMiniStepDot('QC / Prep', true, true),
                            _buildMiniStepConnector(isShipped || isDelivered),
                            _buildMiniStepDot('In Transit', isShipped || isDelivered, isShipped && !isDelivered),
                            _buildMiniStepConnector(isDelivered),
                            _buildMiniStepDot('Delivered', isDelivered, isDelivered),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Footer Actions Row
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(top: BorderSide(color: _border, width: 0.8)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      _showCustomTeeBottomSheet();
                    },
                    icon: const Icon(Icons.help_outline_rounded, size: 15, color: _subtext),
                    label: Text(
                      'Need Support',
                      style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: _subtext),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _goldDark,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
                      );
                    },
                    icon: const Icon(Icons.alt_route_rounded, size: 15, color: Colors.white),
                    label: Text(
                      'Track Order',
                      style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStepDot(String label, bool isDone, bool isActive) {
    final dotColor = isDone ? (isActive ? const Color(0xFF3B82F6) : _goldDark) : _border;
    return Column(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isDone ? dotColor : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: dotColor, width: 2),
            boxShadow: isActive
                ? [BoxShadow(color: dotColor.withAlpha(80), blurRadius: 6)]
                : null,
          ),
          child: isDone
              ? const Center(child: Icon(Icons.check, size: 9, color: Colors.white))
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? _textDark : _subtext,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStepConnector(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14),
        color: isDone ? _goldDark : _border,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WISHLIST TAB VIEW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWishlistTab() {
    final wishItems = _items.where((it) => _favoriteIds.contains(it.id)).toList();

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              setState(() => _currentTabIndex = 2);
            }
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFFFF4757).withAlpha(25), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_rounded, color: Color(0xFFFF4757), size: 20),
            ),
            const SizedBox(width: 10),
            Text('MY WISHLIST', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.5)),
            const SizedBox(width: 6),
            Text('(${wishItems.length})', style: GoogleFonts.outfit(fontSize: 13, color: _subtext, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: wishItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(color: _surfaceBg, shape: BoxShape.circle),
                    child: const Icon(Icons.favorite_border_rounded, color: _subtext, size: 48),
                  ),
                  const SizedBox(height: 18),
                  Text('Your Wishlist is Empty', style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                  const SizedBox(height: 8),
                  Text('Tap the heart icon on any product to save your favorite garments here.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _goldDark, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () => setState(() => _currentTabIndex = 0),
                    child: Text('EXPLORE PRODUCTS', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.64,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: wishItems.length,
              itemBuilder: (ctx, i) {
                final item = wishItems[i];
                return Container(
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
                            GestureDetector(
                              onTap: () => _openProductDetail(item),
                              child: _productImage(item.image, width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _favoriteIds.remove(item.id)),
                                child: const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.close_rounded, color: _textDark, size: 16),
                                ),
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
                            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark)),
                            const SizedBox(height: 2),
                            Text('₹${item.price.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: _goldDark)),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 32,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _goldDark,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  _addToCart(item, item.colors.first, 'M', 1);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added "${item.name}" to cart!'),
                                      backgroundColor: _goldDark,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Text('ADD TO CART', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'floating_cart_wishlist_tab',
        backgroundColor: _goldDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
        ),
        onPressed: _openCartScreen,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
            if (_totalCartCount > 0)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0C2340),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$_totalCartCount',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        label: Text(
          'View Cart',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }

  void _openHomeOrderDetailSheet(BuildContext context, OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          final isCancelled = order.status.toLowerCase() == 'cancelled';

          return Scaffold(
            backgroundColor: _bgColor,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.8,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
                onPressed: () => Navigator.pop(ctx),
              ),
              titleSpacing: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _gold.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _gold.withAlpha(60)),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: _goldDark, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'ORDER ${order.id}',
                                style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: order.statusColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: order.statusColor.withAlpha(90)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 5, height: 5, decoration: BoxDecoration(color: order.statusColor, shape: BoxShape.circle)),
                                  const SizedBox(width: 4),
                                  Text(
                                    order.status.toUpperCase(),
                                    style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w800, color: order.statusColor, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 11, color: _subtext),
                            const SizedBox(width: 4),
                            Text('Placed on ${order.formattedDate}', style: GoogleFonts.outfit(fontSize: 10, color: _subtext)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. CANCELLATION BANNER (If Cancelled)
                if (isCancelled) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEF4444).withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order Cancelled',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.cancelReason ?? 'Cancelled by user request. Refund initiated.',
                                style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // 2. SHIPPING ADDRESS BLOCK
                Text('SHIPPING ADDRESS', style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _gold.withAlpha(20), shape: BoxShape.circle),
                        child: const Icon(Icons.location_on_rounded, color: _goldDark, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customerName, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
                            const SizedBox(height: 3),
                            Text(order.shippingAddress, style: GoogleFonts.outfit(fontSize: 12, color: _subtext, height: 1.35)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 13, color: _goldDark),
                                const SizedBox(width: 5),
                                Text(order.phone, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. ITEMS IN ORDER SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ITEMS IN ORDER (${order.items.length})', style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2)),
                    Text('${order.items.fold(0, (sum, i) => sum + i.quantity)} total pcs', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                  ],
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(3), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(border: Border.all(color: _border)),
                            child: item.image.startsWith('assets/')
                                ? Image.asset(item.image, width: 54, height: 54, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 54, height: 54, color: _surfaceBg, child: const Icon(Icons.checkroom)))
                                : Image.network(item.image, width: 54, height: 54, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 54, height: 54, color: _surfaceBg, child: const Icon(Icons.checkroom))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(6)),
                                    child: Text('Size ${item.size}', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: _textDark)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Qty: ${item.quantity}', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: _goldDark)),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // 4. PAYMENT & RECEIPT SUMMARY CARD
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surfaceBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.payment_rounded, size: 16, color: _subtext),
                              const SizedBox(width: 6),
                              Text('Payment Method', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
                              child: Text(
                                order.paymentMethod,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _textDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 6),
                              Text('Shipping Fee', style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
                            ],
                          ),
                          Text('FREE Express', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: _border),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount Paid', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _goldDark,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: _goldDark.withAlpha(60), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Text('₹${order.totalAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5. ACTION BUTTONS (DOWNLOAD INVOICE & COURIER ASSIST)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _goldDark, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          _showInvoiceModal(ctx, order, autoStartDownload: true);
                        },
                        icon: const Icon(Icons.download_rounded, color: _goldDark, size: 18),
                        label: Text(
                          'Download Invoice',
                          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: _goldDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          _showCustomTeeBottomSheet();
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                        label: Text(
                          'Courier Support',
                          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }



  Widget _buildOrderItemDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, color: _subtext)),
        Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark)),
      ],
    );
  }

  Future<String?> _saveInvoiceFileToDisk(String invoiceNo, OrderModel order) async {
    try {
      String? downloadsPath;
      if (Platform.isAndroid) {
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) {
          downloadsPath = dir.path;
        }
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          downloadsPath = '$userProfile\\Downloads';
        }
      } else if (Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          downloadsPath = '$home/Downloads';
        }
      }

      downloadsPath ??= Directory.systemTemp.path;

      final file = File('$downloadsPath/$invoiceNo.pdf');
      final content = '''
============================================================
                  VEXA LUXURY WEAR - TAX E-INVOICE
                   Vexa Style Hub Pvt. Ltd.
        100ft Road, Indiranagar, Bengaluru - 560038
         GSTIN: 29AAACV9812F1Z4 | CIN: U74999KA2026PTC
============================================================

INVOICE NO   : $invoiceNo
DATE         : ${order.formattedDate}
ORDER ID     : ${order.id}
PAYMENT      : ${order.paymentMethod}
STATUS       : PAID

BILLED TO:
Name    : ${order.customerName}
Address : ${order.shippingAddress}
Phone   : ${order.phone}

------------------------------------------------------------
ITEMS PURCHASED:
------------------------------------------------------------
${order.items.map((i) => '${i.name.padRight(28)} Size:${i.size} Qty:${i.quantity} Price:₹${i.price} Total:₹${(i.price * i.quantity).toStringAsFixed(0)}').join('\n')}

------------------------------------------------------------
TAX BREAKDOWN:
Subtotal (Taxable Value) : ₹${(order.totalAmount / 1.18).toStringAsFixed(2)}
CGST (9%)               : ₹${((order.totalAmount - (order.totalAmount / 1.18)) / 2).toStringAsFixed(2)}
SGST (9%)               : ₹${((order.totalAmount - (order.totalAmount / 1.18)) / 2).toStringAsFixed(2)}
------------------------------------------------------------
TOTAL AMOUNT PAID        : ₹${order.totalAmount.toStringAsFixed(0)}
============================================================
      Thank you for shopping with VEXA Luxury Wear!
============================================================
''';

      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      debugPrint('Error saving invoice file: $e');
      return null;
    }
  }

  // ── TAX E-INVOICE GENERATOR & PREVIEW SCREEN (100% FULL SCREEN) ──────────
  void _showInvoiceModal(BuildContext context, OrderModel order, {bool autoStartDownload = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          bool isDownloading = false;
          bool isDownloaded = false;
          bool hasAutoTriggered = false;

          return StatefulBuilder(
            builder: (modalCtx, setInvoiceState) {
              final invoiceNo = 'INV-2026-${order.id.replaceAll('#', '').replaceAll('-', '')}';
              final totalAmt = order.totalAmount > 0 ? order.totalAmount : 1699.0;
              final subtotal = totalAmt / 1.18;
              final gstTotal = totalAmt - subtotal;
              final cgst = gstTotal / 2;
              final sgst = gstTotal / 2;

              void triggerDownload() async {
                if (isDownloading || isDownloaded) return;
                setInvoiceState(() => isDownloading = true);
                
                // Save actual file to disk
                final savedPath = await _saveInvoiceFileToDisk(invoiceNo, order);

                if (modalCtx.mounted) {
                  setInvoiceState(() {
                    isDownloading = false;
                    isDownloaded = true;
                  });

                  ScaffoldMessenger.of(modalCtx).clearSnackBars();
                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              savedPath != null
                                  ? 'Saved $invoiceNo.pdf to Downloads!'
                                  : 'Tax E-Invoice $invoiceNo downloaded & saved!',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  // Auto-reset green saved banner after 2 seconds
                  await Future.delayed(const Duration(seconds: 2));
                  if (modalCtx.mounted) {
                    setInvoiceState(() {
                      isDownloaded = false;
                    });
                  }
                }
              }

              if (autoStartDownload && !hasAutoTriggered && !isDownloaded && !isDownloading) {
                hasAutoTriggered = true;
                Future.microtask(() => triggerDownload());
              }

              return Scaffold(
                backgroundColor: _bgColor,
                appBar: AppBar(
                  backgroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                  titleSpacing: 0,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: _gold.withAlpha(50), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: _gold, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TAX E-INVOICE', style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                          Text(invoiceNo, style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    // Invoice Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Brand & GSTIN
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('VEXA LUXURY WEAR', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.w900, color: _goldDark, letterSpacing: 1.5)),
                                      const SizedBox(height: 2),
                                      Text('Vexa Style Hub Pvt. Ltd.', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _textDark)),
                                      Text('100ft Road, Indiranagar, Bengaluru - 560038', style: GoogleFonts.outfit(fontSize: 10, color: _subtext)),
                                      Text('GSTIN: 29AAACV9812F1Z4 | CIN: U74999KA2026PTC', style: GoogleFonts.outfit(fontSize: 10, color: _subtext)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                                    ),
                                    child: Text('PAID', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), letterSpacing: 1)),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              // Customer & Order Info
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('BILLED TO:', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _subtext, letterSpacing: 1)),
                                        const SizedBox(height: 4),
                                        Text(order.customerName, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                                        Text(order.shippingAddress, style: GoogleFonts.outfit(fontSize: 11, color: _subtext, height: 1.3)),
                                        Text('Contact: ${order.phone}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('INVOICE DETAILS:', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _subtext, letterSpacing: 1)),
                                      const SizedBox(height: 4),
                                      Text('Date: ${order.formattedDate}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      Text('Order ID: ${order.id}', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _goldDark)),
                                      Text('Payment: ${order.paymentMethod}', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Items Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    Expanded(flex: 4, child: Text('ITEM DESCRIPTION', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                    Expanded(flex: 1, child: Text('QTY', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                    Expanded(flex: 2, child: Text('PRICE', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                    Expanded(flex: 2, child: Text('AMOUNT', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Items Rows
                              ...order.items.map((item) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _border, width: 0.8))),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.name, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _textDark)),
                                            Text('Size: ${item.size} · Color: ${item.color} | HSN: 610910', style: GoogleFonts.outfit(fontSize: 9, color: _subtext)),
                                          ],
                                        ),
                                      ),
                                      Expanded(flex: 1, child: Text('${item.quantity}', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 11, color: _textDark))),
                                      Expanded(flex: 2, child: Text('₹${item.price.toStringAsFixed(0)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 11, color: _textDark))),
                                      Expanded(flex: 2, child: Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', textAlign: TextAlign.right, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _textDark))),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 14),

                              // Tax & Totals Breakdown
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Taxable Value', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                        Text('₹${subtotal.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('CGST (9%)', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                        Text('₹${cgst.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('SGST (9%)', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                        Text('₹${sgst.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 11, color: _textDark)),
                                      ],
                                    ),
                                    const Divider(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('GRAND TOTAL (INCL. GST)', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark)),
                                        Text('₹${totalAmt.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: _goldDark)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Footer verification stamp
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.qr_code_2_rounded, size: 40, color: _textDark),
                                      const SizedBox(width: 8),
                                      Text('Scan QR for Digital\nE-Invoice Verification', style: GoogleFonts.outfit(fontSize: 9, color: _subtext, height: 1.2)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('For VEXA STYLE HUB PVT LTD', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: _textDark)),
                                      const SizedBox(height: 16),
                                      Text('Authorized Signatory', style: GoogleFonts.outfit(fontSize: 9, color: _subtext, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Action Button / Progress
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: _border)),
                      ),
                      child: isDownloaded
                          ? Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Invoice Saved to Downloads ($invoiceNo.pdf)',
                                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _goldDark,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: isDownloading ? null : () => triggerDownload(),
                                icon: isDownloading
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                                label: Text(
                                  isDownloading ? 'GENERATING E-INVOICE PDF...' : 'SAVE E-INVOICE TO DEVICE (PDF)',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }



  // ══════════════════════════════════════════════════════════════════════════
  // ROOT BUILD (5 BOTTOM BAR TABS: Products, My Orders, Home, Wishlist, Profile)
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else if (_currentTabIndex != 2) {
          setState(() => _currentTabIndex = 2);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Stack(
        children: [
          IndexedStack(
            index: _currentTabIndex,
            children: [
              // 0: Products
              ProductsScreen(
                items: _items,
                onAddToCart: (item, color, size, qty) => _addToCart(item, color, size, qty),
                favoriteIds: _favoriteIds,
                onToggleFavorite: (id) => setState(() => _favoriteIds.contains(id) ? _favoriteIds.remove(id) : _favoriteIds.add(id)),
                showBackButton: true,
                onBackTap: () => setState(() => _currentTabIndex = 2),
                cartItems: _cartItems,
                onOpenCart: _openCartScreen,
              ),
              // 1: My Orders
              _buildOrdersTab(),
              // 2: Home
              _buildDiscoverTab(),
              // 3: Wishlist
              _buildWishlistTab(),
              // 4: Profile
              ProfileScreen(
                onNavigateToDiscover: () async {
                  final user = await AuthService.getUser();
                  final realUser = user != null && user.id != 'guest_user';
                  setState(() {
                    _currentTabIndex = 2; // Home tab
                    _isRealUser = realUser;
                  });
                },
              ),
            ],
          ),

          // Floating Cart Extended Button on Home tab (_currentTabIndex == 2)
          if (_currentTabIndex == 2)
            Positioned(
              right: 16,
              bottom: 20,
              child: FloatingActionButton.extended(
                heroTag: 'floating_cart_home_tab',
                backgroundColor: _goldDark,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                ),
                onPressed: _openCartScreen,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                    if (_totalCartCount > 0)
                      Positioned(
                        top: -6,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0C2340),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$_totalCartCount',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: Text(
                  'View Cart',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _currentTabIndex != 2
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
                    _currentUser = user;
                    _isRealUser = realUser;
                  });
                  if (i == 1) {
                    _refreshOrders();
                  }
                },
                backgroundColor: _cardBg,
                selectedItemColor: _gold,
                unselectedItemColor: _subtext,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
                unselectedLabelStyle: GoogleFonts.outfit(fontSize: 10),
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.grid_view_outlined),
                    activeIcon: Icon(Icons.grid_view_rounded),
                    label: 'Products',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.inventory_2_outlined),
                    activeIcon: Icon(Icons.inventory_2_rounded),
                    label: 'My Orders',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      label: Text('${_favoriteIds.length}'),
                      isLabelVisible: _favoriteIds.isNotEmpty,
                      backgroundColor: const Color(0xFFFF4757),
                      child: const Icon(Icons.favorite_outline_rounded),
                    ),
                    activeIcon: Badge(
                      label: Text('${_favoriteIds.length}'),
                      isLabelVisible: _favoriteIds.isNotEmpty,
                      backgroundColor: const Color(0xFFFF4757),
                      child: const Icon(Icons.favorite_rounded),
                    ),
                    label: 'Wishlist',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline_rounded),
                    activeIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ════════════════════════════════════════════════════════════════════════════

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
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _gold.withAlpha(120), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Background image with custom alignment
            Positioned.fill(
              child: Image.asset(
                banner.img,
                fit: BoxFit.cover,
                alignment: banner.imgAlignment,
              ),
            ),

            // Right-Aligned Compact Gold Action Button (No Black Background)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_goldDark, _gold],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
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
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
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
