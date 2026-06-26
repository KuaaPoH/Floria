import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_constants.dart';

class ScanProvider extends ChangeNotifier {
  final Dio _dio = Dio();
  
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _scanResult;
  XFile? _selectedImage;
  Uint8List? _webImageBytes; // Luu bytes de hien thi anh tren Web va Mobile

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get scanResult => _scanResult;
  XFile? get selectedImage => _selectedImage;
  Uint8List? get webImageBytes => _webImageBytes;

  // Chon anh tu Camera hoac Thu vien
  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1000, // Gioi han kich thuoc de upload nhanh hon
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (image != null) {
        _selectedImage = image;
        _webImageBytes = await image.readAsBytes();
        _scanResult = null; // Xoa ket qua cu
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Loi khi chon anh: $e";
      notifyListeners();
    }
  }

  // Nhan anh truc tiep (tu camera nhung)
  Future<void> setImage(XFile image) async {
    _selectedImage = image;
    _webImageBytes = await image.readAsBytes();
    _scanResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Gui anh len Spring Boot API de quet benh
  Future<void> uploadAndScan(String modelName) async {
    if (_selectedImage == null || _webImageBytes == null) {
      _errorMessage = "Vui long chon hoac chup anh truoc.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _scanResult = null;
    notifyListeners();

    try {
      // Chuyen doi anh sang MultipartFile tu mang bytes (hoat dong tren moi nen tang Web/Mobile)
      final MultipartFile multipartFile = MultipartFile.fromBytes(
        _webImageBytes!,
        filename: _selectedImage!.name,
      );

      final FormData formData = FormData.fromMap({
        'file': multipartFile,
      });

      // Gui request POST sang Spring Boot (vi du: /api/scan-disease?model=efficientnetb0)
      final String url = "${AppConstants.scanDiseaseUrl}?model=$modelName";
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        _scanResult = Map<String, dynamic>.from(response.data);
      } else {
        _errorMessage = "Loi backend: Ma phan hoi ${response.statusCode}";
      }
    } catch (e) {
      if (e is DioException) {
        // Xóa Mock Data để hiển thị LỖI THẬT
        _errorMessage = "Lỗi kết nối từ App: ${e.message} - Chi tiết: ${e.response?.data}";
      } else {
        _errorMessage = "Loi: $e";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset trang thai
  void reset() {
    _selectedImage = null;
    _webImageBytes = null;
    _scanResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}
