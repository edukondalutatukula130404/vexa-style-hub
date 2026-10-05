import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../widgets/vexa_empty_state.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';

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
  final VoidCallback? onNavigateToOrders;

  const CartScreen({
    super.key,
    required this.cartItems,
    this.onCartUpdated,
    this.onNavigateToProducts,
    this.onNavigateToOrders,
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

  Future<void> _showCheckoutDialog() async {
    final loggedInUser = await AuthService.getUser();
    final isGuest = loggedInUser == null || loggedInUser.id == 'guest_user';

    if (isGuest) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please sign in to proceed with checkout.',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: _goldDark,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    final nameController = TextEditingController(text: loggedInUser.name.isNotEmpty ? loggedInUser.name : 'John Doe');
    final addressController = TextEditingController(text: '123 Luxury Avenue, Fashion District');
    final phoneController = TextEditingController(text: '+91 98765 43210');
    final pincodeController = TextEditingController(text: '400001');

    String selectedPayment = 'Razorpay Online Payment (UPI, Cards, NetBanking, Wallets)';

    String selectedSavedAddress = 'home'; // 'home' | 'work' | 'custom'
    String selectedDeliverySpeed = 'express'; // 'express' | 'standard'
    String selectedInstruction = 'Leave at Door';

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _bgColor,
      elevation: 20,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.92,
            child: Column(
              children: [
                // ── 1. STICKY TOP HEADER WITH PROGRESS STEPS ─────────────────────────
                Container(
                  padding: const EdgeInsets.only(top: 16, bottom: 14, left: 20, right: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag indicator handle bar
                      Center(
                        child: Container(
                          width: 42,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: _border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _gold.withAlpha(25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.local_shipping_outlined, color: _goldDark, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'CHECKOUT & DELIVERY',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cinzel(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                          color: _textDark,
                                        ),
                                      ),
                                      Text(
                                        'Fast Doorstep Shipping & Secure Checkout',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: _subtext,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0C2340),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lock_rounded, color: Color(0xFFFFD700), size: 11),
                                    const SizedBox(width: 4),
                                    Text(
                                      '256-Bit SSL',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: _textDark, size: 22),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 2. SCROLLABLE FORM BODY ─────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── SECTION A: SAVED ADDRESS QUICK SELECT ────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '1. Select Shipping Address',
                              style: GoogleFonts.outfit(color: _textDark, fontSize: 13.5, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Saved Locations',
                              style: GoogleFonts.outfit(color: _goldDark, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            (id: 'home', label: '🏠 Home (Default)', name: 'John Doe', addr: '123 Luxury Avenue, Fashion District', phone: '+91 98765 43210', pin: '400001'),
                            (id: 'work', label: '🏢 Work', name: 'John Doe (Office)', addr: 'Corporate Tower B, Financial Center', phone: '+91 98765 11223', pin: '400051'),
                          ].map((savedAddr) {
                            final isSelected = selectedSavedAddress == savedAddr.id;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    selectedSavedAddress = savedAddr.id;
                                    nameController.text = savedAddr.name;
                                    addressController.text = savedAddr.addr;
                                    phoneController.text = savedAddr.phone;
                                    pincodeController.text = savedAddr.pin;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _gold.withAlpha(20) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? _goldDark : _border,
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            savedAddr.label,
                                            style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: _textDark),
                                          ),
                                          if (isSelected)
                                            const Icon(Icons.check_circle_rounded, color: _goldDark, size: 14),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        savedAddr.addr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(fontSize: 10.5, color: _subtext),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 14),

                        // Input fields
                        Text('Full Name', style: GoogleFonts.outfit(color: _textDark, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: nameController,
                          style: GoogleFonts.outfit(color: _textDark, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. John Doe',
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: _goldDark, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _goldDark, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text('Delivery Address', style: GoogleFonts.outfit(color: _textDark, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: addressController,
                          style: GoogleFonts.outfit(color: _textDark, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Street name, Apartment, Suite',
                            prefixIcon: const Icon(Icons.location_on_outlined, color: _goldDark, size: 20),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _goldDark, width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Phone Number', style: GoogleFonts.outfit(color: _textDark, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: phoneController,
                                    style: GoogleFonts.outfit(color: _textDark, fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: '+91 98765 43210',
                                      prefixIcon: const Icon(Icons.phone_outlined, color: _goldDark, size: 20),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _goldDark, width: 1.5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('PIN Code', style: GoogleFonts.outfit(color: _textDark, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: pincodeController,
                                    style: GoogleFonts.outfit(color: _textDark, fontSize: 14),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: '400001',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _goldDark, width: 1.5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── SECTION B: DELIVERY SPEED & INSTRUCTIONS ─────────────────
                        Text(
                          '2. Delivery Speed & Preference',
                          style: GoogleFonts.outfit(color: _textDark, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            (id: 'express', title: '⚡ Express Priority', subtitle: 'Tomorrow, 5 PM', fee: 'FREE'),
                            (id: 'standard', title: '🚚 Standard Ground', subtitle: 'In 3-4 Business Days', fee: 'FREE'),
                          ].map((speed) {
                            final isSel = selectedDeliverySpeed == speed.id;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => selectedDeliverySpeed = speed.id),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSel ? _gold.withAlpha(20) : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: isSel ? _goldDark : _border, width: isSel ? 1.5 : 1.0),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(speed.title, style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: _textDark)),
                                          Icon(isSel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: isSel ? _goldDark : _subtext),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(speed.subtitle, style: GoogleFonts.outfit(fontSize: 10.5, color: _subtext)),
                                      const SizedBox(height: 4),
                                      Text(speed.fee, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _successGreen)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: ['🚪 Leave at Door', '📞 Call First', '🔔 Don\'t Ring Bell'].map((inst) {
                            final isSel = selectedInstruction == inst;
                            return ChoiceChip(
                              label: Text(inst, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: isSel ? Colors.white : _textDark)),
                              selected: isSel,
                              selectedColor: _goldDark,
                              backgroundColor: Colors.white,
                              side: BorderSide(color: isSel ? _goldDark : _border),
                              onSelected: (_) => setModalState(() => selectedInstruction = inst),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),

                        // ── SECTION C: PAYMENT METHOD SELECTION ─────────────────────
                        Text(
                          '3. Select Payment Method',
                          style: GoogleFonts.outfit(color: _textDark, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        // Payment Cards
                        Column(
                          children: [
                            // 1. Razorpay
                            GestureDetector(
                              onTap: () => setModalState(() => selectedPayment = 'Razorpay Online Payment (UPI, Cards, NetBanking, Wallets)'),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selectedPayment.contains('Razorpay') ? const Color(0xFF0C2340).withAlpha(12) : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selectedPayment.contains('Razorpay') ? const Color(0xFF0C2340) : _border,
                                    width: selectedPayment.contains('Razorpay') ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0C2340),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.bolt_rounded, color: Color(0xFFFFD700), size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text('Razorpay Online Payment', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(color: _successGreen, borderRadius: BorderRadius.circular(4)),
                                                child: Text('OFFICIAL', style: GoogleFonts.outfit(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text('UPI, Cards, NetBanking & Wallets', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      selectedPayment.contains('Razorpay') ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      color: selectedPayment.contains('Razorpay') ? const Color(0xFF0C2340) : _subtext,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),



                            // 3. COD
                            GestureDetector(
                              onTap: () => setModalState(() => selectedPayment = 'Cash on Delivery'),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: selectedPayment == 'Cash on Delivery' ? Colors.white : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selectedPayment == 'Cash on Delivery' ? _textDark : _border,
                                    width: selectedPayment == 'Cash on Delivery' ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _textDark,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.payments_outlined, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Cash on Delivery (COD)', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                                          const SizedBox(height: 2),
                                          Text('Pay in cash upon doorstep delivery', style: GoogleFonts.outfit(fontSize: 11, color: _subtext)),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      selectedPayment == 'Cash on Delivery' ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                      color: selectedPayment == 'Cash on Delivery' ? _textDark : _subtext,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── SECTION D: ORDER BILL BREAKDOWN SUMMARY ───────────────────
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order Bill Details', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark)),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Items Subtotal (${widget.cartItems.length}):', style: GoogleFonts.outfit(fontSize: 12.5, color: _subtext)),
                                  Text('₹${_rawSubtotal.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 12.5, color: _textDark, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              if (_discountAmount > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Promo Discount ($_appliedCoupon):', style: GoogleFonts.outfit(fontSize: 12.5, color: _successGreen)),
                                    Text('-₹${_discountAmount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 12.5, color: _successGreen, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Delivery & Handing:', style: GoogleFonts.outfit(fontSize: 12.5, color: _subtext)),
                                  Text('FREE', style: GoogleFonts.outfit(fontSize: 12.5, color: _successGreen, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(color: _border, height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total Payable Amount:', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _textDark)),
                                  Text(
                                    '₹${_finalTotal.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
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
                      ],
                    ),
                  ),
                ),

                // ── 3. STICKY BOTTOM ACTION BAR ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -3)),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedPayment.contains('Razorpay') ? const Color(0xFF0C2340) : _goldDark,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSubmittingOrder
                            ? null
                            : () {
                                if (selectedPayment.contains('Razorpay')) {
                                  // Launch Realtime Razorpay Gateway Flow
                                  _showRazorpayGatewayModal(
                                    amount: _finalTotal,
                                    channel: 'upi',
                                    subChoice: 'Razorpay Online (UPI/Cards/Netbanking)',
                                    customerName: nameController.text,
                                    customerPhone: phoneController.text,
                                    onPaymentSuccess: (String methodLabel) async {
                                      final orderItems = widget.cartItems.map((c) => OrderItem(
                                        itemId: c.item.id,
                                        name: c.item.name,
                                        price: c.item.price,
                                        quantity: c.quantity,
                                        color: c.selectedColor,
                                        size: c.selectedSize,
                                        image: c.item.image,
                                      )).toList();

                                      final currentUser = await AuthService.getUser();
                                      final placedOrder = await OrderService.createOrder(
                                        customerName: nameController.text.isNotEmpty ? nameController.text : (currentUser?.name ?? 'Valued Customer'),
                                        shippingAddress: '${addressController.text}, Pincode: ${pincodeController.text}',
                                        phone: phoneController.text,
                                        paymentMethod: methodLabel,
                                        totalAmount: _finalTotal,
                                        couponApplied: _appliedCoupon,
                                        items: orderItems,
                                        email: currentUser?.email,
                                        context: mounted ? context : null,
                                      );

                                      if (!context.mounted) return;
                                      setState(() {
                                        widget.cartItems.clear();
                                        _appliedCoupon = '';
                                        _discountPercent = 0.0;
                                      });
                                      if (widget.onCartUpdated != null) widget.onCartUpdated!();

                                      Navigator.pop(context);
                                      _showOrderSuccessDialog(placedOrder);
                                    },
                                  );
                                } else {
                                  // Standard Wallet / COD flow
                                  setModalState(() {
                                    _isSubmittingOrder = true;
                                  });

                                  Future.microtask(() async {
                                    final orderItems = widget.cartItems.map((c) => OrderItem(
                                      itemId: c.item.id,
                                      name: c.item.name,
                                      price: c.item.price,
                                      quantity: c.quantity,
                                      color: c.selectedColor,
                                      size: c.selectedSize,
                                      image: c.item.image,
                                    )).toList();

                                    final placedOrder = await OrderService.createOrder(
                                      customerName: nameController.text,
                                      shippingAddress: '${addressController.text}, Pincode: ${pincodeController.text}',
                                      phone: phoneController.text,
                                      paymentMethod: selectedPayment,
                                      totalAmount: _finalTotal,
                                      couponApplied: _appliedCoupon,
                                      items: orderItems,
                                    );

                                    if (!context.mounted) return;
                                    setState(() {
                                      _isSubmittingOrder = false;
                                      widget.cartItems.clear();
                                      _appliedCoupon = '';
                                      _discountPercent = 0.0;
                                    });
                                    if (widget.onCartUpdated != null) widget.onCartUpdated!();

                                    Navigator.pop(context);
                                    _showOrderSuccessDialog(placedOrder);
                                  });
                                }
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
                                  Icon(
                                    selectedPayment.contains('Razorpay') ? Icons.bolt_rounded : Icons.lock_outline_rounded,
                                    color: selectedPayment.contains('Razorpay') ? const Color(0xFFFFD700) : Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    selectedPayment.contains('Razorpay')
                                        ? 'PAY VIA RAZORPAY • ₹${_finalTotal.toStringAsFixed(0)}'
                                        : 'PLACE ORDER • ₹${_finalTotal.toStringAsFixed(0)}',
                                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white),
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
        },
      ),
    );
  }

  // ── RAZORPAY LIVE PAYMENT GATEWAY FULL-SCREEN VIEW (EXACT WEB & BANK FLOW REPLICA) ──
  void _showRazorpayGatewayModal({
    required double amount,
    required String channel, // 'upi', 'card', 'netbanking', 'wallet'
    required String subChoice,
    required String customerName,
    required String customerPhone,
    required Function(String methodLabel) onPaymentSuccess,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageCtx) {
          int step = 0; // 0: Payment Options, 1: Loading Bank Page, 2: Demo Bank Gateway, 3: Confirming Payment, 4: Payment Successful Green Screen
          String selectedBankName = 'Razorpay Software Private Ltd';
          String activeCategory = channel == 'card'
              ? 'Cards'
              : channel == 'netbanking'
                  ? 'Netbanking'
                  : channel == 'wallet'
                      ? 'Wallet'
                      : 'Recommended';

          String razorpayOrderId = '';
          String currentPaymentId = 'pay_${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';

          // Countdown timer state (11:54 dynamic countdown)
          int timerSeconds = 714; // 11 min 54 sec
          Timer? countTimer;

          // Controllers for Card details
          final cardNumberCtrl = TextEditingController(text: '4532 8892 1092 8892');
          final cardExpiryCtrl = TextEditingController(text: '12/28');
          final cardCvvCtrl = TextEditingController(text: '778');
          final cardHolderCtrl = TextEditingController(text: customerName.isNotEmpty ? customerName : 'John Doe');

          return PopScope(
            onPopInvokedWithResult: (didPop, result) {
              countTimer?.cancel();
            },
            child: Scaffold(
              backgroundColor: step == 4 ? const Color(0xFF00A859) : const Color(0xFFD8B475),
              body: SafeArea(
                top: true,
                bottom: true,
                child: StatefulBuilder(
                  builder: (ctx, setGateState) {
                    // Start countdown timer if not already running
                    countTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
                      if (pageCtx.mounted) {
                        if (timerSeconds > 0) {
                          setGateState(() {
                            timerSeconds--;
                          });
                        } else {
                          t.cancel();
                        }
                      } else {
                        t.cancel();
                      }
                    });
                  // Trigger Razorpay Order Creation via backend on launch
                  if (razorpayOrderId.isEmpty) {
                    ApiService.createRazorpayOrder(amount: amount).then((res) {
                      if (res['order'] != null && res['order']['id'] != null) {
                        razorpayOrderId = res['order']['id'].toString();
                      } else {
                        razorpayOrderId = 'order_rzp_${DateTime.now().millisecondsSinceEpoch}';
                      }
                    });
                  }

                  void startBankFlow(String bankName) {
                    setGateState(() {
                      selectedBankName = bankName;
                      step = 1; // Step 1: Loading bank page...
                    });

                    // Automatically transition from Step 1 -> Step 2 after 1.2s
                    Future.delayed(const Duration(milliseconds: 1200), () {
                      if (pageCtx.mounted && step == 1) {
                        setGateState(() {
                          step = 2; // Step 2: Demo Bank Redirection Page
                        });
                      }
                    });
                  }

                  void handleBankSuccess() {
                    setGateState(() {
                      step = 3; // Step 3: Confirming Payment...
                    });

                    Future.delayed(const Duration(milliseconds: 1400), () async {
                      final sig = 'sig_${DateTime.now().millisecondsSinceEpoch}';
                      await ApiService.verifyRazorpayPayment(
                        razorpayOrderId: razorpayOrderId.isNotEmpty ? razorpayOrderId : 'order_rzp_mock',
                        razorpayPaymentId: currentPaymentId,
                        razorpaySignature: sig,
                      );

                      if (pageCtx.mounted) {
                        setGateState(() {
                          step = 4; // Step 4: Payment Successful Green Screen
                        });

                        // Automatically finish and trigger order completion after 2.8 seconds
                        Future.delayed(const Duration(milliseconds: 2800), () {
                          if (pageCtx.mounted) {
                            Navigator.pop(pageCtx);
                            onPaymentSuccess('Razorpay NetBanking ($selectedBankName)');
                          }
                        });
                      }
                    });
                  }

                  void handleBankFailure() {
                    setGateState(() {
                      step = 0; // Return to payment options
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment cancelled at $selectedBankName demo bank page.', style: GoogleFonts.outfit(color: Colors.white)),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                  }

                  final timerMinutes = (timerSeconds ~/ 60).toString().padLeft(2, '0');
                  final timerRemainingSecs = (timerSeconds % 60).toString().padLeft(2, '0');
                  final timerString = '$timerMinutes:$timerRemainingSecs';

                  // ── STEP 4: PAYMENT SUCCESSFUL GREEN SCREEN (IMAGE 4) ────────────────
                  if (step == 4) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFF00A859),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          Text(
                            'You will be redirected in 3 seconds',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Payment Successful',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.check_circle_rounded, size: 76, color: Color(0xFF00A859)),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // White Receipt Card (Image 4)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 12)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('VEXA - Wear Confidence', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                    Text('₹${amount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sep 23, 2026, 10:18 AM',
                                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: Color(0xFFE2E8F0), height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text('Netbanking', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
                                    const SizedBox(width: 8),
                                    Text('|', style: GoogleFonts.outfit(color: const Color(0xFFCBD5E1))),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        currentPaymentId,
                                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF64748B)),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Visit razorpay.com/support for queries',
                                      style: GoogleFonts.outfit(fontSize: 10.5, color: const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Bottom Secured by Razorpay
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Secured by ', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
                              Text('Razorpay', style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    );
                  }

                  // ── STEP 1: LOADING BANK PAGE... (IMAGE 1) ──────────────────────
                  if (step == 1) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFFD8B475).withAlpha(230),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 380),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 16)],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAF8F5),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.image_outlined, size: 16, color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text('VEXA - Wear Co...', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('PAYING', style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8))),
                                      Text('₹${amount.toStringAsFixed(0)}', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(color: Color(0xFFE2E8F0), height: 1),
                              const SizedBox(height: 28),

                              Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Loading bank page...',
                                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Please wait while we redirect you to your bank page.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              const Divider(color: Color(0xFFE2E8F0), height: 1),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Secured by ', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11)),
                                  Text('Razorpay', style: GoogleFonts.outfit(color: const Color(0xFF0C2340), fontSize: 12, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // ── STEP 2: DEMO BANK REDIRECTION PAGE ────────────────────────
                  if (step == 2) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.white,
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Bank Logo Badge Icon (Blue 1 Icon from Image 2)
                                  Text(
                                    '1',
                                    style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, color: const Color(0xFF3B82F6)),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Welcome to $selectedBankName Demo Bank',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'This is just a demo bank page.\nYou can choose whether to make this payment successful or not:',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B), height: 1.4),
                                  ),
                                  const SizedBox(height: 28),

                                  // Success / Failure Action Buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 130,
                                        height: 46,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF27AE60),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                            padding: EdgeInsets.zero,
                                            alignment: Alignment.center,
                                          ),
                                          onPressed: handleBankSuccess,
                                          child: Center(
                                            child: Text(
                                              'Success',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                height: 1.1,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 130,
                                        height: 46,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFE74C3C),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                            padding: EdgeInsets.zero,
                                            alignment: Alignment.center,
                                          ),
                                          onPressed: handleBankFailure,
                                          child: Center(
                                            child: Text(
                                              'Failure',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                height: 1.1,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
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
                    );
                  }

                  // ── STEP 3: CONFIRMING PAYMENT (IMAGE 3) ───────────────────────
                  if (step == 3) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: const Color(0xFFD8B475).withAlpha(230),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 380),
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 16)],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Confirming Payment',
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'This will only take a few seconds.',
                                style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 28),

                              // Animated Gold Coin Graphic (Image 3)
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withAlpha(40),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFD700),
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: Color(0xFFB8860B), blurRadius: 8)],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              const Divider(color: Color(0xFFE2E8F0), height: 1),
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Secured by ', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11)),
                                  Text('Razorpay', style: GoogleFonts.outfit(color: const Color(0xFF0C2340), fontSize: 12, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // ── STEP 0: INITIAL PAYMENT OPTIONS SELECTION VIEW ─────────────
                  return Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // ── 1. TOP GOLD/BRONZE SUMMARY PANEL WITH TEST MODE BANNER ──
                        Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFD8B475),
                                    Color(0xFFC5A059),
                                    Color(0xFF9E7B3B),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withAlpha(50),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withAlpha(120)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'V',
                                            style: GoogleFonts.cinzel(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'VEXA - Wear Confidence',
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(235),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6)],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Price Summary',
                                          style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 10.5, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${amount.toStringAsFixed(0)}',
                                          style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 22),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(220),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.person_outline_rounded, size: 15, color: Color(0xFF475569)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Using as ${customerPhone.isNotEmpty ? customerPhone : "+91 93461 57714"}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded, size: 15, color: Color(0xFF475569)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text('Secured by ', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500)),
                                      Text('Razorpay', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 14,
                              right: -30,
                              child: Transform.rotate(
                                angle: 0.785,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 3.5),
                                  color: const Color(0xFFDC2626),
                                  child: Text(
                                    'Test Mode',
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ── 2. RIGHT PAYMENT OPTIONS MENU & DETAILS AREA ─────────────
                        Expanded(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Payment Options', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                    Row(
                                      children: [
                                        const Icon(Icons.more_horiz_rounded, color: Color(0xFF64748B), size: 20),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A), size: 20),
                                          onPressed: () => Navigator.pop(pageCtx),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Color(0xFFE2E8F0)),

                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Categories Sidebar
                                    Container(
                                      width: 125,
                                      color: const Color(0xFFFAF8F5),
                                      child: ListView(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        children: [
                                          (id: 'Recommended', label: 'Recommended', sub: 'Mobikwik, PayZapp', icon: Icons.star_rounded),
                                          (id: 'UPI', label: 'UPI', sub: 'GPay, PhonePe', icon: Icons.qr_code_scanner_rounded),
                                          (id: 'Cards', label: 'Cards', sub: 'Visa, Mastercard', icon: Icons.credit_card_rounded),
                                          (id: 'EMI', label: 'EMI', sub: 'Axis, HDFC, ICICI', icon: Icons.account_balance_rounded),
                                          (id: 'Netbanking', label: 'Netbanking', sub: 'HDFC, ICICI, SBI', icon: Icons.account_balance_rounded),
                                          (id: 'Wallet', label: 'Wallet', sub: 'Mobikwik, Paytm', icon: Icons.account_balance_wallet_rounded),
                                        ].map((cat) {
                                          final isCatSel = activeCategory == cat.id;
                                          return GestureDetector(
                                            onTap: () => setGateState(() => activeCategory = cat.id),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: isCatSel ? Colors.white : Colors.transparent,
                                                border: Border(
                                                  left: BorderSide(
                                                    color: isCatSel ? const Color(0xFFC5A059) : Colors.transparent,
                                                    width: 3.5,
                                                  ),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    cat.label,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12.5,
                                                      fontWeight: isCatSel ? FontWeight.bold : FontWeight.w600,
                                                      color: isCatSel ? const Color(0xFF0F172A) : const Color(0xFF475569),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  Text(
                                                    cat.sub,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.outfit(fontSize: 8.8, color: const Color(0xFF94A3B8)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),

                                    // Details Panel Area
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (activeCategory == 'Recommended' || activeCategory == 'UPI') ...[
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('UPI QR', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF64748B)),
                                                      const SizedBox(width: 4),
                                                      Text(timerString, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),

                                              Center(
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFAF8F5),
                                                    borderRadius: BorderRadius.circular(14),
                                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(8),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(color: const Color(0xFFCBD5E1)),
                                                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
                                                        ),
                                                        child: const Icon(Icons.qr_code_2_rounded, size: 105, color: Color(0xFF0F172A)),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text('Scan the QR using any UPI App', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          _buildMiniAppBadge('GPay', const Color(0xFF4285F4)),
                                                          _buildMiniAppBadge('PhonePe', const Color(0xFF5F259F)),
                                                          _buildMiniAppBadge('Paytm', const Color(0xFF00BAF2)),
                                                          _buildMiniAppBadge('CRED', const Color(0xFF121212)),
                                                          _buildMiniAppBadge('BHIM', const Color(0xFFF15A24)),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 14),

                                              Text('Recommended', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                              const SizedBox(height: 8),

                                              _buildBankListItem('Punjab National Bank - Retail Banking', () {
                                                startBankFlow('Punjab National Bank');
                                              }),
                                              const SizedBox(height: 6),
                                              _buildBankListItem('Canara Bank Netbanking', () {
                                                startBankFlow('Canara Bank');
                                              }),
                                              const SizedBox(height: 14),

                                              Text('Pay via Mobikwik, PayZapp, Airtel Money & Wallets', style: GoogleFonts.outfit(fontSize: 11.0, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                              const SizedBox(height: 8),
                                              GestureDetector(
                                                onTap: () => setGateState(() => activeCategory = 'Wallet'),
                                                child: Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFFB8860B)),
                                                      const SizedBox(width: 10),
                                                      Text('Wallet', style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                                      const Spacer(),
                                                      const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF64748B)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ] else if (activeCategory == 'Cards') ...[
                                              Text('Debit / Credit Card Checkout', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                              const SizedBox(height: 10),
                                              TextField(
                                                controller: cardHolderCtrl,
                                                style: GoogleFonts.outfit(fontSize: 13),
                                                decoration: InputDecoration(
                                                  labelText: 'Cardholder Name',
                                                  filled: true,
                                                  fillColor: const Color(0xFFF8FAFC),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              TextField(
                                                controller: cardNumberCtrl,
                                                style: GoogleFonts.outfit(fontSize: 13),
                                                decoration: InputDecoration(
                                                  labelText: 'Card Number',
                                                  prefixIcon: const Icon(Icons.credit_card_rounded, color: Color(0xFFB8860B)),
                                                  filled: true,
                                                  fillColor: const Color(0xFFF8FAFC),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      controller: cardExpiryCtrl,
                                                      style: GoogleFonts.outfit(fontSize: 13),
                                                      decoration: InputDecoration(
                                                        labelText: 'Expiry (MM/YY)',
                                                        filled: true,
                                                        fillColor: const Color(0xFFF8FAFC),
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  SizedBox(
                                                    width: 90,
                                                    child: TextField(
                                                      controller: cardCvvCtrl,
                                                      obscureText: true,
                                                      style: GoogleFonts.outfit(fontSize: 13),
                                                      decoration: InputDecoration(
                                                        labelText: 'CVV',
                                                        filled: true,
                                                        fillColor: const Color(0xFFF8FAFC),
                                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              SizedBox(
                                                width: double.infinity,
                                                height: 46,
                                                child: ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0C2340)),
                                                  onPressed: () {
                                                    final cleaned = cardNumberCtrl.text.replaceAll(' ', '');
                                                    final last4 = cleaned.length >= 4 ? cleaned.substring(cleaned.length - 4) : '8892';
                                                    startBankFlow('Visa Card ($last4)');
                                                  },
                                                  child: Text('PAY ₹${amount.toStringAsFixed(0)}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            ] else if (activeCategory == 'Netbanking') ...[
                                              Text('Select Bank', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                              const SizedBox(height: 10),
                                              ...['Punjab National Bank', 'Canara Bank', 'State Bank of India', 'HDFC Bank', 'ICICI Bank', 'Axis Bank'].map((b) => Padding(
                                                padding: const EdgeInsets.only(bottom: 6),
                                                child: _buildBankListItem(b, () {
                                                  startBankFlow(b);
                                                }),
                                              )),
                                            ] else if (activeCategory == 'Wallet') ...[
                                              Text('Select Mobile Wallet', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                              const SizedBox(height: 10),
                                              ...['Mobikwik Wallet', 'PayZapp Wallet', 'Airtel Money Wallet', 'Paytm Wallet'].map((w) => Padding(
                                                padding: const EdgeInsets.only(bottom: 6),
                                                child: _buildBankListItem(w, () {
                                                  startBankFlow(w);
                                                }),
                                              )),
                                            ] else if (activeCategory == 'EMI') ...[
                                              Text('Select EMI Bank Plan', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                              const SizedBox(height: 10),
                                              ...['HDFC Bank No-Cost EMI (3 Mos)', 'ICICI Bank Easy EMI (6 Mos)', 'Axis Bank Standard EMI (12 Mos)'].map((emi) => Padding(
                                                padding: const EdgeInsets.only(bottom: 6),
                                                child: _buildBankListItem(emi, () {
                                                  startBankFlow(emi);
                                                }),
                                              )),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
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
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildMiniAppBadge(String label, Color bg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildBankListItem(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: const Color(0xFFFAF8F5), borderRadius: BorderRadius.circular(6)),
              child: const Icon(Icons.account_balance_rounded, size: 15, color: Color(0xFFC5A059)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }




  void _showOrderSuccessDialog(OrderModel order) {
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
              const SizedBox(height: 16),
              Text(
                'ORDER CONFIRMED',
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _gold.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withAlpha(80)),
                ),
                child: Text(
                  'Order Number: ${order.id}',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _goldDark),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thank you ${order.customerName}! Your order for ₹${order.totalAmount.toStringAsFixed(0)} (${order.paymentMethod}) has been registered and is being prepared for dispatch.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 12, color: _subtext, height: 1.4),
              ),
              const SizedBox(height: 20),
              // View My Orders Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    if (widget.onNavigateToOrders != null) {
                      widget.onNavigateToOrders!();
                    } else {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      OrderService.notifyOrdersChanged();
                    }
                  },
                  icon: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18),
                  label: Text(
                    'VIEW MY ORDERS',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Continue Shopping Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: _border),
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
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: _textDark),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
        actions: const [],
      ),
      body: widget.cartItems.isEmpty
          ? _buildEmptyStateView()
          : _buildPopulatedCartView(),
    );
  }

  // ── 1. EMPTY CART VIEW ───────────────────────────────────────────────────
  Widget _buildEmptyStateView() {
    return VexaEmptyState.cart(
      onStartShopping: () {
        if (widget.onNavigateToProducts != null) {
          widget.onNavigateToProducts!();
        } else {
          Navigator.pushNamed(context, '/home');
        }
      },
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

  void _navigateToProductDetail(ItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          item: item,
          onAddToCart: (pItem, color, size, qty) {
            final existingIndex = widget.cartItems.indexWhere(
              (c) => c.item.id == pItem.id && c.selectedColor == color && c.selectedSize == size,
            );
            if (existingIndex >= 0) {
              setState(() {
                widget.cartItems[existingIndex].quantity += qty;
              });
            } else {
              setState(() {
                widget.cartItems.add(CartItemData(
                  item: pItem,
                  selectedColor: color,
                  selectedSize: size,
                  quantity: qty,
                ));
              });
            }
            if (widget.onCartUpdated != null) widget.onCartUpdated!();
          },
        ),
      ),
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
          // Image Thumbnail (Tapping opens Product Detail)
          GestureDetector(
            onTap: () => _navigateToProductDetail(cartItem.item),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _cartProductImage(
                cartItem.item.image,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title, Variant Chips & Unit Price (Tapping opens Product Detail)
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToProductDetail(cartItem.item),
              behavior: HitTestBehavior.opaque,
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
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        constraints: const BoxConstraints(maxWidth: 150),
                        decoration: BoxDecoration(
                          color: _surfaceBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _border),
                        ),
                        child: Text(
                          'Color: ${cartItem.selectedColor}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 10, color: _subtext, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _surfaceBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _border),
                        ),
                        child: Text(
                          'Size: ${cartItem.selectedSize}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                        setState(() {
                          if (cartItem.quantity > 1) {
                            cartItem.quantity--;
                          } else {
                            widget.cartItems.remove(cartItem);
                          }
                        });
                        if (widget.onCartUpdated != null) widget.onCartUpdated!();
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
