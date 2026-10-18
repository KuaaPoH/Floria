import os
import shutil
import random
from PIL import Image
from pathlib import Path

# Thiet lap seed ngau nhien de co the tai lap ket qua
random.seed(42)

BASE_DIR = Path(r"d:\Plan\utrasupervip\AI_Engine")
DATASET_DIR = BASE_DIR / "dataset"
TRAIN_DIR = DATASET_DIR / "train"
VAL_DIR = DATASET_DIR / "val"

PLANTDOC_DIR = Path(r"C:\Users\KENN\.cache\kagglehub\datasets\nirmalsankalana\plantdoc-dataset\versions\7")
MANGO_DIR = Path(r"C:\Users\KENN\.cache\kagglehub\datasets\aryashah2k\mango-leaf-disease-dataset\versions\1")

CLASSES = [
    "Healthy",
    "Anthracnose",
    "Leaf_Spot",
    "Bacterial_Blight",
    "Powdery_Mildew"
]

def clean_and_make_dirs():
    if DATASET_DIR.exists():
        print(f"Xoa thu muc cu: {DATASET_DIR}")
        shutil.rmtree(DATASET_DIR)
    
    for split in [TRAIN_DIR, VAL_DIR]:
        for c in CLASSES:
            (split / c).mkdir(parents=True, exist_ok=True)
    print("Da tao xong cau truc thu muc train va val cho 5 nhom benh!")

def get_valid_images(folder_path):
    images = []
    if not folder_path.exists():
        return images
    for root, _, files in os.walk(folder_path):
        for f in files:
            if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
                full_path = Path(root) / f
                images.append(full_path)
    return images

def is_valid_image(img_path):
    try:
        with Image.open(img_path) as img:
            img.verify()
        return True
    except Exception:
        return False

def collect_images():
    collected = {c: [] for c in CLASSES}
    
    # 1. Anthracnose
    mango_anthracnose = MANGO_DIR / "Anthracnose"
    collected["Anthracnose"].extend(get_valid_images(mango_anthracnose))
    
    # 2. Powdery Mildew
    mango_pm = MANGO_DIR / "Powdery Mildew"
    collected["Powdery_Mildew"].extend(get_valid_images(mango_pm))
    for split in ["train", "test"]:
        squash_pm = PLANTDOC_DIR / split / "Squash_Powdery_mildew_leaf"
        collected["Powdery_Mildew"].extend(get_valid_images(squash_pm))
        
    # 3. Healthy
    mango_healthy = MANGO_DIR / "Healthy"
    collected["Healthy"].extend(get_valid_images(mango_healthy))
    healthy_folders = [
        "Apple_leaf", "Bell_pepper_leaf", "Blueberry_leaf", 
        "Cherry_leaf", "grape_leaf", "Peach_leaf", 
        "Raspberry_leaf", "Soyabean_leaf", "Strawberry_leaf", "Tomato_leaf"
    ]
    for split in ["train", "test"]:
        for hf in healthy_folders:
            folder = PLANTDOC_DIR / split / hf
            collected["Healthy"].extend(get_valid_images(folder))
            
    # 4. Leaf Spot
    spot_folders = ["Bell_pepper_leaf_spot", "Corn_Gray_leaf_spot", "Tomato_Septoria_leaf_spot"]
    for split in ["train", "test"]:
        for sf in spot_folders:
            folder = PLANTDOC_DIR / split / sf
            collected["Leaf_Spot"].extend(get_valid_images(folder))
            
    # 5. Bacterial Blight
    blight_folders = [
        "Corn_leaf_blight", "Potato_leaf_early_blight", "Potato_leaf_late_blight",
        "Tomato_Early_blight_leaf", "Tomato_leaf_bacterial_spot", "Tomato_leaf_late_blight"
    ]
    for split in ["train", "test"]:
        for bf in blight_folders:
            folder = PLANTDOC_DIR / split / bf
            collected["Bacterial_Blight"].extend(get_valid_images(folder))
            
    return collected

def distribute_dataset(collected, max_per_class=450, val_ratio=0.2):
    print("\n--- Bat dau tong hop va phan chia Train / Val ---")
    summary = {}
    
    for c in CLASSES:
        all_imgs = collected[c]
        random.shuffle(all_imgs)
        
        # Loc anh hop le
        valid_imgs = []
        for p in all_imgs:
            if is_valid_image(p):
                valid_imgs.append(p)
            if len(valid_imgs) >= max_per_class:
                break
                
        num_val = int(len(valid_imgs) * val_ratio)
        val_imgs = valid_imgs[:num_val]
        train_imgs = valid_imgs[num_val:]
        
        # Copy train
        for idx, src in enumerate(train_imgs):
            dst = TRAIN_DIR / c / f"{c}_train_{idx:04d}{src.suffix.lower()}"
            shutil.copy2(src, dst)
            
        # Copy val
        for idx, src in enumerate(val_imgs):
            dst = VAL_DIR / c / f"{c}_val_{idx:04d}{src.suffix.lower()}"
            shutil.copy2(src, dst)
            
        summary[c] = {"train": len(train_imgs), "val": len(val_imgs), "total": len(valid_imgs)}
        print(f"[{c}]: Total = {len(valid_imgs)} (Train: {len(train_imgs)}, Val: {len(val_imgs)})")
        
    return summary

if __name__ == "__main__":
    clean_and_make_dirs()
    collected = collect_images()
    summary = distribute_dataset(collected, max_per_class=450, val_ratio=0.2)
    print("\nHoan tat tong hop bo du lieu 5 nhom benh cay canh!")
