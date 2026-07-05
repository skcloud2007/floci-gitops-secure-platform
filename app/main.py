from fastapi import FastAPI, Response
import os
import socket
from prometheus_client import Counter, Gauge, generate_latest, CONTENT_TYPE_LATEST

app = FastAPI(title="Customer Portal API")

REQUEST_COUNT = Counter(
    "customer_portal_requests_total",
    "Total requests received by Customer Portal API",
    ["endpoint"]
)

APP_INFO = Gauge(
    "customer_portal_app_info",
    "Customer Portal API application info",
    ["version", "environment"]
)

@app.on_event("startup")
def startup_event():
    APP_INFO.labels(
        version=os.getenv("APP_VERSION", "dev"),
        environment=os.getenv("APP_ENVIRONMENT", "dev")
    ).set(1)

@app.get("/")
def home():
    REQUEST_COUNT.labels(endpoint="/").inc()
    return {
        "service": "customer-portal-api",
        "message": "Running with GitOps + FLoCI",
        "version": os.getenv("APP_VERSION", "dev"),
        "environment": os.getenv("APP_ENVIRONMENT", "dev"),
        "hostname": socket.gethostname()
    }

@app.get("/health")
def health():
    REQUEST_COUNT.labels(endpoint="/health").inc()
    return {
        "status": "healthy"
    }

@app.get("/ready")
def ready():
    REQUEST_COUNT.labels(endpoint="/ready").inc()
    return {
        "status": "ready"
    }

@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
