import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_image.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../models/shop_product.dart';
import '../providers/shop_provider.dart';
import '../widgets/cart_animation_helper.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _cartIconKey = GlobalKey();
  final Map<String, GlobalKey> _addBtnKeys = {};
  final Set<String> _justAddedIds = {};
  bool _cartBouncing = false;

  GlobalKey _keyForProduct(String productId) {
    return _addBtnKeys.putIfAbsent(productId, () => GlobalKey());
  }

  void _triggerAddToCart(ShopProduct product, ShopProvider provider) {
    final sourceKey = _keyForProduct(product.id);
    setState(() => _justAddedIds.add(product.id));
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _justAddedIds.remove(product.id));
    });

    CartAnimationHelper.playFlyToCart(
      context: context,
      sourceKey: sourceKey,
      cartIconKey: _cartIconKey,
      imageUrl: product.imageUrl,
      onComplete: () {
        if (!mounted) return;
        setState(() => _cartBouncing = true);
        Future.delayed(const Duration(milliseconds: 220), () {
          if (mounted) setState(() => _cartBouncing = false);
        });
      },
    );

    provider.addToCart(product);
  }

  final List<Map<String, String>> _categories = [
    {'title': 'Tất cả', 'key': 'all'},
    {'title': 'Thuốc trị bệnh', 'key': 'medicine'},
    {'title': 'Phân bón & Dưỡng', 'key': 'fertilizer'},
    {'title': 'Dụng cụ', 'key': 'tools'},
    {'title': 'Đất trồng', 'key': 'soil'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    final products = shopProvider.filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => shopProvider.fetchProducts(),
          color: const Color(0xFF2E6F40),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header & Nút giỏ hàng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VẬT TƯ & DƯỢC PHẨM CÂY TRỒNG',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: const Color(0xFF6A756B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cửa hàng',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: const Color(0xFF1F2A21),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nút Lịch sử đơn hàng (icon tròn gọn gàng kèm badge số lượng)
                        Tooltip(
                          message: 'Đơn mua của tôi',
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE0E5DD)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.receipt_long_outlined, color: Color(0xFF2E6F40), size: 21),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Nút Giỏ hàng với hiệu ứng nảy khi có sản phẩm bay vào
                        AnimatedScale(
                          scale: _cartBouncing ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          child: InkWell(
                            key: _cartIconKey,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: _cartBouncing ? const Color(0xFFE5F4EA) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _cartBouncing ? const Color(0xFF2E6F40) : const Color(0xFFE0E5DD),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shopping_bag_outlined, color: Color(0xFF2E6F40), size: 21),
                                  const SizedBox(width: 5),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                    child: Text(
                                      '${shopProvider.cartCount}',
                                      key: ValueKey<int>(shopProvider.cartCount),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF2E6F40),
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
                  ],
                ),
                const SizedBox(height: 16),

                // Thanh tìm kiếm sản phẩm
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE0E5DD)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => shopProvider.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: "Tìm thuốc trị nấm, rệp, kéo tỉa, đất...",
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8C9388)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6A756B)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                shopProvider.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Banner Bác sĩ cây khuyên dùng
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF17231A).withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomImage(
                          imageUrl: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=800&auto=format&fit=crop&q=80',
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
                                Colors.transparent,
                                const Color(0xFF18221B).withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F9D69),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '🛡️ Dược phẩm sinh học',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Bộ Đôi Khắc Tinh Bệnh Lá & Sâu Hại',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nano Bạc Đồng & Tinh dầu Neem giúp bảo vệ cây toàn diện không độc hại.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Danh mục Categories
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = shopProvider.selectedCategoryKey == cat['key'];

                      return GestureDetector(
                        onTap: () => shopProvider.setCategory(cat['key']!),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF364534) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF364534) : const Color(0xFFE0E5DD),
                            ),
                          ),
                          child: Text(
                            cat['title']!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF434940),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Danh sách sản phẩm (Product Grid)
                if (shopProvider.isLoading)
                  _buildShopSkeleton()
                else if (products.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        "Không tìm thấy sản phẩm nào phù hợp.",
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF747871)),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(context, product, shopProvider);
                    },
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.65,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E5DD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerLoading(
                height: 130,
                width: double.infinity,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerLoading(width: 60, height: 10),
                    const SizedBox(height: 8),
                    const ShimmerLoading(width: double.infinity, height: 14),
                    const SizedBox(height: 6),
                    const ShimmerLoading(width: 80, height: 14),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        ShimmerLoading(width: 60, height: 16),
                        ShimmerLoading(width: 28, height: 28, shape: BoxShape.circle),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, ShopProduct product, ShopProvider provider) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E5DD)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: CustomImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (product.tag.isNotEmpty)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E6F40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.tag,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Thông tin chi tiết
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF191C19),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.shortDesc,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF747871),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Đánh giá sao thật và số lượng đã bán
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF191C19),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• Đã bán ${product.soldCount}',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            color: const Color(0xFF747871),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Giá và nút thêm giỏ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                product.formattedPrice,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2E6F40),
                                ),
                              ),
                              if (product.formattedOriginalPrice != null)
                                Text(
                                  product.formattedOriginalPrice!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF8C9388),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        InkWell(
                          key: _keyForProduct(product.id),
                          onTap: () => _triggerAddToCart(product, provider),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _justAddedIds.contains(product.id)
                                  ? const Color(0xFF2E6F40)
                                  : const Color(0xFFE5F4EA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _justAddedIds.contains(product.id)
                                  ? Icons.check_rounded
                                  : Icons.add_shopping_cart_rounded,
                              size: 16,
                              color: _justAddedIds.contains(product.id)
                                  ? Colors.white
                                  : const Color(0xFF2E6F40),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
