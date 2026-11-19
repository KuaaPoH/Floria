import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/custom_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/models/user_checkout_models.dart';
import '../../profile/screens/address_payment_screen.dart';
import '../models/shop_product.dart';
import '../providers/shop_provider.dart';
import 'order_history_screen.dart';
import 'zalopay_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> selectedItems;

  const CheckoutScreen({super.key, required this.selectedItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _voucherCtrl = TextEditingController();
  String _selectedPaymentOption = 'zalopay';
  bool _isCheckingVoucher = false;
  bool _isPlacingOrder = false;

  String? _appliedVoucherCode;
  String? _appliedVoucherDocId;
  String? _appliedVoucherDesc;
  int _discountAmount = 0;
  List<Map<String, dynamic>> _availableVouchers = [];

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    final sp = Provider.of<ShopProvider>(context, listen: false);
    final list = await sp.fetchActiveVouchers();
    if (mounted) {
      setState(() => _availableVouchers = list);
    }
  }

  @override
  void dispose() {
    _voucherCtrl.dispose();
    super.dispose();
  }

  int get _subtotal =>
      widget.selectedItems.fold<int>(0, (sum, item) => sum + item.totalPrice);

  int get _finalTotal => max(0, _subtotal - _discountAmount);

  Future<void> _applyVoucher(ShopProvider shopProvider) async {
    final code = _voucherCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      AppToast.show(
        context,
        context.tr('Vui lòng nhập mã giảm giá!', 'Please enter a promo code!'),
        isError: true,
      );
      return;
    }

    setState(() => _isCheckingVoucher = true);
    final res = await shopProvider.validateVoucher(code, _subtotal);
    if (!mounted) return;
    setState(() => _isCheckingVoucher = false);

    if (res == null) {
      AppToast.show(
        context,
        context.tr('Mã giảm giá không hợp lệ hoặc đã hết hạn.', 'Invalid or expired promo code.'),
        isError: true,
      );
      return;
    }

    if (res['valid'] != true) {
      AppToast.show(
        context,
        res['reason']?.toString() ?? context.tr('Chưa đủ điều kiện áp dụng mã.', 'Order does not meet voucher requirements.'),
        isError: true,
      );
      return;
    }

    setState(() {
      _appliedVoucherCode = res['code']?.toString();
      _appliedVoucherDocId = res['voucherDocId']?.toString();
      _appliedVoucherDesc = res['description']?.toString();
      _discountAmount = (res['discountAmount'] as int?) ?? 0;
    });
    AppToast.show(
      context,
      context.tr('Đã áp dụng mã $_appliedVoucherCode!', 'Applied code $_appliedVoucherCode!'),
    );
  }

  void _removeVoucher() {
    setState(() {
      _appliedVoucherCode = null;
      _appliedVoucherDocId = null;
      _appliedVoucherDesc = null;
      _discountAmount = 0;
      _voucherCtrl.clear();
    });
  }

  Future<void> _handlePlaceOrder({
    required ShopProvider shopProvider,
    required ShippingAddress? activeAddress,
  }) async {
    final c = context.colors;
    if (activeAddress == null) {
      AppToast.show(
        context,
        context.tr('Vui lòng thêm địa chỉ nhận hàng trước khi đặt đơn!', 'Please add a shipping address before placing an order!'),
        isError: true,
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddressAndPaymentScreen()),
      );
      return;
    }

    final isZaloPay = _selectedPaymentOption != 'cod';
    String paymentMethod = 'cod';
    String paymentLabel = context.tr('Thanh toán khi nhận hàng (COD)', 'Cash on Delivery (COD)');

    if (isZaloPay) {
      paymentMethod = 'zalopay';
      paymentLabel = 'ZaloPay';

      final now = DateTime.now();
      final tempCode =
          'FLR${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8)}';

      final bool? paymentSuccess = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ZaloPayPaymentScreen(
            orderId: tempCode,
            amount: _finalTotal.toDouble(),
            formattedAmount: shopProvider.formatCurrency(_finalTotal),
            orderInfo: 'Floria - Thanh toan don $tempCode',
          ),
        ),
      );

      if (paymentSuccess != true) return;
    }

    if (!mounted) return;
    setState(() => _isPlacingOrder = true);
    try {
      final createdOrder = await shopProvider.placeOrder(
        address: activeAddress,
        paymentMethod: paymentMethod,
        paymentLabel: paymentLabel,
        itemsToOrder: widget.selectedItems,
        discountAmount: _discountAmount,
        voucherCode: _appliedVoucherCode,
        voucherDocId: _appliedVoucherDocId,
      );
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);

      if (createdOrder == null) {
        AppToast.show(
          context,
          shopProvider.errorMessage ??
              context.tr('Không thể tạo đơn hàng. Vui lòng thử lại!', 'Could not create order. Please try again!'),
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
                decoration: BoxDecoration(color: c.surfaceTint, shape: BoxShape.circle),
                child: Icon(Icons.check_circle_rounded, color: c.primary, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Đặt hàng thành công!', 'Order Placed Successfully!'),
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: c.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                '${context.tr("Mã đơn", "Order Code")}: #${createdOrder.orderCode}',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.primary),
              ),
              if (createdOrder.paymentMethod == 'zalopay') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0068FF).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0068FF)),
                      const SizedBox(width: 5),
                      Text(
                        context.tr('ĐÃ THANH TOÁN QUA ZALOPAY', 'PAID VIA ZALOPAY'),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0068FF),
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
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${createdOrder.recipientName} • ${createdOrder.recipientPhone}',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      createdOrder.shippingAddress,
                      style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${context.tr("Thanh toán", "Payment")}: ${createdOrder.paymentLabel}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); // đóng dialog
                    Navigator.pop(context); // thoát Checkout
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    context.tr('Xem đơn hàng của tôi', 'View My Orders'),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  context.tr('Tiếp tục mua sắm', 'Continue Shopping'),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: c.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      AppToast.show(
        context,
        '${context.tr("Lỗi tạo đơn hàng:", "Order error:")} $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shopProvider = Provider.of<ShopProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final ShippingAddress? activeAddress = authProvider.defaultAddress;

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
          context.tr('Thanh toán', 'Checkout'),
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: c.textPrimary),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Địa chỉ nhận hàng
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: c.primary, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                context.tr('ĐỊA CHỈ NHẬN HÀNG', 'SHIPPING ADDRESS'),
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.7,
                                  color: c.primary,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AddressAndPaymentScreen()),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: c.surfaceTint, borderRadius: BorderRadius.circular(10)),
                              child: Text(
                                activeAddress != null
                                    ? context.tr('Chỉnh sửa', 'Edit')
                                    : context.tr('Thêm địa chỉ', 'Add Address'),
                                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: c.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (activeAddress != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${activeAddress.recipientName} • ${activeAddress.phone} (${activeAddress.label})',
                              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.textPrimary),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              activeAddress.address,
                              style: GoogleFonts.inter(fontSize: 12.5, color: c.textSecondary, height: 1.35),
                            ),
                          ],
                        )
                      else
                        Text(
                          context.tr('Chưa có địa chỉ nhận hàng. Bấm "Thêm địa chỉ" để tiếp tục.', 'No shipping address yet.'),
                          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFBA1A1A)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Sản phẩm đã chọn mua
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr("SẢN PHẨM THANH TOÁN", "ITEMS")} (${widget.selectedItems.length})',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: c.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...widget.selectedItems.map((item) {
                        final p = item.product;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CustomImage(
                                  imageUrl: p.imageUrl,
                                  width: 52,
                                  height: 52,
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
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.formattedPrice} × ${item.quantity}',
                                      style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                shopProvider.formatCurrency(item.totalPrice),
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Form nhập mã giảm giá
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.confirmation_number_outlined, color: c.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('MÃ GIẢM GIÁ', 'PROMO CODE'),
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_appliedVoucherCode != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: c.surfaceTint,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.primary.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: c.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_appliedVoucherCode (-${shopProvider.formatCurrency(_discountAmount)})',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: c.primary,
                                      ),
                                    ),
                                    if (_appliedVoucherDesc != null)
                                      Text(
                                        _appliedVoucherDesc!,
                                        style: GoogleFonts.inter(fontSize: 11.5, color: c.textSecondary),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                color: c.textMuted,
                                onPressed: _removeVoucher,
                              ),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _voucherCtrl,
                                textCapitalization: TextCapitalization.characters,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: context.tr('Nhập mã giảm giá (nếu có)', 'Enter promo code'),
                                  hintStyle: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
                                  filled: true,
                                  fillColor: c.surfaceMuted,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: c.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: c.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: c.primary, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: _isCheckingVoucher ? null : () => _applyVoucher(shopProvider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _isCheckingVoucher
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      context.tr('Áp dụng', 'Apply'),
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ],
                        ),
                      if (_appliedVoucherCode == null && _availableVouchers.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _availableVouchers.map((v) {
                            final code = v['code']?.toString() ?? '';
                            final value = (v['value'] as int?) ?? 0;
                            final type = v['type']?.toString() ?? 'fixed';
                            final badgeText = type == 'percent'
                                ? '$code (-$value%)'
                                : '$code (-${shopProvider.formatCurrency(value)})';
                            return ActionChip(
                              avatar: Icon(Icons.local_offer_rounded, size: 14, color: c.primary),
                              label: Text(
                                badgeText,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.primaryText,
                                ),
                              ),
                              backgroundColor: c.surfaceTint,
                              side: BorderSide(color: c.primary.withValues(alpha: 0.25)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onPressed: _isCheckingVoucher
                                  ? null
                                  : () {
                                      _voucherCtrl.text = code;
                                      _applyVoucher(shopProvider);
                                    },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Phương thức thanh toán
                _buildCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('PHƯƠNG THỨC THANH TOÁN', 'PAYMENT METHOD'),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: c.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // ZaloPay (mở cổng thanh toán ZaloPay)
                      _buildPaymentOption(
                        context: context,
                        isSelected: _selectedPaymentOption == 'zalopay',
                        onTap: () => setState(() => _selectedPaymentOption = 'zalopay'),
                        icon: Icons.account_balance_wallet_outlined,
                        iconBg: const Color(0xFFEAF2FF),
                        iconColor: const Color(0xFF0068FF),
                        title: context.tr('Thanh toán qua ZaloPay', 'Pay via ZaloPay'),
                        subtitle: context.tr('Mở cổng thanh toán trực tuyến ZaloPay', 'Open ZaloPay online payment gateway'),
                      ),
                      // COD
                      _buildPaymentOption(
                        context: context,
                        isSelected: _selectedPaymentOption == 'cod',
                        onTap: () => setState(() => _selectedPaymentOption = 'cod'),
                        icon: Icons.payments_outlined,
                        iconBg: c.surfaceTint,
                        iconColor: c.primary,
                        title: context.tr('Thanh toán khi nhận hàng (COD)', 'Cash on Delivery (COD)'),
                        subtitle: context.tr('Thanh toán tiền mặt khi nhận hàng', 'Pay cash upon delivery'),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Chi tiết số tiền
                _buildCard(
                  context,
                  child: Column(
                    children: [
                      _buildPriceRow(
                        context,
                        context.tr('Tạm tính', 'Subtotal'),
                        shopProvider.formatCurrency(_subtotal),
                      ),
                      if (_discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow(
                          context,
                          context.tr('Giảm giá', 'Discount'),
                          '-${shopProvider.formatCurrency(_discountAmount)}',
                          valueColor: const Color(0xFF15803D),
                        ),
                      ],
                      Divider(height: 20, color: c.border),
                      _buildPriceRow(
                        context,
                        context.tr('Tổng thanh toán', 'Total Payment'),
                        shopProvider.formatCurrency(_finalTotal),
                        isBold: true,
                        valueColor: c.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Thanh đáy đặt hàng
          Container(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + MediaQuery.paddingOf(context).bottom),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('Tổng thanh toán', 'Total'),
                      style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
                    ),
                    Text(
                      shopProvider.formatCurrency(_finalTotal),
                      style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800, color: c.primary),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isPlacingOrder
                        ? null
                        : () => _handlePlaceOrder(
                              shopProvider: shopProvider,
                              activeAddress: activeAddress,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isPlacingOrder
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : Text(
                            _selectedPaymentOption == 'cod'
                                ? context.tr('Đặt hàng ngay', 'Place Order')
                                : context.tr('Thanh toán ZaloPay', 'Pay with ZaloPay'),
                            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: child,
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (c.isDark ? const Color(0xFF1B2A1E) : const Color(0xFFF2F9F4))
              : c.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? c.primary : c.border, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: c.primary, size: 20),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold ? c.textPrimary : c.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 16 : 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? c.textPrimary,
          ),
        ),
      ],
    );
  }
}
