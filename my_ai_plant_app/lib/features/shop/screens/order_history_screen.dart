import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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
  static const Color _textDark = Color(0xFF1F2A21);
  static const Color _textMuted = Color(0xFF6A756B);
  static const Color _green = Color(0xFF2E6F40);

  late String _selectedFilter;

  final List<Map<String, String>> _tabs = const [
    {'key': 'all', 'label': 'Tất cả'},
    {'key': 'pending', 'label': 'Chờ xác nhận'},
    {'key': 'shipping', 'label': 'Đang giao'},
    {'key': 'completed', 'label': 'Đã giao'},
    {'key': 'cancelled', 'label': 'Đã hủy'},
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
                        'Xem giỏ',
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

  Color _statusBgColor(String status) {
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Hủy đơn hàng?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: _textDark),
        ),
        content: Text(
          'Bạn có chắc muốn hủy đơn hàng #${order.orderCode} không?',
          style: GoogleFonts.inter(fontSize: 13.5, color: _textMuted, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Không', style: GoogleFonts.inter(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Hủy đơn', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await provider.updateOrderStatus(order.id, 'cancelled');
      if (ok) {
        _showToast('Đã hủy đơn hàng #${order.orderCode}');
      } else {
        _showToast('Không thể hủy đơn hàng. Vui lòng thử lại!', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    final allOrders = shopProvider.orders;
    final filteredOrders = _selectedFilter == 'all'
        ? allOrders
        : allOrders.where((o) => o.status == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lịch sử đơn hàng',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Giỏ hàng',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_bag_outlined, color: _green, size: 22),
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
            color: Colors.white,
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
                        color: isSelected ? const Color(0xFF364534) : const Color(0xFFF5F7F3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF364534) : const Color(0xFFE0E5DD),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tab['label']!,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : _textDark,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.22)
                                    : const Color(0xFFE5F4EA),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : _green,
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
                ? const Center(child: CircularProgressIndicator(color: _green))
                : filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return _buildOrderCard(order, shopProvider);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                color: Color(0xFFE5F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 40, color: _green),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đơn hàng nào',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Các đơn mua vật tư và chế phẩm chăm sóc cây của bạn sẽ hiển thị tại đây.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: _textMuted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, ShopProvider provider) {
    final sColor = _statusColor(order.status);
    final sBg = _statusBgColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17231A).withValues(alpha: 0.04),
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
                      const Icon(Icons.local_mall_outlined, size: 17, color: _green),
                      const SizedBox(width: 6),
                      Text(
                        '#${order.orderCode}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: order.orderCode));
                          _showToast('Đã sao chép mã đơn #${order.orderCode}');
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.copy_rounded, size: 14, color: _textMuted),
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
                'Đặt lúc ${_formatDateTime(order.createdAt)}',
                style: GoogleFonts.inter(fontSize: 11.5, color: _textMuted),
              ),

              // Thanh tiến trình 3 bước (nếu chưa hủy)
              if (order.status != 'cancelled') ...[
                const SizedBox(height: 12),
                _buildOrderStepIndicator(order.status),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: Color(0x144F9D69)),
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
                                  color: _textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.formattedPrice} × ${item.quantity}',
                                style: GoogleFonts.inter(fontSize: 12, color: _textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item.formattedSubtotal,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                  )),
              if (order.items.length > 2)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '+ ${order.items.length - 2} sản phẩm khác (Chạm để xem chi tiết)',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _green,
                    ),
                  ),
                ),

              const Divider(height: 1, color: Color(0x144F9D69)),
              const SizedBox(height: 10),

              // Tổng tiền + Nút thao tác
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng thanh toán (${order.totalItemsCount} món)',
                        style: GoogleFonts.inter(fontSize: 11.5, color: _textMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.formattedTotal,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _green,
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
                            'Hủy đơn',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await provider.updateOrderStatus(order.id, 'completed');
                            _showToast('Đơn #${order.orderCode} đã hoàn tất! Bạn có thể đánh giá ngay.');
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                          label: Text(
                            'Nhận hàng',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
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
                            await provider.updateOrderStatus(order.id, 'completed');
                            _showToast('Cảm ơn bạn đã xác nhận nhận hàng!');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'Đã nhận hàng',
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
                              color: const Color(0xFFFFF9E6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFD54F)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFE6A100)),
                                const SizedBox(width: 4),
                                Text(
                                  '${order.rating ?? 5}★ Đã đánh giá',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF9E6500),
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
                              'Đánh giá',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB26A00),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFF9E6),
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
                            'Đã thêm lại $added sản phẩm vào giỏ hàng!',
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
                          'Mua lại',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5F4EA),
                          foregroundColor: _green,
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
                color: active ? _green : const Color(0xFFE0E5DD),
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
                  color: active ? _textDark : _textMuted,
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
        color: const Color(0xFFF6F8F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          buildNode(1, 'Chờ xác nhận'),
          buildNode(2, 'Đang giao'),
          buildNode(3, 'Đã giao'),
        ],
      ),
    );
  }

  void _showOrderDetailSheet(OrderModel order, ShopProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chi tiết đơn hàng #${order.orderCode}',
                      style: GoogleFonts.inter(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: _textMuted),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0x144F9D69)),
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
                          color: const Color(0xFFF5F7F3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 17, color: _green),
                                const SizedBox(width: 6),
                                Text(
                                  'ĐỊA CHỈ NHẬN HÀNG (${order.addressLabel})',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _green,
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
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.shippingAddress,
                              style: GoogleFonts.inter(fontSize: 13, color: _textMuted, height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.payments_outlined, size: 15, color: _green),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Thanh toán: ${order.paymentLabel}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _textDark,
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
                        'DANH SÁCH SẢN PHẨM (${order.totalItemsCount})',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _textMuted,
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
                                          color: _textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${item.formattedPrice} × ${item.quantity}',
                                        style: GoogleFonts.inter(fontSize: 12, color: _textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  item.formattedSubtotal,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: _textDark,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 20, color: Color(0x144F9D69)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng cộng',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          Text(
                            order.formattedTotal,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _green,
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
                            color: const Color(0xFFEAF5EC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.flash_on_rounded, size: 18, color: _green),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Công cụ thử nghiệm chuyển trạng thái:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _green,
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
                                          Navigator.pop(ctx);
                                          await provider.updateOrderStatus(order.id, 'shipping');
                                          _showToast('Đơn #${order.orderCode} đã chuyển sang Đang giao!');
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _green,
                                          side: const BorderSide(color: _green),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text(
                                          'Đang giao',
                                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(ctx);
                                        await provider.updateOrderStatus(order.id, 'completed');
                                        _showToast('Đơn #${order.orderCode} đã hoàn tất! Bạn có thể đánh giá ngay.');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _green,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: Text(
                                        'Hoàn tất đơn ngay',
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
                                'Đánh giá đơn hàng này',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A24),
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
                              color: const Color(0xFFFFF9E6),
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
                                        'Bạn đã đánh giá ${order.rating ?? 5}/5 sao',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF9E6500),
                                        ),
                                      ),
                                      if (order.reviewNote != null && order.reviewNote!.isNotEmpty)
                                        Text(
                                          order.reviewNote!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(fontSize: 11.5, color: _textDark),
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
    int selectedRating = 5;
    final Set<String> selectedTags = {'Sản phẩm chất lượng tốt', 'Đóng gói cẩn thận'};
    final commentController = TextEditingController();
    final List<_ReviewPhotoItem> attachedPhotos = [];
    final ImagePicker picker = ImagePicker();
    bool isSubmitting = false;

    final tags = [
      'Giao hàng rất nhanh',
      'Đóng gói cẩn thận',
      'Sản phẩm chất lượng tốt',
      'Đúng mô tả',
      'Chăm cây hiệu quả',
      'Tư vấn nhiệt tình',
    ];

    String ratingText(int r) {
      switch (r) {
        case 1:
          return 'Chưa hài lòng 😞';
        case 2:
          return 'Tạm ổn 😐';
        case 3:
          return 'Bình thường 🙂';
        case 4:
          return 'Hài lòng 😊';
        case 5:
        default:
          return 'Rất tuyệt vời! 🌟';
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
                    final url = await StorageService.uploadToImgbb(bytes);
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
                      StorageService.uploadToImgbb(bytes).then((url) {
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
                backgroundColor: Colors.white,
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
                          leading: const Icon(Icons.camera_alt_outlined, color: _green),
                          title: Text(
                            'Chụp ảnh mới',
                            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: const Color(0xFF191C19)),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            pickPhotos(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library_outlined, color: _green),
                          title: Text(
                            'Chọn từ thư viện ảnh',
                            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: const Color(0xFF191C19)),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                        color: const Color(0xFFD8DED5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đánh giá đơn hàng #${order.orderCode}',
                      style: GoogleFonts.inter(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF191C19),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chia sẻ trải nghiệm sử dụng vật tư & chế phẩm của bạn',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5A6657),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8F5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE0E5DD)),
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
                                    color: const Color(0xFF191C19),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tổng cộng ${order.items.length} món',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6A756B),
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
                        'Điểm bạn hài lòng nhất:',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF191C19),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        final isChecked = selectedTags.contains(tag);
                        return InkWell(
                          onTap: () {
                            setSheetState(() {
                              if (isChecked) {
                                selectedTags.remove(tag);
                              } else {
                                selectedTags.add(tag);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isChecked ? const Color(0xFFE5F4EA) : const Color(0xFFF1F4F0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isChecked ? _green : const Color(0xFFE0E5DD),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isChecked) ...[
                                  const Icon(Icons.check_rounded, size: 14, color: _green),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  tag,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isChecked ? FontWeight.w700 : FontWeight.w600,
                                    color: isChecked ? _green : const Color(0xFF2E382C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Ô nhập cảm nhận chi tiết (Màu chữ đen đậm rõ nét, tương phản cao)
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      cursorColor: _green,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF191C19),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cây của bạn đã phát triển hoặc hồi phục thế nào? Hãy viết vài dòng chia sẻ nhé...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8C9388),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7FAF6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFC8E6C9)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFC8E6C9)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(color: _green, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mục đính kèm hình ảnh thực tế (sử dụng ImgBB Cloud)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          const Icon(Icons.photo_camera_back_outlined, size: 17, color: _green),
                          const SizedBox(width: 6),
                          Text(
                            'Hình ảnh thực tế (${attachedPhotos.length}/5):',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF191C19),
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
                                  color: const Color(0xFFF1F5F0),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF2E6F40).withValues(alpha: 0.35),
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined, size: 22, color: _green),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Thêm ảnh',
                                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _green),
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
                                      border: Border.all(color: const Color(0xFFE0E5DD)),
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
                                  _showToast('Ảnh đang được tải lên, vui lòng đợi trong giây lát...');
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
                                  if (success) {
                                    _showToast('Cảm ơn bạn đã gửi đánh giá sản phẩm! ⭐');
                                  } else {
                                    _showToast('Có lỗi xảy ra, vui lòng thử lại sau.');
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
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
                                'Gửi đánh giá',
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
