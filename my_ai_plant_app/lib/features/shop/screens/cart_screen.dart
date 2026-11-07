import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/widgets/custom_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/models/user_checkout_models.dart';
import '../../profile/screens/address_payment_screen.dart';
import '../providers/shop_provider.dart';
import 'order_history_screen.dart';
import 'vnpay_payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _selectedAddressId;
  // Giá trị: 'cod' hoặc id của thẻ đã lưu (VD: 'card_ncb_sandbox')
  String? _selectedPaymentOption;
  bool _isPlacingOrder = false;

  void _showModernToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        duration: const Duration(seconds: 3),
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? const Color(0xFF2D1618) : const Color(0xFF1E2D22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isError
                      ? const Color(0xFFFF6B6B).withValues(alpha: 0.35)
                      : const Color(0xFF66BB6A).withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isError
                          ? const Color(0xFFFF6B6B).withValues(alpha: 0.18)
                          : const Color(0xFF4CAF50).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isError ? Icons.error_outline_rounded : Icons.check_rounded,
                      color: isError ? const Color(0xFFFF8A80) : const Color(0xFF81C784),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAddressAndPaymentScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressAndPaymentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shopProvider = Provider.of<ShopProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final items = shopProvider.cartItems;
    final addresses = authProvider.addresses;
    final savedCards = authProvider.savedCards;

    // Đồng bộ địa chỉ đang chọn với danh sách đã lưu
    ShippingAddress? activeAddress;
    if (addresses.isNotEmpty) {
      if (_selectedAddressId != null && addresses.any((a) => a.id == _selectedAddressId)) {
        activeAddress = addresses.firstWhere((a) => a.id == _selectedAddressId);
      } else {
        activeAddress = authProvider.defaultAddress;
        _selectedAddressId = activeAddress?.id;
      }
    }

    // Đồng bộ phương thức thanh toán đang chọn
    if (_selectedPaymentOption == null ||
        (_selectedPaymentOption != 'cod' && !savedCards.any((c) => c.id == _selectedPaymentOption))) {
      _selectedPaymentOption = authProvider.defaultCard?.id ?? 'cod';
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text(
          "${context.tr('Giỏ hàng & Thanh toán', 'Cart & Checkout')} (${shopProvider.cartCount})",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        backgroundColor: c.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.receipt_long_outlined, color: c.primary),
            tooltip: context.tr("Lịch sử đơn hàng", "Order History"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
              );
            },
          ),
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFBA1A1A)),
              tooltip: context.tr("Xóa toàn bộ giỏ hàng", "Clear Cart"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: c.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: Text(
                      context.tr("Xác nhận xóa", "Confirm Clear"),
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: c.textPrimary),
                    ),
                    content: Text(
                      context.tr("Bạn có chắc chắn muốn dọn sạch giỏ hàng không?", "Are you sure you want to clear your cart?"),
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
                        child: Text(
                          context.tr("Xóa sạch", "Clear"),
                          style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: items.isEmpty
          ? Center(
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
                    child: Icon(
                      Icons.shopping_basket_outlined,
                      color: c.primary,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr("Giỏ hàng của bạn đang trống", "Your cart is empty"),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr("Hãy khám phá các loại thuốc sinh học và vật tư chăm sóc cây nhé!", "Explore bio-solutions and plant care supplies!"),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: c.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.tr("Khám phá cửa hàng ngay", "Explore Shop Now"),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ================= 1. KHỐI ĐỊA CHỈ NHẬN HÀNG =================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.border),
                      boxShadow: [
                        BoxShadow(
                          color: c.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, color: c.primary, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr("ĐỊA CHỈ NHẬN HÀNG", "SHIPPING ADDRESS"),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: c.primary,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _openAddressAndPaymentScreen,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: c.surfaceTint,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_outlined, size: 13, color: c.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      context.tr("Chỉnh sửa", "Edit"),
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: c.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (addresses.isEmpty)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _openAddressAndPaymentScreen,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: c.warningBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.add_location_alt_outlined, color: Color(0xFFD97706), size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      context.tr(
                                        "Bạn chưa có địa chỉ nhận hàng. Chạm vào đây để thêm địa chỉ!",
                                        "No shipping address yet. Tap here to add one!",
                                      ),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFD97706)),
                                ],
                              ),
                            ),
                          )
                        else
                          ...addresses.map((addr) {
                            final isSelected = addr.id == activeAddress?.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedAddressId = addr.id),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (c.isDark ? const Color(0xFF1B2A1E) : const Color(0xFFF2F9F4))
                                      : c.surfaceMuted,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? c.primary : c.border,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                      color: c.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  addr.recipientName,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: c.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "• ${addr.phone}",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: c.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: c.surfaceTint,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  addr.label,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: c.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            addr.address,
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5,
                                              color: c.textSecondary,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ================= 2. DANH SÁCH VẬT TƯ TRONG GIỎ =================
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      "${context.tr('SẢN PHẨM CHỌN MUA', 'SELECTED ITEMS')} (${items.length})",
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                  ...items.map((item) {
                    final p = item.product;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border),
                        boxShadow: [
                          BoxShadow(
                            color: c.shadow,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CustomImage(
                              imageUrl: p.imageUrl,
                              width: 76,
                              height: 76,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary,
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
                                      ),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () => shopProvider.decreaseQuantity(p.id),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Icon(Icons.remove, size: 16, color: c.textPrimary),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '${item.quantity}',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: c.textPrimary,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => shopProvider.addToCart(p, quantity: 1),
                                            borderRadius: BorderRadius.circular(8),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

                  const SizedBox(height: 8),

                  // ================= 3. PHƯƠNG THỨC THANH TOÁN =================
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.border),
                      boxShadow: [
                        BoxShadow(
                          color: c.shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.payment_rounded, color: c.primary, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  context.tr("PHƯƠNG THỨC THANH TOÁN", "PAYMENT METHOD"),
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: c.primary,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _openAddressAndPaymentScreen,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: c.surfaceTint,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_outlined, size: 13, color: c.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      context.tr("Quản lý thẻ", "Manage Cards"),
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: c.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Danh sách các thẻ đã lưu
                        ...savedCards.map((card) {
                          final isSelected = _selectedPaymentOption == card.id;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedPaymentOption = card.id),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (c.isDark ? const Color(0xFF1B2A1E) : const Color(0xFFF2F9F4))
                                    : c.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? c.primary : c.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: c.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF2FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.credit_card_rounded, color: Color(0xFF005BAA), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              card.bankName.replaceAll('(VNPay Sandbox)', '').trim(),
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: c.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEAF2FF),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFF005BAA).withValues(alpha: 0.2)),
                                              ),
                                              child: Text(
                                                "VNPay Sandbox",
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF005BAA),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${card.maskedCardNumber} • ${card.cardHolder}",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: c.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        // Tùy chọn Thanh toán khi nhận hàng (COD)
                        GestureDetector(
                          onTap: () => setState(() => _selectedPaymentOption = 'cod'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedPaymentOption == 'cod'
                                  ? (c.isDark ? const Color(0xFF1B2A1E) : const Color(0xFFF2F9F4))
                                  : c.surfaceMuted,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedPaymentOption == 'cod' ? c.primary : c.border,
                                width: _selectedPaymentOption == 'cod' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedPaymentOption == 'cod'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: c.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: c.surfaceTint,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.payments_outlined, color: c.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr("Thanh toán khi nhận hàng (COD)", "Cash on Delivery (COD)"),
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.tr("Kiểm tra vật tư và thanh toán tiền mặt khi nhận hàng", "Inspect items and pay cash upon delivery"),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: c.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

      // Thanh tổng tiền & Thanh toán
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: c.surface,
                boxShadow: [
                  BoxShadow(
                    color: c.shadow,
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr("Tổng thanh toán", "Total Payment"),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: c.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shopProvider.formattedCartTotal,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: c.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isPlacingOrder
                            ? null
                            : () async {
                                if (activeAddress == null) {
                                  _showModernToast(
                                    context.tr(
                                      "Vui lòng thêm địa chỉ nhận hàng trước khi đặt mua!",
                                      "Please add a shipping address before ordering!",
                                    ),
                                    isError: true,
                                  );
                                  _openAddressAndPaymentScreen();
                                  return;
                                }

                                final failOrderMsg = context.tr("Không thể tạo đơn hàng. Vui lòng thử lại!", "Could not create order. Please try again!");
                                final isVnpay = _selectedPaymentOption != 'cod' && savedCards.isNotEmpty;
                                String paymentMethod = 'cod';
                                String paymentLabel = "Thanh toán khi nhận hàng (COD)";

                                if (isVnpay) {
                                  final card = savedCards.firstWhere(
                                    (c) => c.id == _selectedPaymentOption,
                                    orElse: () => savedCards.first,
                                  );
                                  paymentMethod = 'vnpay';
                                  paymentLabel =
                                      "VNPay Sandbox (${card.bankName.replaceAll('(VNPay Sandbox)', '').trim()})";

                                  // Mở Cổng thanh toán trực tuyến VNPay Sandbox
                                  final now = DateTime.now();
                                  final tempCode = "FLR${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8)}";
                                  final bool? paymentSuccess = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VnpayPaymentScreen(
                                        orderId: tempCode,
                                        amount: shopProvider.cartTotalAmount.toDouble(),
                                        formattedAmount: shopProvider.formattedCartTotal,
                                        orderInfo: "Thanh toan don $tempCode",
                                      ),
                                    ),
                                  );

                                  if (paymentSuccess != true) {
                                    // Người dùng đã hủy giao dịch hoặc thanh toán không thành công
                                    return;
                                  }
                                }

                                if (!mounted) return;

                                setState(() => _isPlacingOrder = true);
                                try {
                                  final createdOrder = await shopProvider.placeOrder(
                                    address: activeAddress,
                                    paymentMethod: paymentMethod,
                                    paymentLabel: paymentLabel,
                                  );
                                  if (!mounted) return;
                                  setState(() => _isPlacingOrder = false);

                                  if (createdOrder == null) {
                                    _showModernToast(
                                      failOrderMsg,
                                      isError: true,
                                    );
                                    return;
                                  }

                                  if (!context.mounted) return;
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: c.surface,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      contentPadding: const EdgeInsets.all(24),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 70,
                                            height: 70,
                                            decoration: BoxDecoration(
                                              color: c.surfaceTint,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check_circle_rounded,
                                              color: c.primary,
                                              size: 40,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            context.tr("Đặt hàng thành công!", "Order Placed Successfully!"),
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: c.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${context.tr('Mã đơn', 'Order Code')}: #${createdOrder.orderCode}",
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: c.primary,
                                            ),
                                          ),
                                          if (createdOrder.paymentMethod == 'vnpay') ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEAF2FF),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFF005BAA).withValues(alpha: 0.25)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF005BAA)),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    "ĐÃ THANH TOÁN QUA VNPAY SANDBOX",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w700,
                                                      color: const Color(0xFF005BAA),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 12),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: c.surfaceMuted,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${context.tr('Người nhận', 'Recipient')}: ${createdOrder.recipientName} (${createdOrder.recipientPhone})",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: c.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "${context.tr('Giao đến', 'Ship to')}: ${createdOrder.shippingAddress}",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: c.textSecondary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "${context.tr('Thanh toán', 'Payment')}: ${createdOrder.paymentLabel}",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: c.primary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "${context.tr('Tổng cộng', 'Total')}: ${createdOrder.formattedTotal} (${createdOrder.totalItemsCount} ${context.tr('sản phẩm', 'items')})",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: c.textPrimary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                    Navigator.pop(context);
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: c.primary,
                                                    side: BorderSide(color: c.primary),
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    context.tr("Đóng", "Close"),
                                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                    Navigator.pushReplacement(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => const OrderHistoryScreen(),
                                                      ),
                                                    );
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: c.primary,
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    context.tr("Xem đơn hàng", "View Order"),
                                                    style: GoogleFonts.inter(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    setState(() => _isPlacingOrder = false);
                                    _showModernToast("Lỗi tạo đơn hàng: $e", isError: true);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isPlacingOrder
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                context.tr("Đặt hàng ngay", "Place Order Now"),
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
}
