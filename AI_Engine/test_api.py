import requests
from PIL import Image
import io

# 1. Tạo một ảnh dummy kích thước 224x224 màu xanh lá đại diện cho lá cây
img = Image.new('RGB', (224, 224), color = 'green')
img_byte_arr = io.BytesIO()
img.save(img_byte_arr, format='JPEG')
img_byte_arr = img_byte_arr.getvalue()

# 2. Gửi request POST test với cả 3 mô hình đang chạy trên API
models = ["efficientnetb0", "mobilenetv2", "resnet50v2"]

print("BAT DAU THU NGHIEM API PREDICT:")
for model in models:
    print(f"\n--- Dang test model: {model} ---")
    files = {'file': ('test.jpg', img_byte_arr, 'image/jpeg')}
    data = {'model_name': model}
    
    try:
        response = requests.post("http://localhost:8000/predict", files=files, data=data)
        print("Status Code:", response.status_code)
        if response.status_code == 200:
            print("Response:", response.json())
        else:
            print("Error Detail:", response.text)
    except Exception as e:
        print("Loi ket noi:", e)
