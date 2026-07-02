import firebase_admin
from firebase_admin import credentials, firestore
import json
import os

def upload_plants_to_firestore():
    # 1. Đọc file dữ liệu
    json_path = 'plants_data.json'
    if not os.path.exists(json_path):
        print(f"Không tìm thấy {json_path}. Vui lòng chạy python seed_plants.py trước.")
        return

    with open(json_path, 'r', encoding='utf-8') as f:
        plants_data = json.load(f)

    # 2. Khởi tạo Firebase
    # LƯU Ý: Bạn cần tạo và tải file serviceAccountKey.json từ Firebase Console
    # (Project Settings -> Service Accounts -> Generate new private key)
    # Sau đó đổi tên thành 'serviceAccountKey.json' và để cùng thư mục này.
    cred_path = 'serviceAccountKey.json'
    if not os.path.exists(cred_path):
        print(f"LỖI: Không tìm thấy {cred_path}!")
        print("Vui lòng tải file Private Key từ Firebase Console và đặt vào thư mục AI_Engine.")
        return

    try:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    except ValueError:
        # Nếu app đã được initialize trước đó
        pass

    db = firestore.client()
    collection_name = 'plants_info'

    print(f"Bắt đầu tải lên {len(plants_data)} loại cây lên Firestore (Collection: '{collection_name}')...")

    # 3. Đẩy dữ liệu
    success_count = 0
    for plant_id, data in plants_data.items():
        try:
            # Document ID chính là tên tiếng Anh (trùng khớp 100% với model AI)
            doc_ref = db.collection(collection_name).document(plant_id)
            doc_ref.set(data)
            success_count += 1
            print(f"[{success_count}/{len(plants_data)}] Đã tải lên: {plant_id}")
        except Exception as e:
            print(f"Lỗi khi tải lên {plant_id}: {e}")

    print(f"\nHoàn tất! Đã tải lên thành công {success_count}/{len(plants_data)} loại cây.")

if __name__ == "__main__":
    upload_plants_to_firestore()
