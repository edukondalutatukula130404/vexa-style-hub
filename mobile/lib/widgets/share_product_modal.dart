import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../models/item_model.dart';

class ShareProductModal extends StatelessWidget {
  final ItemModel item;

  const ShareProductModal({
    super.key,
    required this.item,
  });

  static Future<void> show(BuildContext context, ItemModel item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ShareProductModal(item: item),
      ),
    );
  }

  String get _productUrl {
    final cleanId = item.id.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    final id = cleanId.isEmpty ? 'vx-01' : cleanId;

    // Use active valid server domain so links resolve online without DNS errors
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    final validDomain = base.contains('http') && !base.contains('10.0.2.2')
        ? base
        : ApiConfig.productionUrl.replaceAll(RegExp(r'/api/?$'), '');

    return '$validDomain/product?id=$id';
  }

  String get _shareText {
    return '🛍️ *${item.name}*\nSpecial Price: ₹${item.price.toStringAsFixed(0)}\n\n🔗 Open product link in VEXA app:\n$_productUrl';
  }

  Future<void> _handleSystemShare(BuildContext context) async {
    Navigator.pop(context);
    try {
      await Share.share(_shareText, subject: item.name);
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: _productUrl));
      if (context.mounted) {
        _showSnackBar(context, '📋 Product link copied to clipboard!');
      }
    }
  }

  Future<void> _handleShareOption(BuildContext context, String appName) async {
    final encodedText = Uri.encodeComponent(_shareText);
    final encodedUrl = Uri.encodeComponent(_productUrl);

    if (appName == 'Copy Link') {
      await Clipboard.setData(ClipboardData(text: _productUrl));
      if (!context.mounted) return;
      Navigator.pop(context);
      _showSnackBar(context, '📋 Product link copied to clipboard!');
      return;
    }

    Uri? targetUri;
    bool triggerSystemShare = false;

    switch (appName) {
      case 'WhatsApp':
        targetUri = Uri.parse('whatsapp://send?text=$encodedText');
        break;
      case 'Gmail':
        targetUri = Uri.parse('mailto:?subject=${Uri.encodeComponent(item.name)}&body=$encodedText');
        break;
      case 'Messages':
      case 'Private message':
        targetUri = Uri.parse('sms:?body=$encodedText');
        break;
      case 'Telegram':
        targetUri = Uri.parse('tg://msg?text=$encodedText');
        break;
      case 'Twitter / X':
      case 'Threads':
        targetUri = Uri.parse('https://twitter.com/intent/tweet?text=$encodedText');
        break;
      case 'Facebook':
      case 'Feed':
      case 'Your groups':
      case 'Your story':
        targetUri = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=$encodedUrl');
        break;
      case 'Instagram':
        targetUri = Uri.parse('instagram://');
        break;
      case 'Chrome':
        targetUri = Uri.parse(_productUrl);
        break;
      case 'Drive':
        targetUri = Uri.parse('https://drive.google.com/');
        break;
      case 'ChatGPT':
        targetUri = Uri.parse('https://chatgpt.com/');
        break;
      case 'Snapchat':
        targetUri = Uri.parse('snapchat://');
        break;
      case 'Truecaller':
        targetUri = Uri.parse('truecaller://');
        break;
      case 'Rapido':
        targetUri = Uri.parse('rapido://');
        break;
      case 'Paytm':
        targetUri = Uri.parse('paytmmp://');
        break;
      case 'Quick Share':
      case 'Share Nearby\n(data-free)':
      case 'Share hub':
      case 'File share':
      default:
        triggerSystemShare = true;
        break;
    }

    if (!context.mounted) return;
    Navigator.pop(context);

    if (triggerSystemShare) {
      await Share.share(_shareText, subject: item.name);
    } else if (targetUri != null) {
      try {
        if (await canLaunchUrl(targetUri)) {
          await launchUrl(targetUri, mode: LaunchMode.externalApplication);
        } else {
          final fallback = _getWebFallback(appName, encodedText, encodedUrl);
          if (fallback != null && await canLaunchUrl(fallback)) {
            await launchUrl(fallback, mode: LaunchMode.externalApplication);
          } else {
            await Share.share(_shareText, subject: item.name);
          }
        }
      } catch (_) {
        await Share.share(_shareText, subject: item.name);
      }
    }
  }

  Uri? _getWebFallback(String appName, String encodedText, String encodedUrl) {
    if (appName == 'WhatsApp') {
      return Uri.parse('https://api.whatsapp.com/send?text=$encodedText');
    }
    if (appName == 'Telegram') {
      return Uri.parse('https://t.me/share/url?url=$encodedUrl&text=$encodedText');
    }
    if (appName == 'Instagram') {
      return Uri.parse('https://www.instagram.com/');
    }
    return null;
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF0F172A),
        content: Text(
          message,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildProductImage(String src) {
    if (src.startsWith('assets/')) {
      return Image.asset(
        src,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      src,
      width: 52,
      height: 52,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 52,
        height: 52,
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF94A3B8), size: 24),
      ),
    );
  }

  List<Map<String, dynamic>> _getShareApps() {
    return [
      {
        'name': 'Copy Link',
        'icon': Icons.link_rounded,
        'badgeBg': const Color(0xFF2563EB),
        'iconColor': Colors.white,
      },
      {
        'name': 'WhatsApp',
        'icon': Icons.chat_bubble_rounded,
        'badgeBg': const Color(0xFF25D366),
        'iconColor': Colors.white,
      },
      {
        'name': 'Your groups',
        'icon': Icons.groups_rounded,
        'badgeBg': const Color(0xFF1877F2),
        'iconColor': Colors.white,
      },
      {
        'name': 'Feed',
        'icon': Icons.dynamic_feed_rounded,
        'badgeBg': const Color(0xFF1877F2),
        'iconColor': Colors.white,
      },
      {
        'name': 'Your story',
        'icon': Icons.add_a_photo_rounded,
        'badgeBg': const Color(0xFF1877F2),
        'iconColor': Colors.white,
      },
      {
        'name': 'Gmail',
        'icon': Icons.mark_email_unread_rounded,
        'badgeBg': const Color(0xFFF1F5F9),
        'iconColor': const Color(0xFFEA4335),
      },
      {
        'name': 'Messages',
        'icon': Icons.message_rounded,
        'badgeBg': const Color(0xFF1A73E8),
        'iconColor': Colors.white,
      },
      {
        'name': 'Private message',
        'icon': Icons.lock_person_rounded,
        'badgeBg': const Color(0xFF0A66C2),
        'iconColor': Colors.white,
      },
      {
        'name': 'Share in a post',
        'icon': Icons.post_add_rounded,
        'badgeBg': const Color(0xFF0A66C2),
        'iconColor': Colors.white,
      },
      {
        'name': 'Bluetooth',
        'icon': Icons.bluetooth_rounded,
        'badgeBg': const Color(0xFFE8F0FE),
        'iconColor': const Color(0xFF1A73E8),
      },
      {
        'name': 'Chrome',
        'icon': Icons.language_rounded,
        'badgeBg': const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFF4285F4),
      },
      {
        'name': 'Drive',
        'icon': Icons.add_to_drive_rounded,
        'badgeBg': const Color(0xFFDCFCE7),
        'iconColor': const Color(0xFF16A34A),
      },
      {
        'name': 'Download',
        'icon': Icons.folder_zip_rounded,
        'badgeBg': const Color(0xFF3B82F6),
        'iconColor': Colors.white,
      },
      {
        'name': 'Quick Share',
        'icon': Icons.swap_horizontal_circle_rounded,
        'badgeBg': const Color(0xFF2563EB),
        'iconColor': Colors.white,
      },
      {
        'name': 'Save',
        'icon': Icons.bookmark_added_rounded,
        'badgeBg': const Color(0xFFF1F5F9),
        'iconColor': const Color(0xFF4285F4),
      },
      {
        'name': 'Read aloud',
        'icon': Icons.accessibility_new_rounded,
        'badgeBg': const Color(0xFF3B82F6),
        'iconColor': Colors.white,
      },
      {
        'name': 'File share',
        'icon': Icons.folder_shared_rounded,
        'badgeBg': const Color(0xFF0F172A),
        'iconColor': const Color(0xFF38BDF8),
      },
      {
        'name': 'Share hub',
        'icon': Icons.compare_arrows_rounded,
        'badgeBg': const Color(0xFFF1F5F9),
        'iconColor': const Color(0xFF0F172A),
      },
      {
        'name': 'Share via barcode',
        'icon': Icons.qr_code_2_rounded,
        'badgeBg': const Color(0xFFEF4444),
        'iconColor': Colors.white,
      },
      {
        'name': 'District',
        'icon': Icons.confirmation_number_rounded,
        'badgeBg': const Color(0xFF7C3AED),
        'iconColor': Colors.white,
      },
      {
        'name': 'Messages',
        'icon': Icons.near_me_rounded,
        'badgeBg': const Color(0xFFE4405F),
        'iconColor': Colors.white,
      },
      {
        'name': 'Threads',
        'icon': Icons.alternate_email_rounded,
        'badgeBg': const Color(0xFF000000),
        'iconColor': Colors.white,
      },
      {
        'name': 'Teams',
        'icon': Icons.diversity_3_rounded,
        'badgeBg': const Color(0xFF5B5FC7),
        'iconColor': Colors.white,
      },
      {
        'name': 'Share Nearby\n(data-free)',
        'icon': Icons.play_circle_fill_rounded,
        'badgeBg': const Color(0xFF1A73E8),
        'iconColor': Colors.white,
      },
      {
        'name': 'ChatGPT',
        'icon': Icons.auto_awesome_rounded,
        'badgeBg': const Color(0xFF10A37F),
        'iconColor': Colors.white,
      },
      {
        'name': 'Rapido',
        'icon': Icons.two_wheeler_rounded,
        'badgeBg': const Color(0xFFFFCC00),
        'iconColor': const Color(0xFF0F172A),
      },
      {
        'name': 'Snapchat',
        'icon': Icons.face_rounded,
        'badgeBg': const Color(0xFFFFFC00),
        'iconColor': const Color(0xFF000000),
      },
      {
        'name': 'Truecaller',
        'icon': Icons.phone_in_talk_rounded,
        'badgeBg': const Color(0xFF0088FF),
        'iconColor': Colors.white,
      },
      {
        'name': 'Products',
        'icon': Icons.shopping_bag_rounded,
        'badgeBg': const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFFD97706),
      },
      {
        'name': 'Paytm',
        'icon': Icons.account_balance_wallet_rounded,
        'badgeBg': const Color(0xFF00BAF2),
        'iconColor': Colors.white,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final shareApps = _getShareApps();

    return Column(
      children: [
        // Top Bar (X close icon on left, Share title + Realtime System Share Button)
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 16, top: 12, bottom: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF1E293B), size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Text(
                'Share',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF0F172A),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Realtime Installed Apps System Share Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => _handleSystemShare(context),
                icon: const Icon(Icons.share_rounded, size: 16),
                label: Text(
                  'Installed Apps',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Product Card Preview
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildProductImage(item.image),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.name} - Buy ${item.name} Online at Best Price',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Check out ${item.name} on VEXA Style Hub - $_productUrl',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 4-Column App Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            physics: const BouncingScrollPhysics(),
            itemCount: shareApps.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 18,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              final app = shareApps[index];
              final appName = app['name'] as String;
              final appIcon = app['icon'] as IconData;
              final badgeBg = app['badgeBg'] as Color;
              final iconColor = app['iconColor'] as Color;

              return InkWell(
                onTap: () => _handleShareOption(context, appName),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: badgeBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(appIcon, color: iconColor, size: 25),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        appName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF334155),
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Bottom home bar space
        const SafeArea(child: SizedBox(height: 8)),
      ],
    );
  }
}


