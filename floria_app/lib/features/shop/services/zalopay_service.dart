import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class ZaloPayOrderResult {
  final bool success;
  final String? orderUrl;
  final String? zpTransToken;
  final String appTransId;
  final String message;

  const ZaloPayOrderResult({
    required this.success,
    required this.appTransId,
    required this.message,
    this.orderUrl,
    this.zpTransToken,
  });
}

class ZaloPayService {
  // Cấu hình Sandbox OpenAPI v2 của ZaloPay
  static const int appId = 2554;
  static const String key1 = 'sdngKKJmqEMzvh5QQcdD2A9XBSKUNaYn';
  static const String createOrderUrl = 'https://sb-openapi.zalopay.vn/v2/create';
  static const String queryOrderUrl = 'https://sb-openapi.zalopay.vn/v2/query';

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  static String _hmacSha256(String data, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(data)).toString();
  }

  /// Tạo đơn hàng thanh toán qua ZaloPay Sandbox OpenAPI v2
  static Future<ZaloPayOrderResult> createSandboxOrder({
    required String orderCode,
    required double amount,
    required String description,
    String appUser = 'floria_user',
    String bankCode = '',
  }) async {
    final now = DateTime.now();
    final yyMMdd = DateFormat('yyMMdd').format(now);
    final suffix = (now.millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0');
    final cleanCode = orderCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final appTransId = '${yyMMdd}_${cleanCode.isEmpty ? suffix : '${cleanCode}_$suffix'}';

    final int appTime = now.millisecondsSinceEpoch;
    final int amountVnd = amount.round();
    const String embedData = '{}';
    const String item = '[]';

    final String macInput = '$appId|$appTransId|$appUser|$amountVnd|$appTime|$embedData|$item';
    final String mac = _hmacSha256(macInput, key1);

    try {
      final response = await _dio.post(
        createOrderUrl,
        data: {
          'app_id': appId,
          'app_user': appUser,
          'app_time': appTime,
          'amount': amountVnd,
          'app_trans_id': appTransId,
          'embed_data': embedData,
          'item': item,
          'description': description,
          'bank_code': bankCode,
          'mac': mac,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      final int returnCode = int.tryParse('${data['return_code'] ?? 0}') ?? 0;
      if (returnCode == 1) {
        return ZaloPayOrderResult(
          success: true,
          appTransId: appTransId,
          orderUrl: data['order_url']?.toString(),
          zpTransToken: data['zp_trans_token']?.toString(),
          message: data['return_message']?.toString() ?? 'Tạo đơn ZaloPay Sandbox thành công',
        );
      }

      return ZaloPayOrderResult(
        success: false,
        appTransId: appTransId,
        message: data['sub_return_message']?.toString() ??
            data['return_message']?.toString() ??
            'Không thể khởi tạo giao dịch ZaloPay Sandbox',
      );
    } catch (e) {
      return ZaloPayOrderResult(
        success: false,
        appTransId: appTransId,
        message: 'Lỗi kết nối ZaloPay Sandbox: $e',
      );
    }
  }

  /// Kiểm tra trạng thái giao dịch trên ZaloPay Sandbox
  static Future<bool> queryOrderStatus(String appTransId) async {
    try {
      final macInput = '$appId|$appTransId|$key1';
      final mac = _hmacSha256(macInput, key1);

      final response = await _dio.post(
        queryOrderUrl,
        data: {
          'app_id': appId,
          'app_trans_id': appTransId,
          'mac': mac,
        },
        options: Options(contentType: Headers.jsonContentType),
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};

      final int returnCode = int.tryParse('${data['return_code'] ?? 0}') ?? 0;
      return returnCode == 1;
    } catch (_) {
      return false;
    }
  }
}
