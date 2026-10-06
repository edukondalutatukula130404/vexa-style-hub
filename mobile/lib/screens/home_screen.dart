import 'dart:async';
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
import 'order_details_screen.dart';
import 'customer_support_screen.dart';
import '../widgets/razorpay_gateway_modal.dart';
import '../services/invoice_pdf_service.dart';

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

  // Manual scroll promo showcase banner controller
  int _bannerIndex = 0;
  late final PageController _promoPageController;
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

  // Stream subscription for notification tap events
  StreamSubscription<String>? _notifTapSub;

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
    _notifTapSub = NotificationService.onNotificationTap.stream.listen((payload) {
      if (mounted) {
        _showNotificationsSheet();
      }
    });
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

    // Manual scroll promo showcase controller
    _promoPageController = PageController(initialPage: _bannerIndex);
  }

  @override
  void dispose() {
    ApiConfig.baseUrlNotifier.removeListener(_onServerUrlChanged);
    NotificationService.notificationNotifier.removeListener(_onNotificationsChanged);
    OrderService.ordersChangeNotifier.removeListener(_refreshOrders);
    _wsSub?.cancel();
    _notifTapSub?.cancel();
    _promoPageController.dispose();
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
        onOpenCart: _openCartScreen,
        favoriteIds: _favoriteIds,
        onToggleFavorite: (id) => setState(() => _favoriteIds.contains(id) ? _favoriteIds.remove(id) : _favoriteIds.add(id)),
      ),
    );
  }

  void _handleBannerTap(String cta) {
    // Banners are purely for display/showcase - do not open any screens on click
    return;
  }

  // ignore: unused_element
  void _showCustomTeeBottomSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final detailsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (ctx) {
        return SizedBox(
          width: double.infinity,
          height: MediaQuery.of(ctx).size.height,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 16,
              left: 24,
              right: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top close bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VEXA BESPOKE',
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _goldDark,
                        letterSpacing: 1.5,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: _textDark, size: 26),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: _border),
                const SizedBox(height: 20),

                // Scrollable content area taking 100% height
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BESPOKE CUSTOMISATION',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: _gold,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Book Your Custom Tee',
                          style: GoogleFonts.cinzel(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Personalized embroidery, custom colorways & bulk corporate/personal orders. Made to measure by VEXA master tailors.',
                          style: GoogleFonts.outfit(fontSize: 13, color: _subtext, height: 1.4),
                        ),
                        const SizedBox(height: 24),

                        // Input Fields
                        TextField(
                          controller: nameController,
                          style: GoogleFonts.outfit(color: _textDark),
                          decoration: InputDecoration(
                            labelText: 'Your Full Name',
                            labelStyle: GoogleFonts.outfit(color: _subtext),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: _gold),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _gold, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.outfit(color: _textDark),
                          decoration: InputDecoration(
                            labelText: 'Phone / WhatsApp Number',
                            labelStyle: GoogleFonts.outfit(color: _subtext),
                            prefixIcon: const Icon(Icons.phone_outlined, color: _gold),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _gold, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: detailsController,
                          maxLines: 4,
                          style: GoogleFonts.outfit(color: _textDark),
                          decoration: InputDecoration(
                            labelText: 'Customization Details (e.g. Custom embroidery text, fit type, color preference, quantity)',
                            labelStyle: GoogleFonts.outfit(color: _subtext),
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 50),
                              child: Icon(Icons.edit_note_rounded, color: _gold),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: _gold, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _goldDark,
                              elevation: 4,
                              shadowColor: _goldDark.withAlpha(100),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                            child: Text(
                              'Submit Custom Order Request',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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

                  // 4. HOW TO BOOK FLOW SECTION
                  SliverToBoxAdapter(child: _buildHowToBookFlowSection()),

                  // 5. JOIN VEXA CTA (Only shown in Guest mode)
                  if (!_isRealUser) SliverToBoxAdapter(child: _buildJoinCta()),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
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



  Widget _buildGreetingHeader() {
    String cleanText(String s) {
      String str = s.replaceAll(RegExp(r'vexa', caseSensitive: false), '')
                    .replaceAll(RegExp(r'\s+'), ' ')
                    .trim();
      final lower = str.toLowerCase();
      if (lower.contains('tatukulaedukondalu')) {
        str = str.replaceAll(RegExp(r'tatukulaedukondalu', caseSensitive: false), 'TATUKULA EDUKONDALU');
      } else if (lower.contains('tatukula') && lower.contains('edukondalu') && !lower.contains('tatukula edukondalu')) {
        str = str.replaceAll(RegExp(r'tatukula\s*edukondalu', caseSensitive: false), 'TATUKULA EDUKONDALU');
      } else {
        str = str.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
      }
      return str.trim();
    }

    final rawUser = (_currentUser != null && _currentUser!.name.trim().isNotEmpty)
        ? cleanText(_currentUser!.name)
        : 'Collector';

    final displayName = rawUser.isNotEmpty ? rawUser : 'Collector';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFDF2),
              Color(0xFFFFF4D1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5C158).withAlpha(160),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB8860B).withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _goldDark,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'WELCOME,',
                  style: GoogleFonts.cinzel(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: _goldDark,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              displayName.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textDark,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToBookFlowSection() {
    final steps = [
      (
        stepNum: '01',
        tag: 'STEP 01',
        title: 'Browse Catalog or Custom Request',
        subtitle: 'Explore 240 GSM luxury catalog drops or tap "Book Custom Tee" for bespoke tailored designs.',
        icon: Icons.grid_view_rounded,
      ),
      (
        stepNum: '02',
        tag: 'STEP 02',
        title: 'Choose Fit & Personalize',
        subtitle: 'Select long-staple cotton colorways, drop-shoulder sizes, or enter custom embroidery text.',
        icon: Icons.design_services_outlined,
      ),
      (
        stepNum: '03',
        tag: 'STEP 03',
        title: 'Instant Secure Checkout',
        subtitle: 'Complete order seamlessly using Razorpay, UPI, NetBanking, Credit Cards, or COD.',
        icon: Icons.lock_outline_rounded,
      ),
      (
        stepNum: '04',
        tag: 'STEP 04',
        title: 'Doorstep Luxury Delivery',
        subtitle: 'Track your shipment live from VEXA master tailors to your doorstep with luxury packaging.',
        icon: Icons.local_shipping_outlined,
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFDF5),
            Color(0xFFFFF4D8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE5C158).withAlpha(160),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB8860B).withAlpha(25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Header (Single Line Layout)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'HOW TO BOOK YOUR VEXA TEE',
              maxLines: 1,
              style: GoogleFonts.cinzel(
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
                color: _textDark,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '4 easy steps from catalog selection to custom doorstep delivery.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: _subtext,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),

          // 4 Step Cards (Light Theme Cards)
          Column(
            children: steps.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5C158).withAlpha(80),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Badge Circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4D1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withAlpha(100),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          item.icon,
                          color: _goldDark,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Description Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _gold.withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.tag,
                                  style: GoogleFonts.outfit(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: _goldDark,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.title,
                            style: GoogleFonts.outfit(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.subtitle,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: _subtext,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Radiant VEXA Gold Action CTA Button
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFBE89C),
                  Color(0xFFF2D370),
                  Color(0xFFE5BF4E),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withAlpha(200),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF2D370).withAlpha(100),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showCustomTeeBottomSheet,
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.edit_note_rounded,
                        color: Color(0xFF0F172A),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'BOOK A CUSTOM TEE NOW',
                        style: GoogleFonts.outfit(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
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
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> n) {
    if (n['isRead'] == false) {
      n['isRead'] = true;
      NotificationService.markAsRead(n['id'] as String);
      if (mounted) setState(() {});
    }

    _showNotificationDetailsModal(n);
  }

  void _showNotificationDetailsModal(Map<String, dynamic> n) {
    final title = (n['title'] ?? 'Notification').toString();
    final body = (n['body'] ?? '').toString();
    final time = (n['time'] ?? 'Just now').toString();
    final type = (n['type'] ?? '').toString();
    final data = n['data'] as Map<String, dynamic>?;
    final IconData icon = (n['icon'] is IconData) ? n['icon'] as IconData : Icons.notifications_active_rounded;
    final Color color = (n['color'] is Color) ? n['color'] as Color : _gold;

    // Extract reference information if present
    String? orderId;
    final orderMatch = RegExp(r'#VX-([A-Za-z0-9-]+)').firstMatch('$title $body');
    if (orderMatch != null) {
      orderId = orderMatch.group(1);
    } else if (data != null && (data['orderId'] != null || data['_id'] != null)) {
      orderId = (data['orderId'] ?? data['_id']).toString();
    }

    String? amount;
    final amountMatch = RegExp(r'₹\s*([0-9,]+)').firstMatch('$title $body');
    if (amountMatch != null) {
      amount = '₹${amountMatch.group(1)}';
    }

    String categoryText = 'NOTIFICATION';
    if (type.contains('ORDER') || title.toLowerCase().contains('order') || orderId != null) {
      categoryText = 'ORDER UPDATE';
    } else if (type.contains('DROP') || title.toLowerCase().contains('drop') || title.toLowerCase().contains('collection')) {
      categoryText = 'EXCLUSIVE DROP';
    } else if (title.toLowerCase().contains('welcome') || title.toLowerCase().contains('account')) {
      categoryText = 'ACCOUNT ALERT';
    } else if (title.toLowerCase().contains('point') || title.toLowerCase().contains('vip') || title.toLowerCase().contains('loyalty')) {
      categoryText = 'LOYALTY REWARDS';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (pageContext) {
          return Scaffold(
            backgroundColor: _bgColor,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withAlpha(15),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
                onPressed: () => Navigator.pop(pageContext),
              ),
              title: Text(
                'NOTIFICATION DETAILS',
                style: GoogleFonts.cinzel(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: _textDark,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 13, color: color),
                          const SizedBox(width: 5),
                          Text(
                            categoryText,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          // High-impact Icon Glow Avatar
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              shape: BoxShape.circle,
                              border: Border.all(color: color.withAlpha(90), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withAlpha(40),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(icon, color: color, size: 48),
                          ),
                          const SizedBox(height: 24),

                          // Large Notification Title
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Time Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _surfaceBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded, size: 14, color: _subtext),
                                const SizedBox(width: 6),
                                Text(
                                  time,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    color: _subtext,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Main Message Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(8),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'MESSAGE SUMMARY',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        color: _subtext,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  body,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    height: 1.6,
                                    color: const Color(0xFF334155),
                                  ),
                                ),
                                if (orderId != null || amount != null) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Divider(height: 1),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      if (orderId != null)
                                        Column(
                                          children: [
                                            Text(
                                              'ORDER REFERENCE',
                                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _subtext),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _surfaceBg,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '#VX-$orderId',
                                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark),
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (amount != null)
                                        Column(
                                          children: [
                                            Text(
                                              'ORDER TOTAL',
                                              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: _subtext),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              amount,
                                              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: _goldDark),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Additional VEXA Service Badge Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.withAlpha(12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: color.withAlpha(40)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.verified_user_outlined, color: color, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Verified VEXA System Alert',
                                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Official notification from your VEXA mobile account.',
                                        style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(pageContext); // Close full screen details

                              if (categoryText == 'ORDER UPDATE' || orderId != null) {
                                final targetOrder = OrderModel(
                                  id: orderId ?? '1726',
                                  customerName: 'Valued Customer',
                                  shippingAddress: 'Indiranagar 100ft Road, Bengaluru, Karnataka',
                                  phone: '+91 98765 43210',
                                  paymentMethod: 'VEXA Pay (Card)',
                                  totalAmount: amount != null ? (double.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1899.0) : 1899.0,
                                  status: title.toLowerCase().contains('dispatched') ? 'Out for Delivery' : 'Confirmed',
                                  createdAt: DateTime.now().subtract(const Duration(hours: 2)),
                                  items: [
                                    OrderItem(
                                      itemId: '1',
                                      name: 'Urban Silhouette 240 GSM Oversized Tee',
                                      price: amount != null ? (double.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1899.0) : 1899.0,
                                      quantity: 1,
                                      color: 'Obsidian Black',
                                      size: 'L',
                                      image: 'assets/images/hero_luxury_tshirt.png',
                                    ),
                                  ],
                                );

                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context); // Close notifications sheet
                                }
                                _navigateToScreen(OrderDetailsScreen(
                                  order: targetOrder,
                                  onRefreshParent: _refreshOrders,
                                ));
                              } else if (categoryText == 'EXCLUSIVE DROP') {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context); // Close notifications sheet
                                }
                                _navigateToScreen(AllProductsScreen(
                                  items: _items,
                                  favoriteIds: _favoriteIds,
                                  onToggleFavorite: (id) {
                                    setState(() {
                                      if (_favoriteIds.contains(id)) {
                                        _favoriteIds.remove(id);
                                      } else {
                                        _favoriteIds.add(id);
                                      }
                                    });
                                  },
                                  cartItems: _cartItems,
                                ));
                              } else if (categoryText == 'LOYALTY REWARDS' || categoryText == 'ACCOUNT ALERT') {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context); // Close notifications sheet
                                }
                                setState(() {
                                  _currentTabIndex = 4; // Navigate to Profile tab
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _textDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Text(
                              categoryText == 'ORDER UPDATE'
                                  ? 'VIEW ORDER DETAILS'
                                  : categoryText == 'EXCLUSIVE DROP'
                                      ? 'EXPLORE COLLECTION'
                                      : categoryText == 'LOYALTY REWARDS'
                                          ? 'VIEW REWARDS & POINTS'
                                          : 'OK, GOT IT',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
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
      ),
    );
  }

  void _showNotificationsSheet() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (context, animation, secondaryAnimation) => StatefulBuilder(
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
                                      setSheetState(() { n['isRead'] = true; }); _handleNotificationTap(n);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: isUnread ? Colors.white : _bgColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isUnread ? _gold.withAlpha(100) : _border,
                                          width: isUnread ? 1.2 : 1,
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
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn,
            )),
            child: child,
          );
        },
      ),
    );
  }

  // ── 4. PROMO BANNER CAROUSEL (MANUAL SCROLL SHOWCASE) ─────────────────
  Widget _buildPromoBannerCarousel() {
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
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _promoPageController,
              itemCount: _promoBanners.length,
              onPageChanged: (index) {
                setState(() {
                  _bannerIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final b = _promoBanners[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _PromoBannerCard(
                    banner: b,
                    onTap: () => _handleBannerTap(b.cta),
                  ),
                );
              },
            ),
          ),
          // Interactive manual dot indicators
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_promoBanners.length, (i) {
              return GestureDetector(
                onTap: () {
                  _promoPageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  width: i == _bannerIndex ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _bannerIndex ? _gold : _subtext.withAlpha(80),
                    borderRadius: BorderRadius.circular(4),
                  ),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View All', style: GoogleFonts.outfit(fontSize: 11, color: _gold, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: _gold),
                    ],
                  ),
                ),
              ),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 22),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              setState(() => _currentTabIndex = 2);
            }
          },
        ),
        title: Text(
          'My Orders',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFD4AF37),
        onRefresh: _refreshOrders,
        child: FutureBuilder<List<OrderModel>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2.5),
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

            // Apply filters
            final filteredOrders = rawOrders.where((order) {
              final s = order.status.toLowerCase();
              final matchesFilter = _selectedOrderStatusFilter == 'All' ||
                  (_selectedOrderStatusFilter == 'Processing' && (s.contains('process') || s.contains('confirm'))) ||
                  (_selectedOrderStatusFilter == 'Shipped' && (s.contains('ship') || s.contains('transit') || s.contains('out for delivery'))) ||
                  (_selectedOrderStatusFilter == 'Delivered' && (s == 'delivered' || (s.contains('deliver') && !s.contains('out for delivery')))) ||
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
                // 1. SEARCH BAR & SIDE-BY-SIDE FILTERS BUTTON
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: TextField(
                              onChanged: (val) => setState(() => _orderSearchQuery = val),
                              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF0F172A)),
                              decoration: InputDecoration(
                                hintText: 'Search your order here',
                                hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                                suffixIcon: _orderSearchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                                        onPressed: () => setState(() => _orderSearchQuery = ''),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        PopupMenuButton<String>(
                          initialValue: _selectedOrderStatusFilter,
                          onSelected: (val) => setState(() => _selectedOrderStatusFilter = val),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'All', child: Text('All Orders')),
                            const PopupMenuItem(value: 'Shipped', child: Text('Expected / Shipped')),
                            const PopupMenuItem(value: 'Delivered', child: Text('Delivered')),
                            const PopupMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                          ],
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune_rounded, color: Color(0xFF334155), size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Filters',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF334155),
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
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.local_shipping_outlined, color: Color(0xFFD4AF37), size: 48),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _orderSearchQuery.isNotEmpty || _selectedOrderStatusFilter != 'All'
                                    ? 'No Matching Orders'
                                    : 'No Orders Placed Yet',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _orderSearchQuery.isNotEmpty || _selectedOrderStatusFilter != 'All'
                                    ? 'Try changing your filter settings or search query to view other purchases.'
                                    : 'Order luxury garments to track live shipment status here.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: _subtext,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.only(bottom: 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final order = filteredOrders[index];
                              return _buildRedesignedOrderCard(context, order);
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



  Widget _buildRedesignedOrderCard(BuildContext context, OrderModel order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final status = order.status.toLowerCase();

    int stepIdx = 0;
    if (status.contains('cancel')) {
      stepIdx = -1;
    } else if (status.contains('deliver')) {
      stepIdx = 4;
    } else if (status.contains('out for delivery') || status.contains('courier')) {
      stepIdx = 3;
    } else if (status.contains('ship') || status.contains('transit')) {
      stepIdx = 2;
    } else if (status.contains('qc')) {
      stepIdx = 1;
    } else {
      final elapsedSeconds = DateTime.now().difference(order.createdAt).inSeconds;
      if (elapsedSeconds < 25) {
        stepIdx = 0;
      } else if (elapsedSeconds < 55) {
        stepIdx = 1;
      } else if (elapsedSeconds < 110) {
        stepIdx = 2;
      } else if (elapsedSeconds < 180) {
        stepIdx = 3;
      } else {
        stepIdx = 4;
      }
    }

    final isDelivered = stepIdx == 4 || status == 'delivered' || (status.contains('deliver') && !status.contains('out for delivery'));
    final isCancelled = stepIdx == -1 || status.contains('cancel');

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    // Format status header string (e.g., Delivered on Oct 06 / Delivery expected by Oct 09 / Cancelled on Dec 30)
    String headerText;
    if (isCancelled) {
      final m = months[order.createdAt.month - 1];
      final d = order.createdAt.day.toString().padLeft(2, '0');
      headerText = 'Cancelled on $m $d, ${order.createdAt.year}';
    } else if (isDelivered) {
      final delDate = order.createdAt.add(const Duration(days: 2));
      final delTime = delDate.isAfter(DateTime.now()) ? DateTime.now() : delDate;
      final m = months[delTime.month - 1];
      final d = delTime.day.toString().padLeft(2, '0');
      headerText = 'Delivered on $m $d';
    } else {
      final exp = order.createdAt.add(const Duration(days: 3));
      final m = months[exp.month - 1];
      final d = exp.day.toString().padLeft(2, '0');
      headerText = 'Delivery expected by $m $d';
    }

    // Format status subtitle string
    String subtitleText;
    if (isCancelled) {
      if (order.cancelReason != null && order.cancelReason!.isNotEmpty) {
        subtitleText = order.cancelReason!;
      } else {
        subtitleText = 'Your order was cancelled as per your request...';
      }
    } else if (isDelivered) {
      subtitleText = firstItem != null ? 'Item delivered at doorstep • ${firstItem.name}' : 'Package delivered to customer successfully';
    } else if (stepIdx == 0) {
      subtitleText = 'Warehouse Dispatch Active • Packing Garment...';
    } else if (stepIdx == 1) {
      subtitleText = 'Quality Check Active at Central QC Hub...';
    } else if (stepIdx == 2) {
      subtitleText = 'In Transit via VEXA Express Courier...';
    } else if (stepIdx == 3) {
      subtitleText = 'Out for Delivery • Courier Agent En Route...';
    } else {
      subtitleText = 'Product in transit to your address...';
    }

    final isUnpaidOrActive = !order.isPaid && !isCancelled && !isDelivered;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          InkWell(
            onTap: () => _openHomeOrderDetailSheet(context, order),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Thumbnail Box
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: firstItem != null
                        ? (firstItem.image.startsWith('assets/')
                            ? Image.asset(firstItem.image, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.checkroom, color: Color(0xFF94A3B8)))
                            : Image.network(firstItem.image, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.checkroom, color: Color(0xFF94A3B8))))
                        : const Icon(Icons.checkroom, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(width: 14),
                  // Middle Details Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerText,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitleText,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chevron Right
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF0F172A),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Pay right now banner if active COD order
          if (isUnpaidOrActive) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Pay right now and save the COD fee',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF37),
                      side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      RazorpayGatewayModal.show(
                        context: context,
                        amount: order.totalAmount,
                        customerName: order.customerName,
                        customerPhone: order.phone,
                        onPaymentSuccess: (methodLabel) {
                          order.paymentMethod = methodLabel;
                          order.status = 'Confirmed';
                          OrderService.updateOrderStatusLocally(
                            order.id,
                            'Confirmed',
                            context: context,
                          );
                          _refreshOrders();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Payment of ₹${order.totalAmount.toStringAsFixed(0)} verified via Razorpay!',
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: const Color(0xFF00A859),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                    child: Text(
                      'Pay ₹${order.totalAmount.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ],
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
    );
  }

  Widget _buildTrackingProgressCard(OrderModel order) {
    final isCancelled = order.status.toLowerCase().contains('cancel');
    final status = order.status.toLowerCase();

    int stepIdx = 0;
    if (status.contains('cancel')) {
      stepIdx = -1;
    } else if (status.contains('deliver')) {
      stepIdx = 4;
    } else if (status.contains('out for delivery') || status.contains('courier')) {
      stepIdx = 3;
    } else if (status.contains('ship') || status.contains('transit')) {
      stepIdx = 2;
    } else if (status.contains('qc')) {
      stepIdx = 1;
    } else {
      // Real-time time progression based on order creation
      final elapsedSeconds = DateTime.now().difference(order.createdAt).inSeconds;
      if (elapsedSeconds < 25) {
        stepIdx = 0; // Warehouse
      } else if (elapsedSeconds < 55) {
        stepIdx = 1; // QC Hub
      } else if (elapsedSeconds < 110) {
        stepIdx = 2; // Express Van
      } else if (elapsedSeconds < 180) {
        stepIdx = 3; // Out for Delivery
      } else {
        stepIdx = 4; // Delivered
      }
    }

    String expectedText = 'Expected in 2–3 Business Days';
    if (isCancelled) {
      expectedText = 'Order Cancelled';
    } else if (stepIdx == 0) {
      expectedText = 'Warehouse Dispatch Pending';
    } else if (stepIdx == 1) {
      expectedText = 'QC Inspection in Progress';
    } else if (stepIdx == 2) {
      expectedText = 'In Transit via Express Courier';
    } else if (stepIdx == 3) {
      expectedText = 'Arriving Today by 6:00 PM';
    } else if (stepIdx == 4) {
      expectedText = 'Delivered on ${order.formattedDate}';
    }

    double progressWidthFactor = 0.0;
    if (!isCancelled) {
      if (stepIdx <= 0) {
        progressWidthFactor = 0.12;
      } else if (stepIdx == 1) {
        progressWidthFactor = 0.38;
      } else if (stepIdx == 2) {
        progressWidthFactor = 0.65;
      } else if (stepIdx == 3) {
        progressWidthFactor = 0.88;
      } else {
        progressWidthFactor = 1.0;
      }
    }

    String statusDisplay = order.status.toUpperCase();
    if (!isCancelled) {
      if (stepIdx == 0) {
        statusDisplay = 'PROCESSING';
      } else if (stepIdx == 1) {
        statusDisplay = 'QC CHECK ACTIVE';
      } else if (stepIdx == 2) {
        statusDisplay = 'IN TRANSIT';
      } else if (stepIdx == 3) {
        statusDisplay = 'OUT FOR DELIVERY';
      } else if (stepIdx == 4) {
        statusDisplay = 'DELIVERED';
      }
    }

    String gpsText = 'Live GPS Sync Active • Waybill #BD-98402';
    if (isCancelled) {
      gpsText = 'Shipment Cancelled';
    } else if (stepIdx == 0) {
      gpsText = 'Warehouse Dispatch Active • Packing Garment';
    } else if (stepIdx == 1) {
      gpsText = 'Quality Check Active at QC Hub • Waybill #BD-98402';
    } else if (stepIdx == 2) {
      gpsText = 'Live GPS Sync Active • Waybill #BD-98402';
    } else if (stepIdx == 3) {
      gpsText = 'Out for Delivery • Courier Arriving Soon';
    } else if (stepIdx == 4) {
      gpsText = 'Package Delivered';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row inside Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED DELIVERY',
                      style: GoogleFonts.outfit(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: _goldDark,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      expectedText,
                      style: GoogleFonts.cinzel(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: order.statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: order.statusColor.withAlpha(100)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: order.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusDisplay,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
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

          const SizedBox(height: 24),

          // Route Nodes & Progress Line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Base Track Line
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Solid Single Color Progress Line
                FractionallySizedBox(
                  widthFactor: progressWidthFactor,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: _goldDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Route Nodes: Warehouse -> QC Hub -> Express Van -> Your Home
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHomeMapNodeIcon(Icons.storefront_rounded, 'Warehouse', stepIdx >= 0, isActiveNode: stepIdx == 0),
                    _buildHomeMapNodeIcon(Icons.inventory_2_rounded, 'QC Hub', stepIdx >= 1, isActiveNode: stepIdx == 1),
                    _buildHomeMapNodeIcon(Icons.local_shipping_rounded, 'Express Van', stepIdx >= 2, isActiveNode: stepIdx == 2 || stepIdx == 3),
                    _buildHomeMapNodeIcon(Icons.home_rounded, 'Your Home', stepIdx == 4, isActiveNode: stepIdx == 4),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Live GPS Sync Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981).withAlpha(50)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 12),
                const SizedBox(width: 6),
                Text(
                  gpsText,
                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF065F46)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeMapNodeIcon(IconData icon, String label, bool isReached, {bool isActiveNode = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActiveNode ? 34 : 26,
          height: isActiveNode ? 34 : 26,
          decoration: BoxDecoration(
            color: isReached ? _goldDark : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isReached ? _goldDark : _border,
              width: isActiveNode ? 2.5 : 1.0,
            ),
            boxShadow: isActiveNode
                ? [BoxShadow(color: _goldDark.withAlpha(100), blurRadius: 8)]
                : null,
          ),
          child: Icon(
            icon,
            size: isActiveNode ? 16 : 13,
            color: isReached ? Colors.white : _subtext,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 9.5,
            fontWeight: isReached ? FontWeight.bold : FontWeight.w500,
            color: isReached ? _textDark : _subtext,
          ),
        ),
      ],
    );
  }

  void _openHomeOrderDetailSheet(BuildContext context, OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          final isCancelled = order.status.toLowerCase() == 'cancelled';
          final isDelivered = order.status.toLowerCase().contains('deliver');

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
              actions: [
                if (order.isPaid)
                  IconButton(
                    icon: const Icon(Icons.download_rounded, color: _goldDark, size: 22),
                    tooltip: 'Download Invoice',
                    onPressed: () => _showInvoiceModal(ctx, order, autoStartDownload: true),
                  ),
              ],
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
                const SizedBox(height: 12),

                // 1.5 ESTIMATED DELIVERY & TRACKING PROGRESS CARD
                _buildTrackingProgressCard(order),

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

                // 4. PRICE DETAILS & PAYMENT SUMMARY CARD
                Text('PRICE DETAILS', style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final itemsSubtotal = order.items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
                    final baseSubtotal = itemsSubtotal > 0 ? itemsSubtotal : order.totalAmount;
                    final hasCoupon = order.couponApplied.isNotEmpty;
                    final discountAmount = hasCoupon ? (baseSubtotal * 0.10) : 0.0;
                    final netSubtotal = (baseSubtotal - discountAmount).clamp(0.0, double.infinity);
                    final taxAmount = netSubtotal * 0.18;
                    final displayTotalAmount = netSubtotal + taxAmount;
                    final totalSavings = 150.0 + discountAmount;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(4), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Items Subtotal', style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
                              Text('₹${baseSubtotal.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (hasCoupon || discountAmount > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.local_offer_rounded, size: 14, color: Color(0xFF10B981)),
                                    const SizedBox(width: 5),
                                    Text(
                                      hasCoupon ? 'Discount (${order.couponApplied})' : 'Instant Order Discount',
                                      style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF10B981), fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                Text(
                                  '-₹${discountAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_shipping_outlined, size: 15, color: _subtext),
                                  const SizedBox(width: 5),
                                  Text('Shipping Fee', style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
                                ],
                              ),
                              Row(
                                children: [
                                  Text('₹150', style: GoogleFonts.outfit(fontSize: 12, color: _subtext, decoration: TextDecoration.lineThrough)),
                                  const SizedBox(width: 6),
                                  Text('FREE Express', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF10B981))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long_rounded, size: 15, color: _subtext),
                                  const SizedBox(width: 5),
                                  Text('Taxes & Duties (GST 18%)', style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
                                ],
                              ),
                              Text('+₹${taxAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: _textDark)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.credit_card_rounded, size: 15, color: _subtext),
                                  const SizedBox(width: 5),
                                  Text('Payment Method', style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: _surfaceBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: _border)),
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
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: _border),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.isPaid ? 'Payment Received' : 'Payment Pending',
                                    style: GoogleFonts.outfit(fontSize: 11, color: order.isPaid ? const Color(0xFF10B981) : const Color(0xFFEAB308), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _goldDark,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [BoxShadow(color: _goldDark.withAlpha(60), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Text('₹${displayTotalAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF059669)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'You saved ₹${totalSavings.toStringAsFixed(0)} on this order with FREE shipping & offers!',
                                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF047857)),
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
                if (!order.isPaid && !isCancelled && !isDelivered) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C2340),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        RazorpayGatewayModal.show(
                          context: context,
                          amount: order.totalAmount,
                          customerName: order.customerName,
                          customerPhone: order.phone,
                          onPaymentSuccess: (methodLabel) {
                            order.paymentMethod = methodLabel;
                            order.status = 'Confirmed';
                            OrderService.updateOrderStatusLocally(
                              order.id,
                              'Confirmed',
                              context: context,
                            );
                            _refreshOrders();
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Payment of ₹${order.totalAmount.toStringAsFixed(0)} verified via Razorpay!',
                                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: const Color(0xFF00A859),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.bolt_rounded, color: Color(0xFFFFD700), size: 20),
                      label: Text(
                        'Pay Now via Razorpay',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // 5. ACTION BUTTONS (CANCEL ORDER LEFT, TRACK ORDER RIGHT & CUSTOMER SUPPORT)
                Row(
                  children: [
                    if (!isCancelled && !isDelivered) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: const Color(0xFFEF4444).withAlpha(150)),
                            backgroundColor: const Color(0xFFFEF2F2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showCancelOrderDialog(order);
                          },
                          icon: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 18),
                          label: Text(
                            'Cancel Order',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _goldDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
                          );
                        },
                        icon: const Icon(Icons.location_on_outlined, color: Colors.white, size: 18),
                        label: Text(
                          'Track Order',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CustomerSupportScreen(order: order)),
                      );
                    },
                    icon: const Icon(Icons.headset_mic_outlined, color: Color(0xFF10B981), size: 18),
                    label: Text(
                      'Customer Support',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCancelOrderDialog(OrderModel order) {
    String selectedReason = 'Changed my mind / Placed by mistake';
    final customReasonController = TextEditingController();

    final cancelReasons = [
      'Changed my mind / Placed by mistake',
      'Ordered wrong size or color variant',
      'Found better deal / price elsewhere',
      'Delivery time is too long',
      'Need to change shipping address',
      'Other reason',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              width: double.infinity,
              height: MediaQuery.of(sheetCtx).size.height,
              child: Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cancel_outlined, color: Color(0xFFEF4444), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CANCEL ORDER ${order.id}',
                              style: GoogleFonts.cinzel(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                              ),
                            ),
                            Text(
                              'Please select a reason for cancellation',
                              style: GoogleFonts.outfit(fontSize: 12, color: _subtext),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: _textDark, size: 26),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                  bottom: const PreferredSize(
                    preferredSize: Size.fromHeight(1),
                    child: Divider(height: 1, color: _border),
                  ),
                ),
                body: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 20,
                            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WHY DO YOU WANT TO CANCEL?',
                                style: GoogleFonts.cinzel(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...cancelReasons.map((reason) {
                                final isSelected = selectedReason == reason;
                                return InkWell(
                                  onTap: () {
                                    setSheetState(() {
                                      selectedReason = reason;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFEF4444).withAlpha(12) : const Color(0xFFFAFAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFEF4444) : _border,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                          color: isSelected ? const Color(0xFFEF4444) : _subtext,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            reason,
                                            style: GoogleFonts.outfit(
                                              fontSize: 13.5,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected ? const Color(0xFF991B1B) : _textDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              if (selectedReason == 'Other reason') ...[
                                const SizedBox(height: 10),
                                TextField(
                                  controller: customReasonController,
                                  maxLines: 3,
                                  style: GoogleFonts.outfit(fontSize: 13, color: _textDark),
                                  decoration: InputDecoration(
                                    hintText: 'Enter specific cancellation reason...',
                                    hintStyle: GoogleFonts.outfit(fontSize: 13, color: _subtext),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: _border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.all(14),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      // Bottom action buttons
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(top: BorderSide(color: _border)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: _border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.pop(sheetCtx),
                                child: Text(
                                  'Keep Order',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _subtext,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEF4444),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  final finalReason = selectedReason == 'Other reason' && customReasonController.text.trim().isNotEmpty
                                      ? customReasonController.text.trim()
                                      : selectedReason;

                                  final messenger = ScaffoldMessenger.of(context);
                                  Navigator.pop(sheetCtx);

                                  await OrderService.cancelOrder(order.id, finalReason, context: context, targetOrder: order);

                                  if (mounted) {
                                    setState(() {
                                      order.status = 'Cancelled';
                                      order.cancelReason = finalReason;
                                      _selectedOrderStatusFilter = 'Cancelled';
                                    });
                                    _refreshOrders();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        backgroundColor: const Color(0xFF10B981),
                                        behavior: SnackBarBehavior.floating,
                                        content: Row(
                                          children: [
                                            const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'Order ${order.id} cancelled. ₹${order.totalAmount.toStringAsFixed(0)} credited to VEXA Wallet!',
                                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  'Confirm Cancel',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
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
        );
      },
    );
  }
  Future<String?> _saveInvoiceFileToDisk(String invoiceNo, OrderModel order) async {
    return InvoicePdfService.saveInvoiceToDisk(invoiceNo, order);
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
              final itemsSubtotal = order.items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
              final subtotal = itemsSubtotal > 0 ? itemsSubtotal : (order.totalAmount > 0 ? order.totalAmount : 1499.0);
              final gstTotal = subtotal * 0.18;
              final cgst = gstTotal / 2;
              final sgst = gstTotal / 2;
              final totalAmt = subtotal + gstTotal;

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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFE5BF4E),
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

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
        backgroundColor: const Color(0xFFEFEFEF),
        body: Container(
          decoration: const BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
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

              // Floating Cart Icon Button on Home & Wishlist tabs
              if (_currentTabIndex == 2 || _currentTabIndex == 3)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    heroTag: 'floating_cart_home_tab',
                    backgroundColor: const Color(0xFFF2D370),
                    elevation: 8,
                    shape: const CircleBorder(
                      side: BorderSide(color: Colors.white, width: 1.5),
                    ),
                    onPressed: _openCartScreen,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0F172A), size: 22),
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
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: Color(0x3B000000),
                blurRadius: 20,
                spreadRadius: 1,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFBE89C), // Light radiant gold top
                    Color(0xFFF2D370), // Light Vexa Gold core
                    Color(0xFFE5BF4E), // Warm light gold bottom
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withAlpha(220),
                    width: 1.2,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildGoldNavItem(
                        index: 0,
                        label: 'Products',
                        icon: Icons.grid_view_outlined,
                        activeIcon: Icons.grid_view_rounded,
                      ),
                      _buildGoldNavItem(
                        index: 1,
                        label: 'My Orders',
                        icon: Icons.inventory_2_outlined,
                        activeIcon: Icons.inventory_2_rounded,
                      ),
                      _buildGoldNavItem(
                        index: 2,
                        label: 'Home',
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                      ),
                      _buildGoldNavItem(
                        index: 3,
                        label: 'Wishlist',
                        icon: Icons.favorite_outline_rounded,
                        activeIcon: Icons.favorite_rounded,
                        badgeCount: _favoriteIds.length,
                      ),
                      _buildGoldNavItem(
                        index: 4,
                        label: 'Profile',
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoldNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    int badgeCount = 0,
  }) {
    final isSelected = _currentTabIndex == index;

    return InkWell(
      onTap: () async {
        final user = await AuthService.getUser();
        final realUser = user != null && user.id != 'guest_user';
        if (mounted) {
          setState(() {
            _currentTabIndex = index;
            _currentUser = user;
            _isRealUser = realUser;
          });
          if (index == 1) {
            _refreshOrders();
          }
        }
      },
      splashColor: Colors.black12,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? Border.all(color: const Color(0xFFFFD700).withAlpha(120), width: 1)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF0F172A),
                  size: isSelected ? 22 : 20,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                      child: Text(
                        '$badgeCount',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF0F172A),
                letterSpacing: 0.2,
              ),
            ),
          ],
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
  const _PromoBannerCard({required this.banner, this.onTap});

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
          ],
        ),
      ),
    );
  }
}

// Typedef alias so SliverWidget compiles without issue
typedef SliverWidget = Widget;
