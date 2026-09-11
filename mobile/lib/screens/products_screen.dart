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

class ProductsScreen extends StatefulWidget {
  final List<ItemModel> items;
  final Function(ItemModel item, String selectedColor, String selectedSize, int quantity)? onAddToCart;
  final Set<String> favoriteIds;
  final Function(String id)? onToggleFavorite;
  final bool showBackButton;

  const ProductsScreen({
    super.key,
    required this.items,
    this.onAddToCart,
    required this.favoriteIds,
    this.onToggleFavorite,
    this.showBackButton = false,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedSort = 'Featured';
  String _selectedPriceRange = 'All';
  String _selectedColor = 'All';
  bool _inStockOnly = false;

  final List<String> _categories = ['All', 'Limited', 'Oversized', 'Classic', 'Essentials'];
  final List<String> _sortOptions = ['Featured', 'Price: Low to High', 'Price: High to Low', 'Name: A-Z'];
  final List<String> _priceRanges = ['All', 'Under ₹1500', '₹1500 - ₹1700', 'Above ₹1700'];
  final List<String> _colors = ['All', 'Black', 'White', 'Emerald', 'Rust', 'Navy', 'Sand', 'Charcoal', 'Olive', 'Lavender'];

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCategory != 'All') count++;
    if (_selectedSort != 'Featured') count++;
    if (_selectedPriceRange != 'All') count++;
    if (_selectedColor != 'All') count++;
    if (_inStockOnly) count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedSort = 'Featured';
      _selectedPriceRange = 'All';
      _selectedColor = 'All';
      _inStockOnly = false;
      _searchQuery = '';
    });
  }

  List<ItemModel> get _filteredItems {
    var list = widget.items.where((item) {
      final cat = item.category.toLowerCase();
      final selCat = _selectedCategory.toLowerCase();
      final matchCat = selCat == 'all' ||
          cat == selCat ||
          (selCat == 't-shirts' && (cat == 'oversized' || cat == 'classic' || cat == 'limited' || cat.contains('shirt'))) ||
          (selCat == 'limited' && cat == 'limited') ||
          (selCat == 'oversized' && cat == 'oversized') ||
          (selCat == 'classic' && cat == 'classic') ||
          (selCat == 'essentials' && (cat == 'essentials' || item.collectionType.toLowerCase().contains('essentials')));

      final matchSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.color.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchColor = _selectedColor == 'All' ||
          item.color.toLowerCase().contains(_selectedColor.toLowerCase()) ||
          item.colors.any((c) => c.toLowerCase().contains(_selectedColor.toLowerCase()));

      bool matchPrice = true;
      if (_selectedPriceRange == 'Under ₹1500') {
        matchPrice = item.price < 1500;
      } else if (_selectedPriceRange == '₹1500 - ₹1700') {
        matchPrice = item.price >= 1500 && item.price <= 1700;
      } else if (_selectedPriceRange == 'Above ₹1700') {
        matchPrice = item.price > 1700;
      }

      bool matchStock = !_inStockOnly || item.inStock;

      return matchCat && matchSearch && matchColor && matchPrice && matchStock;
    }).toList();

    if (_selectedSort == 'Price: Low to High') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_selectedSort == 'Price: High to Low') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_selectedSort == 'Name: A-Z') {
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    final evenCount = list.length - (list.length % 2);
    return list.take(evenCount).toList();
  }

  void _openProductDetail(ItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          item: item,
          onAddToCart: widget.onAddToCart,
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle indicator
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune_rounded, color: _gold, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Filter & Sort',
                              style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  _selectedCategory = 'All';
                                  _selectedSort = 'Featured';
                                  _selectedPriceRange = 'All';
                                  _selectedColor = 'All';
                                  _inStockOnly = false;
                                });
                                setState(() {});
                              },
                              child: Text(
                                'Reset All',
                                style: GoogleFonts.outfit(color: _subtext, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: _textDark),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: _border),

                  // Content Body
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      children: [
                        // 1. Sort By
                        _buildSectionTitle('Sort By'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _sortOptions.map((opt) {
                            final sel = _selectedSort == opt;
                            return ChoiceChip(
                              label: Text(opt),
                              selected: sel,
                              onSelected: (_) {
                                setModalState(() => _selectedSort = opt);
                                setState(() {});
                              },
                              selectedColor: _goldDark,
                              backgroundColor: _surfaceBg,
                              labelStyle: GoogleFonts.outfit(
                                color: sel ? Colors.white : _textDark,
                                fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: sel ? _gold : _border),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // 2. Category
                        _buildSectionTitle('Category'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((cat) {
                            final sel = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: sel,
                              onSelected: (_) {
                                setModalState(() => _selectedCategory = cat);
                                setState(() {});
                              },
                              selectedColor: _goldDark,
                              backgroundColor: _surfaceBg,
                              labelStyle: GoogleFonts.outfit(
                                color: sel ? Colors.white : _textDark,
                                fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: sel ? _gold : _border),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // 3. Price Range
                        _buildSectionTitle('Price Range'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _priceRanges.map((pr) {
                            final sel = _selectedPriceRange == pr;
                            return ChoiceChip(
                              label: Text(pr),
                              selected: sel,
                              onSelected: (_) {
                                setModalState(() => _selectedPriceRange = pr);
                                setState(() {});
                              },
                              selectedColor: _goldDark,
                              backgroundColor: _surfaceBg,
                              labelStyle: GoogleFonts.outfit(
                                color: sel ? Colors.white : _textDark,
                                fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: sel ? _gold : _border),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // 4. Color Option
                        _buildSectionTitle('Color Theme'),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _colors.length,
                            itemBuilder: (_, i) {
                              final c = _colors[i];
                              final sel = _selectedColor == c;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(c),
                                  selected: sel,
                                  onSelected: (_) {
                                    setModalState(() => _selectedColor = c);
                                    setState(() {});
                                  },
                                  selectedColor: _goldDark,
                                  backgroundColor: _surfaceBg,
                                  labelStyle: GoogleFonts.outfit(
                                    color: sel ? Colors.white : _textDark,
                                    fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: sel ? _gold : _border),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 5. In Stock Switch
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _surfaceBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('In Stock Only', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark)),
                              Switch(
                                value: _inStockOnly,
                                activeTrackColor: _gold,
                                activeThumbColor: Colors.white,
                                onChanged: (val) {
                                  setModalState(() => _inStockOnly = val);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Action Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: _border)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _goldDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Show ${_filteredItems.length} Products',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: _gold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final filterCount = _activeFilterCount;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        titleSpacing: widget.showBackButton ? 0 : 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _goldDark.withAlpha(50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _gold.withAlpha(120)),
              ),
              child: const Icon(Icons.grid_view_rounded, color: _gold, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('VEXA CATALOG', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: _gold)),
                Text('All Products (${filtered.length})', style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Search Bar & Filter Button Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: GoogleFonts.outfit(color: _textDark),
                    decoration: InputDecoration(
                      hintText: 'Search tees, colors, styles...',
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
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showFilterModal,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: filterCount > 0 ? _goldDark : _cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: filterCount > 0 ? _gold : _border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tune_rounded, color: filterCount > 0 ? Colors.white : _textDark, size: 20),
                        if (filterCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              '$filterCount',
                              style: GoogleFonts.outfit(color: _goldDark, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Active Filters Pill Bar (if any active filter)
          if (filterCount > 0 || _searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedCategory != 'All') _buildActiveFilterChip('Cat: $_selectedCategory', () => setState(() => _selectedCategory = 'All')),
                          if (_selectedPriceRange != 'All') _buildActiveFilterChip(_selectedPriceRange, () => setState(() => _selectedPriceRange = 'All')),
                          if (_selectedColor != 'All') _buildActiveFilterChip('Color: $_selectedColor', () => setState(() => _selectedColor = 'All')),
                          if (_selectedSort != 'Featured') _buildActiveFilterChip('Sort: $_selectedSort', () => setState(() => _selectedSort = 'Featured')),
                          if (_inStockOnly) _buildActiveFilterChip('In Stock Only', () => setState(() => _inStockOnly = false)),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    style: TextButton.styleFrom(padding: const EdgeInsets.only(left: 8)),
                    child: Text('Clear All', style: GoogleFonts.outfit(color: _goldDark, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // 4. Products Grid (ALL PRODUCTS)
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
                        Text('Try adjusting your search or filter options.', style: GoogleFonts.outfit(color: _subtext)),
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: _goldDark),
                          onPressed: _resetFilters,
                          child: Text('Reset Filters', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
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

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
        onDeleted: onRemove,
        backgroundColor: _goldDark,
        labelStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
