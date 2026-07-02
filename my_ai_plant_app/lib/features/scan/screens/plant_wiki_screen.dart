import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  // Design Tokens (Verdant Care)
  static const Color surface = Color(0xFFfbf9f6);
  static const Color surfaceVariant = Color(0xFFe4e2df);
  static const Color surfaceContainerLow = Color(0xFFf5f3f0);
  static const Color surfaceContainerLowest = Color(0xFFffffff);
  static const Color surfaceContainerHighest = Color(0xFFe4e2df);
  static const Color surfaceContainer = Color(0xFFefeeea);
  static const Color onSurface = Color(0xFF1b1c1a);
  static const Color onSurfaceVariant = Color(0xFF444842);
  static const Color primary = Color(0xFF364534);
  static const Color primaryContainer = Color(0xFF4d5d4a);
  static const Color onPrimaryContainer = Color(0xFFc3d5bd);
  static const Color secondaryContainer = Color(0xFFd4e8ce);
  static const Color secondaryFixed = Color(0xFFd4e8ce);
  static const Color onSecondaryFixedVariant = Color(0xFF3a4b38);
  static const Color error = Color(0xFFba1a1a);
  static const Color errorContainer = Color(0xFFffdad6);

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
    String nameVi = widget.data['name_vi'] ?? widget.docId.replaceAll('_', ' ');
    String scientificName = widget.data['scientific_name'] ?? 'Chưa cập nhật';
    String family = widget.data['family'] ?? 'Chưa cập nhật';
    String description = widget.data['wiki_detail'] ?? widget.data['description'] ?? widget.data['wiki_description'] ?? 'Chưa có thông tin bách khoa về loài cây này.';

    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          // Fixed Hero Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 400,
            child: Container(
              color: secondaryContainer,
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
                          Colors.black.withOpacity(0.4),
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
                    color: surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4D5D4A).withOpacity(0.15),
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
                            color: surfaceVariant,
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
                        style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: onSurface, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        scientificName,
                        style: GoogleFonts.inter(fontSize: 17, color: onSurfaceVariant, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 32),

                      // Biological Profile
                      Row(
                        children: [
                          const Icon(Icons.menu_book, color: primary, size: 20),
                          const SizedBox(width: 8),
                          Text("Hồ sơ sinh học", style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: onSurface)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: surfaceVariant.withOpacity(0.5)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
                        ),
                        child: Text(
                          description,
                          style: GoogleFonts.inter(fontSize: 15, color: onSurfaceVariant, height: 1.6),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Morphological Characteristics
                      Row(
                        children: [
                          const Icon(Icons.nature, color: primary, size: 20),
                          const SizedBox(width: 8),
                          Text("Đặc điểm hình thái", style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: onSurface)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Grid
                      Row(
                        children: [
                          Expanded(child: _buildCharacteristicCard(Icons.eco, "Đặc điểm nhận dạng", widget.data['identification'] ?? "Đang cập nhật thông tin")),
                          const SizedBox(width: 16),
                          Expanded(child: _buildCharacteristicCard(Icons.light_mode, "Ánh sáng", widget.data['light'] ?? "Đang cập nhật thông tin")),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildCharacteristicCard(Icons.grass, "Loại rễ", widget.data['root_type'] ?? "Đang cập nhật thông tin")),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCharacteristicCard(
                              Icons.warning_amber_rounded, 
                              "Độc tính", 
                              widget.data['toxicity'] ?? "Chưa xác định", 
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
              label: Text("Thêm vào vườn", style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryContainer,
                foregroundColor: onPrimaryContainer,
                elevation: 10,
                shadowColor: primaryContainer.withOpacity(0.5),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _isScrolled ? surface.withOpacity(0.8) : Colors.white.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: _isScrolled ? surfaceVariant.withOpacity(0.5) : Colors.white.withOpacity(0.1)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: _isScrolled ? onSurface : Colors.white,
        ),
      ),
    );
  }

  Widget _buildTaxonomyTag(String text, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? secondaryFixed.withOpacity(0.5) : surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isPrimary ? secondaryFixed : Colors.transparent),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
          color: isPrimary ? onSecondaryFixedVariant : onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCharacteristicCard(IconData icon, String title, String desc, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAlert ? errorContainer.withOpacity(0.3) : surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAlert ? errorContainer : surfaceVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isAlert ? error.withOpacity(0.1) : primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isAlert ? error : primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isAlert ? error : onSurface,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.inter(fontSize: 13, color: onSurfaceVariant, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAvatar(IconData icon) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: surfaceContainer,
        shape: BoxShape.circle,
        border: Border.all(color: surface, width: 2),
      ),
      child: Icon(icon, size: 16, color: primary),
    );
  }
}
