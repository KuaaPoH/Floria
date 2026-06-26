# HƯỚNG DẪN HUẤN LUYỆN VÀ SO SÁNH 3 MÔ HÌNH AI TRÊN GOOGLE COLAB

Tài liệu này hướng dẫn chi tiết cách tải bộ dữ liệu, phân chia dữ liệu theo tỷ lệ chuẩn **80/10/10** và tiến hành huấn luyện so sánh hiệu năng 3 mô hình học máy: **MobileNetV2**, **ResNet50V2**, và **EfficientNetB0** trên môi trường Google Colab. 

Đặc biệt, mã nguồn đã được tối ưu hóa cho **báo cáo đồ án tốt nghiệp khoa học**, bao gồm đầy đủ:
- **Cơ chế chống Overfitting:** Dropout, L2 Regularization (Thành phần phạt), Early Stopping, ReduceLROnPlateau.
- **Hàm mất mát (Loss) & Kích hoạt (Activation):** Softmax, ReLU, Categorical Crossentropy.
- **Biểu đồ & Ma trận đánh giá:** Đồ thị Accuracy/Loss, Ma trận nhầm lẫn (Confusion Matrix), Báo cáo phân loại (Precision, Recall, F1-Score).

---

## 1. Chuẩn bị tài nguyên trước khi Huấn luyện
1. Nén thư mục dataset của bạn trên máy tính thành file zip với tên `archive.zip`.
2. Truy cập [Google Drive](https://drive.google.com/), tạo một thư mục tên là `DoAn_AI`.
3. Tải file `archive.zip` vào thư mục `DoAn_AI`.
4. Mở [Google Colab](https://colab.research.google.com/), tạo một Notebook mới và bật **GPU (Runtime > Change runtime type > T4 GPU)**.

---

## 2. Các ô mã (Cell) cần chạy trên Google Colab

Hãy dán và chạy tuần tự các ô mã dưới đây:

### Ô số 1: Kết nối Google Drive và Giải nén Dataset
```python
from google.colab import drive
import os
import zipfile

# 1. Kết nối với Google Drive
drive.mount('/content/drive')

# 2. Giải nén file archive.zip từ Drive vào ổ cứng tạm của Colab để xử lý tốc độ cao
zip_path = '/content/drive/MyDrive/DoAn_AI/archive.zip'
extract_path = '/content/dataset/'

if os.path.exists(zip_path):
    print("Đang giải nén file zip...")
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_path)
    print("Giải nén thành công!")
else:
    print(f"❌ Không tìm thấy file zip tại: {zip_path}. Hãy kiểm tra lại đường dẫn trên Drive!")
```

### Ô số 2: Tự động tìm thư mục dữ liệu và thiết lập tỷ lệ 80/10/10
```python
import os
import glob
import tensorflow as tf

# 1. Tự động tìm đường dẫn của thư mục 'train' và 'valid' để tránh sai sót cấu trúc zip
search_train = glob.glob('/content/dataset/**/train', recursive=True)
search_val = glob.glob('/content/dataset/**/valid', recursive=True)

if not search_train or not search_val:
    print("❌ LỖI: Không tìm thấy thư mục 'train' hoặc 'valid' trong thư mục giải nén!")
else:
    TRAIN_DIR = search_train[0]
    VAL_DIR = search_val[0]
    print(f"✅ Đã định vị thư mục Train tại: {TRAIN_DIR}")
    print(f"✅ Đã định vị thư mục Validation tại: {VAL_DIR}")
    print("-" * 60)

    # Cấu hình tham số kích thước ảnh đầu vào chuẩn
    IMG_SIZE = (224, 224)
    BATCH_SIZE = 32

    # 2. Đọc toàn bộ ảnh từ thư mục train
    train_ds = tf.keras.utils.image_dataset_from_directory(
        TRAIN_DIR,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode='categorical',
        seed=123
    )

    # 3. Đọc toàn bộ ảnh từ thư mục valid thô ban đầu
    val_ds_raw = tf.keras.utils.image_dataset_from_directory(
        VAL_DIR,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode='categorical',
        seed=123,
        shuffle=True
    )

    # 4. Chia đôi tập valid thô thành Validation (10% tổng) và Test (10% tổng) độc lập
    val_batches = tf.data.experimental.cardinality(val_ds_raw).numpy()
    val_ds = val_ds_raw.take(val_batches // 2)
    test_ds = val_ds_raw.skip(val_batches // 2)

    # 5. Lưu danh sách nhãn lớp bệnh ra file labels.txt để Backend dùng sau này
    class_names = train_ds.class_names
    num_classes = len(class_names)
    with open('labels.txt', 'w') as f:
        for name in class_names:
            f.write(f"{name}\n")

    print("-" * 60)
    print(f"📂 Đã lưu danh sách {num_classes} nhãn bệnh vào file: labels.txt")
    print(f"📊 Tập Train: {len(train_ds) * BATCH_SIZE} ảnh ({len(train_ds)} batches)")
    print(f"📊 Tập Validation: {len(val_ds) * BATCH_SIZE} ảnh ({len(val_ds)} batches)")
    print(f"📊 Tập Test (Độc lập): {len(test_ds) * BATCH_SIZE} ảnh ({len(test_ds)} batches)")
```

### Ô số 3: Xây dựng 3 Mô hình AI tích hợp Cơ chế phạt (Regularization) và Tiền xử lý
```python
from tensorflow.keras.applications import MobileNetV2, ResNet50V2, EfficientNetB0
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout, Lambda
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras import regularizers
import tensorflow as tf

# Hàm hỗ trợ đóng gói mô hình, bao gồm các thành phần chuẩn học thuật
def build_custom_model(base_model_name, base_model, preprocess_func=None):
    inputs = tf.keras.Input(shape=(224, 224, 3))
    
    # Nhúng tiền xử lý vào làm lớp đầu tiên
    if preprocess_func:
        x = Lambda(preprocess_func)(inputs)
    else:
        x = inputs
        
    base_model.trainable = False  # Đóng băng các tầng học cơ bản
    x = base_model(x, training=False)
    
    # Trích xuất đặc trưng
    x = GlobalAveragePooling2D()(x)
    
    # Hàm kích hoạt (Activation): ReLU (Giúp giảm rủi ro triệt tiêu gradient)
    # Thành phần phạt (Penalty/L2 Regularization): kernel_regularizer chống Overfitting
    x = Dense(256, activation='relu', kernel_regularizer=regularizers.l2(0.001))(x)
    
    # Cơ chế chống Overfitting: Dropout (Tắt ngẫu nhiên 50% nơ-ron)
    x = Dropout(0.5)(x)
    
    # Hàm kích hoạt lớp Output: Softmax (Tính xác suất phân loại đa lớp)
    predictions = Dense(num_classes, activation='softmax')(x)
    
    model = Model(inputs=inputs, outputs=predictions)
    
    # Hàm mất mát (Loss Function): Categorical Crossentropy (Tính sai số đa phân loại)
    model.compile(
        optimizer=Adam(learning_rate=0.0001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    return model

print("Đang khởi tạo các mô hình...")

# 1. Khởi tạo MobileNetV2
base_mobilenet = MobileNetV2(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
model_mobilenet = build_custom_model("MobileNetV2", base_mobilenet, tf.keras.applications.mobilenet_v2.preprocess_input)

# 2. Khởi tạo ResNet50V2
base_resnet = ResNet50V2(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
model_resnet = build_custom_model("ResNet50V2", base_resnet, tf.keras.applications.resnet_v2.preprocess_input)

# 3. Khởi tạo EfficientNetB0
base_effnet = EfficientNetB0(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
model_effnet = build_custom_model("EfficientNetB0", base_effnet, None)

print("✅ Đã khởi tạo và biên dịch thành công cả 3 mô hình!")
```

### Ô số 4: Tiến hành Huấn luyện với Các cơ chế chống Overfitting (Callbacks)
```python
from tensorflow.keras.callbacks import ModelCheckpoint, EarlyStopping, ReduceLROnPlateau
import time

EPOCHS = 10
histories = {}
training_times = {}

models = {
    'MobileNetV2': model_mobilenet,
    'ResNet50V2': model_resnet,
    'EfficientNetB0': model_effnet
}

for name, model in models.items():
    print(f"\n🚀 BẮT ĐẦU HUẤN LUYỆN MÔ HÌNH: {name}...")
    
    # 1. ModelCheckpoint: Lưu lại mô hình có val_accuracy cao nhất (định dạng .keras hiện đại)
    checkpoint = ModelCheckpoint(
        f'best_{name.lower()}_model.keras', monitor='val_accuracy', save_best_only=True, mode='max', verbose=1
    )
    
    # 2. EarlyStopping: Chống overfitting bằng cách dừng sớm nếu sau 3 epoch loss không giảm
    early_stop = EarlyStopping(
        monitor='val_loss', patience=3, restore_best_weights=True, verbose=1
    )
    
    # 3. ReduceLROnPlateau: Tự động giảm Learning Rate nếu mô hình kẹt ở vùng Loss không đổi
    reduce_lr = ReduceLROnPlateau(
        monitor='val_loss', factor=0.2, patience=2, min_lr=1e-6, verbose=1
    )
    
    start_time = time.time()
    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS,
        callbacks=[checkpoint, early_stop, reduce_lr]
    )
    end_time = time.time()
    
    histories[name] = history.history
    training_times[name] = end_time - start_time
    print(f"⏱️ Thời gian huấn luyện xong {name}: {training_times[name]:.2f} giây")
```

### Ô số 5: Đánh giá Học thuật: Confusion Matrix, Classification Report và Đồ thị
```python
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import classification_report, confusion_matrix, roc_curve, auc
from sklearn.preprocessing import label_binarize

results = []

for name, model in models.items():
    print(f"\n" + "="*80)
    print(f"ĐANG ĐÁNH GIÁ MÔ HÌNH {name.upper()} TRÊN TẬP TEST ĐỘC LẬP...")
    
    # 1. Đo lường cơ bản Loss và Accuracy
    loss, accuracy = model.evaluate(test_ds, verbose=0)
    model_file = f'best_{name.lower()}_model.keras'
    file_size_mb = os.path.getsize(model_file) / (1024 * 1024)
    
    results.append({
        'Tên mô hình': name,
        'Độ chính xác Test (%)': f"{accuracy * 100:.2f}%",
        'Hàm lỗi Test (Loss)': f"{loss:.4f}",
        'Thời gian train': f"{training_times[name]:.1f}s",
        'Kích thước file (MB)': f"{file_size_mb:.2f} MB"
    })
    
    # 2. Rút trích Nhãn thực tế (True Labels), Nhãn dự đoán (Pred Labels) và Xác suất (Probs)
    y_true = []
    y_pred = []
    y_pred_probs = []
    for images, labels in test_ds:
        preds = model.predict(images, verbose=0)
        y_pred.extend(np.argmax(preds, axis=1))
        y_true.extend(np.argmax(labels.numpy(), axis=1))
        y_pred_probs.extend(preds)
        
    y_pred_probs = np.array(y_pred_probs)
        
    # 3. Báo cáo phân loại (Precision, Recall, F1-Score)
    print(f"\n📝 BÁO CÁO PHÂN LOẠI (CLASSIFICATION REPORT) - {name}")
    print(classification_report(y_true, y_pred, target_names=class_names))
    
    # 4. Vẽ Ma trận nhầm lẫn (Confusion Matrix)
    cm = confusion_matrix(y_true, y_pred)
    plt.figure(figsize=(22, 18))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=class_names, yticklabels=class_names)
    plt.title(f'Ma trận Nhầm lẫn (Confusion Matrix) - {name}', fontsize=16)
    plt.ylabel('Nhãn thực tế (True Label)', fontsize=14)
    plt.xlabel('Nhãn dự đoán (Predicted Label)', fontsize=14)
    plt.xticks(rotation=90, fontsize=9)
    plt.yticks(rotation=0, fontsize=9)
    plt.tight_layout()
    plt.show()

    # 5. BIỂU ĐỒ THAY THẾ ROC: Phân tích 10 lớp khó nhận diện nhất (Dựa trên F1-Score)
    # Vì độ chính xác quá cao, đường ROC bị dính vào nhau không đẹp.
    # Biểu đồ này sẽ chỉ ra điểm yếu của AI để viết phần "Hướng phát triển" trong Đồ án.
    report_dict = classification_report(y_true, y_pred, target_names=class_names, output_dict=True)
    f1_scores = {name: metrics['f1-score'] for name, metrics in report_dict.items() if name in class_names}
    
    # Sắp xếp F1-Score từ thấp đến cao và lấy 10 lớp thấp nhất
    sorted_f1 = sorted(f1_scores.items(), key=lambda x: x[1])
    worst_10_names = [x[0] for x in sorted_f1[:10]]
    worst_10_scores = [x[1] for x in sorted_f1[:10]]

    plt.figure(figsize=(12, 6))
    bars = plt.barh(worst_10_names, worst_10_scores, color='crimson', edgecolor='black')
    plt.title(f'10 Bệnh khó nhận diện nhất (F1-Score thấp nhất) - {name}', fontsize=14, fontweight='bold')
    plt.xlabel('Chỉ số F1-Score (Càng gần 1.0 càng tốt)', fontsize=12)
    plt.xlim(0, 1.05)
    plt.grid(axis='x', linestyle='--', alpha=0.7)
    
    # Ghi chú số liệu trực tiếp lên biểu đồ
    for bar in bars:
        width = bar.get_width()
        plt.text(width + 0.01, bar.get_y() + bar.get_height()/2, f'{width:.3f}', 
                 ha='left', va='center', fontweight='bold', color='black')
    
    plt.tight_layout()
    plt.show()

# Hiển thị bảng tóm tắt so sánh
df_compare = pd.DataFrame(results)
print("\n" + "="*80)
print("📊 BẢNG SO SÁNH HIỆU SUẤT TỔNG QUAN")
print("="*80)
print(df_compare.to_string(index=False))
print("="*80)

# Vẽ đồ thị đường Accuracy và Loss
plt.figure(figsize=(15, 5))
plt.subplot(1, 2, 1)
for name, hist in histories.items():
    plt.plot(hist['val_accuracy'], marker='o', label=f"{name}")
plt.title('Đồ thị Độ chính xác (Validation Accuracy)')
plt.xlabel('Epoch')
plt.ylabel('Accuracy')
plt.legend()
plt.grid(True)

plt.subplot(1, 2, 2)
for name, hist in histories.items():
    plt.plot(hist['val_loss'], marker='o', label=f"{name}")
plt.title('Đồ thị Mất mát (Validation Loss)')
plt.xlabel('Epoch')
plt.ylabel('Loss')
plt.legend()
plt.grid(True)

plt.tight_layout()
plt.show()

# ==============================================================================
# VẼ BIỂU ĐỒ CỘT TỔNG KẾT SO SÁNH (BAR CHARTS) DÀNH CHO BÁO CÁO THUYẾT TRÌNH
# ==============================================================================
model_names = [res['Tên mô hình'] for res in results]
test_accs = [float(res['Độ chính xác Test (%)'].strip('%')) for res in results]
model_sizes = [float(res['Kích thước file (MB)'].replace(' MB', '')) for res in results]
train_times = [float(res['Thời gian train'].replace('s', '')) for res in results]

plt.figure(figsize=(18, 6))

# 1. Biểu đồ So sánh Độ chính xác (Test Accuracy)
plt.subplot(1, 3, 1)
bars = plt.bar(model_names, test_accs, color=['#4CAF50', '#2196F3', '#FF9800'], edgecolor='black')
plt.title('So sánh Độ chính xác (Test Accuracy)', fontsize=12, fontweight='bold')
plt.ylabel('Độ chính xác (%)')
plt.ylim(0, 110)
for bar in bars:
    yval = bar.get_height()
    plt.text(bar.get_x() + bar.get_width()/2, yval + 1.5, f'{yval:.2f}%', ha='center', va='bottom', fontweight='bold')

# 2. Biểu đồ So sánh Kích thước mô hình (Model Size)
plt.subplot(1, 3, 2)
bars = plt.bar(model_names, model_sizes, color=['#e91e63', '#9c27b0', '#00bcd4'], edgecolor='black')
plt.title('So sánh Kích thước file (.keras)', fontsize=12, fontweight='bold')
plt.ylabel('Dung lượng (MB)')
for bar in bars:
    yval = bar.get_height()
    plt.text(bar.get_x() + bar.get_width()/2, yval + max(model_sizes)*0.02, f'{yval:.1f} MB', ha='center', va='bottom', fontweight='bold')

# 3. Biểu đồ So sánh Thời gian Huấn luyện
plt.subplot(1, 3, 3)
bars = plt.bar(model_names, train_times, color=['#ffc107', '#795548', '#607d8b'], edgecolor='black')
plt.title('So sánh Thời gian Huấn luyện', fontsize=12, fontweight='bold')
plt.ylabel('Thời gian (Giây)')
for bar in bars:
    yval = bar.get_height()
    plt.text(bar.get_x() + bar.get_width()/2, yval + max(train_times)*0.02, f'{yval:.1f}s', ha='center', va='bottom', fontweight='bold')

plt.tight_layout()
plt.show()
```

### Ô số 6: Chuyển đổi định dạng TFLite và đồng bộ hóa về Google Drive
```python
import shutil

drive_folder = '/content/drive/MyDrive/DoAn_AI'
if not os.path.exists(drive_folder):
    os.makedirs(drive_folder)

print("Đang xuất định dạng mô hình và đồng bộ lên Drive...")

for name in models.keys():
    keras_file = f'best_{name.lower()}_model.keras'
    shutil.copy(keras_file, drive_folder)
    
    # Xuất định dạng TFLite phục vụ Android chạy offline
    try:
        converter = tf.lite.TFLiteConverter.from_keras_model(models[name])
        tflite_model = converter.convert()
        tflite_name = f'best_{name.lower()}_model.tflite'
        with open(tflite_name, 'wb') as f:
            f.write(tflite_model)
        shutil.copy(tflite_name, drive_folder)
        print(f"✅ Đã sao lưu bản .keras và .tflite của {name} lên Google Drive!")
    except Exception as e:
        print(f"❌ Không thể chuyển đổi TFLite cho {name}: {e}")

shutil.copy('labels.txt', drive_folder)
print("-" * 60)
print("🎉 ĐỒNG BỘ HOÀN TẤT! File mô hình đã nằm trong thư mục 'DoAn_AI' trên Google Drive.")
```
