import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_image.dart';
import '../models/shop_product.dart';
import '../providers/shop_provider.dart';
import '../widgets/cart_animation_helper.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ShopProduct product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  final GlobalKey _cartIconKey = GlobalKey();
  final GlobalKey _addButtonKey = GlobalKey();
  bool _cartBouncing = false;
  bool _justAdded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final shopProvider = Provider.of<ShopProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      body: CustomScrollView(
        slivers: [
          // Sliver AppBar với hình ảnh Hero lớn
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: const Color(0xFF364534),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              AnimatedScale(
                scale: _cartBouncing ? 1.28 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: IconButton(
                  key: _cartIconKey,
                  icon: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 20),
                      ),
                      if (shopProvider.cartCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${shopProvider.cartCount}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CustomImage(
                    imageUrl: p.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  if (p.tag.isNotEmpty)
                    Positioned(
                      top: 90,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F9D69),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          p.tag,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Nội dung chi tiết sản phẩm
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Danh mục và Tình trạng kho
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5F4EA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.category.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: const Color(0xFF2E6F40),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF9A825), size: 20),
                          const SizedBox(width: 4),
                          Text(
                            "${p.rating}",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2A21),
                            ),
                          ),
                          Text(
                            " (${p.soldCount} đã bán)",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF747871),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tên sản phẩm
                  Text(
                    p.name,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF191C19),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Giá
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        p.formattedPrice,
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2E6F40),
                        ),
                      ),
                      if (p.formattedOriginalPrice != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          p.formattedOriginalPrice!,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8C9388),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE0E5DD)),
                  const SizedBox(height: 16),

                  // Chỉ định điều trị bệnh cây (Chỉ có ở sản phẩm trị bệnh)
                  if (p.indications.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.healing_rounded, color: Color(0xFF2E6F40), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          "Chỉ định điều trị",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF191C19),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: p.indications.map((ind) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA5D6A7)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                ind,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Mô tả chi tiết
                  Text(
                    "Công dụng & Đặc tính",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF191C19),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF434940),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hướng dẫn sử dụng & Liều lượng
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.menu_book_rounded, color: Color(0xFF2E6F40), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Hướng dẫn pha & Sử dụng",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2A21),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.usageGuide,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF2E4532),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Đánh giá thực tế từ khách hàng
                  _buildCustomerReviewsSection(context, p),
                  const SizedBox(height: 100), // Khoảng trống cho Bottom Navigation Bar
                ],
              ),
            ),
          ),
        ],
      ),

      // Thanh Bottom Bar đặt mua
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // 1. Bộ chọn số lượng (màu sắc rõ nét, tương phản cao)
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0E5DD)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, size: 18, color: Color(0xFF2E6F40)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '$_quantity',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1F2A21),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF2E6F40)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // 2. Nút nhỏ: Thêm vào giỏ hàng (kèm hiệu ứng bay vào giỏ)
              Tooltip(
                message: 'Thêm vào giỏ hàng',
                child: InkWell(
                  key: _addButtonKey,
                  onTap: () {
                    setState(() => _justAdded = true);
                    Future.delayed(const Duration(milliseconds: 900), () {
                      if (mounted) setState(() => _justAdded = false);
                    });

                    CartAnimationHelper.playFlyToCart(
                      context: context,
                      sourceKey: _addButtonKey,
                      cartIconKey: _cartIconKey,
                      imageUrl: p.imageUrl,
                      onComplete: () {
                        if (!mounted) return;
                        setState(() => _cartBouncing = true);
                        Future.delayed(const Duration(milliseconds: 220), () {
                          if (mounted) setState(() => _cartBouncing = false);
                        });
                      },
                    );

                    shopProvider.addToCart(p, quantity: _quantity);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _justAdded ? const Color(0xFF2E6F40) : const Color(0xFFE5F4EA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _justAdded ? const Color(0xFF2E6F40) : const Color(0xFFA5D6A7),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _justAdded ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
                        color: _justAdded ? Colors.white : const Color(0xFF2E6F40),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Nút to: Mua ngay -> dẫn thẳng sang trang Giỏ hàng & Thanh toán
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      shopProvider.addToCart(p, quantity: _quantity);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                    icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                    label: Text(
                      "Mua ngay",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E6F40),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerReviewsSection(BuildContext context, ShopProduct product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review_outlined, color: Color(0xFF2E6F40), size: 22),
                const SizedBox(width: 8),
                Text(
                  "Đánh giá từ khách hàng",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF191C19),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('ProductReviews')
              .where('productId', isEqualTo: product.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Color(0xFF2E6F40)),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            final sortedDocs = List<QueryDocumentSnapshot>.from(docs)
              ..sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                return bTime.compareTo(aTime);
              });

            if (sortedDocs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E5DD)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.reviews_outlined, size: 36, color: Color(0xFF8C9388)),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có đánh giá nào',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF191C19),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hãy là người đầu tiên trải nghiệm và chia sẻ nhận xét về sản phẩm này nhé!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF747871)),
                    ),
                  ],
                ),
              );
            }

            // Tính điểm trung bình thực tế
            double totalStars = 0;
            for (final doc in sortedDocs) {
              final d = doc.data() as Map<String, dynamic>;
              totalStars += (d['rating'] as num?)?.toDouble() ?? 5.0;
            }
            final avgRating = (totalStars / sortedDocs.length).toStringAsFixed(1);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thẻ tóm tắt điểm
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E5DD)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Text(
                            avgRating,
                            style: GoogleFonts.inter(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF191C19),
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF9A825));
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${sortedDocs.length} đánh giá',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF747871)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Container(width: 1, height: 60, color: const Color(0xFFE0E5DD)),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đánh giá thực tế từ khách hàng Floria',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF191C19),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hình ảnh thực tế & phản hồi sau khi nhận hàng và chăm cây.',
                              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5A6657)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Danh sách nhận xét
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sortedDocs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final data = sortedDocs[idx].data() as Map<String, dynamic>;
                    final userName = (data['userName'] ?? 'Khách hàng Floria').toString();
                    final userAvatar = (data['userAvatar'] ?? '').toString();
                    final rating = (data['rating'] as num?)?.toInt() ?? 5;
                    final comment = (data['comment'] ?? '').toString();
                    final images = (data['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                    final dateStr = createdAt != null
                        ? '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}'
                        : 'Vừa xong';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE0E5DD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFE5F4EA),
                                backgroundImage: userAvatar.isNotEmpty ? NetworkImage(userAvatar) : null,
                                child: userAvatar.isEmpty
                                    ? Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'F',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF2E6F40)),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF191C19),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateStr,
                                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF8C9388)),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: List.generate(5, (sIdx) {
                                  return Icon(
                                    sIdx < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 15,
                                    color: sIdx < rating ? const Color(0xFFF9A825) : const Color(0xFFCBD5E1),
                                  );
                                }),
                              ),
                            ],
                          ),
                          if (comment.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              comment,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF2E382C),
                                height: 1.45,
                              ),
                            ),
                          ],
                          if (images.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 72,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: images.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 8),
                                itemBuilder: (context, iIdx) {
                                  final imgUrl = images[iIdx];
                                  return GestureDetector(
                                    onTap: () => _showFullImageDialog(context, imgUrl),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: SizedBox(
                                        width: 72,
                                        height: 72,
                                        child: CustomImage(imageUrl: imgUrl, fit: BoxFit.cover),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                child: CustomImage(imageUrl: imageUrl, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
