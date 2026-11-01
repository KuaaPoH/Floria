import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final String imageUrl;
  final String category;
  final int price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.price,
    required this.quantity,
  });

  int get subtotal => price * quantity;

  String get formattedPrice => _formatVnd(price);
  String get formattedSubtotal => _formatVnd(subtotal);

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'category': category,
      'price': price,
      'quantity': quantity,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: (map['productId'] ?? '').toString(),
      name: (map['name'] ?? 'Sản phẩm').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      category: (map['category'] ?? 'Vật tư').toString(),
      price: (map['price'] as num?)?.toInt() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class OrderModel {
  final String id;
  final String orderCode;
  final String userId;
  final List<OrderItem> items;
  final int totalAmount;
  final String recipientName;
  final String recipientPhone;
  final String shippingAddress;
  final String addressLabel;
  final double? latitude;
  final double? longitude;
  final String paymentMethod; // 'cod' hoặc 'card'
  final String paymentLabel;
  final String status; // 'pending' | 'shipping' | 'completed' | 'cancelled'
  final bool isReviewed;
  final int? rating;
  final String? reviewNote;
  final List<String> reviewImages;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.orderCode,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.recipientName,
    required this.recipientPhone,
    required this.shippingAddress,
    this.addressLabel = 'Nhà riêng',
    this.latitude,
    this.longitude,
    required this.paymentMethod,
    required this.paymentLabel,
    this.status = 'pending',
    this.isReviewed = false,
    this.rating,
    this.reviewNote,
    this.reviewImages = const [],
    this.reviewedAt,
    required this.createdAt,
    this.updatedAt,
  });

  int get totalItemsCount => items.fold(0, (acc, item) => acc + item.quantity);

  String get formattedTotal => _formatVnd(totalAmount);

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Chờ xác nhận';
      case 'shipping':
        return 'Đang giao hàng';
      case 'completed':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Chờ xác nhận';
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderCode': orderCode,
      'userId': userId,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'shippingAddress': shippingAddress,
      'addressLabel': addressLabel,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'paymentMethod': paymentMethod,
      'paymentLabel': paymentLabel,
      'status': status,
      'isReviewed': isReviewed,
      if (rating != null) 'rating': rating,
      if (reviewNote != null) 'reviewNote': reviewNote,
      if (reviewImages.isNotEmpty) 'reviewImages': reviewImages,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt ?? createdAt),
    };
  }

  OrderModel copyWith({
    String? status,
    bool? isReviewed,
    int? rating,
    String? reviewNote,
    List<String>? reviewImages,
    DateTime? reviewedAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id,
      orderCode: orderCode,
      userId: userId,
      items: items,
      totalAmount: totalAmount,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      shippingAddress: shippingAddress,
      addressLabel: addressLabel,
      latitude: latitude,
      longitude: longitude,
      paymentMethod: paymentMethod,
      paymentLabel: paymentLabel,
      status: status ?? this.status,
      isReviewed: isReviewed ?? this.isReviewed,
      rating: rating ?? this.rating,
      reviewNote: reviewNote ?? this.reviewNote,
      reviewImages: reviewImages ?? this.reviewImages,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawItems = data['items'];
    final parsedItems = <OrderItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          parsedItems.add(OrderItem.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawImages = data['reviewImages'];
    final parsedImages = <String>[];
    if (rawImages is List) {
      for (final img in rawImages) {
        if (img != null) parsedImages.add(img.toString());
      }
    }

    return OrderModel(
      id: doc.id,
      orderCode: (data['orderCode'] ?? doc.id.substring(0, 8).toUpperCase()).toString(),
      userId: (data['userId'] ?? '').toString(),
      items: parsedItems,
      totalAmount: (data['totalAmount'] as num?)?.toInt() ?? 0,
      recipientName: (data['recipientName'] ?? '').toString(),
      recipientPhone: (data['recipientPhone'] ?? '').toString(),
      shippingAddress: (data['shippingAddress'] ?? '').toString(),
      addressLabel: (data['addressLabel'] ?? 'Nhà riêng').toString(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      paymentMethod: (data['paymentMethod'] ?? 'cod').toString(),
      paymentLabel: (data['paymentLabel'] ?? 'Thanh toán khi nhận hàng (COD)').toString(),
      status: (data['status'] ?? 'pending').toString(),
      isReviewed: data['isReviewed'] == true,
      rating: (data['rating'] as num?)?.toInt(),
      reviewNote: data['reviewNote']?.toString(),
      reviewImages: parsedImages,
      reviewedAt: data['reviewedAt'] != null ? parseDate(data['reviewedAt']) : null,
      createdAt: parseDate(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? parseDate(data['updatedAt']) : null,
    );
  }
}

String _formatVnd(int amount) {
  final str = amount.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(str[i]);
  }
  return '${buffer.toString()}đ';
}

