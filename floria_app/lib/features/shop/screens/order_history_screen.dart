import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/custom_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/order_model.dart';
import '../providers/shop_provider.dart';
import 'cart_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String initialFilter;
  const OrderHistoryScreen({super.key, this.initialFilter = 'all'});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late String _selectedFilter;

  final List<Map<String, String>> _tabs = const [
    {'key': 'all', 'labelVi': 'Tất cả', 'labelEn': 'All'},
    {'key': 'pending', 'labelVi': 'Chờ xác nhận', 'labelEn': 'Pending'},
    {'key': 'shipping', 'labelVi': 'Đang giao', 'labelEn': 'Shipping'},
    {'key': 'completed', 'labelVi': 'Đã giao', 'labelEn': 'Delivered'},
    {'key': 'cancelled', 'labelVi': 'Đã hủy', 'labelEn': 'Cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  void _showToast(String message, {bool isError = false, VoidCallback? onViewCart}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        duration: const Duration(seconds: 3),
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? const Color(0xFF2D1618) : const Color(0xFF1E2D22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (isError ? const Color(0xFFFF6B6B) : const Color(0xFF66BB6A))
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                    color: isError ? const Color(0xFFFF8A80) : const Color(0xFF81C784),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (onViewCart != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        onViewCart();
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF3E8055),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        context.tr('Xem giỏ', 'View Cart'),
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min • $d/$m/$y';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'shipping':
        return const Color(0xFF0284C7);
      case 'completed':
        return const Color(0xFF15803D);
      case 'cancelled':
        return const Color(0xFFBA1A1A);
      default:
        return const Color(0xFFD97706);
    }
  }

  Color _statusBgColor(String status, bool isDark) {
    if (isDark) {
      switch (status) {
        case 'pending':
          return const Color(0xFF3D2E14);
        case 'shipping':
          return const Color(0xFF10283B);
        case 'completed':
          return const Color(0xFF13331C);
        case 'cancelled':
          return const Color(0xFF3D1414);
        default:
          return const Color(0xFF3D2E14);
      }
    }
    switch (status) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'shipping':
        return const Color(0xFFE0F2FE);
      case 'completed':
        return const Color(0xFFDCFCE7);
      case 'cancelled':
        return const Color(0xFFFFDAD6);
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'shipping':
        return Icons.local_shipping_outlined;
      case 'completed':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Future<void> _confirmCancelOrder(OrderModel order, ShopProvider provider) async {
    final c = context.colors;
    final successMsg = context.tr('Đã hủy đơn hàng #${order.orderCode}', 'Order #${order.orderCode} cancelled');
    final failMsg = context.tr('Không thể hủy đơn hàng. Vui lòng thử lại!', 'Could not cancel order. Please try again!');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('Hủy đơn hàng?', 'Cancel Order?'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: c.textPrimary),
        ),
        content: Text(
          context.tr(
            'Bạn có chắc muốn hủy đơn hàng #${order.orderCode} không?',
            'Are you sure you want to cancel order #${order.orderCode}?',
          ),
          style: GoogleFonts.inter(fontSize: 13.5, color: c.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('Không', 'No'), style: GoogleFonts.inter(color: c.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(context.tr('Hủy đơn', 'Cancel Order'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await provider.updateOrderStatus(order.id, 'cancelled');
      if (ok) {
        _showToast(successMsg);
      } else {
        _showToast(failMsg, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shopProvider = Provider.of<ShopProvider>(context);
    final allOrders = shopProvider.orders;
    final filteredOrders = _selectedFilter == 'all'
        ? allOrders
        : allOrders.where((o) => o.status == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('Lịch sử đơn hàng', 'Order History'),
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: context.tr('Giỏ hàng', 'Cart'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.shopping_bag_outlined, color: c.primary, size: 22),
                if (shopProvider.cartCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${shopProvider.cartCount}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Thanh lọc trạng thái đơn hàng
          Container(
            color: c.surface,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final key = tab['key']!;
                  final isSelected = _selectedFilter == key;
                  final count = key == 'all'
                      ? allOrders.length
                      : allOrders.where((o) => o.status == key).length;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? c.primary : c.surfaceMuted,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? c.primary : c.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr(tab['labelVi']!, tab['labelEn']!),
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : c.textSecondary,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.22)
                                    : c.surfaceTint,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : c.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Expanded(
            child: shopProvider.isOrdersLoading
                ? Center(child: CircularProgressIndicator(color: c.primary))
                : filteredOrders.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _buildOrderCard(context, order, shopProvider);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: c.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined, size: 40, color: c.primary),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Chưa có đơn hàng nào', 'No orders yet'),
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'Các đơn mua vật tư và chế phẩm chăm sóc cây của bạn sẽ hiển thị tại đây.',
                'Your plant care and supply orders will appear here.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: c.textMuted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, ShopProvider provider) {
    final c = context.colors;
    final sColor = _statusColor(order.status);
    final sBg = _statusBgColor(order.status, c.isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.shadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showOrderDetailSheet(order, provider),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dòng mã đơn + Trạng thái
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_mall_outlined, size: 17, color: c.primary),
                      const SizedBox(width: 6),
                      Text(
                        '#${order.orderCode}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: order.orderCode));
                          _showToast(context.tr('Đã sao chép mã đơn #${order.orderCode}', 'Copied order code #${order.orderCode}'));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.copy_rounded, size: 14, color: c.textMuted),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(order.status), size: 13, color: sColor),
                        const SizedBox(width: 4),
                        Text(
                          order.statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: sColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${context.tr("Đặt lúc", "Ordered at")} ${_formatDateTime(order.createdAt)}',
                style: GoogleFonts.inter(fontSize: 11.5, color: c.textMuted),
              ),

              // Thanh tiến trình 3 bước (nếu chưa hủy)
              if (order.status != 'cancelled') ...[
                const SizedBox(height: 12),
                _buildOrderStepIndicator(order.status),
              ],

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: c.border),
              ),

              // Danh sách sản phẩm (hiển thị tối đa 2 món, còn lại thu gọn)
              ...order.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: CustomImage(imageUrl: item.imageUrl, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
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
                                '${item.formattedPrice} × ${item.quantity}',
                                style: GoogleFonts.inter(fontSize: 12, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item.formattedSubtotal,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )),
              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '+ ${order.items.length - 2} ${context.tr("sản phẩm khác (Chạm để xem chi tiết)", "more items (Tap to view details)")}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ),

              Divider(height: 1, color: c.border),
              const SizedBox(height: 10),

              // Tổng tiền + Nút thao tác
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${context.tr("Tổng thanh toán", "Total Payment")} (${order.totalItemsCount} ${context.tr("món", "items")})',
                        style: GoogleFonts.inter(fontSize: 11.5, color: c.textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.formattedTotal,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (order.status == 'pending') ...[
                        OutlinedButton(
                          onPressed: () => _confirmCancelOrder(order, provider),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFBA1A1A),
                            side: const BorderSide(color: Color(0xFFFFB4AB)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            context.tr('Hủy đơn', 'Cancel'),
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final msg = context.tr('Đơn #${order.orderCode} đã hoàn tất! Bạn có thể đánh giá ngay.', 'Order #${order.orderCode} completed! You can review now.');
                            await provider.updateOrderStatus(order.id, 'completed');
                            _showToast(msg);
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                          label: Text(
                            context.tr('Nhận hàng', 'Received'),
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (order.status == 'shipping') ...[
                        ElevatedButton(
                          onPressed: () async {
                            final msg = context.tr('Cảm ơn bạn đã xác nhận nhận hàng!', 'Thank you for confirming receipt!');
                            await provider.updateOrderStatus(order.id, 'completed');
                            _showToast(msg);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            context.tr('Đã nhận hàng', 'Received'),
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (order.status == 'completed') ...[
                        if (order.isReviewed) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                            decoration: BoxDecoration(
                              color: c.isDark ? const Color(0xFF38290E) : const Color(0xFFFFF9E6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFD54F)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFE6A100)),
                                const SizedBox(width: 4),
                                Text(
                                  '${order.rating ?? 5}★ ${context.tr("Đã đánh giá", "Reviewed")}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: c.isDark ? const Color(0xFFFFD54F) : const Color(0xFF9E6500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          OutlinedButton.icon(
                            onPressed: () => _showReviewBottomSheet(order, provider),
                            icon: const Icon(Icons.star_outline_rounded, size: 14, color: Color(0xFFE6A100)),
                            label: Text(
                              context.tr('Đánh giá', 'Review'),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB26A00),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: c.isDark ? const Color(0xFF38290E) : const Color(0xFFFFF9E6),
                              side: const BorderSide(color: Color(0xFFFFD54F)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                      ElevatedButton.icon(
                        onPressed: () {
                          final added = provider.reorderFromOrder(order);
                          _showToast(
                            context.tr('Đã thêm lại $added sản phẩm vào giỏ hàng!', 'Added $added item(s) back to cart!'),
                            onViewCart: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.replay_rounded, size: 15),
                        label: Text(
                          context.tr('Mua lại', 'Reorder'),
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.surfaceTint,
                          foregroundColor: c.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStepIndicator(String status) {
    final c = context.colors;
    final step = status == 'completed'
        ? 3
        : status == 'shipping'
            ? 2
            : 1;

    Widget buildNode(int idx, String label) {
      final active = step >= idx;
      return Expanded(
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? c.primary : c.border,
              ),
              child: Icon(
                active ? Icons.check_rounded : Icons.circle,
                size: active ? 13 : 6,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? c.textPrimary : c.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          buildNode(1, context.tr('Chờ xác nhận', 'Pending')),
          buildNode(2, context.tr('Đang giao', 'Shipping')),
          buildNode(3, context.tr('Đã giao', 'Delivered')),
        ],
      ),
    );
  }

  void _showOrderDetailSheet(OrderModel order, ShopProvider provider) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${context.tr("Chi tiết đơn hàng", "Order Details")} #${order.orderCode}',
                      style: GoogleFonts.inter(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.border),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Địa chỉ nhận hàng
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 17, color: c.primary),
                                const SizedBox(width: 6),
                                Text(
                                  '${context.tr("ĐỊA CHỈ NHẬN HÀNG", "SHIPPING ADDRESS")} (${order.addressLabel})',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: c.primary,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${order.recipientName} • ${order.recipientPhone}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.shippingAddress,
                              style: GoogleFonts.inter(fontSize: 13, color: c.textMuted, height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.payments_outlined, size: 15, color: c.primary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '${context.tr("Thanh toán", "Payment")}: ${order.paymentLabel}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        '${context.tr("DANH SÁCH SẢN PHẨM", "PRODUCT LIST")} (${order.totalItemsCount})',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: c.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: CustomImage(imageUrl: item.imageUrl, fit: BoxFit.cover),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.formattedPrice} × ${item.quantity}',
                                        style: GoogleFonts.inter(fontSize: 12, color: c.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  item.formattedSubtotal,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      Divider(height: 20, color: c.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('Tổng cộng', 'Total'),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                          Text(
                            order.formattedTotal,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: c.primary,
                            ),
                          ),
                        ],
                      ),

                      // Chuyển trạng thái nhanh (tiện kiểm thử luồng giao hàng)
                      if (order.status == 'pending' || order.status == 'shipping') ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: c.surfaceTint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.flash_on_rounded, size: 18, color: c.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.tr('Công cụ thử nghiệm chuyển trạng thái:', 'Testing state tools:'),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: c.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (order.status == 'pending') ...[
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          final msg = context.tr('Đơn #${order.orderCode} đã chuyển sang Đang giao!', 'Order #${order.orderCode} changed to Shipping!');
                                          Navigator.pop(ctx);
                                          await provider.updateOrderStatus(order.id, 'shipping');
                                          _showToast(msg);
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: c.primary,
                                          side: BorderSide(color: c.primary),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text(
                                          context.tr('Đang giao', 'Shipping'),
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final msg = context.tr('Đơn #${order.orderCode} đã hoàn tất! Bạn có thể đánh giá ngay.', 'Order #${order.orderCode} completed! You can review now.');
                                        Navigator.pop(ctx);
                                        await provider.updateOrderStatus(order.id, 'completed');
                                        _showToast(msg);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: c.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text(
                                        context.tr('Hoàn tất đơn ngay', 'Complete Order Now'),
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (order.status == 'completed') ...[
                        const SizedBox(height: 20),
                        if (!order.isReviewed) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showReviewBottomSheet(order, provider);
                              },
                              icon: const Icon(Icons.star_rounded, color: Color(0xFFFFD54F)),
                              label: Text(
                                context.tr('Đánh giá đơn hàng này', 'Review this order'),
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: c.isDark ? const Color(0xFF38290E) : const Color(0xFFFFF9E6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFFD54F)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFE6A100), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${context.tr("Bạn đã đánh giá", "You reviewed")} ${order.rating ?? 5}/5 ${context.tr("sao", "stars")}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: c.isDark ? const Color(0xFFFFD54F) : const Color(0xFF9E6500),
                                        ),
                                      ),
                                      if (order.reviewNote != null && order.reviewNote!.isNotEmpty)
                                        Text(
                                          order.reviewNote!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(fontSize: 11.5, color: c.textPrimary),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReviewBottomSheet(OrderModel order, ShopProvider provider) {
    final c = context.colors;
    int selectedRating = 5;
    final Set<String> selectedTags = {'Sản phẩm chất lượng tốt', 'Đóng gói cẩn thận'};
    final commentController = TextEditingController();
    final List<_ReviewPhotoItem> attachedPhotos = [];
    final ImagePicker picker = ImagePicker();
    bool isSubmitting = false;

    final tags = [
      {'vi': 'Giao hàng rất nhanh', 'en': 'Fast delivery'},
      {'vi': 'Đóng gói cẩn thận', 'en': 'Careful packaging'},
      {'vi': 'Sản phẩm chất lượng tốt', 'en': 'High quality'},
      {'vi': 'Đúng mô tả', 'en': 'Matches description'},
      {'vi': 'Chăm cây hiệu quả', 'en': 'Effective care'},
      {'vi': 'Tư vấn nhiệt tình', 'en': 'Helpful support'},
    ];

    String ratingText(int r) {
      switch (r) {
        case 1:
          return context.tr('Chưa hài lòng 😞', 'Not satisfied 😞');
        case 2:
          return context.tr('Tạm ổn 😐', 'Fair 😐');
        case 3:
          return context.tr('Bình thường 🙂', 'Average 🙂');
        case 4:
          return context.tr('Hài lòng 😊', 'Satisfied 😊');
        case 5:
        default:
          return context.tr('Rất tuyệt vời! 🌟', 'Excellent! 🌟');
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickPhotos(ImageSource source) async {
              try {
                if (source == ImageSource.camera) {
                  final XFile? file = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 960,
                    maxHeight: 960,
                    imageQuality: 75,
                  );
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    final item = _ReviewPhotoItem(bytes: bytes, isUploading: true);
                    setSheetState(() => attachedPhotos.add(item));
                    final url = await StorageService.uploadToCloud(bytes);
                    setSheetState(() {
                      item.url = url;
                      item.isUploading = false;
                    });
                  }
                } else {
                  final List<XFile> files = await picker.pickMultiImage(
                    maxWidth: 960,
                    maxHeight: 960,
                    imageQuality: 75,
                  );
                  if (files.isNotEmpty) {
                    for (final f in files) {
                      if (attachedPhotos.length >= 5) break;
                      final bytes = await f.readAsBytes();
                      final item = _ReviewPhotoItem(bytes: bytes, isUploading: true);
                      setSheetState(() => attachedPhotos.add(item));
                      StorageService.uploadToCloud(bytes).then((url) {
                        try {
                          setSheetState(() {
                            item.url = url;
                            item.isUploading = false;
                          });
                        } catch (_) {}
                      });
                    }
                  }
                }
              } catch (e) {
                debugPrint('Lỗi chọn ảnh: $e');
              }
            }

            void showPhotoSourceDialog() {
              showModalBottomSheet(
                context: context,
                backgroundColor: c.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.camera_alt_outlined, color: c.primary),
                          title: Text(
                            context.tr('Chụp ảnh mới', 'Take new photo'),
                            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.textPrimary),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            pickPhotos(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.photo_library_outlined, color: c.primary),
                          title: Text(
                            context.tr('Chọn từ thư viện ảnh', 'Choose from gallery'),
                            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.textPrimary),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            pickPhotos(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 16,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${context.tr("Đánh giá đơn hàng", "Review Order")} #${order.orderCode}',
                      style: GoogleFonts.inter(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('Chia sẻ trải nghiệm sử dụng vật tư & chế phẩm của bạn', 'Share your experience using your care products'),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: c.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.items.map((e) => e.name).join(', '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: c.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${context.tr("Tổng cộng", "Total")} ${order.items.length} ${context.tr("món", "items")}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: c.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        final isFilled = star <= selectedRating;
                        return IconButton(
                          onPressed: () {
                            setSheetState(() => selectedRating = star);
                          },
                          icon: Icon(
                            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 38,
                            color: isFilled ? const Color(0xFFF9A825) : const Color(0xFFCBD5E1),
                          ),
                        );
                      }),
                    ),
                    Text(
                      ratingText(selectedRating),
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.tr('Điểm bạn hài lòng nhất:', 'What you liked most:'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((t) {
                        final tagVi = t['vi']!;
                        final isChecked = selectedTags.contains(tagVi);
                        return InkWell(
                          onTap: () {
                            setSheetState(() {
                              if (isChecked) {
                                selectedTags.remove(tagVi);
                              } else {
                                selectedTags.add(tagVi);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isChecked ? c.surfaceTint : c.surfaceMuted,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isChecked ? c.primary : c.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isChecked) ...[
                                  Icon(Icons.check_rounded, size: 14, color: c.primary),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  context.tr(tagVi, t['en']!),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isChecked ? FontWeight.w700 : FontWeight.w600,
                                    color: isChecked ? c.primary : c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Ô nhập cảm nhận chi tiết
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      cursorColor: c.primary,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: context.tr(
                          'Cây của bạn đã phát triển hoặc hồi phục thế nào? Hãy viết vài dòng chia sẻ nhé...',
                          'How has your plant grown or recovered? Share your thoughts...',
                        ),
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: c.textMuted,
                        ),
                        filled: true,
                        fillColor: c.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(color: c.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mục đính kèm hình ảnh thực tế (sử dụng Cloudinary Cloud)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Icon(Icons.photo_camera_back_outlined, size: 17, color: c.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${context.tr("Hình ảnh thực tế", "Photos")} (${attachedPhotos.length}/5):',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 72,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (attachedPhotos.length < 5) ...[
                            InkWell(
                              onTap: showPhotoSourceDialog,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: c.surfaceMuted,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: c.primary.withValues(alpha: 0.35),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, size: 22, color: c.primary),
                                    const SizedBox(height: 3),
                                    Text(
                                      context.tr('Thêm ảnh', 'Add photo'),
                                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: c.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          for (int i = 0; i < attachedPhotos.length; i++) ...[
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: c.border),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Image.memory(
                                      attachedPhotos[i].bytes,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                if (attachedPhotos[i].isUploading)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () {
                                      setSheetState(() => attachedPhotos.removeAt(i));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFD32F2F),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Nút gửi đánh giá
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (attachedPhotos.any((p) => p.isUploading)) {
                                  _showToast(context.tr('Ảnh đang được tải lên, vui lòng đợi trong giây lát...', 'Photo is uploading, please wait...'));
                                  return;
                                }

                                setSheetState(() => isSubmitting = true);
                                final combinedNote = [
                                  if (selectedTags.isNotEmpty) 'Ưu điểm: ${selectedTags.join(", ")}',
                                  if (commentController.text.trim().isNotEmpty) commentController.text.trim(),
                                ].join('\n');

                                final imageUrls = attachedPhotos.map((p) => p.url).whereType<String>().toList();
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                final userName = (authProvider.userName?.trim().isNotEmpty == true)
                                    ? authProvider.userName!.trim()
                                    : (authProvider.userEmail?.split('@').first ?? 'Khách hàng Floria');
                                final userAvatar = authProvider.effectivePhotoUrl ?? '';

                                final okMsg = context.tr('Cảm ơn bạn đã gửi đánh giá sản phẩm! ⭐', 'Thank you for your review! ⭐');
                                final failMsg = context.tr('Có lỗi xảy ra, vui lòng thử lại sau.', 'An error occurred, please try again later.');

                                final success = await provider.submitOrderReview(
                                  orderId: order.id,
                                  rating: selectedRating,
                                  reviewNote: combinedNote.isEmpty ? 'Hài lòng với sản phẩm' : combinedNote,
                                  reviewImages: imageUrls,
                                  userDisplayName: userName,
                                  userAvatarUrl: userAvatar,
                                  items: order.items,
                                );

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                                if (mounted) {
                                  _showToast(success ? okMsg : failMsg, isError: !success);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                context.tr('Gửi đánh giá', 'Submit Review'),
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReviewPhotoItem {
  final Uint8List bytes;
  String? url;
  bool isUploading;
  _ReviewPhotoItem({required this.bytes, this.isUploading = false});
}
