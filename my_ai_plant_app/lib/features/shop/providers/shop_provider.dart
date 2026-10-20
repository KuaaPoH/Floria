import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/shop_product.dart';

class ShopProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ShopProduct> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _selectedCategoryKey = 'all';
  String _searchQuery = '';

  // Giỏ hàng
  final Map<String, CartItem> _cart = {};

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
    fetchProducts();
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
    notifyListeners();
  }

  void decreaseQuantity(String productId) {
    if (!_cart.containsKey(productId)) return;
    if (_cart[productId]!.quantity > 1) {
      _cart[productId]!.quantity -= 1;
    } else {
      _cart.remove(productId);
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cart.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}
