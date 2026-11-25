import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../services/zalopay_service.dart';

class ZaloPayPaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String formattedAmount;
  final String? orderInfo;

  const ZaloPayPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.formattedAmount,
    this.orderInfo,
  });

  @override
  State<ZaloPayPaymentScreen> createState() => _ZaloPayPaymentScreenState();
}

class _ZaloPayPaymentScreenState extends State<ZaloPayPaymentScreen> {
  bool _isCreatingOrder = true;
  bool _isChecking = false;
  bool _isWebLoading = true;
  bool _hasProcessedCallback = false;

  ZaloPayOrderResult? _orderResult;
  WebViewController? _webViewController;

  bool get _supportsWebView =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void initState() {
    super.initState();
    _initZaloPayGateway();
  }

  Future<void> _initZaloPayGateway() async {
    setState(() => _isCreatingOrder = true);
    final result = await ZaloPayService.createSandboxOrder(
      orderCode: widget.orderId,
      amount: widget.amount,
      description: widget.orderInfo ?? 'Floria - Thanh toan don ${widget.orderId}',
    );
    if (!mounted) return;

    WebViewController? controller;
    if (result.success &&
        (result.orderUrl?.isNotEmpty ?? false) &&
        _supportsWebView) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (url) {
              if (mounted) setState(() => _isWebLoading = true);
              _handleWebUrl(url);
            },
            onPageFinished: (url) {
              if (mounted) setState(() => _isWebLoading = false);
              _handleWebUrl(url);
            },
            onNavigationRequest: (request) {
              if (_handleWebUrl(request.url)) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(result.orderUrl!));
    }

    setState(() {
      _orderResult = result;
      _webViewController = controller;
      _isCreatingOrder = false;
    });
  }

  bool _handleWebUrl(String url) {
    if (_hasProcessedCallback) return true;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final status = uri.queryParameters['status'];
    if (status == '1') {
      _hasProcessedCallback = true;
      _notifyAndClose(
        success: true,
        message: context.tr('Thanh toán ZaloPay thành công!', 'ZaloPay payment successful!'),
      );
      return true;
    } else if (status != null && status != '1') {
      _hasProcessedCallback = true;
      _notifyAndClose(
        success: false,
        message: context.tr('Giao dịch ZaloPay chưa hoàn tất.', 'ZaloPay transaction was not completed.'),
      );
      return true;
    }
    return false;
  }

  Future<void> _checkPaymentStatus() async {
    final appTransId = _orderResult?.appTransId;
    if (appTransId == null || appTransId.isEmpty) return;

    setState(() => _isChecking = true);
    final paid = await ZaloPayService.queryOrderStatus(appTransId);
    if (!mounted) return;
    setState(() => _isChecking = false);

    if (paid) {
      _notifyAndClose(
        success: true,
        message: context.tr('Thanh toán ZaloPay thành công!', 'ZaloPay payment successful!'),
      );
    } else {
      AppToast.show(
        context,
        context.tr('Giao dịch chưa hoàn tất trên cổng ZaloPay.', 'Transaction is not completed on ZaloPay yet.'),
        isError: true,
      );
    }
  }

  void _notifyAndClose({required bool success, required String message}) {
    if (!mounted) return;
    final rootContext = Navigator.of(context).context;
    final result = success ? (_orderResult?.appTransId ?? 'paid') : null;
    Navigator.of(context).pop<String?>(result);
    AppToast.show(rootContext, message, isError: !success);
  }

  Future<bool> _onWillPop() async {
    final c = context.colors;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          context.tr('Hủy thanh toán?', 'Cancel payment?'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17, color: c.textPrimary),
        ),
        content: Text(
          context.tr(
            'Giao dịch ZaloPay của bạn chưa hoàn tất. Bạn có chắc muốn quay lại?',
            'Your ZaloPay transaction is not complete. Are you sure you want to go back?',
          ),
          style: GoogleFonts.inter(fontSize: 13.5, color: c.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              context.tr('Tiếp tục', 'Continue'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: c.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              context.tr('Thoát', 'Exit'),
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _onWillPop();
        if (leave && context.mounted) {
          Navigator.of(context).pop<String?>(null);
        }
      },
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: c.textPrimary),
            onPressed: () async {
              final leave = await _onWillPop();
              if (leave && context.mounted) {
                Navigator.of(context).pop<String?>(null);
              }
            },
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0068FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ZaloPay',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Cổng thanh toán ZaloPay', 'ZaloPay Payment Gateway'),
                      style: GoogleFonts.inter(
                        color: c.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${context.tr("Đơn", "Order")} #${widget.orderId} • ${widget.formattedAmount}',
                      style: GoogleFonts.inter(
                        color: c.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: _isCreatingOrder
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF0068FF)),
                    const SizedBox(height: 14),
                    Text(
                      context.tr('Đang mở cổng thanh toán ZaloPay...', 'Opening ZaloPay payment gateway...'),
                      style: GoogleFonts.inter(fontSize: 13.5, color: c.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            : _webViewController != null
                ? Column(
                    children: [
                      if (_isWebLoading)
                        const LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: Color(0xFFEAF2FF),
                          color: Color(0xFF0068FF),
                        ),
                      Expanded(child: WebViewWidget(controller: _webViewController!)),
                      SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                          decoration: BoxDecoration(
                            color: c.surface,
                            border: Border(top: BorderSide(color: c.border)),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isChecking ? null : _checkPaymentStatus,
                              icon: _isChecking
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.verified_outlined, size: 18),
                              label: Text(
                                _isChecking
                                    ? context.tr('Đang kiểm tra kết quả...', 'Checking payment status...')
                                    : context.tr('Tôi đã thanh toán xong', 'I have completed payment'),
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0068FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SafeArea(
                    top: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _orderResult?.success == true ? Icons.open_in_browser_rounded : Icons.error_outline_rounded,
                              size: 48,
                              color: _orderResult?.success == true ? const Color(0xFF0068FF) : const Color(0xFFBA1A1A),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _orderResult?.success == true
                                  ? context.tr(
                                      'WebView ZaloPay chỉ khả dụng trực tiếp trên ứng dụng di động (Android/iOS).',
                                      'ZaloPay WebView is available directly on mobile devices (Android/iOS).',
                                    )
                                  : (_orderResult?.message ??
                                      context.tr('Không thể kết nối cổng ZaloPay.', 'Could not connect to ZaloPay gateway.')),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 14, color: c.textPrimary, height: 1.45),
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: _initZaloPayGateway,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(context.tr('Thử kết nối lại', 'Retry')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0068FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
}
