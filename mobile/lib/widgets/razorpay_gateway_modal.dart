import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class RazorpayGatewayModal {
  static void show({
    required BuildContext context,
    required double amount,
    String channel = 'upi', // 'upi', 'card', 'netbanking', 'wallet'
    String subChoice = 'Razorpay Online (UPI/Cards/Netbanking)',
    required String customerName,
    required String customerPhone,
    required Function(String methodLabel) onPaymentSuccess,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (pageCtx) {
          int step = 0; // 0: Options, 1: Loading Bank, 2: Demo Bank, 3: Confirming, 4: Success
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
          int timerSeconds = 714;
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
                        step = 1;
                      });

                      Future.delayed(const Duration(milliseconds: 1200), () {
                        if (pageCtx.mounted && step == 1) {
                          setGateState(() {
                            step = 2;
                          });
                        }
                      });
                    }

                    void handleBankSuccess() {
                      setGateState(() {
                        step = 3;
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
                            step = 4;
                          });

                          Future.delayed(const Duration(milliseconds: 2800), () {
                            if (pageCtx.mounted) {
                              Navigator.pop(pageCtx);
                              onPaymentSuccess('Razorpay Online ($selectedBankName)');
                            }
                          });
                        }
                      });
                    }

                    void handleBankFailure() {
                      setGateState(() {
                        step = 0;
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

                    // ── STEP 4: PAYMENT SUCCESSFUL GREEN SCREEN ────────────────
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
                                      Text('Razorpay Online', style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B))),
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

                    // ── STEP 1: LOADING BANK PAGE... ──────────────────────
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

                    // ── STEP 3: CONFIRMING PAYMENT ───────────────────────
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
                                              'Using as ${customerPhone.isNotEmpty ? customerPhone : "+91 98765 43210"}',
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
                                                            _buildMiniBadge('GPay', const Color(0xFF4285F4)),
                                                            _buildMiniBadge('PhonePe', const Color(0xFF5F259F)),
                                                            _buildMiniBadge('Paytm', const Color(0xFF00BAF2)),
                                                            _buildMiniBadge('CRED', const Color(0xFF121212)),
                                                            _buildMiniBadge('BHIM', const Color(0xFFF15A24)),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 14),

                                                Text('Recommended', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                                const SizedBox(height: 8),

                                                _buildBankItem('Punjab National Bank - Retail Banking', () {
                                                  startBankFlow('Punjab National Bank');
                                                }),
                                                const SizedBox(height: 6),
                                                _buildBankItem('Canara Bank Netbanking', () {
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
                                                  child: _buildBankItem(b, () {
                                                    startBankFlow(b);
                                                  }),
                                                )),
                                              ] else if (activeCategory == 'Wallet') ...[
                                                Text('Select Mobile Wallet', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                                const SizedBox(height: 10),
                                                ...['Mobikwik Wallet', 'PayZapp Wallet', 'Airtel Money Wallet', 'Paytm Wallet'].map((w) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 6),
                                                  child: _buildBankItem(w, () {
                                                    startBankFlow(w);
                                                  }),
                                                )),
                                              ] else if (activeCategory == 'EMI') ...[
                                                Text('Select EMI Bank Plan', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                                const SizedBox(height: 10),
                                                ...['HDFC Bank No-Cost EMI (3 Mos)', 'ICICI Bank Easy EMI (6 Mos)', 'Axis Bank Standard EMI (12 Mos)'].map((emi) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 6),
                                                  child: _buildBankItem(emi, () {
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

  static Widget _buildMiniBadge(String label, Color bg) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  static Widget _buildBankItem(String name, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFFAF8F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_rounded, size: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
