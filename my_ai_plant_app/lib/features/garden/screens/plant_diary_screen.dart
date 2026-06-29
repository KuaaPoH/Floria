import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/custom_image.dart';
import 'dart:ui';

class PlantDiaryScreen extends StatelessWidget {
  const PlantDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6),
      body: Stack(
        children: [
          // Timeline Content
          ListView(
            padding: const EdgeInsets.only(top: 110, bottom: 100, left: 24, right: 24),
            children: [
              Stack(
                children: [
                  // Timeline vertical line
                  Positioned(
                    left: 15,
                    top: 16,
                    bottom: 32, // Stop slightly before the end
                    child: Container(
                      width: 2,
                      color: const Color(0xFFD6E8CF), // primary-fixed
                    ),
                  ),
                  // Timeline items
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimelineItem(
                        icon: Icons.photo_camera,
                        iconBgColor: const Color(0xFF364534), // primary
                        iconColor: Colors.white,
                        date: "29 Tháng 6, 2026",
                        tag: "Đâm chồi",
                        tagBgColor: const Color(0xFFD6E8CF),
                        tagTextColor: const Color(0xFF364534),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomImage(
                              imageUrl: "https://picsum.photos/seed/plant5/400/400",
                              width: double.infinity,
                              height: 160,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Nay để ý thấy em nó nhú thêm 2 lá non. Có vẻ rất thích loại đất mùn mới thay tuần trước.",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF444842),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTimelineItem(
                        icon: Icons.medical_services,
                        iconBgColor: const Color(0xFFFFF3CD),
                        iconColor: const Color(0xFF856404),
                        date: "15 Tháng 5, 2026",
                        tag: "Sâu bệnh",
                        tagBgColor: const Color(0xFFFFF3CD),
                        tagTextColor: const Color(0xFF856404),
                        content: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9E6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFF3CD)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning, color: Color(0xFF856404), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Phát hiện rệp sáp ở nách lá. Đã dùng cồn lau sạch và cách ly.",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFF856404),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildTimelineItem(
                        icon: Icons.eco,
                        iconBgColor: Colors.white,
                        iconColor: const Color(0xFF747871), // outline
                        iconBorderColor: const Color(0xFFC4C8BF), // outline-variant
                        date: "1 Tháng 1, 2026",
                        tag: "Ngày đầu tiên",
                        tagBgColor: const Color(0xFFE4E2DF), // surface-variant
                        tagTextColor: const Color(0xFF444842), // on-surface-variant
                        content: Text(
                          "Chính thức rước em về góc ban công. Hy vọng em sẽ phát triển tốt!",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF444842),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Sticky Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16, left: 24, right: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF9F6).withOpacity(0.8),
                    border: const Border(bottom: BorderSide(color: Color(0x4DC4C8BF))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderButton(Icons.keyboard_arrow_left, () => Navigator.pop(context)),
                      Column(
                        children: [
                          Text(
                            "Nhật ký phát triển",
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B1C1A),
                            ),
                          ),
                        ],
                      ),
                      _buildHeaderButton(Icons.filter_list, () {}),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF364534),
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0xFF364534).withOpacity(0.4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          icon: const Icon(Icons.edit_square, size: 20),
          label: Text(
            "Viết nhật ký",
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFC4C8BF)),
        ),
        child: Icon(icon, color: const Color(0xFF1B1C1A), size: 20),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    Color? iconBorderColor,
    required String date,
    required String tag,
    required Color tagBgColor,
    required Color tagTextColor,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Node icon
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: iconBorderColor ?? const Color(0xFFFBF9F6),
                  width: iconBorderColor != null ? 2 : 4,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFC4C8BF).withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4D5D4A).withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1B1C1A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: tagBgColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: tagTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  content,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
