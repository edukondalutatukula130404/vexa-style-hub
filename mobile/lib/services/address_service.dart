import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class AddressModel {
  final String id;
  final String type; // 'Home', 'Work', 'Other'
  final String name;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  AddressModel({
    required this.id,
    this.type = 'Home',
    required this.name,
    required this.phone,
    required this.street,
    this.city = 'Hyderabad',
    this.state = 'Telangana',
    required this.pincode,
    this.isDefault = false,
  });

  String get fullAddressText {
    final parts = [street, city, state].where((s) => s.trim().isNotEmpty).toList();
    final joined = parts.join(', ');
    return pincode.isNotEmpty ? '$joined, Pincode: $pincode' : joined;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'name': name,
        'phone': phone,
        'street': street,
        'city': city,
        'state': state,
        'pincode': pincode,
        'isDefault': isDefault,
      };

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id'] ?? 'addr_${DateTime.now().millisecondsSinceEpoch}',
        type: json['type'] ?? 'Home',
        name: json['name'] ?? '',
        phone: json['phone'] ?? '+91 98765 43210',
        street: json['street'] ?? '',
        city: json['city'] ?? 'Hyderabad',
        state: json['state'] ?? 'Telangana',
        pincode: json['pincode'] ?? '',
        isDefault: json['isDefault'] == true,
      );

  AddressModel copyWith({
    String? id,
    String? type,
    String? name,
    String? phone,
    String? street,
    String? city,
    String? state,
    String? pincode,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class AddressNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class AddressService {
  static const String _keyAddresses = 'vexa_user_saved_addresses_v1';
  static final AddressNotifier addressesChangeNotifier = AddressNotifier();

  static List<AddressModel>? _cache;

  /// Fetch all saved addresses. Seeds a high-quality default address if none exist.
  static Future<List<AddressModel>> getAddresses() async {
    if (_cache != null) return List.unmodifiable(_cache!);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyAddresses);

    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        _cache = decoded.map((m) => AddressModel.fromJson(m as Map<String, dynamic>)).toList();
        if (_cache!.isNotEmpty) {
          return List.unmodifiable(_cache!);
        }
      } catch (e) {
        debugPrint('Failed to decode saved addresses: $e');
      }
    }

    // Seed initial default address based on user profile if empty
    final user = await AuthService.getUser();
    final userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Tatukula Edukondalu';
    const userPhone = '+91 98765 43210';

    final defaultSeed = [
      AddressModel(
        id: 'addr_default_1',
        type: 'Home',
        name: userName,
        phone: userPhone,
        street: 'Flat 402, Luxury Heights, Jubilee Hills Road No. 36',
        city: 'Hyderabad',
        state: 'Telangana',
        pincode: '500033',
        isDefault: true,
      ),
      AddressModel(
        id: 'addr_default_2',
        type: 'Work',
        name: userName,
        phone: userPhone,
        street: 'Floor 5, Cyber Towers, HITEC City, Phase 2',
        city: 'Hyderabad',
        state: 'Telangana',
        pincode: '500081',
        isDefault: false,
      ),
    ];

    _cache = defaultSeed;
    await _persist(_cache!);
    return List.unmodifiable(_cache!);
  }

  /// Get the active default address (or first available address)
  static Future<AddressModel?> getDefaultAddress() async {
    final list = await getAddresses();
    if (list.isEmpty) return null;
    return list.firstWhere((a) => a.isDefault, orElse: () => list.first);
  }

  /// Save or update an address. Persists to SharedPreferences and notifies listeners.
  static Future<void> saveAddress(AddressModel address, {bool setAsDefault = true}) async {
    final list = (await getAddresses()).toList();
    final index = list.indexWhere((a) => a.id == address.id);

    final shouldBeDefault = setAsDefault || list.isEmpty || (index != -1 && list[index].isDefault);

    List<AddressModel> updatedList = [];
    for (var a in list) {
      if (shouldBeDefault) {
        updatedList.add(a.copyWith(isDefault: false));
      } else {
        updatedList.add(a);
      }
    }

    final newModel = address.copyWith(isDefault: shouldBeDefault);

    if (index != -1) {
      updatedList[index] = newModel;
    } else {
      updatedList.insert(0, newModel);
    }

    // Ensure at least one default
    if (!updatedList.any((a) => a.isDefault) && updatedList.isNotEmpty) {
      updatedList[0] = updatedList[0].copyWith(isDefault: true);
    }

    _cache = updatedList;
    await _persist(updatedList);
    addressesChangeNotifier.notify();
  }

  /// Explicitly mark an address as default
  static Future<void> setDefaultAddress(String addressId) async {
    final list = (await getAddresses()).toList();
    final updatedList = list.map((a) {
      return a.copyWith(isDefault: a.id == addressId);
    }).toList();

    _cache = updatedList;
    await _persist(updatedList);
    addressesChangeNotifier.notify();
  }

  /// Delete an address
  static Future<void> deleteAddress(String addressId) async {
    final list = (await getAddresses()).toList();
    final updatedList = list.where((a) => a.id != addressId).toList();

    if (updatedList.isNotEmpty && !updatedList.any((a) => a.isDefault)) {
      updatedList[0] = updatedList[0].copyWith(isDefault: true);
    }

    _cache = updatedList;
    await _persist(updatedList);
    addressesChangeNotifier.notify();
  }

  static Future<void> _persist(List<AddressModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(list.map((a) => a.toJson()).toList());
    await prefs.setString(_keyAddresses, encoded);
  }
}
