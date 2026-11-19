import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/custom_image.dart';
import '../providers/shop_provider.dart';
import 'checkout_screen.dart';
import 'order_history_screen.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shopProvider = Provider.of<ShopProvider>(context);
    final cartItems = shopProvider.cartItems;
    final selectedItems = shopProvider.selectedCartItems;
    final isAllSelected = shopProvider.isAllCartSelected;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: c.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${context.tr("Giỏ hàng", "Cart")} (${shopProvider.cartCount})",
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: context.tr("Đơn hàng của tôi", "My Orders"),
            icon: Icon(Icons.receipt_long_outlined, color: c.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              );
            },
          ),
          if (cartItems.isNotEmpty)
            IconButton(
              tooltip: context.tr("Xóa hết giỏ hàng", "Clear Cart"),
              icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFBA1A1A)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: c.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      context.tr("Xóa giỏ hàng?", "Clear cart?"),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: c.textPrimary),
                    ),
                    content: Text(
                      context.tr("Bạn có chắc muốn bỏ toàn bộ sản phẩm trong giỏ hàng?", "Are you sure you want to remove all items from your cart?"),
                      style: GoogleFonts.inter(color: c.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(context.tr("Hủy", "Cancel"), style: GoogleFonts.inter(color: c.textMuted)),
                      ),
                      TextButton(
                        onPressed: () {
                          shopProvider.clearCart();
                          Navigator.pop(ctx);
                        },
                        child: Text(context.tr("Xóa hết", "Clear All"), style: GoogleFonts.inter(color: const Color(0xFFBA1A1A), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: c.isDark ? const Color(0xFF1E2D22) : const Color(0xFFE5F4EA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shopping_basket_outlined, color: c.primary, size: 44),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr("Giỏ hàng của bạn đang trống", "Your cart is empty"),
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr("Hãy khám phá các loại thuốc sinh học và vật tư chăm sóc cây nhé!", "Explore bio-solutions and plant care supplies!"),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, color: c.textMuted),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        context.tr("Khám phá cửa hàng ngay", "Explore Shop Now"),
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Thanh Chọn tất cả
                GestureDetector(
                  onTap: () => shopProvider.toggleSelectAllCart(!isAllSelected),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isAllSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isAllSelected ? c.primary : c.textMuted,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr("Chọn tất cả sản phẩm", "Select all items"),
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          "${selectedItems.length}/${cartItems.length} ${context.tr('mục', 'items')}",
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),

                // Danh sách sản phẩm trong giỏ có nút radio chọn mua
                ...cartItems.map((item) {
                  final p = item.product;
                  final isSelected = shopProvider.isCartItemSelected(p.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? c.primary.withValues(alpha: 0.45) : c.border,
                        width: isSelected ? 1.3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(color: c.shadow, blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => shopProvider.toggleCartItemSelection(p.id),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10, top: 8, bottom: 8),
                            child: Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? c.primary : c.textMuted,
                              size: 22,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CustomImage(
                              imageUrl: p.imageUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
                                ),
                                child: Text(
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.formattedPrice,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: c.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: c.surfaceMuted,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: c.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () => shopProvider.decreaseQuantity(p.id),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            child: Icon(Icons.remove, size: 16, color: c.textPrimary),
                                          ),
                                        ),
                                        Text(
                                          "${item.quantity}",
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: c.textPrimary,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            final added = shopProvider.addToCart(p, quantity: 1);
                                            if (!added) {
                                              AppToast.show(
                                                context,
                                                p.isOutOfStock
                                                    ? context.tr('Sản phẩm hiện đã hết hàng.', 'This product is out of stock.')
                                                    : context.tr('Đã đạt số lượng tối đa còn trong kho (${p.stock}).', 'Reached maximum stock (${p.stock}).'),
                                                isError: true,
                                              );
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            child: Icon(Icons.add, size: 16, color: c.textPrimary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFBA1A1A), size: 20),
                                    onPressed: () => shopProvider.removeFromCart(p.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
      bottomNavigationBar: cartItems.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr("Tổng thanh toán", "Total Payment"),
                        style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
                      ),
                      Text(
                        shopProvider.formattedSelectedTotal,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: c.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedItems.isEmpty) {
                          AppToast.show(
                            context,
                            context.tr("Vui lòng chọn ít nhất 1 sản phẩm để thanh toán!", "Please select at least 1 item to checkout!"),
                            isError: true,
                          );
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(selectedItems: selectedItems),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        "${context.tr("Thanh toán", "Checkout")} (${shopProvider.selectedCartCount})",
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
