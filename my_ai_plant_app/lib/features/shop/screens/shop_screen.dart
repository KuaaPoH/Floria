import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/custom_image.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['Đề xuất', 'Dụng cụ', 'Đất trồng', 'Phân bón', 'Bình xịt'];

  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Bộ dụng cụ chăm cây',
      'desc': 'Xẻng nhỏ, kéo tỉa, găng tay mềm.',
      'price': '590.000đ',
      'tag': 'Hot',
      'w': 64.0, 'h': 64.0,
    },
    {
      'name': 'Đất trồng indoor mix',
      'desc': 'Thoáng khí, giữ ẩm cân bằng cho chậu trong nhà.',
      'price': '185.000đ',
      'tag': '',
      'w': 80.0, 'h': 64.0,
    },
    {
      'name': 'Phân bón lá dịu nhẹ',
      'desc': 'Công thức cân bằng cho lá non và rễ ổn định.',
      'price': '220.000đ',
      'tag': 'Mới',
      'w': 56.0, 'h': 72.0,
    },
    {
      'name': 'Bình xịt sương mịn',
      'desc': 'Phun đều, nhẹ tay cho lá mỏng và khóm nhỏ.',
      'price': '145.000đ',
      'tag': '',
      'w': 48.0, 'h': 64.0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHỌN ĐÚNG VẬT DỤNG',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: const Color(0xFF6A756B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cửa hàng',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                          color: const Color(0xFF1F2A21),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F4EA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Thành viên -10%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3E8055),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Banner Starter Care Kit
              Container(
                height: 206,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF17231A).withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 16))
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomImage(
                        imageUrl: 'https://picsum.photos/seed/shop1/400/400',
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFFF7FBF8).withValues(alpha: 0.14),
                              const Color(0xFF18221B).withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(
                              'Gói gợi ý cho cây đang yếu',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
                            )
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bộ Chăm Sóc Cơ Bản',
                            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bình xịt mịn, phân bón cân bằng và khăn lau lá dành cho cây có dấu hiệu mệt nhẹ.',
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8), height: 1.5),
                          )
                        ],
                      )
                    ],
                  ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Categories / Chips
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE5F4EA) : Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4F9D69).withValues(alpha: 0.16) : const Color(0xFF4F9D69).withValues(alpha: 0.14),
                          ),
                        ),
                        child: Text(
                          _categories[index],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF3E8055) : const Color(0xFF6A756B),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Product Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return _buildProductCard(product);
                },
              ),
              const SizedBox(height: 24),

              // Soft Card (Member Offers)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF17231A).withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ƯU ĐÃI THÀNH VIÊN',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: const Color(0xFF6A756B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mở khóa tài khoản để nhận nhiều ưu đãi',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2A21),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cập nhật thông tin cá nhân để nhận ngay các mã giảm giá đặc biệt và dễ dàng theo dõi lịch sử mua sắm của bạn.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6A756B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF66B27F), Color(0xFF4F9D69)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF4F9D69).withValues(alpha: 0.16), blurRadius: 30, offset: const Offset(0, 12))
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Mở khóa tài khoản',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF17231A).withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visual Container
          Container(
            height: 114,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xD9E5F4EA), Color(0xF5F3FBF5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Container(
                width: product['w'] as double,
                height: product['h'] as double,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF17231A).withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8))
                  ],
                ),
              ),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1F2A21)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['desc'],
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6A756B), height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product['price'],
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF3E8055)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if ((product['tag'] as String).isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: product['tag'] == 'Hot' ? const Color(0xFFE5F4EA) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
                          ),
                          child: Text(
                            product['tag'],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: product['tag'] == 'Hot' ? FontWeight.w600 : FontWeight.w500,
                              color: product['tag'] == 'Hot' ? const Color(0xFF3E8055) : const Color(0xFF6A756B),
                            ),
                          ),
                        )
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
