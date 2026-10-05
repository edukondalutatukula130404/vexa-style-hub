import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/order_service.dart';
import '../services/notification_service.dart';
import '../services/websocket_service.dart';

const Color _gold = Color(0xFFB8860B);
const Color _goldDark = Color(0xFF8B6508);
const Color _textDark = Color(0xFF0F172A);
const Color _subtext = Color(0xFF64748B);
const Color _bgColor = Color(0xFFFAFAFC);
const Color _border = Color(0xFFE2E8F0);

class CustomerSupportScreen extends StatefulWidget {
  final OrderModel? order;

  const CustomerSupportScreen({super.key, this.order});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen> {
  final _messageController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCategory = 'Order Issue';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Order Issue',
    'Delivery & Tracking',
    'Returns & Exchanges',
    'Size & Fit Advice',
    'Bespoke & Custom Orders',
    'Payment & Wallet',
  ];

  final List<({String question, String answer})> _faqs = const [
    (
      question: 'How do I track my live order delivery status?',
      answer: 'You can tap "Track Order" on any active order in your My Orders tab to view real-time GPS courier movements and estimated delivery timelines.',
    ),
    (
      question: 'What is VEXA\'s return & exchange policy?',
      answer: 'We offer 7-day hassle-free returns and exchanges for all unworn luxury garments with tags intact. Instant refund is credited to your VEXA Wallet upon pickup verification.',
    ),
    (
      question: 'How does instant VEXA Wallet refund work?',
      answer: 'When an order is cancelled or returned, refund amount is instantly credited to your VEXA Pay Wallet, ready to be used for future luxury purchases.',
    ),
    (
      question: 'How do I request custom embroidery or bespoke fitting?',
      answer: 'Select "Bespoke & Custom Orders" topic or tap "Book Custom Tee" to submit your custom sleeve text, chest monogram, or tailored size preferences directly to our master tailors.',
    ),
  ];

  int? _expandedFaqIndex;

  @override
  void dispose() {
    _messageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openURL(String urlString, {required String channelName, required String contactDetail}) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _gold.withAlpha(30), shape: BoxShape.circle),
                  child: const Icon(Icons.support_agent_rounded, color: _goldDark, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(channelName, style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark)),
                      Text(contactDetail, style: GoogleFonts.outfit(fontSize: 13, color: _subtext)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Contact via VIP Desk:', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SelectableText(contactDetail, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: _goldDark)),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: _subtext, size: 20),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$channelName info copied: $contactDetail'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _goldDark,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLiveChatModal() {
    final chatMessages = <Map<String, String>>[
      {
        'sender': 'bot',
        'text': 'Welcome to VEXA VIP Concierge 🌟 How can I assist you with your order or custom garment today?',
        'time': 'Just now',
      }
    ];
    final chatInputController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setChatState) {
            void sendMessage(String text) {
              if (text.trim().isEmpty) return;
              setChatState(() {
                chatMessages.add({
                  'sender': 'user',
                  'text': text.trim(),
                  'time': 'Just now',
                });
              });
              chatInputController.clear();

              Future.delayed(const Duration(milliseconds: 900), () {
                if (!ctx.mounted) return;
                String reply = 'Our VIP concierge agent is reviewing your query. A dedicated stylist will reach out within 2 minutes!';
                final lower = text.toLowerCase();
                if (lower.contains('track') || lower.contains('order') || lower.contains('where')) {
                  reply = widget.order != null
                      ? 'Your Order ${widget.order!.id} is currently ${widget.order!.status.toUpperCase()}. Live GPS sync is active!'
                      : 'You can track all active orders under your Profile -> My Orders tab with real-time GPS sync.';
                } else if (lower.contains('refund') || lower.contains('return') || lower.contains('cancel')) {
                  reply = 'Returns and cancellations are processed instantly! Refunds are credited directly to your VEXA Pay Wallet.';
                } else if (lower.contains('size') || lower.contains('fit') || lower.contains('custom')) {
                  reply = 'Our garments use 240 GSM luxury heavyweight cotton with drop-shoulder oversized boxy fit. Order your standard size for tailored drape!';
                }

                setChatState(() {
                  chatMessages.add({
                    'sender': 'bot',
                    'text': reply,
                    'time': 'Just now',
                  });
                });
              });
            }

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(ctx).size.height * 0.75,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: const BoxDecoration(
                        color: _textDark,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: _gold.withAlpha(40), shape: BoxShape.circle),
                            child: const Icon(Icons.support_agent_rounded, color: _gold, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('VIP CONCIERGE LIVE CHAT', style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                                Row(
                                  children: [
                                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                                    const SizedBox(width: 5),
                                    Text('Online • Concierge Active', style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    // Quick Chips
                    Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      color: _bgColor,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildQuickChip('📦 Track Live Delivery', () => sendMessage('Track my live order delivery')),
                          const SizedBox(width: 8),
                          _buildQuickChip('💵 Wallet Refund Query', () => sendMessage('How does instant wallet refund work?')),
                          const SizedBox(width: 8),
                          _buildQuickChip('📏 Size & Fit Advice', () => sendMessage('Help me select correct fit and size')),
                        ],
                      ),
                    ),

                    // Messages list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: chatMessages.length,
                        itemBuilder: (c, idx) {
                          final msg = chatMessages[idx];
                          final isUser = msg['sender'] == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(c).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: isUser ? _goldDark : _bgColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(14),
                                  topRight: const Radius.circular(14),
                                  bottomLeft: Radius.circular(isUser ? 14 : 2),
                                  bottomRight: Radius.circular(isUser ? 2 : 14),
                                ),
                                border: Border.all(color: isUser ? _goldDark : _border),
                              ),
                              child: Text(
                                msg['text'] ?? '',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isUser ? Colors.white : _textDark,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Input field
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: _border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: chatInputController,
                              style: GoogleFonts.outfit(fontSize: 13, color: _textDark),
                              decoration: InputDecoration(
                                hintText: 'Type your message to VIP agent...',
                                hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: _subtext),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: _goldDark)),
                              ),
                              onSubmitted: (val) => sendMessage(val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: _goldDark,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                              onPressed: () => sendMessage(chatInputController.text),
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
        );
      },
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withAlpha(80)),
        ),
        child: Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: _goldDark)),
      ),
    );
  }

  void _submitTicket() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your query details before submitting.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final ticketId = '#VX-SUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final queryText = _messageController.text.trim();
    final phoneText = _phoneController.text.trim();

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _messageController.clear();
      _phoneController.clear();

      NotificationService.addNotification(
        title: 'Support Ticket Raised 🎫',
        body: 'Ticket $ticketId created for topic "$_selectedCategory". Our concierge team will reach out shortly.',
        icon: Icons.confirmation_number_rounded,
        color: const Color(0xFF3B82F6),
        type: 'SUPPORT_TICKET',
        context: context,
      );

      VexaWebSocketService().send('SUPPORT_TICKET_CREATED', {
        'ticketId': ticketId,
        'category': _selectedCategory,
        'query': queryText,
        'phone': phoneText,
        'orderId': widget.order?.id ?? '',
        'createdAt': DateTime.now().toIso8601String(),
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'TICKET CREATED',
                style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark),
              ),
            ],
          ),
          content: Text(
            'Your support ticket ($ticketId) has been raised successfully! Our VIP Concierge executive will contact you shortly.',
            style: GoogleFonts.outfit(fontSize: 13, color: _subtext, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _goldDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text('Done', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.headset_mic_rounded, color: _goldDark, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'CUSTOMER SUPPORT',
              style: GoogleFonts.cinzel(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: _textDark,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ORDER CONTEXT BANNER (IF ORDER PROVIDED)
              if (widget.order != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _gold.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _gold.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_rounded, color: _goldDark, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assistance for Order ${widget.order!.id.startsWith('#') ? widget.order!.id : '#${widget.order!.id}'}',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.order!.items.firstOrNull?.name ?? "Garment"} • ₹${widget.order!.totalAmount.toStringAsFixed(0)}',
                              style: GoogleFonts.outfit(fontSize: 11.5, color: _subtext),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.order!.statusColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.order!.status.toUpperCase(),
                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: widget.order!.statusColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 2. LIVE CONCIERGE CHAT PROMPT CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _gold.withAlpha(40), shape: BoxShape.circle),
                      child: const Icon(Icons.forum_rounded, color: _gold, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VIP Live Concierge Chat', style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                          const SizedBox(height: 2),
                          Text('Instant 24/7 AI & Stylist Support', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _goldDark,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _openLiveChatModal,
                      child: Text('Start Chat', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. CONTACT CHANNELS
              Row(
                children: [
                  Expanded(
                    child: _buildChannelCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'WhatsApp VIP',
                      subtitle: 'Instant Chat',
                      onTap: () => _openURL(
                        'https://wa.me/919876543210?text=Hello%20VEXA%20VIP%20Support',
                        channelName: 'WhatsApp VIP Support',
                        contactDetail: '+91 98765 43210',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildChannelCard(
                      icon: Icons.phone_in_talk_rounded,
                      iconColor: _goldDark,
                      title: 'Call Support',
                      subtitle: 'Toll-Free 24/7',
                      onTap: () => _openURL(
                        'tel:18001238392',
                        channelName: '24/7 Toll-Free VIP Helpline',
                        contactDetail: '1800-123-VEXA (+91 98765 43210)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildChannelCard(
                      icon: Icons.mail_outline_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Email Us',
                      subtitle: 'support@vexa.app',
                      onTap: () => _openURL(
                        'mailto:support@vexa.app?subject=VEXA%20Support%20Request',
                        channelName: 'Email Concierge Desk',
                        contactDetail: 'support@vexa.app',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // 4. CREATE A SUPPORT TICKET FORM
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RAISE A SUPPORT TICKET',
                      style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select category and tell us how we can assist you.',
                      style: GoogleFonts.outfit(fontSize: 12, color: _subtext),
                    ),
                    const SizedBox(height: 16),

                    // Category dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      style: GoogleFonts.outfit(color: _textDark, fontSize: 13, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Select Topic',
                        labelStyle: GoogleFonts.outfit(color: _subtext),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _goldDark, width: 1.5),
                        ),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Phone input
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.outfit(fontSize: 13, color: _textDark),
                      decoration: InputDecoration(
                        labelText: 'Callback Phone / WhatsApp Number',
                        labelStyle: GoogleFonts.outfit(fontSize: 12, color: _subtext),
                        prefixIcon: const Icon(Icons.phone_outlined, color: _goldDark, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _goldDark, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Query message input
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      style: GoogleFonts.outfit(fontSize: 13, color: _textDark),
                      decoration: InputDecoration(
                        hintText: 'Describe your issue or custom request in detail...',
                        hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: _subtext),
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _goldDark, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _goldDark,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSubmitting ? null : _submitTicket,
                        child: _isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                'SUBMIT SUPPORT TICKET',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // 5. FREQUENTLY ASKED QUESTIONS
              Text(
                'FREQUENTLY ASKED QUESTIONS',
                style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              ...List.generate(_faqs.length, (idx) {
                final faq = _faqs[idx];
                final isExpanded = _expandedFaqIndex == idx;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: isExpanded ? _gold : _border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: Key('faq_$idx'),
                        initiallyExpanded: isExpanded,
                        onExpansionChanged: (exp) {
                          setState(() {
                            _expandedFaqIndex = exp ? idx : null;
                          });
                        },
                        iconColor: _goldDark,
                        collapsedIconColor: _subtext,
                        title: Text(
                          faq.question,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: isExpanded ? FontWeight.bold : FontWeight.w600,
                            color: isExpanded ? _goldDark : _textDark,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            child: Text(
                              faq.answer,
                              style: GoogleFonts.outfit(fontSize: 12, color: _subtext, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: _textDark),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 10, color: _subtext),
            ),
          ],
        ),
      ),
    );
  }
}
