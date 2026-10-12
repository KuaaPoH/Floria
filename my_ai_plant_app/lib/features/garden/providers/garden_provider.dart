import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/garden_plant.dart';

class GardenProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tên collection độc lập trên Firestore
  static const String collectionName = 'MyGarden';

  List<GardenPlant> _plants = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _plantsSubscription;

  List<GardenPlant> get plants => _plants;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Lấy danh sách cây cần chú ý (đến hạn tưới)
  List<GardenPlant> get attentionPlants =>
      _plants.where((p) => p.isNeedsWater).toList();

  // Danh sách các góc vườn (Zones) có trong khu vườn của người dùng
  List<String> get availableZones {
    final Set<String> zones = {"Tất cả", "Phòng khách", "Ban công", "Bàn làm việc"};
    for (var p in _plants) {
      if (p.zone.trim().isNotEmpty) {
        zones.add(p.zone.trim());
      }
    }
    return zones.toList();
  }

  // Lọc cây theo khu vực
  List<GardenPlant> getPlantsByZone(String zone) {
    if (zone == "Tất cả") return _plants;
    return _plants.where((p) => p.zone == zone).toList();
  }

  GardenProvider() {
    _initAuthListener();
  }

  // Tự động lắng nghe trạng thái đăng nhập để tải vườn của người dùng
  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _subscribeToUserGarden(user.uid);
      } else {
        _plantsSubscription?.cancel();
        _plants = [];
        notifyListeners();
      }
    });
  }

  // Đăng ký nhận dữ liệu thời gian thực từ Firestore collection riêng 'MyGarden'
  void _subscribeToUserGarden(String uid) {
    _isLoading = true;
    notifyListeners();

    _plantsSubscription?.cancel();
    _plantsSubscription = _firestore
        .collection(collectionName)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snapshot) {
        _plants = snapshot.docs.map((doc) => GardenPlant.fromFirestore(doc)).toList();
        // Sắp xếp cây mới nhất lên đầu (tránh cần composite index trên Firestore)
        _plants.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Lỗi tải dữ liệu khu vườn: $error");
        _errorMessage = "Không thể tải dữ liệu khu vườn: $error";
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Thêm một cây mới vào khu vườn trên Firestore (Collection riêng MyGarden)
  Future<bool> addPlant({
    required String nameVi,
    required String scientificName,
    String? nickname,
    required String zone,
    String? imageUrl,
    String plantType = 'Cây cảnh',
    int waterFrequencyDays = 3,
    String notes = '',
    Map<String, dynamic> wikiData = const {},
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = "Vui lòng đăng nhập để lưu cây vào vườn.";
      notifyListeners();
      return false;
    }

    try {
      final now = DateTime.now();
      final newPlant = GardenPlant(
        id: '', // Firestore sẽ tự sinh document ID
        userId: user.uid,
        nameVi: nameVi,
        scientificName: scientificName,
        nickname: nickname?.trim().isNotEmpty == true ? nickname! : nameVi,
        zone: zone,
        imageUrl: imageUrl,
        plantType: plantType,
        waterFrequencyDays: waterFrequencyDays,
        lastWatered: now,
        nextWatering: now.add(Duration(days: waterFrequencyDays)),
        healthStatus: 'Khỏe mạnh',
        notes: notes,
        wikiData: wikiData,
        createdAt: now,
      );

      await _firestore
          .collection(collectionName)
          .add(newPlant.toFirestore());

      return true;
    } catch (e) {
      debugPrint("Lỗi thêm cây vào vườn: $e");
      _errorMessage = "Lỗi khi lưu cây: $e";
      notifyListeners();
      return false;
    }
  }

  // Đánh dấu đã tưới nước cho cây
  Future<void> waterPlant(String plantId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final plantIndex = _plants.indexWhere((p) => p.id == plantId);
      if (plantIndex == -1) return;

      final plant = _plants[plantIndex];
      final now = DateTime.now();
      final nextDate = now.add(Duration(days: plant.waterFrequencyDays));

      await _firestore
          .collection(collectionName)
          .doc(plantId)
          .update({
        'lastWatered': Timestamp.fromDate(now),
        'nextWatering': Timestamp.fromDate(nextDate),
        'healthStatus': 'Khỏe mạnh',
      });
    } catch (e) {
      debugPrint("Lỗi cập nhật tưới nước: $e");
    }
  }

  // Xóa cây khỏi khu vườn
  Future<bool> removePlant(String plantId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore
          .collection(collectionName)
          .doc(plantId)
          .delete();
      return true;
    } catch (e) {
      debugPrint("Lỗi xóa cây khỏi vườn: $e");
      return false;
    }
  }

  // Đổi khu vực (góc vườn) cho cây
  Future<void> updatePlantZone(String plantId, String newZone) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection(collectionName)
          .doc(plantId)
          .update({'zone': newZone});
    } catch (e) {
      debugPrint("Lỗi cập nhật khu vực: $e");
    }
  }

  @override
  void dispose() {
    _plantsSubscription?.cancel();
    super.dispose();
  }
}
