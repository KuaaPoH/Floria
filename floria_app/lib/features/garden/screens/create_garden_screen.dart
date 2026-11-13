import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';
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
                  "${context.tr("Đã tạo khu vườn", "Created garden")} '${_nameController.text.trim()}' ${context.tr("thành công!", "successfully!")}",
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
            gardenProvider.errorMessage ?? context.tr("Có lỗi khi tạo khu vườn.", "Error creating garden."),
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
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: c.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('Tạo khu vườn mới', 'Create new garden'),
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
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
                    color: c.surfaceTint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.primary,
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
                              context.tr("Không gian thực vật riêng", "Personal plant sanctuary"),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr(
                                "Thiết lập môi trường & điều kiện ánh sáng chuẩn xác giúp AI chăm sóc cây tối ưu.",
                                "Setting up the environment & light conditions accurately helps AI optimize care.",
                              ),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: c.textMuted,
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
                  context.tr('1. Tên khu vườn của bạn', '1. Your garden name'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return context.tr('Vui lòng nhập tên khu vườn của bạn', 'Please enter your garden name');
                    }
                    return null;
                  },
                  style: GoogleFonts.inter(fontSize: 15, color: c.textPrimary),
                  decoration: InputDecoration(
                    hintText: context.tr('VD: Vườn Ban Công, Góc Phòng Khách, Vườn Sen Đá...', 'e.g., Balcony Garden, Living Room Corner, Succulent Garden...'),
                    hintStyle: GoogleFonts.inter(fontSize: 14, color: c.textMuted),
                    filled: true,
                    fillColor: c.surfaceMuted,
                    prefixIcon: Icon(Icons.local_florist_outlined, color: c.textSecondary, size: 22),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: c.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // 2. Môi trường
                Text(
                  context.tr('2. Môi trường trồng cây', '2. Growing environment'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
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

                    String trEnvName = item['name'] as String;
                    String trEnvDesc = item['desc'] as String;
                    if (context.isEnglish) {
                      if (trEnvName == 'Trong nhà') {
                        trEnvName = 'Indoors';
                        trEnvDesc = 'Enclosed space, stable temp';
                      } else if (trEnvName == 'Ngoài trời') {
                        trEnvName = 'Outdoors';
                        trEnvDesc = 'Balcony, yard, airy';
                      } else if (trEnvName == 'Văn phòng') {
                        trEnvName = 'Office';
                        trEnvDesc = 'Air-conditioned, LED light';
                      } else if (trEnvName == 'Nhà kính') {
                        trEnvName = 'Greenhouse';
                        trEnvDesc = 'High humidity, microclimate';
                      }
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEnvironment = item['name'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? c.surfaceTint : c.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? c.primary : c.border,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: c.primary.withValues(alpha: 0.15),
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
                                  color: isSelected ? c.primaryText : c.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    trEnvName,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected ? c.primaryText : c.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              trEnvDesc,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: c.textMuted,
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
                  context.tr('3. Điều kiện ánh sáng', '3. Light condition'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: _lightConditions.map((item) {
                    final isSelected = _selectedLightCondition == item['name'];

                    String trLightName = item['name'] as String;
                    String trLightDesc = item['desc'] as String;
                    if (context.isEnglish) {
                      if (trLightName == 'Sáng trực tiếp') {
                        trLightName = 'Direct sunlight';
                        trLightDesc = 'Direct light > 5 hrs/day';
                      } else if (trLightName == 'Sáng gián tiếp') {
                        trLightName = 'Indirect light';
                        trLightDesc = 'Diffused light through window, shaded balcony';
                      } else if (trLightName == 'Ánh sáng trung bình') {
                        trLightName = 'Moderate light';
                        trLightDesc = 'Partial shade, moderate illumination';
                      } else if (trLightName == 'Ánh sáng yếu') {
                        trLightName = 'Low light';
                        trLightDesc = 'Deep corner, mostly artificial light';
                      }
                    }

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
                          color: isSelected ? c.surfaceTint : c.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? c.primary : c.border,
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
                                    ? c.primary
                                    : c.surfaceTint,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['icon'] as IconData,
                                size: 20,
                                color: isSelected ? Colors.white : c.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trLightName,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      color: isSelected ? c.primaryText : c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    trLightDesc,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: c.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle, color: c.primary, size: 22)
                            else
                              Icon(Icons.radio_button_unchecked, color: c.textMuted, size: 22),
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
                      backgroundColor: c.primary,
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
                                context.tr('Tạo khu vườn', 'Create garden'),
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
