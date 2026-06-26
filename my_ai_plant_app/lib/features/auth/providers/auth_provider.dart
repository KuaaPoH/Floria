import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '896398806405-b4fvkufof9iph4i8oguseiaf714jfup3.apps.googleusercontent.com'
        : null,
  );

  bool _isLoggedIn = false;
  String? _userName;
  String? _userEmail;
  bool _isPremium = false;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isPremium => _isPremium;

  AuthProvider() {
    // Lắng nghe sự thay đổi trạng thái đăng nhập và cập nhật hồ sơ (userChanges)
    _auth.userChanges().listen((User? user) {
      // Chỉ cho phép đăng nhập nếu user khác null VÀ (đã xác thực email hoặc là tài khoản đăng nhập qua Google/Apple)
      // Các tài khoản qua Google/Apple mặc định emailVerified = true
      if (user != null && user.emailVerified) {
        _isLoggedIn = true;
        _userName = user.displayName ?? "Nông Nghiệp Thông Minh";
        _userEmail = user.email;
      } else {
        _isLoggedIn = false;
        _userName = null;
        _userEmail = null;
        _isPremium = false;
      }
      notifyListeners();
    });
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
        'http://192.168.1.78:8080/api/auth/sync',
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
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("Lỗi đăng xuất: $e");
    }
  }
}
