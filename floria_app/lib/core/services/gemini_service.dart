import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'ai_config_service.dart';

class GeminiPlantResult {
  final bool isPlant;
  final bool matchedDatabase;
  final String scientificName;
  final String nameVi;
  final double confidence;
  final String shortDesc;
  final String? rejectReason;

  const GeminiPlantResult({
    required this.isPlant,
    required this.matchedDatabase,
    required this.scientificName,
    required this.nameVi,
    required this.confidence,
    required this.shortDesc,
    this.rejectReason,
  });
}

class GeminiDiseaseResult {
  final bool isPlant;
  final bool matchedDatabase;
  final String prediction;
  final String predictionVi;
  final double confidence;
  final String severity;
  final String cause;
  final List<String> treatmentSteps;
  final String? rejectReason;

  const GeminiDiseaseResult({
    required this.isPlant,
    required this.matchedDatabase,
    required this.prediction,
    required this.predictionVi,
    required this.confidence,
    required this.severity,
    required this.cause,
    required this.treatmentSteps,
    this.rejectReason,
  });
}

class GeminiService {
  static const String _prefKey = 'floria_gemini_api_key';
  static const String _prefModelKey = 'floria_gemini_model_name';
  static const String defaultModel = 'gemini-3.8-flash';

  // Danh sách các mô hình thế hệ 3 mới nhất của Google hoạt động chuẩn xác 100%
  static const List<String> fallbackModels = [
    'gemini-3.8-flash',
    'gemini-3-flash-preview',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-3.1-flash-lite-preview',
    'gemini-3.6-flash',
  ];

  static List<String>? _cachedPlantsPromptLines;

  /// Tải danh sách loài cây trực tiếp từ Firestore `plants_info` (đồng bộ với Web Admin).
  static Future<String> _getPlantsPromptList() async {
    if (_cachedPlantsPromptLines != null && _cachedPlantsPromptLines!.isNotEmpty) {
      return _cachedPlantsPromptLines!.join('\n');
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('plants_info')
          .get()
          .timeout(const Duration(seconds: 4));
      final lines = snap.docs
          .map((doc) {
            final d = doc.data();
            final sci = (d['scientific_name'] ?? d['scientificName'] ?? doc.id).toString().trim();
            final vi = (d['name_vi'] ?? d['nameVi'] ?? d['commonName'] ?? '').toString().trim();
            return vi.isNotEmpty ? '- $sci ($vi)' : '- $sci';
          })
          .where((line) => line.length > 2)
          .toList();
      if (lines.isNotEmpty) {
        _cachedPlantsPromptLines = lines;
        return lines.join('\n');
      }
    } catch (_) {}
    return '';
  }

  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_prefKey)?.trim();
    if (key != null && key.isNotEmpty) return key;
    if (AppConstants.defaultGeminiApiKey.isNotEmpty) {
      return AppConstants.defaultGeminiApiKey;
    }
    return null;
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key.trim());
  }

  static Future<String> getModelName() async {
    if (AiConfigService.assistantDefaultModel.isNotEmpty) {
      return AiConfigService.assistantDefaultModel;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefModelKey)?.trim();
    if (saved != null && fallbackModels.contains(saved)) {
      return saved;
    }
    return defaultModel;
  }

  static List<String> _dynamicCatalogLines = [];
  static String _cachedVouchersPrompt = '';
  static String _cachedDiseasesPrompt = '';
  static String _cachedPlantsKnowledgePrompt = '';
  static DateTime? _lastKnowledgeLoadedAt;

  static String _formatVnd(num amount) {
    final rounded = amount.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < rounded.length; i++) {
      if (i > 0 && (rounded.length - i) % 3 == 0) {
        buf.write('.');
      }
      buf.write(rounded[i]);
    }
    return '${buf.toString()}đ';
  }

  /// Tải & cache ngữ cảnh Vouchers, DiseasesInfo, plants_info từ Firestore để AI trả lời chuẩn xác
  static Future<void> loadKnowledgeContextIfNeeded() async {
    final now = DateTime.now();
    if (_lastKnowledgeLoadedAt != null &&
        now.difference(_lastKnowledgeLoadedAt!).inMinutes < 5 &&
        (_cachedVouchersPrompt.isNotEmpty ||
            _cachedDiseasesPrompt.isNotEmpty ||
            _cachedPlantsKnowledgePrompt.isNotEmpty)) {
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>?>([
        db.collection('Vouchers').get().then<QuerySnapshot<Map<String, dynamic>>?>((s) => s).catchError((_) => null),
        db.collection('DiseasesInfo').get().then<QuerySnapshot<Map<String, dynamic>>?>((s) => s).catchError((_) => null),
        db.collection('plants_info').get().then<QuerySnapshot<Map<String, dynamic>>?>((s) => s).catchError((_) => null),
      ]).timeout(const Duration(seconds: 4));

      final vSnap = results[0];
      if (vSnap != null) {
        final vLines = <String>[];
        for (final doc in vSnap.docs) {
          final d = doc.data();
          if (d['active'] == false || d['isActive'] == false) continue;
          final type = (d['type'] ?? d['discountType'] ?? '').toString();
          if (type == 'shipping') continue;
          final expiresRaw = d['expiresAt'] ?? d['expiryDate'];
          if (expiresRaw is String && expiresRaw.trim().isNotEmpty) {
            final parsed = DateTime.tryParse(expiresRaw);
            if (parsed != null && parsed.isBefore(now)) continue;
          } else if (expiresRaw is Timestamp && expiresRaw.toDate().isBefore(now)) {
            continue;
          }
          final code = (d['code'] ?? doc.id).toString().trim().toUpperCase();
          if (code.isEmpty) continue;
          final value = (d['value'] as num?) ?? (d['discountValue'] as num?) ?? 0;
          final minOrder = (d['minOrder'] as num?) ?? (d['minOrderAmount'] as num?) ?? 0;
          final maxDiscount = d['maxDiscount'] as num?;
          final discountText = type == 'fixed'
              ? 'giảm ${_formatVnd(value)}'
              : 'giảm ${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%${maxDiscount != null && maxDiscount > 0 ? ' (tối đa ${_formatVnd(maxDiscount)})' : ''}';
          final minText = minOrder > 0
              ? ', đơn tối thiểu ${_formatVnd(minOrder)}'
              : ', không giới hạn đơn tối thiểu';
          final desc = (d['description'] ?? d['title'] ?? '').toString().trim();
          vLines.add('- Mã `$code`: $discountText$minText${desc.isNotEmpty ? ' — $desc' : ''}');
        }
        _cachedVouchersPrompt = vLines.join('\n');
      }

      final dSnap = results[1];
      if (dSnap != null) {
        final dLines = <String>[];
        for (final doc in dSnap.docs) {
          final d = doc.data();
          final nameVi = (d['nameVi'] ?? d['name'] ?? doc.id).toString().trim();
          if (nameVi.isEmpty) continue;
          final severity = (d['severity'] ?? '').toString().trim();
          final pathogen = (d['pathogen'] ?? d['agent'] ?? '').toString().trim();
          final rawSymptoms = d['symptoms'];
          final symptoms = rawSymptoms is List
              ? rawSymptoms.map((e) => e.toString()).join('; ')
              : (rawSymptoms ?? d['mechanism'] ?? '').toString().trim();
          final rawSteps = d['treatmentSteps'] ?? d['treatment'];
          final treatment = rawSteps is List
              ? rawSteps.take(3).map((e) => e.toString()).join('; ')
              : '';
          final related = (d['relatedProductIds'] is List)
              ? (d['relatedProductIds'] as List).map((e) => e.toString()).where((s) => s.isNotEmpty).join(', ')
              : '';
          final parts = [
            if (severity.isNotEmpty) 'Mức độ: $severity',
            if (pathogen.isNotEmpty) 'Tác nhân: $pathogen',
            if (symptoms.isNotEmpty) 'Triệu chứng: ${symptoms.length > 110 ? symptoms.substring(0, 110) : symptoms}',
            if (treatment.isNotEmpty) 'Xử lý: ${treatment.length > 130 ? treatment.substring(0, 130) : treatment}',
            if (related.isNotEmpty) 'Vật tư gợi ý: $related',
          ].join(' · ');
          dLines.add('- $nameVi (${doc.id})${parts.isNotEmpty ? ': $parts' : ''}');
        }
        _cachedDiseasesPrompt = dLines.join('\n');
      }

      final pSnap = results[2];
      if (pSnap != null) {
        final pLines = <String>[];
        for (final doc in pSnap.docs) {
          final d = doc.data();
          if (d['status'] == 'draft') continue;
          final nameVi = (d['name_vi'] ?? d['viName'] ?? '').toString().trim();
          final sci = (d['scientific_name'] ?? d['sciName'] ?? doc.id).toString().trim();
          if (nameVi.isEmpty && sci.isEmpty) continue;
          final light = (d['light'] ?? '').toString().trim();
          final water = (d['water_frequency'] ?? d['watering'] ?? '').toString().trim();
          final temp = (d['temperature'] ?? '').toString().trim();
          final humidity = (d['humidity'] ?? '').toString().trim();
          final toxicity = (d['toxicity'] ?? d['toxicityNote'] ?? '').toString().trim();
          final parts = [
            if (light.isNotEmpty) 'Ánh sáng: $light',
            if (water.isNotEmpty) 'Tưới: $water',
            if (temp.isNotEmpty) 'Nhiệt độ: $temp',
            if (humidity.isNotEmpty) 'Độ ẩm: $humidity',
            if (toxicity.isNotEmpty) 'Độc tính: $toxicity',
          ].join(' · ');
          pLines.add('- ${nameVi.isNotEmpty ? '$nameVi ($sci)' : sci}${parts.isNotEmpty ? ': $parts' : ''}');
        }
        _cachedPlantsKnowledgePrompt = pLines.join('\n');
      }

      _lastKnowledgeLoadedAt = now;
    } catch (_) {}
  }

  /// Cập nhật danh sách sản phẩm thật từ ShopProvider (visible == true, còn hàng)
  static void updateProductCatalog(List<dynamic> products) {
    final lines = <String>[];
    for (final p in products) {
      try {
        final bool visible = (p.visible as bool?) ?? true;
        final int stock = (p.stock as int?) ?? 1;
        final id = (p.id as String).trim();
        if (!visible || stock <= 0 || AiConfigService.disabledProductIds.contains(id)) {
          continue;
        }
        final name = (p.name as String).trim();
        final category = ((p.category as String?) ?? '').trim();
        final price = ((p.formattedPrice as String?) ?? '').trim();
        final origPrice = (p.formattedOriginalPrice as String?)?.trim();
        final priceText = price.isNotEmpty
            ? (origPrice != null && origPrice.isNotEmpty
                ? 'Giá bán: $price (giá gốc $origPrice, đang giảm giá)'
                : 'Giá bán: $price')
            : 'Giá bán: Chưa cập nhật';
        final indications = (p.indications as List?)?.join(', ') ?? '';
        final usageGuide = ((p.usageGuide as String?) ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
        final desc = ((p.shortDesc as String?)?.trim().isNotEmpty == true
                ? p.shortDesc as String
                : (p.description as String?) ?? '')
            .trim()
            .replaceAll(RegExp(r'\s+'), ' ');
        final combined = [
          if (category.isNotEmpty) 'Nhóm: $category',
          priceText,
          'Tồn kho: $stock',
          if (indications.isNotEmpty) 'Chỉ định: $indications',
          if (usageGuide.isNotEmpty)
            'Cách dùng: ${usageGuide.length > 130 ? '${usageGuide.substring(0, 130)}...' : usageGuide}',
          if (desc.isNotEmpty)
            'Mô tả: ${desc.length > 120 ? '${desc.substring(0, 120)}...' : desc}',
        ].join(' · ');
        lines.add('   - id: `$id` ➔ $name ($combined)');
      } catch (_) {}
    }
    _dynamicCatalogLines = lines;
  }

  static String _buildChatSystemPrompt(String? currentPlantContext) {
    final filteredGuardrails = AiConfigService.assistantGuardrails.where((rule) {
      if (!AiConfigService.enableProductTags && rule.contains('[RECOMMEND_PRODUCT')) {
        return false;
      }
      if (!AiConfigService.enableCareScheduleTags && rule.contains('[CARE_SCHEDULE')) {
        return false;
      }
      return true;
    }).toList();

    final String corePersonaAndRules = [
      AiConfigService.assistantSystemPrompt.isNotEmpty
          ? AiConfigService.assistantSystemPrompt
          : 'Bạn là ${AiConfigService.assistantName}, chuyên gia cây trồng Floria.',
      if (AiConfigService.assistantName.isNotEmpty)
        'Tên xưng hô: ${AiConfigService.assistantName}.',
      if (AiConfigService.assistantTone.isNotEmpty)
        'Giọng điệu: ${AiConfigService.assistantTone}.',
      if (filteredGuardrails.isNotEmpty)
        'QUY TẮC AN TOÀN (GUARDRAILS BẮT BUỘC):\n${filteredGuardrails.join('\n')}',
      'QUY TẮC ĐỊNH DẠNG BẮT BUỘC:\n- TUYỆT ĐỐI KHÔNG sử dụng emoji hay biểu tượng cảm xúc trong câu trả lời.\n- KHÔNG sử dụng ký tự tiêu đề Markdown (#, ##, ###). Trình bày ngắn gọn, rõ ràng bằng đoạn văn và gạch đầu dòng.',
    ].join('\n');

    final String catalogSection = _dynamicCatalogLines.isNotEmpty
        ? '\nKHO SẢN PHẨM & BẢNG GIÁ FLORIA HIỆN CÓ:\n${_dynamicCatalogLines.join('\n')}'
        : '';
    final String vouchersSection = _cachedVouchersPrompt.isNotEmpty
        ? '\nMÃ GIẢM GIÁ (VOUCHER) ĐANG HOẠT ĐỘNG:\n$_cachedVouchersPrompt'
        : '';
    final String diseasesSection = _cachedDiseasesPrompt.isNotEmpty
        ? '\nHỒ SƠ BỆNH LÝ CÂY TRỒNG TRONG HỆ THỐNG:\n$_cachedDiseasesPrompt'
        : '';
    final String plantsSection = _cachedPlantsKnowledgePrompt.isNotEmpty
        ? '\nTỪ ĐIỂN CÂY CẢNH TRONG HỆ THỐNG:\n$_cachedPlantsKnowledgePrompt'
        : '';

    final String productTagInstruction = (AiConfigService.enableProductTags && _dynamicCatalogLines.isNotEmpty)
        ? '\nTHẺ HÀNH ĐỘNG ĐỀ XUẤT SẢN PHẨM (CHỈ dùng khi cây bệnh/sâu hại nặng cần đặc trị HOẶC người dùng hỏi mua/tìm/lọc sản phẩm theo tầm giá, công dụng):\nGắn ở cuối câu trả lời đúng cú pháp:\n[RECOMMEND_PRODUCT: id_san_pham]'
        : '\nTHẺ HÀNH ĐỘNG SẢN PHẨM ĐANG TẮT: TUYỆT ĐỐI KHÔNG chèn hoặc xuất ra thẻ [RECOMMEND_PRODUCT...] dưới bất kỳ hình thức nào.';
    final String careTagInstruction = AiConfigService.enableCareScheduleTags
        ? '\nTHẺ HÀNH ĐỘNG ĐỀ XUẤT LỊCH CHĂM SÓC (CHỈ dùng khi người dùng hỏi lịch/cách chăm sóc cây toàn diện):\nGắn ở cuối câu trả lời đúng cú pháp:\n[CARE_SCHEDULE: water=SO_NGAY_TUOI, fertilize=SO_NGAY_BON_PHAN, clean=SO_NGAY_KIEM_TRA]\nQuy ước số ngày: water (1-14), fertilize (7-60), clean (1-14); không viết tiêu đề cụt lủn ngay trước thẻ.'
        : '\nTHẺ HÀNH ĐỘNG LỊCH CHĂM SÓC ĐANG TẮT: TUYỆT ĐỐI KHÔNG chèn hoặc xuất ra thẻ [CARE_SCHEDULE...] dưới bất kỳ hình thức nào.';

    return '''$corePersonaAndRules
${currentPlantContext != null && currentPlantContext.isNotEmpty ? '\nNgữ cảnh hiện tại của người dùng: $currentPlantContext.' : ''}$catalogSection$vouchersSection$diseasesSection$plantsSection$productTagInstruction$careTagInstruction''';
  }

  static Future<void> saveModelName(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefModelKey, model.trim());
  }

  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  /// Chẩn đoán bệnh lá cây bằng Google Gemini Multimodal (hỗ trợ cả 5 bệnh chuẩn & bệnh ngoài 5 loại)
  static Future<GeminiDiseaseResult> diagnoseDiseaseWithImage({
    required Uint8List imageBytes,
    String? plantName,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Chưa cấu hình Google Gemini API Key.");
    }

    final modelName = await getModelName();
    final promptText = '''
Bạn là bác sĩ bệnh học cây trồng của ứng dụng Floria.
${plantName != null && plantName.trim().isNotEmpty ? 'Cây đang được kiểm tra là: "$plantName".' : ''}
Hãy quan sát kỹ ảnh lá/thân cây được cung cấp và thực hiện:

1. KIỂM DUYỆT THỰC VẬT:
- Nếu ảnh không phải thực vật (người, động vật, đồ vật, ảnh đen/mờ):
Trả về JSON:
{
  "is_plant": false,
  "reason": "Ảnh không phải thực vật"
}

2. NẾU LÀ THỰC VẬT:
Đối chiếu triệu chứng với 5 nhóm chuẩn trong CSDL:
- Healthy (Lá khỏe mạnh)
- Anthracnose (Bệnh thán thư)
- Bacterial_Blight (Bệnh cháy bìa lá / héo rũ vi khuẩn)
- Leaf_Spot (Bệnh đốm lá)
- Powdery_Mildew (Bệnh phấn trắng)

- Nếu khớp 1 trong 5 nhóm trên: đặt "matched_database": true và "prediction" đúng tên tiếng Anh trong 5 nhóm trên.
- Nếu là bệnh khác ngoài 5 nhóm trên (ví dụ: rỉ sắt, rệp sáp, nhện đỏ, vàng lá sinh lý, thiếu dinh dưỡng, thối nhũn...): đặt "matched_database": false và "prediction" là tên bệnh ngắn gọn.

Trả về duy nhất một khối JSON hợp lệ:
{
  "is_plant": true,
  "matched_database": true hoặc false,
  "prediction": "<Tên chuẩn trong 5 nhóm hoặc tên bệnh thực tế>",
  "prediction_vi": "<Tên bệnh bằng tiếng Việt>",
  "confidence": <số từ 75 đến 98>,
  "severity": "<Bình thường | Cảnh báo | Nguy hiểm>",
  "cause": "<Nguyên nhân ngắn gọn 1-2 câu>",
  "treatment_steps": ["<Bước 1>", "<Bước 2>", "<Bước 3>"]
}
''';

    final content = [
      Content.multi([
        TextPart(promptText),
        DataPart('image/jpeg', imageBytes),
      ]),
    ];

    String text = '';
    final modelsToTry = [
      modelName,
      ...fallbackModels.where((m) => m != modelName),
    ];

    dynamic lastError;
    for (final mName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: mName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.15,
            topK: 32,
            topP: 0.9,
          ),
        );
        final response = await model.generateContent(content);
        if (response.text != null && response.text!.trim().isNotEmpty) {
          text = response.text!.trim();
          break;
        }
      } catch (e) {
        lastError = e;
      }
    }

    if (text.isEmpty) {
      throw Exception("Không thể kết nối Gemini để chẩn đoán bệnh: $lastError");
    }

    String jsonStr = text;
    if (jsonStr.contains('```json')) {
      jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
    } else if (jsonStr.contains('```')) {
      jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
    }

    final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
    final bool isPlant = decoded['is_plant'] != false;
    if (!isPlant) {
      return GeminiDiseaseResult(
        isPlant: false,
        matchedDatabase: false,
        prediction: 'Không phải cây',
        predictionVi: 'Không phải cây',
        confidence: 0,
        severity: 'Cảnh báo',
        cause: '',
        treatmentSteps: const [],
        rejectReason: decoded['reason']?.toString(),
      );
    }

    final rawSteps = decoded['treatment_steps'];
    final List<String> steps = rawSteps is List
        ? rawSteps.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : const [];

    return GeminiDiseaseResult(
      isPlant: true,
      matchedDatabase: decoded['matched_database'] == true,
      prediction: (decoded['prediction'] ?? 'Unknown').toString(),
      predictionVi: (decoded['prediction_vi'] ?? decoded['prediction'] ?? 'Đang cập nhật').toString(),
      confidence: (decoded['confidence'] as num?)?.toDouble() ?? 88.0,
      severity: (decoded['severity'] ?? 'Cảnh báo').toString(),
      cause: (decoded['cause'] ?? '').toString(),
      treatmentSteps: steps,
    );
  }

  /// Nhận diện cây bằng hình ảnh + Miêu tả nhận dạng của người dùng
  /// So khớp với 40 cây CSDL. Nếu không khớp nhưng là cây, Gemini sẽ nhận diện tên loài
  static Future<GeminiPlantResult> identifyPlantWithHint({
    required Uint8List imageBytes,
    required String userHint,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Chưa cấu hình Google Gemini API Key.");
    }

    final modelName = await getModelName();

    final dbListPrompt = await _getPlantsPromptList();

    final promptText = '''
Bạn là chuyên gia thẩm định và phân loại thực vật học của ứng dụng Floria.
Nhiệm vụ của bạn:
1. Xem kỹ ảnh được cung cấp và đọc miêu tả đặc điểm nhận dạng bổ sung từ người dùng:
"${userHint.isEmpty ? 'Không có mô tả bổ sung' : userHint}"

2. KIỂM DUYỆT THỰC VẬT:
- Hãy xác định đây có phải là thực vật (cây cảnh, hoa, lá, cành cây, quả...) hay không.
- Nếu là động vật, người, đồ vật, màn hình, ảnh đen/mờ không nhận ra cây:
Trả về JSON:
{
  "is_plant": false,
  "reason": "Ảnh không phải thực vật (hãy nêu rõ là động vật, đồ vật hay ảnh mờ)"
}

3. NẾU LÀ THỰC VẬT:
Hãy đối chiếu ảnh và miêu tả nhận dạng với danh sách 40 cây sau đây trong Cơ sở dữ liệu:
$dbListPrompt

- TRƯỜNG HỢP A (Khớp với 1 trong 40 cây CSDL):
Trả về JSON:
{
  "is_plant": true,
  "matched_database": true,
  "scientific_name": "<Tên khoa học chính xác trong danh sách 40 cây>",
  "name_vi": "<Tên tiếng Việt trong danh sách>",
  "confidence": <độ tin cậy từ 80 đến 99>,
  "short_desc": "<Mô tả ngắn gọn 1-2 câu về loài cây này>"
}

- TRƯỜNG HỢP B (LÀ THỰC VẬT, nhưng KHÔNG thuộc 40 cây trong CSDL):
Hãy dùng kiến thức bách khoa thực vật học của bạn để định danh chính xác loài cây này:
Trả về JSON:
{
  "is_plant": true,
  "matched_database": false,
  "scientific_name": "<Tên khoa học chính xác của cây>",
  "name_vi": "<Tên tiếng Việt thông dụng nhất của cây>",
  "confidence": <độ tin cậy từ 70 đến 95>,
  "short_desc": "<Mô tả ngắn gọn 1-2 câu về loài cây này>"
}

QUY TẮC BẮT BUỘC: Chỉ trả về một khối JSON duy nhất hợp lệ, không có lời dẫn nào khác.
''';

    final content = [
      Content.multi([
        TextPart(promptText),
        DataPart('image/jpeg', imageBytes),
      ]),
    ];

    String text = '';
    final modelsToTry = [
      modelName,
      ...fallbackModels.where((m) => m != modelName),
    ];

    dynamic lastError;
    for (final mName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: mName,
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.15,
            topK: 32,
            topP: 0.9,
          ),
        );
        final response = await model.generateContent(content);
        if (response.text != null && response.text!.trim().isNotEmpty) {
          text = response.text!.trim();
          break;
        }
      } catch (e) {
        lastError = e;
        continue;
      }
    }

    if (text.isEmpty) {
      throw lastError ?? Exception("Không nhận được phản hồi từ Gemini.");
    }

    // Làm sạch JSON markdown
    String jsonStr = text;
    if (jsonStr.contains('```json')) {
      jsonStr = jsonStr.split('```json')[1].split('```')[0].trim();
    } else if (jsonStr.contains('```')) {
      jsonStr = jsonStr.split('```')[1].split('```')[0].trim();
    }

    final Map<String, dynamic> data = jsonDecode(jsonStr);

    final bool isPlant = data['is_plant'] == true;
    if (!isPlant) {
      return GeminiPlantResult(
        isPlant: false,
        matchedDatabase: false,
        scientificName: '',
        nameVi: '',
        confidence: 0,
        shortDesc: '',
        rejectReason: data['reason']?.toString() ?? "Hệ thống phát hiện đây không phải là thực vật.",
      );
    }

    final bool matchedDb = data['matched_database'] == true;
    final String sciName = data['scientific_name']?.toString() ?? 'Thực vật';
    final String nameVi = data['name_vi']?.toString() ?? sciName;
    final double confidence = (data['confidence'] as num?)?.toDouble() ?? 88.0;
    final String shortDesc = data['short_desc']?.toString() ?? '';

    return GeminiPlantResult(
      isPlant: true,
      matchedDatabase: matchedDb,
      scientificName: sciName,
      nameVi: nameVi,
      confidence: confidence,
      shortDesc: shortDesc,
    );
  }

  /// Trợ lý Trò chuyện Bác sĩ Cây trồng Floria (Gemini 3.8 Flash với chuyển đổi mượt mà)
  static Future<String> chatWithDoctor({
    required String prompt,
    List<Content>? history,
    Uint8List? imageBytes,
    String? currentPlantContext,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Chưa cấu hình Google Gemini API Key.");
    }

    final primaryModel = await getModelName();
    await loadKnowledgeContextIfNeeded();

    final systemInstruction = Content.system(_buildChatSystemPrompt(currentPlantContext));

    List<Part> parts = [];
    if (imageBytes != null) {
      parts.add(DataPart('image/jpeg', imageBytes));
    }
    parts.add(TextPart(prompt));

    final modelsToTry = [
      primaryModel,
      ...fallbackModels.where((m) => m != primaryModel),
    ];

    dynamic lastError;
    for (final mName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: mName,
          apiKey: apiKey,
          systemInstruction: systemInstruction,
        );

        final chat = model.startChat(history: history);
        final response = await chat.sendMessage(Content.multi(parts));
        if (response.text != null && response.text!.isNotEmpty) {
          return response.text!;
        }
      } catch (e) {
        lastError = e;
        // Nếu model gặp 503 (quá tải) hoặc lỗi kết nối, tự động thử model tiếp theo trong danh sách
        continue;
      }
    }

    throw lastError ?? Exception("Không thể kết nối đến Bác sĩ Cây trồng AI.");
  }

  static const String _prefDeepThinkingKey = 'floria_gemini_deep_thinking';

  static Future<bool> getDeepThinkingMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefDeepThinkingKey) ?? false;
  }

  static Future<void> saveDeepThinkingMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefDeepThinkingKey, enabled);
  }

  /// Trợ lý Trò chuyện Real-time Streaming Tức thì (Hỗ trợ chuyển đổi giữa Siêu tốc ~1s và Suy nghĩ sâu)
  static Stream<String> chatWithDoctorStream({
    required String prompt,
    List<Content>? history,
    Uint8List? imageBytes,
    String? currentPlantContext,
    bool enableDeepThinking = false,
  }) async* {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("Chưa cấu hình Google Gemini API Key.");
    }

    final primaryModel = await getModelName();
    await loadKnowledgeContextIfNeeded();
    final systemPrompt = _buildChatSystemPrompt(currentPlantContext);

    // Chuẩn bị danh sách contents theo chuẩn REST API của Google Generative Language
    final List<Map<String, dynamic>> apiContents = [];

    // Chuyển lịch sử trò chuyện sang định dạng REST
    if (history != null) {
      for (final item in history) {
        final role = item.role == 'user' ? 'user' : 'model';
        final List<Map<String, dynamic>> partsList = [];
        for (final p in item.parts) {
          if (p is TextPart) {
            partsList.add({'text': p.text});
          } else if (p is DataPart) {
            partsList.add({
              'inlineData': {
                'mimeType': p.mimeType,
                'data': base64Encode(p.bytes),
              }
            });
          }
        }
        if (partsList.isNotEmpty) {
          apiContents.add({'role': role, 'parts': partsList});
        }
      }
    }

    // Tin nhắn hiện tại của người dùng
    final List<Map<String, dynamic>> currentParts = [];
    if (imageBytes != null) {
      currentParts.add({
        'inlineData': {
          'mimeType': 'image/jpeg',
          'data': base64Encode(imageBytes),
        }
      });
    }
    currentParts.add({'text': prompt});
    apiContents.add({'role': 'user', 'parts': currentParts});

    final modelsToTry = [
      primaryModel,
      ...fallbackModels.where((m) => m != primaryModel),
    ];

    bool hasYielded = false;
    final List<String> attemptErrors = [];
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 25),
    ));

    for (final mName in modelsToTry) {
      try {
        final Map<String, dynamic> genConfig = {
          'temperature': enableDeepThinking ? 0.2 : 0.35,
          'topK': 40,
          'topP': 0.95,
        };
        if (!mName.startsWith('gemini-2.0') && !mName.contains('flash-lite')) {
          genConfig['thinkingConfig'] = {
            'thinkingBudget': enableDeepThinking ? 1024 : 0,
          };
        }
        final payload = {
          'contents': apiContents,
          'systemInstruction': {
            'parts': [
              {'text': systemPrompt}
            ]
          },
          'generationConfig': genConfig,
        };
        final streamUrl = 'https://generativelanguage.googleapis.com/v1beta/models/$mName:streamGenerateContent?alt=sse&key=$apiKey';
        final response = await dio.post<ResponseBody>(
          streamUrl,
          data: payload,
          options: Options(
            responseType: ResponseType.stream,
            headers: {'Content-Type': 'application/json'},
          ),
        );

        final stream = response.data!.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter());

        await for (final line in stream) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty) continue;
            try {
              final Map<String, dynamic> data = jsonDecode(jsonStr);
              final candidates = data['candidates'] as List?;
              if (candidates != null && candidates.isNotEmpty) {
                final parts = candidates[0]['content']?['parts'] as List?;
                if (parts != null) {
                  for (final p in parts) {
                    final txt = p['text']?.toString();
                    if (txt != null && txt.isNotEmpty) {
                      hasYielded = true;
                      yield txt;
                    }
                  }
                }
              }
            } catch (_) {}
          }
        }

        if (hasYielded) return;
        attemptErrors.add('$mName: Không có dữ liệu trả về (empty stream)');
      } catch (e) {
        if (hasYielded) return;
        String detail = e.toString();
        if (e is DioException) {
          final status = e.response?.statusCode;
          String serverMsg = '';
          try {
            final body = e.response?.data;
            if (body is ResponseBody) {
              final raw = await utf8.decoder.bind(body.stream).join();
              serverMsg = raw.length > 180 ? '${raw.substring(0, 180)}...' : raw;
            } else if (body != null) {
              serverMsg = body.toString();
            }
          } catch (_) {}
          detail = status != null
              ? 'HTTP $status${serverMsg.isNotEmpty ? " - $serverMsg" : ""}'
              : '${e.type.name}: ${e.message ?? ""}';
        }
        attemptErrors.add('$mName: $detail');
        debugPrint("Thử SSE model $mName thất bại ($detail), đang tự động fallback...");
        continue;
      }
    }

    if (!hasYielded) {
      throw Exception(attemptErrors.isNotEmpty
          ? attemptErrors.join('\n')
          : "Không thể kết nối đến Trợ lý Floria.");
    }
  }

  /// Hộp thoại cấu hình Gemini API Key & Lựa chọn Phiên bản Mô hình AI
  static void showApiKeyDialog(BuildContext context, {VoidCallback? onSaved}) async {
    final currentKey = await getApiKey() ?? '';
    final currentModel = await getModelName();
    final controller = TextEditingController(text: currentKey);
    String selectedModel = currentModel;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF364534).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF364534), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cấu hình Gemini AI",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF151E16),
                      ),
                    ),
                    Text(
                      "Google Gemini Thế hệ Mới",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF006D35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Google Gemini API Key đã được tích hợp sẵn vào hệ thống. Bạn có thể thay đổi Key hoặc phiên bản mô hình nếu muốn:",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF555F53),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: "Google Gemini API Key",
                    labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF364534)),
                    hintText: "AQ.Ab8...",
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.key, color: Color(0xFF364534), size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF364534)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF364534), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Chọn Phiên bản Mô hình AI:",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF151E16),
                  ),
                ),
                const SizedBox(height: 8),
                _buildModelOption(
                  title: " Gemini 3.8 Flash (Khuyên dùng: Mặc định)",
                  subtitle: "Thế hệ Flash 3.8 mới nhất, tốc độ cao và độ chính xác tối ưu.",
                  value: "gemini-3.8-flash",
                  selectedValue: selectedModel,
                  onChanged: (val) => setModalState(() => selectedModel = val),
                ),
                const SizedBox(height: 6),
                _buildModelOption(
                  title: "⚡ Gemini 3 Flash (Phản hồi ~1s)",
                  subtitle: "Thế hệ Flash 3, zero thinking delay, phản hồi tức thì.",
                  value: "gemini-3-flash-preview",
                  selectedValue: selectedModel,
                  onChanged: (val) => setModalState(() => selectedModel = val),
                ),
                const SizedBox(height: 6),
                _buildModelOption(
                  title: "🚀 Gemini 3.1 Flash-Lite (Siêu nhẹ)",
                  subtitle: "Tối ưu hóa độ trễ, tiết kiệm tài nguyên và ổn định cao.",
                  value: "gemini-3.1-flash-lite",
                  selectedValue: selectedModel,
                  onChanged: (val) => setModalState(() => selectedModel = val),
                ),
                const SizedBox(height: 6),
                _buildModelOption(
                  title: "🧠 Gemini 3.6 Flash (Chuyên sâu)",
                  subtitle: "Khả năng suy luận lâm sàng thực vật học mở rộng.",
                  value: "gemini-3.6-flash",
                  selectedValue: selectedModel,
                  onChanged: (val) => setModalState(() => selectedModel = val),
                ),
                const SizedBox(height: 12),
                Text(
                  "💡 Lấy API Key miễn phí tại: aistudio.google.com",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF006D35),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Đóng",
                style: GoogleFonts.inter(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final newKey = controller.text.trim();
                await saveApiKey(newKey);
                await saveModelName(selectedModel);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newKey.isEmpty
                            ? "Đang dùng Key mặc định của hệ thống!"
                            : "Đã lưu cấu hình và kích hoạt $selectedModel thành công!",
                      ),
                      backgroundColor: const Color(0xFF364534),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                onSaved?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF364534),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                "Lưu cấu hình",
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildModelOption({
    required String title,
    required String subtitle,
    required String value,
    required String selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF364534).withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF364534) : const Color(0xFFE4E2DF),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            RadioGroup<String>(
              groupValue: selectedValue,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              child: Radio<String>(
                value: value,
                activeColor: const Color(0xFF364534),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? const Color(0xFF151E16) : const Color(0xFF444842),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF747871),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tự động tóm tắt và đặt tiêu đề ngắn gọn (3-6 từ) cho cuộc hội thoại như ChatGPT
  static Future<String?> generateConversationTitle({
    required String userPrompt,
    String? aiResponse,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ));

    final model = await getModelName();
    final url = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey";

    final promptText = """
Bạn là trợ lý đặt tiêu đề hội thoại cho ứng dụng chăm sóc cây trồng Floria.
Dựa trên câu hỏi của người dùng: "$userPrompt"
${aiResponse != null && aiResponse.isNotEmpty ? 'Và câu trả lời tóm tắt: "${aiResponse.length > 200 ? aiResponse.substring(0, 200) : aiResponse}"' : ''}

Hãy đặt một tiêu đề ngắn gọn, súc tích, tự nhiên bằng tiếng Việt (từ 3 đến 6 từ) để tóm tắt chủ đề cuộc trò chuyện này (phong cách giống ChatGPT).
Quy tắc:
- Không dùng dấu ngoặc kép, không dùng dấu chấm cuối câu, không dùng emoji.
- Chỉ trả về duy nhất chuỗi tiêu đề.
Ví dụ:
- Gợi ý cây trồng cho người mới
- Cách chăm sóc Cây Lưỡi Hổ
- Xử lý cây bị vàng lá
- Kỹ thuật bón phân an toàn
""";

    try {
      final response = await dio.post(
        url,
        data: {
          "contents": [
            {
              "parts": [
                {"text": promptText}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.4,
            "maxOutputTokens": 30,
            "thinkingConfig": {"thinkingBudget": 0}
          }
        },
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            String title = parts[0]['text']?.toString().trim() ?? '';
            title = title.replaceAll('"', '').replaceAll("'", '').replaceAll('.', '').trim();
            if (title.isNotEmpty) {
              return title;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi tạo tiêu đề hội thoại tự động: $e");
    }
    return null;
  }
}
