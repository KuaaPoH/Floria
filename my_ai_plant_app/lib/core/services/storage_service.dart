import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class StorageService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 25),
    ),
  );

  /// Tải 1 ảnh lên ImgBB Cloud và nhận về đường dẫn trực tiếp (Direct URL vĩnh viễn)
  static Future<String?> uploadToImgbb(
    Uint8List bytes, {
    ProgressCallback? onProgress,
  }) async {
    try {
      final base64Image = base64Encode(bytes);
      final formData = FormData.fromMap({
        'key': AppConstants.imgbbApiKey,
        'image': base64Image,
      });

      final response = await _dio.post(
        AppConstants.imgbbUploadUrl,
        data: formData,
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null && data['url'] != null) {
          final String directUrl = data['url'].toString();
          debugPrint("✅ Tải ảnh lên ImgBB thành công: $directUrl");
          return directUrl;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Lỗi upload ảnh lên ImgBB: $e");
    }
    return null;
  }

  /// Tải nhiều ảnh nhật ký cây lên ImgBB Cloud song song (tối ưu tốc độ cao)
  static Future<List<String>> uploadDiaryImages({
    required List<Uint8List> imagesBytes,
    required String plantId,
  }) async {
    if (imagesBytes.isEmpty) return [];

    // Chạy song song tất cả các tiến trình upload cùng một lúc để tiết kiệm thời gian
    final futures = imagesBytes.map((bytes) async {
      final url = await uploadToImgbb(bytes);
      if (url != null && url.isNotEmpty) {
        return url;
      }
      // Fallback tự động: nếu mạng lỗi thì lưu base64 để người dùng không bị mất bài viết
      return "data:image/jpeg;base64,${base64Encode(bytes)}";
    });

    return await Future.wait(futures);
  }

  /// Tải 1 ảnh chụp cây mới lên ImgBB Cloud
  static Future<String?> uploadPlantPhoto({
    required Uint8List bytes,
    required String plantName,
    ProgressCallback? onProgress,
  }) async {
    return await uploadToImgbb(bytes, onProgress: onProgress);
  }

  /// Tải một ảnh từ URL bên ngoài (VD: Unsplash) về và lưu vĩnh viễn lên ImgBB Cloud
  static Future<String?> migrateExternalUrlToStorage({
    required String externalUrl,
    required String targetPath,
  }) async {
    // Nếu ảnh đã nằm trên ImgBB thì giữ nguyên
    if (externalUrl.contains('ibb.co')) {
      return externalUrl;
    }

    try {
      final response = await _dio.get<List<int>>(
        externalUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(response.data!);
        final imgbbUrl = await uploadToImgbb(bytes);
        return imgbbUrl ?? externalUrl;
      }
    } catch (e) {
      debugPrint("Không thể chuyển đổi ảnh từ $externalUrl sang ImgBB: $e");
    }
    return externalUrl;
  }
}
