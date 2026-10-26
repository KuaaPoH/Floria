import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

class MigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Chạy toàn bộ quá trình di chuyển ảnh Unsplash & Base64 sang ImgBB Cloud
  static Future<Map<String, int>> runFullMigration({Function(String)? onProgress}) async {
    int migratedShop = 0;
    int migratedPlants = 0;
    int migratedDiaries = 0;

    onProgress?.call("Bắt đầu di chuyển hình ảnh sang ImgBB Cloud vĩnh viễn...");

    // 1. Di chuyển ảnh sản phẩm Cửa hàng
    try {
      final shopSnapshot = await _firestore.collection('ShopProducts').get();
      for (final doc in shopSnapshot.docs) {
        final data = doc.data();
        final imgUrl = data['imageUrl'] as String?;
        if (imgUrl != null &&
            imgUrl.isNotEmpty &&
            !imgUrl.contains('ibb.co')) {
          onProgress?.call("Đang chuyển đổi sản phẩm: ${data['name'] ?? doc.id}...");
          final newUrl = await StorageService.migrateExternalUrlToStorage(
            externalUrl: imgUrl,
            targetPath: 'shop_products/${doc.id}.jpg',
          );
          if (newUrl != null && newUrl != imgUrl && newUrl.contains('ibb.co')) {
            await doc.reference.update({'imageUrl': newUrl});
            migratedShop++;
          }
        }
      }
    } catch (e) {
      debugPrint("Lỗi di chuyển ảnh Shop: $e");
    }

    // 2. Di chuyển ảnh cây trong Khu vườn (MyGarden)
    try {
      final plantsSnapshot = await _firestore.collection('MyGarden').get();
      for (final plantDoc in plantsSnapshot.docs) {
        final plantData = plantDoc.data();
        final plantImg = plantData['imageUrl'] as String?;
        if (plantImg != null &&
            plantImg.isNotEmpty &&
            !plantImg.contains('ibb.co')) {
          onProgress?.call("Đang chuyển đổi cây: ${plantData['nickname'] ?? plantDoc.id}...");
          final newUrl = await StorageService.migrateExternalUrlToStorage(
            externalUrl: plantImg,
            targetPath: 'garden_plants/${plantDoc.id}.jpg',
          );
          if (newUrl != null && newUrl != plantImg && newUrl.contains('ibb.co')) {
            await plantDoc.reference.update({'imageUrl': newUrl});
            migratedPlants++;
          }
        }

        // 3. Di chuyển ảnh trong Nhật ký (từ chuỗi Base64 sang ImgBB Cloud)
        try {
          final diarySnapshot = await plantDoc.reference.collection('DiaryNotes').get();
          for (final diaryDoc in diarySnapshot.docs) {
            final diaryData = diaryDoc.data();
            final List<dynamic>? rawUrls = diaryData['imageUrls'] as List<dynamic>?;
            final String? singleUrl = diaryData['imageUrl'] as String?;

            final List<String> currentImages = rawUrls != null
                ? rawUrls.map((e) => e.toString()).toList()
                : (singleUrl != null && singleUrl.isNotEmpty ? [singleUrl] : []);

            final List<String> newStorageUrls = [];
            bool hasChange = false;

            for (int i = 0; i < currentImages.length; i++) {
              final imgStr = currentImages[i];
              if (imgStr.startsWith('data:image') || imgStr.length > 500) {
                // Là ảnh Base64 -> chuyển thành bytes và upload lên ImgBB
                try {
                  final base64Content = imgStr.contains(',') ? imgStr.split(',').last : imgStr;
                  final bytes = base64Decode(base64Content);
                  final storageUrl = await StorageService.uploadToImgbb(bytes);
                  if (storageUrl != null && storageUrl.contains('ibb.co')) {
                    newStorageUrls.add(storageUrl);
                    hasChange = true;
                  } else {
                    newStorageUrls.add(imgStr);
                  }
                } catch (err) {
                  debugPrint("Lỗi giải mã base64 nhật ký: $err");
                  newStorageUrls.add(imgStr);
                }
              } else if (imgStr.contains('unsplash.com') ||
                  (!imgStr.contains('ibb.co') && imgStr.startsWith('http'))) {
                // Là link Unsplash bên ngoài -> tải về và lưu vào ImgBB
                final storageUrl = await StorageService.migrateExternalUrlToStorage(
                  externalUrl: imgStr,
                  targetPath: 'diary_migrated/${plantDoc.id}/${diaryDoc.id}_$i.jpg',
                );
                newStorageUrls.add(storageUrl ?? imgStr);
                if (storageUrl != null && storageUrl != imgStr && storageUrl.contains('ibb.co')) {
                  hasChange = true;
                }
              } else {
                newStorageUrls.add(imgStr);
              }
            }

            if (hasChange) {
              await diaryDoc.reference.update({
                'imageUrls': newStorageUrls,
                'imageUrl': newStorageUrls.isNotEmpty ? newStorageUrls.first : null,
              });
              migratedDiaries++;
            }
          }
        } catch (diaryErr) {
          debugPrint("Lỗi quét DiaryNotes của cây ${plantDoc.id}: $diaryErr");
        }
      }
    } catch (e) {
      debugPrint("Lỗi di chuyển ảnh Vườn: $e");
    }

    onProgress?.call("Hoàn tất! Đã chuyển đổi: $migratedShop sản phẩm, $migratedPlants cây, $migratedDiaries bài nhật ký.");

    return {
      'shop': migratedShop,
      'plants': migratedPlants,
      'diaries': migratedDiaries,
    };
  }
}
