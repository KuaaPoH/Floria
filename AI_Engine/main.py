from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from PIL import Image
import numpy as np
import io
import os
import onnxruntime as ort
import torch
from transformers import CLIPProcessor, CLIPModel

app = FastAPI(title="AI Disease Classification Engine")

models_path = "models"
if not os.path.exists(models_path):
    os.makedirs(models_path)

loaded_models = {}

print("Dang khoi dong AI Engine va tai mo hinh ONNX...")
try:
    onnx_path = os.path.join(models_path, "mobilenetv3_large_100.onnx")
    if os.path.exists(onnx_path):
        # Load ONNX model
        session = ort.InferenceSession(onnx_path, providers=['CPUExecutionProvider'])
        loaded_models["mobilenetv3_large_100"] = session
        print("Da tai xong mobilenetv3_large_100 (ONNX)")
except Exception as e:
    print(f"Loi khi tai mo hinh: {e}")

print("Dang tai mo hinh kiem duyet CLIP (Gatekeeper)...")
try:
    clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
    clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
    print("Da tai xong mo hinh CLIP!")
except Exception as e:
    print(f"Loi khi tai CLIP: {e}")
    clip_model = None
    clip_processor = None

if not loaded_models:
    print("CANH BAO: Chua co mo hinh nao duoc tai. Hay chep cac file .onnx vao thu muc models/")

class_names = []
labels_path = os.path.join(models_path, "labels.txt")
if os.path.exists(labels_path):
    with open(labels_path, "r", encoding="utf-8") as f:
        class_names = [line.strip() for line in f.readlines()]
else:
    print("CANH BAO: Khong tim thay file labels.txt")

def preprocess_image(image_bytes):
    # PyTorch/ImageNet preprocessing standard
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = image.resize((224, 224))
    
    img_array = np.array(image).astype(np.float32) / 255.0
    
    # Normalize with standard mean and std
    mean = np.array([0.485, 0.456, 0.406])
    std = np.array([0.229, 0.224, 0.225])
    img_array = (img_array - mean) / std
    
    # PyTorch expects channel first: (C, H, W)
    img_array = np.transpose(img_array, (2, 0, 1))
    
    # Add batch dimension: (1, C, H, W) and ensure float32
    img_array = np.expand_dims(img_array, axis=0).astype(np.float32)
    return img_array

def softmax(x):
    e_x = np.exp(x - np.max(x, axis=1, keepdims=True))
    return e_x / e_x.sum(axis=1, keepdims=True)

@app.get("/")
def home():
    return {
        "status": "online",
        "message": "AI Engine Microservice đang hoạt động với ONNX!",
        "loaded_models": list(loaded_models.keys())
    }

@app.post("/predict")
async def predict(file: UploadFile = File(...), model_name: str = Form("mobilenetv3_large_100")):
    model_name = model_name.lower()
    
    if model_name not in loaded_models:
        if loaded_models:
            # Fallback to the first available model if the requested one is missing
            model_name = list(loaded_models.keys())[0]
        else:
            raise HTTPException(
                status_code=400, 
                detail="Chưa có mô hình nào được tải lên Server."
            )
        
    try:
        image_bytes = await file.read()
        
        # 1. Kiem tra chat luong anh (Chan anh den xi hoac don sac)
        image_pil = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        img_gray = image_pil.convert("L")
        if np.std(np.array(img_gray)) < 15.0:
            return {
                "model_used": model_name,
                "prediction": "Không hợp lệ",
                "confidence": 0.0,
                "top_3": [],
                "is_valid_plant": False,
                "success": True,
                "message": "Ảnh quá tối hoặc thiếu chi tiết. Vui lòng chụp rõ lại cây!"
            }
            
        # 2. Gatekeeper: CLIP (Chan cho meo, do vat)
        if clip_model and clip_processor:
            inputs = clip_processor(
                text=["a photo of a plant, leaf, tree, or flower", "a photo of an animal, human, or random object"], 
                images=image_pil, return_tensors="pt", padding=True
            )
            outputs = clip_model(**inputs)
            logits_per_image = outputs.logits_per_image  # this is the image-text similarity score
            probs = logits_per_image.softmax(dim=1).detach().numpy()[0]
            
            # Neu xac suat cua "animal, human, or random object" lon hon "plant"
            if probs[1] > 0.5:
                return {
                    "model_used": model_name,
                    "prediction": "Không phải cây",
                    "confidence": 0.0,
                    "top_3": [],
                    "is_valid_plant": False,
                    "success": True,
                    "message": "Hệ thống phát hiện đây không phải là thực vật. Vui lòng chụp ảnh lá cây hoặc cây cảnh!"
                }
            
        # 3. Predict bang mo hinh chinh
        img_array = preprocess_image(image_bytes)
        
        session = loaded_models[model_name]
        input_name = session.get_inputs()[0].name
        
        # Run inference
        outputs = session.run(None, {input_name: img_array})
        logits = outputs[0]
        
        # Apply softmax to get probabilities
        probs = softmax(logits)[0]
        
        # Get top 3 predictions
        top3_idx = np.argsort(probs)[-3:][::-1]
        top3_results = []
        for idx in top3_idx:
            c_name = class_names[idx] if len(class_names) > idx else str(idx)
            conf = float(probs[idx]) * 100
            top3_results.append({"class": c_name, "confidence": round(conf, 2)})
            
        predicted_class = top3_results[0]["class"]
        top_confidence = top3_results[0]["confidence"]
        
        is_plant = top_confidence >= 50.0
        
        return {
            "model_used": model_name,
            "prediction": predicted_class,
            "confidence": top_confidence,
            "top_3": top3_results,
            "is_valid_plant": is_plant,
            "success": True,
            "message": "Thành công" if is_plant else "Vui lòng chụp rõ lại ảnh, hệ thống không nhận diện được loài cây này!"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi khi phân tích ảnh: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
