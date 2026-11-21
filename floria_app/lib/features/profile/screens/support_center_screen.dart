import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../chatbot/screens/ai_assistant_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';
import '../../../core/widgets/app_toast.dart';

/// Thông tin liên hệ hỗ trợ
class SupportContactInfo {
  static const String contactName = 'Trần Ngọc Hải';
  static const String hotline = '0866 459 082';
  static const String email = 'trankenn04@gmail.com';
  static const String workingHours = '8:00 – 21:00, Thứ 2 – Chủ nhật';
}

class _SupportArticle {
  final String id;
  final String category;
  final String categoryVi;
  final String categoryEn;
  final String questionVi;
  final String questionEn;
  final String answerVi;
  final String answerEn;
  final int order;

  const _SupportArticle({
    required this.id,
    required this.category,
    required this.categoryVi,
    required this.categoryEn,
    required this.questionVi,
    required this.questionEn,
    required this.answerVi,
    required this.answerEn,
    required this.order,
  });

  factory _SupportArticle.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    final qVi = (d['questionVi'] ?? '').toString();
    final aVi = (d['answerVi'] ?? '').toString();
    return _SupportArticle(
      id: doc.id,
      category: (d['category'] ?? 'other').toString(),
      categoryVi: (d['categoryVi'] ?? 'Hỗ trợ chung').toString(),
      categoryEn: (d['categoryEn'] ?? 'General Support').toString(),
      questionVi: qVi,
      questionEn: (d['questionEn']?.toString().trim().isNotEmpty == true)
          ? d['questionEn'].toString()
          : qVi,
      answerVi: aVi,
      answerEn: (d['answerEn']?.toString().trim().isNotEmpty == true)
          ? d['answerEn'].toString()
          : aVi,
      order: (d['order'] is num) ? (d['order'] as num).toInt() : 999,
    );
  }
}

class _FaqGroup {
  final String category;
  final String titleVi;
  final String titleEn;
  final IconData icon;
  final List<_SupportArticle> items;

  const _FaqGroup({
    required this.category,
    required this.titleVi,
    required this.titleEn,
    required this.icon,
    required this.items,
  });
}

/// Trung tâm hỗ trợ & Câu hỏi thường gặp (đọc trực tiếp từ Firestore SupportArticles)
class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  static IconData _iconForCategory(String category) {
    switch (category) {
      case 'scan':
        return Icons.document_scanner_outlined;
      case 'care':
        return Icons.water_drop_outlined;
      case 'account':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  List<_FaqGroup> _groupArticles(List<_SupportArticle> articles) {
    final Map<String, List<_SupportArticle>> map = {};
    for (final item in articles) {
      map.putIfAbsent(item.category, () => []).add(item);
    }
    final groups = <_FaqGroup>[];
    for (final entry in map.entries) {
      final first = entry.value.first;
      groups.add(
        _FaqGroup(
          category: entry.key,
          titleVi: first.categoryVi,
          titleEn: first.categoryEn,
          icon: _iconForCategory(entry.key),
          items: entry.value,
        ),
      );
    }
    return groups;
  }

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppToast.show(
      context,
      "${context.tr('Đã sao chép', 'Copied')} $label: $text",
      duration: const Duration(seconds: 2),
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
      body: SafeArea(
        top: false,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('SupportArticles').snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            final articles = docs
                .where((doc) => doc.data()['visible'] != false)
                .map(_SupportArticle.fromDoc)
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order));
            final groups = _groupArticles(articles);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                _buildAssistantBanner(context),
                const SizedBox(height: 24),
                if (snapshot.connectionState == ConnectionState.waiting && articles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator(color: c.primary)),
                  )
                else if (groups.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: _cardDecoration(context),
                    child: Text(
                      context.tr(
                        'Hiện chưa có bài viết hướng dẫn nào. Bạn có thể hỏi trực tiếp Trợ lý Floria hoặc liên hệ bên dưới.',
                        'No support articles available yet. You can ask Floria Assistant or contact us below.',
                      ),
                      style: GoogleFonts.inter(fontSize: 13.5, color: c.textSecondary, height: 1.5),
                    ),
                  )
                else
                  for (final group in groups) ...[
                    _buildGroupTitle(context, group),
                    const SizedBox(height: 8),
                    _buildFaqCard(context, group),
                    const SizedBox(height: 20),
                  ],
                _buildGroupTitleText(context, context.tr('LIÊN HỆ VỚI CHÚNG TÔI', 'CONTACT US')),
                const SizedBox(height: 8),
                _buildContactCard(context),
              ],
            );
          },
        ),
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
            value: SupportContactInfo.workingHours,
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: c.primary),
            ),
            const SizedBox(width: 14),
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
