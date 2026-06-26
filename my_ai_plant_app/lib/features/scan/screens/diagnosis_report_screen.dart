import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';

class DiagnosisReportScreen extends StatelessWidget {
  const DiagnosisReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF006D35)),
          onPressed: () {
            scanProvider.reset();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Báo Cáo Sức Khỏe',
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF006D35),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            _buildHeroImage(scanProvider),
            const SizedBox(height: 24),
            _buildDiagnosisCard(context, scanProvider),
            const SizedBox(height: 24),
            _buildEcommerceCarousel(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildHeroImage(ScanProvider scanProvider) {
    if (scanProvider.webImageBytes == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF006D35).withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 12))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ảnh tự động scale theo tỷ lệ thực, không bị cắt xén hay dư viền trắng
            Image.memory(
              scanProvider.webImageBytes!,
              width: double.infinity,
              fit: BoxFit.cover, 
            ),
            // Badge Tin cậy (Top Right)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF00612E), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      scanProvider.scanResult != null && scanProvider.scanResult!['confidence'] != null 
                          ? "Độ tin cậy: ${scanProvider.scanResult!['confidence']}%" 
                          : "Độ tin cậy: 95%",
                      style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF00612E)),
                    ),
                  ],
                ),
              ),
            ),
            // Badge Model (Bottom Left)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  scanProvider.scanResult != null && scanProvider.scanResult!['model_used'] != null 
                      ? "Model: ${scanProvider.scanResult!['model_used']}" 
                      : "Model: Bio-AI Ultra v4.2",
                  style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisCard(BuildContext context, ScanProvider scanProvider) {
    String diseaseName = "Không rõ bệnh";
    if (scanProvider.scanResult != null && scanProvider.scanResult!['prediction'] != null) {
      diseaseName = scanProvider.scanResult!['prediction'];
      // Format lại chữ cho dễ đọc, ví dụ: Apple___Cedar_apple_rust -> Cedar apple rust
      if (diseaseName.contains('___')) {
        diseaseName = diseaseName.split('___').last.replaceAll('_', ' ');
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.05), blurRadius: 32, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.coronavirus, color: Colors.red, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diseaseName.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red, height: 1.2),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text("Phát hiện lúc ${TimeOfDay.now().format(context)}", style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF3B4A3D))),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Nguyên nhân", style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF6B7B6C))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.biotech, size: 18, color: Color(0xFF86521B)),
                          const SizedBox(width: 6),
                          Text("Nấm (Fungal)", style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF151E16))),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mức độ", style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF6B7B6C))),
                      const SizedBox(height: 4),
                      Text("Trung Bình", style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFFFBA79))),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFBA79)),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.medical_services, color: Color(0xFF006D35)),
              const SizedBox(width: 8),
              Text(
                "Phác đồ điều trị khẩn cấp",
                style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF006D35)),
              )
            ],
          ),
          const SizedBox(height: 16),
          _buildTreatmentItem("1. Cắt tỉa ngay các lá có đốm nâu rộng để tránh lây lan bào tử."),
          const SizedBox(height: 12),
          _buildTreatmentItem("2. Hạn chế tưới nước vào buổi đêm, giữ cho bề mặt lá luôn khô ráo."),
        ],
      ),
    );
  }

  Widget _buildTreatmentItem(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(Icons.check_circle, color: Color(0xFF006D35), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.beVietnamPro(fontSize: 14, color: const Color(0xFF3B4A3D), height: 1.5),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEcommerceCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Thuốc đặc trị đề xuất",
            style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF006D35)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 310, // Tăng chiều cao để thẻ con bên trong không bị tràn (Overflowed by 10 pixels)
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildProductCard(
                "Bio-Shield Advanced",
                "Thuốc Trừ Nấm",
                "135.000 đ",
                "https://lh3.googleusercontent.com/aida-public/AB6AXuBtigTGbvRuAmdZF5ESjwKo-Qie2Wen4HJ5jQORJeilijbZX4-l-PD7J6pFxQfoEze2ibhUT5VCrH7amqgDUfpI0LrhEl4-OOOPHYdD96pZ7AywHgsDTkfTRm4ItrDuWDG3ayUnAGhQbFL2URynkzH3FzloM-0MUw30Vd8OYJf9-RLL0sb3sgmmxPs4Ev7g-o5xTi1jqn_v3NgnB_Q-gKvkr3VGuIdpAH2l7O_x70Ri08CJyPWEDmK5LbjFPyQ3TSZQyI9bEzc5Ji0",
                true,
              ),
              const SizedBox(width: 16),
              _buildProductCard(
                "Phục Hồi Xanh",
                "Phân bón lá",
                "85.000 đ",
                "https://lh3.googleusercontent.com/aida-public/AB6AXuDZAnfOrAvGX9OWQt8tvTh77gFOsLL7_LkfNczeV10IjtEiRkm8W2YtY3BC0Bj8HiL70KwOkXPCFGSSQ1mL14pUCjLA9k2iTevycEoBViXehf_C5ZmDWZtAEzgcIEnibq144gvb4YuVmdB_hTApSIZrpfN2XwELBHvXZo-cU6rT1uuhy8z_1uN4rKPZaO_9H0MVPbN29QwjpoLA6mYocsGvXVeuhTDc2P-lYntSX-44LgxEq4qIq1br3Bjhv4eISTzZvF50deYEjEY",
                false,
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildProductCard(String name, String category, String price, String imageUrl, bool primary) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(category, style: GoogleFonts.beVietnamPro(fontSize: 11, color: const Color(0xFF6B7B6C))),
          const SizedBox(height: 4),
          Text(name, style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF151E16)), maxLines: 2, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(price, style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF006D35))),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: primary ? const Color(0xFF00E676) : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: primary ? [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))] : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (primary) const Icon(Icons.shopping_cart, size: 14, color: Color(0xFF00612E)),
                if (primary) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    "Mua Ngay",
                    style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.bold, color: primary ? const Color(0xFF00612E) : const Color(0xFF3B4A3D)),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      color: const Color(0xFFF5F7FA), // Bỏ shadow
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF00E676),
          borderRadius: BorderRadius.circular(24), // Bo tròn hiện đại
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, color: Color(0xFF00612E)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "Thêm Vào Khu Vườn",
                style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF00612E)),
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
      ),
    );
  }
}
