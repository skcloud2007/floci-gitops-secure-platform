#!/bin/bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-customer-dev}"
ARGO_APP="${ARGO_APP:-customer-portal-api-dev}"

echo "======================================"
echo "Post Deployment Smoke Test"
echo "Namespace: ${NAMESPACE}"
echo "Argo App: ${ARGO_APP}"
echo "======================================"

echo
echo "1. Checking Argo CD application status..."
kubectl get application "${ARGO_APP}" -n argocd -o wide

SYNC_STATUS=$(kubectl get application "${ARGO_APP}" -n argocd -o jsonpath='{.status.sync.status}')
HEALTH_STATUS=$(kubectl get application "${ARGO_APP}" -n argocd -o jsonpath='{.status.health.status}')

echo "SYNC_STATUS=${SYNC_STATUS}"
echo "HEALTH_STATUS=${HEALTH_STATUS}"

if [ "${SYNC_STATUS}" != "Synced" ]; then
  echo "ERROR: Argo CD app is not Synced"
  exit 1
fi

if [ "${HEALTH_STATUS}" != "Healthy" ]; then
  echo "ERROR: Argo CD app is not Healthy"
  exit 1
fi

echo
echo "2. Checking Kubernetes resources..."
kubectl get deploy,rs,pods,svc -n "${NAMESPACE}"

echo
echo "3. Waiting for deployment rollout..."
kubectl rollout status deployment/"${ARGO_APP}" -n "${NAMESPACE}" --timeout=120s

echo
echo "4. Checking pod image..."
POD_NAME=$(kubectl get pod -n "${NAMESPACE}" -l app.kubernetes.io/instance="${ARGO_APP}" -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod "${POD_NAME}" -n "${NAMESPACE}" | grep -i "Image:"

echo
echo "5. Testing service health endpoints..."
kubectl port-forward svc/"${ARGO_APP}" 18081:80 -n "${NAMESPACE}" >/tmp/floci-smoke-port-forward.log 2>&1 &
PF_PID=$!

cleanup() {
  kill "${PF_PID}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

sleep 5

echo "Testing /health"
curl -fsS http://localhost:18081/health
echo

echo "Testing /ready"
curl -fsS http://localhost:18081/ready
echo

echo
echo "======================================"
echo "Smoke test completed successfully"
echo "======================================"
