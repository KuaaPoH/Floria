import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/theme/app_colors.dart';
import '../../../core/l10n/app_tr.dart';

class PlantWikiScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String? imagePath;
  final Uint8List? webImageBytes;

  const PlantWikiScreen({
    super.key,
    required this.docId,
    required this.data,
    this.imagePath,
    this.webImageBytes,
  });

  @override
  State<PlantWikiScreen> createState() => _PlantWikiScreenState();
}

class _PlantWikiScreenState extends State<PlantWikiScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final plantData = widget.data;
    String nameVi = plantData['name_vi'] ?? widget.docId.replaceAll('_', ' ');
    String scientificName = plantData['scientific_name'] ?? widget.docId.replaceAll('_', ' ');
    String family = plantData['family'] ?? context.tr('Chưa cập nhật', 'Not updated');
    String description = plantData['wiki_detail'] ?? plantData['description'] ?? plantData['wiki_description'] ?? context.tr('Chưa có thông tin bách khoa về loài cây này.', 'No encyclopedia information available for this plant.');

    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          // Fixed Hero Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 400,
            child: Container(
              color: c.surfaceTint,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content Scrollable Area
          Positioned.fill(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 310, bottom: 100), // Push content down to expose hero
              children: [
                // Content Sheet
                Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(
                        color: c.shadow,
                        blurRadius: 40,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 48,
                          height: 6,
                          margin: const EdgeInsets.only(bottom: 32),
                          decoration: BoxDecoration(
                            color: c.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      // Header Section
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTaxonomyTag(family, isPrimary: true),
                          if (widget.data['origin'] != null)
                            _buildTaxonomyTag(widget.data['origin'], isPrimary: false),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        nameVi,
                        style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: c.textPrimary, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scientificName,
                        style: GoogleFonts.inter(fontSize: 17, color: c.textSecondary, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 32),

                      // Biological Profile
                      Row(
                        children: [
                          Icon(Icons.menu_book, color: c.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(context.tr("Hồ sơ sinh học", "Biological Profile"), style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: c.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: c.surfaceMuted,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border),
                          boxShadow: [BoxShadow(color: c.shadow, blurRadius: 4)],
                        ),
                        child: Text(
                          description,
                          style: GoogleFonts.inter(fontSize: 15, color: c.textSecondary, height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Morphological Characteristics
                      Row(
                        children: [
                          Icon(Icons.nature, color: c.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(context.tr("Đặc điểm hình thái", "Morphological Traits"), style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: c.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Grid
                      Row(
                        children: [
                          Expanded(child: _buildCharacteristicCard(Icons.eco, context.tr("Đặc điểm nhận dạng", "Identification"), plantData['identification'] ?? context.tr("Đang cập nhật thông tin", "Updating information"))),
                          const SizedBox(width: 16),
                          Expanded(child: _buildCharacteristicCard(Icons.light_mode, context.tr("Ánh sáng", "Light"), plantData['light'] ?? context.tr("Đang cập nhật thông tin", "Updating information"))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildCharacteristicCard(Icons.grass, context.tr("Loại rễ", "Root Type"), plantData['root_type'] ?? context.tr("Đang cập nhật thông tin", "Updating information"))),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCharacteristicCard(
                              Icons.warning_amber_rounded, 
                              context.tr("Độc tính", "Toxicity"), 
                              plantData['toxicity'] ?? context.tr("Chưa xác định", "Not determined"), 
                              isAlert: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top Navigation (Overlay)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavButton(
                  icon: Icons.chevron_left,
                  onTap: () => Navigator.pop(context),
                ),
                _buildNavButton(
                  icon: Icons.favorite_border,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Floating Action Bar
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 22),
              label: Text(context.tr("Thêm vào vườn", "Add to Garden"), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: Colors.white,
                elevation: 10,
                shadowColor: c.primary.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.webImageBytes != null) {
      return Image.memory(widget.webImageBytes!, fit: BoxFit.cover);
    } else if (widget.imagePath != null && !kIsWeb) {
      return Image.file(File(widget.imagePath!), fit: BoxFit.cover);
    } else if (widget.data['wiki_image'] != null) {
      return Image.network(widget.data['wiki_image'], fit: BoxFit.cover);
    } else {
      return const Center(child: Icon(Icons.eco, size: 100, color: Colors.white30));
    }
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onTap}) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isScrolled ? c.surface.withValues(alpha: 0.8) : Colors.black38,
          shape: BoxShape.circle,
          border: Border.all(color: _isScrolled ? c.border : Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: _isScrolled ? c.textPrimary : Colors.white,
        ),
      ),
    );
  }

  Widget _buildTaxonomyTag(String text, {required bool isPrimary}) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? c.surfaceTint : c.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPrimary ? c.primary.withValues(alpha: 0.3) : c.border),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
          color: isPrimary ? c.primary : c.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCharacteristicCard(IconData icon, String title, String desc, {bool isAlert = false}) {
    final c = context.colors;
    final alertColor = const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAlert ? alertColor.withValues(alpha: 0.08) : c.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAlert ? alertColor.withValues(alpha: 0.3) : c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isAlert ? alertColor.withValues(alpha: 0.12) : c.surfaceTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isAlert ? alertColor : c.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isAlert ? alertColor : c.textPrimary,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.inter(fontSize: 13, color: c.textSecondary, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
