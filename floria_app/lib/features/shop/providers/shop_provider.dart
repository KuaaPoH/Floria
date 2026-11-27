import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/gemini_service.dart';
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
  final Set<String> _selectedCartIds = {};
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
  int get cartCount =>
      _cart.values.fold(0, (total, item) => total + item.quantity);
  int get cartTotalAmount =>
      _cart.values.fold(0, (total, item) => total + item.totalPrice);
  int get cartPulseTick => _cartPulseTick;

  List<CartItem> get selectedCartItems => _cart.values
      .where((item) => _selectedCartIds.contains(item.product.id))
      .toList();
  int get selectedCartCount =>
      selectedCartItems.fold(0, (total, item) => total + item.quantity);
  int get selectedTotalAmount =>
      selectedCartItems.fold(0, (total, item) => total + item.totalPrice);
  bool get isAllCartSelected =>
      _cart.isNotEmpty &&
      _cart.keys.every((id) => _selectedCartIds.contains(id));

  bool isCartItemSelected(String productId) =>
      _selectedCartIds.contains(productId);

  String get formattedSelectedTotal {
    final s = selectedTotalAmount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return '${buffer.toString().split('').reversed.join('')}đ';
  }

  void toggleCartItemSelection(String productId) {
    if (_selectedCartIds.contains(productId)) {
      _selectedCartIds.remove(productId);
    } else if (_cart.containsKey(productId)) {
      _selectedCartIds.add(productId);
    }
    notifyListeners();
  }

  void toggleSelectAllCart(bool selectAll) {
    if (selectAll) {
      _selectedCartIds
        ..clear()
        ..addAll(_cart.keys);
    } else {
      _selectedCartIds.clear();
    }
    notifyListeners();
  }

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
      final matchesCategory =
          _selectedCategoryKey == 'all' ||
          p.categoryKey == _selectedCategoryKey;
      final matchesQuery =
          _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.shortDesc.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.indications.any(
            (ind) => ind.toLowerCase().contains(_searchQuery.toLowerCase()),
          );
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
    return uid != null && uid.isNotEmpty
        ? 'floria_cart_$uid'
        : 'floria_cart_guest';
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
              final cartItem = CartItem.fromMap(
                Map<String, dynamic>.from(item),
              );
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
                  final cartItem = CartItem.fromMap(
                    Map<String, dynamic>.from(item),
                  );
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
      _selectedCartIds
        ..clear()
        ..addAll(loaded.keys);
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

  // Cập nhật thông tin sản phẩm mới nhất cho các món trong giỏ & lọc sản phẩm đã bị Admin ẩn
  void _refreshCartProductsWithCatalog() {
    if (_products.isEmpty || _cart.isEmpty) return;
    final catalogMap = {for (final p in _products) p.id: p};
    bool cartChanged = false;
    for (final entry in _cart.entries.toList()) {
      final latest = catalogMap[entry.key];
      if (latest == null) {
        _cart.remove(entry.key);
        _selectedCartIds.remove(entry.key);
        cartChanged = true;
      } else {
        final clampedQty = latest.stock > 0
            ? min(entry.value.quantity, latest.stock)
            : entry.value.quantity;
        if (clampedQty != entry.value.quantity) cartChanged = true;
        _cart[entry.key] = CartItem(product: latest, quantity: clampedQty);
      }
    }
    if (cartChanged) {
      unawaited(_persistCart());
    }
  }

  // Tải danh sách sản phẩm từ Firestore (chỉ lấy sản phẩm đang hiển thị visible != false)
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('ShopProducts').get();
      _products = snapshot.docs
          .map((doc) => ShopProduct.fromFirestore(doc.data(), doc.id))
          .where((p) => p.visible)
          .toList();
      GeminiService.updateProductCatalog(_products);
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
  bool addToCart(ShopProduct product, {int quantity = 1}) {
    if (product.isOutOfStock || quantity <= 0) {
      return false;
    }
    final existingQty = _cart[product.id]?.quantity ?? 0;
    if (existingQty >= product.stock) {
      return false;
    }
    final nextQty = min(product.stock, existingQty + quantity);
    _cart[product.id] = CartItem(product: product, quantity: nextQty);
    _selectedCartIds.add(product.id);
    _cartPulseTick++;
    notifyListeners();
    unawaited(_persistCart());
    return true;
  }

  void decreaseQuantity(String productId) {
    if (!_cart.containsKey(productId)) return;
    if (_cart[productId]!.quantity > 1) {
      _cart[productId]!.quantity -= 1;
    } else {
      _cart.remove(productId);
      _selectedCartIds.remove(productId);
    }
    notifyListeners();
    unawaited(_persistCart());
  }

  void removeFromCart(String productId) {
    _cart.remove(productId);
    _selectedCartIds.remove(productId);
    notifyListeners();
    unawaited(_persistCart());
  }

  void clearCart() {
    _cart.clear();
    _selectedCartIds.clear();
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
        .listen(
          (snapshot) {
            final list = snapshot.docs
                .map((doc) => OrderModel.fromFirestore(doc))
                .toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _orders = list;
            _isOrdersLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('Lỗi lắng nghe đơn hàng: $e');
            _isOrdersLoading = false;
            notifyListeners();
          },
        );
  }

  String _generateOrderCode() {
    final now = DateTime.now();
    final datePart =
        '${(now.year % 100).toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randPart = (1000 + Random().nextInt(9000)).toString();
    return 'FLR-$datePart-$randPart';
  }

  DateTime? _parseVoucherExpiry(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(raw.trim());
      if (parsed != null) {
        // Nếu chuỗi ngày ở dạng 00:00:00Z thì hiểu là hết ngày hôm đó
        if (!raw.contains('T') || raw.endsWith('T00:00:00.000Z')) {
          return DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
        }
        return parsed;
      }
    }
    return null;
  }

  /// Lấy danh sách mã giảm giá đang hoạt động từ Firestore (`Vouchers` collection)
  Future<List<Map<String, dynamic>>> fetchActiveVouchers() async {
    try {
      final snap = await _firestore.collection('Vouchers').get();
      final now = DateTime.now();
      final List<Map<String, dynamic>> activeList = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['active'] == false || data['isActive'] == false) continue;
        final expiry = _parseVoucherExpiry(
          data['expiresAt'] ?? data['expiryDate'],
        );
        if (expiry != null && now.isAfter(expiry)) continue;
        final maxUsage = (data['maxUsage'] as num?)?.toInt() ?? 0;
        final used = (data['used'] as num?)?.toInt() ?? 0;
        if (maxUsage > 0 && used >= maxUsage) continue;

        final code = (data['code'] ?? doc.id).toString().trim().toUpperCase();
        final type = (data['discountType'] ?? data['type'] ?? 'fixed')
            .toString();
        final value =
            (data['discountValue'] ?? data['value'] as num?)?.toInt() ?? 0;
        final minOrder =
            (data['minOrderAmount'] ?? data['minOrder'] as num?)?.toInt() ?? 0;
        activeList.add({
          'docId': doc.id,
          'code': code,
          'type': type,
          'value': value,
          'minOrder': minOrder,
        });
      }
      return activeList;
    } catch (e) {
      debugPrint('Lỗi tải danh sách voucher: $e');
      return [];
    }
  }

  /// Kiểm tra mã giảm giá thực tế từ Firestore (`Vouchers` collection)
  Future<Map<String, dynamic>?> validateVoucher(
    String rawCode,
    int subtotal,
  ) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return null;

    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('Vouchers')
          .doc(code)
          .get();
      if (!doc.exists || doc.data() == null) {
        final querySnap = await _firestore
            .collection('Vouchers')
            .where('code', isEqualTo: code)
            .limit(1)
            .get();
        if (querySnap.docs.isEmpty) {
          return {'valid': false, 'reason': 'Mã giảm giá không tồn tại.'};
        }
        doc = querySnap.docs.first;
      }

      final data = doc.data()!;
      if (data['active'] == false || data['isActive'] == false) {
        return {'valid': false, 'reason': 'Mã giảm giá hiện đang tạm ngưng.'};
      }

      final expiry = _parseVoucherExpiry(
        data['expiresAt'] ?? data['expiryDate'],
      );
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        return {'valid': false, 'reason': 'Mã giảm giá đã hết hạn sử dụng.'};
      }

      final maxUsage = (data['maxUsage'] as num?)?.toInt() ?? 0;
      final used = (data['used'] as num?)?.toInt() ?? 0;
      if (maxUsage > 0 && used >= maxUsage) {
        return {'valid': false, 'reason': 'Mã giảm giá đã hết lượt sử dụng.'};
      }

      final minOrder =
          (data['minOrderAmount'] ?? data['minOrder'] as num?)?.toInt() ?? 0;
      if (subtotal < minOrder) {
        return {
          'valid': false,
          'reason':
              'Đơn tối thiểu ${formatCurrency(minOrder)} để áp dụng mã này.',
        };
      }

      final discountType = (data['discountType'] ?? data['type'] ?? 'fixed')
          .toString();
      final discountValue =
          (data['discountValue'] ?? data['value'] as num?)?.toInt() ?? 0;
      final maxDiscount = (data['maxDiscount'] as num?)?.toInt() ?? 0;

      int discountAmount = discountType == 'percent'
          ? ((subtotal * discountValue) / 100).round()
          : discountValue;

      if (maxDiscount > 0 && discountAmount > maxDiscount) {
        discountAmount = maxDiscount;
      }
      if (discountAmount > subtotal) {
        discountAmount = subtotal;
      }

      final normalizedCode = (data['code'] ?? doc.id)
          .toString()
          .trim()
          .toUpperCase();
      return {
        'valid': true,
        'voucherDocId': doc.id,
        'code': normalizedCode,
        'discountAmount': discountAmount,
        'description':
            data['description']?.toString() ??
            (discountType == 'percent'
                ? 'Giảm $discountValue% cho đơn từ ${formatCurrency(minOrder)}'
                : 'Giảm ${formatCurrency(discountValue)} cho đơn từ ${formatCurrency(minOrder)}'),
      };
    } catch (e) {
      debugPrint('Lỗi kiểm tra voucher: $e');
      return null;
    }
  }

  String formatCurrency(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return '${buffer.toString().split('').reversed.join('')}đ';
  }

  /// Tạo đơn hàng mới trên Firestore, trừ tồn kho (stock), ghi lịch sử xuất kho và tăng lượt dùng voucher
  Future<OrderModel?> placeOrder({
    required ShippingAddress address,
    required String paymentMethod, // 'cod' hoặc 'zalopay'
    required String paymentLabel,
    String? paymentStatus,
    String? appTransId,
    List<CartItem>? itemsToOrder,
    int discountAmount = 0,
    String? voucherCode,
    String? voucherDocId,
  }) async {
    final sourceItems = (itemsToOrder != null && itemsToOrder.isNotEmpty)
        ? itemsToOrder
        : _cart.values.toList();
    if (sourceItems.isEmpty) return null;

    _errorMessage = null;
    final uid = _auth.currentUser?.uid ?? 'guest';
    final now = DateTime.now();
    final nowIso = now.toIso8601String();
    final orderCode = _generateOrderCode();

    final orderItems = sourceItems
        .map(
          (ci) => OrderItem(
            productId: ci.product.id,
            name: ci.product.name,
            imageUrl: ci.product.imageUrl,
            category: ci.product.category,
            price: ci.product.price,
            quantity: ci.quantity,
          ),
        )
        .toList();

    final subtotal = sourceItems.fold<int>(
      0,
      (total, item) => total + item.totalPrice,
    );
    final total = max(0, subtotal - discountAmount);
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
      paymentStatus:
          paymentStatus ?? (paymentMethod == 'zalopay' ? 'paid' : 'unpaid'),
      appTransId: appTransId,
      status: 'pending',
      createdAt: now,
      updatedAt: now,
    );

    final Map<String, int> updatedStockById = {};

    try {
      await _firestore.runTransaction((tx) async {
        // 1. Đọc kiểm tra tồn kho thực tế của tất cả sản phẩm trước khi ghi
        final Map<String, int> currentStocks = {};
        final Map<String, DocumentReference<Map<String, dynamic>>> prodRefs =
            {};

        for (final item in orderItems) {
          final pRef = _firestore
              .collection('ShopProducts')
              .doc(item.productId);
          final pSnap = await tx.get(pRef);
          if (!pSnap.exists || pSnap.data() == null) {
            throw Exception('Sản phẩm "${item.name}" không còn tồn tại.');
          }
          final pData = pSnap.data()!;
          if (pData['visible'] == false) {
            throw Exception(
              'Sản phẩm "${item.name}" hiện đã ngừng kinh doanh.',
            );
          }
          final currentStock =
              (pData['stock'] as num?)?.toInt() ??
              ((pData['inStock'] ?? true) ? 25 : 0);
          if (currentStock < item.quantity) {
            throw Exception(
              currentStock <= 0
                  ? 'Sản phẩm "${item.name}" đã hết hàng.'
                  : 'Sản phẩm "${item.name}" chỉ còn $currentStock trong kho.',
            );
          }
          currentStocks[item.productId] = currentStock;
          prodRefs[item.productId] = pRef;
        }

        // 2. Đọc & kiểm tra voucher (nếu có) trước khi ghi
        DocumentReference<Map<String, dynamic>>? voucherRef;
        DocumentSnapshot<Map<String, dynamic>>? voucherSnap;
        final trimmedCode = voucherCode?.trim().toUpperCase();
        if (trimmedCode != null && trimmedCode.isNotEmpty) {
          voucherRef = _firestore
              .collection('Vouchers')
              .doc(
                (voucherDocId != null && voucherDocId.isNotEmpty)
                    ? voucherDocId
                    : trimmedCode,
              );
          voucherSnap = await tx.get(voucherRef);
          if (voucherSnap.exists && voucherSnap.data() != null) {
            final vData = voucherSnap.data()!;
            if (vData['active'] == false || vData['isActive'] == false) {
              throw Exception('Mã giảm giá $trimmedCode đã bị tạm ngưng.');
            }
            final maxUsage = (vData['maxUsage'] as num?)?.toInt() ?? 0;
            final used = (vData['used'] as num?)?.toInt() ?? 0;
            if (maxUsage > 0 && used >= maxUsage) {
              throw Exception('Mã giảm giá $trimmedCode đã hết lượt sử dụng.');
            }
          }
        }

        // 3. Tạo đơn hàng
        final orderPayload = order.toFirestore();
        if (trimmedCode != null && trimmedCode.isNotEmpty) {
          orderPayload['voucherCode'] = trimmedCode;
          orderPayload['discountAmount'] = discountAmount;
        }
        tx.set(docRef, orderPayload);

        // 4. Trừ stock, cập nhật soldCount & ghi lịch sử xuất kho InventoryTransactions
        for (final item in orderItems) {
          final pRef = prodRefs[item.productId]!;
          final newStock =
              (currentStocks[item.productId] ?? item.quantity) - item.quantity;
          updatedStockById[item.productId] = newStock;
          tx.update(pRef, {
            'stock': newStock,
            'inStock': newStock > 0,
            'soldCount': FieldValue.increment(item.quantity),
            'updatedAt': nowIso,
          });

          final txRef = _firestore.collection('InventoryTransactions').doc();
          tx.set(txRef, {
            'productId': item.productId,
            'productName': item.name,
            'type': 'out',
            'qty': item.quantity,
            'note': 'Xuất kho đơn hàng $orderCode',
            'by': address.recipientName.isNotEmpty
                ? address.recipientName
                : 'Khách hàng App',
            'at': nowIso,
            'orderId': docRef.id,
            'orderCode': orderCode,
          });
        }

        // 5. Tăng lượt sử dụng voucher
        if (voucherRef != null && voucherSnap != null && voucherSnap.exists) {
          tx.update(voucherRef, {'used': FieldValue.increment(1)});
        }
      });

      // Đồng bộ lại state local ngay lập tức
      for (final item in orderItems) {
        final pIdx = _products.indexWhere((p) => p.id == item.productId);
        if (pIdx != -1) {
          final newStock =
              updatedStockById[item.productId] ??
              max(0, _products[pIdx].stock - item.quantity);
          _products[pIdx] = _products[pIdx].copyWith(
            stock: newStock,
            inStock: newStock > 0,
            soldCount: _products[pIdx].soldCount + item.quantity,
          );
        }
      }

      for (final item in orderItems) {
        _cart.remove(item.productId);
        _selectedCartIds.remove(item.productId);
      }
      notifyListeners();
      unawaited(_persistCart());
      return order;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Lỗi đặt hàng: $_errorMessage');
      notifyListeners();
      return null;
    }
  }

  /// Cập nhật trạng thái đơn hàng (VD: hủy đơn hoàn kho hoặc xác nhận đã nhận hàng)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      if (newStatus == 'cancelled') {
        final nowIso = DateTime.now().toIso8601String();
        String nextPaymentStatus = 'unpaid';
        final Map<String, int> restoredStocks = {};
        final Map<String, int> restoredSoldCounts = {};

        await _firestore.runTransaction((tx) async {
          final orderRef = _firestore.collection('Orders').doc(orderId);
          final orderSnap = await tx.get(orderRef);
          if (!orderSnap.exists || orderSnap.data() == null) {
            throw Exception('Không tìm thấy đơn hàng.');
          }
          final od = orderSnap.data()!;
          final curStatus = (od['status'] ?? 'pending').toString();
          if (curStatus != 'pending') {
            throw Exception('Đơn hàng này không thể hủy.');
          }

          final curPaymentStatus =
              (od['paymentStatus'] ??
                      (od['paymentMethod'] == 'zalopay' ? 'paid' : 'unpaid'))
                  .toString();
          nextPaymentStatus = curPaymentStatus == 'paid'
              ? 'refunded'
              : curPaymentStatus;
          final orderCode = (od['orderCode'] ?? orderId).toString();

          final rawItems = od['items'];
          final List<Map<String, dynamic>> items = rawItems is List
              ? rawItems
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
              : [];

          // 1. ALL READS: đọc tồn kho tất cả sản phẩm trước khi ghi
          final List<DocumentSnapshot<Map<String, dynamic>>> prodSnaps = [];
          final List<int> qtys = [];
          for (final item in items) {
            final pid = (item['productId'] ?? '').toString();
            final qty = (item['quantity'] as num?)?.toInt() ?? 1;
            if (pid.isEmpty || qty <= 0) continue;
            final pSnap = await tx.get(
              _firestore.collection('ShopProducts').doc(pid),
            );
            prodSnaps.add(pSnap);
            qtys.add(qty);
          }

          // 2. ALL WRITES: hoàn kho + ghi lịch sử nhập kho + cập nhật đơn hàng
          for (int i = 0; i < prodSnaps.length; i++) {
            final pSnap = prodSnaps[i];
            final qty = qtys[i];
            if (pSnap.exists && pSnap.data() != null) {
              final pd = pSnap.data()!;
              final curStock = (pd['stock'] as num?)?.toInt() ?? 0;
              final nextStock = curStock + qty;
              final nextSold = max(
                0,
                ((pd['soldCount'] as num?)?.toInt() ?? 0) - qty,
              );
              restoredStocks[pSnap.id] = nextStock;
              restoredSoldCounts[pSnap.id] = nextSold;

              tx.update(pSnap.reference, {
                'stock': nextStock,
                'inStock': nextStock > 0,
                'soldCount': nextSold,
                'updatedAt': nowIso,
              });

              tx.set(_firestore.collection('InventoryTransactions').doc(), {
                'productId': pSnap.id,
                'productName': (pd['name'] ?? '').toString(),
                'type': 'in',
                'qty': qty,
                'previousStock': curStock,
                'newStock': nextStock,
                'note': 'Hoàn kho hủy đơn #$orderCode',
                'at': nowIso,
                'createdAt': nowIso,
                'orderId': orderId,
                'orderCode': orderCode,
              });
            }
          }

          tx.update(orderRef, {
            'status': 'cancelled',
            'paymentStatus': nextPaymentStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });

        // Đồng bộ cache local
        for (final entry in restoredStocks.entries) {
          final pIdx = _products.indexWhere((p) => p.id == entry.key);
          if (pIdx != -1) {
            _products[pIdx] = _products[pIdx].copyWith(
              stock: entry.value,
              inStock: entry.value > 0,
              soldCount:
                  restoredSoldCounts[entry.key] ?? _products[pIdx].soldCount,
            );
          }
        }
        final idx = _orders.indexWhere((o) => o.id == orderId);
        if (idx != -1) {
          _orders[idx] = _orders[idx].copyWith(
            status: 'cancelled',
            paymentStatus: nextPaymentStatus,
            updatedAt: DateTime.now(),
          );
        }
        notifyListeners();
        return true;
      }

      final Map<String, dynamic> updatePayload = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (newStatus == 'completed') {
        updatePayload['paymentStatus'] = 'paid';
      }

      await _firestore.collection('Orders').doc(orderId).update(updatePayload);
      final idx = _orders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _orders[idx] = _orders[idx].copyWith(
          status: newStatus,
          paymentStatus: newStatus == 'completed' ? 'paid' : null,
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
          final newRating = double.parse(
            (((prod.rating * prod.reviewCount) + rating) / newCount)
                .toStringAsFixed(1),
          );
          final prodDoc = _firestore
              .collection('ShopProducts')
              .doc(item.productId);
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
      final existingProduct =
          getProductById(item.productId) ??
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
