# 🌿 CropGuard AI

**AI-powered plant disease detection and cure recommendation system.**

Upload a photo of any plant leaf and CropGuard AI will instantly identify the disease, assess its severity, and recommend treatment — powered by a fine-tuned MobileNetV2 deep learning model trained on the PlantVillage dataset.

---

## ✨ Features

- 🔬 **Instant Disease Detection** — Identifies 38 plant diseases across 14 crop species using a MobileNetV2 model
- 📊 **Confidence Scoring** — Returns top-3 predictions with confidence percentages
- 💊 **Cure & Prevention** — Provides treatment recommendations and preventive measures for each disease
- 🚦 **Severity Assessment** — Categorizes diseases as None / Medium / High / Critical
- ⚡ **Low-Latency Inference** — Runs on CPU with optimized PyTorch inference
- 🌐 **Web Interface** — Clean, responsive UI for uploading leaf images and viewing results
- 🏥 **Health Endpoint** — Built-in `/health` route for Kubernetes liveness/readiness probes

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Backend** | FastAPI + Uvicorn |
| **ML Model** | MobileNetV2 (HuggingFace Transformers) |
| **Deep Learning** | PyTorch + TorchVision |
| **Frontend** | HTML/CSS/JS (static, served by FastAPI) |
| **Containerization** | Docker |
| **Orchestration** | K3s (Lightweight Kubernetes) |
| **CI/CD** | Jenkins (Pipeline) |
| **Infrastructure** | Terraform + AWS (EC2, ECR, IAM, EIP) |
| **Ingress** | Traefik (K3s default) |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS EC2 Instance                     │
│                                                             │
│  ┌──────────┐    ┌─────────────────────────────────────┐    │
│  │ Jenkins  │───▶│              K3s Cluster             │    │
│  │ :8080    │    │                                       │   │
│  └──────────┘    │  ┌───────────┐   ┌────────────────┐  │   │
│       │          │  │  Traefik  │──▶│  CropGuard AI  │  │   │
│       │          │  │  Ingress  │   │  Pod (:8000)   │  │   │
│       ▼          │  │  (:80)    │   │                │  │   │
│  ┌──────────┐    │  └───────────┘   │  FastAPI +     │  │   │
│  │   ECR    │    │                  │  MobileNetV2   │  │   │
│  │ Registry │◀───│                  └────────────────┘  │   │
│  └──────────┘    └─────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**CI/CD Flow:** `Git Push → Jenkins → Docker Build → Push to ECR → Deploy to K3s → Health Check`

---

## 🚀 Getting Started

### Prerequisites

- Python 3.11+
- Docker (for containerized deployment)
- AWS CLI (for cloud deployment)

### Local Development

```bash
# Clone the repository
git clone https://github.com/AayushPunia/cropguard-ai.git
cd cropguard-ai

# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate   # Windows

# Install dependencies
pip install -r requirements.txt

# Run the application
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The app will be available at **http://localhost:8000**

> **Note:** On first run, the MobileNetV2 model (~14 MB) will be downloaded from HuggingFace Hub.

### Docker

```bash
# Build the image
docker build -t cropguard-ai .

# Run the container
docker run -p 8000:8000 cropguard-ai
```

---

## 📡 API Reference

### `GET /`
Serves the web interface (static HTML page).

### `GET /health`
Health check endpoint for Kubernetes probes.

**Response:**
```json
{
  "status": "ok",
  "model": "mobilenet_v2_plantvillage"
}
```

### `POST /predict`
Upload a plant leaf image to detect diseases.

**Request:**
- Content-Type: `multipart/form-data`
- Body: `file` — Image file (JPEG, PNG, etc.) under 10 MB

**Response:**
```json
{
  "class_name": "Tomato with Early Blight",
  "display_name": "Tomato Early Blight",
  "confidence": 97.42,
  "severity": "Medium",
  "cure": "Apply mancozeb or chlorothalonil. Mulch to prevent soil splash.",
  "prevention": "Stake plants for air circulation. Remove lower leaves.",
  "top_3": [
    { "disease": "Tomato with Early Blight", "confidence": 97.42 },
    { "disease": "Tomato with Septoria Leaf Spot", "confidence": 1.83 },
    { "disease": "Tomato with Late Blight", "confidence": 0.54 }
  ],
  "latency_ms": 342.1
}
```

---

## 🌱 Supported Crops & Diseases

<details>
<summary><strong>14 Crops — 38 Classes (click to expand)</strong></summary>

| Crop | Diseases Detected |
|---|---|
| 🍎 Apple | Scab, Black Rot, Cedar Apple Rust, Healthy |
| 🫐 Blueberry | Healthy |
| 🍒 Cherry | Powdery Mildew, Healthy |
| 🌽 Corn (Maize) | Cercospora/Gray Leaf Spot, Common Rust, Northern Leaf Blight, Healthy |
| 🍇 Grape | Black Rot, Esca (Black Measles), Isariopsis Leaf Spot, Healthy |
| 🍊 Orange | Citrus Greening (HLB) |
| 🍑 Peach | Bacterial Spot, Healthy |
| 🫑 Bell Pepper | Bacterial Spot, Healthy |
| 🥔 Potato | Early Blight, Late Blight, Healthy |
| 🫐 Raspberry | Healthy |
| 🫘 Soybean | Healthy |
| 🎃 Squash | Powdery Mildew |
| 🍓 Strawberry | Leaf Scorch, Healthy |
| 🍅 Tomato | Bacterial Spot, Early Blight, Late Blight, Leaf Mold, Septoria Leaf Spot, Spider Mites, Target Spot, Yellow Leaf Curl Virus, Mosaic Virus, Healthy |

</details>

---

## ⚙️ CI/CD Pipeline (Jenkins)

The Jenkins pipeline automates the full build-to-deploy lifecycle:

```
Checkout → Build Docker Image → Push to ECR → Deploy to K3s → Health Check
```

| Stage | Description |
|---|---|
| **Checkout** | Pulls latest code from the Git repository |
| **Build Docker Image** | Builds and tags the image with the Jenkins build number |
| **Push to ECR** | Authenticates with AWS ECR and pushes the image |
| **Deploy to K3s** | Applies K8s manifests or updates the running deployment |
| **Health Check** | Verifies the pod is running and `/health` responds |

---

## 🏢 Infrastructure (Terraform)

The `terraform/` directory provisions all AWS resources needed:

| Resource | Purpose |
|---|---|
| **IAM Role + Instance Profile** | Grants EC2 access to pull/push ECR images |
| **Security Group** | Opens ports 22 (SSH), 80 (App), 8080 (Jenkins) |
| **Elastic IP** | Permanent public IP that survives instance reboots |

### EC2 Setup

The `terraform/setup-ec2.sh` script bootstraps a fresh Ubuntu EC2 instance with:
- Docker
- Jenkins (Java 17)
- K3s (lightweight Kubernetes)
- AWS CLI v2
- ECR credential auto-refresh (cron every 6 hours)

```bash
# On the EC2 instance
sudo ./setup-ec2.sh
```

---

## 📁 Project Structure

```
cropguard-ai/
├── app/
│   ├── main.py            # FastAPI application entry point
│   ├── predict.py          # ML inference (MobileNetV2 + Transformers)
│   ├── cures.py            # Disease info, cures & prevention database
│   ├── model/              # Local model cache (auto-downloaded)
│   └── static/
│       └── index.html      # Web interface
├── k8s/
│   ├── deployment.yaml     # K8s Deployment + Service + Ingress
│   └── ingress.yaml        # Traefik Ingress configuration
├── terraform/
│   ├── main.tf             # AWS resources (IAM, SG, EIP)
│   ├── variables.tf        # Configurable variables
│   ├── outputs.tf          # Terraform outputs (URLs, IPs)
│   └── setup-ec2.sh        # EC2 bootstrap script
├── tests/                  # Test directory
├── Dockerfile              # Container image definition
├── Jenkinsfile             # CI/CD pipeline definition
├── requirements.txt        # Python dependencies
└── README.md
```

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).

---

<p align="center">
  Built with 🌿 by <a href="https://github.com/AayushPunia">Aayush Punia</a>
</p>
