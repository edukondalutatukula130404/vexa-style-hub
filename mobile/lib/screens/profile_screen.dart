import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/server_config_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text('Log Out', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to log out of VEXA Style Hub?', style: GoogleFonts.outfit(color: AppTheme.subtextColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              await AuthService.clearSession();
              if (!context.mounted) return;
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Profile & Settings',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet_rounded, color: AppTheme.accentColor),
            tooltip: 'Server Connection Settings',
            onPressed: () => ServerConfigDialog.show(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E2452), Color(0xFF1E1E28)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentColor.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            _currentUser?.name.isNotEmpty == true ? _currentUser!.name[0].toUpperCase() : 'G',
                            style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser?.name ?? 'Guest User',
                                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentUser?.email ?? 'guest@vexa.app',
                                style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.subtextColor),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withAlpha(40),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _currentUser != null ? 'VIP Member' : 'Guest Account',
                                  style: GoogleFonts.outfit(color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Server Connection Card
                  Text('Server Connection:', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  ValueListenableBuilder<String>(
                    valueListenable: ApiConfig.baseUrlNotifier,
                    builder: (context, activeUrl, _) {
                      return Material(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => ServerConfigDialog.show(context),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.accentColor.withAlpha(50)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withAlpha(35),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.dns_rounded, color: AppTheme.accentColor, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Active Backend Endpoint',
                                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        activeUrl,
                                        style: GoogleFonts.outfit(color: AppTheme.accentColor, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.tune_rounded, color: AppTheme.subtextColor, size: 18),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Account Options
                  Text('Account Preferences:', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Material(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF2D2D3A)),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                            title: Text('My Orders & History', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.subtextColor),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Orders list up to date'), backgroundColor: AppTheme.primaryColor),
                              );
                            },
                          ),
                          const Divider(color: Color(0xFF2D2D3A), height: 1),
                          ListTile(
                            leading: const Icon(Icons.location_on_outlined, color: Colors.white),
                            title: Text('Saved Shipping Addresses', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.subtextColor),
                          ),
                          const Divider(color: Color(0xFF2D2D3A), height: 1),
                          ListTile(
                            leading: const Icon(Icons.help_outline_rounded, color: Colors.white),
                            title: Text('Customer Support & FAQ', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.subtextColor),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppTheme.cardColor,
                                  title: Text('VEXA Help & FAQ', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                                  content: Text('Need assistance? Our fashion support team is available 24/7. Contact support@vexa.app.', style: GoogleFonts.outfit(color: AppTheme.subtextColor)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Logout / Sign In Button
                  SizedBox(
                    width: double.infinity,
                    child: _currentUser != null
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                            onPressed: _handleLogout,
                            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                            label: Text('Log Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                            label: Text('Sign In to Your Account', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // App Version Footer
                  Center(
                    child: Text(
                      'VEXA Style Hub v1.0.0 (Production Build)',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppTheme.subtextColor.withAlpha(120)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
