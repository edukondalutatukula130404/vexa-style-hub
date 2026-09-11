import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/item_model.dart';

// ── Gold & White Luxury Theme Tokens ───────────────────────────────────────
const Color _gold = Color(0xFFB8860B);
const Color _goldDark = Color(0xFF8B6508);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _surfaceBg = Color(0xFFF1F5F9);
const Color _bgColor = Color(0xFFFAFAFC);
const Color _subtext = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);
const Color _textDark = Color(0xFF0F172A);
const Color _successGreen = Color(0xFF10B981);
const Color _errorRed = Color(0xFFEF4444);

class CartItemData {
  final ItemModel item;
  final String selectedColor;
  final String selectedSize;
  int quantity;

  CartItemData({
    required this.item,
    required this.selectedColor,
    required this.selectedSize,
    this.quantity = 1,
  });

  double get totalPrice => item.price * quantity;
}

Widget _cartProductImage(
  String src, {
  double height = 80,
  double width = 80,
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
      child: const Center(
        child: Icon(Icons.image_outlined, color: _subtext, size: 24),
      ),
    ),
  );
}

class CartScreen extends StatefulWidget {
  final List<CartItemData> cartItems;
  final VoidCallback? onCartUpdated;
  final VoidCallback? onNavigateToProducts;

  const CartScreen({
    super.key,
    required this.cartItems,
    this.onCartUpdated,
    this.onNavigateToProducts,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isSubmittingOrder = false;
  final TextEditingController _couponController = TextEditingController();
  String _appliedCoupon = '';
  double _discountPercent = 0.0;
  String _couponMessage = '';
  bool _couponSuccess = false;

  double get _rawSubtotal {
    double total = 0;
    for (final cartItem in widget.cartItems) {
      total += cartItem.totalPrice;
    }
    return total;
  }

  double get _discountAmount => _rawSubtotal * _discountPercent;

  double get _finalTotal => (_rawSubtotal - _discountAmount).clamp(0, double.infinity);

  void _applyCoupon() {
    FocusScope.of(context).unfocus();
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _couponMessage = 'Please enter a valid promo code';
        _couponSuccess = false;
      });
      return;
    }

    if (code == 'VEXA10' || code == 'WELCOME10') {
      setState(() {
        _appliedCoupon = code;
        _discountPercent = 0.10;
        _couponMessage = '10% VEXA Welcome discount applied!';
        _couponSuccess = true;
      });
    } else if (code == 'VEXA30' || code == 'FESTIVE30') {
      setState(() {
        _appliedCoupon = code;
        _discountPercent = 0.30;
        _couponMessage = '30% Luxury Drop discount applied!';
        _couponSuccess = true;
      });
    } else {
      setState(() {
        _appliedCoupon = '';
        _discountPercent = 0.0;
        _couponMessage = 'Invalid code. Try "VEXA10" or "VEXA30"';
        _couponSuccess = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = '';
      _discountPercent = 0.0;
      _couponController.clear();
      _couponMessage = '';
    });
  }

  void _showCheckoutDialog() {
    final nameController = TextEditingController(text: 'John Doe');
    final addressController = TextEditingController(text: '123 Luxury Avenue, Fashion District');
    final phoneController = TextEditingController(text: '+91 98765 43210');
    final pincodeController = TextEditingController(text: '400001');
    String selectedPayment = 'UPI';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardBg,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CHECKOUT & DELIVERY',
                            style: GoogleFonts.cinzel(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Enter your shipping details below',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: _subtext,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: _subtext),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  Text(
                    'Full Name',
                    style: GoogleFonts.outfit(color: _textDark, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.outfit(color: _textDark, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. John Doe',
                      prefixIcon: const Icon(Icons.person_outline_rounded, color: _gold),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: _surfaceBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Address
                  Text(
                    'Delivery Address',
                    style: GoogleFonts.outfit(color: _textDark, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: addressController,
                    style: GoogleFonts.outfit(color: _textDark, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Street name, Apartment, Suite',
                      prefixIcon: const Icon(Icons.location_on_outlined, color: _gold),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      filled: true,
                      fillColor: _surfaceBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      // Phone
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone Number',
                              style: GoogleFonts.outfit(color: _textDark, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: phoneController,
                              style: GoogleFonts.outfit(color: _textDark, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: '+91 98765 43210',
                                prefixIcon: const Icon(Icons.phone_outlined, color: _gold),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                filled: true,
                                fillColor: _surfaceBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold, width: 1.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Pincode
                      SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PIN Code',
                              style: GoogleFonts.outfit(color: _textDark, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: pincodeController,
                              style: GoogleFonts.outfit(color: _textDark, fontSize: 14),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '400001',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                filled: true,
                                fillColor: _surfaceBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _gold, width: 1.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Payment Method Selection
                  Text(
                    'Payment Options',
                    style: GoogleFonts.outfit(color: _textDark, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      (name: 'UPI', icon: Icons.qr_code_scanner_rounded),
                      (name: 'Card', icon: Icons.credit_card_rounded),
                      (name: 'Cash on Delivery', icon: Icons.payments_outlined),
                    ].map((method) {
                      final isSelected = selectedPayment == method.name;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedPayment = method.name;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? _gold.withAlpha(20) : _surfaceBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? _gold : _border,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  method.icon,
                                  size: 20,
                                  color: isSelected ? _goldDark : _subtext,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  method.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? _goldDark : _subtext,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Final Total Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surfaceBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _gold.withAlpha(80)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Items (${widget.cartItems.length}):', style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
                            Text('₹${_rawSubtotal.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 13, color: _textDark, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        if (_discountAmount > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Promo Discount ($_appliedCoupon):', style: GoogleFonts.outfit(fontSize: 13, color: _successGreen)),
                              Text('-₹${_discountAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 13, color: _successGreen, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Shipping:', style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
                            Text('FREE', style: GoogleFonts.outfit(fontSize: 13, color: _successGreen, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(color: _border, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Payable Amount:', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark)),
                            Text(
                              '₹${_finalTotal.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: _goldDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _goldDark,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSubmittingOrder
                          ? null
                          : () async {
                              setModalState(() {
                                _isSubmittingOrder = true;
                              });

                              try {
                                final orderData = {
                                  'customer': nameController.text,
                                  'address': '${addressController.text}, Pincode: ${pincodeController.text}',
                                  'phone': phoneController.text,
                                  'paymentMethod': selectedPayment,
                                  'totalAmount': _finalTotal,
                                  'couponApplied': _appliedCoupon,
                                  'items': widget.cartItems.map((c) => {
                                    'itemId': c.item.id,
                                    'name': c.item.name,
                                    'price': c.item.price,
                                    'quantity': c.quantity,
                                    'color': c.selectedColor,
                                    'size': c.selectedSize,
                                  }).toList(),
                                };

                                final response = await http.post(
                                  Uri.parse('${ApiConfig.baseUrl}/orders'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode(orderData),
                                ).timeout(const Duration(seconds: 5));

                                debugPrint('Order response: ${response.statusCode}');
                              } catch (e) {
                                debugPrint('Order placement notice: $e');
                              }

                              if (!context.mounted) return;
                              setState(() {
                                _isSubmittingOrder = false;
                                widget.cartItems.clear();
                                _appliedCoupon = '';
                                _discountPercent = 0.0;
                              });
                              if (widget.onCartUpdated != null) widget.onCartUpdated!();

                              Navigator.pop(context);
                              _showOrderSuccessDialog();
                            },
                      child: _isSubmittingOrder
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'PLACE ORDER • ₹${_finalTotal.toStringAsFixed(0)}',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _cardBg,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _gold.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold, width: 2),
                ),
                child: const Icon(Icons.check_circle_rounded, size: 44, color: _goldDark),
              ),
              const SizedBox(height: 20),
              Text(
                'ORDER CONFIRMED',
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for your order! Your luxury VEXA garments are being prepared for dispatch.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 13, color: _subtext, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onNavigateToProducts != null) {
                      widget.onNavigateToProducts!();
                    }
                  },
                  child: Text(
                    'CONTINUE SHOPPING',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _gold.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _gold.withAlpha(80)),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: _goldDark, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHOPPING CART',
                  style: GoogleFonts.cinzel(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 2,
                    color: _textDark,
                  ),
                ),
                Text(
                  widget.cartItems.isEmpty
                      ? 'No items selected'
                      : '${widget.cartItems.length} ${widget.cartItems.length == 1 ? 'item' : 'items'} in cart',
                  style: GoogleFonts.outfit(fontSize: 11, color: _subtext),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (widget.cartItems.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: Text('Clear Cart?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    content: Text('Are you sure you want to remove all items from your cart?', style: GoogleFonts.outfit(color: _subtext)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: GoogleFonts.outfit(color: _subtext)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _errorRed),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            widget.cartItems.clear();
                            _appliedCoupon = '';
                            _discountPercent = 0.0;
                          });
                          if (widget.onCartUpdated != null) widget.onCartUpdated!();
                        },
                        child: Text('Clear All', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: _errorRed),
              label: Text('Clear', style: GoogleFonts.outfit(fontSize: 12, color: _errorRed, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.cartItems.isEmpty
          ? _buildEmptyStateView()
          : _buildPopulatedCartView(),
    );
  }

  // ── 1. EMPTY CART VIEW ───────────────────────────────────────────────────
  Widget _buildEmptyStateView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Luxury Bag Badge
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: _gold.withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold.withAlpha(120), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _goldDark.withAlpha(25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: _goldDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            Text(
              'YOUR CART IS EMPTY',
              style: GoogleFonts.cinzel(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Discover our 240 GSM heavyweight cotton drop and elevate your wardrobe with effortless style.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                color: _subtext,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Start Shopping CTA
            SizedBox(
              width: 220,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _goldDark,
                  elevation: 4,
                  shadowColor: _goldDark.withAlpha(80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (widget.onNavigateToProducts != null) {
                    widget.onNavigateToProducts!();
                  } else {
                    Navigator.pushNamed(context, '/home');
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'EXPLORE CATALOG',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Trust Badges Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTrustBadge(Icons.local_shipping_outlined, 'Free Express Shipping')),
                  Container(height: 24, width: 1, color: _border),
                  Expanded(child: _buildTrustBadge(Icons.shield_outlined, '30-Day Easy Returns')),
                  Container(height: 24, width: 1, color: _border),
                  Expanded(child: _buildTrustBadge(Icons.verified_outlined, '100% Cotton Quality')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: _goldDark),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(fontSize: 10, color: _subtext, fontWeight: FontWeight.w600, height: 1.2),
        ),
      ],
    );
  }

  // ── 2. POPULATED CART VIEW ────────────────────────────────────────────────
  Widget _buildPopulatedCartView() {
    return Column(
      children: [
        // Free Shipping Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: _gold.withAlpha(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_shipping_rounded, size: 16, color: _goldDark),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'FREE EXPRESS SHIPPING APPLIED TO YOUR ORDER',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: _goldDark,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Cart Items List + Coupon Code Box
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Items List
              ...List.generate(widget.cartItems.length, (index) {
                final cartItem = widget.cartItems[index];
                return _buildCartItemCard(cartItem, index);
              }),

              const SizedBox(height: 12),

              // Coupon / Promo Code Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer_outlined, size: 18, color: _goldDark),
                        const SizedBox(width: 8),
                        Text(
                          'Promo / Coupon Code',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark),
                        ),
                        const Spacer(),
                        Text(
                          'Try "VEXA10" or "VEXA30"',
                          style: GoogleFonts.outfit(fontSize: 11, color: _gold, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponController,
                            style: GoogleFonts.outfit(fontSize: 13, color: _textDark, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Enter code (e.g. VEXA10)',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              filled: true,
                              fillColor: _surfaceBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _gold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _appliedCoupon.isNotEmpty
                            ? OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: _errorRed),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _removeCoupon,
                                child: Text('Remove', style: GoogleFonts.outfit(fontSize: 12, color: _errorRed, fontWeight: FontWeight.bold)),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _goldDark,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _applyCoupon,
                                child: Text('Apply', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                      ],
                    ),
                    if (_couponMessage.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _couponMessage,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _couponSuccess ? _successGreen : _errorRed,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),

        // Sticky Bottom Order Summary & Checkout Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal:', style: GoogleFonts.outfit(color: _subtext, fontSize: 13)),
                    Text('₹${_rawSubtotal.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: _textDark, fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
                if (_discountAmount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Coupon Discount:', style: GoogleFonts.outfit(color: _successGreen, fontSize: 13)),
                      Text('-₹${_discountAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: _successGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Shipping:', style: GoogleFonts.outfit(color: _subtext, fontSize: 13)),
                    Text('FREE', style: GoogleFonts.outfit(color: _successGreen, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const Divider(color: _border, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Grand Total', style: GoogleFonts.cinzel(color: _textDark, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                        Text('Taxes & duties included', style: GoogleFonts.outfit(color: _subtext, fontSize: 10)),
                      ],
                    ),
                    Text(
                      '₹${_finalTotal.toStringAsFixed(0)}',
                      style: GoogleFonts.outfit(color: _goldDark, fontWeight: FontWeight.w900, fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _goldDark,
                      elevation: 3,
                      shadowColor: _goldDark.withAlpha(80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _showCheckoutDialog,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PROCEED TO CHECKOUT',
                          style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── CART ITEM CARD ───────────────────────────────────────────────────────
  Widget _buildCartItemCard(CartItemData cartItem, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _cartProductImage(
              cartItem.item.image,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),

          // Title, Variant Chips & Unit Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 6),

                // Color & Size Chips
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _surfaceBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        'Color: ${cartItem.selectedColor}',
                        style: GoogleFonts.outfit(fontSize: 10, color: _subtext, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _surfaceBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        'Size: ${cartItem.selectedSize}',
                        style: GoogleFonts.outfit(fontSize: 10, color: _subtext, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Price display
                Text(
                  '₹${cartItem.totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _goldDark,
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls & Trash Button
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Delete Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.cartItems.removeAt(index);
                  });
                  if (widget.onCartUpdated != null) widget.onCartUpdated!();
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline_rounded, color: _errorRed, size: 20),
                ),
              ),
              const SizedBox(height: 12),

              // Quantity Selector Pill
              Container(
                decoration: BoxDecoration(
                  color: _surfaceBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (cartItem.quantity > 1) {
                          setState(() {
                            cartItem.quantity--;
                          });
                          if (widget.onCartUpdated != null) widget.onCartUpdated!();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: const Icon(Icons.remove, size: 14, color: _textDark),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '${cartItem.quantity}',
                        style: GoogleFonts.outfit(
                          color: _textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          cartItem.quantity++;
                        });
                        if (widget.onCartUpdated != null) widget.onCartUpdated!();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: const Icon(Icons.add, size: 14, color: _textDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
