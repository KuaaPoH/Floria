import os
import time
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torchvision import datasets, transforms, models
import onnx
import onnxruntime as ort
import numpy as np
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DATASET_DIR = BASE_DIR / "dataset"
TRAIN_DIR = DATASET_DIR / "train"
VAL_DIR = DATASET_DIR / "val"
MODELS_DIR = BASE_DIR / "models"
MODELS_DIR.mkdir(parents=True, exist_ok=True)

ONNX_OUTPUT_PATH = MODELS_DIR / "plant_disease_mobilenetv3.onnx"
LABELS_OUTPUT_PATH = MODELS_DIR / "disease_labels.txt"
BEST_PTH_PATH = MODELS_DIR / "best_disease_model.pth"

# Hyperparameters
NUM_CLASSES = 5
BATCH_SIZE = 32
NUM_EPOCHS = 8  # Chay nhanh va hoi tu tot voi Transfer Learning
LEARNING_RATE = 2e-4
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

def get_data_loaders():
    # Data Augmentation & Normalization
    train_transform = transforms.Compose([
        transforms.Resize((240, 240)),
        transforms.RandomResizedCrop(224, scale=(0.8, 1.0)),
        transforms.RandomHorizontalFlip(),
        transforms.RandomRotation(15),
        transforms.ColorJitter(brightness=0.15, contrast=0.15, saturation=0.15),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    val_transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])

    train_dataset = datasets.ImageFolder(TRAIN_DIR, transform=train_transform)
    val_dataset = datasets.ImageFolder(VAL_DIR, transform=val_transform)

    train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True, num_workers=0)
    val_loader = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False, num_workers=0)

    class_names = train_dataset.classes
    print(f"Cac lop nhan dien ({len(class_names)}): {class_names}")
    print(f"So luong anh: Train = {len(train_dataset)}, Val = {len(val_dataset)}")
    
    return train_loader, val_loader, class_names

def build_model(num_classes):
    print("Khoi tao MobileNetV3-Large voi trong so Pre-trained tu ImageNet...")
    weights = models.MobileNet_V3_Large_Weights.DEFAULT
    model = models.mobilenet_v3_large(weights=weights)
    
    # Thay the lop classifier cuoi cung cho 5 nhom benh
    in_features = model.classifier[3].in_features
    model.classifier[3] = nn.Linear(in_features, num_classes)
    
    return model.to(DEVICE)

def train_one_epoch(model, loader, criterion, optimizer):
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0

    for images, labels in loader:
        images, labels = images.to(DEVICE), labels.to(DEVICE)
        
        optimizer.zero_grad()
        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()

        running_loss += loss.item() * images.size(0)
        _, preds = outputs.max(1)
        correct += preds.eq(labels).sum().item()
        total += labels.size(0)

    epoch_loss = running_loss / total
    epoch_acc = (correct / total) * 100
    return epoch_loss, epoch_acc

def evaluate(model, loader, criterion):
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0

    with torch.no_grad():
        for images, labels in loader:
            images, labels = images.to(DEVICE), labels.to(DEVICE)
            outputs = model(images)
            loss = criterion(outputs, labels)

            running_loss += loss.item() * images.size(0)
            _, preds = outputs.max(1)
            correct += preds.eq(labels).sum().item()
            total += labels.size(0)

    val_loss = running_loss / total
    val_acc = (correct / total) * 100
    return val_loss, val_acc

def export_to_onnx(model, onnx_path):
    print(f"\nDang xuat mo hinh sang dinh dang ONNX: {onnx_path}...")
    model.eval()
    model.to("cpu")
    
    dummy_input = torch.randn(1, 3, 224, 224, requires_grad=False)
    
    torch.onnx.export(
        model,
        dummy_input,
        onnx_path,
        export_params=True,
        opset_version=14,
        do_constant_folding=True,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={
            "input": {0: "batch_size"},
            "output": {0: "batch_size"}
        }
    )
    
    # Kiem tra mo hinh ONNX
    onnx_model = onnx.load(str(onnx_path))
    onnx.checker.check_model(onnx_model)
    print("Kiem tra ONNX model hop le 100%!")

    # Test thu nghiem bang ONNXRuntime
    session = ort.InferenceSession(str(onnx_path), providers=["CPUExecutionProvider"])
    ort_inputs = {session.get_inputs()[0].name: dummy_input.numpy()}
    ort_outs = session.run(None, ort_inputs)
    print(f"Chay thu ONNXRuntime thanh cong, output shape: {ort_outs[0].shape}")

def main():
    print(f"=== HUAN LUYEN MO HINH CHAN DOAN BENH LA CAY CANH ===")
    print(f"Thiet bi huan luyen: {DEVICE}")

    train_loader, val_loader, class_names = get_data_loaders()
    
    # Luu file nhan benh
    with open(LABELS_OUTPUT_PATH, "w", encoding="utf-8") as f:
        for c in class_names:
            f.write(f"{c}\n")
    print(f"Da luu nhan benh tai: {LABELS_OUTPUT_PATH}")

    model = build_model(len(class_names))
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(model.parameters(), lr=LEARNING_RATE, weight_decay=1e-2)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=NUM_EPOCHS)

    best_val_acc = 0.0
    start_time = time.time()

    for epoch in range(1, NUM_EPOCHS + 1):
        epoch_start = time.time()
        train_loss, train_acc = train_one_epoch(model, train_loader, criterion, optimizer)
        val_loss, val_acc = evaluate(model, val_loader, criterion)
        scheduler.step()
        
        elapsed = time.time() - epoch_start
        print(f"Epoch [{epoch:02d}/{NUM_EPOCHS:02d}] ({elapsed:.1f}s) - "
              f"Train Loss: {train_loss:.4f}, Train Acc: {train_acc:.2f}% | "
              f"Val Loss: {val_loss:.4f}, Val Acc: {val_acc:.2f}%")

        if val_acc > best_val_acc:
            best_val_acc = val_acc
            torch.save(model.state_dict(), BEST_PTH_PATH)
            print(f"--> [Ky luc moi] Da luu trong so tot nhat (Val Acc: {val_acc:.2f}%)")

    total_time = (time.time() - start_time) / 60
    print(f"\nHuan luyen hoan tat sau {total_time:.2f} phut!")
    print(f"Do chinh xac cao nhat tren tap Validation: {best_val_acc:.2f}%")

    # Load lai model tot nhat de xuat sang ONNX
    model.load_state_dict(torch.load(BEST_PTH_PATH))
    export_to_onnx(model, ONNX_OUTPUT_PATH)
    print("\n=== HOAN TAT TOAN BO TIEN TRINH ===")

if __name__ == "__main__":
    main()
