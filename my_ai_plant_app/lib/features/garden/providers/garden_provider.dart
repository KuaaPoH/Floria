import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/garden_plant.dart';
import '../models/user_garden.dart';

class GardenProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Tên collection độc lập trên Firestore
  static const String plantsCollection = 'MyGarden';
  static const String gardensCollection = 'UserGardens';

  List<UserGarden> _gardens = [];
  UserGarden? _selectedGarden;
  StreamSubscription<QuerySnapshot>? _gardensSubscription;

  List<GardenPlant> _plants = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _plantsSubscription;

  List<UserGarden> get gardens => _gardens;
  UserGarden? get selectedGarden => _selectedGarden;
  bool get hasGarden => _gardens.isNotEmpty;

  List<GardenPlant> get plants {
    if (_selectedGarden == null) return _plants;
    return _plants.where((p) => p.gardenId.isEmpty || p.gardenId == _selectedGarden!.id).toList();
  }
  List<GardenPlant> get allUserPlants => _plants;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Lấy danh sách cây cần chú ý (đến hạn tưới)
  List<GardenPlant> get attentionPlants =>
      plants.where((p) => p.isNeedsWater).toList();

  // Danh sách các góc vườn (Zones) - CHỈ hiển thị những vị trí thực tế người dùng đã thêm cây
  List<String> get availableZones {
    final Set<String> zones = {"Tất cả"};
    for (var p in plants) {
      final z = p.zone.trim();
      if (z.isNotEmpty) {
        zones.add(z);
      }
    }
    return zones.toList();
  }

  // Lọc cây theo khu vực
  List<GardenPlant> getPlantsByZone(String zone) {
    final currentPlants = plants;
    if (zone == "Tất cả") return currentPlants;
    return currentPlants.where((p) => p.zone == zone).toList();
  }

  GardenProvider() {
    _initAuthListener();
  }

  // Tự động lắng nghe trạng thái đăng nhập để tải vườn của người dùng
  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _subscribeToUserGardens(user.uid);
        _subscribeToUserPlants(user.uid);
      } else {
        _gardensSubscription?.cancel();
        _plantsSubscription?.cancel();
        _gardens = [];
        _selectedGarden = null;
        _plants = [];
        notifyListeners();
      }
    });
  }

  // Đăng ký nhận dữ liệu danh sách khu vườn từ Firestore
  void _subscribeToUserGardens(String uid) {
    _gardensSubscription?.cancel();
    _gardensSubscription = _firestore
        .collection(gardensCollection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snapshot) {
        _gardens = snapshot.docs.map((doc) => UserGarden.fromFirestore(doc)).toList();
        _gardens.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        if (_gardens.isNotEmpty) {
          // Giữ vườn đang chọn nếu còn tồn tại, nếu không chọn vườn đầu tiên
          final matched = _gardens.firstWhere(
            (g) => g.id == _selectedGarden?.id,
            orElse: () => _gardens.first,
          );
          _selectedGarden = matched;
        } else {
          _selectedGarden = null;
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Lỗi tải danh sách khu vườn: $error");
      },
    );
  }

  // Chọn khu vườn hiện tại để xem
  void selectGarden(UserGarden garden) {
    _selectedGarden = garden;
    notifyListeners();
  }

  // Tạo khu vườn mới
  Future<bool> createGarden({
    required String name,
    required String environment,
    required String lightCondition,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = "Vui lòng đăng nhập để tạo khu vườn.";
      notifyListeners();
      return false;
    }

    try {
      final newGarden = UserGarden(
        id: '',
        userId: user.uid,
        name: name.trim(),
        environment: environment,
        lightCondition: lightCondition,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(gardensCollection)
          .add(newGarden.toFirestore());

      // Chọn ngay vườn vừa tạo
      _selectedGarden = newGarden.copyWith(id: docRef.id, name: name.trim());
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Lỗi tạo khu vườn: $e");
      _errorMessage = "Không thể tạo khu vườn: $e";
      notifyListeners();
      return false;
    }
  }

  // Xóa khu vườn
  Future<bool> deleteGarden(String gardenId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection(gardensCollection).doc(gardenId).delete();
      return true;
    } catch (e) {
      debugPrint("Lỗi xóa khu vườn: $e");
      return false;
    }
  }

  // Đăng ký nhận dữ liệu thời gian thực cây trồng từ Firestore collection 'MyGarden'
  void _subscribeToUserPlants(String uid) {
    _isLoading = true;
    notifyListeners();

    _plantsSubscription?.cancel();
    _plantsSubscription = _firestore
        .collection(plantsCollection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snapshot) {
        _plants = snapshot.docs.map((doc) => GardenPlant.fromFirestore(doc)).toList();
        // Sắp xếp cây mới nhất lên đầu
        _plants.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Lỗi tải dữ liệu cây trồng: $error");
        _errorMessage = "Không thể tải dữ liệu khu vườn: $error";
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Thêm một cây mới vào khu vườn trên Firestore (Collection riêng MyGarden)
  Future<bool> addPlant({
    String? gardenId,
    required String nameVi,
    required String scientificName,
    String? nickname,
    required String zone,
    String? imageUrl,
    String plantType = 'Cây cảnh',
    int waterFrequencyDays = 3,
    String reminderTime = '07:00',
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
      final targetGardenId = gardenId ?? _selectedGarden?.id ?? '';
      final newPlant = GardenPlant(
        id: '', // Firestore sẽ tự sinh document ID
        userId: user.uid,
        gardenId: targetGardenId,
        nameVi: nameVi,
        scientificName: scientificName,
        nickname: nickname?.trim().isNotEmpty == true ? nickname! : nameVi,
        zone: zone,
        imageUrl: imageUrl,
        plantType: plantType,
        waterFrequencyDays: waterFrequencyDays,
        reminderTime: reminderTime,
        lastWatered: now,
        nextWatering: now.add(Duration(days: waterFrequencyDays)),
        healthStatus: 'Khỏe mạnh',
        notes: notes,
        wikiData: wikiData,
        createdAt: now,
      );

      await _firestore
          .collection(plantsCollection)
          .add(newPlant.toFirestore());

      return true;
    } catch (e) {
      debugPrint("Lỗi thêm cây vào vườn: $e");
      _errorMessage = "Lỗi khi lưu cây: $e";
      notifyListeners();
      return false;
    }
  }

  // Cập nhật lịch chăm sóc cây (chu kỳ tưới và giờ nhắc nhở)
  Future<bool> updatePlantCareSchedule(
    String plantId, {
    required int waterFrequencyDays,
    required String reminderTime,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final plantIndex = _plants.indexWhere((p) => p.id == plantId);
      if (plantIndex == -1) return false;

      final plant = _plants[plantIndex];
      final nextDate = plant.lastWatered.add(Duration(days: waterFrequencyDays));

      await _firestore.collection(plantsCollection).doc(plantId).update({
        'waterFrequencyDays': waterFrequencyDays,
        'reminderTime': reminderTime,
        'nextWatering': Timestamp.fromDate(nextDate),
      });

      return true;
    } catch (e) {
      debugPrint("Lỗi cập nhật lịch chăm sóc: $e");
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
          .collection(plantsCollection)
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
          .collection(plantsCollection)
          .doc(plantId)
          .delete();
      return true;
    } catch (e) {
      debugPrint("Lỗi xóa cây khỏi vườn: $e");
      return false;
    }
  }

  // Cập nhật thông tin chi tiết của cây: Tên biệt danh, Vị trí, Tần suất tưới, Giờ nhắc, Tình trạng sức khỏe, Ghi chú
  Future<bool> updatePlantInfo(
    String plantId, {
    required String nickname,
    required String zone,
    required int waterFrequencyDays,
    required String reminderTime,
    required String healthStatus,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final plantIndex = _plants.indexWhere((p) => p.id == plantId);
      if (plantIndex == -1) return false;

      final plant = _plants[plantIndex];
      final nextDate = plant.lastWatered.add(Duration(days: waterFrequencyDays));

      final Map<String, dynamic> updateData = {
        'nickname': nickname.trim().isNotEmpty ? nickname.trim() : plant.nameVi,
        'zone': zone.trim().isNotEmpty ? zone.trim() : 'Phòng khách',
        'waterFrequencyDays': waterFrequencyDays,
        'reminderTime': reminderTime,
        'healthStatus': healthStatus,
        'nextWatering': Timestamp.fromDate(nextDate),
      };

      if (notes != null) {
        updateData['notes'] = notes.trim();
      }

      await _firestore.collection(plantsCollection).doc(plantId).update(updateData);
      return true;
    } catch (e) {
      debugPrint("Lỗi cập nhật thông tin cây: $e");
      return false;
    }
  }

  // Đổi khu vực (góc vườn) cho cây
  Future<void> updatePlantZone(String plantId, String newZone) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection(plantsCollection)
          .doc(plantId)
          .update({'zone': newZone});
    } catch (e) {
      debugPrint("Lỗi cập nhật khu vực: $e");
    }
  }

  @override
  void dispose() {
    _gardensSubscription?.cancel();
    _plantsSubscription?.cancel();
    super.dispose();
  }
}
