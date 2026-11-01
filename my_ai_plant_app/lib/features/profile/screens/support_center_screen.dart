import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../chatbot/screens/ai_assistant_screen.dart';

/// Thông tin liên hệ hỗ trợ
class SupportContactInfo {
  static const String contactName = 'Trần Ngọc Hải';
  static const String hotline = '0866 459 082';
  static const String email = 'trankenn04@gmail.com';
  static const String workingHours = '8:00 – 21:00, Thứ 2 – Chủ nhật';
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

class _FaqGroup {
  final String title;
  final IconData icon;
  final List<_FaqItem> items;
  const _FaqGroup(this.title, this.icon, this.items);
}

/// Trung tâm hỗ trợ & Câu hỏi thường gặp
class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  static const Color _textDark = Color(0xFF1F2A21);
  static const Color _textMuted = Color(0xFF6A756B);
  static const Color _green = Color(0xFF3E8055);

  static const List<_FaqGroup> _faqGroups = [
    _FaqGroup('Quét ảnh & Chẩn đoán AI', Icons.document_scanner_outlined, [
      _FaqItem(
        'Làm sao để chụp ảnh lá cho kết quả chính xác nhất?',
        '• Chụp ở nơi đủ sáng tự nhiên, tránh ánh nắng gắt hoặc đèn flash chói.\n'
            '• Đưa lá bệnh vào giữa khung hình, cách khoảng 15–30 cm, giữ máy thật chắc để ảnh không bị mờ.\n'
            '• Chỉ chụp 1 lá hoặc 1 cụm lá, nền phía sau càng đơn giản càng tốt.\n'
            '• Nên chụp mặt có vết bệnh rõ nhất (đốm, vàng, cháy mép...).',
      ),
      _FaqItem(
        'AI của Floria nhận diện được những gì?',
        'Floria dùng mô hình EfficientNetV2 để nhận diện loài cây và các bệnh lá phổ biến trên cây trồng, cây cảnh. '
            'Độ chính xác đạt khoảng 90% với loài cây và 92,5% với bệnh lá trên bộ dữ liệu kiểm thử. '
            'Với các loài hiếm hoặc ảnh chất lượng thấp, kết quả có thể chưa chính xác.',
      ),
      _FaqItem(
        'Kết quả chẩn đoán có kèm hướng dẫn chữa trị không?',
        'Có. Mỗi kết quả chẩn đoán đều có báo cáo gồm nguyên nhân, triệu chứng, cách xử lý và phòng ngừa. '
            'Bạn cũng có thể bấm hỏi thêm Trợ lý Floria để được tư vấn chi tiết theo đúng cây của mình.',
      ),
      _FaqItem(
        'Vì sao ảnh của tôi không nhận diện được hoặc kết quả sai?',
        'Nguyên nhân thường gặp: ảnh bị mờ/thiếu sáng, lá quá nhỏ trong khung hình, chụp cả chậu cây thay vì lá, '
            'hoặc loài cây chưa có trong dữ liệu. Hãy chụp lại theo hướng dẫn và kiểm tra kết nối mạng. '
            'Các lần quét được lưu trong mục "Lịch sử quét" để bạn so sánh lại.',
      ),
    ]),
    _FaqGroup('Lịch chăm sóc & Nhắc nhở', Icons.water_drop_outlined, [
      _FaqItem(
        'Tại sao tôi không thấy thông báo nhắc tưới cây?',
        'Hiện tại Floria nhắc nhở bằng banner hiển thị ngay trong ứng dụng khi bạn đang mở app. '
            'Hãy kiểm tra: (1) đã bật "Nhắc nhở" trong mục Nhắc tưới, (2) không nằm trong khung giờ Không làm phiền, '
            '(3) đã qua giờ nhắc của cây đó trong ngày.',
      ),
      _FaqItem(
        'Lỡ quên tưới cây vài ngày thì lịch có bị sai không?',
        'Không. Cây sẽ chuyển sang trạng thái "Cần tưới nước" và hiện trong danh sách việc cần làm. '
            'Khi bạn bấm hoàn thành, chu kỳ tiếp theo sẽ được tính lại từ thời điểm bạn thực sự tưới.',
      ),
      _FaqItem(
        'Làm sao để đổi chu kỳ tưới hoặc giờ nhắc của một cây?',
        'Vào Khu vườn → chọn cây → mục Lịch chăm sóc để chỉnh số ngày tưới, bón phân, kiểm tra sâu bệnh và giờ nhắc riêng. '
            'Giờ nhắc mặc định cho cây mới thêm được chỉnh trong Cá nhân → Nhắc tưới.',
      ),
    ]),
    _FaqGroup('Tài khoản & Mua sắm', Icons.shopping_bag_outlined, [
      _FaqItem(
        'Tôi muốn đổi mật khẩu thì làm thế nào?',
        'Vào Cá nhân → Cài đặt → Đổi mật khẩu, Floria sẽ gửi đường dẫn đặt lại mật khẩu về email của bạn. '
            'Nếu bạn đăng nhập bằng Google, mật khẩu được quản lý bởi tài khoản Google nên không đổi trong ứng dụng.',
      ),
      _FaqItem(
        'Thanh toán COD và thanh toán bằng thẻ khác nhau thế nào?',
        'COD (thanh toán khi nhận hàng): bạn trả tiền mặt cho người giao hàng. '
            'Thanh toán bằng thẻ: dùng thẻ ngân hàng đã lưu trong mục Địa chỉ & Thanh toán. '
            'Bạn có thể đổi phương thức mặc định bất cứ lúc nào trước khi đặt hàng.',
      ),
      _FaqItem(
        'Vật tư mua trên Floria có được đổi trả không?',
        'Sản phẩm lỗi, hư hỏng do vận chuyển hoặc giao sai được hỗ trợ đổi trả. '
            'Vui lòng liên hệ bộ phận hỗ trợ kèm ảnh sản phẩm và mã đơn hàng để được xử lý nhanh nhất.',
      ),
    ]),
  ];

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E2D22),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text('Đã sao chép $label: $text', style: GoogleFonts.inter(color: Colors.white)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F3),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Trung tâm hỗ trợ',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: _textDark),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _buildAssistantBanner(context),
          const SizedBox(height: 24),
          for (final group in _faqGroups) ...[
            _buildGroupTitle(group),
            const SizedBox(height: 8),
            _buildFaqCard(group),
            const SizedBox(height: 20),
          ],
          _buildGroupTitleText('LIÊN HỆ VỚI CHÚNG TÔI'),
          const SizedBox(height: 8),
          _buildContactCard(context),
        ],
      ),
    );
  }

  Widget _buildAssistantBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E6F40), Color(0xFF4F9D69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chúng tôi có thể giúp gì?',
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Xem các câu hỏi thường gặp bên dưới hoặc hỏi ngay Trợ lý Floria 24/7.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text('Hỏi Trợ lý Floria', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _green,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.support_agent_rounded, size: 56, color: Colors.white.withValues(alpha: 0.85)),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(_FaqGroup group) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(group.icon, size: 16, color: _textMuted),
          const SizedBox(width: 6),
          Text(
            group.title.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _textMuted, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTitleText(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _textMuted, letterSpacing: 1),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF17231A).withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      );

  Widget _buildFaqCard(_FaqGroup group) {
    return Container(
      decoration: _cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < group.items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0x144F9D69)),
            Theme(
              data: ThemeData(dividerColor: Colors.transparent, splashColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                iconColor: _green,
                collapsedIconColor: _textMuted,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: Text(
                  group.items[i].question,
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: _textDark),
                ),
                children: [
                  Text(
                    group.items[i].answer,
                    style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF4A554C), height: 1.55),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      decoration: _cardDecoration,
      child: Column(
        children: [
          _buildContactRow(
            icon: Icons.person_outline_rounded,
            title: 'Người phụ trách hỗ trợ',
            value: SupportContactInfo.contactName,
          ),
          const Divider(height: 1, color: Color(0x144F9D69)),
          _buildContactRow(
            icon: Icons.phone_in_talk_outlined,
            title: 'Hotline',
            value: SupportContactInfo.hotline,
            onTap: () => _copy(context, SupportContactInfo.hotline, 'hotline'),
          ),
          const Divider(height: 1, color: Color(0x144F9D69)),
          _buildContactRow(
            icon: Icons.mail_outline_rounded,
            title: 'Email',
            value: SupportContactInfo.email,
            onTap: () => _copy(context, SupportContactInfo.email, 'email'),
          ),
          const Divider(height: 1, color: Color(0x144F9D69)),
          _buildContactRow(
            icon: Icons.schedule_rounded,
            title: 'Thời gian hỗ trợ',
            value: SupportContactInfo.workingHours,
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4F9D69), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 12, color: _textMuted)),
                  const SizedBox(height: 2),
                  Text(value, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: _textDark)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.copy_rounded, size: 18, color: _textMuted),
          ],
        ),
      ),
    );
  }
}

