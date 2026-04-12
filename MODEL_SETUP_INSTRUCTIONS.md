# YOLOv8 Model Kurulum Talimatları

## Şu Anki Durum
✅ Kod hazır (mock detection aktif)
⚠️ Model dosyası bekleniyor

---

## Adım 1: Ultralytics Yükle

```powershell
pip install ultralytics
```

---

## Adım 2: best.pt Modelini Dönüştür

`best.pt` dosyanın nerede olduğunu belirle ve şu komutu çalıştır:

```powershell
python tools/convert_model_to_tflite.py --model "C:/path/to/your/best.pt" --output "assets/models/"
```

**Örnekler:**

```powershell
# Masaüstünde:
python tools/convert_model_to_tflite.py --model "C:/Users/ahmet/Desktop/best.pt" --output "assets/models/"

# İndirilenler klasöründe:
python tools/convert_model_to_tflite.py --model "C:/Users/ahmet/Downloads/best.pt" --output "assets/models/"

# Proje klasöründe:
python tools/convert_model_to_tflite.py --model "best.pt" --output "assets/models/"
```

Script şunları yapacak:
1. ✅ `best.pt` modelini TFLite'a dönüştürür
2. ✅ `assets/models/yolov8n_food.tflite` olarak kaydeder
3. ✅ `assets/models/labels.txt` dosyasını oluşturur (model sınıflarıyla)

---

## Adım 3: Mock Detection'ı Kapat

Model dosyası hazır olunca, `lib/services/ingredient_detector_service.dart` dosyasında:

1. `detectIngredients()` metodundaki **mock kodu sil**:
```dart
// TODO: Remove this mock implementation when model file is ready
// MOCK DETECTION FOR TESTING
await Future.delayed(const Duration(seconds: 2));

return [
  DetectedIngredient(...),
  ...
];
```

2. **Gerçek kodu aktif et** (comment'leri kaldır):
```dart
/* REAL IMPLEMENTATION - Uncomment when model file is ready
...
*/
```

Şöyle olmalı:
```dart
Future<List<DetectedIngredient>> detectIngredients(File imageFile) async {
  if (!_isInitialized) {
    await initialize();
  }

  // Read and preprocess image
  final imageBytes = await imageFile.readAsBytes();
  final image = img.decodeImage(imageBytes);
  if (image == null) {
    throw Exception('Failed to decode image');
  }

  // ... (rest of the real implementation)
}
```

---

## Adım 4: Test Et

```powershell
flutter run --dart-define=SUPABASE_URL="https://zfoksgtwuoplsiydiimx.supabase.co" --dart-define=SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpmb2tzZ3R3dW9wbHNpeWRpaW14Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1OTQzOTEsImV4cCI6MjA4NDE3MDM5MX0.QIpb1vGoGZU3BiBoEL1vN9Fe898_pmZUYsf0pXfpll4"
```

Test adımları:
1. **Ekle** sekmesine git
2. **"Kamera ile Malzeme Ekle"** butonuna tıkla
3. Malzeme fotoğrafı çek
4. Tespit edilen malzemeleri kontrol et
5. Seçilenleri envantere ekle
6. **Öneri** sekmesinde tarifleri gör

---

## Sorun Giderme

### Model yüklenmiyor
```
Error: Failed to initialize ingredient detector: ...
```

**Çözüm:**
- `assets/models/yolov8n_food.tflite` dosyası var mı kontrol et
- `flutter clean && flutter pub get` çalıştır
- Uygulamayı yeniden başlat

### Tespit çalışmıyor
```
Hiç malzeme tespit edilemedi
```

**Çözüm:**
- Confidence threshold'u düşür (0.5 → 0.3):
```dart
static const double confidenceThreshold = 0.3;
```
- Daha iyi ışıklandırma ile fotoğraf çek
- Model eğitiminde kullanılan sınıfları kontrol et

### Yavaş çalışıyor
**Çözüm:**
- Int8 quantized model kullan (dönüştürme sırasında `int8=True`)
- Input size'ı küçült (640 → 416)
- GPU delegate ekle (Android)

---

## Hızlı Başlangıç (Özet)

```powershell
# 1. Model dönüştür
python tools/convert_model_to_tflite.py --model "path/to/best.pt" --output "assets/models/"

# 2. Mock kodu kaldır (ingredient_detector_service.dart)

# 3. Test et
flutter run --dart-define=SUPABASE_URL="..." --dart-define=SUPABASE_ANON_KEY="..."
```

---

**Hazırlayan:** Cascade AI
**Tarih:** 17 Ocak 2026
