import 'package:flutter/widgets.dart';

/// Dịch nhãn giao diện (Hub) Việt ↔ Anh ngay tại chỗ.
///
/// Dùng: `Text(context.tr('Cài đặt', 'Settings'))`
/// Chỉ dùng cho chữ CỐ ĐỊNH của giao diện. Dữ liệu người dùng (tên cây, nhật ký),
/// nội dung bài viết / sản phẩm từ Firestore và câu trả lời AI giữ nguyên, KHÔNG bọc tr().
///
/// Tự rebuild khi đổi ngôn ngữ vì phụ thuộc vào `Localizations` của MaterialApp.
extension AppTr on BuildContext {
  bool get isEnglish => Localizations.localeOf(this).languageCode == 'en';

  String tr(String vi, String en) => isEnglish ? en : vi;
}

