import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../profile/models/user_checkout_models.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '896398806405-b4fvkufof9iph4i8oguseiaf714jfup3.apps.googleusercontent.com'
        : null,
  );

  bool _isLoggedIn = false;
  String? _userId;
  String? _userName;
  String? _userEmail;
  String? _userPhone;
  String? _userAddress;
  String _paymentMethod = 'vnpay'; // 'vnpay' hoặc 'cod'
  List<ShippingAddress> _addresses = [];
  List<SavedPaymentCard> _savedCards = [];
  String? _googlePhotoUrl;
  String? _customPhotoUrl;
  String? _bio;
  bool _isUploadingAvatar = false;
  bool _isPremium = false;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userPhone => _userPhone;
  String? get userAddress => _userAddress;
  String get paymentMethod => _paymentMethod;
  List<ShippingAddress> get addresses => _addresses;
  List<SavedPaymentCard> get savedCards => _savedCards;
  String? get bio => _bio;
  String? get googlePhotoUrl => _googlePhotoUrl;
  String? get customPhotoUrl => _customPhotoUrl;
  bool get isUploadingAvatar => _isUploadingAvatar;
  bool get isPremium => _isPremium;
  bool get hasCustomAvatar => _customPhotoUrl != null && _customPhotoUrl!.trim().isNotEmpty;

  ShippingAddress? get defaultAddress {
    if (_addresses.isEmpty) return null;
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.first;
    }
  }

  SavedPaymentCard? get defaultCard {
    if (_savedCards.isEmpty) return null;
    try {
      return _savedCards.firstWhere((c) => c.isDefault);
    } catch (_) {
      return _savedCards.first;
    }
  }

  /// Đường dẫn ảnh đại diện có hiệu lực:
  /// 1. Ưu tiên ảnh đại diện tùy chỉnh (customPhotoUrl) được tải lên trong ứng dụng
  /// 2. Nếu không có, dùng ảnh đại diện Google (googlePhotoUrl / user.photoURL)
  /// 3. Nếu không có cả 2, trả về null để giao diện dùng chữ cái đầu hoặc avatar mặc định
  String? get effectivePhotoUrl {
    if (_customPhotoUrl != null && _customPhotoUrl!.trim().isNotEmpty) {
      return _customPhotoUrl;
    }
    if (_googlePhotoUrl != null && _googlePhotoUrl!.trim().isNotEmpty) {
      return _googlePhotoUrl;
    }
    if (_auth.currentUser?.photoURL != null && _auth.currentUser!.photoURL!.trim().isNotEmpty) {
      return _auth.currentUser!.photoURL;
    }
    return null;
  }

  AuthProvider() {
    // Lắng nghe sự thay đổi trạng thái đăng nhập và cập nhật hồ sơ (userChanges)
    _auth.userChanges().listen((User? user) {
      if (user != null && user.emailVerified) {
        _isLoggedIn = true;
        _userId = user.uid;
        _userName = user.displayName ?? "Nông Nghiệp Thông Minh";
        _userEmail = user.email;
        _googlePhotoUrl = user.photoURL;
        _subscribeToUserProfile(user.uid, user);
      } else {
        _userDocSubscription?.cancel();
        _userDocSubscription = null;
        _isLoggedIn = false;
        _userId = null;
        _userName = null;
        _userEmail = null;
        _userPhone = null;
        _userAddress = null;
        _googlePhotoUrl = null;
        _customPhotoUrl = null;
        _bio = null;
        _isPremium = false;
      }
      notifyListeners();
    });
  }

  /// Đồng bộ và lắng nghe thông tin hồ sơ chi tiết (avatar riêng, tiểu sử, sđt, địa chỉ) từ Firestore Users/{uid}
  void _subscribeToUserProfile(String uid, User user) {
    _userDocSubscription?.cancel();
    _userDocSubscription = _firestore.collection('Users').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        _customPhotoUrl = data['customPhotoUrl'] as String?;
        if (data['displayName'] != null && (data['displayName'] as String).trim().isNotEmpty) {
          _userName = data['displayName'] as String;
        } else {
          _userName = user.displayName ?? "Nông Nghiệp Thông Minh";
        }
        _userPhone = data['phone'] as String?;
        _userAddress = data['address'] as String?;
        if (data['paymentMethod'] != null && (data['paymentMethod'] as String).trim().isNotEmpty) {
          _paymentMethod = data['paymentMethod'] as String;
        }
        if (data['addresses'] is List) {
          _addresses = (data['addresses'] as List)
              .map((item) => ShippingAddress.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList();
        } else if ((_userPhone != null && _userPhone!.isNotEmpty) ||
            (_userAddress != null && _userAddress!.isNotEmpty)) {
          _addresses = [
            ShippingAddress(
              id: 'addr_default',
              recipientName: _userName ?? "Nông Nghiệp Thông Minh",
              phone: _userPhone ?? "",
              address: _userAddress ?? "",
              label: "Nhà riêng",
              isDefault: true,
            ),
          ];
        } else {
          _addresses = [];
        }

        if (data['savedCards'] is List) {
          _savedCards = (data['savedCards'] as List)
              .map((item) => SavedPaymentCard.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList();
        } else {
          _savedCards = [
            SavedPaymentCard(
              id: 'card_ncb_sandbox',
              bankName: 'NCB Bank (VNPay Sandbox)',
              cardNumber: '9704198526191432198',
              cardHolder: 'NGUYEN VAN A',
              issueDate: '07/15',
              isDefault: true,
            ),
          ];
        }

        if (data['bio'] != null && (data['bio'] as String).trim().isNotEmpty) {
          _bio = data['bio'] as String;
        } else {
          _bio = 'Chăm cây trong nhà theo nhịp nhẹ, đều và đẹp mắt.';
        }
      } else {
        final defaultSandboxCard = SavedPaymentCard(
          id: 'card_ncb_sandbox',
          bankName: 'NCB Bank (VNPay Sandbox)',
          cardNumber: '9704198526191432198',
          cardHolder: 'NGUYEN VAN A',
          issueDate: '07/15',
          isDefault: true,
        );
        _savedCards = [defaultSandboxCard];
        // Document chưa tồn tại, khởi tạo hồ sơ người dùng trên Firestore
        _firestore.collection('Users').doc(uid).set({
          'uid': uid,
          'displayName': user.displayName ?? "Nông Nghiệp Thông Minh",
          'email': user.email ?? "",
          'phone': user.phoneNumber ?? "",
          'address': "",
          'paymentMethod': 'vnpay',
          'addresses': [],
          'savedCards': [defaultSandboxCard.toMap()],
          'googlePhotoUrl': user.photoURL ?? "",
          'customPhotoUrl': null,
          'bio': 'Chăm cây trong nhà theo nhịp nhẹ, đều và đẹp mắt.',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _bio = 'Chăm cây trong nhà theo nhịp nhẹ, đều và đẹp mắt.';
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint("⚠️ Lỗi lắng nghe hồ sơ User Firestore: $e");
    });
  }

  /// Lưu ảnh đại diện riêng trực tiếp vào Cloud Firestore (Users/{uid})
  /// Không cần qua bên thứ 3 (ImgBB) hay trả phí Firebase Storage
  Future<bool> updateAvatar(Uint8List imageBytes) async {
    final uid = _userId ?? _auth.currentUser?.uid;
    if (uid == null) return false;

    _isUploadingAvatar = true;
    notifyListeners();

    try {
      final String base64DataUri = "data:image/jpeg;base64,${base64Encode(imageBytes)}";
      _customPhotoUrl = base64DataUri;
      await _firestore.collection('Users').doc(uid).set({
        'customPhotoUrl': base64DataUri,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _isUploadingAvatar = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ Lỗi lưu avatar lên Firestore: $e");
    }

    _isUploadingAvatar = false;
    notifyListeners();
    return false;
  }

  /// Xóa ảnh tùy chỉnh, quay lại hiển thị ảnh Google mặc định
  Future<void> resetToDefaultAvatar() async {
    final uid = _userId ?? _auth.currentUser?.uid;
    if (uid == null) return;
    _customPhotoUrl = null;
    notifyListeners();
    try {
      await _firestore.collection('Users').doc(uid).set({
        'customPhotoUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Lỗi reset avatar về mặc định: $e");
    }
  }

  /// Cập nhật tên hiển thị, số điện thoại, địa chỉ nhận hàng, phương thức thanh toán và tiểu sử
  Future<void> updateProfileInfo({
    String? name,
    String? phone,
    String? address,
    String? paymentMethod,
    String? bio,
  }) async {
    final uid = _userId ?? _auth.currentUser?.uid;
    if (uid == null) return;

    if (name != null && name.trim().isNotEmpty) {
      _userName = name.trim();
      try {
        await _auth.currentUser?.updateDisplayName(name.trim());
      } catch (e) {
        debugPrint("⚠️ Lỗi cập nhật DisplayName auth: $e");
      }
    }
    if (phone != null) {
      _userPhone = phone.trim();
    }
    if (address != null) {
      _userAddress = address.trim();
    }
    if (paymentMethod != null) {
      _paymentMethod = paymentMethod;
    }
    if (bio != null) {
      _bio = bio.trim();
    }
    notifyListeners();

    try {
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null && name.trim().isNotEmpty) {
        updateData['displayName'] = name.trim();
      }
      if (phone != null) {
        updateData['phone'] = phone.trim();
      }
      if (address != null) {
        updateData['address'] = address.trim();
      }
      if (paymentMethod != null) {
        updateData['paymentMethod'] = paymentMethod;
      }
      if (bio != null) {
        updateData['bio'] = bio.trim();
      }
      await _firestore.collection('Users').doc(uid).set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Lỗi cập nhật Firestore Users: $e");
    }
  }

  /// Thêm mới hoặc cập nhật 1 địa chỉ nhận hàng trong sổ địa chỉ
  Future<void> saveShippingAddress(ShippingAddress address) async {
    final uid = _userId ?? _auth.currentUser?.uid;
    if (uid == null) return;

    final List<ShippingAddress> updated = List.from(_addresses);
    final int existingIdx = updated.indexWhere((a) => a.id == address.id);

    final bool makeDefault = address.isDefault || updated.isEmpty;
    if (makeDefault) {
      for (int i = 0; i < updated.length; i++) {
        updated[i] = updated[i].copyWith(isDefault: false);
      }
    }

    final finalAddress = address.copyWith(isDefault: makeDefault);
    if (existingIdx >= 0) {
      updated[existingIdx] = finalAddress;
    } else {
      updated.add(finalAddress);
    }

    // Đảm bảo luôn có ít nhất 1 địa chỉ mặc định
    if (updated.isNotEmpty && !updated.any((a) => a.isDefault)) {
      updated[0] = updated[0].copyWith(isDefault: true);
    }

    _addresses = updated;
    notifyListeners();

    try {
      await _firestore.collection('Users').doc(uid).set({
        'addresses': _addresses.map((a) => a.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Lỗi lưu sổ địa chỉ: $e");
    }
  }

  /// Xóa 1 địa chỉ nhận hàng khỏi sổ địa chỉ
  Future<void> deleteShippingAddress(String id) async {
    final uid = _userId ?? _auth.currentUser?.uid;
    if (uid == null) return;

    final List<ShippingAddress> updated = _addresses.where((a) => a.id != id).toList();
    if (updated.isNotEmpty && !updated.any((a) => a.isDefault)) {
      updated[0] = updated[0].copyWith(isDefault: true);
    }

    _addresses = updated;
    notifyListeners();

    try {
      await _firestore.collection('Users').doc(uid).set({
        'addresses': _addresses.map((a) => a.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Lỗi xóa địa chỉ: $e");
    }
  }

  /// Đặt 1 địa chỉ làm mặc định
  Future<void> setDefaultShippingAddress(String id) async {
    final uid = _userId ?? _auth.currentUser?.uid;
    if (uid == null) return;

    _addresses = _addresses.map((a) => a.copyWith(isDefault: a.id == id)).toList();
    notifyListeners();

    try {
      await _firestore.collection('Users').doc(uid).set({
        'addresses': _addresses.map((a) => a.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Lỗi đặt địa chỉ mặc định: $e");
    }
  }

  /// Thêm mới hoặc cập nhật 1 thẻ ngân hàng thanh toán
  Future<void> savePaymentCard(SavedPaymentCard card) async {
    final uid = _userId ?? _auth.currentUser?.uid;
    if (uid == null) return;

    final List<SavedPaymentCard> updated = List.from(_savedCards);
    final int existingIdx = updated.indexWhere((c) => c.id == card.id);

    final bool makeDefault = card.isDefault || updated.isEmpty;
    if (makeDefault) {
      for (int i = 0; i < updated.length; i++) {
        updated[i] = updated[i].copyWith(isDefault: false);
      }
    }

    final finalCard = card.copyWith(isDefault: makeDefault);
    if (existingIdx >= 0) {
      updated[existingIdx] = finalCard;
    } else {
      updated.add(finalCard);
    }

    if (updated.isNotEmpty && !updated.any((c) => c.isDefault)) {
      updated[0] = updated[0].copyWith(isDefault: true);
    }

    _savedCards = updated;
    notifyListeners();

    try {
      await _firestore.collection('Users').doc(uid).set({
        'savedCards': _savedCards.map((c) => c.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Lỗi lưu thẻ thanh toán: $e");
    }
  }

  /// Xóa 1 thẻ ngân hàng khỏi danh sách đã lưu
  Future<void> deletePaymentCard(String id) async {
    final uid = _userId ?? _auth.currentUser?.uid;
    if (uid == null) return;

    final List<SavedPaymentCard> updated = _savedCards.where((c) => c.id != id).toList();
    if (updated.isNotEmpty && !updated.any((c) => c.isDefault)) {
      updated[0] = updated[0].copyWith(isDefault: true);
    }

    _savedCards = updated;
    notifyListeners();

    try {
      await _firestore.collection('Users').doc(uid).set({
        'savedCards': _savedCards.map((c) => c.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Lỗi xóa thẻ thanh toán: $e");
    }
  }

  /// Đặt 1 thẻ ngân hàng làm mặc định
  Future<void> setDefaultPaymentCard(String id) async {
    final uid = _userId ?? _auth.currentUser?.uid;
    if (uid == null) return;

    _savedCards = _savedCards.map((c) => c.copyWith(isDefault: c.id == id)).toList();
    notifyListeners();

    try {
      await _firestore.collection('Users').doc(uid).set({
        'savedCards': _savedCards.map((c) => c.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Lỗi đặt thẻ mặc định: $e");
    }
  }

  void setPremium(bool val) {
    _isPremium = val;
    notifyListeners();
  }

  // Đồng bộ User Token với Spring Boot Backend
  Future<void> _syncWithBackend(User user) async {
    try {
      String? token = await user.getIdToken();
      if (token == null) return;

      final dio = Dio();
      final response = await dio.post(
        AppConstants.authSyncUrl,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      print("✅ Đồng bộ Spring Boot: ${response.data}");
    } catch (e) {
      print("❌ Lỗi đồng bộ Spring Boot: $e");
    }
  }

  // Đăng nhập bằng Email/Password
  Future<String?> login(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // KIỂM TRA ĐÃ XÁC THỰC EMAIL CHƯA
      if (cred.user != null && !cred.user!.emailVerified) {
        await _auth.signOut();
        return "Tài khoản chưa được kích hoạt. Vui lòng kiểm tra hộp thư Email để xác thực!";
      }

      if (cred.user != null) {
        await _syncWithBackend(cred.user!);
      }
      return null; // Đăng nhập thành công
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return "Sai Email hoặc Mật khẩu!";
      }
      return "Lỗi: ${e.message}";
    } catch (e) {
      print("Lỗi đăng nhập: $e");
      return "Lỗi kết nối. Vui lòng thử lại!";
    }
  }

  // Đăng ký bằng Email/Password
  Future<String?> register(String name, String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      // Cập nhật tên hiển thị
      await userCredential.user?.updateDisplayName(name);

      // GỬI EMAIL XÁC THỰC
      await userCredential.user?.sendEmailVerification();

      // Đăng xuất ngay lập tức để ép user vào email kích hoạt
      await _auth.signOut();

      return null; // Đăng ký thành công
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "Email này đã được sử dụng!";
      } else if (e.code == 'weak-password') {
        return "Mật khẩu quá yếu!";
      }
      return "Lỗi: ${e.message}";
    } catch (e) {
      print("Lỗi đăng ký: $e");
      return "Lỗi kết nối. Vui lòng thử lại!";
    }
  }

  // Đăng nhập bằng Google
  Future<bool> loginWithGoogle() async {
    try {
      if (kIsWeb) {
        // Trên Web: Google Identity Services bản mới yêu cầu dùng Popup thay vì signIn()
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        // Ép Google luôn luôn hiển thị bảng chọn tài khoản thay vì tự động đăng nhập
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        UserCredential cred = await _auth.signInWithPopup(googleProvider);
        if (cred.user != null) {
          await _syncWithBackend(cred.user!);
        }
        return true;
      } else {
        // Trên Mobile: Vẫn dùng luồng cũ
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return false;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential cred = await _auth.signInWithCredential(credential);
        if (cred.user != null) {
          await _syncWithBackend(cred.user!);
        }
        return true;
      }
    } catch (e) {
      print("Lỗi đăng nhập Google: $e");
      return false;
    }
  }

  // Gửi email khôi phục mật khẩu
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "Email không tồn tại trong hệ thống!";
      } else if (e.code == 'invalid-email') {
        return "Email không hợp lệ!";
      }
      return "Lỗi: ${e.message}";
    } catch (e) {
      print("Lỗi reset password: $e");
      return "Lỗi kết nối. Vui lòng thử lại!";
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    try {
      _userDocSubscription?.cancel();
      _userDocSubscription = null;
      _userId = null;
      _userName = null;
      _userEmail = null;
      _userPhone = null;
      _userAddress = null;
      _googlePhotoUrl = null;
      _customPhotoUrl = null;
      _bio = null;
      _isPremium = false;
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("Lỗi đăng xuất: $e");
    }
  }
}
