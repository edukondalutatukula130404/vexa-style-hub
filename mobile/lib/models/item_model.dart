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
    required String image,
    required this.inStock,
  }) : image = _resolveImage(image, name, id);

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedColors = [];
    if (json['colors'] is List) {
      parsedColors = List<String>.from(json['colors']);
    } else if (json['color'] != null) {
      parsedColors = [json['color'].toString()];
    }

    final rawImage = (json['image'] ?? json['imageUrl'] ?? '') as String;
    final itemId = (json['_id'] ?? json['id'] ?? '') as String;

    return ItemModel(
      id: itemId,
      name: json['name'] ?? json['title'] ?? 'Fashion Item',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (json['oldPrice'] as num?)?.toDouble(),
      color: json['color'] ?? (parsedColors.isNotEmpty ? parsedColors.first : 'Default'),
      colors: parsedColors.isNotEmpty ? parsedColors : ['Black'],
      category: json['category'] ?? 'Apparel',
      collectionType: json['collectionType'] ?? json['collection'] ?? 'Trending',
      image: rawImage,
      inStock: json['inStock'] ?? true,
    );
  }

  /// Maps each product ID or name to its unique bundled T-shirt asset image.
  static String _resolveImage(String rawImage, String name, [String id = '']) {
    final n = name.toLowerCase();
    final itemID = id.toLowerCase();

    if (itemID == 'vx-08' || n.contains('emerald'))   return 'assets/images/tee-emerald.png';
    if (itemID == 'vx-12' || n.contains('lavender') || n.contains('lilac')) return 'assets/images/tee-lavender.png';
    if (itemID == 'vx-00' || n.contains('gold') || n.contains('luxe tee')) return 'assets/images/hero_luxury_tshirt.png';
    if (itemID == 'vx-07' || n.contains('rust'))      return 'assets/images/tee-rust.png';
    if (itemID == 'vx-01' || n.contains('obsidian') || n.contains('stealth')) return 'assets/images/tee-black.jpg';
    if (itemID == 'vx-02' || n.contains('ivory'))     return 'assets/images/tee-white.jpg';
    if (itemID == 'vx-03' || n.contains('midnight') || n.contains('indigo')) return 'assets/images/tee-navy.jpg';
    if (itemID == 'vx-04' || n.contains('desert') || n.contains('sand')) return 'assets/images/tee-beige.jpg';
    if (itemID == 'vx-05' || n.contains('charcoal'))  return 'assets/images/tee-charcoal.jpg';
    if (itemID == 'vx-06' || n.contains('military'))  return 'assets/images/tee-olive.jpg';
    if (itemID == 'vx-15' || n.contains('cyber') || n.contains('chrome')) return 'assets/images/promo_banner_1.png';
    if (itemID == 'vx-16' || n.contains('crimson'))   return 'assets/images/promo_banner_2.png';

    if (rawImage.isNotEmpty && rawImage.startsWith('assets/')) {
      return rawImage;
    }

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
