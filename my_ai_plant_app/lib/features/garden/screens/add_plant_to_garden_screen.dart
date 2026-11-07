import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
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
          SnackBar(
            content: Text(
              "Lỗi khi chọn ảnh: $e",
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Đảm bảo lấy được URL vĩnh viễn trên Cloudinary Cloud
  Future<String?> _ensurePermanentImageUrl(Map<String, dynamic> wikiData) async {
    if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
      return _uploadedImageUrl;
    }
    // Ưu tiên 1: Upload trực tiếp lên Cloudinary Cloud
    if (_imageBytes != null) {
      try {
        final storageUrl = await StorageService.uploadPlantPhoto(
          bytes: _imageBytes!,
          plantName: wikiData['name_vi'] ?? 'plant',
        );
        if (storageUrl != null && storageUrl.isNotEmpty) {
          _uploadedImageUrl = storageUrl;
          return _uploadedImageUrl;
        }
      } catch (e) {
        debugPrint("Lỗi upload lên Cloudinary Cloud: $e");
      }
    }
    // Ưu tiên 2: Upload lên Backend Server cục bộ nếu có
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
        SnackBar(
          content: Text(
            "Vui lòng chụp ảnh hoặc chọn ảnh lá cây trước nhé!",
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFE06C00),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusText = "Đang nhận diện & phân tích cây...";
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

        // Kích hoạt upload ảnh cây lên Cloudinary Cloud ngầm ngay trong lúc người dùng xem thông tin và chọn phòng
        if (_imageBytes != null && (_uploadedImageUrl == null || _uploadedImageUrl!.isEmpty)) {
          StorageService.uploadPlantPhoto(
            bytes: _imageBytes!,
            plantName: nameVi,
          ).then((url) {
            if (url != null && url.isNotEmpty && mounted) {
              _uploadedImageUrl = url;
            }
          }).catchError((_) {});
        }

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
            content: Text(
              "$e".replaceAll("Exception: ", ""),
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
            ),
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

    // Tình trạng sức khỏe ban đầu
    String selectedHealth = 'Khỏe mạnh';

    // Bón phân dinh dưỡng
    bool enableFertilizer = true;
    int fertilizeDays = 20;
    if (wikiData['fertilizer'] != null) {
      final fertText = wikiData['fertilizer'].toString().toLowerCase();
      if (fertText.contains("tháng")) {
        fertilizeDays = 30;
      } else if (fertText.contains("tuần")) {
        final match = RegExp(r'(\d+)').firstMatch(fertText);
        final weeks = int.tryParse(match?.group(1) ?? '2') ?? 2;
        fertilizeDays = weeks * 7;
      }
    }

    // Kiểm tra sâu bệnh & lau lá
    int checkPestDays = 3;

    // Ghi chú chăm sóc riêng
    final TextEditingController noteCtrl = TextEditingController(
      text: _aiHintNotesCtrl.text.trim(),
    );

    // Giờ nhắc mặc định lấy theo khung giờ chuẩn trong màn hình "Nhắc tưới"
    final String morningTime = NotificationService.cachedMorningTime;
    final String eveningTime = NotificationService.cachedEveningTime;
    String reminderTime = morningTime;
    final List<Map<String, String>> presetTimes = [
      {"label": "$morningTime (Sáng)", "time": morningTime},
      if (morningTime != "09:30" && eveningTime != "09:30") {"label": "09:30", "time": "09:30"},
      if (eveningTime != morningTime) {"label": "$eveningTime (Chiều)", "time": eveningTime},
      if (morningTime != "20:00" && eveningTime != "20:00") {"label": "20:00 (Tối)", "time": "20:00"},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = context.colors;
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
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                          color: c.border,
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
                                  color: c.surfaceTint,
                                  child: Icon(Icons.local_florist, color: c.textSecondary, size: 32),
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
                                      color: c.surfaceTint,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      confidence > 0
                                          ? "${context.tr("ĐỘ CHÍNH XÁC:", "ACCURACY:")} ${confidence.toStringAsFixed(1)}%"
                                          : context.tr("KHỚP TỐT NHẤT", "BEST MATCH"),
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: c.primaryText,
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
                                          color: c.textMuted,
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
                                  color: c.textPrimary,
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
                                  color: c.textMuted,
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
                          color: c.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border),
                        ),
                        child: Text(
                          shortDesc,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: c.textSecondary,
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
                            context,
                            icon: Icons.wb_sunny_outlined,
                            title: context.tr("Ánh sáng", "Light"),
                            value: light,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildEcoBadge(
                            context,
                            icon: Icons.water_drop_outlined,
                            title: context.tr("Tưới nước", "Water"),
                            value: waterFreq,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildEcoBadge(
                            context,
                            icon: Icons.spa_outlined,
                            title: context.tr("Chăm sóc", "Care"),
                            value: difficulty,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. Biệt danh cây
                    Text(
                      context.tr("Tên hoặc biệt danh trong vườn", "Name or nickname in garden"),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nicknameCtrl,
                      style: GoogleFonts.inter(fontSize: 14, color: c.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: c.surfaceMuted,
                        prefixIcon: Icon(Icons.loyalty_outlined, size: 18, color: c.textSecondary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Tình trạng sức khỏe ban đầu
                    Text(
                      context.tr("Tình trạng sức khỏe ban đầu", "Initial health status"),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Khỏe mạnh',
                        'Cần chú ý',
                        'Đang phục hồi',
                      ].map((h) {
                        final isSelected = selectedHealth == h;
                        Color chipColor;
                        if (h == 'Khỏe mạnh') {
                          chipColor = const Color(0xFF15803D);
                        } else if (h == 'Cần chú ý') {
                          chipColor = const Color(0xFFD97706);
                        } else {
                          chipColor = const Color(0xFF2563EB);
                        }

                        String trH = h;
                        if (context.isEnglish) {
                          if (h == 'Khỏe mạnh') trH = 'Healthy';
                          else if (h == 'Cần chú ý') trH = 'Needs attention';
                          else if (h == 'Đang phục hồi') trH = 'Recovering';
                        }

                        return ChoiceChip(
                          label: Text(trH),
                          selected: isSelected,
                          checkmarkColor: Colors.white,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedHealth = h);
                          },
                          selectedColor: chipColor,
                          backgroundColor: c.surfaceMuted,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : c.textPrimary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: isSelected ? chipColor : c.border),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // 3. Chỗ đặt cây trong khu vườn
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr("Chỗ đặt cây", "Plant location"),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        if (currentGarden != null)
                          Text(
                            "${context.tr("Vườn:", "Garden:")} ${currentGarden.name} (${currentGarden.environment})",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary,
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
                          String trZone = zone;
                          if (context.isEnglish) {
                            if (zone == 'Phòng khách') trZone = 'Living room';
                            else if (zone == 'Phòng ngủ') trZone = 'Bedroom';
                            else if (zone == 'Cửa sổ') trZone = 'Window';
                            else if (zone == 'Ban công') trZone = 'Balcony';
                            else if (zone == 'Sân thượng') trZone = 'Rooftop';
                            else if (zone == 'Sân trước') trZone = 'Front yard';
                            else if (zone == 'Bàn làm việc') trZone = 'Desk';
                          }
                          return ChoiceChip(
                            label: Text(trZone),
                            selected: isSel,
                            checkmarkColor: Colors.white,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  selectedZone = zone;
                                  isCustomZone = false;
                                });
                              }
                            },
                            selectedColor: c.primary,
                            backgroundColor: c.surfaceMuted,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                              color: isSel ? Colors.white : c.textSecondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSel ? c.primary : c.border,
                              ),
                            ),
                          );
                        }),
                        ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_note_outlined, size: 16, color: isCustomZone ? Colors.white : c.textSecondary),
                              const SizedBox(width: 4),
                              Text(context.tr("Khác...", "Other...")),
                            ],
                          ),
                          selected: isCustomZone,
                          checkmarkColor: Colors.white,
                          onSelected: (val) {
                            setModalState(() {
                              isCustomZone = true;
                            });
                          },
                          selectedColor: c.primary,
                          backgroundColor: c.surfaceMuted,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isCustomZone ? FontWeight.w600 : FontWeight.w500,
                            color: isCustomZone ? Colors.white : c.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isCustomZone ? c.primary : c.border,
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
                        style: GoogleFonts.inter(fontSize: 14, color: c.textPrimary),
                        decoration: InputDecoration(
                          hintText: context.tr('Nhập vị trí đặt cây (VD: Góc làm việc, Bàn ăn, Cạnh TV...)', 'Enter location (e.g., Desk, Dining table, Beside TV...)'),
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
                          filled: true,
                          fillColor: c.surfaceMuted,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: c.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: c.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // 4. Tần suất tưới nước (Theo khuyến nghị từ điển & tùy chỉnh người dùng)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr("Lịch tưới nước", "Watering schedule"),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.surfaceTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${context.tr("Khuyến nghị:", "Recommended:")} $waterFreq",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c.textSecondary,
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
                          context,
                          label: context.tr("1 lần / tuần", "Once / week"),
                          isSelected: timesPerWeek == 1,
                          onTap: () => setModalState(() => timesPerWeek = 1),
                        ),
                        _buildFrequencyChip(
                          context,
                          label: context.tr("2 lần / tuần", "2 times / week"),
                          isSelected: timesPerWeek == 2,
                          onTap: () => setModalState(() => timesPerWeek = 2),
                        ),
                        _buildFrequencyChip(
                          context,
                          label: context.tr("3 lần / tuần", "3 times / week"),
                          isSelected: timesPerWeek == 3,
                          onTap: () => setModalState(() => timesPerWeek = 3),
                        ),
                        _buildFrequencyChip(
                          context,
                          label: context.tr("Hàng ngày (7 lần)", "Daily (7 times)"),
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
                        color: c.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${context.tr("Tùy chỉnh:", "Custom:")} $timesPerWeek ${context.tr("lần/tuần (~mỗi", "times/week (~every")} ${(7 / timesPerWeek).round().clamp(1, 14)} ${context.tr("ngày)", "days)")}",
                              style: GoogleFonts.inter(fontSize: 13, color: c.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline, size: 22, color: c.textSecondary),
                                onPressed: timesPerWeek > 1 ? () => setModalState(() => timesPerWeek--) : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "$timesPerWeek",
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: c.textPrimary),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline, size: 22, color: c.textSecondary),
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

                    // 5. Chu kỳ bón phân dinh dưỡng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr("Yêu cầu bón phân dinh dưỡng:", "Fertilization requirement:"),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: enableFertilizer ? (c.isDark ? const Color(0xFF3E3218) : const Color(0xFFFEF3C7)) : c.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: enableFertilizer ? (c.isDark ? const Color(0xFF5A4820) : const Color(0xFFFDE68A)) : c.border,
                            ),
                          ),
                          child: Text(
                            enableFertilizer
                                ? "${context.tr("Mỗi", "Every")} $fertilizeDays ${context.tr("ngày / lần", "days")}"
                                : context.tr("Không áp dụng", "Not applicable"),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: enableFertilizer ? (c.isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)) : c.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Nhóm Radio Button (Cần bón phân / Không cần bón)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                enableFertilizer = true;
                                if (fertilizeDays <= 0) fertilizeDays = 20;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: enableFertilizer ? (c.isDark ? const Color(0xFF3E3218) : const Color(0xFFFEF3C7)) : c.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: enableFertilizer ? const Color(0xFFF59E0B) : c.border,
                                  width: enableFertilizer ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<bool>(
                                    value: true,
                                    groupValue: enableFertilizer,
                                    activeColor: const Color(0xFFD97706),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (val) {
                                      if (val == true) {
                                        setModalState(() {
                                          enableFertilizer = true;
                                          if (fertilizeDays <= 0) fertilizeDays = 20;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      context.tr("Cần bón phân", "Needs fertilizer"),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: enableFertilizer ? (c.isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E)) : c.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setModalState(() {
                                enableFertilizer = false;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                              decoration: BoxDecoration(
                                color: !enableFertilizer ? (c.isDark ? const Color(0xFF2E332F) : const Color(0xFFF3F4F6)) : c.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: !enableFertilizer ? (c.isDark ? c.primaryText : const Color(0xFF9CA3AF)) : c.border,
                                  width: !enableFertilizer ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Radio<bool>(
                                    value: false,
                                    groupValue: enableFertilizer,
                                    activeColor: c.textSecondary,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (val) {
                                      if (val == false) {
                                        setModalState(() {
                                          enableFertilizer = false;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      context.tr("Không cần bón", "No fertilizer"),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: !enableFertilizer ? c.textPrimary : c.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (enableFertilizer) ...[
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFFF59E0B),
                          inactiveTrackColor: c.surfaceMuted,
                          thumbColor: const Color(0xFFF59E0B),
                          overlayColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          valueIndicatorColor: const Color(0xFF78350F),
                          valueIndicatorTextStyle: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          showValueIndicator: ShowValueIndicator.onDrag,
                        ),
                        child: Slider(
                          value: fertilizeDays.toDouble().clamp(7, 60),
                          min: 7,
                          max: 60,
                          divisions: 53,
                          label: "$fertilizeDays ${context.tr("ngày/lần", "days")}",
                          onChanged: (val) {
                            setModalState(() => fertilizeDays = val.round());
                          },
                        ),
                      ),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 8),
                        child: Text(
                          context.tr(
                            "💡 Loài cây này không yêu cầu phân bón (ví dụ: cây không khí, sen đá giai đoạn nghỉ...). Tác vụ bón phân sẽ được tắt khỏi lịch nhắc việc.",
                            "💡 This plant doesn't require fertilizer (e.g., air plants, dormant succulents). Fertilizing tasks will be disabled.",
                          ),
                          style: GoogleFonts.inter(fontSize: 11.5, color: c.textMuted, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // 6. Chu kỳ kiểm tra sâu bệnh & lau lá
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr("Chu kỳ kiểm tra sâu bệnh & lau lá:", "Pest check & clean frequency:"),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: c.isDark ? const Color(0xFF1E2D40) : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: c.isDark ? const Color(0xFF2A4260) : const Color(0xFFBAE6FD)),
                          ),
                          child: Text(
                            "${context.tr("Mỗi", "Every")} $checkPestDays ${context.tr("ngày / lần", "days")}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: c.isDark ? const Color(0xFF60A5FA) : const Color(0xFF0369A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF0284C7),
                        inactiveTrackColor: c.surfaceMuted,
                        thumbColor: const Color(0xFF0284C7),
                        overlayColor: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        valueIndicatorColor: const Color(0xFF0C4A6E),
                        valueIndicatorTextStyle: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        showValueIndicator: ShowValueIndicator.onDrag,
                      ),
                      child: Slider(
                        value: checkPestDays.toDouble().clamp(1, 14),
                        min: 1,
                        max: 14,
                        divisions: 13,
                        label: "$checkPestDays ${context.tr("ngày/lần", "days")}",
                        onChanged: (val) {
                          setModalState(() => checkPestDays = val.round());
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 7. Khung giờ nhắc nhở tưới cây
                    Text(
                      context.tr("Khung giờ nhắc nhở", "Reminder time"),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
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
                            checkmarkColor: Colors.white,
                            onSelected: (val) {
                              if (val) setModalState(() => reminderTime = item['time']!);
                            },
                            selectedColor: c.primary,
                            backgroundColor: c.surfaceMuted,
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                              color: isSel ? Colors.white : c.textSecondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSel ? c.primary : c.border,
                              ),
                            ),
                          );
                        }),
                        ChoiceChip(
                          label: Text(
                            !presetTimes.any((t) => t['time'] == reminderTime)
                                ? reminderTime
                                : context.tr("Giờ khác...", "Custom time..."),
                          ),
                          selected: !presetTimes.any((t) => t['time'] == reminderTime),
                          checkmarkColor: Colors.white,
                          onSelected: (val) async {
                            final pickedTime = await showTimePicker(
                              context: modalContext,
                              initialTime: const TimeOfDay(hour: 7, minute: 0),
                              builder: (ctx, child) {
                                return Theme(
                                  data: Theme.of(ctx).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: c.primary,
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
                          selectedColor: c.primary,
                          backgroundColor: c.surfaceMuted,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: !presetTimes.any((t) => t['time'] == reminderTime) ? Colors.white : c.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: !presetTimes.any((t) => t['time'] == reminderTime)
                                  ? c.primary
                                  : c.border,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // 8. Ghi chú chăm sóc
                    Text(
                      context.tr("Ghi chú chăm sóc:", "Care notes:"),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      style: GoogleFonts.inter(fontSize: 13, color: c.textPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: c.surfaceMuted,
                        hintText: context.tr("Ví dụ: Đặt cạnh cửa sổ hướng đông, tưới buổi sáng...", "e.g., Near east window, water in morning..."),
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.primary, width: 1.5)),
                      ),
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
                            fertilizeFrequencyDays: enableFertilizer ? fertilizeDays : 0,
                            checkPestFrequencyDays: checkPestDays,
                            healthStatus: selectedHealth,
                            reminderTime: reminderTime,
                            notes: noteCtrl.text.trim(),
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
                                          "${context.tr("Đã thêm", "Added")} '$finalNickname' ${context.tr("vào", "to")} '$finalZone' ${context.tr("thành công!", "successfully!")}",
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            fontSize: 13.5,
                                          ),
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
                                  content: Text(
                                    gardenProvider.errorMessage ?? context.tr("Có lỗi khi lưu cây.", "Error saving plant."),
                                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                                  ),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 2,
                        ),
                        child: Text(
                          context.tr('Xác nhận lưu vào khu vườn', 'Confirm & save to garden'),
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
    final c = context.colors;
    final gardenProvider = Provider.of<GardenProvider>(context);
    final UserGarden? currentGarden = gardenProvider.selectedGarden;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: c.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              context.tr('Thêm cây vào vườn', 'Add plant to garden'),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            if (currentGarden != null)
              Text(
                "${context.tr("Khu vườn:", "Garden:")} ${currentGarden.name}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.textMuted,
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
                context.tr('1. Hình ảnh cây cần nhận diện', '1. Plant photo for identification'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _buildImageSelector(context),
              const SizedBox(height: 24),

              // 2. Ghi chú bổ sung hỗ trợ AI nhận dạng
              Row(
                children: [
                  Text(
                    context.tr('2. Miêu tả đặc điểm hỗ trợ AI', '2. Plant traits to assist AI'),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.surfaceTint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.tr('Tùy chọn', 'Optional'),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: c.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'Ghi lại các đặc điểm hình thái nổi bật (màu hoa, gân lá, dạng thân leo hay thân gỗ, đốm vân bạc...) để AI nhận diện rõ ràng và chuẩn xác hơn.',
                  'Note distinctive features (flower color, leaf veins, climbing or woody stem, silver patterns...) for more accurate AI identification.',
                ),
                style: GoogleFonts.inter(fontSize: 12, color: c.textMuted, height: 1.4),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _aiHintNotesCtrl,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 14, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: context.tr(
                    'VD: Lá hình trái tim, viền có vân bạc, cành mọng nước, hoa nhỏ màu trắng, cuống lá dài...',
                    'e.g., Heart-shaped leaves, silver variegated edges, succulent stems, small white flowers...',
                  ),
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
                  filled: true,
                  fillColor: c.surfaceMuted,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.primary, width: 1.5),
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
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: c.primary.withValues(alpha: 0.7),
                    disabledForegroundColor: Colors.white,
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
                                _statusText ?? context.tr("Đang nhận diện & phân tích cây...", "Identifying & analyzing plant..."),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.document_scanner_outlined, size: 22, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              context.tr('Nhận diện & Thêm vào vườn', 'Identify & Add to garden'),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
  Widget _buildImageSelector(BuildContext context) {
    final c = context.colors;
    if (_imageBytes != null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
          color: c.surface,
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
                    icon: Icon(Icons.camera_alt_outlined, size: 18, color: c.primaryText),
                    label: Text(context.tr("Chụp lại", "Retake"), style: GoogleFonts.inter(color: c.primaryText, fontWeight: FontWeight.w600)),
                  ),
                  Container(height: 20, width: 1, color: c.border),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library_outlined, size: 18, color: c.primaryText),
                    label: Text(context.tr("Chọn ảnh khác", "Change photo"), style: GoogleFonts.inter(color: c.primaryText, fontWeight: FontWeight.w600)),
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
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: c.isDark ? 0.2 : 0.03),
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
              color: c.surfaceTint,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_a_photo_outlined, size: 30, color: c.textSecondary),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr("Chụp hoặc chọn ảnh lá cây", "Take or select plant photo"),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr("AI sẽ nhận diện loài cây và tự động gợi ý lịch chăm sóc", "AI will identify the plant and suggest care routines"),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 12, color: c.textMuted),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text(context.tr("Chụp ảnh", "Camera"), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textPrimary,
                    side: BorderSide(color: c.border),
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
                  label: Text(context.tr("Thư viện", "Gallery"), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
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

  Widget _buildEcoBadge(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: c.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: c.textMuted,
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
              color: c.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? c.primary : c.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? c.primary : c.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : c.textSecondary,
          ),
        ),
      ),
    );
  }
}
