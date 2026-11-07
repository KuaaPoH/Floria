import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class VnpayService {
  // Cấu hình môi trường Sandbox chính thức của VNPay
  static const String tmnCode = '2QXUI4B4';
  static const String hashSecret = 'RAHZPQTGUTMSMGWFHGZIZPTBMKTOJFFQ';
  static const String paymentUrl = 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  static const String returnUrl = 'https://sandbox.vnpayment.vn/merchant_webapi/report.html';

  // Thông tin thẻ test Sandbox mặc định được VNPay cấp
  static const String testBankCode = 'NCB';
  static const String testCardNumber = '9704198526191432198';
  static const String testCardHolder = 'NGUYEN VAN A';
  static const String testIssueDate = '07/15';
  static const String testOtp = '123456';

  /// Tạo URL thanh toán VNPay Sandbox với mã bảo mật HMAC-SHA512
  static String createPaymentUrl({
    required String orderId,
    required double amount,
    String? orderInfo,
    String? bankCode,
  }) {
    final now = DateTime.now();
    final createDate = DateFormat('yyyyMMddHHmmss').format(now);
    
    // VNPay yêu cầu nhân 100 để đổi thành đơn vị xu
    final int amountInVndCents = (amount * 100).round();

    // Mã tham chiếu đơn hàng: loại bỏ ký tự đặc biệt # hoặc -
    final String txnRef = orderId.replaceAll('#', '').replaceAll('-', '').trim();
    final String cleanOrderInfo = (orderInfo != null && orderInfo.isNotEmpty)
        ? _removeVietnameseDiacritics(orderInfo)
        : 'Thanh toan don hang $txnRef';

    final Map<String, String> vnpParams = {
      'vnp_Version': '2.1.0',
      'vnp_Command': 'pay',
      'vnp_TmnCode': tmnCode,
      'vnp_Amount': amountInVndCents.toString(),
      'vnp_CreateDate': createDate,
      'vnp_CurrCode': 'VND',
      'vnp_IpAddr': '127.0.0.1',
      'vnp_Locale': 'vn',
      'vnp_OrderInfo': cleanOrderInfo,
      'vnp_OrderType': 'other',
      'vnp_ReturnUrl': returnUrl,
      'vnp_TxnRef': txnRef,
    };

    if (bankCode != null && bankCode.trim().isNotEmpty) {
      vnpParams['vnp_BankCode'] = bankCode.trim();
    }

    // 1. Sắp xếp danh sách tham số theo thứ tự bảng chữ cái A-Z
    final sortedKeys = vnpParams.keys.toList()..sort();

    // 2. Xây dựng chuỗi query string và chuỗi dữ liệu băm (hash data)
    final StringBuffer hashData = StringBuffer();
    final StringBuffer queryString = StringBuffer();

    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final value = vnpParams[key]!;
      if (value.isNotEmpty) {
        final encodedKey = Uri.encodeQueryComponent(key);
        final encodedValue = Uri.encodeQueryComponent(value);

        if (i > 0) {
          hashData.write('&');
          queryString.write('&');
        }
        hashData.write('$encodedKey=$encodedValue');
        queryString.write('$encodedKey=$encodedValue');
      }
    }

    // 3. Tính mã băm HMAC-SHA512
    final keyBytes = utf8.encode(hashSecret);
    final dataBytes = utf8.encode(hashData.toString());
    final hmacSha512 = Hmac(sha512, keyBytes);
    final digest = hmacSha512.convert(dataBytes);
    final secureHash = digest.toString();

    // 4. Trả về URL thanh toán hoàn chỉnh kèm chữ ký vnp_SecureHash
    return '$paymentUrl?${queryString.toString()}&vnp_SecureHash=$secureHash';
  }

  /// Kiểm tra tính hợp lệ của phản hồi từ VNPay
  static bool verifyReturnUrl(Uri uri) {
    final Map<String, String> params = Map.from(uri.queryParameters);
    final receivedHash = params.remove('vnp_SecureHash');
    params.remove('vnp_SecureHashType');

    if (receivedHash == null || receivedHash.isEmpty) {
      return false;
    }

    final sortedKeys = params.keys.toList()..sort();
    final StringBuffer hashData = StringBuffer();

    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      final value = params[key]!;
      if (value.isNotEmpty) {
        final encodedKey = Uri.encodeQueryComponent(key);
        final encodedValue = Uri.encodeQueryComponent(value);
        if (hashData.isNotEmpty) {
          hashData.write('&');
        }
        hashData.write('$encodedKey=$encodedValue');
      }
    }

    final keyBytes = utf8.encode(hashSecret);
    final dataBytes = utf8.encode(hashData.toString());
    final hmacSha512 = Hmac(sha512, keyBytes);
    final digest = hmacSha512.convert(dataBytes);
    final calculatedHash = digest.toString().toLowerCase();

    return calculatedHash == receivedHash.toLowerCase();
  }

  /// Loại bỏ dấu tiếng Việt để chuỗi OrderInfo gửi VNPay tuyệt đối an toàn
  static String _removeVietnameseDiacritics(String str) {
    const vietnamese = 'aAeEiIoOuUyYdD';
    final vietnameseRegex = <RegExp>[
      RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'),
      RegExp(r'[ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ]'),
      RegExp(r'[èéẹẻẽêềếệểễ]'),
      RegExp(r'[ÈÉẸẺẼÊỀẾỆỂỄ]'),
      RegExp(r'[ìíịỉĩ]'),
      RegExp(r'[ÌÍỊỈĨ]'),
      RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'),
      RegExp(r'[ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ]'),
      RegExp(r'[ùúụủũưừứựửữ]'),
      RegExp(r'[ÙÚỤỦŨƯỪỨỰỬỮ]'),
      RegExp(r'[ỳýỵỷỹ]'),
      RegExp(r'[ỲÝỴỶỸ]'),
      RegExp(r'[đ]'),
      RegExp(r'[Đ]'),
    ];

    var result = str;
    for (int i = 0; i < vietnameseRegex.length; i++) {
      result = result.replaceAll(vietnameseRegex[i], vietnamese[i]);
    }
    return result;
  }
}

