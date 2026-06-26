import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/premium_screen.dart';
import 'camera_scanning_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String _selectedModel = "resnet50v2";

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2FCEF),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        title: Text(
          'Hướng Dẫn Quét Ảnh',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF006D35),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Hero Illustration
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006D35).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.energy_savings_leaf,
                            size: 64,
                            color: Color(0xFF006D35),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Trí Tuệ Nhân Tạo - Nâng Tầm Nông Nghiệp Xanh',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF006D35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Steps Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 4))
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cách sử dụng camera', style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3B4A3D))),
                      const SizedBox(height: 16),
                      _buildStepRow(1, 'Đưa camera cách lá cây bệnh khoảng 10-15cm.'),
                      const SizedBox(height: 16),
                      _buildStepRow(2, 'Chạm vào màn hình để lấy nét.'),
                      const SizedBox(height: 16),
                      _buildStepRow(3, 'Bấm chụp để AI tự động phân tích.'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Tips Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mẹo để AI nhận diện tốt nhất', style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3B4A3D))),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF006D35).withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: const BoxDecoration(color: Color(0xFF006D35), shape: BoxShape.circle),
                                    child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('NÊN', style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF00612E))),
                                  const SizedBox(height: 8),
                                  _buildTipItem('Đủ ánh sáng tự nhiên', const Color(0xFF006D35)),
                                  _buildTipItem('Lá nằm giữa khung', const Color(0xFF006D35)),
                                  _buildTipItem('Nền đơn giản', const Color(0xFF006D35)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDAD6).withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: const BoxDecoration(color: Color(0xFFBA1A1A), shape: BoxShape.circle),
                                    child: const Icon(Icons.cancel, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('KHÔNG NÊN', style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFBA1A1A))),
                                  const SizedBox(height: 8),
                                  _buildTipItem('Ảnh bị nhòe/mờ', const Color(0xFFBA1A1A)),
                                  _buildTipItem('Lá bị che khuất', const Color(0xFFBA1A1A)),
                                  _buildTipItem('Chụp ngược sáng', const Color(0xFFBA1A1A)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // AI Engine Section
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Động cơ AI', style: GoogleFonts.beVietnamPro(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3B4A3D))),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildEngineCard(
                              id: 'mobilenetv2',
                              name: 'Basic AI',
                              accuracy: '85% Accuracy',
                              desc: 'Phân tích cơ bản cho các loại cây phổ biến.',
                              isPremiumRequired: false,
                              isPremiumUser: authProvider.isPremium,
                            ),
                            _buildEngineCard(
                              id: 'resnet50v2',
                              name: 'DeepVision',
                              accuracy: '92% Accuracy',
                              desc: 'Nhận diện sâu các triệu chứng bệnh phức tạp.',
                              isPremiumRequired: false,
                              isPremiumUser: authProvider.isPremium,
                            ),
                            _buildPremiumEngineCard(authProvider.isPremium),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [const Color(0xFFF2FCEF), const Color(0xFFF2FCEF).withValues(alpha: 0.0)],
                )
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraScanningScreen(selectedModel: _selectedModel),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: Text('Đã Hiểu, Mở Camera Ngay', style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D35),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: const Color(0xFF006D35).withValues(alpha: 0.5),
                ),
              ),
            ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStepRow(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: GoogleFonts.beVietnamPro(color: const Color(0xFF006D35), fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(text, style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF151E16))),
          ),
        )
      ],
    );
  }

  Widget _buildTipItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6.0, right: 8.0),
            child: Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
          Expanded(
            child: Text(text, style: GoogleFonts.beVietnamPro(fontSize: 14, color: const Color(0xFF3B4A3D))),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineCard({
    required String id,
    required String name,
    required String accuracy,
    required String desc,
    required bool isPremiumRequired,
    required bool isPremiumUser,
  }) {
    final bool isSelected = _selectedModel == id;
    
    return GestureDetector(
      onTap: () {
        setState(() { _selectedModel = id; });
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF006D35) : Colors.white.withValues(alpha: 0.4), width: isSelected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name, style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF006D35) : const Color(0xFF151E16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: isSelected ? const Color(0xFF006D35).withValues(alpha: 0.1) : const Color(0xFFDBE5D9), borderRadius: BorderRadius.circular(12)),
                  child: Text(accuracy, style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF006D35) : const Color(0xFF3B4A3D))),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(desc, style: GoogleFonts.beVietnamPro(fontSize: 14, color: const Color(0xFF3B4A3D))),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumEngineCard(bool isPremiumUser) {
    final bool isSelected = _selectedModel == 'efficientnetb0';
    return GestureDetector(
      onTap: () {
        if (!isPremiumUser) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
        } else {
          setState(() { _selectedModel = 'efficientnetb0'; });
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFDB878), Color(0xFFFFBA79)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF86521B) : Colors.white.withValues(alpha: 0.3), width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: const Color(0xFF86521B).withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Ultra AI', style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF86521B))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFF86521B), borderRadius: BorderRadius.circular(10)),
                          child: Text('PRO', style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        )
                      ],
                    ),
                    if (!isPremiumUser) const Icon(Icons.lock, size: 16, color: Color(0xFF86521B)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Độ chính xác: 98%', style: GoogleFonts.beVietnamPro(fontSize: 10, color: const Color(0xFF86521B))),
                const SizedBox(height: 8),
                Text('Công nghệ AI tiên tiến nhất với khả năng tự học vượt trội.', style: GoogleFonts.beVietnamPro(fontSize: 14, color: const Color(0xFF6A3C03))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
