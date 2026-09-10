import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _controller;
  bool _isTesting = false;
  bool _isAutoDiscovering = false;
  bool? _isConnected;
  int _latencyMs = -1;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiConfig.baseUrl);
    _runConnectionCheck(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runConnectionCheck(String url) async {
    if (!mounted) return;
    setState(() {
      _isTesting = true;
      _statusText = 'Pinging server...';
    });

    final res = await ApiConfig.testServerConnection(url);
    if (!mounted) return;

    setState(() {
      _isTesting = false;
      _isConnected = res['success'] == true;
      _latencyMs = res['latencyMs'] ?? -1;
      _statusText = res['message'] ?? (_isConnected! ? 'Connected' : 'Offline');
    });
  }

  Future<void> _handleAutoDiscover() async {
    setState(() {
      _isAutoDiscovering = true;
      _statusText = 'Scanning local network & candidates...';
    });

    final found = await ApiConfig.autoDiscoverBackend();
    if (!mounted) return;

    setState(() {
      _isAutoDiscovering = false;
    });

    if (found != null) {
      _controller.text = found;
      await _runConnectionCheck(found);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-discovered active server: $found'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } else {
      setState(() {
        _statusText = 'Auto-discovery found no active backend server.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dns_rounded, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Server API Connection',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Indicator Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _isConnected == true
                    ? AppTheme.successColor.withAlpha(25)
                    : (_isConnected == false
                        ? AppTheme.errorColor.withAlpha(25)
                        : AppTheme.surfaceColor),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isConnected == true
                      ? AppTheme.successColor.withAlpha(80)
                      : (_isConnected == false
                          ? AppTheme.errorColor.withAlpha(80)
                          : Colors.white10),
                ),
              ),
              child: Row(
                children: [
                  if (_isTesting || _isAutoDiscovering)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColor),
                    )
                  else
                    Icon(
                      _isConnected == true ? Icons.check_circle_rounded : Icons.offline_bolt_rounded,
                      color: _isConnected == true ? AppTheme.successColor : AppTheme.errorColor,
                      size: 20,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isConnected == true
                              ? 'ONLINE (${_latencyMs}ms)'
                              : (_isConnected == false ? 'OFFLINE' : 'TESTING'),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _isConnected == true
                                ? AppTheme.successColor
                                : (_isConnected == false ? AppTheme.errorColor : AppTheme.accentColor),
                          ),
                        ),
                        Text(
                          _statusText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white70),
                    tooltip: 'Re-test connection',
                    onPressed: () => _runConnectionCheck(_controller.text),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Preset Selection Chips
            Text(
              'Quick Presets:',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.wifi_rounded, size: 15, color: AppTheme.accentColor),
                  label: const Text('Wi-Fi Network'),
                  backgroundColor: AppTheme.surfaceColor,
                  labelStyle: GoogleFonts.outfit(fontSize: 11, color: Colors.white),
                  onPressed: () {
                    _controller.text = ApiConfig.localWifiUrl;
                    _runConnectionCheck(_controller.text);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.phone_android_rounded, size: 15, color: Colors.white),
                  label: const Text('Emulator (10.0.2.2)'),
                  backgroundColor: AppTheme.surfaceColor,
                  labelStyle: GoogleFonts.outfit(fontSize: 11, color: Colors.white),
                  onPressed: () {
                    _controller.text = 'http://10.0.2.2:5000/api';
                    _runConnectionCheck(_controller.text);
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.computer_rounded, size: 15, color: Colors.white),
                  label: const Text('Localhost (127.0.0.1)'),
                  backgroundColor: AppTheme.surfaceColor,
                  labelStyle: GoogleFonts.outfit(fontSize: 11, color: Colors.white),
                  onPressed: () {
                    _controller.text = 'http://127.0.0.1:5000/api';
                    _runConnectionCheck(_controller.text);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Custom Input Field
            Text(
              'Server URL / Custom Host:',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _controller,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. 192.168.1.50 or my-backend.com',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.bolt_rounded, size: 18, color: AppTheme.accentColor),
                  tooltip: 'Test entered URL',
                  onPressed: () => _runConnectionCheck(_controller.text),
                ),
              ),
              onSubmitted: (val) => _runConnectionCheck(val),
            ),
            const SizedBox(height: 14),

            // Helper Action Buttons (Auto-Detect / Reset)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isAutoDiscovering ? null : _handleAutoDiscover,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 15, color: AppTheme.accentColor),
                    label: Text(
                      _isAutoDiscovering ? 'Scanning...' : 'Auto Detect',
                      style: GoogleFonts.outfit(color: AppTheme.accentColor, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    await ApiConfig.resetToAuto();
                    if (!mounted) return;
                    _controller.text = ApiConfig.baseUrl;
                    await _runConnectionCheck(_controller.text);
                  },
                  child: Text(
                    'Reset',
                    style: GoogleFonts.outfit(color: AppTheme.subtextColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.outfit(color: AppTheme.subtextColor)),
        ),
        ElevatedButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            await ApiConfig.setCustomBaseUrl(_controller.text);
            if (!mounted) return;
            navigator.pop();
            messenger.showSnackBar(
              SnackBar(
                content: Text('Updated active backend server: ${ApiConfig.baseUrl}'),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
          },
          child: Text('Save & Connect', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
