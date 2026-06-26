import requests
from PIL import Image
import io

# 1. Tạo một ảnh dummy 224x224 màu xanh lá
img = Image.new('RGB', (224, 224), color = 'green')
img_byte_arr = io.BytesIO()
img.save(img_byte_arr, format='JPEG')
img_byte_arr = img_byte_arr.getvalue()

# 2. Gửi request POST test tới Spring Boot Backend cổng 8080
models = ["efficientnetb0", "mobilenetv2", "resnet50v2"]

print("BAT DAU THU NGHIEM TICH HOP (INTEGRATION TEST) QUA SPRING BOOT BACKEND:")
for model in models:
    print(f"\n--- Gui anh scan voi model: {model} ---")
    files = {'file': ('test.jpg', img_byte_arr, 'image/jpeg')}
    # Gửi model name qua request param
    url = f"http://localhost:8080/api/scan-disease?model={model}"
    
    try:
        response = requests.post(url, files=files)
        print("Spring Boot Status Code:", response.status_code)
        if response.status_code == 200:
            print("Response JSON:", response.json())
        else:
            print("Response Error:", response.text)
    except Exception as e:
        print("Loi ket noi Backend:", e)
