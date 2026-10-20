class ShopProduct {
  final String id;
  final String name;
  final String category;
  final String categoryKey;
  final int price;
  final int? originalPrice;
  final String imageUrl;
  final String shortDesc;
  final String description;
  final List<String> indications;
  final String usageGuide;
  final String tag;
  final double rating;
  final int soldCount;
  final bool inStock;

  ShopProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryKey,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.shortDesc,
    required this.description,
    required this.indications,
    required this.usageGuide,
    this.tag = '',
    this.rating = 5.0,
    this.soldCount = 0,
    this.inStock = true,
  });

  factory ShopProduct.fromFirestore(Map<String, dynamic> data, String docId) {
    return ShopProduct(
      id: docId,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Khác',
      categoryKey: data['categoryKey'] ?? 'all',
      price: (data['price'] as num?)?.toInt() ?? 0,
      originalPrice: (data['originalPrice'] as num?)?.toInt(),
      imageUrl: data['imageUrl'] ?? '',
      shortDesc: data['shortDesc'] ?? '',
      description: data['description'] ?? '',
      indications: (data['indications'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      usageGuide: data['usageGuide'] ?? '',
      tag: data['tag'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
      soldCount: (data['soldCount'] as num?)?.toInt() ?? 0,
      inStock: data['inStock'] ?? true,
    );
  }

  String get formattedPrice {
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()}đ';
  }

  String? get formattedOriginalPrice {
    if (originalPrice == null || originalPrice! <= price) return null;
    final str = originalPrice.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()}đ';
  }
}

class CartItem {
  final ShopProduct product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  int get totalPrice => product.price * quantity;
}
