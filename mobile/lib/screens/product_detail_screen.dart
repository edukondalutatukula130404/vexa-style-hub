import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';

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

  const ProductDetailScreen({
    super.key,
    required this.item,
    this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late String _selectedColor;
  String _selectedSize = 'M';
  int _quantity = 1;
  bool _isFavorite = false;
  int _filterStar = 0; // 0 = All

  final List<String> _availableSizes = ['S', 'M', 'L', 'XL'];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewsSectionKey = GlobalKey();

  late List<_ReviewItem> _reviews;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.item.colors.isNotEmpty ? widget.item.colors.first : widget.item.color;

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
        comment: 'Pure luxury streetwear aesthetic. Stitching detail on the collar and drop shoulders is premium quality.',
        verified: true,
        helpfulCount: 18,
      ),
      _ReviewItem(
        id: 'rev-3',
        author: 'Kabir M.',
        rating: 4,
        date: '1 week ago',
        comment: 'Heavy weight fabric and premium dye finish. Sizing runs slightly larger than expected, order true to size for relaxed fit.',
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
    _scrollController.dispose();
    super.dispose();
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 5.0;
    final total = _reviews.fold<double>(0, (sum, item) => sum + item.rating);
    return total / _reviews.length;
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

  void _toggleHelpful(_ReviewItem review) {
    setState(() {
      if (review.isHelpful) {
        review.helpfulCount--;
        review.isHelpful = false;
      } else {
        review.helpfulCount++;
        review.isHelpful = true;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final discountPercent = widget.item.oldPrice != null && widget.item.oldPrice! > widget.item.price
        ? (((widget.item.oldPrice! - widget.item.price) / widget.item.oldPrice!) * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Item Details',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isFavorite ? const Color(0xFFFF4757) : AppTheme.textColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                  ),
                ],
              ),
            ),
            // Product Content ScrollView
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Image Stack
                    Container(
                      height: 320,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF2D2D3A)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            if (widget.item.image.startsWith('assets/'))
                              Image.asset(
                                widget.item.image,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            else
                              Image.network(
                                widget.item.image,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppTheme.surfaceColor,
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported_outlined, color: AppTheme.subtextColor, size: 48),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.item.category,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (discountPercent > 0)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '-$discountPercent% OFF',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Details Card Container
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹${widget.item.price.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                              if (widget.item.oldPrice != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '₹${widget.item.oldPrice!.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    color: AppTheme.subtextColor,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _scrollToReviews,
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '${_averageRating.toStringAsFixed(1)} (${_reviews.length} reviews)',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.subtextColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_downward_rounded, size: 13, color: AppTheme.subtextColor),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Color Selection
                          Text(
                            'Select Color:',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 10,
                            children: widget.item.colors.map((color) {
                              final isSelected = _selectedColor == color;
                              return ChoiceChip(
                                label: Text(color),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedColor = color;
                                  });
                                },
                                selectedColor: AppTheme.primaryColor,
                                backgroundColor: AppTheme.cardColor,
                                labelStyle: GoogleFonts.outfit(
                                  color: isSelected ? Colors.white : AppTheme.subtextColor,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected ? AppTheme.primaryColor : const Color(0xFF2D2D3A),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Size Selection Header & Chips
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
                                        width: 50,
                                        height: 50,
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
                          const SizedBox(height: 12),

                          // Amazon & Flipkart Style In-Stock / Out-of-Stock Inline Banner
                          if (_outOfStockSizes.contains(_selectedSize))
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
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withAlpha(80)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'In Stock — Ready for immediate dispatch',
                                    style: GoogleFonts.outfit(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

                          // Description
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
                            widget.item.description,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.subtextColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ════════════════════════════════════════════════════
                          // DYNAMIC CUSTOMER REVIEWS SECTION
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

                                // Ratings Summary & Breakdown Box
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF2D2D3A)),
                                  ),
                                  child: Row(
                                    children: [
                                      // Score Overview Column
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
                                            '${_reviews.length} ratings',
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

                                      // Rating Bars Column
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

                                // Rating Filter Chips
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [0, 5, 4, 3, 2, 1].map((star) {
                                      final isSelected = _filterStar == star;
                                      final label = star == 0 ? 'All (${_reviews.length})' : '$star ★';
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text(label),
                                          selected: isSelected,
                                          onSelected: (_) {
                                            setState(() {
                                              _filterStar = star;
                                            });
                                          },
                                          selectedColor: AppTheme.primaryColor,
                                          backgroundColor: AppTheme.cardColor,
                                          labelStyle: GoogleFonts.outfit(
                                            color: isSelected ? Colors.white : AppTheme.subtextColor,
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            side: BorderSide(
                                              color: isSelected ? AppTheme.primaryColor : const Color(0xFF2D2D3A),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
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
                                        const SizedBox(height: 4),
                                        Text(
                                          'Be the first to share your thoughts!',
                                          style: GoogleFonts.outfit(
                                            color: AppTheme.subtextColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _filteredReviews.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final rev = _filteredReviews[index];
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
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  borderRadius: BorderRadius.circular(8),
                                                  onTap: () => _toggleHelpful(rev),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          rev.isHelpful ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                                          size: 13,
                                                          color: rev.isHelpful ? AppTheme.primaryColor : AppTheme.subtextColor,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Helpful (${rev.helpfulCount})',
                                                          style: GoogleFonts.outfit(
                                                            fontSize: 11,
                                                            color: rev.isHelpful ? AppTheme.primaryColor : AppTheme.subtextColor,
                                                            fontWeight: rev.isHelpful ? FontWeight.bold : FontWeight.normal,
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
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Add to Cart Bar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: const Color(0xFF2D2D3A)),
              ),
              child: _outOfStockSizes.contains(_selectedSize)
                  ? SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
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
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              if (widget.onAddToCart != null) {
                                widget.onAddToCart!(widget.item, _selectedColor, _selectedSize, _quantity);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added $_quantity x ${widget.item.name} ($_selectedSize, $_selectedColor) to cart'),
                                  backgroundColor: AppTheme.primaryColor,
                                ),
                              );
                            },
                            child: Text(
                              'Add to Cart',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              if (widget.onAddToCart != null) {
                                widget.onAddToCart!(widget.item, _selectedColor, _selectedSize, _quantity);
                              }
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Buy Now',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
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
  }
}
