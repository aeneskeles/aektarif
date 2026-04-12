"""
YOLOv8 .pt modelini TFLite formatına dönüştürür.

Kullanım:
    python convert_model_to_tflite.py --model path/to/best.pt --output assets/models/

Gereksinimler:
    pip install ultralytics
"""

import argparse
from pathlib import Path
from ultralytics import YOLO


def convert_to_tflite(model_path: str, output_dir: str):
    """
    YOLOv8 .pt modelini TFLite'a dönüştürür.
    
    Args:
        model_path: best.pt dosyasının yolu
        output_dir: TFLite dosyasının kaydedileceği klasör
    """
    print(f"Model yükleniyor: {model_path}")
    model = YOLO(model_path)
    
    print(f"Model bilgileri:")
    print(f"  - Sınıf sayısı: {len(model.names)}")
    print(f"  - Sınıflar: {model.names}")
    
    print("\nTFLite'a dönüştürülüyor...")
    output_path = model.export(
        format='tflite',
        imgsz=640,  # Input size
        int8=False,  # Float32 model (daha yavaş ama daha doğru)
        # int8=True,  # Int8 quantized model (daha hızlı ama biraz daha az doğru)
    )
    
    print(f"\n✅ Dönüştürme başarılı!")
    print(f"📁 Dosya: {output_path}")
    
    # Dosyayı hedef klasöre kopyala
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    target_path = output_dir / "yolov8n_food.tflite"
    import shutil
    shutil.copy(output_path, target_path)
    
    print(f"📁 Hedef: {target_path}")
    
    # Labels.txt dosyasını oluştur
    labels_path = output_dir / "labels.txt"
    with open(labels_path, 'w', encoding='utf-8') as f:
        for class_name in model.names.values():
            f.write(f"{class_name}\n")
    
    print(f"📁 Labels: {labels_path}")
    print(f"\n✅ Tamamlandı! Artık uygulamayı çalıştırabilirsin.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="YOLOv8 modelini TFLite'a dönüştür")
    parser.add_argument(
        "--model",
        type=str,
        required=True,
        help="best.pt dosyasının yolu"
    )
    parser.add_argument(
        "--output",
        type=str,
        default="assets/models/",
        help="TFLite dosyasının kaydedileceği klasör (varsayılan: assets/models/)"
    )
    
    args = parser.parse_args()
    
    convert_to_tflite(args.model, args.output)
