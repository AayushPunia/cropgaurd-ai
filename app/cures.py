DISEASE_INFO = {
    "Apple___Apple_scab": {
        "display": "Apple Scab",
        "cure": "Apply fungicides containing captan or myclobutanil. Remove and destroy infected leaves.",
        "prevention": "Plant resistant varieties. Ensure good air circulation. Avoid overhead irrigation.",
        "severity": "Medium"
    },
    "Apple___Black_rot": {
        "display": "Apple Black Rot",
        "cure": "Prune infected branches 8 inches below visible damage. Apply copper-based fungicide.",
        "prevention": "Remove mummified fruit. Maintain tree vigor with proper fertilization.",
        "severity": "High"
    },
    "Apple___Cedar_apple_rust": {
        "display": "Cedar Apple Rust",
        "cure": "Apply myclobutanil fungicide at first sign of infection. Repeat every 7-10 days.",
        "prevention": "Remove nearby juniper/cedar trees. Plant rust-resistant apple varieties.",
        "severity": "Medium"
    },
    "Apple___healthy": {
        "display": "Healthy Apple",
        "cure": "No treatment needed.",
        "prevention": "Continue regular monitoring and good agricultural practices.",
        "severity": "None"
    },
    "Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot": {
        "display": "Corn Gray Leaf Spot",
        "cure": "Apply strobilurin or triazole fungicide. Improve field drainage.",
        "prevention": "Rotate crops. Use resistant hybrids. Avoid excessive nitrogen.",
        "severity": "High"
    },
    "Corn_(maize)___Common_rust_": {
        "display": "Corn Common Rust",
        "cure": "Apply foliar fungicide (mancozeb). Most effective before tasseling.",
        "prevention": "Plant resistant hybrids. Early planting reduces exposure.",
        "severity": "Medium"
    },
    "Corn_(maize)___Northern_Leaf_Blight": {
        "display": "Corn Northern Leaf Blight",
        "cure": "Fungicide application with propiconazole. Remove heavily infected plants.",
        "prevention": "Use resistant varieties. Crop rotation. Till infected debris.",
        "severity": "High"
    },
    "Corn_(maize)___healthy": {
        "display": "Healthy Corn",
        "cure": "No treatment needed.",
        "prevention": "Maintain balanced soil nutrition and proper irrigation.",
        "severity": "None"
    },
    "Potato___Early_blight": {
        "display": "Potato Early Blight",
        "cure": "Apply chlorothalonil or mancozeb fungicide every 7-10 days.",
        "prevention": "Use certified seed potatoes. Proper spacing for air circulation.",
        "severity": "Medium"
    },
    "Potato___Late_blight": {
        "display": "Potato Late Blight",
        "cure": "Apply metalaxyl or cymoxanil immediately. Destroy infected plants.",
        "prevention": "Use resistant varieties. Avoid overhead watering. Monitor humidity.",
        "severity": "Critical"
    },
    "Potato___healthy": {
        "display": "Healthy Potato",
        "cure": "No treatment needed.",
        "prevention": "Regular field scouting and soil testing recommended.",
        "severity": "None"
    },
    "Tomato___Bacterial_spot": {
        "display": "Tomato Bacterial Spot",
        "cure": "Apply copper-based bactericide. Remove infected plant parts.",
        "prevention": "Use disease-free seeds. Avoid working with wet plants.",
        "severity": "High"
    },
    "Tomato___Early_blight": {
        "display": "Tomato Early Blight",
        "cure": "Apply mancozeb or chlorothalonil. Mulch to prevent soil splash.",
        "prevention": "Stake plants for air circulation. Remove lower leaves.",
        "severity": "Medium"
    },
    "Tomato___Late_blight": {
        "display": "Tomato Late Blight",
        "cure": "Apply metalaxyl fungicide immediately. Remove all infected tissue.",
        "prevention": "Avoid wet foliage. Plant in well-drained soil.",
        "severity": "Critical"
    },
    "Tomato___Leaf_Mold": {
        "display": "Tomato Leaf Mold",
        "cure": "Apply chlorothalonil fungicide. Increase ventilation in greenhouses.",
        "prevention": "Reduce humidity below 85%. Space plants adequately.",
        "severity": "Medium"
    },
    "Tomato___Septoria_leaf_spot": {
        "display": "Tomato Septoria Leaf Spot",
        "cure": "Apply mancozeb or copper fungicide. Remove infected lower leaves.",
        "prevention": "Mulch around base. Avoid overhead irrigation.",
        "severity": "Medium"
    },
    "Tomato___healthy": {
        "display": "Healthy Tomato",
        "cure": "No treatment needed.",
        "prevention": "Continue good watering and fertilization practices.",
        "severity": "None"
    },
}

SEVERITY_COLORS = {
    "None": "#22c55e",
    "Medium": "#f59e0b",
    "High": "#ef4444",
    "Critical": "#7c3aed"
}

def get_info(class_name: str) -> dict:
    return DISEASE_INFO.get(class_name, {
        "display": class_name.replace("_", " ").replace("___", " — "),
        "cure": "Consult a local agricultural extension officer for treatment advice.",
        "prevention": "Practice good crop hygiene and regular field monitoring.",
        "severity": "Unknown"
    })