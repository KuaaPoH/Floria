import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import 'dart:ui';
import 'diagnosis_report_screen.dart';

class CameraScanningScreen extends StatefulWidget {
  final String selectedModel;

  const CameraScanningScreen({super.key, required this.selectedModel});

  @override
  State<CameraScanningScreen> createState() => _CameraScanningScreenState();
}

class _CameraScanningScreenState extends State<CameraScanningScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;
  
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );
    
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.veryHigh, // Nâng độ nét lên 1080p, preview sẽ cực nét
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanAnimationController.dispose();
    super.dispose();
  }

  Future<void> _processImage(ScanProvider scanProvider) async {
    // Bắt đầu hiệu ứng quét
    _scanAnimationController.repeat(reverse: true);
    
    // Gọi API phân tích
    await scanProvider.uploadAndScan(widget.selectedModel);
    
    // Dừng hiệu ứng khi xong
    _scanAnimationController.stop();
    
    if (mounted && scanProvider.scanResult != null && scanProvider.errorMessage == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DiagnosisReportScreen()),
      );
    }
  }

  Future<void> _handleGallerySelected(ScanProvider scanProvider) async {
    await scanProvider.pickImage(ImageSource.gallery);
    if (scanProvider.selectedImage != null && mounted) {
      await _processImage(scanProvider);
    }
  }
  
  Future<void> _captureFromCamera(ScanProvider scanProvider) async {
    if (!_isCameraInitialized || _controller == null) return;
    try {
      final XFile image = await _controller!.takePicture();
      await scanProvider.setImage(image);
      if (mounted) {
        await _processImage(scanProvider);
      }
    } catch (e) {
      debugPrint("Capture error: $e");
    }
  }

  void _toggleFlash() async {
    if (!_isCameraInitialized || _controller == null) return;
    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
        setState(() => _isFlashOn = false);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
        setState(() => _isFlashOn = true);
      }
    } catch (e) {
      debugPrint("Flash error: $e");
    }
  }

  void _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    try {
      final lensDirection = _controller!.description.lensDirection;
      CameraDescription newCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection != lensDirection,
        orElse: () => _cameras!.first,
      );
      
      await _controller?.dispose();
      _controller = CameraController(
        newCamera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Toggle camera error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);
    final hasImage = scanProvider.selectedImage != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background / Camera View
          if (hasImage && scanProvider.webImageBytes != null)
            Image.memory(
              scanProvider.webImageBytes!,
              fit: BoxFit.cover,
            )
          else if (_isCameraInitialized && _controller != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.previewSize?.height ?? 1,
                  height: _controller!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_controller!),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFFD6E8CF))),

          // Lớp nền tối mờ khi đã chọn ảnh
          if (hasImage)
            Container(color: Colors.black.withValues(alpha: 0.3)),

          // Top Action Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildGlassButton(
                  icon: Icons.close,
                  onTap: () {
                    if (hasImage) {
                      scanProvider.reset();
                    } else {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    }
                  },
                ),
                Row(
                  children: [
                    _buildGlassButton(
                      icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      onTap: _toggleFlash,
                    ),
                    const SizedBox(width: 16),
                    _buildGlassButton(
                      icon: Icons.help_outline,
                      onTap: () {
                        // Show help
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Viewfinder Reticle
          if (!hasImage)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      children: [
                        Positioned(top: 0, left: 0, child: _buildFocusCorner(isTop: true, isLeft: true)),
                        Positioned(top: 0, right: 0, child: _buildFocusCorner(isTop: true, isLeft: false)),
                        Positioned(bottom: 0, left: 0, child: _buildFocusCorner(isTop: false, isLeft: true)),
                        Positioned(bottom: 0, right: 0, child: _buildFocusCorner(isTop: false, isLeft: false)),
                        
                        // Scanning Line Animation
                        if (scanProvider.isLoading)
                          AnimatedBuilder(
                            animation: _scanAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: _scanAnimation.value * 260,
                                left: 0,
                                right: 0,
                                child: child!,
                              );
                            },
                            child: Container(
                              height: 2,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD6E8CF),
                                boxShadow: [
                                  BoxShadow(color: Color(0xFFD6E8CF), blurRadius: 8),
                                ]
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Instructional Text
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          scanProvider.isLoading ? 'Đang phân tích...' : 'Đưa lá bệnh vào giữa khung hình',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Error Message
          if (hasImage && scanProvider.errorMessage != null)
            Positioned(
              top: MediaQuery.of(context).size.height / 2 + 150,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  scanProvider.errorMessage!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            
          // Bottom Controls Area
          if (!hasImage)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // Mode Switcher
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Nhận diện cây',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.7)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF364534), // primary
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                                ],
                              ),
                              child: Text(
                                'Chẩn đoán bệnh',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Shutter Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Gallery Button
                      GestureDetector(
                        onTap: () => _handleGallerySelected(scanProvider),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                              ),
                              child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      ),
                      
                      // Shutter Button
                      GestureDetector(
                        onTap: () => _captureFromCamera(scanProvider),
                        child: Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF364534), width: 2),
                            ),
                            child: const Center(
                              child: Icon(Icons.document_scanner, color: Color(0xFF364534), size: 32),
                            ),
                          ),
                        ),
                      ),
                      
                      // Flip Camera Button
                      _buildGlassButton(
                        icon: Icons.flip_camera_ios,
                        size: 48,
                        onTap: _toggleCamera,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap, double size = 40}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
        ),
      ),
    );
  }
}
