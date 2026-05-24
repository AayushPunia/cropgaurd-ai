import torch
from transformers import MobileNetV2ForImageClassification, MobileNetV2ImageProcessor
from PIL import Image
import io
from app.cures import get_info

MODEL_ID = "linkanjarad/mobilenet_v2_1.0_224-plant-disease-identification"

_model = None
_processor = None

def load_model():
    global _model, _processor
    if _model is None:
        _processor = MobileNetV2ImageProcessor.from_pretrained(MODEL_ID)
        _model = MobileNetV2ForImageClassification.from_pretrained(MODEL_ID)
        _model.eval()
    return _model, _processor

def predict(image_bytes: bytes) -> dict:
    model, processor = load_model()
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    inputs = processor(images=img, return_tensors="pt")

    with torch.no_grad():
        logits = model(**inputs).logits

    probs = torch.softmax(logits, dim=-1)[0]
    top3_idx = probs.topk(3).indices.tolist()

    top_idx = top3_idx[0]
    class_name = model.config.id2label[top_idx]
    confidence = round(float(probs[top_idx]) * 100, 2)
    info = get_info(class_name)

    return {
        "class_name": class_name,
        "display_name": info["display"],
        "confidence": confidence,
        "severity": info["severity"],
        "cure": info["cure"],
        "prevention": info["prevention"],
        "top_3": [
            {
                "disease": model.config.id2label[i],
                "confidence": round(float(probs[i]) * 100, 2)
            }
            for i in top3_idx
        ]
    }