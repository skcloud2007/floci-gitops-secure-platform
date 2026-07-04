from fastapi import FastAPI
import os
import socket

app = FastAPI(title="Customer Portal API")

@app.get("/")
def home():
    return {
        "service": "customer-portal-api",
        "message": "Running with GitOps + FLoCI",
        "version": os.getenv("APP_VERSION", "dev"),
        "hostname": socket.gethostname()
    }

@app.get("/health")
def health():
    return {
        "status": "healthy"
    }

@app.get("/ready")
def ready():
    return {
        "status": "ready"
    }
