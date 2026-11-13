import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../profile/models/user_checkout_models.dart';
import '../models/order_model.dart';
import '../models/shop_product.dart';

class ShopProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ShopProduct> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _selectedCategoryKey = 'all';
  String _searchQuery = '';

  // Giỏ hàng (lưu bền vững qua SharedPreferences + Firestore Users/{uid})
  final Map<String, CartItem> _cart = {};
  int _cartPulseTick = 0;

  // Đơn hàng của người dùng
  List<OrderModel> _orders = [];
  bool _isOrdersLoading = false;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot>? _ordersSub;

  List<ShopProduct> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategoryKey => _selectedCategoryKey;
  String get searchQuery => _searchQuery;

  Map<String, CartItem> get cart => _cart;
  List<CartItem> get cartItems => _cart.values.toList();
  int get cartCount => _cart.values.fold(0, (total, item) => total + item.quantity);
  int get cartTotalAmount =>
      _cart.values.fold(0, (total, item) => total + item.totalPrice);
  int get cartPulseTick => _cartPulseTick;

  List<OrderModel> get orders => _orders;
  bool get isOrdersLoading => _isOrdersLoading;

  String get formattedCartTotal {
    final str = cartTotalAmount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()}đ';
  }

  // Danh sách sản phẩm sau khi lọc danh mục & tìm kiếm
  List<ShopProduct> get filteredProducts {
    return _products.where((p) {
      final matchesCategory = _selectedCategoryKey == 'all' ||
          p.categoryKey == _selectedCategoryKey;
      final matchesQuery = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.shortDesc.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.indications.any((ind) =>
              ind.toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesQuery;
    }).toList();
  }

  ShopProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadPersistedCart();
    await fetchProducts();
    _authSub = _auth.authStateChanges().listen((user) async {
      await _loadPersistedCart();
      _subscribeToOrders(user?.uid);
    });
    _subscribeToOrders(_auth.currentUser?.uid);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }

  String get _localCartKey {
    final uid = _auth.currentUser?.uid;
    return uid != null && uid.isNotEmpty ? 'floria_cart_$uid' : 'floria_cart_guest';
  }

  // Khôi phục giỏ hàng đã lưu từ SharedPreferences và đồng bộ với Firestore
  Future<void> _loadPersistedCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_localCartKey);
      final Map<String, CartItem> loaded = {};

      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final cartItem = CartItem.fromMap(Map<String, dynamic>.from(item));
              if (cartItem.product.id.isNotEmpty && cartItem.quantity > 0) {
                loaded[cartItem.product.id] = cartItem;
              }
            }
          }
        }
      }

      // Nếu đã đăng nhập, kiểm tra giỏ hàng lưu trên Firestore Users/{uid}
      final uid = _auth.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        try {
          final userDoc = await _firestore.collection('Users').doc(uid).get();
          final data = userDoc.data();
          if (data != null && data['cartItems'] is List) {
            final cloudList = data['cartItems'] as List;
            if (cloudList.isNotEmpty) {
              loaded.clear();
              for (final item in cloudList) {
                if (item is Map) {
                  final cartItem = CartItem.fromMap(Map<String, dynamic>.from(item));
                  if (cartItem.product.id.isNotEmpty && cartItem.quantity > 0) {
                    loaded[cartItem.product.id] = cartItem;
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Lỗi đọc giỏ hàng trên đám mây: $e');
        }
      }

      _cart
        ..clear()
        ..addAll(loaded);
      _refreshCartProductsWithCatalog();
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khôi phục giỏ hàng: $e');
    }
  }

  // Lưu giỏ hàng xuống SharedPreferences và Firestore
  Future<void> _persistCart() async {
    try {
      final serializedList = _cart.values.map((e) => e.toMap()).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localCartKey, jsonEncode(serializedList));

      final uid = _auth.currentUser?.uid;
      if (uid != null && uid.isNotEmpty) {
        await _firestore.collection('Users').doc(uid).set({
          'cartItems': serializedList,
          'cartUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Lỗi lưu giỏ hàng: $e');
    }
  }

  // Cập nhật thông tin sản phẩm mới nhất cho các món trong giỏ
  void _refreshCartProductsWithCatalog() {
    if (_products.isEmpty || _cart.isEmpty) return;
    final catalogMap = {for (final p in _products) p.id: p};
    for (final entry in _cart.entries.toList()) {
      final latest = catalogMap[entry.key];
      if (latest != null) {
        _cart[entry.key] = CartItem(
          product: latest,
          quantity: entry.value.quantity,
        );
      }
    }
  }

  // Tải danh sách sản phẩm từ Firestore
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('ShopProducts').get();
      _products = snapshot.docs
          .map((doc) => ShopProduct.fromFirestore(doc.data(), doc.id))
          .toList();
      _refreshCartProductsWithCatalog();
    } catch (e) {
      _errorMessage = "Không thể tải danh sách sản phẩm: $e";
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String categoryKey) {
    _selectedCategoryKey = categoryKey;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  // Tìm sản phẩm theo ID
  ShopProduct? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // Gợi ý sản phẩm phù hợp với bệnh
  List<ShopProduct> getProductsForDisease(String diseaseName) {
    final lower = diseaseName.toLowerCase();
    return _products.where((p) {
      return p.indications.any((ind) => ind.toLowerCase().contains(lower)) ||
          p.description.toLowerCase().contains(lower);
    }).toList();
  }

  // --- CÁC HÀM XỬ LÝ GIỎ HÀNG ---
  void addToCart(ShopProduct product, {int quantity = 1}) {
    if (_cart.containsKey(product.id)) {
      _cart[product.id]!.quantity += quantity;
    } else {
      _cart[product.id] = CartItem(product: product, quantity: quantity);
    }
    _cartPulseTick++;
    notifyListeners();
    unawaited(_persistCart());
  }

  void decreaseQuantity(String productId) {
    if (!_cart.containsKey(productId)) return;
    if (_cart[productId]!.quantity > 1) {
      _cart[productId]!.quantity -= 1;
    } else {
      _cart.remove(productId);
    }
    notifyListeners();
    unawaited(_persistCart());
  }

  void removeFromCart(String productId) {
    _cart.remove(productId);
    notifyListeners();
    unawaited(_persistCart());
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
    unawaited(_persistCart());
  }

  // --- CÁC HÀM XỬ LÝ ĐƠN HÀNG (ORDERS COLLECTION) ---
  void _subscribeToOrders(String? uid) {
    _ordersSub?.cancel();
    if (uid == null || uid.isEmpty) {
      _orders = [];
      _isOrdersLoading = false;
      notifyListeners();
      return;
    }

    _isOrdersLoading = true;
    notifyListeners();

    _ordersSub = _firestore
        .collection('Orders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      final list = snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _orders = list;
      _isOrdersLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Lỗi lắng nghe đơn hàng: $e');
      _isOrdersLoading = false;
      notifyListeners();
    });
  }

  String _generateOrderCode() {
    final now = DateTime.now();
    final datePart =
        '${(now.year % 100).toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randPart = (1000 + Random().nextInt(9000)).toString();
    return 'FLR-$datePart-$randPart';
  }

  /// Tạo đơn hàng mới trên Firestore và làm trống giỏ hàng
  Future<OrderModel?> placeOrder({
    required ShippingAddress address,
    required String paymentMethod, // 'cod' hoặc 'card'
    required String paymentLabel,
  }) async {
    if (_cart.isEmpty) return null;
    final uid = _auth.currentUser?.uid ?? 'guest';
    final now = DateTime.now();
    final orderCode = _generateOrderCode();

    final orderItems = _cart.values
        .map((ci) => OrderItem(
              productId: ci.product.id,
              name: ci.product.name,
              imageUrl: ci.product.imageUrl,
              category: ci.product.category,
              price: ci.product.price,
              quantity: ci.quantity,
            ))
        .toList();

    final total = cartTotalAmount;
    final docRef = _firestore.collection('Orders').doc();

    final order = OrderModel(
      id: docRef.id,
      orderCode: orderCode,
      userId: uid,
      items: orderItems,
      totalAmount: total,
      recipientName: address.recipientName,
      recipientPhone: address.phone,
      shippingAddress: address.address,
      addressLabel: address.label,
      latitude: address.latitude,
      longitude: address.longitude,
      paymentMethod: paymentMethod,
      paymentLabel: paymentLabel,
      status: 'pending',
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(order.toFirestore());

    // Cập nhật lượt mua soldCount thực tế trên Firestore và danh sách local
    for (final item in orderItems) {
      try {
        _firestore.collection('ShopProducts').doc(item.productId).update({
          'soldCount': FieldValue.increment(item.quantity),
        });
        final pIdx = _products.indexWhere((p) => p.id == item.productId);
        if (pIdx != -1) {
          _products[pIdx] = _products[pIdx].copyWith(
            soldCount: _products[pIdx].soldCount + item.quantity,
          );
        }
      } catch (_) {}
    }

    // Sau khi tạo đơn thành công -> dọn sạch giỏ hàng
    clearCart();
    return order;
  }

  /// Cập nhật trạng thái đơn hàng (VD: hủy đơn hoặc xác nhận đã nhận hàng)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('Orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _orders[idx] = _orders[idx].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Lỗi cập nhật trạng thái đơn hàng: $e');
      return false;
    }
  }

  /// Gửi đánh giá cho đơn hàng đã hoàn thành kèm ảnh thực tế
  Future<bool> submitOrderReview({
    required String orderId,
    required int rating,
    required String reviewNote,
    List<String> reviewImages = const [],
    String? userDisplayName,
    String? userAvatarUrl,
    required List<OrderItem> items,
  }) async {
    try {
      final now = DateTime.now();
      // 1. Cập nhật trạng thái đơn hàng
      await _firestore.collection('Orders').doc(orderId).update({
        'isReviewed': true,
        'rating': rating,
        'reviewNote': reviewNote,
        if (reviewImages.isNotEmpty) 'reviewImages': reviewImages,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Lưu chi tiết đánh giá vào collection ProductReviews & cập nhật rating sản phẩm
      final batch = _firestore.batch();
      final currentUid = _auth.currentUser?.uid ?? 'guest';
      for (final item in items) {
        final reviewDoc = _firestore.collection('ProductReviews').doc();
        batch.set(reviewDoc, {
          'orderId': orderId,
          'productId': item.productId,
          'productName': item.name,
          'userId': currentUid,
          'userName': userDisplayName ?? 'Khách hàng Floria',
          'userAvatar': userAvatarUrl ?? '',
          'rating': rating,
          'comment': reviewNote,
          'images': reviewImages,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Cập nhật rating và reviewCount thật của sản phẩm
        final prod = getProductById(item.productId);
        if (prod != null) {
          final newCount = prod.reviewCount + 1;
          final newRating = double.parse((((prod.rating * prod.reviewCount) + rating) / newCount).toStringAsFixed(1));
          final prodDoc = _firestore.collection('ShopProducts').doc(item.productId);
          batch.update(prodDoc, {
            'rating': newRating,
            'reviewCount': FieldValue.increment(1),
          });

          final pIdx = _products.indexWhere((p) => p.id == item.productId);
          if (pIdx != -1) {
            _products[pIdx] = _products[pIdx].copyWith(
              rating: newRating,
              reviewCount: newCount,
            );
          }
        }
      }
      await batch.commit();

      // 3. Cập nhật ngay trong list local để UI đổi trạng thái tức thì
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _orders[idx] = _orders[idx].copyWith(
          isReviewed: true,
          rating: rating,
          reviewNote: reviewNote,
          reviewImages: reviewImages,
          reviewedAt: now,
          updatedAt: now,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Lỗi gửi đánh giá đơn hàng: $e');
      return false;
    }
  }

  /// Mua lại toàn bộ sản phẩm từ một đơn hàng cũ
  int reorderFromOrder(OrderModel order) {
    int addedCount = 0;
    for (final item in order.items) {
      final existingProduct = getProductById(item.productId) ??
          ShopProduct(
            id: item.productId,
            name: item.name,
            category: item.category,
            categoryKey: 'all',
            price: item.price,
            imageUrl: item.imageUrl,
            shortDesc: '',
            description: '',
            indications: const [],
            usageGuide: '',
          );
      addToCart(existingProduct, quantity: item.quantity);
      addedCount += item.quantity;
    }
    return addedCount;
  }
}
