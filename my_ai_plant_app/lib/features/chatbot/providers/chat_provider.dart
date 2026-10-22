import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_session.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String chatCollection = 'ChatSessions';

  List<ChatSession> _sessions = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _subscription;

  List<ChatSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get effectiveUserId => _auth.currentUser?.uid ?? 'guest_device_user';

  ChatProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _subscribeToSessions(effectiveUserId);

    _auth.authStateChanges().listen((User? user) {
      _subscribeToSessions(effectiveUserId);
    });
  }

  void _subscribeToSessions(String uid) {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    // Truy vấn chỉ dùng where('userId') và sắp xếp bộ nhớ client để tránh lỗi Firestore Composite Index
    _subscription = _firestore
        .collection(chatCollection)
        .where('userId', isEqualTo: uid)
        .snapshots()
        .listen(
      (snapshot) {
        final list = snapshot.docs.map((doc) => ChatSession.fromFirestore(doc)).toList();
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _sessions = list;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (err) {
        debugPrint("Lỗi Firestore ChatSessions: $err");
        _errorMessage = "Không thể tải lịch sử trò chuyện";
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Tạo cuộc trò chuyện mới trên Firestore
  Future<String?> createSession({
    required String firstUserPrompt,
    required List<ChatSessionMessage> messages,
    String? customTitle,
  }) async {
    final uid = effectiveUserId;

    try {
      String title = customTitle?.trim() ?? firstUserPrompt.trim();
      if (title.length > 40) {
        title = '${title.substring(0, 40)}...';
      }
      if (title.isEmpty) title = 'Cuộc trò chuyện mới';

      final docRef = await _firestore.collection(chatCollection).add({
        'userId': uid,
        'title': title,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'messages': messages.map((m) => m.toMap()).toList(),
      });

      return docRef.id;
    } catch (e) {
      debugPrint("Lỗi tạo ChatSession: $e");
      return null;
    }
  }

  /// Cập nhật tin nhắn vào phiên đang trò chuyện
  Future<void> updateSessionMessages({
    required String sessionId,
    required List<ChatSessionMessage> messages,
  }) async {
    if (sessionId.isEmpty) return;

    try {
      await _firestore.collection(chatCollection).doc(sessionId).update({
        'updatedAt': FieldValue.serverTimestamp(),
        'messages': messages.map((m) => m.toMap()).toList(),
      });
    } catch (e) {
      debugPrint("Lỗi cập nhật ChatSession $sessionId: $e");
    }
  }

  /// Đổi tên cuộc trò chuyện
  Future<bool> renameSession({
    required String sessionId,
    required String newTitle,
  }) async {
    if (sessionId.isEmpty) return false;

    try {
      final trimmed = newTitle.trim();
      final validTitle = trimmed.isEmpty ? 'Cuộc trò chuyện mới' : trimmed;

      await _firestore.collection(chatCollection).doc(sessionId).update({
        'title': validTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint("Lỗi đổi tên ChatSession: $e");
      return false;
    }
  }

  /// Xóa 1 cuộc hội thoại
  Future<bool> deleteSession(String sessionId) async {
    try {
      await _firestore.collection(chatCollection).doc(sessionId).delete();
      return true;
    } catch (e) {
      debugPrint("Lỗi xóa ChatSession: $e");
      return false;
    }
  }

  /// Xóa toàn bộ lịch sử hội thoại của người dùng
  Future<bool> clearAllSessions() async {
    final uid = effectiveUserId;

    try {
      final snapshot = await _firestore
          .collection(chatCollection)
          .where('userId', isEqualTo: uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint("Lỗi xóa tất cả ChatSession: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
