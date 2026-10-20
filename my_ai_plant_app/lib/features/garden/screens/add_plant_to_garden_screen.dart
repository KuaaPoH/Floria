import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/gemini_service.dart';
import '../providers/garden_provider.dart';
import '../models/user_garden.dart';

class AddPlantToGardenScreen extends StatefulWidget {
  final String? initialZone;

  const AddPlantToGardenScreen({super.key, this.initialZone});

  @override
  State<AddPlantToGardenScreen> createState() => _AddPlantToGardenScreenState();
}

class _AddPlantToGardenScreenState extends State<AddPlantToGardenScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  String? _uploadedImageUrl;

  final TextEditingController _aiHintNotesCtrl = TextEditingController();

  bool _isLoading = false;
  String? _statusText;
  bool _hasGeminiKey = false;

  @override
  void initState() {
    super.initState();
    _checkGeminiKey();
  }

  Future<void> _checkGeminiKey() async {
    final hasKey = await GeminiService.hasApiKey();
    if (mounted) {
      setState(() {
        _hasGeminiKey = hasKey;
      });
    }
  }

  @override
  void dispose() {
    _aiHintNotesCtrl.dispose();
    super.dispose();
  }

  // Chọn ảnh từ Camera hoặc Thư viện
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 88,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
          _uploadedImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi khi chọn ảnh: $e"), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  // Đảm bảo lấy được URL vĩnh viễn lưu trữ trên backend thay vì đường dẫn blob tạm thời của trình duyệt
  Future<String?> _ensurePermanentImageUrl(Map<String, dynamic> wikiData) async {
    if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
      return _uploadedImageUrl;
    }
    if (_imageBytes != null && _selectedImage != null) {
      try {
        final dio = Dio();
        final multipartFile = MultipartFile.fromBytes(
          _imageBytes!,
          filename: _selectedImage!.name,
        );
        final formData = FormData.fromMap({'file': multipartFile});
        final res = await dio.post(AppConstants.uploadImageUrl, data: formData);
        if (res.statusCode == 200 && res.data != null && res.data['image_url'] != null) {
          _uploadedImageUrl = res.data['image_url'].toString();
          return _uploadedImageUrl;
        }
      } catch (e) {
        debugPrint("Lỗi upload ảnh lên server: $e");
      }
    }
    if (wikiData['imageUrl'] != null && wikiData['imageUrl'].toString().isNotEmpty) {
      return wikiData['imageUrl'].toString();
    }
    if (wikiData['image_url'] != null && wikiData['image_url'].toString().isNotEmpty) {
      return wikiData['image_url'].toString();
    }
    return _selectedImage?.path;
  }

  // Danh sách vị trí gợi ý dựa trên môi trường của khu vườn
  List<String> _getSuggestedZonesForEnvironment(String? env) {
    switch (env) {
      case 'Trong nhà':
        return ["Phòng khách", "Phòng ngủ", "Cửa sổ"];
      case 'Ngoài trời':
        return ["Ban công", "Sân thượng", "Sân trước"];
      case 'Văn phòng':
        return ["Bàn làm việc", "Góc phòng họp", "Quầy tiếp tân"];
      case 'Nhà kính':
        return ["Kệ tầng trên", "Kệ tầng dưới", "Khu ươm giống"];
      default:
        return ["Phòng khách", "Ban công", "Bàn làm việc"];
    }
  }

  // Phân tích chu kỳ tưới từ chuỗi văn bản (VD: "2-3 ngày/lần" -> 3 ngày)
  int _extractWaterFrequencyDays(dynamic freqVal) {
    if (freqVal is num) return freqVal.toInt();
    if (freqVal is String) {
      final lower = freqVal.toLowerCase();
      if (lower.contains("ngày")) {
        final match = RegExp(r'(\d+)').firstMatch(lower);
        if (match != null) {
          return int.tryParse(match.group(1) ?? '3') ?? 3;
        }
      }
      if (lower.contains("tuần")) {
        final match = RegExp(r'(\d+)').firstMatch(lower);
        if (match != null) {
          final timesPerWeek = int.tryParse(match.group(1) ?? '1') ?? 1;
          return (7 / timesPerWeek).round().clamp(1, 14);
        }
        return 7;
      }
    }
    return 3;
  }

  // Quét AI: Ưu tiên Gemini Multimodal (Ảnh + Miêu tả nhận dạng), Fallback về AI Engine
  Future<void> _handleScan() async {
    if (_imageBytes == null || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chụp ảnh hoặc chọn ảnh lá cây trước nhé!"),
          backgroundColor: Color(0xFFE06C00),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusText = _hasGeminiKey
          ? "Google Gemini đang phân tích ảnh và đối chiếu miêu tả..."
          : "AI Engine đang phân tích đặc điểm nhận dạng thực vật...";
    });

    try {
      if (_hasGeminiKey) {
        // --- 1. SỬ DỤNG GOOGLE GEMINI MULTIMODAL ---
        final geminiRes = await GeminiService.identifyPlantWithHint(
          imageBytes: _imageBytes!,
          userHint: _aiHintNotesCtrl.text.trim(),
        );

        if (!geminiRes.isPlant) {
          throw Exception(
            geminiRes.rejectReason ?? "Hệ thống phát hiện đây không phải là thực vật. Vui lòng chụp rõ lại cây cảnh!",
          );
        }

        Map<String, dynamic> plantWikiData = {};

        if (geminiRes.matchedDatabase) {
          // Khớp 1 trong 40 cây CSDL -> Tra cứu Firestore plants_info để lấy đủ thông số
          try {
            final doc = await FirebaseFirestore.instance
                .collection("plants_info")
                .doc(geminiRes.scientificName)
                .get();
            if (doc.exists && doc.data() != null) {
              plantWikiData = Map<String, dynamic>.from(doc.data()!);
            }
          } catch (_) {}
        } else {
          // LÀ CÂY, NHƯNG NGOÀI 40 CÂY CSDL -> Các ô khác hiển thị 'Đang cập nhật...'
          plantWikiData = {
            'name_vi': geminiRes.nameVi,
            'scientific_name': geminiRes.scientificName,
            'light': 'Đang cập nhật...',
            'water_frequency': 'Đang cập nhật...',
            'difficulty': 'Đang cập nhật...',
            'plant_type': 'Đang cập nhật...',
            'family': 'Đang cập nhật...',
            'origin': 'Đang cập nhật...',
            'short_desc': geminiRes.shortDesc.isNotEmpty ? geminiRes.shortDesc : 'Đang cập nhật...',
          };
        }

        final int freqDays = _extractWaterFrequencyDays(plantWikiData['water_frequency']);
        final String plantType = plantWikiData['plant_type'] ?? 'Đang cập nhật...';

        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _statusText = null;
        });

        _showSaveToGardenBottomSheet(
          nameVi: geminiRes.nameVi,
          scientificName: geminiRes.scientificName,
          confidence: geminiRes.confidence,
          plantType: plantType,
          freqDays: freqDays,
          wikiData: plantWikiData,
        );
      } else {
        // --- 2. FALLBACK SANG BACKEND SPRING BOOT + CLIP / AI ENGINE ---
        final dio = Dio();
        final multipartFile = MultipartFile.fromBytes(
          _imageBytes!,
          filename: _selectedImage!.name,
        );
        final formData = FormData.fromMap({
          'file': multipartFile,
          'userHint': _aiHintNotesCtrl.text.trim(),
        });

        final response = await dio.post(
          "${AppConstants.scanDiseaseUrl}?model=efficientnetb0",
          data: formData,
          options: Options(headers: {'Accept': 'application/json'}),
        );

        if (response.statusCode != 200 || response.data == null) {
          throw Exception("Server phản hồi mã: ${response.statusCode}");
        }

        final Map<String, dynamic> result = Map<String, dynamic>.from(response.data);
        if (result['image_url'] != null) {
          _uploadedImageUrl = result['image_url'].toString();
        }

        // Kiểm tra xem có phải thực vật không (bảo vệ bởi CLIP Gatekeeper)
        final bool isValidPlant = result['is_valid_plant'] == true;
        if (!isValidPlant) {
          throw Exception(
            result['message'] ?? "Hệ thống phát hiện đây không phải là thực vật. Vui lòng chụp ảnh lá cây hoặc cây cảnh!",
          );
        }

        final String prediction = result['prediction'] ?? 'Cây cảnh';
        final String nameVi = result['name_vi'] ?? prediction;
        final double confidence = (result['confidence'] as num?)?.toDouble() ?? 88.0;

        // Tra cứu từ điển thực vật trong kết quả
        Map<String, dynamic> plantWikiData = {};
        if (result['plants_map'] is Map && result['plants_map'][prediction] != null) {
          plantWikiData = Map<String, dynamic>.from(result['plants_map'][prediction]);
        }

        // Nếu không có trong từ điển 40 cây -> Đặt các ô khác thành 'Đang cập nhật...'
        if (plantWikiData.isEmpty) {
          plantWikiData = {
            'name_vi': nameVi,
            'scientific_name': prediction,
            'light': 'Đang cập nhật...',
            'water_frequency': 'Đang cập nhật...',
            'difficulty': 'Đang cập nhật...',
            'plant_type': 'Đang cập nhật...',
            'family': 'Đang cập nhật...',
            'short_desc': 'Đang cập nhật...',
          };
        }

        final int freqDays = _extractWaterFrequencyDays(plantWikiData['water_frequency']);
        final String plantType = plantWikiData['plant_type'] ?? 'Đang cập nhật...';

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _statusText = null;
        });

        _showSaveToGardenBottomSheet(
          nameVi: nameVi,
          scientificName: prediction,
          confidence: confidence,
          plantType: plantType,
          freqDays: freqDays,
          wikiData: plantWikiData,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusText = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$e".replaceAll("Exception: ", "")),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Modal BottomSheet: Hiển thị đầy đủ thông tin nhận diện (tên khoa học, tên tiếng Việt, thông số sinh thái) & chọn chỗ đặt
  void _showSaveToGardenBottomSheet({
    required String nameVi,
    required String scientificName,
    required double confidence,
    required String plantType,
    required int freqDays,
    required Map<String, dynamic> wikiData,
  }) {
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
    final UserGarden? currentGarden = gardenProvider.selectedGarden;
    final suggestedZones = _getSuggestedZonesForEnvironment(currentGarden?.environment);

    final TextEditingController nicknameCtrl = TextEditingController(text: nameVi);
    final TextEditingController customZoneCtrl = TextEditingController();

    String selectedZone = suggestedZones.first;
    final init = widget.initialZone?.trim() ?? '';
    if (init.isNotEmpty && init != "Tất cả") {
      selectedZone = init;
    }
    bool isCustomZone = !suggestedZones.contains(selectedZone);
    if (isCustomZone) {
      customZoneCtrl.text = selectedZone;
    }

    final String light = wikiData['light'] ?? 'Đang cập nhật...';
    final String waterFreq = wikiData['water_frequency'] ?? 'Đang cập nhật...';
    final String difficulty = wikiData['difficulty'] ?? 'Đang cập nhật...';
    final String shortDesc = wikiData['short_desc'] ?? '';
    final String family = wikiData['family'] ?? '';

    int timesPerWeek = 2;
    if (freqDays <= 1) {
      timesPerWeek = 7;
    } else if (freqDays == 2) {
      timesPerWeek = 3;
    } else if (freqDays <= 4) {
      timesPerWeek = 2;
    } else {
      timesPerWeek = 1;
    }

    String reminderTime = "07:00";
    final List<Map<String, String>> presetTimes = [
      {"label": "🌅 07:00 (Sáng sớm)", "time": "07:00"},
      {"label": "🌤️ 09:30", "time": "09:30"},
      {"label": "🌇 17:30 (Chiều mát)", "time": "17:30"},
      {"label": "🌙 20:00 (Tối)", "time": "20:00"},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(modalContext).size.height * 0.9,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFFBF9F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh kéo nhỏ
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4E8CE),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Tiêu đề & kết quả nhận diện
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _imageBytes != null
                              ? Image.memory(_imageBytes!, width: 72, height: 72, fit: BoxFit.cover)
                              : Container(
                                  width: 72,
                                  height: 72,
                                  color: const Color(0xFF364534).withOpacity(0.08),
                                  child: const Icon(Icons.local_florist, color: Color(0xFF364534), size: 32),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF364534).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      confidence > 0
                                          ? "ĐỘ CHÍNH XÁC: ${confidence.toStringAsFixed(1)}%"
                                          : "KHỚP TỐT NHẤT",
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF364534),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (family.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        family,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF747871),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                nameVi,
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B1C1A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                scientificName,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6A756B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Mô tả ngắn nếu có
                    if (shortDesc.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE4E2DF)),
                        ),
                        child: Text(
                          shortDesc,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF444842),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Lưới thông số sinh thái (Ánh sáng, Nước, Độ khó)
                    Row(
                      children: [
                        Expanded(
                          child: _buildEcoBadge(
                            icon: Icons.wb_sunny_outlined,
                            title: "Ánh sáng",
                            value: light,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildEcoBadge(
                            icon: Icons.water_drop_outlined,
                            title: "Tưới nước",
                            value: waterFreq,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildEcoBadge(
                            icon: Icons.spa_outlined,
                            title: "Chăm sóc",
                            value: difficulty,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. Biệt danh cây
                    Text(
                      "Tên hoặc biệt danh trong vườn",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1C1A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nicknameCtrl,
                      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1B1C1A)),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.loyalty_outlined, size: 18, color: Color(0xFF364534)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE4E2DF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE4E2DF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF364534), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Chỗ đặt cây trong khu vườn
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Chỗ đặt cây",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B1C1A),
                          ),
                        ),
                        if (currentGarden != null)
                          Text(
                            "Vườn: ${currentGarden.name} (${currentGarden.environment})",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF364534),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...suggestedZones.map((zone) {
                          final isSel = !isCustomZone && selectedZone == zone;
                          return ChoiceChip(
                            label: Text(zone),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  selectedZone = zone;
                                  isCustomZone = false;
                                });
                              }
                            },
                            selectedColor: const Color(0xFF364534),
                            backgroundColor: Colors.white,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                              color: isSel ? Colors.white : const Color(0xFF444842),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSel ? const Color(0xFF364534) : const Color(0xFFE4E2DF),
                              ),
                            ),
                          );
                        }),
                        ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_note_outlined, size: 16, color: isCustomZone ? Colors.white : const Color(0xFF444842)),
                              const SizedBox(width: 4),
                              const Text("Khác..."),
                            ],
                          ),
                          selected: isCustomZone,
                          onSelected: (val) {
                            setModalState(() {
                              isCustomZone = true;
                            });
                          },
                          selectedColor: const Color(0xFF364534),
                          backgroundColor: Colors.white,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isCustomZone ? FontWeight.w600 : FontWeight.w500,
                            color: isCustomZone ? Colors.white : const Color(0xFF444842),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isCustomZone ? const Color(0xFF364534) : const Color(0xFFE4E2DF),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Ô nhập chỗ đặt tùy biến nếu chọn Khác...
                    if (isCustomZone) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customZoneCtrl,
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1B1C1A)),
                        decoration: InputDecoration(
                          hintText: 'Nhập vị trí đặt cây (VD: Góc làm việc, Bàn ăn, Cạnh TV...)',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF747871)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF364534)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF364534), width: 1.5),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // 3. Tần suất tưới nước (Theo khuyến nghị từ điển & tùy chỉnh người dùng)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Lịch tưới nước",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B1C1A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF364534).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Khuyến nghị: $waterFreq",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF364534),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Hàng chip chọn nhanh tần suất
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFrequencyChip(
                          label: "1 lần / tuần",
                          isSelected: timesPerWeek == 1,
                          onTap: () => setModalState(() => timesPerWeek = 1),
                        ),
                        _buildFrequencyChip(
                          label: "2 lần / tuần",
                          isSelected: timesPerWeek == 2,
                          onTap: () => setModalState(() => timesPerWeek = 2),
                        ),
                        _buildFrequencyChip(
                          label: "3 lần / tuần",
                          isSelected: timesPerWeek == 3,
                          onTap: () => setModalState(() => timesPerWeek = 3),
                        ),
                        _buildFrequencyChip(
                          label: "Hàng ngày (7 lần)",
                          isSelected: timesPerWeek == 7,
                          onTap: () => setModalState(() => timesPerWeek = 7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Bộ tinh chỉnh tăng giảm số lần
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE4E2DF)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tùy chỉnh: $timesPerWeek lần/tuần (~mỗi ${(7 / timesPerWeek).round().clamp(1, 14)} ngày)",
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF444842), fontWeight: FontWeight.w500),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 22, color: Color(0xFF364534)),
                                onPressed: timesPerWeek > 1 ? () => setModalState(() => timesPerWeek--) : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "$timesPerWeek",
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 22, color: Color(0xFF364534)),
                                onPressed: timesPerWeek < 14 ? () => setModalState(() => timesPerWeek++) : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4. Khung giờ nhắc nhở tưới cây
                    Text(
                      "Khung giờ nhắc nhở",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1C1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...presetTimes.map((item) {
                          final isSel = reminderTime == item['time'];
                          return ChoiceChip(
                            label: Text(item['label']!),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setModalState(() => reminderTime = item['time']!);
                            },
                            selectedColor: const Color(0xFF364534),
                            backgroundColor: Colors.white,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                              color: isSel ? Colors.white : const Color(0xFF444842),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSel ? const Color(0xFF364534) : const Color(0xFFE4E2DF),
                              ),
                            ),
                          );
                        }),
                        ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 15),
                              const SizedBox(width: 4),
                              Text(
                                !presetTimes.any((t) => t['time'] == reminderTime)
                                    ? reminderTime
                                    : "Giờ khác...",
                              ),
                            ],
                          ),
                          selected: !presetTimes.any((t) => t['time'] == reminderTime),
                          onSelected: (val) async {
                            final pickedTime = await showTimePicker(
                              context: modalContext,
                              initialTime: const TimeOfDay(hour: 7, minute: 0),
                              builder: (ctx, child) {
                                return Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF364534),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedTime != null) {
                              final h = pickedTime.hour.toString().padLeft(2, '0');
                              final m = pickedTime.minute.toString().padLeft(2, '0');
                              setModalState(() => reminderTime = "$h:$m");
                            }
                          },
                          selectedColor: const Color(0xFF364534),
                          backgroundColor: Colors.white,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: !presetTimes.any((t) => t['time'] == reminderTime) ? Colors.white : const Color(0xFF444842),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: !presetTimes.any((t) => t['time'] == reminderTime)
                                  ? const Color(0xFF364534)
                                  : const Color(0xFFE4E2DF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Nút xác nhận lưu vào vườn
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          final finalZone = isCustomZone && customZoneCtrl.text.trim().isNotEmpty
                              ? customZoneCtrl.text.trim()
                              : selectedZone;

                          final finalNickname = nicknameCtrl.text.trim().isNotEmpty
                              ? nicknameCtrl.text.trim()
                              : nameVi;

                          final finalCalculatedDays = (7 / timesPerWeek).round().clamp(1, 14);

                          Navigator.pop(ctx); // Đóng modal
                          final permanentUrl = await _ensurePermanentImageUrl(wikiData);

                          final success = await gardenProvider.addPlant(
                            gardenId: currentGarden?.id,
                            nameVi: nameVi,
                            scientificName: scientificName,
                            nickname: finalNickname,
                            zone: finalZone,
                            imageUrl: permanentUrl,
                            plantType: plantType,
                            waterFrequencyDays: finalCalculatedDays,
                            reminderTime: reminderTime,
                            notes: _aiHintNotesCtrl.text.trim(),
                            wikiData: wikiData,
                          );

                          if (mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          "Đã thêm '$finalNickname' vào '$finalZone' thành công! 🌿",
                                          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF364534),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                              Navigator.pop(context, true); // Trở về màn hình Vườn
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(gardenProvider.errorMessage ?? "Có lỗi khi lưu cây."),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF364534),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 2,
                        ),
                        child: Text(
                          'Xác nhận lưu vào khu vườn',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gardenProvider = Provider.of<GardenProvider>(context);
    final UserGarden? currentGarden = gardenProvider.selectedGarden;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B1C1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Thêm cây vào vườn',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1C1A),
              ),
            ),
            if (currentGarden != null)
              Text(
                "Khu vườn: ${currentGarden.name}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6A756B),
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Khung Chụp / Chọn ảnh
              Text(
                '1. Hình ảnh cây cần nhận diện',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1C1A),
                ),
              ),
              const SizedBox(height: 10),
              _buildImageSelector(),
              const SizedBox(height: 24),

              // Banner Trạng thái AI (Gemini Multimodal / AI Engine)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _hasGeminiKey
                      ? const Color(0xFF364534).withOpacity(0.06)
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hasGeminiKey
                        ? const Color(0xFF364534).withOpacity(0.2)
                        : Colors.amber.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hasGeminiKey ? Icons.auto_awesome : Icons.info_outline,
                      size: 20,
                      color: _hasGeminiKey ? const Color(0xFF364534) : Colors.amber.shade900,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _hasGeminiKey
                            ? "Google Gemini AI sẵn sàng: Phân tích kết hợp cả ảnh & miêu tả nhận dạng."
                            : "Đang dùng AI Engine mặc định. Bật Gemini để đọc ảnh + miêu tả nhận dạng.",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _hasGeminiKey ? const Color(0xFF364534) : Colors.amber.shade900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => GeminiService.showApiKeyDialog(
                        context,
                        onSaved: _checkGeminiKey,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _hasGeminiKey ? "Đổi Key" : "Cài đặt",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _hasGeminiKey ? const Color(0xFF364534) : Colors.amber.shade900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Ghi chú bổ sung hỗ trợ AI nhận dạng
              Row(
                children: [
                  Text(
                    '2. Miêu tả đặc điểm hỗ trợ AI',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1C1A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF364534).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Tùy chọn',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF364534),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Ghi lại các đặc điểm hình thái nổi bật (màu hoa, gân lá, dạng thân leo hay thân gỗ, đốm vân bạc...) để AI nhận diện rõ ràng và chuẩn xác hơn.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF747871), height: 1.4),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _aiHintNotesCtrl,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1B1C1A)),
                decoration: InputDecoration(
                  hintText: 'VD: Lá hình trái tim, viền có vân bạc, cành mọng nước, hoa nhỏ màu trắng, cuống lá dài...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF747871)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE4E2DF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE4E2DF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF364534), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // 3. Nút Quét AI
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleScan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF364534),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusText ?? "Đang phân tích...",
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.document_scanner_outlined, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              'Nhận diện & Thêm vào vườn',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Khung chọn hoặc chụp ảnh
  Widget _buildImageSelector() {
    if (_imageBytes != null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF364534).withOpacity(0.3)),
          color: Colors.white,
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              child: Image.memory(
                _imageBytes!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFF364534)),
                    label: Text("Chụp lại", style: GoogleFonts.inter(color: const Color(0xFF364534), fontWeight: FontWeight.w600)),
                  ),
                  Container(height: 20, width: 1, color: const Color(0xFFE4E2DF)),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18, color: Color(0xFF364534)),
                    label: Text("Chọn ảnh khác", style: GoogleFonts.inter(color: const Color(0xFF364534), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E2DF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF364534).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF364534).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_a_photo_outlined, size: 30, color: Color(0xFF364534)),
          ),
          const SizedBox(height: 14),
          Text(
            "Chụp hoặc chọn ảnh lá cây",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1C1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "AI sẽ nhận diện loài cây và tự động gợi ý lịch chăm sóc",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF747871)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text("Chụp ảnh", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF364534),
                    side: const BorderSide(color: Color(0xFF364534)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text("Thư viện", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF364534),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEcoBadge({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E2DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF364534)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF747871),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1B1C1A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF364534) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF364534) : const Color(0xFFE4E2DF),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF444842),
          ),
        ),
      ),
    );
  }
}
