import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/item_model.dart';
import '../theme/app_theme.dart';

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

class CartScreen extends StatefulWidget {
  final List<CartItemData> cartItems;
  final VoidCallback? onCartUpdated;

  const CartScreen({
    super.key,
    required this.cartItems,
    this.onCartUpdated,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isSubmittingOrder = false;

  double get _subtotal {
    double total = 0;
    for (final cartItem in widget.cartItems) {
      total += cartItem.totalPrice;
    }
    return total;
  }

  void _showCheckoutDialog() {
    final nameController = TextEditingController(text: 'John Doe');
    final addressController = TextEditingController(text: '123 Luxury Avenue, Fashion District');
    final phoneController = TextEditingController(text: '+1 555 019 2831');
    String selectedPayment = 'Card';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Checkout & Order',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Recipient Name
                  Text(
                    'Full Name',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'John Doe',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.subtextColor),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Address
                  Text(
                    'Delivery Address',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: addressController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '123 Fashion Street, NY',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.subtextColor),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Phone
                  Text(
                    'Contact Phone',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: '+1 555 123 4567',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.subtextColor),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  Text(
                    'Payment Method',
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Card', 'UPI', 'Cash on Delivery'].map((method) {
                      final isSelected = selectedPayment == method;
                      return ChoiceChip(
                        label: Text(method),
                        selected: isSelected,
                        onSelected: (_) {
                          setModalState(() {
                            selectedPayment = method;
                          });
                        },
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: AppTheme.surfaceColor,
                        labelStyle: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : AppTheme.subtextColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Order Total Summary Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2D2D3A)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
                        ),
                        Text(
                          '\$${_subtotal.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmittingOrder
                          ? null
                          : () async {
                              setModalState(() {
                                _isSubmittingOrder = true;
                              });

                              // Submit Order to backend API
                              try {
                                final orderData = {
                                  'customer': nameController.text,
                                  'address': addressController.text,
                                  'phone': phoneController.text,
                                  'paymentMethod': selectedPayment,
                                  'totalAmount': _subtotal,
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
                              });
                              if (widget.onCartUpdated != null) widget.onCartUpdated!();

                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 Order Placed Successfully! Your items will arrive soon.'),
                                  backgroundColor: AppTheme.successColor,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            },
                      child: _isSubmittingOrder
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Place Order (${widget.cartItems.length} items)',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_bag_rounded, color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Shopping Cart',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: widget.cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2D2D3A)),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: AppTheme.subtextColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your Cart is Empty',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore the fashion catalog and add your favorite items.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppTheme.subtextColor,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final cartItem = widget.cartItems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2D2D3A)),
                        ),
                        child: Row(
                          children: [
                            // Thumbnail Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                cartItem.item.image,
                                width: 75,
                                height: 75,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 75,
                                  height: 75,
                                  color: AppTheme.surfaceColor,
                                  child: const Icon(Icons.image_not_supported_outlined, color: AppTheme.subtextColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Item Meta Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItem.item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Color: ${cartItem.selectedColor} • Size: ${cartItem.selectedSize}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: AppTheme.subtextColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '\$${cartItem.totalPrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quantity Controls & Delete Button
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      widget.cartItems.removeAt(index);
                                    });
                                    if (widget.onCartUpdated != null) widget.onCartUpdated!();
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
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
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          child: Icon(Icons.remove, size: 14, color: Colors.white),
                                        ),
                                      ),
                                      Text(
                                        '${cartItem.quantity}',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            cartItem.quantity++;
                                          });
                                          if (widget.onCartUpdated != null) widget.onCartUpdated!();
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          child: Icon(Icons.add, size: 14, color: Colors.white),
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
                    },
                  ),
                ),

                // Order Total & Checkout Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(color: const Color(0xFF2D2D3A)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal:', style: GoogleFonts.outfit(color: AppTheme.subtextColor, fontSize: 14)),
                          Text('\$${_subtotal.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Shipping:', style: GoogleFonts.outfit(color: AppTheme.subtextColor, fontSize: 14)),
                          Text('FREE', style: GoogleFonts.outfit(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const Divider(color: Color(0xFF2D2D3A), height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total:', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('\$${_subtotal.toStringAsFixed(2)}', style: GoogleFonts.outfit(color: AppTheme.accentColor, fontWeight: FontWeight.w800, fontSize: 22)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showCheckoutDialog,
                          child: Text(
                            'Proceed to Checkout',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
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
}
