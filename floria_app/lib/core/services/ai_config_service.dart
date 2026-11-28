import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Đồng bộ cấu hình AI từ Firestore `SystemConfig/ai_config` (chỉnh từ Web Admin).
/// Chỉ tải 1 lần lúc mở app (có cache SharedPreferences) để tiết kiệm quota Firestore.
class AiConfigService {
  static const _cacheKey = 'floria_system_ai_config_v1';

  static bool preferGemini = true;
  static double speciesConfidenceThreshold = 70.0;
  static double diseaseConfidenceThreshold = 50.0;

  static String assistantName = 'Trợ lý Floria';
  static String assistantTone = '';
  static String assistantDefaultModel = '';
  static String assistantSystemPrompt = '';
  static bool enableProductTags = true;
  static bool enableCareScheduleTags = true;
  static const String antiHallucinationGuardrail =
      '[Cấm bịa đặt số liệu, giá bán & dữ liệu hệ thống]: TUYỆT ĐỐI KHÔNG tự suy đoán hoặc bịa đặt giá bán, giá gốc, chương trình giảm giá, mã voucher, số lượng tồn kho, quy cách đóng gói hay thông tin khu vườn của người dùng. Mọi con số về giá tiền, khuyến mãi, tồn kho và lịch chăm sóc PHẢI lấy chính xác 100% từ dữ liệu hệ thống cung cấp trong ngữ cảnh. Nếu sản phẩm hoặc thông tin người dùng hỏi không có trong danh sách dữ liệu, phải trả lời trung thực là hiện chưa có thông tin/sản phẩm đó trên hệ thống Floria.';
  static List<String> assistantGuardrails = [antiHallucinationGuardrail];
  static List<String> disabledProductIds = [];

  static Future<void> loadOnAppStart() async {
    // 1. Nạp nhanh từ cache cục bộ trước
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        _applyMap(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}

    // 2. Lấy bản mới nhất từ Firestore SystemConfig (1 lần duy nhất lúc mở app)
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('SystemConfig').doc('ai_config').get(),
        FirebaseFirestore.instance.collection('SystemConfig').doc('assistant_config').get(),
      ]).timeout(const Duration(seconds: 3));

      final aiSnap = results[0];
      if (aiSnap.exists && aiSnap.data() != null) {
        _applyMap(aiSnap.data()!);
      }

      final asstSnap = results[1];
      if (asstSnap.exists && asstSnap.data() != null) {
        _applyAssistantMap(asstSnap.data()!);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'preferGemini': preferGemini,
          'speciesConfidenceThreshold': speciesConfidenceThreshold,
          'diseaseConfidenceThreshold': diseaseConfidenceThreshold,
          'assistantName': assistantName,
          'assistantTone': assistantTone,
          'assistantDefaultModel': assistantDefaultModel,
          'assistantSystemPrompt': assistantSystemPrompt,
          'assistantGuardrails': assistantGuardrails,
          'disabledProductIds': disabledProductIds,
          'enableProductTags': enableProductTags,
          'enableCareScheduleTags': enableCareScheduleTags,
        }),
      );
    } catch (e) {
      debugPrint('AiConfigService fallback to cached/default: $e');
    }
  }

  static void _ensureAntiHallucinationRule() {
    final hasRule = assistantGuardrails.any(
      (r) => r.contains('bịa đặt giá') || r.contains('Cấm bịa đặt số liệu'),
    );
    if (!hasRule) {
      assistantGuardrails = [...assistantGuardrails, antiHallucinationGuardrail];
    }
  }

  static void _applyMap(Map<String, dynamic> data) {
    if (data['preferGemini'] is bool) {
      preferGemini = data['preferGemini'] as bool;
    }
    if (data['speciesConfidenceThreshold'] is num) {
      speciesConfidenceThreshold =
          (data['speciesConfidenceThreshold'] as num).toDouble();
    }
    if (data['diseaseConfidenceThreshold'] is num) {
      diseaseConfidenceThreshold =
          (data['diseaseConfidenceThreshold'] as num).toDouble();
    }
    if (data['assistantName'] is String) {
      assistantName = data['assistantName'] as String;
    }
    if (data['assistantTone'] is String) {
      assistantTone = data['assistantTone'] as String;
    }
    if (data['assistantDefaultModel'] is String) {
      assistantDefaultModel = data['assistantDefaultModel'] as String;
    }
    if (data['assistantSystemPrompt'] is String) {
      assistantSystemPrompt = data['assistantSystemPrompt'] as String;
    }
    if (data['assistantGuardrails'] is List) {
      assistantGuardrails = List<String>.from(data['assistantGuardrails']);
    }
    if (data['disabledProductIds'] is List) {
      disabledProductIds = List<String>.from(data['disabledProductIds']);
    }
    if (data['enableProductTags'] is bool) {
      enableProductTags = data['enableProductTags'] as bool;
    }
    if (data['enableCareScheduleTags'] is bool) {
      enableCareScheduleTags = data['enableCareScheduleTags'] as bool;
    }
    _ensureAntiHallucinationRule();
  }

  static void _applyAssistantMap(Map<String, dynamic> data) {
    if (data['name'] is String && (data['name'] as String).trim().isNotEmpty) {
      assistantName = (data['name'] as String).trim();
    }
    if (data['tone'] is String) {
      assistantTone = (data['tone'] as String).trim();
    }
    if (data['defaultModel'] is String) {
      assistantDefaultModel = (data['defaultModel'] as String).trim();
    }
    if (data['systemPrompt'] is String) {
      assistantSystemPrompt = (data['systemPrompt'] as String).trim();
    }
    if (data['guardrails'] is List) {
      assistantGuardrails = (data['guardrails'] as List)
          .whereType<Map<String, dynamic>>()
          .where((g) => g['enabled'] == true && (g['ruleText'] ?? '').toString().isNotEmpty)
          .map((g) => '[${g['name']}]: ${g['ruleText']}')
          .toList();
    }
    if (data['disabledProductIds'] is List) {
      disabledProductIds = (data['disabledProductIds'] as List)
          .map((e) => e.toString())
          .toList();
    }
    if (data['enableProductTags'] is bool) {
      enableProductTags = data['enableProductTags'] as bool;
    }
    if (data['enableCareScheduleTags'] is bool) {
      enableCareScheduleTags = data['enableCareScheduleTags'] as bool;
    }
    _ensureAntiHallucinationRule();
  }
}
