import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _saveImages = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7F3).withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(color: const Color(0xFF17231A).withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: const Icon(Icons.chevron_left, color: Color(0xFF1F2A21)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cài đặt',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2A21),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Group 1: HIỂN THỊ
          _buildGroupTitle('HIỂN THỊ'),
          const SizedBox(height: 8),
          _buildSettingsContainer([
            _buildToggleTile(
              icon: Icons.dark_mode_outlined,
              title: 'Giao diện tối',
              value: _darkMode,
              onChanged: (val) => setState(() => _darkMode = val),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0x144F9D69)),
            _buildArrowTile(
              icon: Icons.language_outlined,
              title: 'Ngôn ngữ',
              valueText: 'Tiếng Việt',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),

          // Group 2: TÙY CHỈNH
          _buildGroupTitle('TÙY CHỈNH'),
          const SizedBox(height: 8),
          _buildSettingsContainer([
            _buildToggleTile(
              icon: Icons.notifications_none_outlined,
              title: 'Nhắc nhở tưới cây',
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0x144F9D69)),
            _buildToggleTile(
              icon: Icons.image_outlined,
              title: 'Lưu ảnh quét vào Thư viện',
              value: _saveImages,
              onChanged: (val) => setState(() => _saveImages = val),
            ),
          ]),
          const SizedBox(height: 24),

          // Group 3: THÔNG TIN
          _buildGroupTitle('THÔNG TIN'),
          const SizedBox(height: 8),
          _buildSettingsContainer([
            _buildArrowTile(
              icon: null,
              title: 'Điều khoản bảo mật',
              onTap: () {},
            ),
            const Divider(height: 1, thickness: 1, color: Color(0x144F9D69)),
            _buildValueTile(
              title: 'Phiên bản ứng dụng',
              valueText: 'v2.4.1',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6A756B),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4F9D69).withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17231A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF4F9D69), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF1F2A21),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF4F9D69),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildArrowTile({
    IconData? icon,
    required String title,
    String? valueText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: const Color(0xFF4F9D69), size: 24),
                  const SizedBox(width: 12),
                ],
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF1F2A21),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (valueText != null) ...[
                  Text(
                    valueText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6A756B),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Icon(Icons.chevron_right, color: Color(0xFF6A756B), size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueTile({
    required String title,
    required String valueText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF1F2A21),
            ),
          ),
          Text(
            valueText,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6A756B),
            ),
          ),
        ],
      ),
    );
  }
}
