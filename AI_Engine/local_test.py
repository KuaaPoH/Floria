import onnxruntime as ort
import numpy as np
from PIL import Image
import os

print("Bat dau test local ONNX inference...")

onnx_path = os.path.join("models", "mobilenetv3_large_100.onnx")
if not os.path.exists(onnx_path):
    print("LOI: Khong tim thay file ONNX tai", onnx_path)
    exit(1)

session = ort.InferenceSession(onnx_path, providers=['CPUExecutionProvider'])
print("ONNX Session load thanh cong!")

# Dummy image 224x224
img_array = np.zeros((1, 3, 224, 224), dtype=np.float32)

input_name = session.get_inputs()[0].name
print("Input name:", input_name)

outputs = session.run(None, {input_name: img_array})
logits = outputs[0]

def softmax(x):
    e_x = np.exp(x - np.max(x, axis=1, keepdims=True))
    return e_x / e_x.sum(axis=1, keepdims=True)

probs = softmax(logits)
predicted_idx = np.argmax(probs[0])
confidence = float(probs[0][predicted_idx])

print("Test Inference thanh cong!")
print(f"Predicted index: {predicted_idx}, Confidence: {confidence:.4f}")
