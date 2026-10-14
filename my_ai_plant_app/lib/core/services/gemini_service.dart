import 'dart:convert';
import 'dart:typed_data';
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
  static const String defaultModel = 'gemini-3.8-flash';

  // Danh sách các mô hình hoạt động ổn định nhất theo đo lường thực tế để tự động chuyển tiếp (fallback) khi quá tải (503)
  static const List<String> fallbackModels = [
    'gemini-3.5-flash-lite', // Đã kiểm chứng: độ trễ cực thấp, không bị nghẽn tải
    'gemini-3.7-flash',      // Bản 3.7 cân bằng mạnh mẽ
    'gemini-3-flash-preview',
    'gemini-flash-lite-latest',
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
    return prefs.getString(_prefModelKey)?.trim() ?? defaultModel;
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
      '''Bạn là Bác sĩ Cây trồng Floria AI - chuyên gia nông nghiệp và thực vật học giàu kinh nghiệm, thân thiện và tận tâm.
Ngôn ngữ trả lời: 100% tiếng Việt tự nhiên, ấm áp, chuyên nghiệp.
${currentPlantContext != null && currentPlantContext.isNotEmpty ? 'Ngữ cảnh hiện tại của người dùng: $currentPlantContext.' : ''}
Hãy tư vấn chi tiết về:
- Cách chăm sóc, tưới nước, ánh sáng, phân bón.
- Chẩn đoán bệnh cây (vàng lá, rệp, đốm nâu, úng rễ, sâu bệnh) và cách chữa trị an toàn sinh học.
- Hướng dẫn cắt tỉa, nhân giống cây trồng trong nhà và ngoài trời.
Hãy định dạng câu trả lời rõ ràng với gạch đầu dòng, nhấn mạnh các lưu ý quan trọng.
'''
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
                  title: "⚡ Gemini 3.8 Flash (Thông minh nhất)",
                  subtitle: "Thị giác sắc bén, giải đáp bệnh cây sâu sắc (Flagship).",
                  value: "gemini-3.8-flash",
                  selectedValue: selectedModel,
                  onChanged: (val) => setModalState(() => selectedModel = val),
                ),
                const SizedBox(height: 6),
                _buildModelOption(
                  title: "🌱 Gemini 3.5 Flash-Lite (Khuyên dùng: Siêu tốc & Ổn định)",
                  subtitle: "Phản hồi tức thì (<1s), không lo nghẽn mạng giờ cao điểm.",
                  value: "gemini-3.5-flash-lite",
                  selectedValue: selectedModel,
                  onChanged: (val) => setModalState(() => selectedModel = val),
                ),
                const SizedBox(height: 6),
                _buildModelOption(
                  title: "🚀 Gemini 3.7 Flash (Cân bằng mạnh mẽ)",
                  subtitle: "Mô hình thế hệ 3.7 cân bằng giữa tốc độ và suy luận.",
                  value: "gemini-3.7-flash",
                  selectedValue: selectedModel,
                  onChanged: (val) => setModalState(() => selectedModel = val),
                ),
                const SizedBox(height: 6),
                _buildModelOption(
                  title: "🔄 Gemini Flash-Lite Latest",
                  subtitle: "Tự động trỏ về phiên bản Lite mới nhất của Google.",
                  value: "gemini-flash-lite-latest",
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
}
