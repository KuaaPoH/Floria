import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/diary_entry.dart';
import '../models/garden_plant.dart';
import '../providers/garden_provider.dart';
import '../../../core/services/storage_service.dart';

class _DiaryDraftPhoto {
  final Uint8List bytes;
  String? url;
  bool isUploading;
  double progress = 0.0;
  Future<String?>? future;

  _DiaryDraftPhoto({
    required this.bytes,
    this.isUploading = false,
  });
}

class PlantDiaryScreen extends StatefulWidget {
  final GardenPlant? plant;
  final bool isSubpage;

  const PlantDiaryScreen({
    super.key,
    this.plant,
    this.isSubpage = false,
  });

  @override
  State<PlantDiaryScreen> createState() => _PlantDiaryScreenState();
}

class _PlantDiaryScreenState extends State<PlantDiaryScreen> {
  // Bộ lọc: 'all', 'user', 'system'
  String _activeFilter = 'all';

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final gardenProvider = Provider.of<GardenProvider>(context);
    final plant = widget.plant;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          // Vuốt từ trái sang phải để đóng subpage trượt về bên phải
          if (widget.isSubpage &&
              details.primaryVelocity != null &&
              details.primaryVelocity! > 220) {
            Navigator.of(context).pop();
          }
        },
        child: Stack(
        children: [
          // Content
          plant == null
              ? _buildNoPlantPlaceholder()
              : StreamBuilder<List<DiaryEntry>>(
                  stream: gardenProvider.getDiaryStream(plant.id),
                  builder: (context, snapshot) {
                    final streamEntries = snapshot.data ?? [];
                    final allEntries = _mergeWithInitialEvents(plant, streamEntries);
                    final filteredEntries = _filterEntries(allEntries);

                    if (snapshot.connectionState == ConnectionState.waiting && streamEntries.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF2E6F40)),
                      );
                    }

                    if (filteredEntries.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 170, bottom: 100, left: 20, right: 20),
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        final isLast = index == filteredEntries.length - 1;
                        return _buildTimelineItem(entry, isLast);
                      },
                    );
                  },
                ),

          // Sticky Glassmorphism Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 14,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF9F6).withValues(alpha: 0.88),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFF2E6F40).withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCircleButton(
                            icon: Icons.chevron_left,
                            onTap: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  plant?.nickname ?? "Nhật ký phát triển",
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1B1C1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  plant != null
                                      ? "${plant.nameVi} • ${plant.zone}"
                                      : "Dòng thời gian chăm sóc",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6A756B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 40), // Cân bằng với nút back
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Pill Filter Tabs
                      _buildPillFilterRow(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),

      // Floating Action Button: Viết nhật ký mới
      floatingActionButton: plant == null
          ? null
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A24).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showWriteDiaryModal(context, plant),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A24), // Xanh rêu đậm hoàng gia
                  foregroundColor: Colors.white,
                  elevation: 0,
                  side: BorderSide(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.35), // Viền ánh kim vàng nhẹ
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(
                  Icons.edit_square, // Icon viết nhật ký quen thuộc
                  size: 20,
                  color: Color(0xFFFFD700),
                ),
                label: Text(
                  "Viết nhật ký",
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
    );
  }

  // --- FILTER TABS (Loại bỏ các icon, chỉ giữ text thanh lịch) ---
  Widget _buildPillFilterRow() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEE9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _buildFilterChipItem('all', 'Tất cả'),
          _buildFilterChipItem('user', 'Của tôi'),
          _buildFilterChipItem('system', 'Hoạt động'),
        ],
      ),
    );
  }

  Widget _buildFilterChipItem(String key, String label) {
    final isSelected = _activeFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF1E3A24) : const Color(0xFF6A756B),
            ),
          ),
        ),
      ),
    );
  }

  // --- LỌC VÀ GỘP MỐC CƠ BẢN NẾU CHƯA CÓ DỮ LIỆU ---
  List<DiaryEntry> _mergeWithInitialEvents(GardenPlant plant, List<DiaryEntry> streamEntries) {
    final list = List<DiaryEntry>.from(streamEntries);

    // Nếu chưa có mốc "Đón cây về vườn", tự động thêm mốc này từ createdAt
    final hasInit = list.any((e) => e.category == 'init');
    if (!hasInit) {
      list.add(
        DiaryEntry(
          id: 'init_${plant.id}',
          plantId: plant.id,
          userId: plant.userId,
          type: 'system',
          category: 'init',
          title: 'Chào mừng về vườn mới',
          content: 'Chính thức rước "${plant.nickname}" về góc ${plant.zone}. Bắt đầu hành trình chăm sóc xanh!',
          tag: 'Về vườn',
          tagBgColor: 0xFFDCFCE7,
          tagTextColor: 0xFF15803D,
          timestamp: plant.createdAt,
        ),
      );
    }

    // Sắp xếp thời gian mới nhất lên đầu
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  List<DiaryEntry> _filterEntries(List<DiaryEntry> entries) {
    if (_activeFilter == 'user') {
      return entries.where((e) => e.isUser).toList();
    }
    if (_activeFilter == 'system') {
      return entries.where((e) => e.isSystem).toList();
    }
    return entries;
  }

  // --- TIMELINE ITEM WIDGET ---
  Widget _buildTimelineItem(DiaryEntry entry, bool isLast) {
    final iconData = _getEntryIcon(entry);
    final iconColor = _getEntryIconColor(entry);
    final iconBgColor = _getEntryIconBgColor(entry);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột trục thời gian bên trái
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(iconData, color: iconColor, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFD6E8CF),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Thẻ nội dung bên phải
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E9E2)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A24).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header thẻ: Ngày giờ + Tag + Nút xóa (nếu là bài người dùng)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(entry.timestamp),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6A756B),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(entry.tagBgColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                entry.tag,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(entry.tagTextColor),
                                ),
                              ),
                            ),
                            if (entry.isUser) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                                onPressed: () => _confirmDeleteEntry(context, entry),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: "Xóa trang nhật ký",
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Tiêu đề
                    if (entry.title.isNotEmpty)
                      Text(
                        entry.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1B1C1A),
                        ),
                      ),
                    if (entry.title.isNotEmpty) const SizedBox(height: 6),

                    // Ảnh đính kèm (hỗ trợ 1 hoặc nhiều ảnh)
                    if (entry.imageUrls.isNotEmpty) ...[
                      if (entry.imageUrls.length == 1)
                        GestureDetector(
                          onTap: () => _openImageViewer(context, entry.imageUrls, 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _buildSingleImage(
                              entry.imageUrls.first,
                              width: double.infinity,
                              height: 180,
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 150,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: entry.imageUrls.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 8),
                                itemBuilder: (context, imgIdx) {
                                  final imgUrl = entry.imageUrls[imgIdx];
                                  return GestureDetector(
                                    onTap: () => _openImageViewer(context, entry.imageUrls, imgIdx),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _buildSingleImage(
                                        imgUrl,
                                        width: 200,
                                        height: 150,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.photo_library_outlined, size: 13, color: Color(0xFF6B7280)),
                                const SizedBox(width: 4),
                                Text(
                                  "${entry.imageUrls.length} ảnh",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 10),
                    ],

                    // Nội dung
                    Text(
                      entry.content,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: const Color(0xFF374151),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ICONS & COLORS ---
  IconData _getEntryIcon(DiaryEntry entry) {
    if (entry.isUser) return Icons.edit_note_rounded;
    switch (entry.category) {
      case 'care':
        if (entry.title.contains('Tưới')) return Icons.water_drop_rounded;
        if (entry.title.contains('phân')) return Icons.science_rounded;
        return Icons.eco_rounded;
      case 'health':
        return Icons.healing_rounded;
      case 'init':
        return Icons.park_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  Color _getEntryIconColor(DiaryEntry entry) {
    if (entry.isUser) return const Color(0xFFD97706); // Amber vàng đồng
    switch (entry.category) {
      case 'care':
        if (entry.title.contains('Tưới')) return const Color(0xFF0284C7);
        if (entry.title.contains('phân')) return const Color(0xFFD97706);
        return const Color(0xFF16A34A);
      case 'health':
        return const Color(0xFFDC2626);
      case 'init':
        return const Color(0xFF1E3A24);
      default:
        return const Color(0xFF2E6F40);
    }
  }

  Color _getEntryIconBgColor(DiaryEntry entry) {
    return _getEntryIconColor(entry).withValues(alpha: 0.14);
  }

  Widget _buildSingleImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:image') || url.length > 300) {
      return Image.memory(
        base64Decode(url.split(',').last),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const SizedBox(),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const SizedBox(),
    );
  }

  // Trình xem ảnh phóng to toàn màn hình với zoom và lướt ảnh
  void _openImageViewer(BuildContext context, List<String> images, int initialIndex) {
    if (images.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.94),
      builder: (dialogCtx) {
        int currentIndex = initialIndex;
        final pageCtrl = PageController(initialPage: initialIndex);

        return StatefulBuilder(
          builder: (context, setViewerState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Stack(
                children: [
                  // Lướt xem ảnh với zoom phóng to thu nhỏ
                  PageView.builder(
                    controller: pageCtrl,
                    itemCount: images.length,
                    onPageChanged: (idx) {
                      setViewerState(() => currentIndex = idx);
                    },
                    itemBuilder: (context, idx) {
                      final url = images[idx];
                      return Center(
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 3.5,
                          child: _buildSingleImage(
                            url,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),

                  // Thanh điều hướng: Nút đóng & Chỉ số ảnh
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(dialogCtx),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                          if (images.length > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${currentIndex + 1} / ${images.length}",
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(width: 38),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.year == dt.year && now.month == dt.month && now.day == dt.day) {
      return "Hôm nay, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == dt.year && yesterday.month == dt.month && yesterday.day == dt.day) {
      return "Hôm qua, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  // --- EMPTY STATE ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5EC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories_outlined,
                color: Color(0xFF2E6F40),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _activeFilter == 'user'
                  ? "Chưa có trang nhật ký cá nhân nào"
                  : "Chưa có ghi chép nhật ký",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1B1C1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _activeFilter == 'user'
                  ? "Hãy chạm vào nút cây bút quý phái bên dưới để viết những cảm nhận và lưu giữ bức ảnh đầu tiên cho cây nhé!"
                  : "Mọi hoạt động tưới nước, bón phân hay bài viết mới sẽ xuất hiện tại đây.",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6A756B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPlantPlaceholder() {
    return Center(
      child: Text(
        "Không tìm thấy thông tin cây trồng.",
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF6A756B)),
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE0E5DD)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1B1C1A), size: 20),
      ),
    );
  }

  // --- MODAL: VIẾT NHẬT KÝ MỚI ---
  void _showWriteDiaryModal(BuildContext context, GardenPlant plant) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedTag = 'Đâm chồi';
    int selectedTagBg = 0xFFDCFCE7;
    int selectedTagText = 0xFF15803D;
    final List<_DiaryDraftPhoto> draftPhotos = [];
    bool isSaving = false;

    // Loại bỏ hoàn toàn các icon của đâm chồi, ra hoa... chỉ giữ chữ thanh lịch
    final tagsList = [
      {'tag': 'Đâm chồi', 'bg': 0xFFDCFCE7, 'text': 0xFF15803D},
      {'tag': 'Ra hoa', 'bg': 0xFFFCE7F3, 'text': 0xFFBE185D},
      {'tag': 'Thay chậu', 'bg': 0xFFFEF3C7, 'text': 0xFFB45309},
      {'tag': 'Cắt tỉa', 'bg': 0xFFE0F2FE, 'text': 0xFF0369A1},
      {'tag': 'Kỷ niệm', 'bg': 0xFFF3E8FF, 'text': 0xFF7E22CE},
      {'tag': 'Tâm tình', 'bg': 0xFFE5F4EA, 'text': 0xFF1E3A24},
    ];

    Future<void> pickMoreImages(StateSetter setModalState) async {
      try {
        final List<XFile> files = await _picker.pickMultiImage(
          maxWidth: 960,
          maxHeight: 960,
          imageQuality: 72,
        );
        if (files.isNotEmpty) {
          final List<_DiaryDraftPhoto> newDrafts = [];
          for (final f in files) {
            if (draftPhotos.length + newDrafts.length >= 8) break;
            final bytes = await f.readAsBytes();
            final draft = _DiaryDraftPhoto(bytes: bytes, isUploading: true);

            // Kích hoạt upload ngầm lên ImgBB Cloud ngay trong lúc người dùng đang gõ bài
            draft.future = StorageService.uploadToImgbb(
              bytes,
              onProgress: (count, total) {
                if (total > 0) {
                  draft.progress = (count / total).clamp(0.0, 0.95);
                  try { setModalState(() {}); } catch (_) {}
                }
              },
            ).then((uploadedUrl) {
              draft.url = uploadedUrl;
              draft.progress = 1.0;
              draft.isUploading = false;
              try { setModalState(() {}); } catch (_) {}
              return uploadedUrl;
            }).catchError((_) {
              draft.isUploading = false;
              try { setModalState(() {}); } catch (_) {}
              return null;
            });
            newDrafts.add(draft);
          }
          setModalState(() {
            draftPhotos.addAll(newDrafts);
          });
        }
      } catch (e) {
        debugPrint("Lỗi chọn nhiều ảnh: $e");
      }
    }

    Future<void> takePhoto(StateSetter setModalState) async {
      try {
        final XFile? file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 960,
          maxHeight: 960,
          imageQuality: 72,
        );
        if (file != null) {
          final bytes = await file.readAsBytes();
          if (draftPhotos.length < 8) {
            final draft = _DiaryDraftPhoto(bytes: bytes, isUploading: true);
            draft.future = StorageService.uploadToImgbb(
              bytes,
              onProgress: (count, total) {
                if (total > 0) {
                  draft.progress = (count / total).clamp(0.0, 0.95);
                  try { setModalState(() {}); } catch (_) {}
                }
              },
            ).then((uploadedUrl) {
              draft.url = uploadedUrl;
              draft.progress = 1.0;
              draft.isUploading = false;
              try { setModalState(() {}); } catch (_) {}
              return uploadedUrl;
            }).catchError((_) {
              draft.isUploading = false;
              try { setModalState(() {}); } catch (_) {}
              return null;
            });
            setModalState(() {
              draftPhotos.add(draft);
            });
          }
        }
      } catch (e) {
        debugPrint("Lỗi chụp ảnh: $e");
      }
    }

    void showImageSourcePicker(StateSetter setModalState) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (pickerCtx) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Thêm ảnh vào nhật ký",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1C1A),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Color(0xFF2E6F40)),
                  ),
                  title: Text(
                    "Chọn từ thư viện ảnh",
                    style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: const Color(0xFF1B1C1A)),
                  ),
                  subtitle: Text("Thêm tối đa 8 ảnh chất lượng cao", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                  onTap: () {
                    Navigator.pop(pickerCtx);
                    pickMoreImages(setModalState);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2E6F40)),
                  ),
                  title: Text(
                    "Chụp ảnh mới",
                    style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: const Color(0xFF1B1C1A)),
                  ),
                  subtitle: Text("Mở camera ghi lại khoảnh khắc hiện tại", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                  onTap: () {
                    Navigator.pop(pickerCtx);
                    takePhoto(setModalState);
                  },
                ),
              ],
            ),
          );
        },
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thanh gạch ngang
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E5DD),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tiêu đề Modal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.edit_note_rounded,
                              color: Color(0xFFD97706),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Trang nhật ký mới",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1B1C1A),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF6A756B)),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Chọn ảnh (Hỗ trợ nhiều ảnh)
                    if (draftPhotos.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Ảnh nhật ký (${draftPhotos.length}/8)",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B1C1A),
                            ),
                          ),
                          if (draftPhotos.length < 8)
                            GestureDetector(
                              onTap: () => showImageSourcePicker(setModalState),
                              child: Text(
                                "+ Thêm ảnh",
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E6F40),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 125,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: draftPhotos.length + (draftPhotos.length < 8 ? 1 : 0),
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            if (idx == draftPhotos.length) {
                              return GestureDetector(
                                onTap: () => showImageSourcePicker(setModalState),
                                child: Container(
                                  width: 95,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F9F6),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFF2E6F40).withValues(alpha: 0.35),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF2E6F40), size: 26),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Thêm ảnh",
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF2E6F40),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final draft = draftPhotos[idx];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.memory(
                                    draft.bytes,
                                    width: 115,
                                    height: 125,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Nút xóa ảnh
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => setModalState(() => draftPhotos.removeAt(idx)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                                // Hiệu ứng mờ mờ và hiển thị % chạy từ 0% -> 100%
                                if (draft.isUploading)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.55),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                CircularProgressIndicator(
                                                  value: draft.progress > 0 ? draft.progress : null,
                                                  strokeWidth: 3,
                                                  color: const Color(0xFF4ADE80),
                                                  backgroundColor: Colors.white24,
                                                ),
                                                Text(
                                                  "${(draft.progress * 100).toInt()}%",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Đang tải...",
                                            style: GoogleFonts.inter(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (idx == 0)
                                  Positioned(
                                    bottom: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E3A24).withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "Ảnh bìa",
                                        style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ] else
                      GestureDetector(
                        onTap: () => showImageSourcePicker(setModalState),
                        child: Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF2E6F40).withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, color: Color(0xFF2E6F40), size: 28),
                              const SizedBox(height: 6),
                              Text(
                                "Thêm ảnh chụp cho cây (Tối đa 8 ảnh)",
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E6F40),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Chọn Tag sinh trưởng (Loại bỏ các icon hoàn toàn)
                    Text(
                      "Mốc sinh trưởng",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1C1A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tagsList.map((item) {
                        final isSel = selectedTag == item['tag'];
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedTag = item['tag'] as String;
                              selectedTagBg = item['bg'] as int;
                              selectedTagText = item['text'] as int;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSel ? Color(item['bg'] as int) : const Color(0xFFF3F4F1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSel ? Color(item['text'] as int) : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              item['tag'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? Color(item['text'] as int) : const Color(0xFF374151),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Tiêu đề bài viết (Chữ đậm nét rõ ràng, không mờ)
                    TextField(
                      controller: titleCtrl,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1B1C1A), // Đen than sắc nét
                      ),
                      decoration: InputDecoration(
                        hintText: "Tiêu đề",
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B7280), // Xám trung tính đậm rõ ràng
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF2E6F40), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nội dung ghi chú (Chữ đậm nét rõ ràng, không mờ)
                    TextField(
                      controller: contentCtrl,
                      minLines: 3,
                      maxLines: 5,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: const Color(0xFF1B1C1A), // Đen than sắc nét
                      ),
                      decoration: InputDecoration(
                        hintText: "Ghi chép cảm nhận, thời tiết, tình trạng đất và nước...",
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B7280), // Xám trung tính đậm rõ ràng
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF2E6F40), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nút Lưu nhật ký
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final content = contentCtrl.text.trim();
                                if (content.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFF1E3A24),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      content: Text(
                                        "Vui lòng nhập nội dung trang nhật ký!",
                                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                final gardenProvider = Provider.of<GardenProvider>(context, listen: false);

                                // Thu thập URL ảnh: Đã xong ngầm từ trước, nếu chưa thì đợi nốt vài mili-giây
                                final List<String> imageUrlsList = [];
                                for (final draft in draftPhotos) {
                                  if (draft.url != null && draft.url!.isNotEmpty) {
                                    imageUrlsList.add(draft.url!);
                                  } else if (draft.future != null) {
                                    final uploaded = await draft.future;
                                    if (uploaded != null && uploaded.isNotEmpty) {
                                      imageUrlsList.add(uploaded);
                                    } else {
                                      imageUrlsList.add("data:image/jpeg;base64,${base64Encode(draft.bytes)}");
                                    }
                                  } else {
                                    imageUrlsList.add("data:image/jpeg;base64,${base64Encode(draft.bytes)}");
                                  }
                                }

                                final success = await gardenProvider.addDiaryEntry(
                                  plantId: plant.id,
                                  type: 'user',
                                  category: 'note',
                                  title: titleCtrl.text.trim(),
                                  content: content,
                                  imageUrl: imageUrlsList.isNotEmpty ? imageUrlsList.first : null,
                                  imageUrls: imageUrlsList,
                                  tag: selectedTag,
                                  tagBgColor: selectedTagBg,
                                  tagTextColor: selectedTagText,
                                );

                                if (modalCtx.mounted) {
                                  Navigator.pop(modalCtx);
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFF1E3A24),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 20),
                                          const SizedBox(width: 10),
                                          Text(
                                            success
                                                ? "Đã lưu trang nhật ký mới cho cây!"
                                                : "Chưa thể lưu nhật ký. Vui lòng thử lại.",
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A24),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: isSaving
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    draftPhotos.any((d) => d.isUploading)
                                        ? "Đang tải ảnh (${(draftPhotos.where((d) => d.isUploading).map((d) => d.progress).fold(0.0, (a, b) => a + b) / (draftPhotos.where((d) => d.isUploading).isNotEmpty ? draftPhotos.where((d) => d.isUploading).length : 1) * 100).toInt()}%)..."
                                        : "Đang lưu bài viết...",
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            : Text(
                                "Lưu trang nhật ký",
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- CONFIRM DELETE ENTRY ---
  void _confirmDeleteEntry(BuildContext context, DiaryEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Xóa bài nhật ký?",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF1B1C1A)),
        ),
        content: Text(
          "Trang nhật ký này sẽ bị xóa vĩnh viễn khỏi dòng thời gian của cây.",
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF6A756B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Hủy", style: GoogleFonts.inter(color: const Color(0xFF6A756B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final gardenProvider = Provider.of<GardenProvider>(context, listen: false);
              await gardenProvider.deleteDiaryEntry(plantId: entry.plantId, entryId: entry.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }
}
