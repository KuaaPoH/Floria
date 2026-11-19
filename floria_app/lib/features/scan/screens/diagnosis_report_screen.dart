import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/scan_provider.dart';
import '../../home/screens/main_navigation_screen.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_toast.dart';
import 'plant_wiki_screen.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import '../../garden/providers/garden_provider.dart';
import '../../garden/models/garden_plant.dart';
import '../../garden/models/user_garden.dart';
import '../../garden/screens/create_garden_screen.dart';
import '../../chatbot/screens/ai_assistant_screen.dart';
import '../models/disease_info.dart';
import '../services/disease_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';

class DiagnosisReportScreen extends StatefulWidget {
  final bool isDiseaseScan;
  final GardenPlant? currentPlant;

  const DiagnosisReportScreen({
    super.key,
    this.isDiseaseScan = false,
    this.currentPlant,
  });

  @override
  State<DiagnosisReportScreen> createState() => _DiagnosisReportScreenState();
}

class _DiagnosisReportScreenState extends State<DiagnosisReportScreen> {
  final int _selectedResultIndex = 0;
  Future<Map<String, dynamic>?>? _plantDataFuture;
  String? _currentDocId;
  OverlayEntry? _topNotificationEntry;
  String? _uploadedGardenImageUrl;
  Uint8List? _uploadedGardenImageBytes;

  @override
  void dispose() {
    _topNotificationEntry?.remove();
    _topNotificationEntry = null;
    super.dispose();
  }

  // Lấy dữ liệu cây trồng 100% động từ đám mây (Firestore & Spring Boot Backend Gateway)
  Future<Map<String, dynamic>?> _fetchPlantData(
    String docId,
    ScanProvider scanProvider,
  ) async {
    if (docId.isEmpty) return null;
    String queryId = docId.replaceAll('_', ' ').trim();

    // 1. Kiểm tra trong plants_map đính kèm sẵn từ Backend
    if (scanProvider.scanResult != null &&
        scanProvider.scanResult!['plants_map'] != null) {
      final pMap = scanProvider.scanResult!['plants_map'];
      if (pMap is Map && pMap[queryId] != null) {
        return Map<String, dynamic>.from(pMap[queryId]);
      }
    }

    // 2. Nếu Backend Spring Boot đính kèm plant_details và trùng khớp với queryId đang tìm
    if (scanProvider.scanResult != null &&
        scanProvider.scanResult!['plant_details'] != null) {
      final details = scanProvider.scanResult!['plant_details'];
      if (details is Map) {
        String? plantSci = details['scientific_name']
            ?.toString()
            .replaceAll('_', ' ')
            .trim()
            .toLowerCase();
        String? plantPred = scanProvider.scanResult!['prediction']
            ?.toString()
            .replaceAll('_', ' ')
            .trim()
            .toLowerCase();
        if (queryId.toLowerCase() == plantSci ||
            queryId.toLowerCase() == plantPred) {
          return Map<String, dynamic>.from(details);
        }
      }
    }

    // 3. Thử truy vấn trực tiếp Firestore client cho đúng cây queryId
    try {
      final doc = await FirebaseFirestore.instance
          .collection('plants_info')
          .doc(queryId)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (e) {
      debugPrint("Lỗi đọc Firestore client trực tiếp cho $queryId: $e");
    }

    // 4. Fallback qua Spring Boot Gateway (Admin SDK đọc Firestore không bị chặn Security Rules)
    try {
      final dio = Dio();
      final res = await dio.get("${AppConstants.baseUrl}/plants/$queryId");
      if (res.statusCode == 200 && res.data is Map) {
        return Map<String, dynamic>.from(res.data);
      }
    } catch (e) {
      debugPrint("Lỗi đọc cây qua Backend Gateway: $e");
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);

    // Parse result from provider
    String mainTitle = "Đang phân tích...";
    double confidence = 0.0;
    bool isValidPlant = true;
    String message = "";

    List<dynamic> top3 = [];
    if (scanProvider.scanResult != null) {
      if (scanProvider.scanResult!['top_predictions'] != null) {
        top3 = scanProvider.scanResult!['top_predictions'];
      } else if (scanProvider.scanResult!['top_3'] != null) {
        top3 = scanProvider.scanResult!['top_3'];
      }
    }

    if (widget.isDiseaseScan && scanProvider.scanResult != null) {
      if (scanProvider.scanResult!['prediction_vi'] != null) {
        mainTitle = scanProvider.scanResult!['prediction_vi'].toString();
      } else if (scanProvider.scanResult!['prediction'] != null) {
        mainTitle = scanProvider.scanResult!['prediction']
            .toString()
            .replaceAll('_', ' ');
      }
      if (scanProvider.scanResult!['confidence'] != null) {
        confidence =
            double.tryParse(
              scanProvider.scanResult!['confidence'].toString(),
            ) ??
            95.0;
      }
    } else if (top3.isNotEmpty && _selectedResultIndex < top3.length) {
      var item = top3[_selectedResultIndex];
      if (item is Map && item['name_vi'] != null) {
        mainTitle = item['name_vi'].toString();
      } else {
        mainTitle = item['class'].toString();
        if (mainTitle.contains('___')) {
          mainTitle = mainTitle.split('___').last;
        }
        mainTitle = mainTitle.replaceAll('_', ' ');
      }
      confidence = double.tryParse(item['confidence'].toString()) ?? 0.0;
    } else if (scanProvider.scanResult != null &&
        scanProvider.scanResult!['prediction'] != null) {
      mainTitle = scanProvider.scanResult!['prediction'].toString();
      if (mainTitle.contains('___')) {
        mainTitle = mainTitle.split('___').last;
      }
      mainTitle = mainTitle.replaceAll('_', ' ');
      if (scanProvider.scanResult!['confidence'] != null) {
        confidence =
            double.tryParse(
              scanProvider.scanResult!['confidence'].toString(),
            ) ??
            95.0;
      }
    }

    if (scanProvider.scanResult != null) {
      if (scanProvider.scanResult!['is_valid_plant'] != null) {
        isValidPlant = scanProvider.scanResult!['is_valid_plant'] == true;
      }
      if (scanProvider.scanResult!['message'] != null) {
        message = scanProvider.scanResult!['message'].toString();
      }
    }

    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          // Ambient Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c.background, c.surface, c.background],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, confidence, scanProvider.isLoading),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (scanProvider.errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.cloud_off_rounded,
                                      color: Colors.red,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        context.tr(
                                          "Lỗi kết nối máy chủ",
                                          "Server Connection Error",
                                        ),
                                        style: GoogleFonts.inter(
                                          color: Colors.red.shade900,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  scanProvider.errorMessage!,
                                  style: GoogleFonts.inter(
                                    color: Colors.red.shade800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: c.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: const Icon(Icons.arrow_back, size: 16),
                                  label: Text(
                                    context.tr("Quay lại kiểm tra", "Back"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!isValidPlant && scanProvider.errorMessage == null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    message.isNotEmpty
                                        ? message
                                        : context.tr(
                                            "Hệ thống phát hiện ảnh không phải thực vật hoặc quá mờ.",
                                            "System detected image is not a plant or is too blurry.",
                                          ),
                                    style: GoogleFonts.inter(
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildContentBlock(scanProvider, mainTitle, confidence),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBlock(
    ScanProvider scanProvider,
    String mainTitle,
    double confidence,
  ) {
    final c = context.colors;
    List<dynamic> top3 = [];
    if (scanProvider.scanResult != null) {
      if (scanProvider.scanResult!['top_predictions'] != null) {
        top3 = scanProvider.scanResult!['top_predictions'];
      } else if (scanProvider.scanResult!['top_3'] != null) {
        top3 = scanProvider.scanResult!['top_3'];
      }
    }
    String docId = "";
    if (top3.isNotEmpty && _selectedResultIndex < top3.length) {
      docId = top3[_selectedResultIndex]['class'].toString();
      if (docId.contains('___')) {
        docId = docId.split('___').last;
      }
    } else if (scanProvider.scanResult != null &&
        scanProvider.scanResult!['prediction'] != null) {
      String pred = scanProvider.scanResult!['prediction'].toString();
      if (pred != "Không hợp lệ" && pred != "Không phải cây") {
        docId = pred.contains('___') ? pred.split('___').last : pred;
      }
    }

    if (scanProvider.isLoading) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Column(
          key: const ValueKey('loading'),
          children: [
            _buildHeroCard(scanProvider, mainTitle, null, confidence),
            const SizedBox(height: 16),
            _buildResultStackSkeleton(),
            const SizedBox(height: 16),
            _buildSkeletonCard(),
            const SizedBox(height: 16),
            _buildSkeletonCard(),
            const SizedBox(height: 16),
            _buildActionPills(context, scanProvider, docId, null),
          ],
        ),
      );
    }

    // Nhánh chuyên trách cho Quét bệnh lá cây (Disease Scan)
    if (widget.isDiseaseScan) {
      if (scanProvider.errorMessage != null) {
        return Column(
          children: [
            _buildHeroCard(scanProvider, mainTitle, null, confidence),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 44,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr("Lỗi phân tích bệnh lá", "Leaf Diagnosis Error"),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    scanProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(
                      context.tr("Quay lại", "Back"),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      return Column(
        children: [
          _buildHeroCard(scanProvider, mainTitle, null, confidence),
          const SizedBox(height: 16),
          _buildDiseasePathologyCard(scanProvider),
          const SizedBox(height: 16),
          _buildActionPills(context, scanProvider, docId, null),
        ],
      );
    }

    if (scanProvider.errorMessage != null || docId.isEmpty) {
      return Column(
        children: [
          _buildHeroCard(scanProvider, mainTitle, null, confidence),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.primary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  scanProvider.errorMessage != null
                      ? Icons.wifi_off_rounded
                      : Icons.spa_outlined,
                  size: 44,
                  color: c.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  scanProvider.errorMessage != null
                      ? context.tr(
                          "Không thể nhận kết quả từ máy chủ",
                          "Could not get results from server",
                        )
                      : context.tr(
                          "Không thể nhận diện rõ loại cây này",
                          "Could not identify this plant",
                        ),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scanProvider.errorMessage != null
                      ? context.tr(
                          "Vui lòng kiểm tra kết nối tới Backend Spring Boot trên cổng 8080.",
                          "Please check connection to Backend Spring Boot on port 8080.",
                        )
                      : context.tr(
                          "Hãy chụp ảnh lại gần hơn, đầy đủ ánh sáng và lấy nét trực diện vào lá cây.",
                          "Please retake photo closer, with good lighting and focused on the leaf.",
                        ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: c.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text(
                    context.tr("Chụp lại ảnh khác", "Retake another photo"),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildActionPills(context, scanProvider, docId, null),
        ],
      );
    }

    if (_currentDocId != docId) {
      _currentDocId = docId;
      _plantDataFuture = docId.isNotEmpty
          ? _fetchPlantData(docId, scanProvider)
          : Future.value(null);
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _plantDataFuture,
      builder: (context, snapshot) {
        Map<String, dynamic>? plantData = snapshot.data;

        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting &&
            plantData == null) {
          child = Column(
            key: const ValueKey('waiting'),
            children: [
              _buildHeroCard(scanProvider, mainTitle, null, confidence),
              const SizedBox(height: 16),
              _buildSkeletonCard(),
              const SizedBox(height: 16),
              _buildSkeletonCard(),
              const SizedBox(height: 16),
              _buildActionPills(context, scanProvider, docId, null),
            ],
          );
        } else {
          child = Column(
            key: ValueKey(docId),
            children: [
              _buildHeroCard(scanProvider, mainTitle, plantData, confidence),
              const SizedBox(height: 16),
              _buildInfoCard(docId, plantData),
              const SizedBox(height: 16),
              _buildCareCard(plantData),
              const SizedBox(height: 16),
              _buildActionPills(context, scanProvider, docId, plantData),
            ],
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: child,
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, double confidence, bool isLoading) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: c.textPrimary,
                  size: 20,
                ),
                onPressed: () {
                  Provider.of<ScanProvider>(context, listen: false).reset();
                  Navigator.pop(context);
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isDiseaseScan
                        ? context.tr("CHẨN ĐOÁN BỆNH", "DISEASE DIAGNOSIS")
                        : context.tr(
                            "KẾT QUẢ NHẬN DIỆN",
                            "IDENTIFICATION RESULT",
                          ),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: c.textMuted,
                    ),
                  ),
                  Text(
                    context.tr("Kết quả quét", "Scan Results"),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    isLoading ? "--%" : "${confidence.toInt()}%",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: widget.isDiseaseScan
                          ? const Color(0xFFDC2626)
                          : c.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
    ScanProvider provider,
    String title,
    Map<String, dynamic>? data,
    double confidence,
  ) {
    final c = context.colors;
    String displayName = title;
    if (widget.isDiseaseScan &&
        provider.scanResult != null &&
        provider.scanResult!['prediction_vi'] != null) {
      displayName = provider.scanResult!['prediction_vi'].toString();
    } else if (data != null &&
        data['name_vi'] != null &&
        data['name_vi'].toString().isNotEmpty) {
      displayName = data['name_vi'].toString();
    } else if (provider.scanResult != null &&
        provider.scanResult!['top_3'] != null) {
      List<dynamic> t3 = provider.scanResult!['top_3'];
      if (_selectedResultIndex < t3.length &&
          t3[_selectedResultIndex] is Map &&
          t3[_selectedResultIndex]['name_vi'] != null) {
        displayName = t3[_selectedResultIndex]['name_vi'].toString();
      } else if (provider.isLoading || data == null) {
        displayName = context.tr("Đang tra cứu...", "Looking up...");
      }
    } else if (provider.isLoading || data == null) {
      displayName = context.tr("Đang tra cứu...", "Looking up...");
    }

    final bool isHealthy =
        widget.isDiseaseScan &&
        provider.scanResult != null &&
        provider.scanResult!['prediction']?.toString().toLowerCase() ==
            'healthy';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: c.surface,
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scanned Image
          Container(
            width: 120,
            height: 154,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: c.surfaceMuted,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: provider.webImageBytes != null
                      ? Image.memory(provider.webImageBytes!, fit: BoxFit.cover)
                      : const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: Colors.black.withValues(alpha: 0.35),
                        alignment: Alignment.center,
                        child: Text(
                          context.tr("Ảnh vừa quét", "Scanned photo"),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Short Summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.isDiseaseScan
                        ? (isHealthy
                              ? c.primary.withValues(alpha: 0.15)
                              : const Color(0xFFDC2626).withValues(alpha: 0.15))
                        : c.surfaceTint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isDiseaseScan
                            ? (isHealthy
                                  ? Icons.verified_rounded
                                  : Icons.coronavirus)
                            : Icons.auto_awesome,
                        color: widget.isDiseaseScan
                            ? (isHealthy ? c.primary : const Color(0xFFDC2626))
                            : c.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        provider.isLoading
                            ? context.tr("Đang xử lý...", "Processing...")
                            : widget.isDiseaseScan
                            ? (provider.scanResult?['severity_vi']
                                      ?.toString() ??
                                  (isHealthy
                                      ? context.tr("Khỏe mạnh", "Healthy")
                                      : context.tr(
                                          "Cảnh báo bệnh",
                                          "Disease Warning",
                                        )))
                            : (_selectedResultIndex == 0
                                  ? context.tr("Khớp tốt nhất", "Best match")
                                  : (_selectedResultIndex == 1
                                        ? context.tr("Gần giống", "Similar")
                                        : context.tr(
                                            "Ít khả năng",
                                            "Low match",
                                          ))),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.isDiseaseScan
                              ? (isHealthy
                                    ? c.primary
                                    : const Color(0xFFDC2626))
                              : c.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (widget.isDiseaseScan) ...[
                      if (widget.currentPlant != null)
                        _buildTag(
                          widget.currentPlant!.nameVi,
                          color: c.surfaceTint,
                          textColor: c.primary,
                        ),
                      _buildTag(
                        provider.scanResult?['severity_vi']?.toString() ??
                            (isHealthy
                                ? context.tr("An toàn", "Safe")
                                : context.tr("Cần xử lý", "Needs Care")),
                        color: isHealthy
                            ? c.surfaceTint
                            : const Color(0xFFDC2626).withValues(alpha: 0.15),
                        textColor: isHealthy
                            ? c.primary
                            : const Color(0xFFDC2626),
                      ),
                    ],
                    if (!widget.isDiseaseScan &&
                        data != null &&
                        data['placements'] != null)
                      ...((data['placements'] as List<dynamic>).map(
                        (e) => _buildTag(e.toString()),
                      )),
                    if (!widget.isDiseaseScan && data == null)
                      _buildTag(
                        provider.isLoading
                            ? context.tr("Đang tra cứu...", "Looking up...")
                            : context.tr("Cây cảnh", "Plant"),
                      ),
                  ],
                ),
                if (!provider.isLoading) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.isDiseaseScan
                        ? (provider.scanResult?['is_in_database'] == false
                              ? context.tr("Đang cập nhật...", "Updating...")
                              : (provider.scanResult?['cause']?.toString() ??
                                    (isHealthy
                                        ? context.tr(
                                            "Cây không có dấu hiệu nhiễm bệnh.",
                                            "Plant has no signs of infection.",
                                          )
                                        : context.tr(
                                            "Cây có dấu hiệu nhiễm mầm bệnh. Cần xử lý sớm để tránh lây lan.",
                                            "Plant shows signs of infection. Early treatment recommended.",
                                          ))))
                        : (data != null && data['short_desc'] != null
                              ? data['short_desc']
                              : ""),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: c.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, {Color? color, Color? textColor}) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? c.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: textColor ?? c.textSecondary,
        ),
      ),
    );
  }

  // --- THẺ KHUNG XƯƠNG (SKELETON) KHI ĐANG TẢI ---
  Widget _buildSkeletonCard() {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              margin: const EdgeInsets.only(bottom: 8),
            ),
            Container(
              width: 160,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              margin: const EdgeInsets.only(bottom: 24),
            ),

            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 12),
            ),
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 12),
            ),
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- THẺ KHUNG XƯƠNG CHO ĐỘ TƯƠNG ĐỒNG KHI ĐANG QUÉT ---
  Widget _buildResultStackSkeleton() {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      margin: const EdgeInsets.only(bottom: 6),
                    ),
                    Container(
                      width: 130,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 80,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.only(bottom: 12),
            ),
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String mainTitle, Map<String, dynamic>? data) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: c.surface,
        border: Border.all(color: c.border),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 20)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr("HỒ SƠ CÂY", "PLANT PROFILE"),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: c.textMuted,
                    ),
                  ),
                  Text(
                    context.tr("Thông tin cơ bản", "Basic Info"),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: c.surfaceTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data != null
                      ? (data['plant_type'] ?? context.tr("Thực vật", "Flora"))
                      : context.tr("Dễ chăm", "Easy care"),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: c.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildInfoCell(
                    context.tr("Tên tiếng Việt", "Vietnamese Name"),
                    data?['name_vi'] ??
                        Provider.of<ScanProvider>(
                          context,
                          listen: false,
                        ).scanResult?['name_vi']?.toString() ??
                        context.tr("Đang cập nhật...", "Updating..."),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCell(
                    context.tr("Tên quốc tế", "Scientific Name"),
                    data?['scientific_name'] ?? mainTitle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildInfoCell(
                    context.tr("Họ thực vật", "Family"),
                    data?['family'] ??
                        context.tr("Đang cập nhật...", "Updating..."),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCell(
                    context.tr("Nguồn gốc", "Origin"),
                    data?['origin'] ??
                        context.tr("Đang cập nhật...", "Updating..."),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCell(
            context.tr("Độ khó chăm", "Care Level"),
            data?['difficulty'] ??
                context.tr("Đang cập nhật...", "Updating..."),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseasePathologyCard(ScanProvider scanProvider) {
    final c = context.colors;
    final result = scanProvider.scanResult;
    final String prediction = result?['prediction']?.toString() ?? "Healthy";
    final String predictionVi =
        result?['prediction_vi']?.toString() ?? "Lá khỏe mạnh";
    final bool isHealthy = prediction.toLowerCase() == 'healthy';

    return FutureBuilder<DiseaseInfo?>(
      future: DiseaseService.getDiseaseById(prediction),
      builder: (context, snapshot) {
        final disease = snapshot.data;
        final bool isOutside5Diseases = result?['is_in_database'] == false;
        final String updatingText = context.tr("Đang cập nhật...", "Updating...");

        final String severity = isOutside5Diseases
            ? updatingText
            : (disease?.severity ??
                  result?['severity_vi']?.toString() ??
                  result?['severity']?.toString() ??
                  (isHealthy
                      ? context.tr("Khỏe mạnh", "Healthy")
                      : context.tr("Cảnh báo", "Warning")));

        final Color badgeColor = isOutside5Diseases
            ? const Color(0xFFB08F63)
            : (isHealthy
                  ? c.primary
                  : (severity.contains("Nguy hiểm")
                        ? const Color(0xFFDC2626)
                        : (severity.contains("Trung bình") ||
                                  severity.contains("Cảnh báo")
                              ? const Color(0xFFB08F63)
                              : c.primary)));

        final String pathogen = isOutside5Diseases
            ? updatingText
            : (disease?.pathogen ??
                  result?['pathogen']?.toString() ??
                  result?['cause']?.toString() ??
                  (isHealthy
                      ? context.tr(
                          "Tự nhiên, không phát hiện vi nấm hay vi khuẩn gây hại.",
                          "Natural, no harmful fungus or bacteria detected.",
                        )
                      : context.tr(
                          "Đang cập nhật tác nhân...",
                          "Updating pathogen...",
                        )));
        final String mechanism = isOutside5Diseases
            ? updatingText
            : (disease?.mechanism ??
                  result?['mechanism']?.toString() ??
                  (isHealthy
                      ? context.tr(
                          "Mô biểu bì nguyên vẹn, các lục lạp quang hợp bình thường.",
                          "Intact epidermis, normal chloroplast photosynthesis.",
                        )
                      : context.tr(
                          "Mầm bệnh tấn công làm suy giảm diệp lục lá.",
                          "Pathogen attacks reducing leaf chlorophyll.",
                        )));
        final String favorableConditions = isOutside5Diseases
            ? updatingText
            : (disease?.favorableConditions ??
                  result?['favorable_conditions']?.toString() ??
                  (isHealthy
                      ? context.tr(
                          "Ánh sáng tán xạ, thông thoáng, chu kỳ ẩm ổn định.",
                          "Scattered light, good ventilation, stable moisture.",
                        )
                      : context.tr(
                          "Ẩm độ cao, kém thông thoáng, đọng nước trên mặt lá.",
                          "High humidity, poor ventilation, standing water on leaves.",
                        )));
        final String prevention = isOutside5Diseases
            ? updatingText
            : (disease?.prevention ??
                  result?['prevention']?.toString() ??
                  (isHealthy
                      ? context.tr(
                          "Tiếp tục duy trì chế độ chăm sóc và vị trí hiện tại.",
                          "Continue regular care and current placement.",
                  )
                : context.tr(
                    "Giữ thông thoáng, cách ly và hạn chế tưới ướt sũng lá.",
                    "Ensure ventilation, isolate and avoid soaking leaves.",
                  )));

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: c.surface,
            border: Border.all(color: c.border),
            boxShadow: [BoxShadow(color: c.shadow, blurRadius: 20)],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            "HỒ SƠ BỆNH HỌC & CƠ CHẾ",
                            "PATHOLOGY & MECHANISM",
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: c.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          predictionVi,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      severity,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildInfoCell(
                        context.tr("Tình trạng", "Status"),
                        isHealthy
                            ? context.tr("Lá bình thường", "Normal Leaf")
                            : context.tr("Nhiễm bệnh", "Infected"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCell(
                        context.tr("Mức độ nguy hại", "Severity"),
                        severity,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoCell(
                context.tr("Tác nhân gây bệnh (Pathogen)", "Pathogen"),
                pathogen,
              ),
              const SizedBox(height: 12),
              _buildInfoCell(
                context.tr(
                  "Cơ chế gây hại biểu mô lá",
                  "Leaf Damage Mechanism",
                ),
                mechanism,
              ),
              const SizedBox(height: 12),
              _buildInfoCell(
                context.tr("Môi trường bùng phát bệnh", "Favorable Conditions"),
                favorableConditions,
              ),
              const SizedBox(height: 12),
              _buildInfoCell(
                context.tr(
                  "Phòng ngừa canh tác & Cách ly",
                  "Prevention & Quarantine",
                ),
                prevention,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCareCard(Map<String, dynamic>? data) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: c.surface,
        border: Border.all(color: c.border),
        boxShadow: [BoxShadow(color: c.shadow, blurRadius: 20)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr("ĐỀ XUẤT CHĂM CÂY", "CARE SUGGESTIONS"),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: c.textMuted,
                ),
              ),
              Text(
                context.tr("Môi trường phù hợp", "Suitable Environment"),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildCareTile(
                    context.tr("Ánh sáng", "Light"),
                    data?['light'] ??
                        context.tr("Đang cập nhật...", "Updating..."),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCareTile(
                    context.tr("Tưới nước", "Water"),
                    data?['water_frequency'] ??
                        context.tr("Đang cập nhật...", "Updating..."),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildCareTile(
                    context.tr("Độ ẩm", "Humidity"),
                    data?['humidity'] ??
                        context.tr("Đang cập nhật...", "Updating..."),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCareTile(
                    context.tr("Nhiệt độ", "Temperature"),
                    data?['temperature'] ??
                        context.tr("Đang cập nhật...", "Updating..."),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCell(String label, String value) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 0.8,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareTile(String kicker, String main) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 0.8,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            main,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: c.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionPills(
    BuildContext context,
    ScanProvider scanProvider,
    String docId,
    Map<String, dynamic>? data,
  ) {
    final c = context.colors;
    if (widget.isDiseaseScan) {
      final result = scanProvider.scanResult;
      final String predictionVi =
          result?['prediction_vi']?.toString() ?? "Bệnh lá";
      final bool isHealthy =
          result?['prediction']?.toString().toLowerCase() == 'healthy';
      final String severityVi =
          result?['severity_vi']?.toString() ??
          result?['severity']?.toString() ??
          (isHealthy ? "Khỏe mạnh" : "Cần chú ý");
      final String cause = result?['cause']?.toString() ?? "";
      final double confidence =
          double.tryParse(result?['confidence']?.toString() ?? '95') ?? 95.0;

      return Column(
        children: [
          Row(
            children: [
              if (widget.currentPlant != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final gardenProvider = Provider.of<GardenProvider>(
                        context,
                        listen: false,
                      );
                      final String newStatus = isHealthy
                          ? 'Khỏe mạnh'
                          : 'Bị $predictionVi';
                      final String newNotes =
                          'Chẩn đoán Trợ lý Floria ngày ${DateTime.now().day}/${DateTime.now().month}: $predictionVi (Độ tin cậy: ${confidence.toStringAsFixed(1)}%)';
                      final bool success = await gardenProvider.updatePlantInfo(
                        widget.currentPlant!.id,
                        nickname: widget.currentPlant!.nickname,
                        zone: widget.currentPlant!.zone,
                        waterFrequencyDays:
                            widget.currentPlant!.waterFrequencyDays,
                        reminderTime: widget.currentPlant!.reminderTime,
                        healthStatus: newStatus,
                        notes: newNotes,
                      );

                      if (success) {
                        unawaited(
                          gardenProvider.addDiaryEntry(
                            plantId: widget.currentPlant!.id,
                            type: 'system',
                            category: 'health',
                            title: isHealthy
                                ? 'Kiểm tra sức khỏe: Khỏe mạnh'
                                : 'Chẩn đoán bệnh: $predictionVi',
                            content: isHealthy
                                ? 'Trợ lý Floria kiểm tra phiến lá không phát hiện mầm bệnh. Cây đạt độ tin cậy ${confidence.toStringAsFixed(1)}%.'
                                : 'Trợ lý Floria chẩn đoán phát hiện [$predictionVi] (Mức độ: $severityVi, Độ tin cậy: ${confidence.toStringAsFixed(1)}%).${cause.isNotEmpty ? '\nNguyên nhân: $cause' : ''}',
                            imageUrl: result?['image_url']?.toString(),
                            tag: isHealthy ? '🌿 Khỏe mạnh' : '🩺 Bệnh án lá',
                            tagBgColor: isHealthy ? 0xFFDCFCE7 : 0xFFFEE2E2,
                            tagTextColor: isHealthy ? 0xFF166534 : 0xFF991B1B,
                          ),
                        );
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: success
                                ? c.primary
                                : const Color(0xFF7F1D1D),
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            content: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    success
                                        ? Icons.check_circle_rounded
                                        : Icons.error_outline_rounded,
                                    color: success
                                        ? const Color(0xFF4ADE80)
                                        : const Color(0xFFF87171),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    success
                                        ? "${context.tr("Đã cập nhật tình trạng", "Updated status")} [$newStatus] ${context.tr("& lưu vào nhật ký cây!", "& saved to plant diary!")}"
                                        : context.tr(
                                            "Chưa thể cập nhật bệnh án vào cây.",
                                            "Could not update plant medical record.",
                                          ),
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHealthy
                          ? c.primary
                          : const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor:
                          (isHealthy ? c.primary : const Color(0xFFDC2626))
                              .withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.healing, size: 18),
                    label: Text(
                      context.tr("Cập nhật bệnh án", "Update Record"),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (widget.currentPlant != null) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final plantName =
                        widget.currentPlant?.nameVi ?? "Cây trồng";
                    final sciName = widget.currentPlant?.scientificName;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiAssistantScreen(
                          plantNameVi: plantName,
                          scientificName: sciName,
                          diseaseContext:
                              "Cây $plantName đang được chẩn đoán mắc [$predictionVi] (mức độ: $severityVi). Nguyên nhân: $cause. Hãy hướng dẫn tôi cách cứu chữa chi tiết!",
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: const Color(0xFFFFD700),
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: Color(0xFFFFD700),
                  ),
                  label: Text(
                    context.tr("Hỏi Trợ lý Floria", "Ask Floria AI"),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Provider.of<ScanProvider>(context, listen: false).reset();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: c.surface,
                    foregroundColor: c.textPrimary,
                    side: BorderSide(color: c.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    context.tr("Chụp lại lá", "Retake Leaf"),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Provider.of<ScanProvider>(context, listen: false).reset();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: c.surface,
                    foregroundColor: c.textPrimary,
                    side: BorderSide(color: c.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    context.tr("Quay lại cây", "Back to Plant"),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReportButton(
            context,
            scanProvider,
            result?['prediction']?.toString() ?? '',
            null,
            highlight: confidence < 50.0 || result?['is_in_database'] == false,
          ),
        ],
      );
    }

    final bool canShowPlantActions =
        scanProvider.errorMessage == null &&
        docId.isNotEmpty &&
        scanProvider.scanResult?['is_valid_plant'] != false;

    return Column(
      children: [
        if (canShowPlantActions) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _showAddToGardenModal(context, scanProvider, docId, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: c.primary.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    context.tr("Lưu vào vườn", "Save to Garden"),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlantWikiScreen(
                          docId: docId,
                          data: data ?? {},
                          imagePath: scanProvider.selectedImage?.path,
                          webImageBytes: scanProvider.webImageBytes,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.surfaceTint,
                    foregroundColor: c.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    context.tr("Chi tiết", "Details"),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final plantName =
                    data?['name_vi'] ?? docId.replaceAll('_', ' ');
                final sciName =
                    data?['scientific_name'] ?? docId.replaceAll('_', ' ');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AiAssistantScreen(
                      plantNameVi: plantName,
                      scientificName: sciName,
                      diseaseContext:
                          "Tôi vừa nhận diện được cây $plantName ($sciName). Hãy hướng dẫn tôi cách chăm sóc, lượng nước tưới, vị trí đặt phù hợp và những lưu ý quan trọng để cây luôn khỏe mạnh!",
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: const Color(0xFFFFD700),
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: Color(0xFFFFD700),
              ),
              label: Text(
                context.tr(
                  "Hỏi Trợ lý Floria về cây này",
                  "Ask Floria AI about this plant",
                ),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            if (canShowPlantActions) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Provider.of<ScanProvider>(context, listen: false).reset();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: c.surface,
                    foregroundColor: c.textPrimary,
                    side: BorderSide(color: c.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    context.tr("Quét lại", "Scan Again"),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Provider.of<ScanProvider>(context, listen: false).reset();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: c.surface,
                  foregroundColor: c.textPrimary,
                  side: BorderSide(color: c.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  context.tr("Trang chủ", "Home"),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildReportButton(
          context,
          scanProvider,
          docId,
          data,
          highlight: data == null || !canShowPlantActions,
        ),
      ],
    );
  }

  Widget _buildReportButton(
    BuildContext context,
    ScanProvider scanProvider,
    String docId,
    Map<String, dynamic>? data, {
    required bool highlight,
  }) {
    final c = context.colors;
    final String label = widget.isDiseaseScan
        ? (highlight
              ? context.tr(
                  "Báo cáo / Yêu cầu cập nhật bệnh mới",
                  "Report / Request new disease update",
                )
              : context.tr(
                  "Báo lỗi chẩn đoán / Đề xuất cập nhật",
                  "Report diagnosis issue / Suggest update",
                ))
        : (highlight
              ? context.tr(
                  "Báo cáo / Yêu cầu cập nhật loài cây này",
                  "Report / Request update for this plant",
                )
              : context.tr(
                  "Báo lỗi nhận diện / Đề xuất cập nhật",
                  "Report issue / Suggest update",
                ));

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () =>
            _showReportPlantModal(context, scanProvider, docId, data),
        style: OutlinedButton.styleFrom(
          backgroundColor: highlight
              ? const Color(
                  0xFFFEF3C7,
                ).withValues(alpha: c.isDark ? 0.16 : 0.85)
              : c.surface,
          foregroundColor: highlight
              ? (c.isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
              : c.textSecondary,
          side: BorderSide(
            color: highlight
                ? const Color(0xFFF59E0B).withValues(alpha: 0.6)
                : c.border,
          ),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: const Icon(Icons.flag_outlined, size: 18),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showReportPlantModal(
    BuildContext context,
    ScanProvider scanProvider,
    String docId,
    Map<String, dynamic>? data,
  ) {
    final double conf =
        double.tryParse(
          scanProvider.scanResult?['confidence']?.toString() ?? '100',
        ) ??
        100.0;
    final bool isMissingOrInvalid = widget.isDiseaseScan
        ? (conf < 50.0 || scanProvider.scanResult?['is_in_database'] == false)
        : (data == null ||
              docId.isEmpty ||
              scanProvider.scanResult?['is_valid_plant'] == false);
    String reportType = isMissingOrInvalid
        ? (widget.isDiseaseScan ? 'missing_disease' : 'missing_plant')
        : 'wrong_prediction';
    final suggestedNameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool isSubmitting = false;

    final Future<String?> uploadFuture = _ensureCloudinaryPlantImageUrl(
      scanProvider,
      (data?['name_vi'] ?? docId).toString(),
      data,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final c = modalContext.colors;
            final mq = MediaQuery.of(modalContext);
            final double bottomSafePad = math.max(
              mq.viewInsets.bottom,
              mq.viewPadding.bottom,
            );

            final List<Map<String, String>> types = [
              {
                'key': widget.isDiseaseScan
                    ? 'missing_disease'
                    : 'missing_plant',
                'label': widget.isDiseaseScan
                    ? modalContext.tr(
                        "Bệnh chưa có trong thư viện",
                        "Disease missing from library",
                      )
                    : modalContext.tr(
                        "Chưa có trong thư viện",
                        "Missing from library",
                      ),
              },
              {
                'key': 'wrong_prediction',
                'label': modalContext.tr(
                  "Nhận diện chưa đúng",
                  "Wrong prediction",
                ),
              },
              {
                'key': 'info_error',
                'label': modalContext.tr(
                  "Lỗi thông tin / khác",
                  "Info / bug report",
                ),
              },
            ];

            return Container(
              constraints: BoxConstraints(maxHeight: mq.size.height * 0.86),
              padding: EdgeInsets.only(
                top: 14,
                left: 20,
                right: 20,
                bottom: bottomSafePad + 16,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: c.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFEF3C7,
                                  ).withValues(alpha: c.isDark ? 0.2 : 1.0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.flag_rounded,
                                  color: Color(0xFFD97706),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      modalContext.tr(
                                        "Gửi báo cáo & yêu cầu cập nhật",
                                        "Report & Request Update",
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      modalContext.tr(
                                        "Ảnh quét sẽ được gửi để đội ngũ Floria bổ sung dữ liệu.",
                                        "Your scan photo will help the Floria team improve the library.",
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: c.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            modalContext.tr("Loại phản hồi", "Report type"),
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: types.map((t) {
                              final isSel = reportType == t['key'];
                              return ChoiceChip(
                                label: Text(t['label']!),
                                selected: isSel,
                                checkmarkColor: Colors.white,
                                onSelected: (val) {
                                  if (val) {
                                    setModalState(() => reportType = t['key']!);
                                  }
                                },
                                selectedColor: c.primary,
                                backgroundColor: c.surfaceMuted,
                                labelStyle: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: isSel
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isSel ? Colors.white : c.textPrimary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isSel ? c.primary : c.border,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            modalContext.tr(
                              "Tên cây bạn biết (không bắt buộc)",
                              "Plant name if known (optional)",
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: suggestedNameCtrl,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: c.textPrimary,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: c.surfaceMuted,
                              hintText: modalContext.tr(
                                "VD: Lan hồ điệp, Cây mai vàng...",
                                "e.g., Orchid, Monstera...",
                              ),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                color: c.textMuted,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: c.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: c.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: c.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            modalContext.tr(
                              "Mô tả chi tiết / Góp ý",
                              "Details / Feedback",
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: noteCtrl,
                            maxLines: 3,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: c.textPrimary,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: c.surfaceMuted,
                              hintText: modalContext.tr(
                                "Ví dụ: Cây ngoài 40 loài, mong Floria cập nhật thêm hoặc lỗi hiển thị...",
                                "e.g., Plant not in library yet, please add...",
                              ),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                color: c.textMuted,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: c.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: c.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: c.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (suggestedNameCtrl.text.trim().isEmpty &&
                                  noteCtrl.text.trim().isEmpty) {
                                AppToast.show(
                                  modalContext,
                                  modalContext.tr(
                                    "Vui lòng nhập tên cây hoặc mô tả ngắn trước khi gửi.",
                                    "Please enter plant name or a short description.",
                                  ),
                                  isError: true,
                                );
                                return;
                              }
                              setModalState(() => isSubmitting = true);
                              try {
                                final uploadedUrl = await uploadFuture;
                                final user = FirebaseAuth.instance.currentUser;
                                await FirebaseFirestore.instance
                                    .collection('PlantRequests')
                                    .add({
                                      'userId': user?.uid ?? 'guest',
                                      'userEmail': user?.email ?? '',
                                      'userName': user?.displayName ?? '',
                                      'reportType': reportType,
                                      'suggestedName': suggestedNameCtrl.text
                                          .trim(),
                                      'note': noteCtrl.text.trim(),
                                      'predictedLabel': docId,
                                      'predictedNameVi':
                                          (data?['name_vi'] ?? '').toString(),
                                      'confidence': scanProvider
                                          .scanResult?['confidence'],
                                      'isValidPlant':
                                          scanProvider
                                              .scanResult?['is_valid_plant'] ??
                                          true,
                                      'isDiseaseScan': widget.isDiseaseScan,
                                      'imageUrl': uploadedUrl ?? '',
                                      'status': 'pending',
                                      'createdAt': FieldValue.serverTimestamp(),
                                      'createdAtIso': DateTime.now()
                                          .toIso8601String(),
                                    });

                                if (modalContext.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (!mounted) return;
                                AppToast.show(
                                  this.context,
                                  this.context.tr(
                                    "Đã gửi báo cáo thành công! Cảm ơn bạn đã đóng góp.",
                                    "Report submitted! Thank you for helping Floria.",
                                  ),
                                );
                              } catch (e) {
                                if (modalContext.mounted) {
                                  setModalState(() => isSubmitting = false);
                                  AppToast.show(
                                    modalContext,
                                    modalContext.tr(
                                      "Không thể gửi báo cáo: $e",
                                      "Failed to submit report: $e",
                                    ),
                                    isError: true,
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              modalContext.tr(
                                "Gửi báo cáo cho Floria",
                                "Submit Report",
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Đảm bảo ảnh cây chụp từ camera luôn được upload lên Cloudinary CDN vĩnh viễn
  Future<String?> _ensureCloudinaryPlantImageUrl(
    ScanProvider scanProvider,
    String plantName,
    Map<String, dynamic>? wikiData,
  ) async {
    if (_uploadedGardenImageUrl != null &&
        _uploadedGardenImageUrl!.isNotEmpty &&
        identical(_uploadedGardenImageBytes, scanProvider.webImageBytes)) {
      return _uploadedGardenImageUrl;
    }

    Uint8List? bytes = scanProvider.webImageBytes;
    if (bytes == null && scanProvider.selectedImage != null) {
      try {
        bytes = await scanProvider.selectedImage!.readAsBytes();
      } catch (_) {}
    }

    if (bytes != null) {
      try {
        final cloudUrl = await StorageService.uploadPlantPhoto(
          bytes: bytes,
          plantName: plantName,
        );
        if (cloudUrl != null && cloudUrl.isNotEmpty) {
          _uploadedGardenImageUrl = cloudUrl;
          _uploadedGardenImageBytes = scanProvider.webImageBytes;
          return cloudUrl;
        }
      } catch (e) {
        debugPrint("Lỗi upload ảnh lên Cloudinary: $e");
      }
    }

    // Fallback an toàn nếu upload Cloudinary tạm thời thất bại
    final wikiImg = (wikiData?['imageUrl'] ?? wikiData?['image_url'])
        ?.toString()
        .trim();
    if (wikiImg != null &&
        (wikiImg.startsWith('http://') || wikiImg.startsWith('https://'))) {
      return wikiImg;
    }

    final scanImg = scanProvider.scanResult?['image_url']?.toString().trim();
    if (scanImg != null && scanImg.isNotEmpty) {
      return AppConstants.formatImageUrl(scanImg);
    }

    return wikiImg;
  }

  List<String> _suggestedZonesForEnvironment(String? env) {
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

  int _extractWaterDays(dynamic freqVal) {
    if (freqVal is num) return freqVal.toInt().clamp(1, 14);
    if (freqVal is String) {
      final lower = freqVal.toLowerCase();
      if (lower.contains("ngày")) {
        final match = RegExp(r'(\d+)').firstMatch(lower);
        if (match != null) {
          return (int.tryParse(match.group(1) ?? '3') ?? 3).clamp(1, 14);
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

  String _translateEnvironment(BuildContext context, String env) {
    if (!context.isEnglish) return env;
    return const {
          'Trong nhà': 'Indoor',
          'Ngoài trời': 'Outdoor',
          'Văn phòng': 'Office',
          'Nhà kính': 'Greenhouse',
        }[env] ??
        env;
  }

  String _translateZone(BuildContext context, String zone) {
    if (!context.isEnglish) return zone;
    return const {
          'Phòng khách': 'Living room',
          'Phòng ngủ': 'Bedroom',
          'Cửa sổ': 'Window',
          'Ban công': 'Balcony',
          'Sân thượng': 'Rooftop',
          'Sân trước': 'Front yard',
          'Bàn làm việc': 'Desk',
          'Góc phòng họp': 'Meeting corner',
          'Quầy tiếp tân': 'Reception',
          'Kệ tầng trên': 'Upper shelf',
          'Kệ tầng dưới': 'Lower shelf',
          'Khu ươm giống': 'Nursery area',
        }[zone] ??
        zone;
  }

  Widget _buildModalEcoBadge(
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

  Widget _buildModalFrequencyChip(
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
          border: Border.all(color: isSelected ? c.primary : c.border),
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

  void _showAddToGardenModal(
    BuildContext context,
    ScanProvider scanProvider,
    String docId,
    Map<String, dynamic>? data,
  ) {
    final nameVi = (data?['name_vi'] ?? docId).toString();
    final scientificName = (data?['scientific_name'] ?? docId).toString();
    final plantType = (data?['plant_type'] ?? 'Cây cảnh').toString();
    final light = (data?['light'] ?? 'Đang cập nhật...').toString();
    final waterFreq = (data?['water_frequency'] ?? '2-3 lần/tuần').toString();
    final difficulty = (data?['difficulty'] ?? 'Đang cập nhật...').toString();
    final shortDesc = (data?['short_desc'] ?? '').toString();
    final family = (data?['family'] ?? '').toString();

    // Kích hoạt upload ảnh lên Cloudinary ngầm ngay khi mở modal
    final Future<String?> backgroundUploadFuture =
        _ensureCloudinaryPlantImageUrl(scanProvider, nameVi, data);

    final initialGardenProvider = Provider.of<GardenProvider>(
      context,
      listen: false,
    );
    String? selectedGardenId =
        initialGardenProvider.selectedGarden?.id ??
        (initialGardenProvider.gardens.isNotEmpty
            ? initialGardenProvider.gardens.first.id
            : null);
    UserGarden? initialGarden;
    if (selectedGardenId != null) {
      for (final g in initialGardenProvider.gardens) {
        if (g.id == selectedGardenId) {
          initialGarden = g;
          break;
        }
      }
    }

    final initialZones = _suggestedZonesForEnvironment(
      initialGarden?.environment,
    );
    String selectedZone = initialZones.first;
    bool isCustomZone = false;

    final nicknameCtrl = TextEditingController(text: nameVi);
    final customZoneCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final int freqDays = _extractWaterDays(data?['water_frequency']);
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

    String selectedHealth = 'Khỏe mạnh';
    bool enableFertilizer = true;
    int fertilizeDays = 20;
    if (data?['fertilizer'] != null) {
      final fertText = data!['fertilizer'].toString().toLowerCase();
      if (fertText.contains("tháng")) {
        fertilizeDays = 30;
      } else if (fertText.contains("tuần")) {
        final match = RegExp(r'(\d+)').firstMatch(fertText);
        final weeks = int.tryParse(match?.group(1) ?? '2') ?? 2;
        fertilizeDays = (weeks * 7).clamp(7, 60);
      }
    }
    int checkPestDays = 3;

    final String morningTime = NotificationService.cachedMorningTime;
    final String eveningTime = NotificationService.cachedEveningTime;
    String reminderTime = morningTime;
    final List<Map<String, String>> presetTimes = [
      {
        "label": "$morningTime (${context.tr('Sáng', 'Morning')})",
        "time": morningTime,
      },
      if (morningTime != "09:30" && eveningTime != "09:30")
        {"label": "09:30", "time": "09:30"},
      if (eveningTime != morningTime)
        {
          "label": "$eveningTime (${context.tr('Chiều', 'Afternoon')})",
          "time": eveningTime,
        },
      if (morningTime != "20:00" && eveningTime != "20:00")
        {"label": "20:00 (${context.tr('Tối', 'Evening')})", "time": "20:00"},
    ];

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final c = modalContext.colors;
            final mq = MediaQuery.of(modalContext);
            final double bottomSafePad = math.max(
              mq.viewInsets.bottom,
              mq.viewPadding.bottom,
            );

            final gardenProvider = Provider.of<GardenProvider>(modalContext);
            final gardens = gardenProvider.gardens;
            UserGarden? currentGarden;
            if (gardens.isNotEmpty) {
              currentGarden = gardens.firstWhere(
                (g) => g.id == selectedGardenId,
                orElse: () => gardenProvider.selectedGarden ?? gardens.first,
              );
              selectedGardenId = currentGarden.id;
            } else {
              selectedGardenId = null;
            }

            final suggestedZones = _suggestedZonesForEnvironment(
              currentGarden?.environment,
            );
            if (!isCustomZone && !suggestedZones.contains(selectedZone)) {
              selectedZone = suggestedZones.first;
            }

            final String? previewFallbackUrl =
                (data?['imageUrl'] ?? data?['image_url'])?.toString().trim();

            return Container(
              constraints: BoxConstraints(maxHeight: mq.size.height * 0.9),
              padding: EdgeInsets.only(
                top: 14,
                left: 20,
                right: 20,
                bottom: bottomSafePad + 16,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thanh kéo nhỏ
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: c.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tiêu đề & kết quả nhận diện
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: scanProvider.webImageBytes != null
                                    ? Image.memory(
                                        scanProvider.webImageBytes!,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                      )
                                    : (previewFallbackUrl != null &&
                                          previewFallbackUrl.isNotEmpty)
                                    ? Image.network(
                                        AppConstants.formatImageUrl(
                                          previewFallbackUrl,
                                        ),
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          width: 72,
                                          height: 72,
                                          color: c.surfaceTint,
                                          child: Icon(
                                            Icons.local_florist,
                                            color: c.primary,
                                            size: 32,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 72,
                                        height: 72,
                                        color: c.surfaceTint,
                                        child: Icon(
                                          Icons.local_florist,
                                          color: c.primary,
                                          size: 32,
                                        ),
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
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: c.surfaceTint,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            plantType.toUpperCase(),
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
                          const SizedBox(height: 14),

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
                            const SizedBox(height: 12),
                          ],

                          // Lưới thông số sinh thái
                          Row(
                            children: [
                              Expanded(
                                child: _buildModalEcoBadge(
                                  modalContext,
                                  icon: Icons.wb_sunny_outlined,
                                  title: modalContext.tr("Ánh sáng", "Light"),
                                  value: light,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildModalEcoBadge(
                                  modalContext,
                                  icon: Icons.water_drop_outlined,
                                  title: modalContext.tr("Tưới nước", "Water"),
                                  value: waterFreq,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildModalEcoBadge(
                                  modalContext,
                                  icon: Icons.spa_outlined,
                                  title: modalContext.tr("Chăm sóc", "Care"),
                                  value: difficulty,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // 0. Chọn khu vườn lưu cây
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                modalContext.tr(
                                  "Chọn khu vườn",
                                  "Select garden",
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final created =
                                            await Navigator.push<bool>(
                                              modalContext,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const CreateGardenScreen(),
                                              ),
                                            );
                                        if (created == true &&
                                            modalContext.mounted) {
                                          final latestProvider =
                                              Provider.of<GardenProvider>(
                                                modalContext,
                                                listen: false,
                                              );
                                          final newGarden =
                                              latestProvider.selectedGarden;
                                          if (newGarden != null) {
                                            setModalState(() {
                                              selectedGardenId = newGarden.id;
                                              final nextZones =
                                                  _suggestedZonesForEnvironment(
                                                    newGarden.environment,
                                                  );
                                              if (!isCustomZone &&
                                                  !nextZones.contains(
                                                    selectedZone,
                                                  )) {
                                                selectedZone = nextZones.first;
                                              }
                                            });
                                          }
                                        }
                                      },
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 16,
                                ),
                                label: Text(
                                  modalContext.tr("Tạo vườn mới", "New garden"),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: c.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (gardens.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: c.surfaceMuted,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: c.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.yard_outlined,
                                    size: 20,
                                    color: c.textSecondary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      modalContext.tr(
                                        "Bạn chưa có khu vườn nào. Hãy nhấn 'Tạo vườn mới' hoặc lưu tạm vào vườn mặc định.",
                                        "No garden yet. Tap 'New garden' or save to default view.",
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: c.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: gardens.map((g) {
                                final isSel = currentGarden?.id == g.id;
                                final envLabel = _translateEnvironment(
                                  modalContext,
                                  g.environment,
                                );
                                return ChoiceChip(
                                  label: Text("${g.name} ($envLabel)"),
                                  selected: isSel,
                                  checkmarkColor: Colors.white,
                                  onSelected: (val) {
                                    if (val) {
                                      setModalState(() {
                                        selectedGardenId = g.id;
                                        final nextZones =
                                            _suggestedZonesForEnvironment(
                                              g.environment,
                                            );
                                        if (!isCustomZone &&
                                            !nextZones.contains(selectedZone)) {
                                          selectedZone = nextZones.first;
                                        }
                                      });
                                    }
                                  },
                                  selectedColor: c.primary,
                                  backgroundColor: c.surfaceMuted,
                                  labelStyle: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: isSel
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSel ? Colors.white : c.textPrimary,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isSel ? c.primary : c.border,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 18),

                          // 1. Biệt danh cây
                          Text(
                            modalContext.tr(
                              "Tên hoặc biệt danh trong vườn",
                              "Name or nickname in garden",
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nicknameCtrl,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: c.textPrimary,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: c.surfaceMuted,
                              prefixIcon: Icon(
                                Icons.loyalty_outlined,
                                size: 18,
                                color: c.textSecondary,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
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
                                borderSide: BorderSide(
                                  color: c.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 2. Tình trạng sức khỏe ban đầu
                          Text(
                            modalContext.tr(
                              "Tình trạng sức khỏe ban đầu",
                              "Initial health status",
                            ),
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
                            children:
                                [
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
                                  final trH = modalContext.isEnglish
                                      ? (const {
                                              'Khỏe mạnh': 'Healthy',
                                              'Cần chú ý': 'Needs attention',
                                              'Đang phục hồi': 'Recovering',
                                            }[h] ??
                                            h)
                                      : h;

                                  return ChoiceChip(
                                    label: Text(trH),
                                    selected: isSelected,
                                    checkmarkColor: Colors.white,
                                    onSelected: (val) {
                                      if (val) {
                                        setModalState(() => selectedHealth = h);
                                      }
                                    },
                                    selectedColor: chipColor,
                                    backgroundColor: c.surfaceMuted,
                                    labelStyle: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : c.textPrimary,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isSelected
                                            ? chipColor
                                            : c.border,
                                      ),
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
                                modalContext.tr(
                                  "Chỗ đặt cây",
                                  "Plant location",
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                              if (currentGarden != null)
                                Flexible(
                                  child: Text(
                                    "${modalContext.tr("Vườn:", "Garden:")} ${currentGarden.name} (${_translateEnvironment(modalContext, currentGarden.environment)})",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: c.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
                                final isSel =
                                    !isCustomZone && selectedZone == zone;
                                return ChoiceChip(
                                  label: Text(
                                    _translateZone(modalContext, zone),
                                  ),
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
                                    fontWeight: isSel
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSel
                                        ? Colors.white
                                        : c.textSecondary,
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
                                    Icon(
                                      Icons.edit_note_outlined,
                                      size: 16,
                                      color: isCustomZone
                                          ? Colors.white
                                          : c.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      modalContext.tr("Khác...", "Other..."),
                                    ),
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
                                  fontWeight: isCustomZone
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: isCustomZone
                                      ? Colors.white
                                      : c.textSecondary,
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
                          if (isCustomZone) ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: customZoneCtrl,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: c.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: modalContext.tr(
                                  'Nhập vị trí đặt cây (VD: Góc làm việc, Bàn ăn, Cạnh TV...)',
                                  'Enter location (e.g., Desk, Dining table, Beside TV...)',
                                ),
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: c.textMuted,
                                ),
                                filled: true,
                                fillColor: c.surfaceMuted,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: c.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: c.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),

                          // 4. Lịch tưới nước
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                modalContext.tr(
                                  "Lịch tưới nước",
                                  "Watering schedule",
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.surfaceTint,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${modalContext.tr("Khuyến nghị:", "Recommended:")} $waterFreq",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: c.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildModalFrequencyChip(
                                modalContext,
                                label: modalContext.tr(
                                  "1 lần / tuần",
                                  "Once / week",
                                ),
                                isSelected: timesPerWeek == 1,
                                onTap: () =>
                                    setModalState(() => timesPerWeek = 1),
                              ),
                              _buildModalFrequencyChip(
                                modalContext,
                                label: modalContext.tr(
                                  "2 lần / tuần",
                                  "2 times / week",
                                ),
                                isSelected: timesPerWeek == 2,
                                onTap: () =>
                                    setModalState(() => timesPerWeek = 2),
                              ),
                              _buildModalFrequencyChip(
                                modalContext,
                                label: modalContext.tr(
                                  "3 lần / tuần",
                                  "3 times / week",
                                ),
                                isSelected: timesPerWeek == 3,
                                onTap: () =>
                                    setModalState(() => timesPerWeek = 3),
                              ),
                              _buildModalFrequencyChip(
                                modalContext,
                                label: modalContext.tr(
                                  "Hàng ngày (7 lần)",
                                  "Daily (7 times)",
                                ),
                                isSelected: timesPerWeek == 7,
                                onTap: () =>
                                    setModalState(() => timesPerWeek = 7),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
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
                                    "${modalContext.tr("Tùy chỉnh:", "Custom:")} $timesPerWeek ${modalContext.tr("lần/tuần (~mỗi", "times/week (~every")} ${(7 / timesPerWeek).round().clamp(1, 14)} ${modalContext.tr("ngày)", "days)")}",
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: c.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        size: 22,
                                        color: c.textSecondary,
                                      ),
                                      onPressed: timesPerWeek > 1
                                          ? () => setModalState(
                                              () => timesPerWeek--,
                                            )
                                          : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "$timesPerWeek",
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: Icon(
                                        Icons.add_circle_outline,
                                        size: 22,
                                        color: c.textSecondary,
                                      ),
                                      onPressed: timesPerWeek < 14
                                          ? () => setModalState(
                                              () => timesPerWeek++,
                                            )
                                          : null,
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
                              Expanded(
                                child: Text(
                                  modalContext.tr(
                                    "Yêu cầu bón phân dinh dưỡng:",
                                    "Fertilization requirement:",
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: enableFertilizer
                                      ? (c.isDark
                                            ? const Color(0xFF3E3218)
                                            : const Color(0xFFFEF3C7))
                                      : c.surfaceMuted,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: enableFertilizer
                                        ? (c.isDark
                                              ? const Color(0xFF5A4820)
                                              : const Color(0xFFFDE68A))
                                        : c.border,
                                  ),
                                ),
                                child: Text(
                                  enableFertilizer
                                      ? "${modalContext.tr("Mỗi", "Every")} $fertilizeDays ${modalContext.tr("ngày / lần", "days")}"
                                      : modalContext.tr(
                                          "Không áp dụng",
                                          "Not applicable",
                                        ),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: enableFertilizer
                                        ? (c.isDark
                                              ? const Color(0xFFFBBF24)
                                              : const Color(0xFFB45309))
                                        : c.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      enableFertilizer = true;
                                      if (fertilizeDays <= 0) {
                                        fertilizeDays = 20;
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: enableFertilizer
                                          ? (c.isDark
                                                ? const Color(0xFF3E3218)
                                                : const Color(0xFFFEF3C7))
                                          : c.surfaceMuted,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: enableFertilizer
                                            ? const Color(0xFFF59E0B)
                                            : c.border,
                                        width: enableFertilizer ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        RadioGroup<bool>(
                                          groupValue: enableFertilizer,
                                          onChanged: (val) {
                                            if (val == true) {
                                              setModalState(() {
                                                enableFertilizer = true;
                                                if (fertilizeDays <= 0) {
                                                  fertilizeDays = 20;
                                                }
                                              });
                                            }
                                          },
                                          child: Radio<bool>(
                                            value: true,
                                            activeColor: const Color(
                                              0xFFD97706,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            modalContext.tr(
                                              "Cần bón phân",
                                              "Needs fertilizer",
                                            ),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: enableFertilizer
                                                  ? (c.isDark
                                                        ? const Color(
                                                            0xFFFBBF24,
                                                          )
                                                        : const Color(
                                                            0xFF92400E,
                                                          ))
                                                  : c.textSecondary,
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: !enableFertilizer
                                          ? (c.isDark
                                                ? const Color(0xFF2E332F)
                                                : const Color(0xFFF3F4F6))
                                          : c.surfaceMuted,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: !enableFertilizer
                                            ? (c.isDark
                                                  ? c.primaryText
                                                  : const Color(0xFF9CA3AF))
                                            : c.border,
                                        width: !enableFertilizer ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        RadioGroup<bool>(
                                          groupValue: enableFertilizer,
                                          onChanged: (val) {
                                            if (val == false) {
                                              setModalState(() {
                                                enableFertilizer = false;
                                              });
                                            }
                                          },
                                          child: Radio<bool>(
                                            value: false,
                                            activeColor: c.textSecondary,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            modalContext.tr(
                                              "Không cần bón",
                                              "No fertilizer",
                                            ),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: !enableFertilizer
                                                  ? c.textPrimary
                                                  : c.textMuted,
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
                              data: SliderTheme.of(modalContext).copyWith(
                                activeTrackColor: const Color(0xFFF59E0B),
                                inactiveTrackColor: c.surfaceMuted,
                                thumbColor: const Color(0xFFF59E0B),
                                overlayColor: const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.15),
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
                                label:
                                    "$fertilizeDays ${modalContext.tr("ngày/lần", "days")}",
                                onChanged: (val) {
                                  setModalState(
                                    () => fertilizeDays = val.round(),
                                  );
                                },
                              ),
                            ),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 8),
                              child: Text(
                                modalContext.tr(
                                  "💡 Loài cây này không yêu cầu phân bón. Tác vụ bón phân sẽ được tắt khỏi lịch nhắc việc.",
                                  "💡 This plant doesn't require fertilizer. Fertilizing tasks will be disabled.",
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: c.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // 6. Chu kỳ kiểm tra sâu bệnh & lau lá
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  modalContext.tr(
                                    "Chu kỳ kiểm tra sâu bệnh & lau lá:",
                                    "Pest check & clean frequency:",
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: c.isDark
                                      ? const Color(0xFF1E2D40)
                                      : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: c.isDark
                                        ? const Color(0xFF2A4260)
                                        : const Color(0xFFBAE6FD),
                                  ),
                                ),
                                child: Text(
                                  "${modalContext.tr("Mỗi", "Every")} $checkPestDays ${modalContext.tr("ngày / lần", "days")}",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: c.isDark
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFF0369A1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(modalContext).copyWith(
                              activeTrackColor: const Color(0xFF0284C7),
                              inactiveTrackColor: c.surfaceMuted,
                              thumbColor: const Color(0xFF0284C7),
                              overlayColor: const Color(
                                0xFF0284C7,
                              ).withValues(alpha: 0.15),
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
                              label:
                                  "$checkPestDays ${modalContext.tr("ngày/lần", "days")}",
                              onChanged: (val) {
                                setModalState(
                                  () => checkPestDays = val.round(),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 7. Khung giờ nhắc nhở
                          Text(
                            modalContext.tr(
                              "Khung giờ nhắc nhở",
                              "Reminder time",
                            ),
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
                                    if (val) {
                                      setModalState(
                                        () => reminderTime = item['time']!,
                                      );
                                    }
                                  },
                                  selectedColor: c.primary,
                                  backgroundColor: c.surfaceMuted,
                                  labelStyle: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSel
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSel
                                        ? Colors.white
                                        : c.textSecondary,
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
                                  !presetTimes.any(
                                        (t) => t['time'] == reminderTime,
                                      )
                                      ? reminderTime
                                      : modalContext.tr(
                                          "Giờ khác...",
                                          "Custom time...",
                                        ),
                                ),
                                selected: !presetTimes.any(
                                  (t) => t['time'] == reminderTime,
                                ),
                                checkmarkColor: Colors.white,
                                onSelected: (val) async {
                                  final pickedTime = await showTimePicker(
                                    context: modalContext,
                                    initialTime: const TimeOfDay(
                                      hour: 7,
                                      minute: 0,
                                    ),
                                    builder: (pickerCtx, child) {
                                      return Theme(
                                        data: Theme.of(pickerCtx).copyWith(
                                          colorScheme: c.isDark
                                              ? ColorScheme.dark(
                                                  primary: c.primary,
                                                )
                                              : ColorScheme.light(
                                                  primary: c.primary,
                                                ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (pickedTime != null &&
                                      modalContext.mounted) {
                                    final h = pickedTime.hour
                                        .toString()
                                        .padLeft(2, '0');
                                    final m = pickedTime.minute
                                        .toString()
                                        .padLeft(2, '0');
                                    setModalState(() => reminderTime = "$h:$m");
                                  }
                                },
                                selectedColor: c.primary,
                                backgroundColor: c.surfaceMuted,
                                labelStyle: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      !presetTimes.any(
                                        (t) => t['time'] == reminderTime,
                                      )
                                      ? Colors.white
                                      : c.textSecondary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color:
                                        !presetTimes.any(
                                          (t) => t['time'] == reminderTime,
                                        )
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
                            modalContext.tr("Ghi chú chăm sóc:", "Care notes:"),
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
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: c.textPrimary,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: c.surfaceMuted,
                              hintText: modalContext.tr(
                                "Ví dụ: Đặt cạnh cửa sổ hướng đông, tưới buổi sáng...",
                                "e.g., Near east window, water in morning...",
                              ),
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                color: c.textMuted,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: c.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: c.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: c.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Nút xác nhận cố định phía trên thanh điều hướng hệ thống
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              final finalZone =
                                  isCustomZone &&
                                      customZoneCtrl.text.trim().isNotEmpty
                                  ? customZoneCtrl.text.trim()
                                  : selectedZone;
                              final finalNickname =
                                  nicknameCtrl.text.trim().isNotEmpty
                                  ? nicknameCtrl.text.trim()
                                  : nameVi;
                              final finalCalculatedDays = (7 / timesPerWeek)
                                  .round()
                                  .clamp(1, 14);
                              final finalNotes = noteCtrl.text.trim().isNotEmpty
                                  ? noteCtrl.text.trim()
                                  : "Thêm từ lượt quét camera của Trợ lý Floria";

                              final permanentUrl =
                                  await backgroundUploadFuture ??
                                  await _ensureCloudinaryPlantImageUrl(
                                    scanProvider,
                                    nameVi,
                                    data,
                                  );

                              if (!mounted) return;
                              final gp = Provider.of<GardenProvider>(
                                this.context,
                                listen: false,
                              );
                              final success = await gp.addPlant(
                                gardenId: currentGarden?.id,
                                nameVi: nameVi,
                                scientificName: scientificName,
                                nickname: finalNickname,
                                zone: finalZone,
                                imageUrl: permanentUrl,
                                plantType: plantType,
                                waterFrequencyDays: finalCalculatedDays,
                                fertilizeFrequencyDays: enableFertilizer
                                    ? fertilizeDays
                                    : 0,
                                checkPestFrequencyDays: checkPestDays,
                                healthStatus: selectedHealth,
                                reminderTime: reminderTime,
                                notes: finalNotes,
                                wikiData: data ?? {},
                              );

                              if (success && currentGarden != null) {
                                gp.selectGarden(currentGarden);
                              }

                              if (modalContext.mounted) {
                                Navigator.pop(ctx);
                              }

                              if (!mounted) return;
                              if (success) {
                                _showTopNotification(
                                  context: this.context,
                                  plantName: finalNickname,
                                );
                              } else {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      gp.errorMessage ??
                                          this.context.tr(
                                            "Có lỗi khi lưu vào vườn",
                                            "Error saving to garden",
                                          ),
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: c.primary.withValues(
                          alpha: 0.65,
                        ),
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 4,
                      ),
                      child: isSaving
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  modalContext.tr(
                                    "Đang tải ảnh & lưu...",
                                    "Uploading & saving...",
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              modalContext.tr(
                                "Xác nhận thêm vào vườn",
                                "Confirm Add to Garden",
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTopNotification({
    required BuildContext context,
    required String plantName,
  }) {
    _topNotificationEntry?.remove();
    _topNotificationEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _TopNotificationCard(
        plantName: plantName,
        onGoToGarden: () {
          entry.remove();
          _topNotificationEntry = null;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const MainNavigationScreen(initialIndex: 1),
            ),
            (route) => false,
          );
        },
        onDismiss: () {
          if (_topNotificationEntry == entry) {
            entry.remove();
            _topNotificationEntry = null;
          }
        },
      ),
    );

    _topNotificationEntry = entry;
    overlay.insert(entry);
  }
}

class _TopNotificationCard extends StatefulWidget {
  final String plantName;
  final VoidCallback onGoToGarden;
  final VoidCallback onDismiss;

  const _TopNotificationCard({
    required this.plantName,
    required this.onGoToGarden,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationCard> createState() => _TopNotificationCardState();
}

class _TopNotificationCardState extends State<_TopNotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Tự động biến mất sau 3.5 giây để không làm phiền người dùng
    _dismissTimer = Timer(const Duration(milliseconds: 3500), () {
      _closeNotification();
    });
  }

  void _closeNotification() {
    if (!mounted) return;
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: AppToast.decoration(context, radius: 20),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppToast.accentColor(
                        context,
                      ).withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppToast.accentColor(context),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(
                            "Đã lưu vào Khu Vườn!",
                            "Saved to Garden!",
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppToast.textColor(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${context.tr('Cây', 'Plant')} '${widget.plantName}' ${context.tr('đã sẵn sàng theo dõi.', 'is ready for tracking.')}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppToast.textColor(
                              context,
                            ).withValues(alpha: 0.78),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _dismissTimer?.cancel();
                      widget.onGoToGarden();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppToast.accentColor(
                        context,
                      ).withValues(alpha: 0.14),
                      foregroundColor: AppToast.accentColor(context),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      context.tr("ĐẾN VƯỜN", "TO GARDEN"),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppToast.accentColor(context),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _closeNotification,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: AppToast.textColor(
                          context,
                        ).withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- HIỆU ỨNG NHẤP NHÁY (SHIMMER) ---
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  const ShimmerLoading({super.key, required this.child});
  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0.1),
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-2.0 + (_controller.value * 4), -0.3),
              end: Alignment(-0.5 + (_controller.value * 4), 0.3),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
