import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/garden_provider.dart';

class CreateGardenScreen extends StatefulWidget {
  const CreateGardenScreen({super.key});

  @override
  State<CreateGardenScreen> createState() => _CreateGardenScreenState();
}

class _CreateGardenScreenState extends State<CreateGardenScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  String _selectedEnvironment = "Trong nhà";
  String _selectedLightCondition = "Sáng gián tiếp";
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _environments = [
    {
      'name': 'Trong nhà',
      'icon': Icons.home_outlined,
      'desc': 'Không gian kín, ổn định nhiệt độ',
    },
    {
      'name': 'Ngoài trời',
      'icon': Icons.park_outlined,
      'desc': 'Ban công, sân vườn, thoáng khí',
    },
    {
      'name': 'Văn phòng',
      'icon': Icons.business_outlined,
      'desc': 'Máy lạnh, ánh sáng đèn led',
    },
    {
      'name': 'Nhà kính',
      'icon': Icons.grass_outlined,
      'desc': 'Độ ẩm cao, kiểm soát vi khí hậu',
    },
  ];

  final List<Map<String, dynamic>> _lightConditions = [
    {
      'name': 'Sáng trực tiếp',
      'icon': Icons.wb_sunny_rounded,
      'desc': 'Nắng chiếu trực tiếp > 5 tiếng/ngày',
    },
    {
      'name': 'Sáng gián tiếp',
      'icon': Icons.wb_twilight_rounded,
      'desc': 'Ánh sáng tán xạ qua cửa sổ, ban công râm',
    },
    {
      'name': 'Ánh sáng trung bình',
      'icon': Icons.filter_drama_rounded,
      'desc': 'Khu vực bán râm mát, ánh sáng vừa phải',
    },
    {
      'name': 'Ánh sáng yếu',
      'icon': Icons.nightlight_round,
      'desc': 'Góc khuất trong phòng, chủ yếu đèn điện',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateGarden() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
    final success = await gardenProvider.createGarden(
      name: _nameController.text.trim(),
      environment: _selectedEnvironment,
      lightCondition: _selectedLightCondition,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Đã tạo khu vườn '${_nameController.text.trim()}' thành công!",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF364534),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            gardenProvider.errorMessage ?? "Có lỗi khi tạo khu vườn.",
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF9F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1B1C1A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tạo khu vườn mới',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B1C1A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header minh họa
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF364534).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF364534).withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF364534),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.yard_outlined, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Không gian thực vật riêng",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B1C1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Thiết lập môi trường & điều kiện ánh sáng chuẩn xác giúp AI chăm sóc cây tối ưu.",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF747871),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Tên khu vườn
                Text(
                  '1. Tên khu vườn của bạn',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1C1A),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập tên khu vườn của bạn';
                    }
                    return null;
                  },
                  style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1B1C1A)),
                  decoration: InputDecoration(
                    hintText: 'VD: Vườn Ban Công, Góc Phòng Khách, Vườn Sen Đá...',
                    hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF747871)),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.local_florist_outlined, color: Color(0xFF364534), size: 22),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE4E2DF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE4E2DF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF364534), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 2. Môi trường
                Text(
                  '2. Môi trường trồng cây',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1C1A),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _environments.length,
                  itemBuilder: (context, index) {
                    final item = _environments[index];
                    final isSelected = _selectedEnvironment == item['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEnvironment = item['name'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF364534).withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF364534) : const Color(0xFFE4E2DF),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF364534).withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  item['icon'] as IconData,
                                  size: 20,
                                  color: isSelected ? const Color(0xFF364534) : const Color(0xFF747871),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['name'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected ? const Color(0xFF364534) : const Color(0xFF1B1C1A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['desc'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF747871),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // 3. Điều kiện ánh sáng
                Text(
                  '3. Điều kiện ánh sáng',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1C1A),
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: _lightConditions.map((item) {
                    final isSelected = _selectedLightCondition == item['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedLightCondition = item['name'];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF364534).withOpacity(0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF364534) : const Color(0xFFE4E2DF),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF364534)
                                    : const Color(0xFF364534).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                size: 20,
                                color: isSelected ? Colors.white : const Color(0xFF364534),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected ? const Color(0xFF364534) : const Color(0xFF1B1C1A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['desc'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF747871),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: Color(0xFF364534), size: 22)
                            else
                              const Icon(Icons.radio_button_unchecked, color: Color(0xFFC4C8BF), size: 22),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Nút tạo khu vườn
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleCreateGarden,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF364534),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Tạo khu vườn',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
