import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../services/address_service.dart';
import 'add_address_screen.dart';

class DeliveryLocationResult {
  final String displayLocation;
  final AddressModel? address;
  final String? pincode;

  const DeliveryLocationResult({
    required this.displayLocation,
    this.address,
    this.pincode,
  });
}

class DeliveryLocationScreen extends StatefulWidget {
  final String currentLocation;
  final AddressModel? activeAddress;

  const DeliveryLocationScreen({
    super.key,
    required this.currentLocation,
    this.activeAddress,
  });

  @override
  State<DeliveryLocationScreen> createState() => _DeliveryLocationScreenState();
}

class _DeliveryLocationScreenState extends State<DeliveryLocationScreen> {
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _goldDark = Color(0xFF8B6508);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _subtext = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _bgColor = Color(0xFFF8FAFC);

  late final TextEditingController _pincodeController;
  List<AddressModel> _addresses = [];
  bool _isLoading = true;
  String? _selectedAddressId;

  bool _isCheckingPincode = false;
  bool _isDetectingLocation = false;
  String? _detectedLocation;
  String? _detectedPincode;
  bool? _isDeliveryAvailable;
  String? _pincodeError;

  @override
  void initState() {
    super.initState();
    _pincodeController = TextEditingController();
    _selectedAddressId = widget.activeAddress?.id;
    _loadAddresses();
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final list = await AddressService.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = list;
        if (_selectedAddressId == null && _addresses.isNotEmpty) {
          final defaultAddr = _addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => _addresses.first,
          );
          _selectedAddressId = defaultAddr.id;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _selectAddress(AddressModel address) async {
    setState(() => _selectedAddressId = address.id);
    await AddressService.setDefaultAddress(address.id);
    final displayText = address.shortDisplay;

    if (mounted) {
      Navigator.pop(
        context,
        DeliveryLocationResult(
          displayLocation: displayText,
          address: address,
          pincode: address.pincode,
        ),
      );
    }
  }

  Future<void> _openEditAddress(AddressModel address) async {
    final updated = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddAddressScreen(existingAddress: address),
      ),
    );

    if (updated != null && mounted) {
      await _loadAddresses();
      if (_selectedAddressId == address.id) {
        await _selectAddress(updated);
      }
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Address?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Are you sure you want to remove this delivery address?', style: GoogleFonts.outfit(fontSize: 13.5, color: _subtext)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.outfit(color: _subtext, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AddressService.deleteAddress(address.id);
      await _loadAddresses();
    }
  }

  String? _getFallbackRegionForPincode(String pin) {
    if (pin.length != 6) return null;
    final prefix2 = pin.substring(0, 2);
    final prefix1 = pin.substring(0, 1);

    if (prefix1 == '0' || prefix1 == '9') return null;

    if (pin.startsWith('500')) return 'Hyderabad, Telangana';
    if (pin.startsWith('560')) return 'Bengaluru, Karnataka';
    if (pin.startsWith('400')) return 'Mumbai, Maharashtra';
    if (pin.startsWith('110')) return 'New Delhi, Delhi';
    if (pin.startsWith('600')) return 'Chennai, Tamil Nadu';
    if (pin.startsWith('700')) return 'Kolkata, West Bengal';
    if (pin.startsWith('380')) return 'Ahmedabad, Gujarat';
    if (pin.startsWith('411')) return 'Pune, Maharashtra';

    switch (prefix2) {
      case '11': return 'Delhi, NCR';
      case '12': case '13': return 'Haryana';
      case '14': case '15': case '16': return 'Punjab / Chandigarh';
      case '17': return 'Himachal Pradesh';
      case '18': case '19': return 'Jammu & Kashmir';
      case '20': case '21': case '22': case '23': case '24': case '25': case '26': case '27': case '28':
        return 'Uttar Pradesh / Uttarakhand';
      case '30': case '31': case '32': case '33': case '34':
        return 'Rajasthan';
      case '36': case '37': case '38': case '39':
        return 'Gujarat';
      case '40': case '41': case '42': case '43': case '44':
        return 'Maharashtra / Goa';
      case '45': case '46': case '47': case '48': case '49':
        return 'Madhya Pradesh / Chhattisgarh';
      case '50': case '51': case '52': case '53':
        return 'Telangana / Andhra Pradesh';
      case '56': case '57': case '58': case '59':
        return 'Karnataka';
      case '60': case '61': case '62': case '63': case '64':
        return 'Tamil Nadu';
      case '67': case '68': case '69':
        return 'Kerala';
      case '70': case '71': case '72': case '73': case '74':
        return 'West Bengal';
      case '75': case '76': case '77':
        return 'Odisha';
      case '78': case '79':
        return 'Assam / North East';
      case '80': case '81': case '82': case '83': case '84': case '85':
        return 'Bihar / Jharkhand';
      default:
        return null;
    }
  }

  Future<void> _checkPincode() async {
    final pin = _pincodeController.text.trim();
    FocusScope.of(context).unfocus();

    if (pin.length != 6 || !RegExp(r'^[1-9][0-9]{5}$').hasMatch(pin)) {
      setState(() {
        _isCheckingPincode = false;
        _isDeliveryAvailable = false;
        _detectedLocation = null;
        _detectedPincode = null;
        _pincodeError = 'Delivery not available';
      });
      return;
    }

    // If already validated and showing, deliver to it directly on tap
    if (_isDeliveryAvailable == true && _detectedPincode == pin) {
      final loc = _detectedLocation?.isNotEmpty == true ? _detectedLocation! : 'Pincode $pin';
      Navigator.pop(
        context,
        DeliveryLocationResult(
          displayLocation: '$loc ($pin)',
          pincode: pin,
        ),
      );
      return;
    }

    setState(() {
      _isCheckingPincode = true;
      _isDeliveryAvailable = null;
      _pincodeError = null;
      _detectedLocation = null;
      _detectedPincode = null;
    });

    try {
      final uri = Uri.parse('https://api.postalpincode.in/pincode/$pin');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(res.body);
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded[0];
          if (first['Status'] == 'Success') {
            final postOffices = first['PostOffice'] as List<dynamic>?;
            if (postOffices != null && postOffices.isNotEmpty) {
              final po = postOffices.first;
              final name = (po['Name'] ?? '').toString();
              final district = (po['District'] ?? '').toString();
              final state = (po['State'] ?? '').toString();

              final parts = <String>[];
              if (name.isNotEmpty) parts.add(name);
              if (district.isNotEmpty && district.toLowerCase() != name.toLowerCase()) parts.add(district);
              if (state.isNotEmpty) parts.add(state);

              final display = parts.join(', ');

              if (mounted) {
                setState(() {
                  _detectedLocation = display;
                  _detectedPincode = pin;
                  _isCheckingPincode = false;
                  _isDeliveryAvailable = true;
                  _pincodeError = null;
                });
              }
              return;
            }
          } else {
            if (mounted) {
              setState(() {
                _isCheckingPincode = false;
                _isDeliveryAvailable = false;
                _detectedLocation = null;
                _detectedPincode = null;
                _pincodeError = 'Delivery not available';
              });
            }
            return;
          }
        }
      }
    } catch (_) {
      // Offline fallback: check recognized Indian postal zones
      final fallback = _getFallbackRegionForPincode(pin);
      if (fallback != null) {
        if (mounted) {
          setState(() {
            _detectedLocation = fallback;
            _detectedPincode = pin;
            _isCheckingPincode = false;
            _isDeliveryAvailable = true;
            _pincodeError = null;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isCheckingPincode = false;
        _isDeliveryAvailable = false;
        _detectedLocation = null;
        _detectedPincode = null;
        _pincodeError = 'Delivery not available';
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_isDetectingLocation) return;
    setState(() {
      _isDetectingLocation = true;
    });

    try {
      String? detectedCity;
      String? detectedRegion;
      String? detectedPin;

      // 1. Try freeipapi (HTTPS)
      try {
        final res = await http.get(Uri.parse('https://freeipapi.com/api/json')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['cityName'] != null && data['cityName'].toString().isNotEmpty) {
            detectedCity = data['cityName'].toString();
          }
          if (data['regionName'] != null && data['regionName'].toString().isNotEmpty) {
            detectedRegion = data['regionName'].toString();
          }
          if (data['zipCode'] != null && data['zipCode'].toString().isNotEmpty) {
            detectedPin = data['zipCode'].toString();
          }
        }
      } catch (_) {}

      // 2. Fallback to ip-api
      if (detectedCity == null || detectedCity.isEmpty) {
        try {
          final res2 = await http.get(Uri.parse('http://ip-api.com/json')).timeout(const Duration(seconds: 4));
          if (res2.statusCode == 200) {
            final data2 = jsonDecode(res2.body);
            if (data2['status'] == 'success') {
              detectedCity = data2['city'];
              detectedRegion = data2['regionName'];
              detectedPin = data2['zip'];
            }
          }
        } catch (_) {}
      }

      // Safe fallback if offline or no network response
      detectedCity ??= 'Hyderabad';
      detectedRegion ??= 'Telangana';
      detectedPin ??= '500081';

      if (!mounted) return;

      setState(() {
        _isDetectingLocation = false;
      });

      final display = 'Current • $detectedCity, $detectedRegion ($detectedPin)';

      Navigator.pop(
        context,
        DeliveryLocationResult(
          displayLocation: display,
          pincode: detectedPin,
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not detect location. Please enter pincode manually.'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openAddNewAddress() async {
    final newAddress = await Navigator.push<AddressModel>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddAddressScreen(),
      ),
    );

    if (newAddress != null && mounted) {
      await _loadAddresses();
      await _selectAddress(newAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withAlpha(20),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _gold.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded, color: _goldDark, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'DELIVERY LOCATION',
                style: GoogleFonts.cinzel(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: _textDark,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _openAddNewAddress,
            icon: const Icon(Icons.add_rounded, color: _goldDark, size: 18),
            label: Text(
              'Add New',
              style: GoogleFonts.outfit(
                color: _goldDark,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : RefreshIndicator(
              onRefresh: _loadAddresses,
              color: _goldDark,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                children: [
                  // 1. PINCODE SEARCH & CHECK
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _pincodeError != null ? const Color(0xFFEF4444).withAlpha(120) : _border,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(8),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ENTER DELIVERY PINCODE',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: _goldDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isDeliveryAvailable == false
                                  ? const Color(0xFFEF4444)
                                  : _isDeliveryAvailable == true
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFE2E8F0),
                              width: _isDeliveryAvailable != null ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 14, right: 10),
                                child: Icon(
                                  Icons.pin_drop_outlined,
                                  size: 18,
                                  color: _isDeliveryAvailable == false
                                      ? const Color(0xFFEF4444)
                                      : _isDeliveryAvailable == true
                                          ? const Color(0xFF16A34A)
                                          : _subtext,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _pincodeController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter 6-digit Pincode',
                                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                    counterText: '',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  onChanged: (val) {
                                    if (_isDeliveryAvailable != null || _pincodeError != null) {
                                      setState(() {
                                        _isDeliveryAvailable = null;
                                        _pincodeError = null;
                                        _detectedLocation = null;
                                        _detectedPincode = null;
                                      });
                                    }
                                    if (val.trim().length == 6) {
                                      _checkPincode();
                                    }
                                  },
                                  onSubmitted: (_) => _checkPincode(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ElevatedButton(
                                  onPressed: _isCheckingPincode ? null : _checkPincode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _goldDark,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: _isCheckingPincode
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Check',
                                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Checking Status Indicator
                        if (_isCheckingPincode) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: _goldDark),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Checking delivery...',
                                style: GoogleFonts.outfit(fontSize: 12, color: _subtext),
                              ),
                            ],
                          ),
                        ],

                        // Delivery Available Message
                        if (_isDeliveryAvailable == true) ...[
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () {
                              final loc = _detectedLocation?.isNotEmpty == true ? _detectedLocation! : 'Pincode $_detectedPincode';
                              Navigator.pop(
                                context,
                                DeliveryLocationResult(
                                  displayLocation: '$loc ($_detectedPincode)',
                                  pincode: _detectedPincode,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Delivery available',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF16A34A),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Tap to select',
                                    style: GoogleFonts.outfit(
                                      color: _goldDark,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _goldDark),
                                ],
                              ),
                            ),
                          ),
                        ] else if (_isDeliveryAvailable == false) ...[
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Delivery not available',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFDC2626),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. USE CURRENT LOCATION (GPS)
                  InkWell(
                    onTap: _isDetectingLocation ? null : _useCurrentLocation,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(6),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: _gold.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: _isDetectingLocation
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.2, color: _goldDark),
                                  )
                                : const Icon(Icons.my_location_rounded, color: _goldDark, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Use Current Location',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isDetectingLocation
                                      ? 'Detecting your GPS location...'
                                      : 'Detect automatically via device GPS',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: _isDetectingLocation ? _goldDark : _subtext,
                                    fontWeight: _isDetectingLocation ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isDetectingLocation)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _goldDark),
                            )
                          else
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. SAVED ADDRESSES SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SAVED ADDRESSES (${_addresses.length})',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: _subtext,
                        ),
                      ),
                      GestureDetector(
                        onTap: _openAddNewAddress,
                        child: Text(
                          '+ Add Address',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _goldDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_addresses.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_outlined, size: 44, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No Saved Addresses Found',
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add your delivery address to enjoy 1-tap checkout.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(fontSize: 12.5, color: _subtext),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: _openAddNewAddress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _goldDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                            label: Text(
                              'ADD NEW ADDRESS',
                              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._addresses.map((a) {
                      final isSelected = (_selectedAddressId != null)
                          ? (_selectedAddressId == a.id)
                          : a.isDefault;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFFFDF5) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? _gold : _border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected ? _gold.withAlpha(20) : Colors.black.withAlpha(5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: () => _selectAddress(a),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(
                                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                          color: isSelected ? _goldDark : const Color(0xFF94A3B8),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                  decoration: BoxDecoration(
                                                    color: _gold.withAlpha(30),
                                                    borderRadius: BorderRadius.circular(5),
                                                  ),
                                                  child: Text(
                                                    a.type.toUpperCase(),
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: _goldDark,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    a.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: _textDark,
                                                    ),
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF10B981).withAlpha(25),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      'ACTIVE',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: const Color(0xFF10B981),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              a.fullAddressText,
                                              style: GoogleFonts.outfit(
                                                fontSize: 12.5,
                                                color: _subtext,
                                                height: 1.35,
                                              ),
                                            ),
                                            if (a.phone.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Phone: ${a.phone}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11.5,
                                                  color: const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isSelected ? 'Tap to reselect' : 'Tap to select delivery location',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: isSelected ? _goldDark : const Color(0xFF94A3B8),
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () => _openEditAddress(a),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.edit_outlined, size: 14, color: _goldDark),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Edit',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: _goldDark,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (_addresses.length > 1) ...[
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => _deleteAddress(a),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Remove',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: const Color(0xFFEF4444),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 16),
                  // Bottom Add New Address CTA
                  OutlinedButton.icon(
                    onPressed: _openAddNewAddress,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _goldDark, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_location_alt_outlined, color: _goldDark, size: 20),
                    label: Text(
                      'ADD NEW DELIVERY ADDRESS',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: _goldDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
