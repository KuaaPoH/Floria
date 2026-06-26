import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['Tất cả', 'Trừ Sâu', 'Trị Nấm', 'Phân Bón', 'Dụng Cụ'];

  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Thuốc Trừ Nấm Bio-Alpha',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuAcpFMTnNXPCw62kbVO_hzUDDUD9PxuRbrqK8B-AA1sc_yxoNrvE2xzhMoJvK9p2g6qUOsK1QRCEApQDy-dKeSH2mOO7I5Qbgm3NVWNmFKcVWQRWhup6WnBfiavgMBVzudx4ENkCqoeIU5Arp9mkgfaPzDkzcU9TXq83yZahuJue9DZ_5F-iwtopE3Pcp8kM431D0t7qc_YqHYHOKzr6UsGXOX71myCZQf3G9Sx6eF1zjNipqG_agOY_7vLJ-Mz_11n9047mUNRPRY',
      'rating': 4.8,
      'price': '135.000 đ',
    },
    {
      'name': 'Phân Bón Hữu Cơ Nano-Grow',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuABnQkgUeQzfvppz2etDFiNLplcD2UiG87zNKl0Vj1_MLwOlRfrSLV_JhG6Mursb2pclHgHqmgDx_ANfGjZpmBCCjFx50nB8YdVBkKWvG-gP3NUCNv7wRTRREzEGbAq4NMZrVUNGHJAlaxpV7N8w-84pxjMJ1GxCR2UVNJhQLNbjrmoZtisTGH6tHdPJfU6TbE87ubKStFjboIJLW-VovN3C3ZEqEhgBPag9ZBU49Fi0YnUfEN_FhNTxgaok_tud0J67lJ694LHWkw',
      'rating': 4.9,
      'price': '210.000 đ',
    },
    {
      'name': 'Máy Đo Độ Ẩm Smart-Probe',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuD8gQtQ7rpv13wo5Xjpo8gDd7B-GyYllpARl0OWp64TxBFmG_t_QhyyLJVEh77g-YZvPnY_GQbX22yN0KR9EsPRya3c5i5GumnrZCdUOOEf02IdZ8mhKtXCXpzjHmp4pvhpWntg-Ffagmlg3VBbHmSXvwXBYxIbsz2G01uXgjFmvM-CC4q1nAK_GvA2kTrknOT6ETzL5qgSFa7hnKPgLMLLxEi7CHllTMc-k-zfFpHZ2mS-aLwHl6rwZVjh6SZxpSxhIoc6CuXylvQ',
      'rating': 4.7,
      'price': '450.000 đ',
    },
    {
      'name': 'Bộ Kéo Tỉa Cành Precision-X',
      'image': 'https://lh3.googleusercontent.com/aida-public/AB6AXuCMLU-E1YRQX44nJjxPa6KHq7WK1xNCZLM-TDkQZs9_MRYRBfdTKAohVuIFVDApVM4WCYyYdTULcH3v0mc0NZSUD-a-PGRpmP09sNa6gNjyzkwQoy7GLlbkP0PKWmV80zPuIfLj1eZqA3eRDBtvnu2m0qksMVpARsSalZzCChEC4kIrU4FwnrNjTb-rtNyIhal_Do7RahvodEBva1KF7gCa6kF7t7a70DuehGIesZpYHbv22bYOYI9J8S_jp4houNoFmAGzVvpNBUY',
      'rating': 4.6,
      'price': '89.000 đ',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FCEF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2FCEF).withValues(alpha: 0.6),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false, // Hide back button in nav bar
        title: Text(
          'Cửa Hàng',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF006D35),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF006D35), size: 28),
                  onPressed: () {},
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF2FCEF), width: 2),
                    ),
                    child: const Text(
                      '2',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: const Color(0xFF3B4A3D).withValues(alpha: 0.5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm thuốc, phân bón...',
                        hintStyle: GoogleFonts.beVietnamPro(color: const Color(0xFF3B4A3D).withValues(alpha: 0.4), fontSize: 16),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.beVietnamPro(color: const Color(0xFF151E16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Categories
            SizedBox(
              height: 40,
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
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF00E676) : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        boxShadow: isSelected
                            ? [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.4), blurRadius: 15)]
                            : null,
                      ),
                      child: Text(
                        _categories[index],
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFF00612E) : const Color(0xFF3B4A3D),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Promo Banner
            Container(
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E676), Color(0xFFFDFC47), Color(0xFFFFBA79)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 150,
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAvZ6YWt8t6aQlKPQdDLjPDtltWEJvTWvRjwSYi7ZrPN7mrFq_sjVH-WDVIZML9ZAQsXIQaDrW8X91sj7odNTg-Z6Rm6ACxhdZs6-lHOABuz1699ZB55HLCaOlTufvyjdeLQVL-vYoFOIaSX7XlS8jXF1Z7GuU53vYOD9N2IPt-FnJK3wqgco1aiaYVTuluzxLgMwWJgDz_Sa1y12yESfQve5M0KNT3aBrEtLMCkRKT8QBWPHTmVMBek7R3ILMCCbrdpQgsODpzfvc',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Giảm 20% Thuốc Trị Đốm Lá',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00612E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Áp dụng cho đơn hàng từ 500k',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 14,
                            color: const Color(0xFF00612E).withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00612E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Mua ngay',
                            style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Product Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gợi ý cho bạn',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF006D35),
                  ),
                ),
                Text(
                  'Xem tất cả',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF006D35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.55,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return _buildProductCard(product);
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                product['image'],
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            product['name'],
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF151E16),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Rating
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFF86521B), size: 14),
              const SizedBox(width: 4),
              Text(
                product['rating'].toString(),
                style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF3B4A3D)),
              )
            ],
          ),
          const Spacer(),
          // Price and Add
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    product['price'],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF006D35),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E676),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF00612E), size: 20),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
