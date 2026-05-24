import numpy as np
from PIL import Image
import io
from huggingface_hub import hf_hub_download
import tensorflow as tf
from app.cures import get_info

CLASS_NAMES = [
    "Apple___Apple_scab", "Apple___Black_rot", "Apple___Cedar_apple_rust", "Apple___healthy",
    "Blueberry___healthy", "Cherry_(including_sour)___Powdery_mildew",
    "Cherry_(including_sour)___healthy", "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot",
    "Corn_(maize)___Common_rust_", "Corn_(maize)___Northern_Leaf_Blight", "Corn_(maize)___healthy",
    "Grape___Black_rot", "Grape___Esca_(Black_Measles)", "Grape___Leaf_blight_(Isariopsis_Leaf_Spot)",
    "Grape___healthy", "Orange___Haunglongbing_(Citrus_greening)", "Peach___Bacterial_spot",
    "Peach___healthy", "Pepper,_bell___Bacterial_spot", "Pepper,_bell___healthy",
    "Potato___Early_blight", "Potato___Late_blight", "Potato___healthy",
    "Raspberry___healthy", "Soybean___healthy", "Squash___Powdery_mildew",
    "Strawberry___Leaf_scorch", "Strawberry___healthy", "Tomato___Bacterial_spot",
    "Tomato___Early_blight", "Tomato___Late_blight", "Tomato___Leaf_Mold",
    "Tomato___Septoria_leaf_spot", "Tomato___Spider_mites Two-spotted_spider_mite",
    "Tomato___Target_Spot", "Tomato___Tomato_Yellow_Leaf_Curl_Virus",
    "Tomato___Tomato_mosaic_virus", "Tomato___healthy"
]

_model = None

def load_model():
    global _model
    if _model is None:
        model_path = hf_hub_download(
            repo_id="linkanjarad/mobilenet_v2_1.0_224-plant-disease-identification",
            filename="model.h5"
        )
        _model = tf.keras.models.load_model(model_path)
    return _model

def preprocess(image_bytes: bytes) -> np.ndarray:
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB").resize((224, 224))
    arr = np.array(img, dtype=np.float32) / 255.0
    return np.expand_dims(arr, axis=0)

def predict(image_bytes: bytes) -> dict:
    model = load_model()
    input_arr = preprocess(image_bytes)
    preds = model.predict(input_arr, verbose=0)[0]
    top_idx = int(np.argmax(preds))
    confidence = float(preds[top_idx])
    class_name = CLASS_NAMES[top_idx]
    info = get_info(class_name)
    return {
        "class_name": class_name,
        "display_name": info["display"],
        "confidence": round(confidence * 100, 2),
        "severity": info["severity"],
        "cure": info["cure"],
        "prevention": info["prevention"],
        "top_3": [
            {"disease": CLASS_NAMES[i], "confidence": round(float(preds[i]) * 100, 2)}
            for i in np.argsort(preds)[::-1][:3]
        ]
    }