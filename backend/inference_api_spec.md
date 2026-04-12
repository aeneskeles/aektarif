# TarifUyg - Malzeme Tespiti API Sözleşmesi

## Base URL
```
https://your-api-domain.com/api/v1
```

## Endpoints

### POST /detect

Gönderilen fotoğraftaki malzemeleri tespit eder.

#### Request

**Headers:**
```
Content-Type: multipart/form-data
Authorization: Bearer <api_key> (opsiyonel)
```

**Body (multipart/form-data):**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| image | file | Yes | JPEG/PNG formatında görsel (max 10MB) |
| confidence_threshold | float | No | Min güven skoru (default: 0.5) |
| max_detections | int | No | Max tespit sayısı (default: 20) |

#### Response

**Success (200):**
```json
{
  "success": true,
  "detections": [
    {
      "label": "tomato",
      "label_tr": "Domates",
      "confidence": 0.95,
      "bbox": {
        "x1": 100,
        "y1": 100,
        "x2": 200,
        "y2": 200
      }
    },
    {
      "label": "onion",
      "label_tr": "Soğan",
      "confidence": 0.88,
      "bbox": {
        "x1": 250,
        "y1": 150,
        "x2": 350,
        "y2": 250
      }
    }
  ],
  "image_size": {
    "width": 1920,
    "height": 1080
  },
  "processing_time_ms": 150,
  "model_version": "1.0.0"
}
```

**Error (4xx/5xx):**
```json
{
  "success": false,
  "error": {
    "code": "INVALID_IMAGE",
    "message": "Görsel formatı desteklenmiyor"
  }
}
```

#### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| INVALID_IMAGE | 400 | Geçersiz görsel formatı |
| IMAGE_TOO_LARGE | 400 | Görsel boyutu çok büyük |
| NO_IMAGE | 400 | Görsel gönderilmedi |
| PROCESSING_ERROR | 500 | İşleme hatası |
| MODEL_ERROR | 500 | Model yükleme hatası |

---

## Desteklenen Malzeme Etiketleri

### Sebzeler
- tomato (Domates)
- onion (Soğan)
- garlic (Sarımsak)
- potato (Patates)
- carrot (Havuç)
- pepper (Biber)
- eggplant (Patlıcan)
- zucchini (Kabak)
- cucumber (Salatalık)
- lettuce (Marul)
- spinach (Ispanak)
- broccoli (Brokoli)
- cauliflower (Karnabahar)
- cabbage (Lahana)
- mushroom (Mantar)
- corn (Mısır)
- peas (Bezelye)
- green_beans (Yeşil Fasulye)

### Meyveler
- apple (Elma)
- banana (Muz)
- orange (Portakal)
- lemon (Limon)
- strawberry (Çilek)

### Proteinler
- chicken (Tavuk)
- beef (Dana Eti)
- lamb (Kuzu Eti)
- fish (Balık)
- shrimp (Karides)
- egg (Yumurta)
- ground_beef (Kıyma)

### Süt Ürünleri
- milk (Süt)
- cheese (Peynir)
- yogurt (Yoğurt)
- butter (Tereyağı)
- cream (Krema)

### Tahıllar
- rice (Pirinç)
- pasta (Makarna)
- bread (Ekmek)
- flour (Un)

---

## Örnek Kullanım

### cURL
```bash
curl -X POST https://api.tarifuyg.com/api/v1/detect \
  -H "Content-Type: multipart/form-data" \
  -F "image=@/path/to/image.jpg" \
  -F "confidence_threshold=0.5"
```

### Python
```python
import requests

url = "https://api.tarifuyg.com/api/v1/detect"
files = {"image": open("image.jpg", "rb")}
data = {"confidence_threshold": 0.5}

response = requests.post(url, files=files, data=data)
result = response.json()

for detection in result["detections"]:
    print(f"{detection['label_tr']}: {detection['confidence']:.2%}")
```

### Dart/Flutter
```dart
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> detectIngredients(File imageFile) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('https://api.tarifuyg.com/api/v1/detect'),
  );
  
  request.files.add(
    await http.MultipartFile.fromPath('image', imageFile.path),
  );
  request.fields['confidence_threshold'] = '0.5';
  
  final response = await request.send();
  final body = await response.stream.bytesToString();
  return jsonDecode(body);
}
```

---

## Rate Limiting

| Plan | Requests/min | Requests/day |
|------|--------------|--------------|
| Free | 10 | 100 |
| Pro | 60 | 5000 |
| Enterprise | Unlimited | Unlimited |

---

## Model Bilgisi

- **Model**: YOLOv8n (custom trained)
- **Input Size**: 640x640
- **Classes**: 50+ malzeme
- **mAP@0.5**: ~0.85
- **Inference Time**: ~100-200ms (GPU)

---

## Webhook (Opsiyonel)

Batch işlemler için webhook desteği:

```json
POST /webhooks/detection-complete
{
  "job_id": "abc123",
  "status": "completed",
  "results_url": "https://api.tarifuyg.com/results/abc123"
}
```
