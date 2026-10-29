import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'diagnosis_report_screen.dart';

class CameraScanningScreen extends StatefulWidget {
  final String selectedModel;

  const CameraScanningScreen({super.key, this.selectedModel = 'floria_vision'});

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
    // Chạy ngầm việc tải ảnh lên và phân tích TRƯỚC KHI chuyển trang
    scanProvider.uploadAndScan(widget.selectedModel);

    // Tắt preview camera
    try {
      await _controller?.pausePreview();
    } catch (e) {}

    // Chuyển trang sang màn hình kết quả (giữ Camera ở dưới stack)
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DiagnosisReportScreen()),
      );
      
      // Khi quay lại từ màn hình kết quả:
      // Đợi animation đóng trang kết thúc (khoảng 400ms) rồi mới xóa dữ liệu để tránh nháy giật giao diện
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          scanProvider.reset();
          try {
            _controller?.resumePreview();
          } catch (e) {}
        }
      });
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
          // Background / Camera View (Always active in background, paused when hasImage)
          if (_isCameraInitialized && _controller != null)
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

          // --- XÓA TOÀN BỘ GIAO DIỆN LOAD CŨ TRÊN CAMERA ---
          // Khi chọn ảnh/chụp xong, Camera chỉ đóng băng hình ảnh hiện tại và nhảy ngay sang trang kết quả.
          // Không còn vòng lặp quét loading ở đây nữa!

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
                  iconColor: hasImage ? Colors.black87 : Colors.white,
                  bgColor: hasImage ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.2),
                  onTap: () {
                    if (hasImage) {
                      scanProvider.reset();
                      try {
                        _controller?.resumePreview();
                      } catch (e) {}
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
                          'Đưa lá bệnh vào giữa khung hình',
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

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap, double size = 40, Color iconColor = Colors.white, Color? bgColor}) {
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
              color: bgColor ?? Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: iconColor, size: size * 0.5),
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

// --- HIỆU ỨNG HẠT BAY LÊN ---
class FloatingParticles extends StatefulWidget {
  const FloatingParticles({super.key});
  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> particles = List.generate(20, (index) => Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ParticlePainter(particles, _controller.value),
        );
      },
    );
  }
}

class Particle {
  final double x = math.Random().nextDouble();
  final double y = math.Random().nextDouble();
  final double speed = math.Random().nextDouble() * 0.4 + 0.2;
  final double size = math.Random().nextDouble() * 15 + 5;
  final double opacity = math.Random().nextDouble() * 0.5 + 0.1;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = const Color(0xFF6D7F69).withOpacity(p.opacity) // Màu xanh rêu nhạt
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5); // Tỏa sáng nhẹ
      
      // Tính tọa độ Y: bay từ dưới lên trên
      double currentY = (p.y - progress * p.speed) % 1.0;
      if (currentY < 0) currentY += 1.0;
      
      // Tính tọa độ X: trôi lơ lửng nhẹ sang ngang bằng hàm Sin
      double currentX = p.x + math.sin((progress * math.pi * 4) + p.y * 10) * 0.05;
      
      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height), 
        p.size, 
        paint
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
