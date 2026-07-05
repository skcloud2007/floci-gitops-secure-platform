#!/bin/bash
set -euo pipefail

AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"

echo "========== Git =========="
git status --short
git remote -v

echo
echo "========== Docker / FLoCI =========="
docker ps | grep -E 'floci|registry|floci-gitops' || true

echo
echo "========== FLoCI ECR =========="
aws ecr list-images \
  --repository-name customer-portal-api \
  --endpoint-url "${AWS_ENDPOINT_URL}" || true

echo
echo "========== FLoCI S3 Security Evidence =========="
aws s3 ls s3://floci-security-reports/customer-portal-api/dev/ \
  --endpoint-url "${AWS_ENDPOINT_URL}" || true

echo
echo "========== FLoCI S3 Release Evidence =========="
aws s3 ls s3://floci-release-evidence/customer-portal-api/dev/ \
  --endpoint-url "${AWS_ENDPOINT_URL}" || true

echo
echo "========== FLoCI Helm Artifacts =========="
aws s3 ls s3://floci-helm-artifacts/customer-portal-api/dev/ \
  --endpoint-url "${AWS_ENDPOINT_URL}" || true

echo
echo "========== FLoCI DynamoDB Release Ledger =========="
aws dynamodb scan \
  --table-name GitOpsReleaseLedger \
  --endpoint-url "${AWS_ENDPOINT_URL}" || true

echo
echo "========== Argo CD Applications =========="
kubectl get applications -n argocd

echo
echo "========== Customer App =========="
kubectl get deploy,pods,svc -n customer-dev

echo
echo "========== Kyverno =========="
kubectl get pods -n kyverno
kubectl get clusterpolicy

echo
echo "========== Done =========="
