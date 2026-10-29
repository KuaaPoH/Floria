import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/models/user_checkout_models.dart';
import '../../profile/screens/address_payment_screen.dart';
import '../providers/shop_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _selectedAddressId;
  // Giá trị: 'cod' hoặc id của thẻ đã lưu (VD: 'card_ncb_sandbox')
  String? _selectedPaymentOption;

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
      backgroundColor: const Color(0xFFF6F8F5),
      appBar: AppBar(
        title: Text(
          "Giỏ hàng & Thanh toán (${shopProvider.cartCount})",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF191C19),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF191C19), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFBA1A1A)),
              tooltip: "Xóa toàn bộ giỏ hàng",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: Text(
                      "Xác nhận xóa",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1F2A21)),
                    ),
                    content: Text(
                      "Bạn có chắc chắn muốn dọn sạch giỏ hàng không?",
                      style: GoogleFonts.inter(color: const Color(0xFF4A554C)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text("Hủy", style: GoogleFonts.inter(color: const Color(0xFF6A756B))),
                      ),
                      TextButton(
                        onPressed: () {
                          shopProvider.clearCart();
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          "Xóa sạch",
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5F4EA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_basket_outlined,
                      color: Color(0xFF3E8055),
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Giỏ hàng của bạn đang trống",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2A21),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Hãy khám phá các loại thuốc sinh học và vật tư chăm sóc cây nhé!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF747871),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF364534),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Khám phá cửa hàng ngay",
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
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
                                const Icon(Icons.location_on_rounded, color: Color(0xFF3E8055), size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  "ĐỊA CHỈ NHẬN HÀNG",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: const Color(0xFF3E8055),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _openAddressAndPaymentScreen,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5F4EA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF3E8055)),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Chỉnh sửa",
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF3E8055),
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
                                color: const Color(0xFFFFF8EB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.add_location_alt_outlined, color: Color(0xFFD97706), size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Bạn chưa có địa chỉ nhận hàng. Chạm vào đây để thêm địa chỉ!",
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
                                  color: isSelected ? const Color(0xFFF2F9F4) : const Color(0xFFF8FAF8),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF3E8055)
                                        : const Color(0xFF4F9D69).withValues(alpha: 0.15),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                      color: const Color(0xFF3E8055),
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
                                                    color: const Color(0xFF1F2A21),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "• ${addr.phone}",
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: const Color(0xFF6A756B),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE5F4EA),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  addr.label,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF3E8055),
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
                                              color: const Color(0xFF4A554C),
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
                      "SẢN PHẨM CHỌN MUA (${items.length})",
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: const Color(0xFF6A756B),
                      ),
                    ),
                  ),
                  ...items.map((item) {
                    final p = item.product;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
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
                                    color: const Color(0xFF191C19),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.formattedPrice,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2E6F40),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F0),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () => shopProvider.decreaseQuantity(p.id),
                                            borderRadius: BorderRadius.circular(8),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Icon(Icons.remove, size: 16, color: Color(0xFF1F2A21)),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '${item.quantity}',
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF1F2A21),
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => shopProvider.addToCart(p, quantity: 1),
                                            borderRadius: BorderRadius.circular(8),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Icon(Icons.add, size: 16, color: Color(0xFF1F2A21)),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
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
                                const Icon(Icons.payment_rounded, color: Color(0xFF3E8055), size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  "PHƯƠNG THỨC THANH TOÁN",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: const Color(0xFF3E8055),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _openAddressAndPaymentScreen,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5F4EA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF3E8055)),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Quản lý thẻ",
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF3E8055),
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
                                color: isSelected ? const Color(0xFFF2F9F4) : const Color(0xFFF8FAF8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF3E8055)
                                      : const Color(0xFF4F9D69).withValues(alpha: 0.15),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: const Color(0xFF3E8055),
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
                                        Text(
                                          card.bankName.replaceAll('(VNPay Sandbox)', '').trim(),
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1F2A21),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${card.maskedCardNumber} • ${card.cardHolder}",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF6A756B),
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
                                  ? const Color(0xFFF2F9F4)
                                  : const Color(0xFFF8FAF8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedPaymentOption == 'cod'
                                    ? const Color(0xFF3E8055)
                                    : const Color(0xFF4F9D69).withValues(alpha: 0.15),
                                width: _selectedPaymentOption == 'cod' ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedPaymentOption == 'cod'
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: const Color(0xFF3E8055),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F4EA),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.payments_outlined, color: Color(0xFF3E8055), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Thanh toán khi nhận hàng (COD)",
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1F2A21),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Kiểm tra vật tư và thanh toán tiền mặt khi nhận hàng",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF6A756B),
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tổng thanh toán",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF747871),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          shopProvider.formattedCartTotal,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2E6F40),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (activeAddress == null) {
                            _showModernToast(
                              "Vui lòng thêm địa chỉ nhận hàng trước khi đặt mua!",
                              isError: true,
                            );
                            _openAddressAndPaymentScreen();
                            return;
                          }

                          String paymentLabel = "Thanh toán khi nhận hàng (COD)";
                          if (_selectedPaymentOption != 'cod') {
                            final card = savedCards.firstWhere(
                              (c) => c.id == _selectedPaymentOption,
                              orElse: () => savedCards.first,
                            );
                            paymentLabel = "${card.bankName} (${card.maskedCardNumber})";
                          }

                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              contentPadding: const EdgeInsets.all(24),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE5F4EA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF2E6F40),
                                      size: 40,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Đặt hàng thành công!",
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF191C19),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F7F3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Người nhận: ${activeAddress!.recipientName} (${activeAddress.phone})",
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1F2A21),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Giao đến: ${activeAddress.address}",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF4A554C),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Thanh toán: $paymentLabel",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF2E6F40),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        shopProvider.clearCart();
                                        Navigator.pop(ctx);
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF364534),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text("Hoàn tất", style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF364534),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Đặt hàng ngay",
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
