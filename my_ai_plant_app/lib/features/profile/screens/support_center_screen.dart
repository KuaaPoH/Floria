import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../chatbot/screens/ai_assistant_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';

/// Thông tin liên hệ hỗ trợ
class SupportContactInfo {
  static const String contactName = 'Trần Ngọc Hải';
  static const String hotline = '0866 459 082';
  static const String email = 'trankenn04@gmail.com';
  static const String workingHours = '8:00 – 21:00, Thứ 2 – Chủ nhật';
}

class _FaqItem {
  final String questionVi;
  final String questionEn;
  final String answerVi;
  final String answerEn;
  const _FaqItem({
    required this.questionVi,
    required this.questionEn,
    required this.answerVi,
    required this.answerEn,
  });
}

class _FaqGroup {
  final String titleVi;
  final String titleEn;
  final IconData icon;
  final List<_FaqItem> items;
  const _FaqGroup(this.titleVi, this.titleEn, this.icon, this.items);
}

/// Trung tâm hỗ trợ & Câu hỏi thường gặp
class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  static const List<_FaqGroup> _faqGroups = [
    _FaqGroup('Quét ảnh & Chẩn đoán AI', 'Photo Scan & AI Diagnosis', Icons.document_scanner_outlined, [
      _FaqItem(
        questionVi: 'Làm sao để chụp ảnh lá cho kết quả chính xác nhất?',
        questionEn: 'How to take the most accurate leaf photo?',
        answerVi: '• Chụp ở nơi đủ sáng tự nhiên, tránh ánh nắng gắt hoặc đèn flash chói.\n'
            '• Đưa lá bệnh vào giữa khung hình, cách khoảng 15–30 cm, giữ máy thật chắc để ảnh không bị mờ.\n'
            '• Chỉ chụp 1 lá hoặc 1 cụm lá, nền phía sau càng đơn giản càng tốt.\n'
            '• Nên chụp mặt có vết bệnh rõ nhất (đốm, vàng, cháy mép...).',
        answerEn: '• Take photos in natural lighting, avoid harsh sunlight or direct flash.\n'
            '• Place the affected leaf in the center, 15–30 cm away, keep steady to avoid blur.\n'
            '• Capture 1 leaf or cluster, keep background as simple as possible.\n'
            '• Focus on the clearest symptom area (spots, yellowing, edge burn...).',
      ),
      _FaqItem(
        questionVi: 'AI của Floria nhận diện được những gì?',
        questionEn: 'What can Floria AI recognize?',
        answerVi: 'Floria dùng mô hình EfficientNetV2 để nhận diện loài cây và các bệnh lá phổ biến trên cây trồng, cây cảnh. '
            'Độ chính xác đạt khoảng 90% với loài cây và 92,5% với bệnh lá trên bộ dữ liệu kiểm thử. '
            'Với các loài hiếm hoặc ảnh chất lượng thấp, kết quả có thể chưa chính xác.',
        answerEn: 'Floria uses an EfficientNetV2 model to recognize plant species and common leaf diseases. '
            'Accuracy reaches ~90% on plant species and 92.5% on leaf diseases on test datasets. '
            'For rare species or low-quality photos, results may vary.',
      ),
      _FaqItem(
        questionVi: 'Kết quả chẩn đoán có kèm hướng dẫn chữa trị không?',
        questionEn: 'Do diagnosis results include treatment guides?',
        answerVi: 'Có. Mỗi kết quả chẩn đoán đều có báo cáo gồm nguyên nhân, triệu chứng, cách xử lý và phòng ngừa. '
            'Bạn cũng có thể bấm hỏi thêm Trợ lý Floria để được tư vấn chi tiết theo đúng cây của mình.',
        answerEn: 'Yes. Every diagnosis includes causes, symptoms, treatment, and prevention. '
            'You can also consult Floria Assistant for personalized care instructions.',
      ),
      _FaqItem(
        questionVi: 'Vì sao ảnh của tôi không nhận diện được hoặc kết quả sai?',
        questionEn: 'Why was my photo not recognized or inaccurate?',
        answerVi: 'Nguyên nhân thường gặp: ảnh bị mờ/thiếu sáng, lá quá nhỏ trong khung hình, chụp cả chậu cây thay vì lá, '
            'hoặc loài cây chưa có trong dữ liệu. Hãy chụp lại theo hướng dẫn và kiểm tra kết nối mạng. '
            'Các lần quét được lưu trong mục "Lịch sử quét" để bạn so sánh lại.',
        answerEn: 'Common reasons: blurry/low-light photo, leaf too small, whole pot photographed instead of leaf, '
            'or species not yet supported. Try capturing again with proper lighting and check network connection.',
      ),
    ]),
    _FaqGroup('Lịch chăm sóc & Nhắc nhở', 'Care Schedule & Reminders', Icons.water_drop_outlined, [
      _FaqItem(
        questionVi: 'Tại sao tôi không thấy thông báo nhắc tưới cây?',
        questionEn: 'Why am I not receiving watering reminder notifications?',
        answerVi: 'Hiện tại Floria nhắc nhở bằng banner hiển thị ngay trong ứng dụng khi bạn đang mở app. '
            'Hãy kiểm tra: (1) đã bật "Nhắc nhở" trong mục Nhắc tưới, (2) không nằm trong khung giờ Không làm phiền, '
            '(3) đã qua giờ nhắc của cây đó trong ngày.',
        answerEn: 'Currently Floria displays in-app reminder banners when you open the app. '
            'Please verify: (1) Reminders are enabled in Reminders Hub, (2) Not in Do Not Disturb hours, '
            '(3) The scheduled time has passed for today.',
      ),
      _FaqItem(
        questionVi: 'Lỡ quên tưới cây vài ngày thì lịch có bị sai không?',
        questionEn: 'If I miss watering for a few days, will the schedule break?',
        answerVi: 'Không. Cây sẽ chuyển sang trạng thái "Cần tưới nước" và hiện trong danh sách việc cần làm. '
            'Khi bạn bấm hoàn thành, chu kỳ tiếp theo sẽ được tính lại từ thời điểm bạn thực sự tưới.',
        answerEn: 'No. The plant will switch to "Needs Water" and appear in your task list. '
            'When you mark it completed, the next cycle will calculate from your actual watering date.',
      ),
      _FaqItem(
        questionVi: 'Làm sao để đổi chu kỳ tưới hoặc giờ nhắc của một cây?',
        questionEn: 'How do I change the watering frequency or reminder time for a plant?',
        answerVi: 'Vào Khu vườn → chọn cây → mục Lịch chăm sóc để chỉnh số ngày tưới, bón phân, kiểm tra sâu bệnh và giờ nhắc riêng. '
            'Giờ nhắc mặc định cho cây mới thêm được chỉnh trong Cá nhân → Nhắc tưới.',
        answerEn: 'Go to Garden → select plant → Care Schedule to adjust watering, fertilizing, pest check intervals and specific reminder times.',
      ),
    ]),
    _FaqGroup('Tài khoản & Mua sắm', 'Account & Shopping', Icons.shopping_bag_outlined, [
      _FaqItem(
        questionVi: 'Tôi muốn đổi mật khẩu thì làm thế nào?',
        questionEn: 'How can I change my password?',
        answerVi: 'Vào Cá nhân → Cài đặt → Đổi mật khẩu, Floria sẽ gửi đường dẫn đặt lại mật khẩu về email của bạn. '
            'Nếu bạn đăng nhập bằng Google, mật khẩu được quản lý bởi tài khoản Google nên không đổi trong ứng dụng.',
        answerEn: 'Go to Profile → Settings → Change Password. Floria will email you a password reset link. '
            'If you signed in with Google, credentials are managed by Google.',
      ),
      _FaqItem(
        questionVi: 'Thanh toán COD và thanh toán bằng thẻ khác nhau thế nào?',
        questionEn: 'What is the difference between COD and Card payment?',
        answerVi: 'COD (thanh toán khi nhận hàng): bạn trả tiền mặt cho người giao hàng. '
            'Thanh toán bằng thẻ: dùng thẻ ngân hàng đã lưu trong mục Địa chỉ & Thanh toán. '
            'Bạn có thể đổi phương thức mặc định bất cứ lúc nào trước khi đặt hàng.',
        answerEn: 'COD (Cash on Delivery): pay cash upon delivery. '
            'Card / Online payment: VNPay or saved card. You can change payment method anytime before placing an order.',
      ),
      _FaqItem(
        questionVi: 'Vật tư mua trên Floria có được đổi trả không?',
        questionEn: 'Can garden supplies purchased on Floria be returned?',
        answerVi: 'Sản phẩm lỗi, hư hỏng do vận chuyển hoặc giao sai được hỗ trợ đổi trả. '
            'Vui lòng liên hệ bộ phận hỗ trợ kèm ảnh sản phẩm và mã đơn hàng để được xử lý nhanh nhất.',
        answerEn: 'Defective products or transit damages are eligible for return/replacement. '
            'Please contact support with photos and order code for prompt resolution.',
      ),
    ]),
  ];

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    final c = context.colors;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: c.surface,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Text(
            "${context.tr('Đã sao chép', 'Copied')} $label: $text",
            style: GoogleFonts.inter(color: c.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: c.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('Trung tâm hỗ trợ', 'Support Center'),
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: c.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _buildAssistantBanner(context),
          const SizedBox(height: 24),
          for (final group in _faqGroups) ...[
            _buildGroupTitle(context, group),
            const SizedBox(height: 8),
            _buildFaqCard(context, group),
            const SizedBox(height: 20),
          ],
          _buildGroupTitleText(context, context.tr('LIÊN HỆ VỚI CHÚNG TÔI', 'CONTACT US')),
          const SizedBox(height: 8),
          _buildContactCard(context),
        ],
      ),
    );
  }

  Widget _buildAssistantBanner(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: c.isDark
              ? const [Color(0xFF1E3A24), Color(0xFF16251A)]
              : const [Color(0xFF2E6F40), Color(0xFF4F9D69)],
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
                  context.tr('Chúng tôi có thể giúp gì?', 'How can we help?'),
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('Xem các câu hỏi thường gặp bên dưới hoặc hỏi ngay Trợ lý Floria 24/7.', 'Check FAQ below or ask Floria Assistant 24/7.'),
                  style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(context.tr('Hỏi Trợ lý Floria', 'Ask Floria Assistant'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2E6F40),
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

  Widget _buildGroupTitle(BuildContext context, _FaqGroup group) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(group.icon, size: 16, color: c.textMuted),
          const SizedBox(width: 6),
          Text(
            context.tr(group.titleVi.toUpperCase(), group.titleEn.toUpperCase()),
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTitleText(BuildContext context, String title) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: c.textMuted, letterSpacing: 1),
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final c = context.colors;
    return BoxDecoration(
      color: c.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: c.border),
      boxShadow: [
        BoxShadow(color: c.shadow, blurRadius: 12, offset: const Offset(0, 4)),
      ],
    );
  }

  Widget _buildFaqCard(BuildContext context, _FaqGroup group) {
    final c = context.colors;
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < group.items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.border),
            Theme(
              data: ThemeData(dividerColor: Colors.transparent, splashColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                iconColor: c.primary,
                collapsedIconColor: c.textMuted,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: Text(
                  context.tr(group.items[i].questionVi, group.items[i].questionEn),
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.textPrimary),
                ),
                children: [
                  Text(
                    context.tr(group.items[i].answerVi, group.items[i].answerEn),
                    style: GoogleFonts.inter(fontSize: 13.5, color: c.textSecondary, height: 1.55),
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
    final c = context.colors;
    return Container(
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          _buildContactRow(
            context,
            icon: Icons.person_outline_rounded,
            title: context.tr('Người phụ trách hỗ trợ', 'Support Specialist'),
            value: SupportContactInfo.contactName,
          ),
          Divider(height: 1, color: c.border),
          _buildContactRow(
            context,
            icon: Icons.phone_in_talk_outlined,
            title: context.tr('Hotline', 'Hotline'),
            value: SupportContactInfo.hotline,
            onTap: () => _copy(context, SupportContactInfo.hotline, 'Hotline'),
          ),
          Divider(height: 1, color: c.border),
          _buildContactRow(
            context,
            icon: Icons.mail_outline_rounded,
            title: context.tr('Email', 'Email'),
            value: SupportContactInfo.email,
            onTap: () => _copy(context, SupportContactInfo.email, 'Email'),
          ),
          Divider(height: 1, color: c.border),
          _buildContactRow(
            context,
            icon: Icons.schedule_rounded,
            title: context.tr('Thời gian hỗ trợ', 'Working Hours'),
            value: context.tr(SupportContactInfo.workingHours, '8:00 AM – 9:00 PM, Mon – Sun'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: c.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 12, color: c.textMuted)),
                  const SizedBox(height: 2),
                  Text(value, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.textPrimary)),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.copy_rounded, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
