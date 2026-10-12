import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/scan_provider.dart';
import '../../home/screens/main_navigation_screen.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import 'plant_wiki_screen.dart';
import 'dart:ui';
import 'dart:async';
import '../../garden/providers/garden_provider.dart';

class DiagnosisReportScreen extends StatefulWidget {
  final bool isDiseaseScan;

  const DiagnosisReportScreen({super.key, this.isDiseaseScan = false});

  @override
  State<DiagnosisReportScreen> createState() => _DiagnosisReportScreenState();
}

class _DiagnosisReportScreenState extends State<DiagnosisReportScreen> {
  int _selectedResultIndex = 0;
  bool _isSwitching = false;
  Future<Map<String, dynamic>?>? _plantDataFuture;
  String? _currentDocId;
  OverlayEntry? _topNotificationEntry;

  @override
  void dispose() {
    _topNotificationEntry?.remove();
    _topNotificationEntry = null;
    super.dispose();
  }

  // Lấy dữ liệu cây trồng 100% động từ đám mây (Firestore & Spring Boot Backend Gateway)
  Future<Map<String, dynamic>?> _fetchPlantData(String docId, ScanProvider scanProvider) async {
    if (docId.isEmpty) return null;
    String queryId = docId.replaceAll('_', ' ').trim();

    // 1. Kiểm tra trong plants_map đính kèm sẵn từ Backend
    if (scanProvider.scanResult != null && scanProvider.scanResult!['plants_map'] != null) {
      final pMap = scanProvider.scanResult!['plants_map'];
      if (pMap is Map && pMap[queryId] != null) {
        return Map<String, dynamic>.from(pMap[queryId]);
      }
    }

    // 2. Nếu Backend Spring Boot đính kèm plant_details và trùng khớp với queryId đang tìm
    if (scanProvider.scanResult != null && scanProvider.scanResult!['plant_details'] != null) {
      final details = scanProvider.scanResult!['plant_details'];
      if (details is Map) {
        String? plantSci = details['scientific_name']?.toString().replaceAll('_', ' ').trim().toLowerCase();
        String? plantPred = scanProvider.scanResult!['prediction']?.toString().replaceAll('_', ' ').trim().toLowerCase();
        if (queryId.toLowerCase() == plantSci || queryId.toLowerCase() == plantPred) {
          return Map<String, dynamic>.from(details);
        }
      }
    }

    // 3. Thử truy vấn trực tiếp Firestore client cho đúng cây queryId
    try {
      final doc = await FirebaseFirestore.instance.collection('plants_info').doc(queryId).get();
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

  // Design Tokens (Verdant Care Template)
  static const Color primary = Color(0xFF6d7f69);
  static const Color primaryStrong = Color(0xFF4d5d4a);
  static const Color primarySoft = Color(0xFFe5eae1);
  static const Color bg = Color(0xFFf1f0ea);
  static const Color surfaceSolid = Color(0xFFfbfaf6);
  static const Color text = Color(0xFF1f251f);
  static const Color textMuted = Color(0xFF6d736a);
  static const Color stateInfo = Color(0xFF7b8b87);
  static const Color stateWarning = Color(0xFFb08f63);
  static const Color stateError = Color(0xFFa26e69);

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);
    
    // Parse result from provider
    String mainTitle = "Đang phân tích...";
    double confidence = 0.0;
    bool isValidPlant = true;
    String message = "";
    
    List<dynamic> top3 = [];
    if (scanProvider.scanResult != null && scanProvider.scanResult!['top_3'] != null) {
      top3 = scanProvider.scanResult!['top_3'];
    }

    if (top3.isNotEmpty && _selectedResultIndex < top3.length) {
      var item = top3[_selectedResultIndex];
      mainTitle = item['class'].toString();
      if (mainTitle.contains('___')) {
         mainTitle = mainTitle.split('___').last;
      }
      mainTitle = mainTitle.replaceAll('_', ' ');
      confidence = double.tryParse(item['confidence'].toString()) ?? 0.0;
    } else if (scanProvider.scanResult != null && scanProvider.scanResult!['prediction'] != null) {
      mainTitle = scanProvider.scanResult!['prediction'].toString();
      if (mainTitle.contains('___')) {
         mainTitle = mainTitle.split('___').last;
      }
      mainTitle = mainTitle.replaceAll('_', ' ');
      if (scanProvider.scanResult!['confidence'] != null) {
         confidence = double.tryParse(scanProvider.scanResult!['confidence'].toString()) ?? 95.0;
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

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Ambient Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFf7f6f1),
                    bg,
                    Color(0xFFeceae3),
                  ],
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (scanProvider.errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.cloud_off_rounded, color: Colors.red, size: 24),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Lỗi kết nối máy chủ",
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
                                  style: GoogleFonts.inter(color: Colors.red.shade800, fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF364534),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  icon: const Icon(Icons.arrow_back, size: 16),
                                  label: const Text("Quay lại kiểm tra"),
                                ),
                              ],
                            ),
                          ),
                        if (!isValidPlant && scanProvider.errorMessage == null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    message.isNotEmpty ? message : "Hệ thống phát hiện ảnh không phải thực vật hoặc quá mờ.",
                                    style: GoogleFonts.inter(color: Colors.red.shade800, fontWeight: FontWeight.w600, fontSize: 13),
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

  Widget _buildContentBlock(ScanProvider scanProvider, String mainTitle, double confidence) {
    List<dynamic> top3 = [];
    if (scanProvider.scanResult != null && scanProvider.scanResult!['top_3'] != null) {
      top3 = scanProvider.scanResult!['top_3'];
    }
    String docId = "";
    if (top3.isNotEmpty && _selectedResultIndex < top3.length) {
      docId = top3[_selectedResultIndex]['class'].toString();
      if (docId.contains('___')) {
         docId = docId.split('___').last;
      }
    } else if (scanProvider.scanResult != null && scanProvider.scanResult!['prediction'] != null) {
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

    if (scanProvider.errorMessage != null || docId.isEmpty) {
      return Column(
        children: [
          _buildHeroCard(scanProvider, mainTitle, null, confidence),
          const SizedBox(height: 16),
          if (top3.isNotEmpty) _buildResultStack(scanProvider),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primary.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  scanProvider.errorMessage != null ? Icons.wifi_off_rounded : Icons.spa_outlined,
                  size: 44,
                  color: textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  scanProvider.errorMessage != null
                      ? "Không thể nhận kết quả từ máy chủ"
                      : "Không thể nhận diện rõ loại cây này",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  scanProvider.errorMessage != null
                      ? "Vui lòng kiểm tra kết nối tới Backend Spring Boot trên cổng 8080."
                      : "Hãy chụp ảnh lại gần hơn, đầy đủ ánh sáng và lấy nét trực diện vào lá cây.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryStrong,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text("Chụp lại ảnh khác", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildActionPills(context, scanProvider, docId, null),
        ],
      );
    }

    if (widget.isDiseaseScan) {
      return Column(
        children: [
          _buildHeroCard(scanProvider, mainTitle, null, confidence),
          const SizedBox(height: 16),
          _buildResultStack(scanProvider),
          const SizedBox(height: 16),
          _buildCauseCard(),
          const SizedBox(height: 16),
          _buildTreatmentCard(),
          const SizedBox(height: 16),
          _buildActionPills(context, scanProvider, docId, null),
        ],
      );
    }

    if (_currentDocId != docId) {
      _currentDocId = docId;
      _plantDataFuture = docId.isNotEmpty ? _fetchPlantData(docId, scanProvider) : Future.value(null);
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _plantDataFuture,
      builder: (context, snapshot) {
        Map<String, dynamic>? plantData = snapshot.data;

        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting && plantData == null) {
           child = Column(
             key: const ValueKey('waiting'),
             children: [
               _buildHeroCard(scanProvider, mainTitle, null, confidence),
               const SizedBox(height: 16),
               _buildResultStack(scanProvider, null),
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
               _buildResultStack(scanProvider, plantData),
               const SizedBox(height: 16),
               if (plantData == null && docId.isNotEmpty && snapshot.connectionState != ConnectionState.waiting) ...[
                 Center(
                   child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Text("Chưa có thông tin bách khoa trong cơ sở dữ liệu cho: '$docId'", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                   ),
                 ),
               ],
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
      }
    );
  }

  Widget _buildHeader(BuildContext context, double confidence, bool isLoading) {
     return Padding(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Row(
             children: [
               IconButton(
                 icon: const Icon(Icons.arrow_back_ios_new, color: text, size: 20),
                 onPressed: () {
                   Provider.of<ScanProvider>(context, listen: false).reset();
                   Navigator.pop(context);
                 },
               ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isDiseaseScan ? "CHẨN ĐOÁN BỆNH" : "KẾT QUẢ NHẬN DIỆN",
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: textMuted),
                    ),
                   Text(
                     "Kết quả quét",
                     style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: text, letterSpacing: -0.5),
                   ),
                   Text(
                     isLoading ? "--%" : "${confidence.toInt()}%",
                     style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: widget.isDiseaseScan ? stateError : primaryStrong),
                   ),
                 ],
               ),
             ],
           ),
         ],
       ),
     );
  }

  Widget _buildHeroCard(ScanProvider provider, String title, Map<String, dynamic>? data, double confidence) {
    String displayName = title;
    if (data != null && data['name_vi'] != null && data['name_vi'].toString().isNotEmpty) {
      displayName = data['name_vi'].toString();
    } else if (provider.scanResult != null && provider.scanResult!['top_3'] != null) {
      List<dynamic> t3 = provider.scanResult!['top_3'];
      if (_selectedResultIndex < t3.length && t3[_selectedResultIndex] is Map && t3[_selectedResultIndex]['name_vi'] != null) {
        displayName = t3[_selectedResultIndex]['name_vi'].toString();
      } else if (provider.isLoading || data == null) {
        displayName = "Đang tra cứu...";
      }
    } else if (provider.isLoading || data == null) {
      displayName = "Đang tra cứu...";
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.8),
            stateInfo.withOpacity(0.15),
          ],
        ),
        border: Border.all(color: primary.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8))],
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
              color: Colors.grey.shade200,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: provider.webImageBytes != null
                      ? Image.memory(provider.webImageBytes!, fit: BoxFit.cover)
                      : const Center(child: Icon(Icons.image, color: Colors.grey)),
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
                        color: Colors.black.withOpacity(0.35),
                        alignment: Alignment.center,
                        child: Text(
                          "Ảnh vừa quét",
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.isDiseaseScan ? stateError.withOpacity(0.15) : stateInfo.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.isDiseaseScan ? Icons.coronavirus : Icons.auto_awesome, color: widget.isDiseaseScan ? stateError : primaryStrong, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        provider.isLoading 
                          ? "Đang xử lý..." 
                          : widget.isDiseaseScan 
                            ? "Cảnh báo bệnh" 
                            : (_selectedResultIndex == 0 ? "Khớp tốt nhất" : (_selectedResultIndex == 1 ? "Gần giống" : "Ít khả năng")),
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: widget.isDiseaseScan ? stateError : primaryStrong),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayName,
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: text, height: 1.1, letterSpacing: -0.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (widget.isDiseaseScan) 
                      _buildTag("Cần xử lý", color: stateError.withOpacity(0.2), textColor: stateError),
                    if (!widget.isDiseaseScan && data != null && data['placements'] != null)
                      ...((data['placements'] as List<dynamic>).map((e) => _buildTag(e.toString()))),
                    if (!widget.isDiseaseScan && data == null)
                      _buildTag(provider.isLoading ? "Đang tra cứu..." : "Cây cảnh"),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isDiseaseScan 
                    ? "Cây đang có dấu hiệu nhiễm bệnh. Cần xử lý sớm để tránh lây lan."
                    : (data != null && data['short_desc'] != null 
                        ? data['short_desc'] 
                        : ""),
                  style: GoogleFonts.inter(fontSize: 12, color: textMuted, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, {Color? color, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, color: textColor ?? textMuted)),
    );
  }

  // --- THẺ KHUNG XƯƠNG (SKELETON) KHI ĐANG TẢI ---
  Widget _buildSkeletonCard() {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 80, height: 12, decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(6)), margin: const EdgeInsets.only(bottom: 8)),
            Container(width: 160, height: 20, decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(6)), margin: const EdgeInsets.only(bottom: 24)),
            
            Container(height: 64, decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(16)), margin: const EdgeInsets.only(bottom: 12)),
            Container(height: 64, decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(16)), margin: const EdgeInsets.only(bottom: 12)),
            Container(height: 64, decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(16))),
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
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
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
                    Container(width: 70, height: 10, decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(5)), margin: const EdgeInsets.only(bottom: 6)),
                    Container(width: 130, height: 18, decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(6))),
                  ],
                ),
                Container(width: 80, height: 24, decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(12))),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 60, decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(20)), margin: const EdgeInsets.only(bottom: 12)),
            Container(height: 60, decoration: BoxDecoration(color: Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(20))),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStack(ScanProvider scanProvider, [Map<String, dynamic>? currentPlantData]) {
    List<dynamic> top3 = [];
    if (scanProvider.scanResult != null && scanProvider.scanResult!['top_3'] != null) {
      top3 = scanProvider.scanResult!['top_3'];
    }

    String getTitle(int index) {
      if (top3.length > index) {
        var item = top3[index];
        if (item is Map && item['name_vi'] != null && item['name_vi'].toString().isNotEmpty) {
          return item['name_vi'].toString();
        }
        String title = top3[index]['class'].toString();
        if (title.contains('___')) {
           title = title.split('___').last;
        }
        String cleanTitle = title.replaceAll('_', ' ').trim();
        if (scanProvider.scanResult != null && scanProvider.scanResult!['plants_map'] != null) {
          final pMap = scanProvider.scanResult!['plants_map'];
          if (pMap is Map && pMap[cleanTitle] != null && pMap[cleanTitle]['name_vi'] != null) {
            return pMap[cleanTitle]['name_vi'].toString();
          }
        }
        if (index == _selectedResultIndex && currentPlantData != null && currentPlantData['name_vi'] != null) {
          return currentPlantData['name_vi'].toString();
        }
        return cleanTitle;
      }
      return index == 1 ? "Gần giống" : "Ít khả năng";
    }

    String getScore(int index) {
      if (top3.length > index) {
         return "${double.tryParse(top3[index]['confidence'].toString())?.toInt() ?? 0}%";
      }
      return "0%";
    }
    
    bool isPerfectMatch = false;
    if (top3.isNotEmpty) {
      double firstScore = double.tryParse(top3[0]['confidence'].toString()) ?? 0;
      if (firstScore >= 99.99) { // 100%
         isPerfectMatch = true;
      }
    }

    int matchCount = 0;
    if (getScore(0) != "0%") matchCount++;
    if (top3.length > 1 && getScore(1) != "0%") matchCount++;
    if (top3.length > 2 && getScore(2) != "0%") matchCount++;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.4)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (scanProvider.scanResult != null && scanProvider.scanResult!['is_valid_plant'] == false)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: stateWarning.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Text("Cảnh báo: AI không nhận diện được cây hợp lệ trong ảnh.", style: GoogleFonts.inter(color: stateWarning, fontWeight: FontWeight.bold)),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isPerfectMatch ? "1 KẾT QUẢ" : "$matchCount KẾT QUẢ", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textMuted)),
                  Text("Độ tương đồng", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: text)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("Khớp nhất", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: primaryStrong)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (getScore(0) != "0%")
            _buildResultRow(
              index: 0,
              title: "1. ${getTitle(0)}", 
              desc: "Khớp cao nhất với đặc điểm nhận diện.", 
              score: getScore(0), 
              bgColor: primary.withOpacity(0.16),
              scoreColor: primaryStrong
            ),
          if (!isPerfectMatch && top3.length > 1 && getScore(1) != "0%") ...[
            const SizedBox(height: 12),
            _buildResultRow(
              index: 1,
              title: "2. ${getTitle(1)}", 
              desc: "Hình thái gần giống nhưng chi tiết khác.", 
              score: getScore(1), 
              bgColor: stateInfo.withOpacity(0.12),
              scoreColor: stateInfo
            ),
          ],
          if (!isPerfectMatch && top3.length > 2 && getScore(2) != "0%") ...[
            const SizedBox(height: 12),
            _buildResultRow(
              index: 2,
              title: "3. ${getTitle(2)}", 
              desc: "Có sắc độ tương tự nhưng sai biệt lớn.", 
              score: getScore(2), 
              bgColor: textMuted.withOpacity(0.1),
              scoreColor: textMuted
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow({required int index, required String title, required String desc, required String score, required Color bgColor, required Color scoreColor}) {
    bool isSelected = _selectedResultIndex == index;
    return GestureDetector(
      onTap: () async {
        if (_selectedResultIndex == index) return;
        setState(() {
          _isSwitching = true;
          _selectedResultIndex = index;
        });
        await Future.delayed(const Duration(milliseconds: 350));
        if (mounted) {
          setState(() {
            _isSwitching = false;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? bgColor.withOpacity(0.4) : bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primary : Colors.white.withOpacity(0.72), width: isSelected ? 2 : 1),
        ),
        child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: text), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.inter(fontSize: 12, color: textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(score, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
      ),
    );
  }



  Widget _buildInfoCard(String mainTitle, Map<String, dynamic>? data) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [stateInfo.withOpacity(0.12), Colors.white.withOpacity(0.92)],
        ),
        border: Border.all(color: stateInfo.withOpacity(0.16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
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
                  Text("HỒ SƠ CÂY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textMuted)),
                  Text("Thông tin cơ bản", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: text)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(data != null ? (data['plant_type'] ?? "Thực vật") : "Dễ chăm", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: primaryStrong)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildInfoCell("Tên tiếng Việt", data?['name_vi'] ?? "Đang cập nhật...")),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCell("Tên quốc tế", data?['scientific_name'] ?? mainTitle)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildInfoCell("Họ thực vật", data?['family'] ?? "Đang cập nhật...")),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCell("Nguồn gốc", data?['origin'] ?? "Đang cập nhật...")),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCell("Độ khó chăm", data?['difficulty'] ?? "Đang cập nhật..."),
        ],
      ),
    );
  }

  Widget _buildCauseCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [stateError.withOpacity(0.12), Colors.white.withOpacity(0.92)],
        ),
        border: Border.all(color: stateError.withOpacity(0.16)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
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
                  Text("NGUYÊN NHÂN", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textMuted)),
                  Text("Phân tích mầm bệnh", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: text)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: stateError.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("Nguy cơ lây", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: stateError)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildInfoCell("Tác nhân", "Nấm / Vi khuẩn")),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCell("Mức độ", "Trung Bình")),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCell("Đặc điểm", "Xuất hiện các đốm nâu hoặc vàng trên bề mặt lá, viền đốm thường có màu sậm. Bệnh lây lan nhanh trong môi trường ẩm ướt."),
        ],
      ),
    );
  }

  Widget _buildCareCard(Map<String, dynamic>? data) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [stateWarning.withOpacity(0.12), Colors.white.withOpacity(0.94)],
        ),
        border: Border.all(color: stateWarning.withOpacity(0.18)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("ĐỀ XUẤT CHĂM CÂY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textMuted)),
              Text("Môi trường phù hợp", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: text)),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildCareTile("Ánh sáng", data?['light'] ?? "Đang cập nhật...")),
                const SizedBox(width: 12),
                Expanded(child: _buildCareTile("Tưới nước", data?['water_frequency'] ?? "Đang cập nhật...")),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildCareTile("Độ ẩm", data?['humidity'] ?? "Đang cập nhật...")),
                const SizedBox(width: 12),
                Expanded(child: _buildCareTile("Nhiệt độ", data?['temperature'] ?? "Đang cập nhật...")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primarySoft, Colors.white.withOpacity(0.94)],
        ),
        border: Border.all(color: primary.withOpacity(0.18)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
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
                  Text("PHÁC ĐỒ ĐIỀU TRỊ", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: textMuted)),
                  Text("Hành động khẩn cấp", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: text)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: stateWarning.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("Khuyên dùng", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: stateWarning)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCell("Bước 1: Cách ly & Cắt tỉa", "Lập tức tách cây bệnh ra khỏi khu vực chung. Dùng kéo sạch cắt bỏ các lá có đốm nâu/vàng."),
          const SizedBox(height: 12),
          _buildInfoCell("Bước 2: Xử lý hóa học", "Phun thuốc gốc đồng (Copper Fungicide) hoặc Mancozeb theo liều lượng bao bì."),
          const SizedBox(height: 12),
          _buildInfoCell("Bước 3: Chăm sóc", "Ngưng tưới nước lên lá, chỉ tưới gốc. Đặt cây ở nơi thoáng gió nhưng tránh nắng gắt trực tiếp."),
        ],
      ),
    );
  }

  Widget _buildInfoCell(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.74)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, letterSpacing: 0.8, color: textMuted)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: text, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildCareTile(String kicker, String main) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kicker.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, letterSpacing: 0.8, color: textMuted)),
          const SizedBox(height: 8),
          Text(main, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: primaryStrong)),
        ],
      ),
    );
  }

  Widget _buildActionPills(BuildContext context, ScanProvider scanProvider, String docId, Map<String, dynamic>? data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showAddToGardenModal(context, scanProvider, docId, data),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryStrong,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: primary.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text("Lưu vào vườn", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
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
                  backgroundColor: stateInfo.withOpacity(0.14),
                  foregroundColor: primaryStrong,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text("Chi tiết", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
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
                  backgroundColor: Colors.white.withOpacity(0.76),
                  foregroundColor: text,
                  side: BorderSide(color: primary.withOpacity(0.12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text("Quét lại", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Provider.of<ScanProvider>(context, listen: false).reset();
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (context) => const MainNavigationScreen()), 
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.76),
                  foregroundColor: text,
                  side: BorderSide(color: primary.withOpacity(0.12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text("Trang chủ", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddToGardenModal(
    BuildContext context,
    ScanProvider scanProvider,
    String docId,
    Map<String, dynamic>? data,
  ) {
    final nameVi = data?['name_vi'] ?? docId;
    final scientificName = data?['scientific_name'] ?? docId;
    final plantType = data?['plant_type'] ?? 'Cây cảnh';
    
    // Parse chu kỳ tưới nước
    int freqDays = 3;
    final waterFreqStr = data?['water_frequency']?.toString() ?? '2-3 lần/tuần';
    if (waterFreqStr.contains('1 lần/tuần')) {
      freqDays = 7;
    } else if (waterFreqStr.contains('2-3 lần/tuần') || waterFreqStr.contains('2 lần/tuần')) {
      freqDays = 3;
    } else if (waterFreqStr.contains('ngày')) {
      final match = RegExp(r'(\d+)').firstMatch(waterFreqStr);
      if (match != null) {
        freqDays = int.tryParse(match.group(1)!) ?? 3;
      }
    }

    final nicknameCtrl = TextEditingController(text: nameVi);
    String selectedZone = 'Phòng khách';
    final List<String> zones = ['Phòng khách', 'Ban công', 'Bàn làm việc', 'Sân thượng', 'Phòng ngủ'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF364534).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.eco, color: Color(0xFF364534), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Thêm vào Khu Vườn của bạn",
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B1C1A),
                                ),
                              ),
                              Text(
                                nameVi,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF6A756B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Biệt danh của cây",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B1C1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nicknameCtrl,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B1C1A),
                      ),
                      cursorColor: const Color(0xFF364534),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Đặt tên đáng yêu cho cây...",
                        prefixIcon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF6A756B)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    const SizedBox(height: 16),
                    Text(
                      "Vị trí đặt cây (Khu vực)",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B1C1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: zones.map((z) {
                        final isSel = selectedZone == z;
                        return ChoiceChip(
                          label: Text(z),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedZone = z);
                          },
                          labelStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                            color: isSel ? Colors.white : const Color(0xFF444842),
                          ),
                          selectedColor: const Color(0xFF364534),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSel ? Colors.transparent : const Color(0xFFE4E2DF),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF364534).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.water_drop, color: Color(0xFF364534), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Lịch nhắc tưới: Mỗi $freqDays ngày một lần ($waterFreqStr)",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF364534),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
                          final success = await gardenProvider.addPlant(
                            nameVi: nameVi,
                            scientificName: scientificName,
                            nickname: nicknameCtrl.text.trim().isNotEmpty ? nicknameCtrl.text.trim() : nameVi,
                            zone: selectedZone,
                            imageUrl: scanProvider.selectedImage != null
                                ? scanProvider.selectedImage!.path
                                : null,
                            plantType: plantType,
                            waterFrequencyDays: freqDays,
                            notes: "Thêm từ lượt quét thông minh Floria AI",
                            wikiData: data ?? {},
                          );

                          if (context.mounted) {
                            if (success) {
                              _showTopNotification(
                                context: context,
                                plantName: nicknameCtrl.text.trim().isNotEmpty ? nicknameCtrl.text.trim() : nameVi,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(gardenProvider.errorMessage ?? "Có lỗi khi lưu vào vườn"),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF364534),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 4,
                        ),
                        child: Text(
                          "Xác nhận thêm vào vườn",
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

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
              decoration: BoxDecoration(
                color: const Color(0xFF1E3320), // Xanh lá đậm sang trọng
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFF38573C), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4E8CE).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Color(0xFF8CE095), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Đã lưu vào Khu Vườn! 🌱",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white, // Chữ trắng 100%
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Cây '${widget.plantName}' đã sẵn sàng theo dõi.",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9), // Chữ trắng sáng
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
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1E3320),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    child: Text(
                      "ĐẾN VƯỜN",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E3320), // Chữ xanh sẫm trên nền trắng
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
                        color: Colors.white.withValues(alpha: 0.7),
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

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
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
