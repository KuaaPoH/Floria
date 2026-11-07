import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../models/scan_history_item.dart';
import '../../scan/screens/plant_wiki_screen.dart';
import '../../chatbot/screens/ai_assistant_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const Color stateDanger = Color(0xFFBA1A1A);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final historyProvider = Provider.of<HistoryProvider>(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(context, historyProvider),
            _buildSearchBar(historyProvider),
            _buildFilterTabs(historyProvider),
            const SizedBox(height: 8),
            Expanded(
              child: _buildHistoryContent(historyProvider),
            ),
          ],
        ),
      ),
    );
  }

  // --- APP BAR ---
  Widget _buildAppBar(BuildContext context, HistoryProvider provider) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: c.textPrimary, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('NHẬT KÝ QUÉT CÂY', 'PLANT SCAN LOG'),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: c.primary,
                    ),
                  ),
                  Text(
                    context.tr('Lịch Sử Quét', 'Scan History'),
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (provider.totalCount > 0)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: c.textPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: c.surface,
              onSelected: (value) {
                if (value == 'clear_all') {
                  _showConfirmClearDialog(context, provider);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_sweep_outlined, color: stateDanger, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        context.tr('Xóa toàn bộ lịch sử', 'Clear All History'),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: stateDanger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- THANH TÌM KIẾM ---
  Widget _buildSearchBar(HistoryProvider provider) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(Icons.search, color: c.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: provider.setSearchQuery,
                style: GoogleFonts.inter(fontSize: 14, color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: context.tr('Tìm theo tên cây, bệnh lá...', 'Search by plant, leaf disease...'),
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
                child: Icon(Icons.close, color: c.textMuted, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  // --- BỘ LỌC TABS ---
  Widget _buildFilterTabs(HistoryProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildChip(
            label: '${context.tr("Tất cả", "All")} (${provider.totalCount})',
            isSelected: provider.selectedFilter == 'all',
            onTap: () => provider.setFilter('all'),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: '🌿 ${context.tr("Loài cây", "Species")} (${provider.plantCount})',
            isSelected: provider.selectedFilter == 'plant_discovery',
            onTap: () => provider.setFilter('plant_discovery'),
          ),
          const SizedBox(width: 8),
          _buildChip(
            label: '🔬 ${context.tr("Bệnh lá", "Diseases")} (${provider.diseaseCount})',
            isSelected: provider.selectedFilter == 'disease_diagnosis',
            onTap: () => provider.setFilter('disease_diagnosis'),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? c.primary : c.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: c.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : c.textPrimary,
          ),
        ),
      ),
    );
  }

  // --- NỘI DUNG DANH SÁCH LỊCH SỬ ---
  Widget _buildHistoryContent(HistoryProvider provider) {
    final c = context.colors;
    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: c.primary),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: stateDanger),
              const SizedBox(height: 12),
              Text(
                context.tr('Lỗi kết nối lịch sử', 'History connection error'),
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: c.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final items = provider.filteredItems;

    if (items.isEmpty) {
      return _buildEmptyState(provider);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildHistoryCard(context, item, provider);
      },
    );
  }

  // --- THẺ BẢN GHI LỊCH SỬ ---
  Widget _buildHistoryCard(
    BuildContext context,
    ScanHistoryItem item,
    HistoryProvider provider,
  ) {
    final c = context.colors;
    final bool isDisease = item.isDisease;
    final bool isHealthy = item.isHealthy;

    Color iconBgColor;
    Color iconColor;
    IconData iconData;

    if (isDisease) {
      if (isHealthy) {
        iconBgColor = c.isDark ? const Color(0xFF1E3A24) : const Color(0xFFE5F4EA);
        iconColor = const Color(0xFF3E8055);
        iconData = Icons.verified_user_outlined;
      } else {
        iconBgColor = c.isDark ? const Color(0xFF3E1E1E) : const Color(0xFFFFEBEE);
        iconColor = stateDanger;
        iconData = Icons.coronavirus_outlined;
      }
    } else {
      iconBgColor = c.surfaceTint;
      iconColor = c.primary;
      iconData = Icons.eco_outlined;
    }

    final String dateString = _formatDateTime(item.timestamp);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: stateDanger,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await _showConfirmDeleteSingleDialog(context, item);
      },
      onDismissed: (direction) {
        provider.deleteItem(item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.tr("Đã xóa bản ghi", "Deleted record")} "${item.displayName}" ${context.tr("khỏi lịch sử.", "from history.")}',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: GestureDetector(
        onTap: () => _showDetailModal(context, item),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
            boxShadow: [
              BoxShadow(
                color: c.shadow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon khối
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              // Thông tin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.displayName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: c.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${item.confidence.toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: c.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isDisease && item.plantName.isNotEmpty
                          ? '${context.tr("Cây kiểm tra:", "Inspected plant:")} ${item.plantName}'
                          : item.cleanPrediction,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: c.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tag phân loại
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDisease
                                ? (isHealthy
                                    ? (c.isDark ? const Color(0xFF1E3A24) : const Color(0xFFE5F4EA))
                                    : (c.isDark ? const Color(0xFF3E1E1E) : const Color(0xFFFFEBEE)))
                                : c.surfaceTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isDisease
                                ? (item.severityVi.isNotEmpty
                                    ? item.severityVi
                                    : (isHealthy ? context.tr('Khỏe mạnh', 'Healthy') : context.tr('Bệnh lá', 'Leaf disease')))
                                : context.tr('Loài cây', 'Plant species'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDisease
                                  ? (isHealthy ? const Color(0xFF3E8055) : stateDanger)
                                  : c.primary,
                            ),
                          ),
                        ),
                        // Thời gian
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 12, color: c.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              dateString,
                              style: GoogleFonts.inter(fontSize: 11, color: c.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL CHI TIẾT KẾT QUẢ ---
  void _showDetailModal(BuildContext context, ScanHistoryItem item) {
    final c = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool isDisease = item.isDisease;
        final bool isHealthy = item.isHealthy;

        return Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thanh kéo nhỏ
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.textMuted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDisease
                              ? (isHealthy
                                  ? (c.isDark ? const Color(0xFF1E3A24) : const Color(0xFFE5F4EA))
                                  : (c.isDark ? const Color(0xFF3E1E1E) : const Color(0xFFFFEBEE)))
                              : c.surfaceTint,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isDisease
                              ? context.tr("CHẨN ĐOÁN BỆNH HỌC", "PATHOLOGY DIAGNOSIS")
                              : context.tr("NHẬN DIỆN THỰC VẬT", "PLANT IDENTIFICATION"),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDisease
                                ? (isHealthy ? const Color(0xFF3E8055) : stateDanger)
                                : c.primary,
                          ),
                        ),
                      ),
                      Text(
                        _formatDateTime(item.timestamp),
                        style: GoogleFonts.inter(fontSize: 12, color: c.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.displayName,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  if (item.cleanPrediction.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.cleanPrediction,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: c.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Thông số AI
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildParamCol(context.tr("Độ tin cậy", "Confidence"), "${item.confidence.toStringAsFixed(1)}%"),
                        Container(width: 1, height: 28, color: c.border),
                        _buildParamCol(
                          context.tr("Phân loại", "Classification"),
                          isDisease
                              ? (isHealthy ? context.tr("Khỏe mạnh", "Healthy") : context.tr("Bệnh lý", "Pathological"))
                              : context.tr("Loài cây", "Plant species"),
                        ),
                        if (isDisease && item.severityVi.isNotEmpty) ...[
                          Container(width: 1, height: 28, color: c.border),
                          _buildParamCol(context.tr("Mức độ", "Severity"), item.severityVi),
                        ],
                      ],
                    ),
                  ),

                  // Phần chi tiết bệnh lá
                  if (isDisease && !isHealthy) ...[
                    if (item.cause.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        context.tr('Nguyên nhân & Mầm bệnh', 'Causes & Pathogens'),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.cause,
                        style: GoogleFonts.inter(fontSize: 13, color: c.textMuted, height: 1.4),
                      ),
                    ],
                    if (item.treatmentSteps.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        context.tr('Phác đồ điều trị khuyến nghị', 'Recommended Treatment Protocol'),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...item.treatmentSteps.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(top: 2, right: 10),
                                decoration: BoxDecoration(
                                  color: c.primary,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${entry.key + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: c.textPrimary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],

                  const SizedBox(height: 24),
                  // Các nút hành động
                  Row(
                    children: [
                      if (!isDisease)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlantWikiScreen(
                                    docId: item.cleanPrediction,
                                    data: {
                                      'name_vi': item.displayName,
                                      'scientific_name': item.cleanPrediction,
                                    },
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: c.primary,
                              side: BorderSide(color: c.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.menu_book, size: 18),
                            label: Text(
                              context.tr('Từ điển cây', 'Plant Wiki'),
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      if (!isDisease) const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AiAssistantScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: Text(
                            context.tr('Hỏi Trợ lý Floria', 'Ask Floria Assistant'),
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParamCol(String label, String val) {
    final c = context.colors;
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: c.textMuted)),
        const SizedBox(height: 4),
        Text(
          val,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
        ),
      ],
    );
  }

  // --- TRẠNG THÁI RỖNG ---
  Widget _buildEmptyState(HistoryProvider provider) {
    final c = context.colors;
    final bool isSearching = provider.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.history_edu_outlined,
                size: 38,
                color: c.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? context.tr('Không tìm thấy kết quả phù hợp', 'No matching results found')
                  : context.tr('Chưa có lịch sử quét nào', 'No scan history yet'),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? context.tr('Hãy thử tìm kiếm với từ khóa khác.', 'Try searching with different keywords.')
                  : context.tr('Mỗi khi bạn quét nhận diện hoặc kiểm tra bệnh lá cây, kết quả sẽ được lưu tại đây.', 'Scan results for plants and leaf diseases will appear here.'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: c.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG XÁC NHẬN ---
  void _showConfirmClearDialog(BuildContext context, HistoryProvider provider) {
    final c = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('Xóa toàn bộ lịch sử?', 'Clear all history?'),
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: c.textPrimary),
        ),
        content: Text(
          context.tr('Hành động này sẽ xóa vĩnh viễn tất cả nhật ký quét nhận diện và chẩn đoán bệnh của bạn.', 'This will permanently delete all scan and diagnosis logs.'),
          style: GoogleFonts.inter(fontSize: 13, color: c.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('Hủy', 'Cancel'), style: GoogleFonts.inter(color: c.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.clearAllHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: stateDanger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(context.tr('Xóa tất cả', 'Delete all'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDeleteSingleDialog(
    BuildContext context,
    ScanHistoryItem item,
  ) async {
    final c = context.colors;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              context.tr('Xóa bản ghi này?', 'Delete this record?'),
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: c.textPrimary),
            ),
            content: Text(
              '${context.tr("Bạn có chắc chắn muốn xóa bản ghi", "Are you sure you want to delete")} "${item.displayName}" ${context.tr("khỏi lịch sử?", "from history?")}',
              style: GoogleFonts.inter(fontSize: 13, color: c.textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.tr('Hủy', 'Cancel'), style: GoogleFonts.inter(color: c.textMuted, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: stateDanger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(context.tr('Xóa', 'Delete'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    final String timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (diff.inDays == 0 && dt.day == now.day) {
      return '${context.tr("Hôm nay", "Today")}, $timeStr';
    } else if (diff.inDays <= 1 && dt.day == now.day - 1) {
      return '${context.tr("Hôm qua", "Yesterday")}, $timeStr';
    } else {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}, $timeStr';
    }
  }
}
