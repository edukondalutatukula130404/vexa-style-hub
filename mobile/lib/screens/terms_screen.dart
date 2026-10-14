import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _gold = Color(0xFFB8860B);
const Color _goldDark = Color(0xFF8B6508);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _bgColor = Color(0xFFFAFAFC);
const Color _subtext = Color(0xFF64748B);
const Color _border = Color(0xFFE2E8F0);
const Color _textDark = Color(0xFF0F172A);

class TermsScreen extends StatelessWidget {
  final bool isPrivacyPolicy;

  const TermsScreen({
    super.key,
    this.isPrivacyPolicy = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = isPrivacyPolicy ? 'PRIVACY POLICY' : 'TERMS & CONDITIONS';
    final icon = isPrivacyPolicy ? Icons.shield_outlined : Icons.gavel_rounded;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _gold.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _goldDark, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.cinzel(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _textDark,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        centerTitle: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                children: [
                  if (!isPrivacyPolicy) ...[
                    _buildSection(
                      '1. Acceptance of Service Terms',
                      'By downloading, browsing, or placing orders on VEXA Style Hub, you accept all terms outlined herein. Every order placement constitutes a legally binding agreement for high-end streetwear delivery.',
                      Icons.check_circle_outline_rounded,
                    ),
                    _buildSection(
                      '2. Orders, Bespoke & Quality Control',
                      'All custom streetwear orders undergo our signature 2-stage Quality Control inspection before dispatch. Orders are fulfilled within 24-48 hours with live express courier tracking across India.',
                      Icons.inventory_2_outlined,
                    ),
                    _buildSection(
                      '3. Instant Wallet Refund Guarantee',
                      'Cancelled orders or approved returns are credited instantly to your VEXA Pay Wallet. Wallet balances may be applied to any future luxury drops or withdrawn to bank accounts.',
                      Icons.account_balance_wallet_outlined,
                    ),
                    _buildSection(
                      '4. Intellectual Property & Designs',
                      'All original prints, 240 GSM drop designs, bespoke embroidery patterns, typography, and software components are protected trademarks of VEXA Style Hub.',
                      Icons.palette_outlined,
                    ),
                    _buildSection(
                      '5. Payment Security & Cash On Delivery',
                      'We support 100% secure Razorpay online payments (UPI, Cards, Netbanking) and verified Cash on Delivery. All transactions are end-to-end encrypted under 256-bit SSL protocols.',
                      Icons.lock_outline_rounded,
                    ),
                    _buildSection(
                      '6. User Responsibilities & Support',
                      'Users are responsible for maintaining accurate shipping addresses and credentials. For concierge assistance, reach out to support@vexa.app or WhatsApp VIP Concierge.',
                      Icons.support_agent_rounded,
                    ),
                  ] else ...[
                    _buildSection(
                      '1. Information We Collect',
                      'We collect personal details such as your name, delivery address, phone number, and email strictly to process apparel orders, manage shipment tracking, and provide personalized styling.',
                      Icons.perm_identity_rounded,
                    ),
                    _buildSection(
                      '2. Payment Data Privacy',
                      'Payment credentials (card numbers, UPI IDs, netbanking passwords) are securely handled through PCI-DSS compliant gateways like Razorpay. VEXA never stores sensitive banking credentials.',
                      Icons.credit_card_outlined,
                    ),
                    _buildSection(
                      '3. Realtime Tracking & Push Notifications',
                      'With your permission, we send Firebase push notifications and SMS updates regarding dispatch status, order arrival, and exclusive limited streetwear drops.',
                      Icons.notifications_active_outlined,
                    ),
                    _buildSection(
                      '4. Data Retention & Account Deletion',
                      'You have the legal right to request complete deletion of your profile, addresses, and order history at any time through the Account Settings tab in your profile.',
                      Icons.delete_outline_rounded,
                    ),
                    _buildSection(
                      '5. Cookies & Analytics',
                      'We use essential analytical tools to improve app performance, diagnose network crashes, and enhance shopping experiences. We never sell your personal data to third parties.',
                      Icons.analytics_outlined,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'I AGREE & CONTINUE',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _gold.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: _goldDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: _subtext,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
