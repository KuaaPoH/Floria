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
  final int reviewCount;
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
    this.reviewCount = 0,
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
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      inStock: data['inStock'] ?? true,
    );
  }

  ShopProduct copyWith({
    String? id,
    String? name,
    String? category,
    String? categoryKey,
    int? price,
    int? originalPrice,
    String? imageUrl,
    String? shortDesc,
    String? description,
    List<String>? indications,
    String? usageGuide,
    String? tag,
    double? rating,
    int? soldCount,
    int? reviewCount,
    bool? inStock,
  }) {
    return ShopProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      categoryKey: categoryKey ?? this.categoryKey,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      shortDesc: shortDesc ?? this.shortDesc,
      description: description ?? this.description,
      indications: indications ?? this.indications,
      usageGuide: usageGuide ?? this.usageGuide,
      tag: tag ?? this.tag,
      rating: rating ?? this.rating,
      soldCount: soldCount ?? this.soldCount,
      reviewCount: reviewCount ?? this.reviewCount,
      inStock: inStock ?? this.inStock,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'categoryKey': categoryKey,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'shortDesc': shortDesc,
      'description': description,
      'indications': indications,
      'usageGuide': usageGuide,
      'tag': tag,
      'rating': rating,
      'soldCount': soldCount,
      'reviewCount': reviewCount,
      'inStock': inStock,
    };
  }

  factory ShopProduct.fromMap(Map<String, dynamic> data) {
    return ShopProduct.fromFirestore(data, (data['id'] ?? '').toString());
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

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'quantity': quantity,
      'product': product.toMap(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final prodMap = map['product'] is Map
        ? Map<String, dynamic>.from(map['product'] as Map)
        : <String, dynamic>{'id': map['productId'] ?? ''};
    return CartItem(
      product: ShopProduct.fromMap(prodMap),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}
