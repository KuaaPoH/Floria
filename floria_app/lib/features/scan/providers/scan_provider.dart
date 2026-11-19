import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/gemini_service.dart';

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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _errorMessage = "Vui lòng đăng nhập để sử dụng tính năng quét cây!";
        _isLoading = false;
        notifyListeners();
        return;
      }

      String? token;
      try {
        token = await user.getIdToken();
      } catch (_) {}

      // 1. Ưu tiên nhận diện bằng Google Gemini Multimodal để tránh đoán nhầm cây ngoài 40 loài
      if (await GeminiService.hasApiKey()) {
        try {
          final geminiRes = await GeminiService.identifyPlantWithHint(
            imageBytes: _webImageBytes!,
            userHint: '',
          );
          if (!geminiRes.isPlant) {
            _scanResult = {
              'model_used': 'gemini-multimodal',
              'prediction': 'Không phải cây',
              'confidence': 0.0,
              'top_3': [],
              'is_valid_plant': false,
              'is_in_database': false,
              'message': geminiRes.rejectReason ??
                  'Hệ thống phát hiện đây không phải là thực vật. Vui lòng chụp ảnh lá cây hoặc cây cảnh!',
            };
          } else {
            _scanResult = {
              'model_used': 'gemini-multimodal',
              'prediction': geminiRes.scientificName,
              'name_vi': geminiRes.nameVi,
              'confidence': geminiRes.confidence,
              'is_valid_plant': true,
              'is_in_database': geminiRes.matchedDatabase,
              'short_desc': geminiRes.shortDesc,
            };
          }
          _isLoading = false;
          notifyListeners();
          return;
        } catch (e) {
          debugPrint('LLM lỗi, chuyển sang AI Engine nội bộ: $e');
        }
      }

      // 2. Fallback sang Spring Boot + AI Engine (ONNX + CLIP) nếu không có key hoặc Gemini lỗi
      final MultipartFile multipartFile = MultipartFile.fromBytes(
        _webImageBytes!,
        filename: _selectedImage!.name,
      );

      final Map<String, dynamic> formMap = {
        'file': multipartFile,
        'user_id': user.uid,
      };

      final FormData formData = FormData.fromMap(formMap);

      final Map<String, dynamic> headers = {
        'Accept': 'application/json',
        'X-User-Id': user.uid,
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Gui request POST sang Spring Boot (vi du: /api/scan-disease?model=efficientnetb0)
      final String url = "${AppConstants.scanDiseaseUrl}?model=$modelName";
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        _scanResult = Map<String, dynamic>.from(response.data);
      } else {
        _errorMessage = "Loi backend: Ma phan hoi ${response.statusCode}";
      }
    } catch (e) {
      if (e is DioException) {
        // Xóa Mock Data để hiển thị LỖI THẬT
        _errorMessage =
            "Lỗi kết nối từ App: ${e.message} - Chi tiết: ${e.response?.data}";
      } else {
        _errorMessage = "Loi: $e";
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Gửi ảnh lên Spring Boot API chuyên trách chẩn đoán bệnh lá cây (/api/diagnose-disease)
  Future<void> uploadAndDiagnoseDisease({
    String? plantName,
    String? plantId,
    String? token,
  }) async {
    if (_selectedImage == null || _webImageBytes == null) {
      _errorMessage = "Vui lòng chọn hoặc chụp ảnh lá cây cần kiểm tra.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _scanResult = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _errorMessage = "Vui lòng đăng nhập để chẩn đoán bệnh cho cây!";
        _isLoading = false;
        notifyListeners();
        return;
      }

      String? authToken = token;
      if (authToken == null || authToken.isEmpty) {
        try {
          authToken = await user.getIdToken();
        } catch (_) {}
      }

      // 1. Ưu tiên chẩn đoán bằng Google Gemini Multimodal (nhận diện được cả bệnh ngoài 5 loại)
      if (await GeminiService.hasApiKey()) {
        try {
          final geminiRes = await GeminiService.diagnoseDiseaseWithImage(
            imageBytes: _webImageBytes!,
            plantName: plantName,
          );
          if (!geminiRes.isPlant) {
            _scanResult = {
              'model_used': 'gemini-multimodal',
              'prediction': 'Không phải cây',
              'prediction_vi': 'Không phải thực vật',
              'confidence': 0.0,
              'top_3': [],
              'is_valid_plant': false,
              'is_in_database': false,
              'message': geminiRes.rejectReason ??
                  'Hệ thống phát hiện đây không phải là thực vật!',
            };
          } else {
            _scanResult = {
              'model_used': 'gemini-multimodal',
              'prediction': geminiRes.prediction,
              'prediction_vi': geminiRes.predictionVi,
              'confidence': geminiRes.confidence,
              if (geminiRes.matchedDatabase) 'severity': geminiRes.severity,
              if (geminiRes.matchedDatabase) 'severity_vi': geminiRes.severity,
              if (geminiRes.matchedDatabase) 'cause': geminiRes.cause,
              if (geminiRes.matchedDatabase) 'treatment_steps': geminiRes.treatmentSteps,
              'is_valid_plant': true,
              'is_in_database': geminiRes.matchedDatabase,
              'top_3': [
                {
                  'class': geminiRes.prediction,
                  'name_vi': geminiRes.predictionVi,
                  'confidence': geminiRes.confidence,
                },
              ],
            };
          }
          _isLoading = false;
          notifyListeners();
          return;
        } catch (e) {
          debugPrint('Gemini chẩn đoán bệnh lỗi, chuyển sang AI Engine: $e');
        }
      }

      // 2. Fallback sang Spring Boot + AI Engine (/api/diagnose-disease)
      final MultipartFile multipartFile = MultipartFile.fromBytes(
        _webImageBytes!,
        filename: _selectedImage!.name,
      );

      final Map<String, dynamic> formMap = {
        'file': multipartFile,
        'user_id': user.uid,
      };
      if (plantName != null && plantName.isNotEmpty) {
        formMap['plant_name'] = plantName;
      }
      if (plantId != null && plantId.isNotEmpty) {
        formMap['plant_id'] = plantId;
      }

      final FormData formData = FormData.fromMap(formMap);

      final Map<String, dynamic> headers = {
        'Accept': 'application/json',
        'X-User-Id': user.uid,
      };
      if (authToken != null && authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await _dio.post(
        AppConstants.diagnoseDiseaseUrl,
        data: formData,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data != null) {
        final result = Map<String, dynamic>.from(response.data);
        final bool isValidPlant = result['is_valid_plant'] != false;
        final double conf = (result['confidence'] as num?)?.toDouble() ?? 0.0;
        final bool isInDb = result['is_in_database'] != false && conf >= 70.0;

        // Chỉ fallback sang Gemini khi AI Engine xác nhận là cây nhưng độ tin cậy < 50% (ngoài 40 loài)
        if (isValidPlant && !isInDb && _webImageBytes != null) {
          try {
            if (await GeminiService.hasApiKey()) {
              final geminiRes = await GeminiService.identifyPlantWithHint(
                imageBytes: _webImageBytes!,
                userHint: '',
              );
              if (!geminiRes.isPlant) {
                result['is_valid_plant'] = false;
                result['message'] =
                    geminiRes.rejectReason ??
                    'Hệ thống phát hiện đây không phải là thực vật.';
              } else {
                result['prediction'] = geminiRes.scientificName;
                result['name_vi'] = geminiRes.nameVi;
                result['confidence'] = geminiRes.confidence;
                result['is_in_database'] = geminiRes.matchedDatabase;
                result['short_desc'] = geminiRes.shortDesc;
                result['top_3'] = [
                  {
                    'class': geminiRes.scientificName,
                    'name_vi': geminiRes.nameVi,
                    'confidence': geminiRes.confidence,
                  },
                ];
                if (!geminiRes.matchedDatabase) {
                  result.remove('plant_details');
                  result.remove('plants_map');
                }
              }
            }
          } catch (e) {
            debugPrint('Lỗi fallback Gemini khi quét cây < 50%: $e');
          }
        }

        _scanResult = result;
      } else {
        _errorMessage = "Lỗi phản hồi máy chủ: Mã ${response.statusCode}";
      }
    } catch (e) {
      if (e is DioException) {
        _errorMessage =
            "Lỗi kết nối từ App: ${e.message} - Chi tiết: ${e.response?.data}";
      } else {
        _errorMessage = "Lỗi chẩn đoán bệnh: $e";
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
