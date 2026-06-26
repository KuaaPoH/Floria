import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);
    final hasImage = scanProvider.selectedImage != null;

    return Scaffold(
      backgroundColor: const Color(0xFF151E16),
      body: Stack(
        children: [
          // Background / Camera View
          Positioned.fill(
            child: hasImage && scanProvider.webImageBytes != null
                ? Image.memory(
                    scanProvider.webImageBytes!,
                    fit: BoxFit.cover,
                  )
                : (_isCameraInitialized
                    ? SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _controller!.value.previewSize!.height,
                            height: _controller!.value.previewSize!.width,
                            child: CameraPreview(_controller!),
                          ),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))),
          ),

          // Lớp nền tối mờ khi đã chọn ảnh
          if (hasImage)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          
          // Header
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () {
                        if (hasImage) {
                          scanProvider.reset();
                        } else {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  Text(
                    hasImage ? 'Đang phân tích...' : 'Quét Cây Trồng',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
                      ],
                    ),
                  ),
                  const SizedBox(width: 40), // Spacer
                ],
              ),
            ),
          ),
          
          // Camera Focus Frame
          Positioned(
            top: 120,
            bottom: hasImage ? 120 : 220,
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasImage ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.4), 
                  width: hasImage ? 2 : 1
                ),
                borderRadius: BorderRadius.circular(32),
                color: hasImage ? Colors.transparent : null,
              ),
              child: Stack(
                children: [
                  // Focus Corners
                  Positioned(top: 20, left: 20, child: _buildFocusCorner(isTop: true, isLeft: true)),
                  Positioned(top: 20, right: 20, child: _buildFocusCorner(isTop: true, isLeft: false)),
                  Positioned(bottom: 20, left: 20, child: _buildFocusCorner(isTop: false, isLeft: true)),
                  Positioned(bottom: 20, right: 20, child: _buildFocusCorner(isTop: false, isLeft: false)),
                  
                  // Scanning Line Animation (Neon Effect)
                  if (hasImage && scanProvider.isLoading)
                    AnimatedBuilder(
                      animation: _scanAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: _scanAnimation.value * (MediaQuery.of(context).size.height - 380),
                          left: 0,
                          right: 0,
                          child: child!,
                        );
                      },
                      child: Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.8), blurRadius: 20, spreadRadius: 5),
                            BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                          ]
                        ),
                      ),
                    ),
                  
                  if (!hasImage)
                    Center(
                      child: Icon(Icons.center_focus_weak, size: 64, color: Colors.white.withValues(alpha: 0.5)),
                    )
                ],
              ),
            ),
          ),
          
          // Bottom Action Sheet
          if (!hasImage)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 32, bottom: 40, left: 20, right: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, -10))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Đưa lá cây vào giữa khung hình',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.beVietnamPro(fontSize: 14, color: const Color(0xFF3B4A3D), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Gallery Button
                        GestureDetector(
                          onTap: () => _handleGallerySelected(scanProvider),
                          child: Column(
                            children: [
                              Container(
                                width: 56, height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE6F1E4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.photo_library, size: 28, color: Color(0xFF3B4A3D)),
                              ),
                              const SizedBox(height: 8),
                              Text('Thư viện', style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF3B4A3D))),
                            ],
                          ),
                        ),
                        
                        // Main Capture Button
                        GestureDetector(
                          onTap: () => _captureFromCamera(scanProvider),
                          child: Container(
                            width: 96, height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3), width: 4),
                            ),
                            child: Center(
                              child: Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.4), blurRadius: 20)],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF00612E).withValues(alpha: 0.2), width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Flash Button
                        GestureDetector(
                          onTap: _toggleFlash,
                          child: Column(
                            children: [
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                  color: _isFlashOn ? const Color(0xFF00E676) : const Color(0xFFE6F1E4),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isFlashOn ? Icons.flash_on : Icons.flash_off, 
                                  size: 28, 
                                  color: _isFlashOn ? Colors.white : const Color(0xFF3B4A3D)
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Đèn Flash', style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFF3B4A3D))),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            
          if (hasImage && scanProvider.errorMessage != null)
            Positioned(
              bottom: 40,
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
            )
        ],
      ),
    );
  }

  Widget _buildFocusCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Color(0xFF00E676), width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Color(0xFF00E676), width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Color(0xFF00E676), width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Color(0xFF00E676), width: 3) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(12) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(12) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
        ),
      ),
    );
  }
}
