import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/share_product_modal.dart';
import '../widgets/vexa_feedback_snackbar.dart';
import 'login_screen.dart';

class _ReviewItem {
  final String id;
  final String author;
  final int rating;
  final String date;
  final String comment;
  final bool verified;
  int helpfulCount;
  bool isHelpful;

  _ReviewItem({
    required this.id,
    required this.author,
    required this.rating,
    required this.date,
    required this.comment,
    this.verified = true,
    required this.helpfulCount,
  }) : isHelpful = false;
}

class ProductDetailScreen extends StatefulWidget {
  final ItemModel item;
  final Function(ItemModel item, String selectedColor, String selectedSize, int quantity)? onAddToCart;
  final Function(ItemModel item, String selectedColor, String selectedSize, int quantity)? onBuyNow;
  final VoidCallback? onOpenCart;
  final List<ItemModel>? similarProducts;
  final Set<String>? favoriteIds;
  final Function(String id)? onToggleFavorite;

  const ProductDetailScreen({
    super.key,
    required this.item,
    this.onAddToCart,
    this.onBuyNow,
    this.onOpenCart,
    this.similarProducts,
    this.favoriteIds,
    this.onToggleFavorite,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late String _selectedColor;
  late String _currentDisplayImage;
  String _selectedSize = 'M';
  int _quantity = 1;
  bool _isFavorite = false;
  int _filterStar = 0; // 0 = All
  bool _showAllReviews = false;

  late PageController _pageController;
  late TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;
  int _activePageIndex = 0;

  final List<String> _availableSizes = ['S', 'M', 'L', 'XL'];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewsSectionKey = GlobalKey();

  late List<_ReviewItem> _reviews;
  late List<ItemModel> _catalogItems;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _transformationController = TransformationController();
    _selectedColor = widget.item.colors.isNotEmpty ? widget.item.colors.first : widget.item.color;
    _currentDisplayImage = widget.item.image;
    _isFavorite = widget.favoriteIds?.contains(widget.item.id) ?? false;

    _catalogItems = widget.similarProducts ?? ApiService.getFallbackItems();

    // Initialize default customer reviews
    _reviews = [
      _ReviewItem(
        id: 'rev-1',
        author: 'Rohan V.',
        rating: 5,
        date: '2 days ago',
        comment: 'The 240 GSM heavy cotton feel is insane! Fits perfectly oversized without looking boxy. Color fastness after washing is top notch.',
        verified: true,
        helpfulCount: 24,
      ),
      _ReviewItem(
        id: 'rev-2',
        author: 'Ananya I.',
        rating: 5,
        date: '5 days ago',
        comment: 'Pure luxury aesthetic. Stitching detail and drop shoulder cut is premium quality.',
        verified: true,
        helpfulCount: 18,
      ),
      _ReviewItem(
        id: 'rev-3',
        author: 'Kabir M.',
        rating: 4,
        date: '1 week ago',
        comment: 'Heavy weight fabric and premium dye finish. Sizing runs slightly relaxed.',
        verified: true,
        helpfulCount: 9,
      ),
      _ReviewItem(
        id: 'rev-4',
        author: 'Siddharth R.',
        rating: 5,
        date: '2 weeks ago',
        comment: 'Worth every rupee! Better texture and fit than high-end imported streetwear brands.',
        verified: true,
        helpfulCount: 12,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (_transformationController.value.getMaxScaleOnAxis() > 1.1) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? const Offset(200, 200);
      const double scale = 2.5;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);
      _transformationController.value = Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(x, y)
        // ignore: deprecated_member_use
        ..scale(scale);
    }
  }

  List<Map<String, dynamic>> get _gallerySlides {
    final mainImg = _currentDisplayImage;

    return [
      {
        'title': 'Front Side',
        'image': mainImg,
        'type': 'front',
      },
      {
        'title': 'Side Angle',
        'image': mainImg,
        'type': 'side',
      },
      {
        'title': 'Key Highlights',
        'image': mainImg,
        'type': 'highlights',
      },
    ];
  }

  Widget _buildHighlightItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.white.withAlpha(190),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.white.withAlpha(40),
          ),
        ],
      ),
    );
  }

  void _openShareModalSheet() {
    ShareProductModal.show(context, widget.item);
  }

  void _openImagePopup(BuildContext context, String currentImg, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) {
          int popupIndex = initialIndex;
          final slides = _gallerySlides;
          final popupPageController = PageController(initialPage: initialIndex);
          final popupTransformationController = TransformationController();

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                onPressed: () => Navigator.pop(ctx),
              ),
              title: StatefulBuilder(
                builder: (modalCtx, setHeaderState) {
                  return Text(
                    '${popupIndex + 1} of ${slides.length}',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                  );
                },
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  onPressed: () => _openShareModalSheet(),
                ),
              ],
            ),
            body: StatefulBuilder(
              builder: (modalCtx, setModalState) {
                return Stack(
                  children: [
                    PageView.builder(
                      controller: popupPageController,
                      onPageChanged: (idx) {
                        setModalState(() {
                          popupIndex = idx;
                          popupTransformationController.value = Matrix4.identity();
                        });
                      },
                      itemCount: slides.length,
                      itemBuilder: (c, idx) {
                        final slide = slides[idx];
                        final imgPath = slide['image'] as String;

                        Widget popupImageWidget = _buildProductImage(
                          imgPath,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                        );

                        // Render full uncropped product image across all slides in popup


                        return GestureDetector(
                          onDoubleTap: () {
                            if (popupTransformationController.value.getMaxScaleOnAxis() > 1.1) {
                              popupTransformationController.value = Matrix4.identity();
                            } else {
                              // ignore: deprecated_member_use
                              popupTransformationController.value = Matrix4.identity()..scale(2.5);
                            }
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Center(
                                child: InteractiveViewer(
                                  transformationController: popupTransformationController,
                                  minScale: 1.0,
                                  maxScale: 5.0,
                                  child: popupImageWidget,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Bottom navigation dots
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(slides.length, (dotIdx) {
                              final isCurrent = dotIdx == popupIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: isCurrent ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isCurrent ? AppTheme.primaryColor : Colors.white38,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }



  Widget _buildProductImage(String src, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        width: width,
        height: height,
        fit: fit,
      );
    }
    return Image.network(
      src,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: AppTheme.surfaceColor,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined, color: AppTheme.subtextColor, size: 36),
        ),
      ),
    );
  }

  double get _averageRating {
    if (_reviews.length == 4) {
      return widget.item.rating;
    }
    final total = _reviews.fold<double>(0, (sum, item) => sum + item.rating);
    return total / _reviews.length;
  }

  int get _effectiveReviewsCount {
    return widget.item.reviewsCount + (_reviews.length - 4);
  }



  Map<int, int> get _ratingDistribution {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      dist[r.rating] = (dist[r.rating] ?? 0) + 1;
    }
    return dist;
  }

  List<_ReviewItem> get _filteredReviews {
    if (_filterStar == 0) return _reviews;
    return _reviews.where((r) => r.rating == _filterStar).toList();
  }

  Set<String> get _outOfStockSizes {
    final id = widget.item.id.toLowerCase();
    final name = widget.item.name.toLowerCase();
    if (!widget.item.inStock) {
      return {'S', 'M', 'L', 'XL'};
    }
    if (id.contains('vx-08') || name.contains('emerald')) {
      return {'XL'};
    }
    if (id.contains('vx-12') || name.contains('lavender')) {
      return {'S'};
    }
    if (id.contains('vx-01') || name.contains('obsidian')) {
      return {'L'};
    }
    return {'XL'};
  }

  void _scrollToReviews() {
    final context = _reviewsSectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }



  void _openWriteReviewSheet() {
    int selectedRating = 5;
    final nameController = TextEditingController(text: 'Verified Customer');
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.subtextColor.withAlpha(80),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Write a Review',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  Text(
                    'Share your experience with ${widget.item.name}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppTheme.subtextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Rating Selector
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          iconSize: 32,
                          icon: Icon(
                            star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: const Color(0xFFFFC107),
                          ),
                          onPressed: () {
                            setSheetState(() {
                              selectedRating = star;
                            });
                          },
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.outfit(color: AppTheme.textColor),
                    decoration: InputDecoration(
                      labelText: 'Your Name',
                      labelStyle: GoogleFonts.outfit(color: AppTheme.subtextColor),
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: GoogleFonts.outfit(color: AppTheme.textColor),
                    decoration: InputDecoration(
                      labelText: 'Review Comment',
                      labelStyle: GoogleFonts.outfit(color: AppTheme.subtextColor),
                      hintText: 'What did you like or dislike about this item?',
                      hintStyle: GoogleFonts.outfit(color: AppTheme.subtextColor.withAlpha(120)),
                      prefixIcon: const Icon(Icons.rate_review_outlined, color: AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final text = commentController.text.trim();
                        final author = nameController.text.trim().isEmpty ? 'Customer' : nameController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a review comment'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        final newRev = _ReviewItem(
                          id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
                          author: author,
                          rating: selectedRating,
                          date: 'Just now',
                          comment: text,
                          verified: true,
                          helpfulCount: 0,
                        );

                        setState(() {
                          _reviews.insert(0, newRev);
                          _filterStar = 0;
                        });

                        Navigator.pop(ctx);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Thank you! Your $selectedRating-star review has been added.'),
                            backgroundColor: AppTheme.primaryColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );

                        _scrollToReviews();
                      },
                      child: Text(
                        'Submit Review',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
    );
  }

  double _getSizePrice(String size) {
    final basePrice = widget.item.price;
    switch (size.toUpperCase()) {
      case 'S':
        return (basePrice - 50).clamp(1.0, double.infinity);
      case 'M':
        return basePrice;
      case 'L':
        return basePrice + 100;
      case 'XL':
        return basePrice + 200;
      case 'XXL':
        return basePrice + 300;
      default:
        return basePrice;
    }
  }

  double? _getSizeOldPrice(String size) {
    if (widget.item.oldPrice == null) return null;
    final baseOldPrice = widget.item.oldPrice!;
    switch (size.toUpperCase()) {
      case 'S':
        return (baseOldPrice - 50).clamp(1.0, double.infinity);
      case 'M':
        return baseOldPrice;
      case 'L':
        return baseOldPrice + 100;
      case 'XL':
        return baseOldPrice + 200;
      case 'XXL':
        return baseOldPrice + 300;
      default:
        return baseOldPrice;
    }
  }

  double get _currentPrice => _getSizePrice(_selectedSize);
  double? get _currentOldPrice => _getSizeOldPrice(_selectedSize);

  int get _currentDiscountPercent {
    final curPrice = _currentPrice;
    final curOld = _currentOldPrice;
    if (curOld != null && curOld > curPrice) {
      return (((curOld - curPrice) / curOld) * 100).round();
    }
    return 25;
  }

  @override
  Widget build(BuildContext context) {
    final curPrice = _currentPrice;
    final curOldPrice = _currentOldPrice;
    final discountPercent = _currentDiscountPercent;

    // Filter similar products (exclude current product)
    final similarItemsList = _catalogItems.where((i) => i.id != widget.item.id).toList();
    final slides = _gallerySlides;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Main Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ════════════════════════════════════════════════════════
                    // 1. FULL HERO IMAGE DISPLAY WITH SIDE SCROLLING (MULTI-ANGLE)
                    // ════════════════════════════════════════════════════════
                    SizedBox(
                      height: 520,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Studio neutral light-black background container so full uncropped image displays cleanly
                          Container(color: const Color(0xFF2C2C2E)),

                          // Side-scrollable PageView of exact product image angles (Front Side, Back Side, Side Angle, Key Highlights)
                          PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() {
                                _activePageIndex = index;
                                _transformationController.value = Matrix4.identity();
                              });
                            },
                            itemCount: slides.length,
                            itemBuilder: (context, index) {
                              final slide = slides[index];
                              final type = slide['type'] as String;
                              final imgPath = slide['image'] as String;

                              Widget imageWidget = GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _openImagePopup(context, imgPath, index),
                                onDoubleTapDown: (details) {
                                  _doubleTapDetails = details;
                                },
                                onDoubleTap: _handleDoubleTap,
                                child: InteractiveViewer(
                                  transformationController: _transformationController,
                                  minScale: 1.0,
                                  maxScale: 4.5,
                                  clipBehavior: Clip.none,
                                  child: _buildProductImage(
                                    imgPath,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );



                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  imageWidget,
                                  if (type == 'highlights') ...[
                                      // Key Highlights Overlay (Matching user's reference)
                                      Container(
                                        color: Colors.black.withAlpha(165),
                                        padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Key Highlights',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              _buildHighlightItem('Pattern', 'Self Design / Heavy Ribbed Seams'),
                                              _buildHighlightItem('Type', 'Daily | Luxury Streetwear'),
                                              _buildHighlightItem('Occasion', 'Party | Festive | Casual'),
                                              _buildHighlightItem('Fabric', '240 GSM Combed Cotton'),
                                              _buildHighlightItem('Fit', 'Relaxed Boxy Drop-Shoulder'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                          ),

                          // Top Gradient Overlay for back & action buttons contrast
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: MediaQuery.of(context).padding.top + 90,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withAlpha(140),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Top-Left Floating Back Button
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 10,
                            left: 16,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(40),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),
                                ),
                              ),
                            ),
                          ),

                          // Top-Right Floating Controls (Wishlist & Share)
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 10,
                            right: 16,
                            child: Column(
                              children: [
                                // Wishlist Button (Adds to Wishlist on tap)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isFavorite = !_isFavorite;
                                    });
                                    if (widget.onToggleFavorite != null) {
                                      widget.onToggleFavorite!(widget.item.id);
                                    }
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _isFavorite
                                              ? '❤️ Added ${widget.item.name} to your Wishlist!'
                                              : 'Removed ${widget.item.name} from your Wishlist',
                                        ),
                                        backgroundColor: _isFavorite ? const Color(0xFFFF4757) : AppTheme.primaryColor,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(40),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: _isFavorite ? const Color(0xFFFF4757) : Colors.black87,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Share Button (Opens social share apps modal)
                                GestureDetector(
                                  onTap: _openShareModalSheet,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(40),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.send_rounded,
                                        color: Colors.black87,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bottom-Left Floating Rating Badge Pill (e.g., 4.5 ★ | 168)
                          Positioned(
                            left: 16,
                            bottom: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(40),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _averageRating.toStringAsFixed(1),
                                    style: GoogleFonts.outfit(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(Icons.star_rounded, color: Colors.green, size: 15),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 1,
                                    height: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$_effectiveReviewsCount',
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
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

                    // Progress Segment Indicator Bar under image
                    Container(
                      height: 3,
                      width: double.infinity,
                      color: const Color(0xFFE2E8F0),
                      child: Row(
                        children: List.generate(slides.length, (idx) {
                          final isActive = _activePageIndex == idx;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 3,
                              color: isActive ? AppTheme.primaryColor : Colors.transparent,
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Content Padding Container
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [


                          // ════════════════════════════════════════════════════
                          // 3. BRAND, PRODUCT TITLE & PRICE SECTION
                          // ════════════════════════════════════════════════════
                          Text(
                            'Chhavi Fashion',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.subtextColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.item.name,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),


                          // Price Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${curPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (curOldPrice != null) ...[
                                Text(
                                  '₹${curOldPrice.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    color: AppTheme.subtextColor,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                '$discountPercent% OFF',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ════════════════════════════════════════════════════
                          // 4. SIZE SELECTION & STOCK STATUS
                          // ════════════════════════════════════════════════════
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Select Size:',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              Text(
                                _outOfStockSizes.contains(_selectedSize)
                                    ? 'Size $_selectedSize (Out of Stock)'
                                    : 'Size $_selectedSize (In Stock)',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _outOfStockSizes.contains(_selectedSize)
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: _availableSizes.map((size) {
                              final isSelected = _selectedSize == size;
                              final isOutOfStock = _outOfStockSizes.contains(size);

                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedSize = size;
                                    });
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (isOutOfStock ? Colors.redAccent.withAlpha(40) : AppTheme.primaryColor)
                                              : AppTheme.cardColor,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? (isOutOfStock ? Colors.redAccent : AppTheme.primaryColor)
                                                : (isOutOfStock ? Colors.redAccent.withAlpha(70) : const Color(0xFF2D2D3A)),
                                            width: isSelected ? 2 : 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            size,
                                            style: GoogleFonts.outfit(
                                              color: isSelected
                                                  ? (isOutOfStock ? Colors.redAccent : Colors.white)
                                                  : (isOutOfStock ? AppTheme.subtextColor.withAlpha(140) : AppTheme.subtextColor),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              decoration: isOutOfStock ? TextDecoration.lineThrough : TextDecoration.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isOutOfStock)
                                        Positioned(
                                          top: -4,
                                          right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'OOS',
                                              style: GoogleFonts.outfit(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (_outOfStockSizes.contains(_selectedSize)) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent.withAlpha(80)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Currently Out of Stock in Size $_selectedSize',
                                          style: GoogleFonts.outfit(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          'Select another size or tap Notify Me below for restock updates.',
                                          style: GoogleFonts.outfit(
                                            color: AppTheme.subtextColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Quantity Selector
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Quantity:',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textColor,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF2D2D3A)),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_rounded, color: AppTheme.textColor, size: 18),
                                      onPressed: () {
                                        if (_quantity > 1) {
                                          setState(() {
                                            _quantity--;
                                          });
                                        }
                                      },
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '$_quantity',
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_rounded, color: AppTheme.textColor, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _quantity++;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Description Section
                          Text(
                            'Description:',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.item.description.isNotEmpty
                                ? widget.item.description
                                : 'Crafted with premium high-density heavy cotton fabric, drop-shoulder relaxed silhouette, double-stitched reinforced seam detail, and long-lasting vibrant color dye.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.subtextColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ════════════════════════════════════════════════════
                          // 5. SIMILAR PRODUCTS SECTION
                          // ════════════════════════════════════════════════════
                          if (similarItemsList.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Similar Products',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                                Text(
                                  'You May Also Like',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppTheme.subtextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            SizedBox(
                              height: 270,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: similarItemsList.length,
                                itemBuilder: (context, index) {
                                  final simItem = similarItemsList[index];
                                  final simDiscount = simItem.oldPrice != null && simItem.oldPrice! > simItem.price
                                      ? (((simItem.oldPrice! - simItem.price) / simItem.oldPrice!) * 100).round()
                                      : 25;
                                  final isSimFav = widget.favoriteIds?.contains(simItem.id) ?? false;

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(
                                            item: simItem,
                                            onAddToCart: widget.onAddToCart,
                                            onBuyNow: widget.onBuyNow,
                                            onOpenCart: widget.onOpenCart,
                                            similarProducts: _catalogItems,
                                            favoriteIds: widget.favoriteIds,
                                            onToggleFavorite: widget.onToggleFavorite,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 165,
                                      margin: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardColor,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(color: const Color(0xFF2E2E3E), width: 1.2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(50),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Similar Item Image with Badge Overlay
                                          Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                                                child: SizedBox(
                                                  height: 155,
                                                  width: double.infinity,
                                                  child: _buildProductImage(
                                                    simItem.image,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              // Top-Left Discount Badge Pill
                                              Positioned(
                                                top: 8,
                                                left: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '$simDiscount% OFF',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Top-Right Favorite Button
                                              if (widget.onToggleFavorite != null)
                                                Positioned(
                                                  top: 6,
                                                  right: 6,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      widget.onToggleFavorite!(simItem.id);
                                                    },
                                                    child: Container(
                                                      width: 28,
                                                      height: 28,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withAlpha(140),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        isSimFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                        color: isSimFav ? Colors.redAccent : Colors.white,
                                                        size: 15,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          // Product Details Section
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        simItem.category.toUpperCase(),
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 9.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: AppTheme.primaryColor,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        simItem.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppTheme.textColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          if (simItem.oldPrice != null)
                                                            Text(
                                                              '₹${simItem.oldPrice!.toStringAsFixed(0)}',
                                                              style: GoogleFonts.outfit(
                                                                fontSize: 11,
                                                                color: AppTheme.subtextColor,
                                                                decoration: TextDecoration.lineThrough,
                                                              ),
                                                            ),
                                                          Text(
                                                            '₹${simItem.price.toStringAsFixed(0)}',
                                                            style: GoogleFonts.outfit(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.w900,
                                                              color: AppTheme.textColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Container(
                                                        width: 28,
                                                        height: 28,
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.primaryColor.withAlpha(35),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Icon(
                                                          Icons.arrow_forward_rounded,
                                                          color: AppTheme.primaryColor,
                                                          size: 15,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],

                          // ════════════════════════════════════════════════════
                          // 6. CUSTOMER REVIEWS SECTION
                          // ════════════════════════════════════════════════════
                          Container(
                            key: _reviewsSectionKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Customer Reviews',
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textColor,
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppTheme.primaryColor),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: _openWriteReviewSheet,
                                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryColor),
                                      label: Text(
                                        'Write Review',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Ratings Summary Box
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF2D2D3A)),
                                  ),
                                  child: Row(
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            _averageRating.toStringAsFixed(1),
                                            style: GoogleFonts.outfit(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.textColor,
                                            ),
                                          ),
                                          Row(
                                            children: List.generate(5, (index) {
                                              final starVal = index + 1;
                                              return Icon(
                                                starVal <= _averageRating.round()
                                                    ? Icons.star_rounded
                                                    : Icons.star_half_rounded,
                                                color: const Color(0xFFFFC107),
                                                size: 16,
                                              );
                                            }),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$_effectiveReviewsCount ratings',
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              color: AppTheme.subtextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 20),
                                      const SizedBox(
                                        height: 70,
                                        child: VerticalDivider(color: Color(0xFF2D2D3A), width: 1),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          children: [5, 4, 3, 2, 1].map((star) {
                                            final count = _ratingDistribution[star] ?? 0;
                                            final pct = _reviews.isEmpty ? 0.0 : count / _reviews.length;
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: Row(
                                                children: [
                                                  Text(
                                                    '$star',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 11,
                                                      color: AppTheme.subtextColor,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 12),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: LinearProgressIndicator(
                                                        value: pct,
                                                        minHeight: 6,
                                                        backgroundColor: AppTheme.backgroundColor,
                                                        color: AppTheme.primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  SizedBox(
                                                    width: 18,
                                                    child: Text(
                                                      '$count',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 11,
                                                        color: AppTheme.subtextColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),


                                // Reviews List
                                if (_filteredReviews.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFF2D2D3A)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.rate_review_outlined, color: AppTheme.subtextColor, size: 36),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No reviews for this filter yet.',
                                          style: GoogleFonts.outfit(
                                            color: AppTheme.textColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else ...[
                                  Builder(
                                    builder: (context) {
                                      final displayed = _showAllReviews
                                          ? _filteredReviews
                                          : _filteredReviews.take(2).toList();
                                      return Column(
                                        children: [
                                          ListView.separated(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: displayed.length,
                                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                                            itemBuilder: (context, index) {
                                              final rev = displayed[index];
                                              return Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.cardColor,
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: const Color(0xFF2D2D3A)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            CircleAvatar(
                                                              radius: 16,
                                                              backgroundColor: AppTheme.primaryColor.withAlpha(50),
                                                              child: Text(
                                                                rev.author.isNotEmpty ? rev.author[0].toUpperCase() : 'U',
                                                                style: GoogleFonts.outfit(
                                                                  color: AppTheme.primaryColor,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 10),
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Row(
                                                                  children: [
                                                                    Text(
                                                                      rev.author,
                                                                      style: GoogleFonts.outfit(
                                                                        color: AppTheme.textColor,
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: 14,
                                                                      ),
                                                                    ),
                                                                    if (rev.verified) ...[
                                                                      const SizedBox(width: 6),
                                                                      Container(
                                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                                        decoration: BoxDecoration(
                                                                          color: Colors.green.withAlpha(40),
                                                                          borderRadius: BorderRadius.circular(6),
                                                                        ),
                                                                        child: Row(
                                                                          children: [
                                                                            const Icon(Icons.verified_rounded, size: 11, color: Colors.greenAccent),
                                                                            const SizedBox(width: 3),
                                                                            Text(
                                                                              'Verified Buyer',
                                                                              style: GoogleFonts.outfit(
                                                                                color: Colors.greenAccent,
                                                                                fontSize: 10,
                                                                                fontWeight: FontWeight.w600,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ],
                                                                ),
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  rev.date,
                                                                  style: GoogleFonts.outfit(
                                                                    color: AppTheme.subtextColor,
                                                                    fontSize: 11,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: List.generate(5, (starIdx) {
                                                            final starVal = starIdx + 1;
                                                            return Icon(
                                                              starVal <= rev.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                                              color: const Color(0xFFFFC107),
                                                              size: 14,
                                                            );
                                                          }),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      rev.comment,
                                                      style: GoogleFonts.outfit(
                                                        color: AppTheme.textColor,
                                                        fontSize: 13,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                          if (_filteredReviews.length > 2) ...[
                                            const SizedBox(height: 14),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(
                                                    color: AppTheme.primaryColor.withAlpha(200),
                                                    width: 1.5,
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _showAllReviews = !_showAllReviews;
                                                  });
                                                },
                                                icon: Icon(
                                                  _showAllReviews
                                                      ? Icons.keyboard_arrow_up_rounded
                                                      : Icons.keyboard_arrow_down_rounded,
                                                  color: AppTheme.primaryColor,
                                                  size: 20,
                                                ),
                                                label: Text(
                                                  _showAllReviews
                                                      ? 'Show Less Reviews'
                                                      : 'View All Reviews (${_filteredReviews.length})',
                                                  style: GoogleFonts.outfit(
                                                    color: AppTheme.primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                ],
                               const SizedBox(height: 24),
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

            // ════════════════════════════════════════════════════════
            // 7. STICKY BOTTOM ACTION BAR (ADD TO CART & BUY NOW)
            // ════════════════════════════════════════════════════════
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
              child: _outOfStockSizes.contains(_selectedSize)
                  ? SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🔔 Notification alert set for Size $_selectedSize! We will notify you on restock.'),
                              backgroundColor: AppTheme.primaryColor,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        },
                        icon: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 20),
                        label: Text(
                          'NOTIFY ME WHEN AVAILABLE',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        // Add to Cart Button (White Outlined)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                final sizedItem = widget.item.copyWith(
                                  price: _currentPrice,
                                  oldPrice: _currentOldPrice,
                                );
                                if (widget.onAddToCart != null) {
                                  widget.onAddToCart!(sizedItem, _selectedColor, _selectedSize, _quantity);
                                }
                                VexaFeedback.showAddToCartSuccess(
                                  context,
                                  productName: widget.item.name,
                                  onViewCart: widget.onOpenCart,
                                );
                              },
                              child: Text(
                                'Add to cart',
                                style: GoogleFonts.outfit(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Buy Now Button (VEXA Gold based on app theme)
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor, // VEXA Gold based on app
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                final user = await AuthService.getUser();
                                final isGuest = user == null || user.id == 'guest_user';

                                if (isGuest) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please sign in to proceed with your purchase.',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: AppTheme.primaryColor,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  );
                                  return;
                                }

                                final sizedItem = widget.item.copyWith(
                                  price: _currentPrice,
                                  oldPrice: _currentOldPrice,
                                );
                                if (widget.onBuyNow != null) {
                                  widget.onBuyNow!(sizedItem, _selectedColor, _selectedSize, _quantity);
                                } else if (widget.onAddToCart != null) {
                                  widget.onAddToCart!(sizedItem, _selectedColor, _selectedSize, _quantity);
                                }
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                if (widget.onOpenCart != null) {
                                  widget.onOpenCart!();
                                }
                              },
                              child: Text(
                                'Buy now',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
