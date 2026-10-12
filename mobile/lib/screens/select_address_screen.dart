import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/address_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class SelectAddressScreen extends StatefulWidget {
  final String? initialAddressId;

  const SelectAddressScreen({
    super.key,
    this.initialAddressId,
  });

  @override
  State<SelectAddressScreen> createState() => _SelectAddressScreenState();
}

class _SelectAddressScreenState extends State<SelectAddressScreen> {
  List<AddressModel> _addresses = [];
  String? _selectedId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final list = await AddressService.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = list.toList();
        if (_selectedId == null) {
          if (widget.initialAddressId != null &&
              _addresses.any((a) => a.id == widget.initialAddressId)) {
            _selectedId = widget.initialAddressId;
          } else if (_addresses.isNotEmpty) {
            final defaultAddr = _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first);
            _selectedId = defaultAddr.id;
          }
        }
        _isLoading = false;
      });
    }
  }

  AddressModel? get _currentSelectedAddress {
    if (_addresses.isEmpty) return null;
    return _addresses.firstWhere(
      (a) => a.id == _selectedId,
      orElse: () => _addresses.first,
    );
  }

  Future<void> _confirmSelection(AddressModel address) async {
    await AddressService.saveAddress(address, setAsDefault: true);
    if (mounted) {
      Navigator.pop(context, address);
    }
  }

  void _showAddEditAddressDialog({AddressModel? existing}) async {
    final isEditing = existing != null;
    final user = await AuthService.getUser();
    final defaultName = user?.name.isNotEmpty == true ? user!.name : 'Tatukulaedukondalu';

    final nameController = TextEditingController(text: existing?.name ?? defaultName);
    final phoneController = TextEditingController(text: existing?.phone ?? '+91 98765 43210');
    final streetController = TextEditingController(text: existing?.street ?? '');
    final cityController = TextEditingController(text: existing?.city ?? 'Hyderabad');
    final stateController = TextEditingController(text: existing?.state ?? 'Telangana');
    final pincodeController = TextEditingController(text: existing?.pincode ?? '500032');
    String selectedType = existing?.type ?? 'Home';
    bool isDefault = existing?.isDefault ?? true;

    if (!mounted) return;

    final formKey = GlobalKey<FormState>();

    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (modalCtx) {
          return StatefulBuilder(
            builder: (modalCtx, setDialogState) {
              return Scaffold(
                backgroundColor: const Color(0xFFF8FAFC),
                appBar: AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  scrolledUnderElevation: 1,
                  surfaceTintColor: Colors.transparent,
                  shadowColor: const Color(0x15000000),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                  title: Text(
                    isEditing ? 'Edit Address' : 'Add New Address',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name Field
                          TextFormField(
                            controller: nameController,
                            decoration: _inputDecoration('Full Name', Icons.person_outline_rounded),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 14),

                          // Phone Field
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter phone number' : null,
                          ),
                          const SizedBox(height: 14),

                          // Street / Flat / Area
                          TextFormField(
                            controller: streetController,
                            maxLines: 2,
                            decoration: _inputDecoration('House/Flat No, Street, Landmark', Icons.home_outlined),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter street address' : null,
                          ),
                          const SizedBox(height: 14),

                          // City and State in Row
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: cityController,
                                  decoration: _inputDecoration('City', Icons.location_city_outlined),
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter city' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: pincodeController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Pincode', Icons.pin_drop_outlined),
                                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter pincode' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: stateController,
                            decoration: _inputDecoration('State', Icons.map_outlined),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Enter state' : null,
                          ),
                          const SizedBox(height: 20),

                          // Address Type Chips
                          Text(
                            'Address Type',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: ['Home', 'Work', 'Other'].map((type) {
                              final isSelected = selectedType == type;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ChoiceChip(
                                  label: Text(type),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFFEFF6FF),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  labelStyle: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                  ),
                                  onSelected: (_) {
                                    setDialogState(() => selectedType = type);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Set as default checkbox
                          InkWell(
                            onTap: () {
                              setDialogState(() => isDefault = !isDefault);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isDefault,
                                    activeColor: const Color(0xFF2563EB),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) {
                                      setDialogState(() => isDefault = val ?? false);
                                    },
                                  ),
                                  Text(
                                    'Make this my default delivery address',
                                    style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                bottomNavigationBar: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C2340),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final newAddress = AddressModel(
                            id: isEditing ? existing.id : 'addr_${DateTime.now().millisecondsSinceEpoch}',
                            type: selectedType,
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            street: streetController.text.trim(),
                            city: cityController.text.trim(),
                            state: stateController.text.trim(),
                            pincode: pincodeController.text.trim(),
                            isDefault: isDefault,
                          );

                          await AddressService.saveAddress(newAddress, setAsDefault: isDefault);
                          if (modalCtx.mounted) {
                            Navigator.pop(modalCtx);
                          }
                          await _loadAddresses();
                          if (mounted) {
                            setState(() {
                              _selectedId = newAddress.id;
                            });
                          }
                        },
                        child: Text(
                          isEditing ? 'Update Address' : 'Save & Select Address',
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x15000000),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Delivery Address',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddEditAddressDialog(),
            icon: const Icon(Icons.add_rounded, color: Color(0xFF2563EB), size: 18),
            label: Text(
              'Add New',
              style: GoogleFonts.outfit(
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Add new address top banner card
                      InkWell(
                        onTap: () => _showAddEditAddressDialog(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.add_location_alt_outlined, color: Color(0xFF2563EB), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add a new address',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Tap to add another delivery location',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      Text(
                        'SAVED ADDRESSES (${_addresses.length})',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 10),

                      ..._addresses.map((addr) {
                        final isSelected = _selectedId == addr.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              width: isSelected ? 1.8 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(isSelected ? 10 : 5),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _selectedId = addr.id;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Radio indicator
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.radio_button_unchecked_rounded,
                                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),

                                      // Name
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                addr.name.isNotEmpty ? addr.name : 'Delivery Location',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF0F172A),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),

                                            // Type tag
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isSelected ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                addr.type.toUpperCase(),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                                                ),
                                              ),
                                            ),

                                            if (addr.isDefault) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFDCFCE7),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'DEFAULT',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF15803D),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Address body
                                  Padding(
                                    padding: const EdgeInsets.only(left: 34),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          addr.fullAddressText,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13.5,
                                            height: 1.4,
                                            color: const Color(0xFF334155),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                            const SizedBox(width: 5),
                                            Text(
                                              addr.phone,
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF475569),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Divider & Card action buttons
                                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _showAddEditAddressDialog(existing: addr),
                                        icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
                                        label: Text(
                                          'Edit',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF2563EB),
                                          ),
                                        ),
                                      ),
                                      if (_addresses.length > 1) ...[
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () async {
                                            await AddressService.deleteAddress(addr.id);
                                            await _loadAddresses();
                                          },
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                          label: Text(
                                            'Remove',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Sticky Bottom Bar with "Deliver to this Address" button
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C2340), // Premium Dark Navy
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        onPressed: _currentSelectedAddress != null
                            ? () => _confirmSelection(_currentSelectedAddress!)
                            : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Deliver to this Address',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
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
  }
}
