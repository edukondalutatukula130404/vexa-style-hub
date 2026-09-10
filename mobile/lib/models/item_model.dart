class ItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? oldPrice;
  final String color;
  final List<String> colors;
  final String category;
  final String collectionType;
  final String image;
  final bool inStock;

  ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.color,
    required this.colors,
    required this.category,
    required this.collectionType,
    required this.image,
    required this.inStock,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedColors = [];
    if (json['colors'] is List) {
      parsedColors = List<String>.from(json['colors']);
    } else if (json['color'] != null) {
      parsedColors = [json['color'].toString()];
    }

    final rawImage = (json['image'] ?? json['imageUrl'] ?? '') as String;
    final resolvedImage = _resolveImage(rawImage, json['name'] ?? '');

    return ItemModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? json['title'] ?? 'Fashion Item',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (json['oldPrice'] as num?)?.toDouble(),
      color: json['color'] ?? (parsedColors.isNotEmpty ? parsedColors.first : 'Default'),
      colors: parsedColors.isNotEmpty ? parsedColors : ['Black'],
      category: json['category'] ?? 'Apparel',
      collectionType: json['collectionType'] ?? json['collection'] ?? 'Trending',
      image: resolvedImage,
      inStock: json['inStock'] ?? true,
    );
  }

  /// Maps a product name to its local bundled asset when the backend image is empty.
  static String _resolveImage(String rawImage, String name) {
    if (rawImage.isNotEmpty) return rawImage;

    // Name-to-local-asset mapping (matches web frontend assets)
    final n = name.toLowerCase();
    if (n.contains('emerald'))   return 'assets/images/tee-emerald.png';
    if (n.contains('lavender') || n.contains('lilac')) return 'assets/images/tee-lavender.png';
    if (n.contains('rust'))      return 'assets/images/tee-rust.png';
    if (n.contains('obsidian') || n.contains('black')) return 'assets/images/tee-black.jpg';
    if (n.contains('gold') || n.contains('cream') || n.contains('oatmeal') || n.contains('beige')) return 'assets/images/tee-beige.jpg';
    if (n.contains('charcoal'))  return 'assets/images/tee-charcoal.jpg';
    if (n.contains('navy') || n.contains('midnight')) return 'assets/images/tee-navy.jpg';
    if (n.contains('olive') || n.contains('military')) return 'assets/images/tee-olive.jpg';
    if (n.contains('white') || n.contains('essential')) return 'assets/images/tee-white.jpg';
    if (n.contains('silk') || n.contains('luxe') || n.contains('luxury')) return 'assets/images/hero_luxury_tshirt.png';

    // Generic fallback
    return 'assets/images/hero_luxury_tshirt.png';
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'price': price,
      'oldPrice': oldPrice,
      'color': color,
      'colors': colors,
      'category': category,
      'collectionType': collectionType,
      'image': image,
      'inStock': inStock,
    };
  }
}
