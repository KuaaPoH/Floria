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
class_names = []
disease_class_names = []

print("Dang khoi dong AI Engine va tai cac mo hinh ONNX...")
# 1. Tai mo hinh loai cay (Uu tien quan quan tf_efficientnetv2_b0)
plant_models_priority = ["tf_efficientnetv2_b0", "mobilenetv3_large_100"]
for p_name in plant_models_priority:
    p_path = os.path.join(models_path, f"{p_name}.onnx")
    if os.path.exists(p_path):
        try:
            loaded_models[p_name] = ort.InferenceSession(p_path, providers=['CPUExecutionProvider'])
            print(f"-> Da tai thanh cong: {p_name} (ONNX - Nhan dien 40 loai cay)")
        except Exception as e:
            print(f"Loi khi tai {p_name}: {e}")

# 2. Tai mo hinh benh cay (Uu tien tf_efficientnetv2_b0_disease)
disease_models_priority = ["tf_efficientnetv2_b0_disease", "plant_disease_mobilenetv3"]
for d_name in disease_models_priority:
    d_path = os.path.join(models_path, f"{d_name}.onnx")
    if os.path.exists(d_path):
        try:
            loaded_models[d_name] = ort.InferenceSession(d_path, providers=['CPUExecutionProvider'])
            print(f"-> Da tai thanh cong: {d_name} (ONNX - Chan doan 5 nhom benh)")
        except Exception as e:
            print(f"Loi khi tai {d_name}: {e}")

labels_path = os.path.join(models_path, "labels.txt")
if os.path.exists(labels_path):
    with open(labels_path, "r", encoding="utf-8") as f:
        class_names = [line.strip() for line in f.readlines()]

disease_labels_path = os.path.join(models_path, "disease_labels.txt")
if os.path.exists(disease_labels_path):
    with open(disease_labels_path, "r", encoding="utf-8") as f:
        disease_class_names = [line.strip() for line in f.readlines()]
else:
    disease_class_names = ["Anthracnose", "Bacterial_Blight", "Healthy", "Leaf_Spot", "Powdery_Mildew"]

print("Dang tai mo hinh kiem duyet CLIP (Gatekeeper)...")
cached_text_features = None
try:
    clip_model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
    clip_processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
    clip_model.eval()
    
    # Ma hoa san (cache) dac trung van ban 1 lan duy nhat khi khoi dong
    clip_prompts = ["a photo of a plant, leaf, tree, or flower", "a photo of an animal, human, or random object"]
    text_inputs = clip_processor(text=clip_prompts, return_tensors="pt", padding=True)
    with torch.inference_mode():
        t_out = clip_model.get_text_features(**text_inputs)
        text_features = t_out.pooler_output if hasattr(t_out, "pooler_output") else t_out
        cached_text_features = text_features / text_features.norm(dim=-1, keepdim=True)
    print("Da tai xong mo hinh CLIP va ma hoa san (cache) dac trung van ban!")
except Exception as e:
    print(f"Loi khi tai CLIP: {e}")
    clip_model = None
    clip_processor = None

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
async def predict(file: UploadFile = File(...), model_name: str = Form("tf_efficientnetv2_b0")):
    model_name = model_name.lower()
    
    if model_name not in loaded_models:
        if "tf_efficientnetv2_b0" in loaded_models:
            model_name = "tf_efficientnetv2_b0"
        elif loaded_models:
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
            
        # 2. Gatekeeper: CLIP (Chan cho meo, do vat) - Toi uu hoa sieu toc voi cached text features
        if clip_model and clip_processor and cached_text_features is not None:
            with torch.inference_mode():
                image_inputs = clip_processor(images=image_pil, return_tensors="pt")
                i_out = clip_model.get_image_features(**image_inputs)
                image_features = i_out.pooler_output if hasattr(i_out, "pooler_output") else i_out
                image_features = image_features / image_features.norm(dim=-1, keepdim=True)
                
                # So sanh do tuong dong cosine giua anh va dac trung van ban da cache san
                logit_scale = clip_model.logit_scale.exp()
                logits = logit_scale * (image_features @ cached_text_features.T)
                probs = logits.softmax(dim=-1).cpu().numpy()[0]
            
            # Neu xac suat cua "animal, human, or random object" (index 1) lon hon "plant" (index 0)
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
        
        # Neu do tin cay >= 50%: thuoc 40 loai trong CSDL
        # Neu < 50%: CLIP da xac nhan day la cay, nhung loai cay nay nam ngoai 40 loai CSDL
        is_in_database = top_confidence >= 50.0
        
        return {
            "model_used": model_name,
            "prediction": predicted_class,
            "confidence": top_confidence,
            "top_3": top3_results,
            "is_valid_plant": True,
            "is_in_database": is_in_database,
            "success": True,
            "message": "Thành công" if is_in_database else "Phát hiện thực vật nằm ngoài danh mục 40 cây của hệ thống."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi khi phân tích ảnh: {str(e)}")

DISEASE_META = {
    "Healthy": {
        "name_vi": "Lá Khỏe Mạnh",
        "severity": "Bình thường",
        "cause": "Cây phát triển tốt, không phát hiện dấu hiệu mầm bệnh nguy hiểm.",
        "treatment": [
            "Duy trì chế độ tưới nước và ánh sáng phù hợp định kỳ.",
            "Lau bụi trên mặt lá 1-2 lần/tháng để cây quang hợp tối ưu.",
            "Bón phân vi lượng hữu cơ định kỳ theo mùa vụ."
        ]
    },
    "Anthracnose": {
        "name_vi": "Bệnh Thán Thư",
        "severity": "Nguy hiểm",
        "cause": "Do nấm Colletotrichum gây ra, lây lan mạnh khi độ ẩm cao hoặc tưới nước đọng lại trên lá vào ban đêm.",
        "treatment": [
            "Cách ly chậu cây bệnh khỏi các cây khác trong vườn.",
            "Dùng kéo đã khử trùng cắt bỏ các lá có đốm nâu hoại tử, tiêu hủy xa khu vườn.",
            "Phun thuốc trừ nấm gốc đồng (Coc85, Booc-đô) hoặc Antracol 70WP 2 lần cách nhau 5 ngày.",
            "Ngưng tưới phun sương lên lá, chỉ tưới nhẹ vào gốc vào buổi sáng."
        ]
    },
    "Leaf_Spot": {
        "name_vi": "Bệnh Đốm Lá Nấm",
        "severity": "Cảnh báo",
        "cause": "Do nấm Cercospora hoặc Alternaria gây ra. Lá xuất hiện các đốm nâu/vàng mắt cua rải rác.",
        "treatment": [
            "Cắt tỉa các lá bị đốm nặng để hạn chế bào tử nấm phát tán.",
            "Tăng cường độ thông thoáng và ánh sáng tán xạ cho cây.",
            "Sử dụng chế phẩm sinh học Nano Bạc hoặc thuốc Daconil / Ridomil Gold phun đều 2 mặt lá."
        ]
    },
    "Bacterial_Blight": {
        "name_vi": "Cháy Bìa Lá Vi Khuẩn",
        "severity": "Nguy hiểm",
        "cause": "Do vi khuẩn Xanthomonas hoặc Erwinia xâm nhập qua khí khổng hoặc vết thương hở khi giá thể quá ẩm.",
        "treatment": [
            "Lập tức ngừng tưới nước 2-3 ngày, để giá thể khô ráo.",
            "Cắt bỏ phần mép lá bị cháy sũng nước, bôi keo liền sẹo hoặc vôi bột vào vết cắt.",
            "Phun Kasumin 2SL hoặc Starner 20WP đặc trị vi khuẩn."
        ]
    },
    "Powdery_Mildew": {
        "name_vi": "Bệnh Phấn Trắng",
        "severity": "Cảnh báo",
        "cause": "Do nấm Erysiphales phát triển tạo lớp màng phấn trắng xóa cản trở quang hợp.",
        "treatment": [
            "Dùng khăn ẩm lau nhẹ bề mặt lá để giảm bớt lớp phấn nấm.",
            "Đưa cây ra vị trí có ánh nắng buổi sáng và thoáng gió hơn.",
            "Phun dung dịch baking soda pha loãng (5g/1 lít nước) hoặc thuốc Anvil 5SC."
        ]
    }
}

@app.post("/predict-disease")
async def predict_disease(file: UploadFile = File(...)):
    model_name = "tf_efficientnetv2_b0_disease"
    
    if model_name not in loaded_models:
        # Tim xem co model benh nao khac duoc nap khong
        disease_candidates = [m for m in loaded_models if "disease" in m]
        if disease_candidates:
            model_name = disease_candidates[0]
            
    if model_name not in loaded_models:
        raise HTTPException(
            status_code=500,
            detail="Không tìm thấy mô hình chẩn đoán bệnh tf_efficientnetv2_b0_disease.onnx trên máy chủ AI Engine."
        )

    try:
        image_bytes = await file.read()
        
        # 1. Kiem tra do sang va do tuong phan
        image_pil = Image.open(io.BytesIO(image_bytes)).convert("RGB")
        img_gray = image_pil.convert("L")
        if np.std(np.array(img_gray)) < 15.0:
            return {
                "prediction": "Không hợp lệ",
                "prediction_vi": "Không hợp lệ",
                "confidence": 0.0,
                "top_3": [],
                "is_valid_plant": False,
                "success": False,
                "message": "Ảnh quá tối hoặc thiếu chi tiết. Vui lòng chụp rõ lại phiến lá!"
            }

        # 2. Gatekeeper CLIP
        if clip_model and clip_processor and cached_text_features is not None:
            with torch.inference_mode():
                image_inputs = clip_processor(images=image_pil, return_tensors="pt")
                i_out = clip_model.get_image_features(**image_inputs)
                image_features = i_out.pooler_output if hasattr(i_out, "pooler_output") else i_out
                image_features = image_features / image_features.norm(dim=-1, keepdim=True)
                
                logit_scale = clip_model.logit_scale.exp()
                logits = logit_scale * (image_features @ cached_text_features.T)
                probs = logits.softmax(dim=-1).cpu().numpy()[0]
            
            if probs[1] > 0.5:
                return {
                    "prediction": "Không phải cây",
                    "prediction_vi": "Không phải cây",
                    "confidence": 0.0,
                    "top_3": [],
                    "is_valid_plant": False,
                    "success": False,
                    "message": "Hệ thống phát hiện đây không phải thực vật. Hãy chụp cận cảnh lá cây bị bệnh!"
                }

        # 3. Predict bang mo hinh benh ONNX
        img_array = preprocess_image(image_bytes)
        session = loaded_models[model_name]
        input_name = session.get_inputs()[0].name
        
        outputs = session.run(None, {input_name: img_array})
        logits = outputs[0]
        probs = softmax(logits)[0]
        
        top3_idx = np.argsort(probs)[-3:][::-1]
        top3_results = []
        for idx in top3_idx:
            c_name = disease_class_names[idx] if len(disease_class_names) > idx else str(idx)
            conf = float(probs[idx]) * 100
            name_vi = DISEASE_META.get(c_name, {}).get("name_vi", c_name)
            top3_results.append({
                "class": c_name,
                "name_vi": name_vi,
                "confidence": round(conf, 2)
            })
            
        pred_class = top3_results[0]["class"]
        pred_conf = top3_results[0]["confidence"]
        meta = DISEASE_META.get(pred_class, {
            "name_vi": pred_class,
            "severity": "Cảnh báo",
            "cause": "Đang cập nhật thông tin mầm bệnh...",
            "treatment": ["Cách ly cây", "Tham khảo ý kiến chuyên gia"]
        })
        
        return {
            "model_used": model_name,
            "prediction": pred_class,
            "prediction_vi": meta["name_vi"],
            "confidence": pred_conf,
            "top_3": top3_results,
            "severity": meta["severity"],
            "severity_vi": meta["severity"],
            "cause": meta["cause"],
            "treatment_steps": meta["treatment"],
            "is_valid_plant": True,
            "success": True,
            "message": "Chẩn đoán bệnh thành công"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Lỗi chẩn đoán bệnh: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

