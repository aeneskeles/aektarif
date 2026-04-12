# TarifUyg - Malzeme Tabanlı Tarif Öneri & Yemek Paylaşım Uygulaması

<p align="center">
  <img src="docs/logo.png" alt="TarifUyg Logo" width="120"/>
</p>

## 📱 Uygulama Hakkında

TarifUyg, elinizde bulunan malzemelere göre tarif öneren ve kullanıcıların yemeklerini paylaşabildiği bir mobil uygulamadır.

### Temel Özellikler

- 🥕 **Malzeme Yönetimi**: Elle veya kamera ile malzeme ekleme
- 📸 **Akıllı Tespit**: YOLOv8 tabanlı malzeme tespiti (Cloud API)
- 🍳 **Tarif Önerileri**: Malzemelere göre uyum skorlu tarif önerileri
- 📝 **Yemek Paylaşımı**: Yaptığınız yemekleri toplulukla paylaşın
- ❤️ **Sosyal Etkileşim**: Beğeni ve yorum sistemi

## 🏗️ Mimari

```
lib/
├── core/
│   ├── config/          # Uygulama yapılandırmaları
│   ├── models/          # Veri modelleri
│   ├── providers/       # Global Riverpod providers
│   └── theme/           # Tema ve stil
│
├── features/
│   ├── auth/            # Kimlik doğrulama
│   │   ├── data/        # Repository
│   │   └── presentation/
│   │       ├── providers/
│   │       └── screens/
│   │
│   ├── detection/       # ML malzeme tespiti
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── feed/            # Paylaşım akışı
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── home/            # Ana ekran
│   │
│   ├── ingredients/     # Malzeme yönetimi
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── post/            # Paylaşım oluşturma
│   │
│   ├── profile/         # Kullanıcı profili
│   │
│   └── recipes/         # Tarif önerileri
│       ├── data/
│       └── presentation/
│
└── main.dart
```

## 🛠️ Teknoloji Stack

| Kategori | Teknoloji |
|----------|-----------|
| Framework | Flutter 3.10+ |
| State Management | Riverpod |
| Backend | Supabase (Auth, Database, Storage) |
| Local Storage | Hive |
| ML Inference | Cloud API (YOLOv8) / TFLite (opsiyonel) |
| Kamera | camera, image_picker |

## 🚀 Kurulum

### 1. Gereksinimler

- Flutter SDK 3.10+
- Android Studio / VS Code
- Supabase hesabı (opsiyonel, demo modda çalışır)

### 2. Projeyi Klonlama

```bash
git clone <repo-url>
cd tarifuyg
```

### 3. Bağımlılıkları Yükleme

```bash
flutter pub get
```

### 4. Supabase Kurulumu (Opsiyonel)

1. [Supabase](https://supabase.com) hesabı oluşturun
2. Yeni bir proje oluşturun
3. `tools/supabase_schema.sql` dosyasını SQL Editor'de çalıştırın
4. Storage'da bucket oluşturun:
   - `post_images` (public)
   - `avatars` (public)
5. Authentication > Providers > Email'i aktifleştirin

### 5. Uygulamayı Çalıştırma

**Demo Modu (Supabase olmadan):**
```bash
flutter run
```

**Supabase ile:**
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

**ML API ile:**
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=INFERENCE_API_URL=https://your-api.com
```

## 📊 Supabase Schema

### Tablolar

| Tablo | Açıklama |
|-------|----------|
| profiles | Kullanıcı profilleri |
| recipes | Tarifler |
| posts | Paylaşımlar |
| likes | Beğeniler |
| comments | Yorumlar |

### Storage Buckets

| Bucket | Açıklama |
|--------|----------|
| post_images | Paylaşım fotoğrafları |
| avatars | Profil fotoğrafları |

## 🤖 ML Model Eğitimi

### Dataset Hazırlama

1. [Roboflow](https://roboflow.com) hesabı oluşturun
2. Yeni proje oluşturun (Object Detection)
3. Malzeme fotoğraflarını yükleyin ve etiketleyin
4. Augmentation uygulayın
5. YOLOv8 formatında export edin

### Model Eğitimi (Google Colab)

```python
# Ultralytics yükle
!pip install ultralytics

from ultralytics import YOLO

# Model oluştur
model = YOLO('yolov8n.pt')

# Eğit
results = model.train(
    data='path/to/data.yaml',
    epochs=100,
    imgsz=640,
    batch=16,
    name='food_ingredients'
)

# Export
model.export(format='tflite')  # Mobil için
```

### API Deployment

`/detect` endpoint örnek response:

```json
{
  "success": true,
  "detections": [
    {
      "label": "tomato",
      "confidence": 0.95,
      "bbox": {"x1": 100, "y1": 100, "x2": 200, "y2": 200}
    }
  ],
  "processing_time_ms": 150
}
```

## 📱 Ekranlar

| Ekran | Açıklama |
|-------|----------|
| Login/Register | Kullanıcı girişi ve kaydı |
| Feed | Topluluk paylaşımları |
| Inventory | Malzeme listesi yönetimi |
| Camera | Malzeme fotoğrafı çekme |
| Detection Result | Tespit sonuçları düzenleme |
| Recommendations | Tarif önerileri |
| Recipe Detail | Tarif detayı |
| Create Post | Yeni paylaşım oluşturma |
| Profile | Kullanıcı profili |

## 🔜 Sonraki Adımlar

- [ ] TFLite ile cihaz içi inference
- [ ] Yorum sistemi
- [ ] Takip sistemi
- [ ] Keşfet sayfası
- [ ] Tarif API entegrasyonu
- [ ] Push notifications
- [ ] Offline mod

## 📄 Lisans

MIT License

## 🤝 Katkıda Bulunma

Pull request'ler memnuniyetle karşılanır!

---

Made with ❤️ and Flutter
