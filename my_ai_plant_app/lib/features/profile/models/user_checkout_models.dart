class ShippingAddress {
  final String id;
  final String recipientName;
  final String phone;
  final String address;
  final String? provinceName;
  final String? districtName;
  final String? wardName;
  final String? streetDetail;
  final double? latitude;
  final double? longitude;
  final String label; // 'Nhà riêng', 'Văn phòng', 'Khu vườn'
  final bool isDefault;

  ShippingAddress({
    required this.id,
    required this.recipientName,
    required this.phone,
    required this.address,
    this.provinceName,
    this.districtName,
    this.wardName,
    this.streetDetail,
    this.latitude,
    this.longitude,
    this.label = 'Nhà riêng',
    this.isDefault = false,
  });

  ShippingAddress copyWith({
    String? id,
    String? recipientName,
    String? phone,
    String? address,
    String? provinceName,
    String? districtName,
    String? wardName,
    String? streetDetail,
    double? latitude,
    double? longitude,
    String? label,
    bool? isDefault,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      provinceName: provinceName ?? this.provinceName,
      districtName: districtName ?? this.districtName,
      wardName: wardName ?? this.wardName,
      streetDetail: streetDetail ?? this.streetDetail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipientName': recipientName,
      'phone': phone,
      'address': address,
      'provinceName': provinceName,
      'districtName': districtName,
      'wardName': wardName,
      'streetDetail': streetDetail,
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
      'isDefault': isDefault,
    };
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      recipientName: map['recipientName']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      provinceName: map['provinceName']?.toString(),
      districtName: map['districtName']?.toString(),
      wardName: map['wardName']?.toString(),
      streetDetail: map['streetDetail']?.toString(),
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : null,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : null,
      label: map['label']?.toString() ?? 'Nhà riêng',
      isDefault: map['isDefault'] == true,
    );
  }
}

class SavedPaymentCard {
  final String id;
  final String bankName;
  final String cardNumber;
  final String cardHolder;
  final String issueDate;
  final bool isDefault;

  SavedPaymentCard({
    required this.id,
    required this.bankName,
    required this.cardNumber,
    required this.cardHolder,
    required this.issueDate,
    this.isDefault = false,
  });

  SavedPaymentCard copyWith({
    String? id,
    String? bankName,
    String? cardNumber,
    String? cardHolder,
    String? issueDate,
    bool? isDefault,
  }) {
    return SavedPaymentCard(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolder: cardHolder ?? this.cardHolder,
      issueDate: issueDate ?? this.issueDate,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get maskedCardNumber {
    final clean = cardNumber.replaceAll(' ', '');
    if (clean.length <= 4) return clean;
    final last4 = clean.substring(clean.length - 4);
    final first4 = clean.length >= 8 ? clean.substring(0, 4) : '';
    return '$first4 •••• •••• $last4';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankName': bankName,
      'cardNumber': cardNumber,
      'cardHolder': cardHolder,
      'issueDate': issueDate,
      'isDefault': isDefault,
    };
  }

  factory SavedPaymentCard.fromMap(Map<String, dynamic> map) {
    return SavedPaymentCard(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      bankName: map['bankName']?.toString() ?? 'NCB Bank',
      cardNumber: map['cardNumber']?.toString() ?? '',
      cardHolder: map['cardHolder']?.toString() ?? '',
      issueDate: map['issueDate']?.toString() ?? '',
      isDefault: map['isDefault'] == true,
    );
  }
}
