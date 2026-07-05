#!/bin/bash
set -euo pipefail

NAMESPACE="customer-dev"

echo "======================================"
echo "Kyverno Policy Validation Test"
echo "Namespace: ${NAMESPACE}"
echo "======================================"

echo
echo "Checking Kyverno pods..."
kubectl get pods -n kyverno

echo
echo "Checking ClusterPolicies..."
kubectl get clusterpolicy

echo
echo "Test 1: nginx:latest should be blocked"
if kubectl run bad-nginx-latest \
  --image=nginx:latest \
  --namespace "${NAMESPACE}" 2>/tmp/kyverno-test-latest.log; then

  echo "FAILED: nginx:latest pod was allowed"
  kubectl delete pod bad-nginx-latest -n "${NAMESPACE}" --ignore-not-found=true
  exit 1
else
  echo "PASSED: nginx:latest was blocked"
  cat /tmp/kyverno-test-latest.log
fi

echo
echo "Test 2: Pod without resources should be blocked"
cat > /tmp/bad-no-resources.yaml <<EOF_BAD
apiVersion: v1
kind: Pod
metadata:
  name: bad-no-resources
  namespace: ${NAMESPACE}
spec:
  containers:
    - name: nginx
      image: nginx:1.27
EOF_BAD

if kubectl apply -f /tmp/bad-no-resources.yaml 2>/tmp/kyverno-test-resources.log; then
  echo "FAILED: Pod without resources was allowed"
  kubectl delete pod bad-no-resources -n "${NAMESPACE}" --ignore-not-found=true
  exit 1
else
  echo "PASSED: Pod without resources was blocked"
  cat /tmp/kyverno-test-resources.log
fi

echo
echo "Test 3: Privilege escalation should be blocked"
cat > /tmp/bad-privilege-escalation.yaml <<EOF_BAD
apiVersion: v1
kind: Pod
metadata:
  name: bad-privilege-escalation
  namespace: ${NAMESPACE}
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
  containers:
    - name: nginx
      image: nginx:1.27
      resources:
        requests:
          cpu: 50m
          memory: 64Mi
        limits:
          cpu: 100m
          memory: 128Mi
      securityContext:
        allowPrivilegeEscalation: true
EOF_BAD

if kubectl apply -f /tmp/bad-privilege-escalation.yaml 2>/tmp/kyverno-test-privilege.log; then
  echo "FAILED: Privilege escalation pod was allowed"
  kubectl delete pod bad-privilege-escalation -n "${NAMESPACE}" --ignore-not-found=true
  exit 1
else
  echo "PASSED: Privilege escalation pod was blocked"
  cat /tmp/kyverno-test-privilege.log
fi

echo
echo "Checking GitOps app health..."
kubectl get application customer-portal-api-dev -n argocd -o wide
kubectl get pods -n "${NAMESPACE}"

echo
echo "======================================"
echo "Kyverno policy validation completed"
echo "All negative tests were blocked"
echo "======================================"
