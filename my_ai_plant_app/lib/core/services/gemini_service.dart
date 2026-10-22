import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

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

class GeminiService {
  static const String _prefKey = 'floria_gemini_api_key';
  static const String _prefModelKey = 'floria_gemini_model_name';
  static const String defaultModel = 'gemini-3-flash-preview';

  // Danh sách các mô hình thế hệ 3 mới nhất của Google hoạt động chuẩn xác 100%
  static const List<String> fallbackModels = [
    'gemini-3-flash-preview',
    'gemini-3.1-flash-lite',
    'gemini-3.1-flash-lite-preview',
    'gemini-3.6-flash',
  ];

  // 40 loài cây trong Cơ sở Dữ liệu của ứng dụng Floria
  static const List<Map<String, String>> database40Plants = [
    {"sci": "Adenium obesum", "vi": "Cây hoa sứ"},
    {"sci": "Aglaonema commutatum", "vi": "Cây ngọc ngân"},
    {"sci": "Alocasia amazonica", "vi": "Môn quan âm"},
    {"sci": "Alocasia macrorrhizos", "vi": "Cây ráy tai voi"},
    {"sci": "Aloe vera", "vi": "Nha đam"},
    {"sci": "Anthurium andraeanum", "vi": "Hồng môn"},
    {"sci": "Asplenium nidus", "vi": "Ráng ổ phụng"},
    {"sci": "Begonia maculata", "vi": "Thu hải đường chấm bi"},
    {"sci": "Bougainvillea glabra", "vi": "Hoa giấy"},
    {"sci": "Calathea makoyana", "vi": "Cây đuôi công"},
    {"sci": "Calathea orbifolia", "vi": "Cây đuôi công lá tròn"},
    {"sci": "Chlorophytum comosum", "vi": "Cỏ lan chi"},
    {"sci": "Codiaeum variegatum", "vi": "Cây cô tòng"},
    {"sci": "Crassula ovata", "vi": "Cây ngọc bích"},
    {"sci": "Cycas revoluta", "vi": "Cây vạn tuế"},
    {"sci": "Dieffenbachia seguine", "vi": "Môn trường sinh đốm"},
    {"sci": "Dracaena fragrans", "vi": "Thiết mộc lan"},
    {"sci": "Dracaena marginata", "vi": "Phất dụ mảnh"},
    {"sci": "Dracaena reflexa", "vi": "Trúc bách hợp"},
    {"sci": "Epipremnum aureum", "vi": "Trầu bà vàng"},
    {"sci": "Euphorbia milii", "vi": "Hoa bát tiên"},
    {"sci": "Ficus benjamina", "vi": "Cây si"},
    {"sci": "Ficus elastica", "vi": "Đa búp đỏ"},
    {"sci": "Ficus lyrata", "vi": "Bàng Singapore"},
    {"sci": "Hedera helix", "vi": "Thường xuân"},
    {"sci": "Maranta leuconeura", "vi": "Cây dạ lam"},
    {"sci": "Monstera deliciosa", "vi": "Trầu bà Nam Mỹ"},
    {"sci": "Nephrolepis exaltata", "vi": "Dương xỉ Boston"},
    {"sci": "Pachira aquatica", "vi": "Cây kim ngân"},
    {"sci": "Peperomia obtusifolia", "vi": "Cây trường sinh"},
    {"sci": "Philodendron bipinnatifidum", "vi": "Trầu bà thanh xuân"},
    {"sci": "Philodendron hederaceum", "vi": "Trầu bà lá tim"},
    {"sci": "Pilea peperomioides", "vi": "Cây cỏ gương"},
    {"sci": "Sansevieria trifasciata", "vi": "Cây lưỡi hổ"},
    {"sci": "Schefflera arboricola", "vi": "Ngũ gia bì"},
    {"sci": "Schlumbergera truncata", "vi": "Lan càng cua"},
    {"sci": "Spathiphyllum wallisii", "vi": "Lan ý"},
    {"sci": "Syngonium podophyllum", "vi": "Tróc bạc"},
    {"sci": "Tradescantia zebrina", "vi": "Thài lài tía"},
    {"sci": "Zamioculcas zamiifolia", "vi": "Kim tiền"},
  ];

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
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefModelKey)?.trim();
    if (saved != null && fallbackModels.contains(saved)) {
      return saved;
    }
    return defaultModel;
  }

  static Future<void> saveModelName(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefModelKey, model.trim());
  }

  static Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
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

    final dbListPrompt = database40Plants
        .map((p) => "- ${p['sci']} (${p['vi']})")
        .join("\n");

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

    final systemInstruction = Content.system(
      '''Bạn là Trợ lý Cây trồng Floria (hoặc Trợ lý Floria) - chuyên gia nông nghiệp và thực vật học giàu kinh nghiệm, khách quan, tận tâm và gần gũi.
Ngôn ngữ trả lời: 100% tiếng Việt tự nhiên, ấm áp, chuẩn khoa học thực vật.
XƯNG HÔ: Tự xưng là "Trợ lý Floria" (TUYỆT ĐỐI KHÔNG tự xưng là "Floria AI", "Bác sĩ AI" hay dùng từ "AI").
${currentPlantContext != null && currentPlantContext.isNotEmpty ? 'Ngữ cảnh hiện tại của người dùng: $currentPlantContext.' : ''}

NGUYÊN TẮC HÀNH NGHỀ & TƯ VẤN QUAN TRỌNG:
1. ĐẶT LỢI ÍCH CỦA CÂY VÀ NGƯỜI DÙNG LÊN HÀNG ĐẦU:
   - Luôn ưu tiên giải pháp chăm sóc tự nhiên: điều chỉnh ánh sáng, độ ẩm, kiểm soát lượng nước tưới, độ thông thoáng trước khi nghĩ đến thuốc hay phân bón.
   - Trả lời đúng trọng tâm câu hỏi của người dùng, KHÔNG gượng ép bán sản phẩm.

2. QUY TẮC KÊ ĐƠN THUỐC / VẬT TƯ (RẤT CHẶT CHẼ):
   - TUYỆT ĐỐI KHÔNG đề xuất sản phẩm hay đính kèm mã thẻ khi:
     + Người dùng chỉ hỏi kiến thức cơ bản (lịch tưới nước, vị trí đặt cây, cách tỉa cành thông thường, ý nghĩa cây...).
     + Cây chỉ gặp vấn đề sinh lý nhẹ có thể giải quyết bằng cách thay đổi chế độ chăm sóc.
   - CHỈ ĐƯỢC PHÉP đề xuất và đính kèm thẻ sản phẩm trong 2 TRƯỜNG HỢP:
     + Trường hợp A: Cây thực sự bị bệnh hoặc sâu hại phá hoại nghiêm trọng (rệp sáp, bọ trĩ, nhện đỏ, nấm thán thư, đốm lá vi khuẩn, thối rễ úng nặng) bắt buộc phải dùng chế phẩm điều trị.
     + Trường hợp B: Người dùng CHỦ ĐỘNG hỏi xin tên thuốc, phân bón, đất trồng hoặc nhờ đề xuất sản phẩm.

3. KHO DƯỢC PHẨM & VẬT TƯ FLORIA (CHỈ KÊ ĐƠN KHI THỎA MÃN ĐIỀU KIỆN TRÊN):
   - id: `nano-bac-tri-nam` ➔ Chế Phẩm Nano Bạc Đồng Sinh Học (Đặc trị thán thư, đốm lá, phấn trắng, cháy lá vi khuẩn).
   - id: `dau-neem-tri-rep` ➔ Tinh Dầu Neem Hữu Cơ Ép Lạnh (Đặc trị rệp sáp, bọ trĩ, nhện đỏ, rầy mềm).
   - id: `phan-rong-bien-kich-re` ➔ Phân Bón Hữu Cơ Rong Biển & Vi Lượng (Phục hồi cây vàng lá, suy rễ sau ốm).
   - id: `phan-trun-que-vien-nen` ➔ Phân Trùn Quế Viên Nén Tan Chậm (Bổ sung dinh dưỡng êm dịu, ngăn thối rễ).
   - id: `binh-xit-phun-suong-15l` ➔ Bình Xịt Áp Suất Phun Sương Mịn 1.5L (Dụng cụ phun thuốc đẫm đều 2 mặt lá).
   - id: `keo-cat-tia-canh-nhat` ➔ Kéo Cắt Tỉa Cành Thép SK5 (Khử khuẩn cắt bỏ triệt để cành lá bệnh tránh lây chéo).
   - id: `dat-trong-indoor-premium` ➔ Giá Thể Đất Trồng Indoor Mix Thoát Nước Tốt (Cấp cứu cây úng rễ, thay chậu mới).

4. CÚ PHÁP ĐÍNH KÈM THẺ (NẾU VÀ CHỈ NẾU THỰC SỰ CẦN KÊ ĐƠN):
   Chỉ khi thỏa mãn điều kiện kê đơn, hãy ghi mã ở dòng cuối cùng:
   [RECOMMEND_PRODUCT: id_san_pham]
   Nếu không cần kê đơn, TUYỆT ĐỐI KHÔNG ghi thẻ này.'''
    );

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

    final systemPrompt = '''Bạn là Trợ lý Cây trồng Floria (hoặc Trợ lý Floria) - chuyên gia nông nghiệp và thực vật học giàu kinh nghiệm, khách quan, tận tâm và gần gũi.
Ngôn ngữ trả lời: 100% tiếng Việt tự nhiên, ấm áp, chuẩn khoa học thực vật.
XƯNG HÔ: Tự xưng là "Trợ lý Floria" (TUYỆT ĐỐI KHÔNG tự xưng là "Floria AI", "Bác sĩ AI" hay dùng từ "AI").
${currentPlantContext != null && currentPlantContext.isNotEmpty ? 'Ngữ cảnh hiện tại của người dùng: $currentPlantContext.' : ''}

NGUYÊN TẮC HÀNH NGHỀ & TƯ VẤN QUAN TRỌNG:
1. ĐẶT LỢI ÍCH CỦA CÂY VÀ NGƯỜI DÙNG LÊN HÀNG ĐẦU:
   - Luôn ưu tiên giải pháp chăm sóc tự nhiên: điều chỉnh ánh sáng, độ ẩm, kiểm soát lượng nước tưới, độ thông thoáng trước khi nghĩ đến thuốc hay phân bón.
   - Trả lời đúng trọng tâm câu hỏi của người dùng, KHÔNG gượng ép bán sản phẩm.

2. QUY TẮC KÊ ĐƠN THUỐC / VẬT TƯ (RẤT CHẶT CHẼ):
   - TUYỆT ĐỐI KHÔNG đề xuất sản phẩm hay đính kèm mã thẻ khi:
     + Người dùng chỉ hỏi kiến thức cơ bản (lịch tưới nước, vị trí đặt cây, cách tỉa cành thông thường, ý nghĩa cây...).
     + Cây chỉ gặp vấn đề sinh lý nhẹ có thể giải quyết bằng cách thay đổi chế độ chăm sóc.
   - CHỈ ĐƯỢC PHÉP đề xuất và đính kèm thẻ sản phẩm trong 2 TRƯỜNG HỢP:
     + Trường hợp A: Cây thực sự bị bệnh hoặc sâu hại phá hoại nghiêm trọng (rệp sáp, bọ trĩ, nhện đỏ, nấm thán thư, đốm lá vi khuẩn, thối rễ úng nặng) bắt buộc phải dùng chế phẩm điều trị.
     + Trường hợp B: Người dùng CHỦ ĐỘNG hỏi xin tên thuốc, phân bón, đất trồng hoặc nhờ đề xuất sản phẩm (Ví dụ: "dùng phân gì", "mua thuốc gì").

3. KHO DƯỢC PHẨM & VẬT TƯ FLORIA (CHỈ KÊ ĐƠN KHI THỎA MÃN ĐIỀU KIỆN TRÊN):
   - id: `nano-bac-tri-nam` ➔ Chế Phẩm Nano Bạc Đồng Sinh Học (Đặc trị thán thư, đốm lá, phấn trắng, cháy lá vi khuẩn).
   - id: `dau-neem-tri-rep` ➔ Tinh Dầu Neem Hữu Cơ Ép Lạnh (Đặc trị rệp sáp, bọ trĩ, nhện đỏ, rầy mềm).
   - id: `phan-rong-bien-kich-re` ➔ Phân Bón Hữu Cơ Rong Biển & Vi Lượng (Phục hồi cây vàng lá, suy rễ sau ốm).
   - id: `phan-trun-que-vien-nen` ➔ Phân Trùn Quế Viên Nén Tan Chậm (Bổ sung dinh dưỡng êm dịu, ngăn thối rễ).
   - id: `binh-xit-phun-suong-15l` ➔ Bình Xịt Áp Suất Phun Sương Mịn 1.5L (Dụng cụ phun thuốc đẫm đều 2 mặt lá).
   - id: `keo-cat-tia-canh-nhat` ➔ Kéo Cắt Tỉa Cành Thép SK5 (Khử khuẩn cắt bỏ triệt để cành lá bệnh tránh lây chéo).
   - id: `dat-trong-indoor-premium` ➔ Giá Thể Đất Trồng Indoor Mix Thoát Nước Tốt (Cấp cứu cây úng rễ, thay chậu mới).

4. CÚ PHÁP ĐÍNH KÈM THẺ KÊ ĐƠN VẬT TƯ (NẾU VÀ CHỈ NẾU THỰC SỰ CẦN KÊ ĐƠN):
   Chỉ khi thỏa mãn điều kiện kê đơn, hãy ghi mã ở dòng cuối cùng:
   [RECOMMEND_PRODUCT: id_san_pham]
   Nếu không cần kê đơn, TUYỆT ĐỐI KHÔNG ghi thẻ này.

5. CÚ PHÁP ĐỀ XUẤT LỊCH CHĂM SÓC CHUẨN KHOA HỌC:
   - CHỈ đính kèm thẻ lịch chăm sóc khi người dùng hỏi toàn diện về "cách chăm sóc cây", "lịch chăm sóc", "tổng quan chăm sóc cây như thế nào".
   - TUYỆT ĐỐI KHÔNG đính kèm thẻ [CARE_SCHEDULE] khi:
     + Người dùng chỉ hỏi mua phân gì, dùng thuốc gì, chữa bệnh gì.
     + Câu trả lời đã đính kèm thẻ vật tư [RECOMMEND_PRODUCT] (trừ khi người dùng hỏi cả 2 việc cùng lúc).
   - TUYỆT ĐỐI KHÔNG viết các dòng tiêu đề cụt lủn ở cuối phản hồi như '**Lịch chăm sóc đề xuất...:**' vì giao diện ứng dụng sẽ tự động sinh thẻ riêng biệt. Hãy kết thúc văn bản tự nhiên rồi đặt thẻ ở dòng cuối cùng.
   Cú pháp thẻ chuẩn:
   [CARE_SCHEDULE: water=SO_NGAY_TUOI, fertilize=SO_NGAY_BON_PHAN, clean=SO_NGAY_LAU_LA]
   Ví dụ:
   [CARE_SCHEDULE: water=5, fertilize=20, clean=3]
   Quy ước số ngày: water (1-14), fertilize (7-60), clean (1-14).''';

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

    final payload = {
      'contents': apiContents,
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'generationConfig': {
        'temperature': enableDeepThinking ? 0.2 : 0.35,
        'topK': 40,
        'topP': 0.95,
        'thinkingConfig': {
          'thinkingBudget': enableDeepThinking ? 1024 : 0, // 0: Siêu tốc phản hồi ~1s; 1024: Suy nghĩ sâu phân tích đa tầng
        }
      }
    };

    final modelsToTry = [
      primaryModel,
      ...fallbackModels.where((m) => m != primaryModel),
    ];

    bool hasYielded = false;
    dynamic lastError;
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 25),
    ));

    for (final mName in modelsToTry) {
      try {
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
      } catch (e) {
        lastError = e;
        if (hasYielded) return;
        debugPrint("Thử SSE model $mName thất bại ($e), đang tự động fallback...");
        continue;
      }
    }

    if (!hasYielded) {
      throw lastError ?? Exception("Không thể kết nối đến Bác sĩ Cây trồng AI.");
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
                  title: "⚡ Gemini 3 Flash (Khuyên dùng: Phản hồi ~1s)",
                  subtitle: "Thế hệ Flash 3 mới nhất, zero thinking delay, phản hồi tức thì.",
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
            Radio<String>(
              value: value,
              groupValue: selectedValue,
              activeColor: const Color(0xFF364534),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
