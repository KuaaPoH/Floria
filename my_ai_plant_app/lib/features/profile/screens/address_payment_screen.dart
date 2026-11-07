import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/user_checkout_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';

class _AdminUnit {
  final String id;
  final String code;
  final String fullName;
  final double? latitude;
  final double? longitude;

  _AdminUnit({
    required this.id,
    required this.code,
    required this.fullName,
    this.latitude,
    this.longitude,
  });

  // Tọa độ trung tâm của 34 Tỉnh/Thành phố mới sau sáp nhập
  static const Map<String, List<double>> _provinceCenters = {
    '01': [21.0285, 105.8542], // TP. Hà Nội
    '04': [22.6663, 106.2522], // Cao Bằng
    '08': [21.8236, 105.2142], // Tuyên Quang
    '11': [21.3860, 103.0230], // Điện Biên
    '12': [22.3964, 103.4582], // Lai Châu
    '14': [21.3256, 103.9188], // Sơn La
    '15': [22.4856, 103.9707], // Lào Cai
    '19': [21.5942, 105.8482], // Thái Nguyên
    '20': [21.8537, 106.7615], // Lạng Sơn
    '22': [20.9599, 107.0425], // Quảng Ninh
    '24': [21.1861, 106.0763], // Bắc Ninh
    '25': [21.3227, 105.4020], // Phú Thọ
    '31': [20.8449, 106.6881], // TP. Hải Phòng
    '33': [20.6464, 106.0511], // Hưng Yên
    '37': [20.2506, 105.9745], // Ninh Bình
    '38': [19.8067, 105.7852], // Thanh Hóa
    '40': [18.6796, 105.6813], // Nghệ An
    '42': [18.3428, 105.9057], // Hà Tĩnh
    '44': [16.8163, 107.1003], // Quảng Trị
    '46': [16.4637, 107.5909], // TP. Huế
    '48': [16.0544, 108.2022], // TP. Đà Nẵng
    '51': [15.1214, 108.8044], // Quảng Ngãi
    '52': [13.7830, 109.2197], // Gia Lai
    '56': [12.2388, 109.1967], // Khánh Hòa
    '66': [12.6667, 108.0500], // Đắk Lắk
    '68': [11.9404, 108.4583], // Lâm Đồng
    '75': [10.9574, 106.8427], // Đồng Nai
    '79': [10.7769, 106.7009], // TP. Hồ Chí Minh
    '80': [11.3100, 106.0983], // Tây Ninh
    '82': [10.4594, 105.6325], // Đồng Tháp
    '86': [10.2537, 105.9722], // Vĩnh Long
    '91': [10.3864, 105.4352], // An Giang
    '92': [10.0452, 105.7469], // TP. Cần Thơ
    '96': [9.1768, 105.1524],  // Cà Mau
  };

  factory _AdminUnit.fromJson(Map<String, dynamic> json) {
    final code = json['code']?.toString() ?? '';
    double? lat = double.tryParse(json['latitude']?.toString() ?? '');
    double? lng = double.tryParse(json['longitude']?.toString() ?? '');
    if ((lat == null || lng == null) && _provinceCenters.containsKey(code)) {
      lat = _provinceCenters[code]![0];
      lng = _provinceCenters[code]![1];
    }
    return _AdminUnit(
      id: json['id']?.toString() ?? '',
      code: code,
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      latitude: lat,
      longitude: lng,
    );
  }
}

class AddressAndPaymentScreen extends StatefulWidget {
  const AddressAndPaymentScreen({super.key});

  @override
  State<AddressAndPaymentScreen> createState() => _AddressAndPaymentScreenState();
}

class _AddressAndPaymentScreenState extends State<AddressAndPaymentScreen> {
  final Dio _dio = Dio();

  void _showModernToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final c = context.colors;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        duration: const Duration(seconds: 3),
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? c.errorBg : c.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isError
                      ? const Color(0xFFFF6B6B).withValues(alpha: 0.35)
                      : c.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isError
                          ? const Color(0xFFFF6B6B).withValues(alpha: 0.18)
                          : c.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isError ? Icons.error_outline_rounded : Icons.check_rounded,
                      color: isError ? const Color(0xFFFF8A80) : const Color(0xFF81C784),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<_AdminUnit>> _fetchAdminUnits(int level, String parentId) async {
    try {
      final response = await _dio.get('https://esgoo.net/api-tinhthanh-new/$level/$parentId.htm');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['error'] == 0 && data['data'] is List) {
          return (data['data'] as List)
              .map((e) => _AdminUnit.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi tải danh mục hành chính mới ($level/$parentId): $e");
    }
    return [];
  }

  Future<List<double>?> _fetchWardCoordinates(String wardCode) async {
    if (wardCode.isEmpty) return null;
    try {
      final response = await _dio.get('https://esgoo.net/api-tinhthanh/5/$wardCode.htm');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data is Map) {
          final lat = double.tryParse(data['latitude']?.toString() ?? '');
          final lng = double.tryParse(data['longitude']?.toString() ?? '');
          if (lat != null && lng != null) {
            return [lat, lng];
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi lấy tọa độ Phường/Xã ($wardCode): $e");
    }
    return null;
  }

  void _showAddressDialog(AuthProvider authProvider, {ShippingAddress? existing}) {
    final nameCtrl = TextEditingController(
      text: existing?.recipientName ?? authProvider.userName ?? "",
    );
    final phoneCtrl = TextEditingController(text: existing?.phone ?? "");
    final streetCtrl = TextEditingController(
      text: existing?.streetDetail ?? existing?.address ?? "",
    );
    String selectedLabel = existing?.label ?? "Nhà riêng";
    bool isDefault = existing?.isDefault ?? authProvider.addresses.isEmpty;

    List<_AdminUnit> provinces = [];
    List<_AdminUnit> wards = [];

    _AdminUnit? selectedProvince;
    _AdminUnit? selectedWard;

    bool isLoadingProvinces = true;
    bool isLoadingWards = false;

    double pinLat = existing?.latitude ?? 10.7769;
    double pinLng = existing?.longitude ?? 106.7009;
    int mapZoom = existing?.latitude != null ? 16 : 12;
    bool initialized = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (!initialized) {
            initialized = true;
            _fetchAdminUnits(1, '0').then((list) async {
              if (!ctx.mounted) return;
              setModalState(() {
                provinces = list;
                isLoadingProvinces = false;
              });

              // Khôi phục Tỉnh/Thành phố & Phường/Xã nếu đang sửa địa chỉ đã lưu
              if (existing?.provinceName != null) {
                final foundP = list.where((p) => p.fullName == existing!.provinceName).toList();
                if (foundP.isNotEmpty) {
                  selectedProvince = foundP.first;
                  setModalState(() => isLoadingWards = true);
                  final wList = await _fetchAdminUnits(2, selectedProvince!.id);
                  if (!ctx.mounted) return;
                  setModalState(() {
                    wards = wList;
                    isLoadingWards = false;
                    if (existing?.wardName != null) {
                      final foundW = wList.where((w) => w.fullName == existing!.wardName).toList();
                      if (foundW.isNotEmpty) {
                        selectedWard = foundW.first;
                      }
                    }
                  });
                }
              }
            });
          }

          final c = context.colors;
          return AlertDialog(
            backgroundColor: c.surface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.surfaceTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_location_alt_outlined, color: c.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    existing == null
                        ? context.tr("Thêm địa chỉ nhận hàng", "Add Delivery Address")
                        : context.tr("Cập nhật địa chỉ", "Update Address"),
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Họ tên & SĐT
                    TextField(
                      controller: nameCtrl,
                      style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
                      decoration: _inputDecoration(
                        context,
                        context.tr("Họ và tên người nhận", "Recipient Name"),
                        Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
                      decoration: _inputDecoration(
                        context,
                        context.tr("Số điện thoại", "Phone Number"),
                        Icons.phone_outlined,
                        hint: context.tr("VD: 0912 345 678", "E.g. 0912 345 678"),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. Địa chỉ hành chính mới (34 Tỉnh/Thành phố -> Phường/Xã)
                    Text(
                      context.tr("ĐỊA CHỈ", "ADDRESS"),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: c.primary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Dropdown Tỉnh / Thành phố (34 Tỉnh/Thành mới)
                    _buildAdminDropdown(
                      context: context,
                      label: context.tr("Tỉnh / Thành phố", "Province / City"),
                      icon: Icons.location_city_rounded,
                      isLoading: isLoadingProvinces,
                      value: selectedProvince,
                      items: provinces,
                      onChanged: (val) async {
                        if (val == null) return;
                        setModalState(() {
                          selectedProvince = val;
                          selectedWard = null;
                          wards = [];
                          isLoadingWards = true;
                          if (val.latitude != null && val.longitude != null) {
                            pinLat = val.latitude!;
                            pinLng = val.longitude!;
                            mapZoom = 12;
                          }
                        });
                        final wList = await _fetchAdminUnits(2, val.id);
                        if (!ctx.mounted) return;
                        setModalState(() {
                          wards = wList;
                          isLoadingWards = false;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // Dropdown Phường / Xã / Đặc khu trực thuộc Tỉnh/Thành phố
                    _buildAdminDropdown(
                      context: context,
                      label: context.tr("Phường / Xã / Đặc khu", "Ward / Commune"),
                      icon: Icons.signpost_outlined,
                      isLoading: isLoadingWards,
                      value: selectedWard,
                      items: wards,
                      enabled: selectedProvince != null,
                      onChanged: (val) async {
                        if (val == null) return;
                        setModalState(() {
                          selectedWard = val;
                          if (val.latitude != null && val.longitude != null) {
                            pinLat = val.latitude!;
                            pinLng = val.longitude!;
                            mapZoom = 15;
                          }
                        });
                        // Lấy tọa độ chính xác theo mã Phường/Xã từ API hành chính
                        final coords = await _fetchWardCoordinates(val.code);
                        if (coords != null && ctx.mounted) {
                          setModalState(() {
                            pinLat = coords[0];
                            pinLng = coords[1];
                            mapZoom = 15;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Số nhà, tên đường cụ thể
                    TextField(
                      controller: streetCtrl,
                      style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
                      decoration: _inputDecoration(
                        context,
                        context.tr("Số nhà, tên đường, tòa nhà", "Street address, building"),
                        Icons.home_outlined,
                        hint: context.tr("VD: Số 18 Ngõ 45 Đường Nguyễn Trãi", "E.g. No. 18, Alley 45..."),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Bản đồ tương tác ghim vị trí nhận hàng
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.map_outlined, size: 16, color: c.primary),
                            const SizedBox(width: 6),
                            Text(
                              context.tr("GHIM VỊ TRÍ TRÊN BẢN ĐỒ", "PIN LOCATION ON MAP"),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: c.primary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          context.tr("Chạm hoặc kéo để đặt ghim", "Tap or drag to place pin"),
                          style: GoogleFonts.inter(fontSize: 11, color: c.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InteractiveMapPicker(
                      latitude: pinLat,
                      longitude: pinLng,
                      zoom: mapZoom,
                      onLocationChanged: (newLat, newLng, newZoom) {
                        setModalState(() {
                          pinLat = newLat;
                          pinLng = newLng;
                          mapZoom = newZoom;
                        });
                      },
                      onStreetPicked: (pickedStreet) {
                        if (pickedStreet.isNotEmpty) {
                          streetCtrl.text = pickedStreet;
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // 4. Loại địa chỉ & Mặc định
                    Text(
                      context.tr("Loại địa chỉ", "Address Type"),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        {"vi": "Nhà riêng", "en": "Home"},
                        {"vi": "Khu vườn", "en": "Garden"},
                        {"vi": "Văn phòng", "en": "Office"},
                      ].map((type) {
                        final labelVi = type["vi"]!;
                        final labelEn = type["en"]!;
                        final isSelected = selectedLabel == labelVi;
                        return ChoiceChip(
                          label: Text(
                            context.tr(labelVi, labelEn),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : c.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: c.primary,
                          backgroundColor: c.surfaceMuted,
                          checkmarkColor: Colors.white,
                          onSelected: (_) => setModalState(() => selectedLabel = labelVi),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    _buildCircularCheckOption(
                      context: context,
                      label: context.tr("Đặt làm địa chỉ nhận hàng mặc định", "Set as default delivery address"),
                      value: isDefault,
                      onChanged: (val) => setModalState(() => isDefault = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  context.tr("Hủy", "Cancel"),
                  style: GoogleFonts.inter(color: c.textMuted, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty ||
                      phoneCtrl.text.trim().isEmpty ||
                      streetCtrl.text.trim().isEmpty) {
                    _showModernToast(
                      context.tr("Vui lòng nhập họ tên, SĐT và số nhà/tên đường!", "Please enter name, phone, and street address!"),
                      isError: true,
                    );
                    return;
                  }

                  final parts = <String>[
                    streetCtrl.text.trim(),
                    if (selectedWard != null) selectedWard!.fullName,
                    if (selectedProvince != null) selectedProvince!.fullName,
                  ];
                  final fullAddress = parts.join(', ');

                  final addr = ShippingAddress(
                    id: existing?.id ?? 'addr_${DateTime.now().millisecondsSinceEpoch}',
                    recipientName: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    address: fullAddress,
                    provinceName: selectedProvince?.fullName ?? existing?.provinceName,
                    wardName: selectedWard?.fullName ?? existing?.wardName,
                    streetDetail: streetCtrl.text.trim(),
                    latitude: pinLat,
                    longitude: pinLng,
                    label: selectedLabel,
                    isDefault: isDefault,
                  );
                  final successMsg = existing == null
                      ? context.tr("Đã lưu địa chỉ & vị trí bản đồ!", "Saved address & map location!")
                      : context.tr("Đã cập nhật địa chỉ!", "Updated address!");
                  await authProvider.saveShippingAddress(addr);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _showModernToast(successMsg);
                },
                child: Text(
                  context.tr("Lưu địa chỉ", "Save address"),
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAdminDropdown({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isLoading,
    required _AdminUnit? value,
    required List<_AdminUnit> items,
    required ValueChanged<_AdminUnit?> onChanged,
    bool enabled = true,
  }) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: enabled ? c.surfaceMuted : (c.isDark ? Colors.grey[850] : Colors.grey[100]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? c.border : c.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: enabled ? c.primary : c.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "${context.tr("Đang tải", "Loading")} $label...",
                          style: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
                        ),
                      ],
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<_AdminUnit>(
                      value: items.contains(value) ? value : null,
                      isExpanded: true,
                      dropdownColor: c.surface,
                      hint: Text(
                        enabled
                            ? "${context.tr("Chọn", "Select")} $label"
                            : context.tr("Vui lòng chọn cấp trên trước", "Please select higher level first"),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: enabled ? c.textMuted : c.textMuted.withValues(alpha: 0.5),
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: enabled ? c.primary : c.textMuted,
                      ),
                      items: enabled
                          ? items.map((u) {
                              return DropdownMenuItem<_AdminUnit>(
                                value: u,
                                child: Text(
                                  u.fullName,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    color: c.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList()
                          : [],
                      onChanged: enabled ? onChanged : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddCardDialog(AuthProvider authProvider) {
    final c = context.colors;
    final bankCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final holderCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    bool isDefault = authProvider.savedCards.isEmpty;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.surfaceTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add_card_rounded, color: c.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr("Thêm thẻ thanh toán", "Add Payment Card"),
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      bankCtrl.text = "NCB Bank";
                      numberCtrl.text = "9704198526191432198";
                      holderCtrl.text = "NGUYEN VAN A";
                      dateCtrl.text = "07/15";
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: c.surfaceTint,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: c.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr("Điền nhanh Thẻ NCB mẫu", "Fill Sample NCB Card"),
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: c.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: bankCtrl,
                    style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
                    decoration: _inputDecoration(
                      context,
                      context.tr("Tên Ngân hàng", "Bank Name"),
                      Icons.account_balance_outlined,
                      hint: "VD: Vietcombank, MB Bank, NCB Bank...",
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: numberCtrl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
                    decoration: _inputDecoration(
                      context,
                      context.tr("Số thẻ ATM / Ngân hàng", "Card Number"),
                      Icons.credit_card_rounded,
                      hint: "VD: 9704198526191432198",
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: holderCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
                          decoration: _inputDecoration(
                            context,
                            context.tr("Tên chủ thẻ (Không dấu)", "Cardholder Name"),
                            Icons.badge_outlined,
                            hint: "NGUYEN VAN A",
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: dateCtrl,
                          style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
                          decoration: _inputDecoration(
                            context,
                            context.tr("Ngày cấp", "Issue Date"),
                            Icons.calendar_today_outlined,
                            hint: "07/15",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCircularCheckOption(
                    context: context,
                    label: context.tr("Đặt làm thẻ thanh toán mặc định", "Set as default payment card"),
                    value: isDefault,
                    onChanged: (val) => setModalState(() => isDefault = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                context.tr("Hủy", "Cancel"),
                style: GoogleFonts.inter(color: c.textMuted, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (bankCtrl.text.trim().isEmpty ||
                    numberCtrl.text.trim().isEmpty ||
                    holderCtrl.text.trim().isEmpty) {
                  _showModernToast(
                    context.tr(
                      "Vui lòng nhập đầy đủ tên ngân hàng, số thẻ và chủ thẻ!",
                      "Please fill in bank name, card number and holder name!",
                    ),
                    isError: true,
                  );
                  return;
                }
                final card = SavedPaymentCard(
                  id: 'card_${DateTime.now().millisecondsSinceEpoch}',
                  bankName: bankCtrl.text.trim(),
                  cardNumber: numberCtrl.text.trim(),
                  cardHolder: holderCtrl.text.trim().toUpperCase(),
                  issueDate: dateCtrl.text.trim().isNotEmpty ? dateCtrl.text.trim() : "07/15",
                  isDefault: isDefault,
                );
                final successMsg = context.tr("Đã lưu thẻ ngân hàng thành công!", "Saved bank card successfully!");
                await authProvider.savePaymentCard(card);
                if (ctx.mounted) Navigator.pop(ctx);
                _showModernToast(successMsg);
              },
              child: Text(
                context.tr("Lưu thẻ", "Save card"),
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularCheckOption({
    required BuildContext context,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final c = context.colors;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? c.primary : c.surfaceMuted,
                border: Border.all(
                  color: value ? c.primary : c.border,
                  width: 1.6,
                ),
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: c.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                  color: value ? c.primary : c.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label, IconData icon, {String? hint}) {
    final c = context.colors;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: c.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: c.primary, size: 20),
      labelStyle: GoogleFonts.inter(color: c.textMuted, fontSize: 13),
      filled: true,
      fillColor: c.surfaceMuted,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c.border)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final authProvider = Provider.of<AuthProvider>(context);
    final addresses = authProvider.addresses;
    final cards = authProvider.savedCards;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr("Địa chỉ & Thẻ thanh toán", "Addresses & Payment Cards"),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= 1. SỔ ĐỊA CHỈ NHẬN HÀNG =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: c.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      context.tr("SỔ ĐỊA CHỈ NHẬN HÀNG", "SAVED DELIVERY ADDRESSES"),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: c.primary,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddressDialog(authProvider),
                  icon: Icon(Icons.add_rounded, size: 18, color: c.primary),
                  label: Text(
                    context.tr("Thêm địa chỉ", "Add address"),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (addresses.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.surfaceTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_location_alt_outlined, color: c.primary, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr("Chưa có địa chỉ nhận hàng nào được lưu", "No shipping addresses saved yet"),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr("Chọn Tỉnh/Thành, Quận/Huyện, Phường/Xã và ghim vị trí bản đồ", "Select Province/City, District, Ward and pin map location"),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showAddressDialog(authProvider),
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: Text(
                        context.tr("Thêm địa chỉ ngay", "Add address now"),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...addresses.map((addr) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: addr.isDefault
                            ? c.primary
                            : c.border,
                        width: addr.isDefault ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: c.shadow,
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: c.surfaceMuted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                addr.label,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: c.primary,
                                ),
                              ),
                            ),
                            if (addr.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.surfaceTint,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  context.tr("Mặc định", "Default"),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: c.primary,
                                  ),
                                ),
                              ),
                            ],
                            if (addr.latitude != null && addr.longitude != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.isDark ? const Color(0xFF1E3A5F) : const Color(0xFFEAF2FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.pin_drop_rounded, size: 11, color: c.isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0)),
                                    const SizedBox(width: 3),
                                    Text(
                                      context.tr("Đã ghim Map", "Map pinned"),
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: c.isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, size: 18, color: c.primary),
                              tooltip: context.tr("Sửa địa chỉ", "Edit address"),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              onPressed: () => _showAddressDialog(authProvider, existing: addr),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red[400]),
                              tooltip: context.tr("Xóa địa chỉ", "Delete address"),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              onPressed: () async {
                                final msg = context.tr("Đã xóa địa chỉ nhận hàng!", "Delivery address deleted!");
                                await authProvider.deleteShippingAddress(addr.id);
                                _showModernToast(msg);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              addr.recipientName,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(width: 1, height: 13, color: c.border),
                            const SizedBox(width: 10),
                            Text(
                              addr.phone,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          addr.address,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: c.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (!addr.isDefault) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: c.primary),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                final msg = context.tr("Đã đặt làm địa chỉ mặc định!", "Set as default address!");
                                await authProvider.setDefaultShippingAddress(addr.id);
                                _showModernToast(msg);
                              },
                              child: Text(
                                context.tr("Đặt làm mặc định", "Set as default"),
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )),

            const SizedBox(height: 24),

            // ================= 2. THẺ NGÂN HÀNG ĐÃ LƯU =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.credit_card_rounded, color: c.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      context.tr("THẺ NGÂN HÀNG ĐÃ LƯU", "SAVED BANK CARDS"),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: c.primary,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddCardDialog(authProvider),
                  icon: Icon(Icons.add_rounded, size: 18, color: c.primary),
                  label: Text(
                    context.tr("Thêm thẻ", "Add card"),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (cards.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  children: [
                    Text(
                      context.tr("Chưa có thẻ ngân hàng nào được lưu", "No bank cards saved yet"),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showAddCardDialog(authProvider),
                      icon: const Icon(Icons.add_card_rounded, color: Colors.white, size: 18),
                      label: Text(
                        context.tr("Liên kết thẻ ngân hàng", "Link bank card"),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...cards.map((card) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F3443), Color(0xFF1E5631)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F3443).withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_rounded, color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                card.bankName.replaceAll('(VNPay Sandbox)', '').trim().toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (card.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  context.tr("Mặc định", "Default"),
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () async {
                                  final msg = context.tr("Đã đặt thẻ làm mặc định!", "Set card as default!");
                                  await authProvider.setDefaultPaymentCard(card.id);
                                  _showModernToast(msg);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white38),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    context.tr("Đặt mặc định", "Set default"),
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final msg = context.tr("Đã xóa thẻ thanh toán!", "Payment card deleted!");
                                await authProvider.deletePaymentCard(card.id);
                                _showModernToast(msg);
                              },
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.white70, size: 18),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          card.cardNumber,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr("CHỦ THẺ: ${card.cardHolder}", "CARD HOLDER: ${card.cardHolder}"),
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              context.tr("PHÁT HÀNH: ${card.issueDate}", "ISSUED: ${card.issueDate}"),
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.surfaceTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: c.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(
                        "Khi vào Giỏ hàng để đặt mua vật tư, bạn có thể chọn nhanh các địa chỉ & thẻ đã lưu ở trên, hoặc chọn Thanh toán khi nhận hàng (COD).",
                        "When in the Cart to purchase supplies, you can quickly choose from your saved addresses and cards above, or choose Cash on Delivery (COD).",
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: c.primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

/// Bản đồ tương tác trực quan (Slippy Map) hỗ trợ Kéo (Pan),
/// Lăn chuột / Phóng to / Thu nhỏ (Zoom), Chấm (Tap) đặt ghim và Mở rộng ở góc bản đồ.
class _InteractiveMapPicker extends StatefulWidget {
  final double latitude;
  final double longitude;
  final int zoom;
  final void Function(double lat, double lng, int zoom) onLocationChanged;
  final ValueChanged<String>? onStreetPicked;
  final double mapHeight;
  final bool showExpandButton;

  const _InteractiveMapPicker({
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.onLocationChanged,
    this.onStreetPicked,
    this.mapHeight = 230,
    this.showExpandButton = true,
  });

  @override
  State<_InteractiveMapPicker> createState() => _InteractiveMapPickerState();
}

class _InteractiveMapPickerState extends State<_InteractiveMapPicker> {
  final Dio _dio = Dio();

  late double _centerLat;
  late double _centerLng;
  late double _pinLat;
  late double _pinLng;
  late int _zoom;

  Offset? _pointerDownPos;
  bool _isDragging = false;
  String? _reverseAddressLabel;

  @override
  void initState() {
    super.initState();
    _centerLat = widget.latitude;
    _centerLng = widget.longitude;
    _pinLat = widget.latitude;
    _pinLng = widget.longitude;
    _zoom = widget.zoom;
  }

  @override
  void didUpdateWidget(covariant _InteractiveMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ dịch chuyển tâm bản đồ khi tọa độ được thay đổi từ bên ngoài (chọn Tỉnh/Phường mới)
    final externalLatChanged = (widget.latitude - _pinLat).abs() > 0.00001;
    final externalLngChanged = (widget.longitude - _pinLng).abs() > 0.00001;
    if (externalLatChanged || externalLngChanged) {
      _centerLat = widget.latitude;
      _centerLng = widget.longitude;
      _pinLat = widget.latitude;
      _pinLng = widget.longitude;
      _zoom = widget.zoom;
    }
  }

  Future<void> _reverseGeocodePin(double lat, double lng) async {
    try {
      final res = await _dio.get(
        'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/reverseGeocode',
        queryParameters: {
          'location': '$lng,$lat',
          'langCode': 'vi',
          'f': 'json',
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final addrObj = res.data['address'];
        if (addrObj is Map) {
          final shortLabel = addrObj['ShortLabel']?.toString() ?? '';
          final matchAddr = addrObj['Match_addr']?.toString() ?? '';
          final display = shortLabel.isNotEmpty ? shortLabel : matchAddr;
          if (display.isNotEmpty && mounted) {
            setState(() => _reverseAddressLabel = display);
          }
        }
      }
    } catch (_) {}
  }

  void _openExpandedMapModal() {
    final c = context.colors;
    double modalLat = _pinLat;
    double modalLng = _pinLng;
    int modalZoom = _zoom < 15 ? 15 : _zoom;
    String? modalPickedStreet = _reverseAddressLabel;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.surfaceTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.map_rounded, color: c.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr("Ghim vị trí nhận hàng", "Pin delivery location"),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: c.textMuted),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 640,
          child: _InteractiveMapPicker(
            latitude: modalLat,
            longitude: modalLng,
            zoom: modalZoom,
            mapHeight: 420,
            showExpandButton: false,
            onLocationChanged: (lat, lng, z) {
              modalLat = lat;
              modalLng = lng;
              modalZoom = z;
            },
            onStreetPicked: (street) {
              modalPickedStreet = street;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr("Hủy", "Cancel"),
              style: GoogleFonts.inter(color: c.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                _centerLat = modalLat;
                _centerLng = modalLng;
                _pinLat = modalLat;
                _pinLng = modalLng;
                _zoom = modalZoom;
                if (modalPickedStreet != null && modalPickedStreet!.isNotEmpty) {
                  _reverseAddressLabel = modalPickedStreet;
                }
              });
              widget.onLocationChanged(modalLat, modalLng, modalZoom);
              if (modalPickedStreet != null && modalPickedStreet!.isNotEmpty) {
                widget.onStreetPicked?.call(modalPickedStreet!);
              }
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            label: Text(
              context.tr("Xác nhận vị trí này", "Confirm this location"),
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  double _lonToGlobalX(double lon, int z) {
    return ((lon + 180.0) / 360.0) * 256.0 * (1 << z);
  }

  double _latToGlobalY(double lat, int z) {
    final clampedLat = lat.clamp(-85.0511, 85.0511);
    final sinLat = math.sin(clampedLat * math.pi / 180.0);
    return (0.5 - math.log((1.0 + sinLat) / (1.0 - sinLat)) / (4.0 * math.pi)) *
        256.0 *
        (1 << z);
  }

  double _globalXToLon(double gx, int z) {
    final worldSize = 256.0 * (1 << z);
    return (gx / worldSize) * 360.0 - 180.0;
  }

  double _globalYToLat(double gy, int z) {
    final worldSize = 256.0 * (1 << z);
    final n = math.pi - (2.0 * math.pi * gy) / worldSize;
    return (180.0 / math.pi) * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: widget.mapHeight,
      decoration: BoxDecoration(
        color: c.isDark ? const Color(0xFF1E2820) : const Color(0xFFE8EFEA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.primary.withValues(alpha: 0.3), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final centerX = _lonToGlobalX(_centerLng, _zoom);
          final centerY = _latToGlobalY(_centerLat, _zoom);
          final viewLeft = centerX - width / 2.0;
          final viewTop = centerY - height / 2.0;

          final minTileX = (viewLeft / 256.0).floor();
          final maxTileX = ((viewLeft + width) / 256.0).floor();
          final minTileY = (viewTop / 256.0).floor();
          final maxTileY = ((viewTop + height) / 256.0).floor();
          final maxTileIndex = (1 << _zoom) - 1;

          final List<Widget> tiles = [];
          for (int tx = minTileX; tx <= maxTileX; tx++) {
            for (int ty = minTileY; ty <= maxTileY; ty++) {
              if (ty < 0 || ty > maxTileIndex) continue;
              final wrappedTx = ((tx % (1 << _zoom)) + (1 << _zoom)) % (1 << _zoom);
              tiles.add(
                Positioned(
                  left: tx * 256.0 - viewLeft,
                  top: ty * 256.0 - viewTop,
                  width: 256,
                  height: 256,
                  child: Image.network(
                    'https://mt1.google.com/vt/lyrs=m&x=$wrappedTx&y=$ty&z=$_zoom&hl=vi',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(color: c.isDark ? const Color(0xFF1E2820) : const Color(0xFFE8EFEA)),
                  ),
                ),
              );
            }
          }

          final pinScreenX = _lonToGlobalX(_pinLng, _zoom) - viewLeft;
          final pinScreenY = _latToGlobalY(_pinLat, _zoom) - viewTop;

          return Stack(
            children: [
              // Lớp bản đồ + bắt sự kiện kéo/chấm/lăn chuột mượt mà không bị cuộn hộp thoại
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    if (event.scrollDelta.dy < 0 && _zoom < 18) {
                      setState(() => _zoom++);
                      widget.onLocationChanged(_pinLat, _pinLng, _zoom);
                    } else if (event.scrollDelta.dy > 0 && _zoom > 5) {
                      setState(() => _zoom--);
                      widget.onLocationChanged(_pinLat, _pinLng, _zoom);
                    }
                  }
                },
                onPointerDown: (event) {
                  _pointerDownPos = event.localPosition;
                  _isDragging = false;
                },
                onPointerMove: (event) {
                  if (_pointerDownPos != null &&
                      (event.localPosition - _pointerDownPos!).distance > 5) {
                    _isDragging = true;
                  }
                  final newCenterX = _lonToGlobalX(_centerLng, _zoom) - event.delta.dx;
                  final newCenterY = _latToGlobalY(_centerLat, _zoom) - event.delta.dy;
                  setState(() {
                    _centerLng = _globalXToLon(newCenterX, _zoom).clamp(-180.0, 180.0);
                    _centerLat = _globalYToLat(newCenterY, _zoom).clamp(-85.0, 85.0);
                  });
                },
                onPointerUp: (event) {
                  if (!_isDragging) {
                    final curCenterX = _lonToGlobalX(_centerLng, _zoom);
                    final curCenterY = _latToGlobalY(_centerLat, _zoom);
                    final curViewLeft = curCenterX - width / 2.0;
                    final curViewTop = curCenterY - height / 2.0;
                    final tapGlobalX = curViewLeft + event.localPosition.dx;
                    final tapGlobalY = curViewTop + event.localPosition.dy;
                    final newLng = _globalXToLon(tapGlobalX, _zoom).clamp(-180.0, 180.0);
                    final newLat = _globalYToLat(tapGlobalY, _zoom).clamp(-85.0, 85.0);
                    setState(() {
                      _pinLat = newLat;
                      _pinLng = newLng;
                    });
                    widget.onLocationChanged(_pinLat, _pinLng, _zoom);
                    _reverseGeocodePin(_pinLat, _pinLng);
                  }
                  _pointerDownPos = null;
                  _isDragging = false;
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // Chặn SingleChildScrollView bên ngoài cướp thao tác kéo dọc trên bản đồ
                  onVerticalDragUpdate: (_) {},
                  onHorizontalDragUpdate: (_) {},
                  child: IgnorePointer(
                    child: Stack(
                      children: [
                        ...tiles,
                        Positioned(
                          left: pinScreenX - 20,
                          top: pinScreenY - 38,
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFFD32F2F),
                            size: 40,
                            shadows: [
                              Shadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Nút Mở rộng ở góc trên bên trái bản đồ
              if (widget.showExpandButton)
                Positioned(
                  left: 10,
                  top: 10,
                  child: GestureDetector(
                    onTap: _openExpandedMapModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: c.shadow,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_full_rounded, size: 15, color: c.primary),
                          const SizedBox(width: 5),
                          Text(
                            context.tr("Mở rộng", "Expand"),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: c.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Cụm nút điều khiển Zoom + / - và Về vị trí ghim ở góc phải
              Positioned(
                right: 10,
                top: 10,
                child: Column(
                  children: [
                    _mapControlBtn(Icons.add_rounded, () {
                      if (_zoom < 18) {
                        setState(() => _zoom++);
                        widget.onLocationChanged(_pinLat, _pinLng, _zoom);
                      }
                    }),
                    const SizedBox(height: 6),
                    _mapControlBtn(Icons.remove_rounded, () {
                      if (_zoom > 5) {
                        setState(() => _zoom--);
                        widget.onLocationChanged(_pinLat, _pinLng, _zoom);
                      }
                    }),
                    const SizedBox(height: 6),
                    _mapControlBtn(Icons.my_location_rounded, () {
                      setState(() {
                        _centerLat = _pinLat;
                        _centerLng = _pinLng;
                      });
                    }),
                  ],
                ),
              ),

              // Gợi ý tên đường/địa điểm tại vị trí vừa chấm trên bản đồ
              if (_reverseAddressLabel != null && _reverseAddressLabel!.isNotEmpty)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: c.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: c.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.place_rounded, color: Color(0xFFD32F2F), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _reverseAddressLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            widget.onStreetPicked?.call(_reverseAddressLabel!);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.surfaceTint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              context.tr("Điền tên đường", "Use street name"),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: c.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _mapControlBtn(IconData icon, VoidCallback onTap) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: c.textPrimary),
      ),
    );
  }
}
