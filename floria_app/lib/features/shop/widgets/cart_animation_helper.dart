import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/custom_image.dart';
import '../models/shop_product.dart';
import '../screens/cart_screen.dart';

class CartAnimationHelper {
  /// Chạy hiệu ứng ảnh sản phẩm bay theo đường cong parabol vào biểu tượng Giỏ hàng
  static void playFlyToCart({
    required BuildContext context,
    required GlobalKey sourceKey,
    required GlobalKey cartIconKey,
    required String imageUrl,
    VoidCallback? onComplete,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      onComplete?.call();
      return;
    }

    final sourceBox = sourceKey.currentContext?.findRenderObject() as RenderBox?;
    final targetBox = cartIconKey.currentContext?.findRenderObject() as RenderBox?;

    if (sourceBox == null || targetBox == null || !sourceBox.hasSize || !targetBox.hasSize) {
      onComplete?.call();
      return;
    }

    final startOffset = sourceBox.localToGlobal(
      Offset(sourceBox.size.width / 2, sourceBox.size.height / 2),
    );
    final endOffset = targetBox.localToGlobal(
      Offset(targetBox.size.width / 2, targetBox.size.height / 2),
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _FlyingCartBadge(
        startOffset: startOffset,
        endOffset: endOffset,
        imageUrl: imageUrl,
        onFinished: () {
          entry.remove();
          onComplete?.call();
        },
      ),
    );

    overlay.insert(entry);
  }

  /// Hiển thị Toast viên thuốc hiện đại khi thêm sản phẩm vào giỏ kèm nút "Xem giỏ"
  static void showAddedToCartToast(
    BuildContext context, {
    required ShopProduct product,
    int quantity = 1,
    bool showViewCartButton = true,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        duration: const Duration(milliseconds: 2200),
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2D22),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: product.imageUrl.isNotEmpty
                          ? CustomImage(imageUrl: product.imageUrl, fit: BoxFit.cover)
                          : Container(
                              color: const Color(0xFF2E6F40),
                              child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF81C784), size: 14),
                            const SizedBox(width: 5),
                            Text(
                              'Đã lưu vào giỏ hàng',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF81C784),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${quantity}x ${product.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showViewCartButton) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        messenger.hideCurrentSnackBar();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF3E8055),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
}

class _FlyingCartBadge extends StatefulWidget {
  final Offset startOffset;
  final Offset endOffset;
  final String imageUrl;
  final VoidCallback onFinished;

  const _FlyingCartBadge({
    required this.startOffset,
    required this.endOffset,
    required this.imageUrl,
    required this.onFinished,
  });

  @override
  State<_FlyingCartBadge> createState() => _FlyingCartBadgeState();
}

class _FlyingCartBadgeState extends State<_FlyingCartBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _controller.forward().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controlPoint = Offset(
      (widget.startOffset.dx + widget.endOffset.dx) / 2,
      (widget.startOffset.dy < widget.endOffset.dy
              ? widget.startOffset.dy
              : widget.endOffset.dy) -
          90,
    );

    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value;
        // Đường cong Bezier bậc 2
        final dx = (1 - t) * (1 - t) * widget.startOffset.dx +
            2 * (1 - t) * t * controlPoint.dx +
            t * t * widget.endOffset.dx;
        final dy = (1 - t) * (1 - t) * widget.startOffset.dy +
            2 * (1 - t) * t * controlPoint.dy +
            t * t * widget.endOffset.dy;

        final size = lerpDouble(46, 20, t) ?? 30;
        final opacity = t > 0.88 ? ((1.0 - t) / 0.12).clamp(0.0, 1.0) : 1.0;

        return Positioned(
          left: dx - size / 2,
          top: dy - size / 2,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2E6F40),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E6F40).withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.imageUrl.isNotEmpty
                    ? CustomImage(imageUrl: widget.imageUrl, fit: BoxFit.cover)
                    : const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        );
      },
    );
  }
}

