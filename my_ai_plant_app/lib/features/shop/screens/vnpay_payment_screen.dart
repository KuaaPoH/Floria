import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';
import '../services/vnpay_service.dart';

class VnpayPaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  final String formattedAmount;
  final String? orderInfo;

  const VnpayPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.formattedAmount,
    this.orderInfo,
  });

  @override
  State<VnpayPaymentScreen> createState() => _VnpayPaymentScreenState();
}

class _VnpayPaymentScreenState extends State<VnpayPaymentScreen> {
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _showTestCardSheet = true;
  late final String _paymentUrl;
  bool _hasProcessedCallback = false;

  @override
  void initState() {
    super.initState();
    _paymentUrl = VnpayService.createPaymentUrl(
      orderId: widget.orderId,
      amount: widget.amount,
      orderInfo: widget.orderInfo,
    );

    _initWebView();
  }

  void _initWebView() {
    // webview_flutter chỉ hỗ trợ native trên Android / iOS / macOS
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) setState(() => _isLoading = true);
              _handleUrlInterception(url);
            },
            onPageFinished: (String url) {
              if (mounted) setState(() => _isLoading = false);
              _handleUrlInterception(url);
            },
            onNavigationRequest: (NavigationRequest request) {
              final intercept = _handleUrlInterception(request.url);
              if (intercept) {
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint("❌ [VNPay WebView Error]: ${error.description}");
            },
          ),
        )
        ..loadRequest(Uri.parse(_paymentUrl));

      _webViewController = controller;
    } else {
      // Đối với môi trường desktop/web chưa có webview native
      _isLoading = false;
    }
  }

  /// Bắt callback URL từ VNPay khi thanh toán hoàn tất hoặc bị hủy
  bool _handleUrlInterception(String url) {
    if (_hasProcessedCallback) return true;

    try {
      final uri = Uri.parse(url);
      final isReturnUrl = url.contains('vnp_ResponseCode') ||
          url.contains('merchant_webapi/report.html') ||
          url.contains('vnpay_return');

      if (isReturnUrl) {
        final responseCode = uri.queryParameters['vnp_ResponseCode'];
        if (responseCode != null) {
          _hasProcessedCallback = true;
          if (responseCode == '00') {
            // Thanh toán thành công
            _notifyAndClose(success: true, message: "Thanh toán VNPay thành công! ⭐");
          } else if (responseCode == '24') {
            // Khách hàng hủy thanh toán
            _notifyAndClose(success: false, message: "Bạn đã hủy thanh toán VNPay.");
          } else {
            // Giao dịch không thành công
            _notifyAndClose(
              success: false,
              message: "Giao dịch không thành công (Mã lỗi VNPay: $responseCode).",
            );
          }
          return true;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi phân tích URL VNPay: $e");
    }
    return false;
  }

  void _notifyAndClose({required bool success, required String message}) {
    if (!mounted) return;
    Navigator.of(context).pop(success);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: success ? const Color(0xFF2E6F40) : const Color(0xFFBA1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Đã sao chép $label: $text",
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E2D22),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final c = context.colors;
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          context.tr("Hủy thanh toán?", "Cancel Payment?"),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: c.textPrimary),
        ),
        content: Text(
          context.tr(
            "Giao dịch của bạn chưa hoàn tất. Bạn có chắc chắn muốn thoát khỏi cổng VNPay?",
            "Your transaction is not complete. Are you sure you want to exit VNPay?",
          ),
          style: GoogleFonts.inter(fontSize: 14, color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr("Tiếp tục thanh toán", "Continue Payment"), style: GoogleFonts.inter(color: c.primary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(context.tr("Hủy đơn", "Cancel Order"), style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isNativeWebViewSupported = _webViewController != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _onWillPop()) {
          if (context.mounted) Navigator.pop(context, false);
        }
      },
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.surface,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: c.textPrimary),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) Navigator.pop(context, false);
              }
            },
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF005BAA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.credit_card_rounded, color: Color(0xFF005BAA), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "VNPay Sandbox",
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF005BAA),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.formattedAmount,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _showTestCardSheet ? Icons.visibility_off_outlined : Icons.info_outline_rounded,
                color: c.primary,
              ),
              tooltip: _showTestCardSheet
                  ? context.tr("Thu gọn thông tin test", "Collapse test info")
                  : context.tr("Xem thẻ test Sandbox", "View Sandbox test card"),
              onPressed: () => setState(() => _showTestCardSheet = !_showTestCardSheet),
            ),
          ],
        ),
        body: Column(
          children: [
            // Thanh tiến trình loading khi tải trang web VNPay
            if (_isLoading)
              LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: c.surfaceTint,
                valueColor: AlwaysStoppedAnimation<Color>(c.primary),
              ),

            // Banner hướng dẫn & Thông tin thẻ test VNPay Sandbox 1-chạm
            if (_showTestCardSheet)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: c.isDark ? const Color(0xFF132338) : const Color(0xFFF0F7FF),
                  border: Border(bottom: BorderSide(color: const Color(0xFF005BAA).withValues(alpha: 0.2))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: Color(0xFF005BAA), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              context.tr("THÔNG TIN THẺ TEST NHANH", "TEST CARD INFO"),
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: const Color(0xFF005BAA),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => setState(() => _showTestCardSheet = false),
                          child: const Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFF005BAA), size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Hàng sao chép số thẻ
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF005BAA).withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_outlined, size: 14, color: Color(0xFF005BAA)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "NCB: ${VnpayService.testCardNumber}",
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: c.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _copyToClipboard(VnpayService.testCardNumber, "Số thẻ test"),
                          icon: const Icon(Icons.copy_rounded, size: 13, color: Colors.white),
                          label: Text(
                            context.tr("Chép thẻ", "Copy"),
                            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005BAA),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Hàng ngày phát hành & OTP
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                context.tr("Ngày: ", "Date: "),
                                style: GoogleFonts.inter(fontSize: 11.5, color: c.textMuted),
                              ),
                              Text(
                                VnpayService.testIssueDate,
                                style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.bold, color: c.textPrimary),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _copyToClipboard(VnpayService.testIssueDate, "Ngày phát hành"),
                                child: const Icon(Icons.copy, size: 13, color: Color(0xFF005BAA)),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                "OTP: ",
                                style: GoogleFonts.inter(fontSize: 11.5, color: c.textMuted),
                              ),
                              Text(
                                VnpayService.testOtp,
                                style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.bold, color: c.primary),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _copyToClipboard(VnpayService.testOtp, "Mã OTP"),
                                child: const Icon(Icons.copy, size: 13, color: Color(0xFF005BAA)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          context.tr("Chủ thẻ: NGUYEN VAN A", "Cardholder: NGUYEN VAN A"),
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: c.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Khu vực WebView hoặc Giao diện Giả lập nếu chạy trên nền tảng không hỗ trợ native webview
            Expanded(
              child: isNativeWebViewSupported
                  ? WebViewWidget(controller: _webViewController!)
                  : _buildFallbackDesktopSimulator(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Giao diện fallback khi chạy thử nghiệm trên Windows/Web (nơi webview_flutter chưa có native renderer)
  Widget _buildFallbackDesktopSimulator(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF005BAA).withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.isDark ? const Color(0xFF132338) : const Color(0xFFEAF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.credit_card_rounded, color: Color(0xFF005BAA), size: 40),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    context.tr("Cổng Thanh Toán VNPay Sandbox", "VNPay Sandbox Gateway"),
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: c.textPrimary),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    "${context.tr('Đơn hàng', 'Order')}: #${widget.orderId.replaceAll('#', '')}",
                    style: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    widget.formattedAmount,
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: c.primary),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(context, context.tr("Ngân hàng kiểm thử:", "Test Bank:"), "NCB Bank (Quốc Dân)"),
                      Divider(height: 16, color: c.border),
                      _buildInfoRow(context, context.tr("Số thẻ ATM:", "ATM Card No:"), VnpayService.testCardNumber),
                      Divider(height: 16, color: c.border),
                      _buildInfoRow(context, context.tr("Tên chủ thẻ:", "Cardholder:"), VnpayService.testCardHolder),
                      Divider(height: 16, color: c.border),
                      _buildInfoRow(context, context.tr("Ngày phát hành:", "Issue Date:"), VnpayService.testIssueDate),
                      Divider(height: 16, color: c.border),
                      _buildInfoRow(context, context.tr("Mã OTP test:", "Test OTP:"), VnpayService.testOtp),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _notifyAndClose(success: true, message: context.tr("Thanh toán VNPay Sandbox thành công! ⭐", "VNPay Sandbox payment successful! ⭐")),
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  label: Text(
                    context.tr("XÁC NHẬN THANH TOÁN THÀNH CÔNG", "CONFIRM SUCCESSFUL PAYMENT"),
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005BAA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _notifyAndClose(success: false, message: context.tr("Bạn đã hủy thanh toán VNPay.", "You cancelled VNPay payment.")),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: const Color(0xFFBA1A1A).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    context.tr("Hủy giao dịch", "Cancel Transaction"),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFBA1A1A)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final c = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: c.textMuted)),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
      ],
    );
  }
}
