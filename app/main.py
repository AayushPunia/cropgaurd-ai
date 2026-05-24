from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
import time
from app.predict import predict

app = FastAPI(title="CropGuard AI", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/static", StaticFiles(directory="app/static"), name="static")

@app.get("/")
async def root():
    return FileResponse("app/static/index.html")

@app.get("/health")
async def health():
    return {"status": "ok", "model": "mobilenet_v2_plantvillage"}

@app.post("/predict")
async def predict_disease(file: UploadFile = File(...)):
    if not file.content_type.startswith("image/"):
        raise HTTPException(400, "File must be an image")
    if file.size and file.size > 10 * 1024 * 1024:
        raise HTTPException(400, "Image must be under 10MB")
    
    start = time.time()
    image_bytes = await file.read()
    result = predict(image_bytes)
    result["latency_ms"] = round((time.time() - start) * 1000, 1)
    return result