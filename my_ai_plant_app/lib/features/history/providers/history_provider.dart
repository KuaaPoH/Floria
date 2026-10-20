import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/scan_history_item.dart';

class HistoryProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String historyCollection = 'ScanHistory';

  List<ScanHistoryItem> _historyList = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _subscription;

  String _selectedFilter = 'all'; // 'all', 'plant_discovery', 'disease_diagnosis'
  String _searchQuery = '';

  List<ScanHistoryItem> get allItems => _historyList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  int get totalCount => _historyList.length;
  int get plantCount => _historyList.where((i) => !i.isDisease).length;
  int get diseaseCount => _historyList.where((i) => i.isDisease).length;

  List<ScanHistoryItem> get filteredItems {
    return _historyList.where((item) {
      // 1. Lọc theo tab
      if (_selectedFilter == 'plant_discovery' && item.isDisease) return false;
      if (_selectedFilter == 'disease_diagnosis' && !item.isDisease) return false;

      // 2. Lọc theo từ khóa tìm kiếm
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final nameMatch = item.displayName.toLowerCase().contains(q);
        final sciMatch = item.cleanPrediction.toLowerCase().contains(q);
        final plantMatch = item.plantName.toLowerCase().contains(q);
        return nameMatch || sciMatch || plantMatch;
      }
      return true;
    }).toList();
  }

  HistoryProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    // Kích hoạt lắng nghe ngay lập tức cho người dùng hiện tại (nếu có) hoặc anonymous
    final currentUser = _auth.currentUser;
    _subscribeToHistory(currentUser?.uid);

    _auth.authStateChanges().listen((User? user) {
      _subscribeToHistory(user?.uid);
    });
  }

  void _subscribeToHistory(String? uid) {
    if (uid == null || uid.isEmpty) {
      _historyList = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();

    _subscription = _firestore
        .collection(historyCollection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snapshot) {
        _historyList = snapshot.docs
            .map((doc) => ScanHistoryItem.fromFirestore(doc))
            .toList();

        // Sắp xếp thời gian quét mới nhất lên đầu
        _historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Lỗi tải lịch sử quét: $error");
        _errorMessage = "Không thể tải lịch sử quét: $error";
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Xóa 1 bản ghi lịch sử
  Future<bool> deleteItem(String id) async {
    try {
      await _firestore.collection(historyCollection).doc(id).delete();
      return true;
    } catch (e) {
      debugPrint("Lỗi xóa bản ghi lịch sử: $e");
      return false;
    }
  }

  // Xóa toàn bộ lịch sử quét của người dùng
  Future<bool> clearAllHistory() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final snapshot = await _firestore
          .collection(historyCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint("Lỗi dọn dẹp lịch sử: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
