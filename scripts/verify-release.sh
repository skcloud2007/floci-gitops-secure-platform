#!/bin/bash
set -euo pipefail

AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
APP_NAME="${APP_NAME:-customer-portal-api}"
NAMESPACE="${NAMESPACE:-customer-dev}"
ARGO_APP="${ARGO_APP:-customer-portal-api-dev}"

echo "======================================"
echo "FLoCI GitOps Release Verification"
echo "======================================"
echo "AWS_ENDPOINT_URL=${AWS_ENDPOINT_URL}"
echo "APP_NAME=${APP_NAME}"
echo "NAMESPACE=${NAMESPACE}"
echo "ARGO_APP=${ARGO_APP}"
echo

echo "1. Checking FLoCI containers..."
docker ps | grep -E 'floci|registry'

echo
echo "2. Checking FLoCI ECR repository..."
aws ecr describe-repositories \
  --repository-names "${APP_NAME}" \
  --endpoint-url "${AWS_ENDPOINT_URL}"

echo
echo "3. Listing latest FLoCI ECR images..."
aws ecr list-images \
  --repository-name "${APP_NAME}" \
  --endpoint-url "${AWS_ENDPOINT_URL}"

echo
echo "4. Checking FLoCI S3 security reports..."
aws s3 ls "s3://floci-security-reports/${APP_NAME}/dev/" \
  --endpoint-url "${AWS_ENDPOINT_URL}" || true

echo
echo "5. Checking FLoCI S3 Helm artifacts..."
aws s3 ls "s3://floci-helm-artifacts/${APP_NAME}/dev/" \
  --endpoint-url "${AWS_ENDPOINT_URL}" || true

echo
echo "6. Checking FLoCI DynamoDB release ledger..."
aws dynamodb scan \
  --table-name GitOpsReleaseLedger \
  --endpoint-url "${AWS_ENDPOINT_URL}" || true

echo
echo "7. Checking Argo CD application..."
kubectl get application "${ARGO_APP}" -n argocd -o wide

echo
echo "8. Checking Kubernetes deployment and pods..."
kubectl get deploy,rs,pods,svc -n "${NAMESPACE}"

echo
echo "9. Checking pod image..."
POD_NAME=$(kubectl get pod -n "${NAMESPACE}" -l app.kubernetes.io/instance="${ARGO_APP}" -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod "${POD_NAME}" -n "${NAMESPACE}" | grep -i "Image:"

echo
echo "10. Testing app health endpoint using port-forward..."
kubectl port-forward svc/"${ARGO_APP}" 18081:80 -n "${NAMESPACE}" >/tmp/floci-release-port-forward.log 2>&1 &
PF_PID=$!

sleep 5

curl -fsS http://localhost:18081/health
echo
curl -fsS http://localhost:18081/ready
echo

kill "${PF_PID}" >/dev/null 2>&1 || true

echo
echo "======================================"
echo "Release verification completed successfully"
echo "======================================"
