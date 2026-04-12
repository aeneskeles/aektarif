# TarifUyg - YOLOv8 Model Eğitim Rehberi

Bu rehber, gıda/malzeme tespiti için özel YOLOv8 modeli eğitmenizi sağlar.

## 1. Dataset Hazırlama (Roboflow)

### 1.1 Roboflow Hesabı Oluşturma
1. [Roboflow](https://roboflow.com) sitesine gidin
2. Ücretsiz hesap oluşturun
3. Yeni proje oluşturun: "Object Detection" seçin

### 1.2 Görsel Toplama
- En az 100-500 görsel toplayın (her sınıf için en az 50)
- Farklı açılar, ışıklar ve arka planlar kullanın
- Gerçek mutfak ortamlarından fotoğraflar tercih edin

### 1.3 Etiketleme
1. Görselleri Roboflow'a yükleyin
2. Her görseldeki malzemeleri dikdörtgen ile işaretleyin
3. Tutarlı etiket isimleri kullanın (örn: "tomato", "onion")

### 1.4 Augmentation
Roboflow'da şu augmentation'ları uygulayın:
- Flip: Horizontal
- Rotation: -15° to +15°
- Brightness: -25% to +25%
- Blur: Up to 2.5px
- Noise: Up to 5%

### 1.5 Export
- Format: YOLOv8
- Train/Valid/Test: 70/20/10

---

## 2. Google Colab'da Eğitim

### 2.1 Yeni Notebook Oluşturma
1. [Google Colab](https://colab.research.google.com) açın
2. Yeni notebook oluşturun
3. Runtime > Change runtime type > GPU seçin

### 2.2 Kurulum

```python
# GPU kontrolü
!nvidia-smi

# Kütüphaneleri kur
!pip install ultralytics roboflow -q
```

### 2.3 Dataset İndirme

```python
from roboflow import Roboflow

# API key'inizi Roboflow ayarlarından alın
rf = Roboflow(api_key="YOUR_API_KEY")

# Projenizi indirin
project = rf.workspace("YOUR_WORKSPACE").project("food-ingredients")
dataset = project.version(1).download("yolov8")
```

### 2.4 Model Eğitimi

```python
from ultralytics import YOLO

# Pretrained model yükle (nano - mobil için ideal)
model = YOLO('yolov8n.pt')

# Eğitimi başlat
results = model.train(
    data=f"{dataset.location}/data.yaml",
    epochs=100,
    imgsz=640,
    batch=16,
    patience=20,
    name='food_ingredients',
    # Augmentation
    augment=True,
    hsv_h=0.015,
    hsv_s=0.7,
    hsv_v=0.4,
    degrees=10,
    translate=0.1,
    scale=0.5,
    fliplr=0.5,
    mosaic=1.0,
)
```

### 2.5 Değerlendirme

```python
# Validation
metrics = model.val()
print(f"mAP50: {metrics.box.map50:.4f}")
print(f"mAP50-95: {metrics.box.map:.4f}")

# Test inference
results = model("test_image.jpg")
results[0].show()
```

### 2.6 Export

```python
# En iyi modeli yükle
best_model = YOLO('runs/detect/food_ingredients/weights/best.pt')

# TFLite (mobil için)
best_model.export(format='tflite', imgsz=640)

# ONNX (cross-platform)
best_model.export(format='onnx', imgsz=640, simplify=True)
```

### 2.7 Dosyaları İndir

```python
from google.colab import files

# PyTorch model
files.download('runs/detect/food_ingredients/weights/best.pt')

# TFLite model
files.download('runs/detect/food_ingredients/weights/best_saved_model/best_float32.tflite')
```

---

## 3. Labels Dosyası

`labels.txt` dosyası oluşturun:

```
tomato
onion
garlic
potato
carrot
pepper
eggplant
cucumber
egg
chicken
cheese
milk
rice
pasta
```

---

## 4. Flutter Entegrasyonu

### 4.1 Dosyaları Kopyalama
```
assets/
  models/
    yolov8n_food.tflite  <- best_float32.tflite
    labels.txt
```

### 4.2 pubspec.yaml
```yaml
flutter:
  assets:
    - assets/models/
```

### 4.3 Kullanım
Model zaten `lib/services/ingredient_detector_service.dart` içinde entegre edilmiş durumda.

---

## 5. Cloud API Deployment

### 5.1 Backend Kurulumu
```bash
cd backend
pip install -r requirements.txt
```

### 5.2 Model Yerleştirme
`best.pt` dosyasını `backend/app/` klasörüne kopyalayın.

### 5.3 API Başlatma
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 5.4 Test
```bash
curl -X POST http://localhost:8000/detect \
  -F "image=@test.jpg"
```

---

## 6. Önerilen Sınıflar (Classes)

### Sebzeler
- tomato, onion, garlic, potato, carrot
- pepper, eggplant, zucchini, cucumber
- lettuce, spinach, broccoli, cauliflower
- mushroom, corn, peas

### Meyveler
- apple, banana, orange, lemon, strawberry

### Proteinler
- chicken, beef, lamb, fish, egg

### Süt Ürünleri
- milk, cheese, yogurt, butter

### Tahıllar
- rice, pasta, bread, flour

---

## 7. İpuçları

1. **Veri Kalitesi**: Az ama kaliteli veri, çok ama kalitesiz veriden iyidir
2. **Sınıf Dengesi**: Her sınıfta benzer sayıda örnek olsun
3. **Gerçek Ortam**: Stüdyo değil, gerçek mutfak fotoğrafları kullanın
4. **Iterasyon**: İlk modeli test edin, zayıf sınıflar için daha fazla veri ekleyin
5. **Quantization**: Mobil için INT8 quantization boyutu %75 azaltabilir

---

## Kaynaklar

- [Ultralytics YOLOv8 Docs](https://docs.ultralytics.com/)
- [Roboflow Docs](https://docs.roboflow.com/)
- [TFLite Flutter](https://pub.dev/packages/tflite_flutter)
