from fastapi import FastAPI, File, UploadFile, Form, HTTPException
import tensorflow as tf
from PIL import Image
import numpy as np
import io
import os

import keras

@keras.saving.register_keras_serializable()
def preprocess_input(x):
    return (x / 127.5) - 1.0

app = FastAPI(title="AI Disease Classification Engine")

models_path = "models"
if not os.path.exists(models_path):
    os.makedirs(models_path)

loaded_models = {}

print("Dang khoi dong AI Engine va tai mo hinh...")
try:
    # 1. Tải EfficientNetB0 (Mô hình chính ưu tiên nhất)
    eff_path = os.path.join(models_path, "best_efficientnetb0_model.keras")
    if os.path.exists(eff_path):
        loaded_models["efficientnetb0"] = tf.keras.models.load_model(eff_path)
        print("Da tai xong EfficientNetB0")
        
    # 2. Tải MobileNetV2
    mob_path = os.path.join(models_path, "best_mobilenetv2_model.keras")
    if os.path.exists(mob_path):
        loaded_models["mobilenetv2"] = tf.keras.models.load_model(mob_path)
        print("Da tai xong MobileNetV2")
        
    # 3. Tải ResNet50V2
    res_path = os.path.join(models_path, "best_resnet50v2_model.keras")
    if os.path.exists(res_path):
        loaded_models["resnet50v2"] = tf.keras.models.load_model(res_path)
        print("Da tai xong ResNet50V2")

except Exception as e:
    print(f"Loi khi tai mo hinh: {e}")

if not loaded_models:
    print("CANH BAO: Chua co mo hinh nao duoc tai. Hay chep cac file .keras vao thu muc AI_Engine/models/")

# Load danh sách nhãn bệnh
class_names = []
labels_path = os.path.join(models_path, "labels.txt")
if os.path.exists(labels_path):
    with open(labels_path, "r", encoding="utf-8") as f:
        class_names = [line.strip() for line in f.readlines()]
else:
    print("CANH BAO: Khong tim thay file labels.txt trong thu muc models/")

def preprocess_image(image_bytes):
    # Đọc ảnh từ Bytes, chuyển sang RGB và scale về (224, 224)
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = image.resize((224, 224))
    
    # Save the image for debugging
    image.save("debug_received_image.jpg")
    
    # Chuyển thành ma trận số
    img_array = tf.keras.preprocessing.image.img_to_array(image)
    
    # Thêm chiều batch (1, 224, 224, 3)
    img_array = np.expand_dims(img_array, axis=0)
    return img_array

@app.get("/")
def home():
    return {
        "status": "online",
        "message": "AI Engine Microservice đang hoạt động!",
        "loaded_models": list(loaded_models.keys())
    }

@app.post("/predict")
async def predict(file: UploadFile = File(...), model_name: str = Form("efficientnetb0")):
    model_name = model_name.lower()
    
    if model_name not in loaded_models:
        raise HTTPException(
            status_code=400, 
            detail=f"Mô hình '{model_name}' chưa được tải lên Server. Các mô hình hiện có: {list(loaded_models.keys())}"
        )
        
    try:
        # Đọc dữ liệu ảnh gửi qua mạng
        image_bytes = await file.read()
        img_array = preprocess_image(image_bytes)
        
        # Đưa qua AI đoán
        model = loaded_models[model_name]
        predictions = model.predict(img_array, verbose=0)
        
        # Rút trích nhãn có xác suất cao nhất
        predicted_idx = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_idx])
        
        # Lấy tên bệnh từ labels.txt
        predicted_class = class_names[predicted_idx] if class_names else str(predicted_idx)
        
        return {
            "model_used": model_name,
            "prediction": predicted_class,
            "confidence": round(confidence * 100, 2), # Trả về phần trăm cho dễ đọc
            "success": True
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi khi phân tích ảnh: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    # Mở cổng 8000 cho AI Engine
    uvicorn.run(app, host="0.0.0.0", port=8000)
