import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
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
  Timer? _hotTimer;
  int _hotIndex = 0;

  @override
  void initState() {
    super.initState();
    _hotTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() => _hotIndex++);
      }
    });
  }

  GlobalKey _keyForProduct(String productId) {
    return _addBtnKeys.putIfAbsent(productId, () => GlobalKey());
  }

  void _triggerAddToCart(ShopProduct product, ShopProvider provider) {
    if (product.isOutOfStock) {
      AppToast.show(
        context,
        context.tr('Sản phẩm tạm hết hàng.', 'This product is out of stock.'),
        isError: true,
      );
      return;
    }

    final added = provider.addToCart(product);
    if (!added) {
      AppToast.show(
        context,
        context.tr(
          'Đã đạt số lượng tối đa trong kho (${product.stock}).',
          'Reached max stock (${product.stock}).',
        ),
        isError: true,
      );
      return;
    }

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
  }

  List<Map<String, String>> _getCategories(BuildContext context) => [
    {'title': context.tr('Tất cả', 'All'), 'key': 'all'},
    {'title': context.tr('Thuốc trị bệnh', 'Medicine'), 'key': 'medicine'},
    {
      'title': context.tr('Phân bón & Dưỡng', 'Fertilizer'),
      'key': 'fertilizer',
    },
    {'title': context.tr('Dụng cụ', 'Tools'), 'key': 'tools'},
    {'title': context.tr('Đất trồng', 'Soil'), 'key': 'soil'},
  ];

  @override
  void dispose() {
    _hotTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shopProvider = Provider.of<ShopProvider>(context);
    final products = shopProvider.filteredProducts;
    final categories = _getCategories(context);

    return Scaffold(
      backgroundColor: c.background,
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
                            context.tr(
                              'VẬT TƯ & DƯỢC PHẨM CÂY TRỒNG',
                              'SUPPLIES & PLANT CARE',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: c.textMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('Cửa hàng', 'Shop'),
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: c.textPrimary,
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
                          message: context.tr('Đơn mua của tôi', 'My Orders'),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OrderHistoryScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: c.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.shadow.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  color: c.primaryText,
                                  size: 21,
                                ),
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
                                MaterialPageRoute(
                                  builder: (_) => const CartScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _cartBouncing
                                    ? c.surfaceTint
                                    : c.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _cartBouncing
                                      ? c.primaryText
                                      : c.border,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.shadow.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    color: c.primaryText,
                                    size: 21,
                                  ),
                                  const SizedBox(width: 5),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    transitionBuilder: (child, anim) =>
                                        ScaleTransition(
                                          scale: anim,
                                          child: child,
                                        ),
                                    child: Text(
                                      '${shopProvider.cartCount}',
                                      key: ValueKey<int>(
                                        shopProvider.cartCount,
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: c.primaryText,
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
                    color: c.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      color: c.textPrimary,
                      fontSize: 13,
                    ),
                    onChanged: (val) => shopProvider.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: context.tr(
                        "Tìm thuốc trị nấm, rệp, kéo tỉa, đất...",
                        "Search fungicides, neem oil, shears, soil...",
                      ),
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: c.textMuted,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: c.textMuted,
                      ),
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

                // Banner Sản phẩm HOT (tự chuyển mỗi 10s nếu có nhiều hơn 1 sản phẩm hot)
                Builder(
                  builder: (context) {
                    final hotProducts = shopProvider.products.where((p) {
                      if (!p.visible) return false;
                      final t = p.tag.toLowerCase();
                      return t.contains('hot') || t.contains('nổi bật') || t.contains('featured');
                    }).toList();
                    final activeHot = hotProducts.isNotEmpty
                        ? hotProducts[_hotIndex % hotProducts.length]
                        : null;
                    final bannerImage = activeHot != null && activeHot.imageUrl.isNotEmpty
                        ? activeHot.imageUrl
                        : 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=800&auto=format&fit=crop&q=80';
                    final badgeLabel = activeHot != null
                        ? context.tr('Sản phẩm HOT', 'HOT Product')
                        : context.tr('Dược phẩm sinh học', 'Biological Products');
                    final titleLabel = activeHot != null
                        ? activeHot.name
                        : context.tr('Bộ Đôi Khắc Tinh Bệnh Lá & Sâu Hại', 'Leaf Disease & Pest Control Duo');
                    final subtitleLabel = activeHot != null
                        ? (activeHot.shortDesc.isNotEmpty
                            ? activeHot.shortDesc
                            : '${activeHot.price.toStringAsFixed(0)}đ')
                        : context.tr(
                            'Nano Bạc Đồng & Tinh dầu Neem giúp bảo vệ cây toàn diện không độc hại.',
                            'Nano Silver Copper & Neem Oil provide non-toxic, total plant protection.',
                          );

                    return GestureDetector(
                      onTap: activeHot != null
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(product: activeHot),
                                ),
                              );
                            }
                          : null,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        child: Container(
                          key: ValueKey(activeHot?.id ?? 'default_banner'),
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: c.shadow.withValues(alpha: 0.06),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomImage(
                                  imageUrl: bannerImage,
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
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: activeHot != null
                                                  ? const Color(0xFFD97706)
                                                  : const Color(0xFF4F9D69),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              badgeLabel,
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (hotProducts.length > 1)
                                            Row(
                                              children: List.generate(hotProducts.length, (i) {
                                                final isSelected = i == (_hotIndex % hotProducts.length);
                                                return Container(
                                                  margin: const EdgeInsets.only(left: 4),
                                                  width: isSelected ? 16 : 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.white.withValues(alpha: 0.45),
                                                    borderRadius: BorderRadius.circular(99),
                                                  ),
                                                );
                                              }),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        titleLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitleLabel,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Danh mục Categories
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected =
                          shopProvider.selectedCategoryKey == cat['key'];

                      return GestureDetector(
                        onTap: () => shopProvider.setCategory(cat['key']!),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (c.isDark
                                      ? c.primaryText
                                      : const Color(0xFF364534))
                                : c.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? (c.isDark
                                        ? c.primaryText
                                        : const Color(0xFF364534))
                                  : c.border,
                            ),
                          ),
                          child: Text(
                            cat['title']!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? (c.isDark ? Colors.black : Colors.white)
                                  : c.textSecondary,
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
                  _buildShopSkeleton(context)
                else if (products.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        context.tr(
                          "Không tìm thấy sản phẩm nào phù hợp.",
                          "No matching products found.",
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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

  Widget _buildShopSkeleton(BuildContext context) {
    final c = context.colors;
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
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
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
                        ShimmerLoading(
                          width: 28,
                          height: 28,
                          shape: BoxShape.circle,
                        ),
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

  Widget _buildProductCard(
    BuildContext context,
    ShopProduct product,
    ShopProvider provider,
  ) {
    final c = context.colors;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: c.shadow.withValues(alpha: 0.04),
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
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
                if (product.isOutOfStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB91C1C).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr('HẾT HÀNG', 'OUT OF STOCK'),
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
                        color: c.textPrimary,
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
                        color: c.textMuted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Đánh giá sao thật và số lượng đã bán
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product.isOutOfStock
                                ? context.tr('• Hết hàng', '• Out of stock')
                                : '${context.tr('• Đã bán ', '• Sold ')}${product.soldCount} · ${context.tr('Còn ', '')}${product.stock}',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: product.isOutOfStock
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: product.isOutOfStock
                                  ? const Color(0xFFBA1A1A)
                                  : c.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                                  color: c.primaryText,
                                ),
                              ),
                              if (product.formattedOriginalPrice != null)
                                Text(
                                  product.formattedOriginalPrice!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: c.textMuted,
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
                              color: product.isOutOfStock
                                  ? c.surfaceMuted
                                  : _justAddedIds.contains(product.id)
                                  ? const Color(0xFF2E6F40)
                                  : c.surfaceTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              product.isOutOfStock
                                  ? Icons.remove_shopping_cart_outlined
                                  : _justAddedIds.contains(product.id)
                                  ? Icons.check_rounded
                                  : Icons.add_shopping_cart_rounded,
                              size: 16,
                              color: product.isOutOfStock
                                  ? c.textMuted
                                  : _justAddedIds.contains(product.id)
                                  ? Colors.white
                                  : c.primaryText,
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
