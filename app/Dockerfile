FROM python:3.11-slim-bookworm

WORKDIR /app

# Patch OS packages to reduce base-image CVEs
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Create non-root user for runtime
RUN useradd --create-home --uid 10001 appuser \
    && chown -R appuser:appuser /app

USER 10001

ENV APP_VERSION=dev

EXPOSE 8080

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
