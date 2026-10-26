import firebase_admin
from firebase_admin import credentials, firestore
import os
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

diseases_data = {
    "Healthy": {
        "nameVi": "Lá Khỏe Mạnh",
        "nameEn": "Healthy Leaf",
        "severity": "Bình thường",
        "pathogen": "Không có mầm bệnh - Sinh lý cây cân bằng",
        "mechanism": "Quá trình quang hợp, hô hấp và thoát hơi nước diễn ra ổn định. Biểu bì và tầng cutin nguyên vẹn bảo vệ các mô xốp bên trong khỏi tác nhân xâm hại.",
        "favorableConditions": "Ánh sáng tán xạ thích hợp, nhiệt độ 20-30°C, giá thể tơi xốp thoáng khí và dinh dưỡng khoáng cân bằng.",
        "prevention": "Duy trì chế độ tưới nước vừa đủ theo nguyên tắc khô - ướt xen kẽ, lau bụi lá định kỳ để tối ưu quang hợp."
    },
    "Anthracnose": {
        "nameVi": "Bệnh Thán Thư",
        "nameEn": "Anthracnose",
        "severity": "Nguy hiểm",
        "pathogen": "Nấm Colletotrichum spp.",
        "mechanism": "Bào tử nấm nảy mầm hình thành giác bám (appressorium), đâm xuyên lớp cutin biểu bì lá và tiết enzyme phân giải pectin, cellulose. Mô lá bị hoại tử sụp đổ tạo thành các đốm nâu khô giòn có viền sẫm màu.",
        "favorableConditions": "Độ ẩm không khí cao (>85%), giọt nước đọng sương qua đêm trên phiến lá, nhiệt độ ấm áp 25-30°C và không gian bí gió.",
        "prevention": "Cách ly cây, giữ khoảng cách thông thoáng giữa các chậu cây, tưới trực tiếp vào gốc vào buổi sáng và tránh làm ướt mặt lá vào ban đêm."
    },
    "Leaf_Spot": {
        "nameVi": "Bệnh Đốm Lá Nấm",
        "nameEn": "Fungal Leaf Spot",
        "severity": "Cảnh báo",
        "pathogen": "Nấm Cercospora / Alternaria spp.",
        "mechanism": "Sợi nấm xâm nhập qua khí khổng hoặc vết thương vi mô, tiết độc tố cercosporin phá hủy màng tế bào. Diệp lục bị phân hủy tạo thành các đốm mắt cua hoại tử, gây vàng úa và rụng lá sớm.",
        "favorableConditions": "Lá bị ẩm ướt kéo dài, ánh sáng tự nhiên yếu ớt, giá thể chậu ngậm nước lâu ngày hoặc cây thiếu vi lượng.",
        "prevention": "Tăng cường độ thông thoáng khí, đưa cây ra khu vực có ánh sáng tán xạ tốt hơn, khử trùng kéo cắt tỉa định kỳ."
    },
    "Bacterial_Blight": {
        "nameVi": "Cháy Bìa Lá Vi Khuẩn",
        "nameEn": "Bacterial Blight",
        "severity": "Nguy hiểm",
        "pathogen": "Vi khuẩn Xanthomonas / Erwinia spp.",
        "mechanism": "Vi khuẩn xâm nhập qua thủy khổng ở mép lá hoặc qua vết rách tổn thương cơ học. Chúng sinh sôi trong bó mạch dẫn, tiết chất nhầy polysaccharide gây tắc nghẽn dòng nhựa, làm mép lá sũng nước rồi cháy khô hoại tử.",
        "favorableConditions": "Giá thể ngập úng bí rễ, thời tiết nồm ẩm oi bức (28-32°C), nước tưới bắn tung tóe hoặc vết thương hở do va quẹt.",
        "prevention": "Kiểm tra lỗ thoát nước đáy chậu, ngưng tưới khi phát hiện vết úng, không cắt tỉa lá lúc trời mưa ẩm để tránh vi khuẩn xâm nhập."
    },
    "Powdery_Mildew": {
        "nameVi": "Bệnh Phấn Trắng",
        "nameEn": "Powdery Mildew",
        "severity": "Cảnh báo",
        "pathogen": "Nấm ngoại ký sinh họ Erysiphaceae",
        "mechanism": "Bào tử nấm phát triển mạng lưới sợi nấm màu trắng phủ kín mặt ngoài phiến lá. Chúng đâm các vòi hút (haustoria) vào tế bào biểu bì hút kiệt chất dinh dưỡng, cản trở quang hợp khiến lá non xoăn tít và biến dạng.",
        "favorableConditions": "Chênh lệch nhiệt độ ngày - đêm cao, đêm nồm ẩm sương mù nhưng ban ngày khô ráo, cây thiếu sáng hoặc bón thừa phân đạm.",
        "prevention": "Tăng độ lưu thông không khí, đặt chậu ở nơi đón nắng sớm, tránh bón đạm quá mức và bổ sung kali tăng độ cứng vách tế bào."
    }
}

def upload_diseases_to_firestore():
    cred_path = 'serviceAccountKey.json'
    if not os.path.exists(cred_path):
        cred_path = 'AI_Engine/serviceAccountKey.json'

    if not os.path.exists(cred_path):
        print(f"LỖI: Không tìm thấy {cred_path}!")
        return

    try:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
    except ValueError:
        pass

    db = firestore.client()
    collection_name = 'DiseasesInfo'

    print(f"Cập nhật 5 hồ sơ bệnh học vào Firestore (Collection: '{collection_name}')...")

    success_count = 0
    for disease_id, data in diseases_data.items():
        try:
            # Ghi đè set() để xóa sạch các trường cũ không cần thiết (imageUrl, symptoms, treatmentSteps...)
            doc_ref = db.collection(collection_name).document(disease_id)
            doc_ref.set(data)
            success_count += 1
            print(f"[{success_count}/5] Đã lưu: {disease_id} ({data['nameVi']})")
        except Exception as e:
            print(f"Lỗi khi tải lên {disease_id}: {e}")

    print(f"\nHoàn tất! Đã cập nhật thành công {success_count}/5 hồ sơ bệnh học lên Firestore.")

if __name__ == "__main__":
    upload_diseases_to_firestore()
