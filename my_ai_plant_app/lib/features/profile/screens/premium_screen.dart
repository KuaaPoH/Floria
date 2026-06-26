import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'payment_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> with SingleTickerProviderStateMixin {
  bool _isYearly = true;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF006D35);
    final Color onSurfaceVariant = const Color(0xFF3B4A3D);

    return Scaffold(
      backgroundColor: const Color(0xFFF2FCEF),
      body: Stack(
        children: [
          // Background ambient glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700).withValues(alpha: 0.12),
              ),
              child: const SizedBox(),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E676).withValues(alpha: 0.12),
              ),
              child: const SizedBox(),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // AppBar custom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF3B4A3D),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        // 3D Crown Image
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                              ),
                            ),
                            Image.asset(
                              'assets/images/crown.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.workspace_premium,
                                  size: 80,
                                  color: Color(0xFFFFD700),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Title
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFD4AF37), Color(0xFFFFDF00)],
                          ).createShader(bounds),
                          child: Text(
                            'Nâng cấp Floria Pro',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mở khóa sức mạnh AI phân tích cây trồng tối thượng.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            color: onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _isYearly = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isYearly ? primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Text(
                                    'Hàng Tháng',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: !_isYearly ? Colors.white : onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _isYearly = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isYearly ? primaryColor : Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Hàng Năm',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _isYearly ? Colors.white : onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '-20%',
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pricing cards
                        Row(
                          children: [
                            // Monthly Card
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isYearly = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: !_isYearly ? 0.95 : 0.6),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: !_isYearly ? primaryColor : Colors.white.withValues(alpha: 0.5),
                                      width: !_isYearly ? 2.0 : 1.0,
                                    ),
                                    boxShadow: !_isYearly
                                        ? [
                                            BoxShadow(
                                              color: primaryColor.withValues(alpha: 0.1),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Hàng Tháng',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 14,
                                          color: onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '59.000 đ',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF151E16),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '/ tháng',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 12,
                                          color: onSurfaceVariant.withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Yearly Card
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isYearly = true),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: _isYearly ? 0.95 : 0.6),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: _isYearly ? primaryColor : Colors.white.withValues(alpha: 0.5),
                                          width: _isYearly ? 2.0 : 1.0,
                                        ),
                                        boxShadow: _isYearly
                                            ? [
                                                BoxShadow(
                                                  color: primaryColor.withValues(alpha: 0.1),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 5),
                                                )
                                              ]
                                            : [],
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Hàng Năm',
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 14,
                                              color: onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '560.000 đ',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '/ năm',
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 12,
                                              color: onSurfaceVariant.withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: -12,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryColor.withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              )
                                            ],
                                          ),
                                          child: Text(
                                            'Tốt nhất',
                                            style: GoogleFonts.beVietnamPro(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Feature Comparison Table
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Headers
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Tính năng',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: onSurfaceVariant.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      'Free',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: onSurfaceVariant.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      'PRO',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFD4AF37),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 0.5),

                              // Feature 1
                              _buildFeatureRow(
                                title: 'Mô hình AI Ultra (Độ chính xác 98%)',
                                isFreeAvailable: false,
                                isProAvailable: true,
                              ),
                              const Divider(height: 24, thickness: 0.5),

                              // Feature 2
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Trợ lý Chatbot không giới hạn',
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF151E16),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      '5 tin/ngày',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 11,
                                        color: onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      'Vô hạn',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFD4AF37),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 0.5),

                              // Feature 3
                              _buildFeatureRow(
                                title: 'Lưu trữ lịch sử không giới hạn',
                                isFreeAvailable: false,
                                isProAvailable: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                // Fixed Bottom Action
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E676).withValues(alpha: 0.3 + (_glowController.value * 0.3)),
                                  blurRadius: 10 + (_glowController.value * 15),
                                  spreadRadius: 1 + (_glowController.value * 3),
                                )
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentScreen(
                                  planName: _isYearly ? 'Floria Pro (Hàng Năm)' : 'Floria Pro (Hàng Tháng)',
                                  priceText: _isYearly ? '560.000 đ' : '59.000 đ',
                                  cycleText: _isYearly ? '/năm' : '/tháng',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E676),
                            foregroundColor: const Color(0xFF00612E),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Nâng Cấp Ngay',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Hủy bất cứ lúc nào. Thanh toán an toàn qua App Store.',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required String title,
    required bool isFreeAvailable,
    required bool isProAvailable,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.beVietnamPro(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF151E16),
            ),
          ),
        ),
        SizedBox(
          width: 50,
          child: Icon(
            isFreeAvailable ? Icons.check_circle_outline : Icons.close,
            color: isFreeAvailable ? const Color(0xFF00E676) : const Color(0xFFBA1A1A),
            size: 18,
          ),
        ),
        SizedBox(
          width: 50,
          child: Icon(
            isProAvailable ? Icons.check_circle : Icons.close,
            color: isProAvailable ? const Color(0xFF006D35) : const Color(0xFFBA1A1A),
            size: 20,
          ),
        ),
      ],
    );
  }
}
