"""
TarifUyg - Malzeme Tespiti API
FastAPI + YOLOv8 Backend

Kullanım:
  pip install fastapi uvicorn python-multipart ultralytics pillow
  uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""

import io
import time
from typing import Optional
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image
import uvicorn

# YOLOv8 import (uncomment when model is ready)
# from ultralytics import YOLO

app = FastAPI(
    title="TarifUyg Ingredient Detection API",
    description="YOLOv8 tabanlı malzeme tespit servisi",
    version="1.0.0"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Label mappings
LABEL_TR = {
    "tomato": "Domates",
    "onion": "Soğan",
    "garlic": "Sarımsak",
    "potato": "Patates",
    "carrot": "Havuç",
    "pepper": "Biber",
    "eggplant": "Patlıcan",
    "zucchini": "Kabak",
    "cucumber": "Salatalık",
    "lettuce": "Marul",
    "spinach": "Ispanak",
    "broccoli": "Brokoli",
    "cauliflower": "Karnabahar",
    "mushroom": "Mantar",
    "egg": "Yumurta",
    "chicken": "Tavuk",
    "beef": "Dana Eti",
    "fish": "Balık",
    "milk": "Süt",
    "cheese": "Peynir",
    "yogurt": "Yoğurt",
    "butter": "Tereyağı",
    "rice": "Pirinç",
    "pasta": "Makarna",
    "bread": "Ekmek",
    "flour": "Un",
    "apple": "Elma",
    "banana": "Muz",
    "orange": "Portakal",
    "lemon": "Limon",
}

# Model instance (lazy loading)
model = None

def get_model():
    """Load YOLOv8 model (lazy loading)"""
    global model
    if model is None:
        # Uncomment when model is ready:
        # model = YOLO("best.pt")
        pass
    return model


class BoundingBox(BaseModel):
    x1: float
    y1: float
    x2: float
    y2: float


class Detection(BaseModel):
    label: str
    label_tr: str
    confidence: float
    bbox: BoundingBox


class ImageSize(BaseModel):
    width: int
    height: int


class DetectionResponse(BaseModel):
    success: bool
    detections: list[Detection]
    image_size: ImageSize
    processing_time_ms: int
    model_version: str = "1.0.0"


class ErrorDetail(BaseModel):
    code: str
    message: str


class ErrorResponse(BaseModel):
    success: bool = False
    error: ErrorDetail


@app.get("/")
async def root():
    return {
        "service": "TarifUyg Ingredient Detection API",
        "version": "1.0.0",
        "status": "running"
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.post("/detect", response_model=DetectionResponse)
async def detect_ingredients(
    image: UploadFile = File(...),
    confidence_threshold: float = Form(default=0.5),
    max_detections: int = Form(default=20)
):
    """
    Gönderilen fotoğraftaki malzemeleri tespit eder.
    
    - **image**: JPEG/PNG formatında görsel
    - **confidence_threshold**: Minimum güven skoru (0.0-1.0)
    - **max_detections**: Maksimum tespit sayısı
    """
    start_time = time.time()
    
    # Validate file type
    if image.content_type not in ["image/jpeg", "image/png", "image/jpg"]:
        raise HTTPException(
            status_code=400,
            detail={"code": "INVALID_IMAGE", "message": "Sadece JPEG/PNG formatı desteklenir"}
        )
    
    # Read image
    try:
        contents = await image.read()
        img = Image.open(io.BytesIO(contents))
        img_width, img_height = img.size
    except Exception as e:
        raise HTTPException(
            status_code=400,
            detail={"code": "INVALID_IMAGE", "message": f"Görsel okunamadı: {str(e)}"}
        )
    
    # Check file size (max 10MB)
    if len(contents) > 10 * 1024 * 1024:
        raise HTTPException(
            status_code=400,
            detail={"code": "IMAGE_TOO_LARGE", "message": "Görsel boyutu 10MB'dan küçük olmalı"}
        )
    
    detections = []
    
    # Run inference
    model = get_model()
    
    if model is not None:
        # Real inference with YOLOv8
        # results = model(img, conf=confidence_threshold)
        # for result in results:
        #     for box in result.boxes:
        #         label = model.names[int(box.cls)]
        #         detections.append(Detection(
        #             label=label,
        #             label_tr=LABEL_TR.get(label, label),
        #             confidence=float(box.conf),
        #             bbox=BoundingBox(
        #                 x1=float(box.xyxy[0][0]),
        #                 y1=float(box.xyxy[0][1]),
        #                 x2=float(box.xyxy[0][2]),
        #                 y2=float(box.xyxy[0][3])
        #             )
        #         ))
        pass
    else:
        # Mock detections for development
        import random
        mock_labels = ["tomato", "onion", "pepper", "egg", "cheese", "potato"]
        num_detections = random.randint(2, 5)
        
        for i in range(num_detections):
            label = random.choice(mock_labels)
            x1 = random.randint(50, 300)
            y1 = random.randint(50, 300)
            
            detections.append(Detection(
                label=label,
                label_tr=LABEL_TR.get(label, label),
                confidence=random.uniform(0.7, 0.98),
                bbox=BoundingBox(
                    x1=x1,
                    y1=y1,
                    x2=x1 + random.randint(80, 150),
                    y2=y1 + random.randint(80, 150)
                )
            ))
    
    # Sort by confidence and limit
    detections.sort(key=lambda x: x.confidence, reverse=True)
    detections = detections[:max_detections]
    
    processing_time = int((time.time() - start_time) * 1000)
    
    return DetectionResponse(
        success=True,
        detections=detections,
        image_size=ImageSize(width=img_width, height=img_height),
        processing_time_ms=processing_time
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
