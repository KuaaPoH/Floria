import re

file_path = r'D:\Plan\utrasupervip\my_ai_plant_app\lib\features\home\screens\home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
if "import '../../chatbot/screens/ai_assistant_screen.dart';" not in content:
    content = content.replace("import '../../scan/screens/scan_screen.dart';", "import '../../scan/screens/scan_screen.dart';\nimport '../../chatbot/screens/ai_assistant_screen.dart';")

# 2. Insert _buildAIAssistantSection in build method (both places)
old_body_part_1 = '''                      _buildMyGardenSection(context, isTablet),
                      const SizedBox(height: 28),
                      _buildTodayScheduleSection(context),'''

new_body_part_1 = '''                      _buildMyGardenSection(context, isTablet),
                      const SizedBox(height: 28),
                      _buildAIAssistantSection(context),
                      const SizedBox(height: 28),
                      _buildTodayScheduleSection(context),'''

content = content.replace(old_body_part_1, new_body_part_1)

old_body_part_2 = '''                          _buildMyGardenSection(context, isTablet),
                          const SizedBox(height: 28),
                          _buildTodayScheduleSection(context),'''

new_body_part_2 = '''                          _buildMyGardenSection(context, isTablet),
                          const SizedBox(height: 28),
                          _buildAIAssistantSection(context),
                          const SizedBox(height: 28),
                          _buildTodayScheduleSection(context),'''

content = content.replace(old_body_part_2, new_body_part_2)

# 3. Add _buildAIAssistantSection function before _buildTodayScheduleSection
ai_section_code = '''  Widget _buildAIAssistantSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy, color: Color(0xFF006D35), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Trợ Lý AI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF006D35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Xin chào, tôi là trợ lý chăm sóc cây trồng của bạn, tôi có thể giúp gì cho bạn?',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              color: const Color(0xFF3B4A3D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiAssistantScreen()),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
              label: Text(
                'Trò chuyện mới',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006D35),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF006D35).withOpacity(0.4),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTodayScheduleSection'''

content = content.replace('  Widget _buildTodayScheduleSection', ai_section_code)

# 4. Update bottom nav bar text and icon in home_screen.dart local bottom nav
content = content.replace('_buildNavButton(Icons.smart_toy, "Trợ Lý AI", false),', '_buildNavButton(Icons.shopping_cart, "Cửa Hàng", false),')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Updated home_screen.dart successfully')
