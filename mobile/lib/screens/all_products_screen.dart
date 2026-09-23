import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item_model.dart';
import 'product_detail_screen.dart';

const Color _gold = Color(0xFFB8860B);
const Color _goldDark = Color(0xFF8B6508);
const Color _bgColor = Color(0xFFFAFAFC);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _surfaceBg = Color(0xFFF1F5F9);
const Color _subtext = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);
const Color _textDark = Color(0xFF0F172A);

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

class AllProductsScreen extends StatefulWidget {
  final List<ItemModel> items;
  final Function(ItemModel item, String selectedColor, String selectedSize, int quantity)? onAddToCart;
  final Set<String> favoriteIds;
  final Function(String id)? onToggleFavorite;
  final String initialCategory;

  const AllProductsScreen({
    super.key,
    required this.items,
    this.onAddToCart,
    required this.favoriteIds,
    this.onToggleFavorite,
    this.initialCategory = 'All',
  });

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  String _searchQuery = '';

  List<ItemModel> get _filteredItems {
    final list = widget.items.where((item) {
      return _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.color.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
    final evenCount = list.length - (list.length % 2);
    return list.take(evenCount).toList();
  }

  void _openProductDetail(ItemModel item) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          item: item,
          onAddToCart: widget.onAddToCart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('EXPLORE CATALOG', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: _gold)),
            Text('All Products (${filtered.length})', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.outfit(color: _textDark),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, color: _subtext),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded, color: _subtext), onPressed: () => setState(() => _searchQuery = ''))
                    : null,
                filled: true,
                fillColor: _cardBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _gold)),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Products Grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.checkroom_outlined, size: 60, color: _subtext),
                        const SizedBox(height: 16),
                        Text('No items found', style: GoogleFonts.outfit(fontSize: 18, color: _textDark, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Try adjusting your search or category filter.', style: GoogleFonts.outfit(color: _subtext)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isFav = widget.favoriteIds.contains(item.id);
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
                                        onTap: () {
                                          if (widget.onToggleFavorite != null) {
                                            widget.onToggleFavorite!(item.id);
                                            setState(() {});
                                          }
                                        },
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundColor: Colors.black.withAlpha(130),
                                          child: Icon(
                                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            color: isFav ? const Color(0xFFFF4757) : Colors.white,
                                            size: 17,
                                          ),
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
                                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
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
                                          if (widget.onAddToCart != null) {
                                            widget.onAddToCart!(item, item.color, 'M', 1);
                                          }
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
                  ),
          ),
        ],
      ),
    );
  }
}
