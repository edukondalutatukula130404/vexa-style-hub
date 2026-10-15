import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/address_service.dart';
import '../services/auth_service.dart';

class AddAddressScreen extends StatefulWidget {
  final AddressModel? existingAddress;

  const AddAddressScreen({
    super.key,
    this.existingAddress,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  static const Color _goldDark = Color(0xFF8B6508);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _subtext = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _bgColor = Color(0xFFF8FAFC);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;

  String _selectedType = 'Home';
  bool _isDefault = true;
  bool _isSaving = false;

  bool get _isEditing => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;

    _nameController = TextEditingController(text: addr?.name ?? '');
    _phoneController = TextEditingController(text: addr?.phone ?? '');
    _streetController = TextEditingController(text: addr?.street ?? '');
    _cityController = TextEditingController(text: addr?.city ?? 'Hyderabad');
    _stateController = TextEditingController(text: addr?.state ?? 'Telangana');
    _pincodeController = TextEditingController(text: addr?.pincode ?? '');

    if (addr != null) {
      _selectedType = addr.type;
      _isDefault = addr.isDefault;
    } else {
      _prefillUserData();
    }
  }

  Future<void> _prefillUserData() async {
    try {
      final user = await AuthService.getUser();
      if (user != null && mounted) {
        if (_nameController.text.isEmpty && user.name.isNotEmpty) {
          _nameController.text = user.name;
        }
        if (_phoneController.text.isEmpty && user.phone != null && user.phone!.isNotEmpty) {
          _phoneController.text = user.phone!;
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newAddress = AddressModel(
        id: _isEditing ? widget.existingAddress!.id : 'addr_${DateTime.now().millisecondsSinceEpoch}',
        type: _selectedType,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        isDefault: _isDefault,
      );

      await AddressService.saveAddress(newAddress, setAsDefault: _isDefault);

      if (mounted) {
        Navigator.pop(context, newAddress);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: GoogleFonts.outfit(fontSize: 13.5, color: _subtext),
      hintStyle: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, size: 20, color: _subtext),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _goldDark, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
      ),
    );
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
        title: Text(
          _isEditing ? 'Edit Address' : 'Add New Address',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: _textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top subtitle
                Text(
                  'CONTACT DETAILS',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: _goldDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark),
                  decoration: _buildInputDecoration(
                    label: 'Full Name *',
                    icon: Icons.person_outline_rounded,
                    hintText: 'e.g. Charan',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 14),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark),
                  decoration: _buildInputDecoration(
                    label: 'Phone Number *',
                    icon: Icons.phone_outlined,
                    hintText: 'e.g. +91 98765 43210',
                  ),
                  validator: (val) => val == null || val.trim().length < 10 ? 'Please enter a valid phone number' : null,
                ),
                const SizedBox(height: 24),

                // Address Section
                Text(
                  'ADDRESS DETAILS',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: _goldDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Street Address Field
                TextFormField(
                  controller: _streetController,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: _textDark),
                  decoration: _buildInputDecoration(
                    label: 'House / Flat No, Street, Landmark *',
                    icon: Icons.home_outlined,
                    hintText: 'e.g. Flat 402, Luxury Heights, Road No. 36',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter street address' : null,
                ),
                const SizedBox(height: 14),

                // City and Pincode in Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark),
                        decoration: _buildInputDecoration(
                          label: 'City *',
                          icon: Icons.location_city_outlined,
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter city' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark),
                        decoration: _buildInputDecoration(
                          label: 'Pincode *',
                          icon: Icons.pin_drop_outlined,
                          hintText: '500081',
                        ).copyWith(counterText: ''),
                        validator: (val) => val == null || val.trim().length != 6 ? 'Enter 6-digit pin' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // State Field
                TextFormField(
                  controller: _stateController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: _textDark),
                  decoration: _buildInputDecoration(
                    label: 'State *',
                    icon: Icons.map_outlined,
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Enter state' : null,
                ),
                const SizedBox(height: 24),

                // Address Type Chips
                Text(
                  'SAVE ADDRESS AS',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: _goldDark,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: ['Home', 'Work', 'Other'].map((type) {
                    final isSelected = _selectedType == type;
                    IconData typeIcon = Icons.home_rounded;
                    if (type == 'Work') typeIcon = Icons.work_rounded;
                    if (type == 'Other') typeIcon = Icons.location_on_rounded;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        avatar: Icon(
                          typeIcon,
                          size: 16,
                          color: isSelected ? Colors.white : _subtext,
                        ),
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: _goldDark,
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : _textDark,
                        ),
                        side: BorderSide(
                          color: isSelected ? _goldDark : _border,
                          width: isSelected ? 1.4 : 1.0,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedType = type);
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // Default Address Checkbox
                InkWell(
                  onTap: () {
                    setState(() => _isDefault = !_isDefault);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _isDefault,
                          activeColor: _goldDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setState(() => _isDefault = val ?? false);
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Make this my default delivery address',
                            style: GoogleFonts.outfit(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _goldDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              onPressed: _isSaving ? null : _saveAddress,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                    )
                  : Text(
                      _isEditing ? 'UPDATE ADDRESS' : 'SAVE & DELIVER HERE',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
