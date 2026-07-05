# FLoCI GitOps Secure Platform

A production-style local DevSecOps and GitOps platform built using **FLoCI, GitLab CI/CD, Argo CD, Helm, Kubernetes, Trivy, Kyverno, and GitHub mirroring**.

This project demonstrates an end-to-end software delivery workflow where code changes are automatically built, scanned, published, audited, deployed through GitOps, validated by smoke tests, and protected by Kubernetes admission policies.

---

## Project Overview

This project implements a complete GitOps-based delivery platform for a sample microservice named:

```text
customer-portal-api
```

The project uses **FLoCI** as a local AWS-compatible platform to simulate cloud-native services such as ECR, S3, DynamoDB, and SQS.

---

## End-to-End Flow

```text
Developer Push
     |
     v
GitLab Repository
     |
     v
GitLab CI/CD Pipeline
     |
     |-- Validate Helm, FLoCI, Kubernetes
     |-- Validate Kyverno security policies
     |-- Build Docker image
     |-- Run Trivy vulnerability scan
     |-- Fail pipeline on CRITICAL CVEs
     |-- Push image to FLoCI ECR
     |-- Upload security evidence to FLoCI S3
     |-- Upload rendered Helm manifest to FLoCI S3
     |-- Write release metadata to FLoCI DynamoDB
     |-- Send release event to FLoCI SQS
     |-- Update GitOps Helm values in Git
     |
     v
Argo CD
     |
     |-- Detects Git change
     |-- Syncs Helm chart
     |-- Self-heals drift
     |
     v
Kind Kubernetes Cluster
     |
     |-- Kyverno admission control
     |-- Helm-based application deployment
     |-- FastAPI service running
     |-- Smoke test validation
```

---

## Project Goals

This project was created to practice and demonstrate:

- Full GitOps delivery model
- FLoCI-based local cloud platform usage
- Local AWS-style ECR, S3, DynamoDB, and SQS workflows
- GitLab CI/CD with local shell runner
- Docker image build and publish workflow
- Trivy vulnerability scanning
- CI security gate for CRITICAL vulnerabilities
- Helm-based Kubernetes application packaging
- Argo CD GitOps deployment
- Argo CD self-healing
- Kyverno Kubernetes admission policies
- GitOps-managed security policies
- Release evidence storage
- Release ledger tracking
- Smoke test automation
- GitHub mirror for showcase and backup

---

## Tech Stack

| Area | Tool |
|---|---|
| Local AWS-style platform | FLoCI |
| Container registry | FLoCI ECR |
| Object storage | FLoCI S3 |
| Release metadata | FLoCI DynamoDB |
| Release events | FLoCI SQS |
| CI/CD | GitLab CI/CD |
| Runner | Local GitLab Shell Runner |
| Kubernetes | Kind |
| GitOps | Argo CD |
| Kubernetes packaging | Helm |
| Security scanning | Trivy |
| Admission control | Kyverno |
| Application framework | FastAPI |
| Metrics endpoint | prometheus-client |
| Mirror repository | GitHub |

---

## Repository Structure

```text
.
├── app/
│   ├── Dockerfile
│   ├── main.py
│   └── requirements.txt
├── argocd/
│   ├── customer-portal-api-dev.yaml
│   └── kyverno-policies.yaml
├── docs/
│   ├── architecture.md
│   └── commands.md
├── helm/
│   └── customer-portal-api/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── deployment.yaml
│           └── service.yaml
├── infra/
│   ├── floci/
│   │   └── compose.yaml
│   └── kind/
│       └── kind-config.yaml
├── scripts/
│   ├── argocd-ui.sh
│   ├── check-resources.sh
│   ├── gitops-rollback.sh
│   ├── project-status.sh
│   ├── push-all.sh
│   ├── smoke-test.sh
│   ├── test-kyverno-policies.sh
│   ├── update-dev-values.sh
│   └── verify-release.sh
├── security/
│   └── kyverno/
│       ├── disallow-latest-tag.yaml
│       ├── disallow-privilege-escalation.yaml
│       ├── require-non-root.yaml
│       └── require-resources.yaml
├── .gitlab-ci.yml
├── .gitignore
└── README.md
```

---

## Application

The sample service is a FastAPI application.

### Endpoints

| Endpoint | Purpose |
|---|---|
| `/` | Application information |
| `/health` | Health check |
| `/ready` | Readiness check |
| `/metrics` | Prometheus metrics |

### Example Response

```json
{
  "service": "customer-portal-api",
  "message": "Running with GitOps + FLoCI",
  "version": "dev-xxxx",
  "environment": "dev",
  "hostname": "customer-portal-api-dev-xxxxx"
}
```

---

## FLoCI Services Used

| FLoCI Service | Usage |
|---|---|
| ECR | Stores Docker images |
| S3 | Stores security reports, Helm rendered manifests, smoke test reports |
| DynamoDB | Stores release metadata and release ledger |
| SQS | Stores release event messages |

---

## GitOps Principles Followed

This project follows GitOps principles:

- Git is the source of truth.
- Kubernetes manifests are generated from Helm and configured through Git.
- CI does not directly deploy the application with `kubectl apply`.
- CI updates GitOps values.
- Argo CD pulls changes from Git and applies them.
- Argo CD self-heals manual cluster drift.
- Rollback is done by changing Git, not by manually patching Kubernetes.

---

## CI/CD Pipeline

The GitLab pipeline contains the following stages:

```text
validate
policy_test
build
scan
publish
evidence
update_gitops
smoke_test
```

### Stage Details

| Stage | Purpose |
|---|---|
| `validate` | Validates FLoCI, Kubernetes, and Helm setup |
| `policy_test` | Runs Kyverno policy validation tests |
| `build` | Builds Docker image |
| `scan` | Runs Trivy scan and security gate |
| `publish` | Pushes image to FLoCI ECR |
| `evidence` | Uploads reports and release evidence to FLoCI S3 |
| `update_gitops` | Updates Helm values with new image tag |
| `smoke_test` | Verifies Argo CD sync, pod health, and app endpoints |

---

## Security Controls

### Trivy Security Gate

The pipeline fails if CRITICAL vulnerabilities are found.

```bash
trivy image --exit-code 1 --severity CRITICAL --ignore-unfixed
```

This ensures vulnerable images are not pushed or deployed.

### Kyverno Admission Policies

Kyverno policies enforce the following controls in the `customer-dev` namespace:

- Images must not use the `latest` tag.
- CPU and memory requests/limits are required.
- Pods must run as non-root.
- Privilege escalation is blocked.

Kyverno policies are managed through Argo CD from:

```text
security/kyverno/
```

---

## Release Evidence

The pipeline uploads release evidence to FLoCI S3.

### Security Reports

```text
s3://floci-security-reports/customer-portal-api/dev/
```

### Helm Rendered Manifests

```text
s3://floci-helm-artifacts/customer-portal-api/dev/
```

### Smoke Test Reports

```text
s3://floci-release-evidence/customer-portal-api/dev/smoke-tests/
```

### Release Verification Reports

```text
s3://floci-release-evidence/customer-portal-api/dev/release-verification/
```

---

## Release Ledger

Each release writes metadata to FLoCI DynamoDB table:

```text
GitOpsReleaseLedger
```

Stored fields include:

- Release ID
- Service name
- Environment
- Image URI
- Image tag
- Commit SHA
- Pipeline ID
- Release status

---

## Release Events

Each successful pipeline sends a release event to FLoCI SQS queue:

```text
gitops-release-events
```

Example event:

```json
{
  "service": "customer-portal-api",
  "env": "dev",
  "image": "localhost:5100/000000000000/us-east-1/customer-portal-api:dev-xxxx",
  "pipeline": "xxxx"
}
```

---

## Prerequisites

Required tools:

```bash
git
docker
aws
helm
kubectl
kind
trivy
gitlab-runner
```

Check tools:

```bash
command -v git
command -v docker
command -v aws
command -v helm
command -v kubectl
command -v kind
command -v trivy
command -v gitlab-runner
```

---

## Start FLoCI

```bash
docker compose -f infra/floci/compose.yaml up -d
```

Set local AWS-compatible variables:

```bash
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
```

Verify:

```bash
aws s3 ls --endpoint-url "$AWS_ENDPOINT_URL"
```

---

## Kind Cluster

Create Kind cluster:

```bash
kind create cluster --name floci-gitops
```

Check:

```bash
kubectl get nodes
```

Configure Kind to pull from FLoCI ECR if required:

```bash
docker exec floci-gitops-control-plane mkdir -p /etc/containerd/certs.d/localhost:5100
```

```bash
cat <<'EOF_KIND_REGISTRY' | docker exec -i floci-gitops-control-plane tee /etc/containerd/certs.d/localhost:5100/hosts.toml
server = "http://localhost:5100"

[host."http://host.docker.internal:5100"]
  capabilities = ["pull", "resolve"]
EOF_KIND_REGISTRY
```

Restart containerd:

```bash
docker exec floci-gitops-control-plane systemctl restart containerd
```

---

## Argo CD

Install Argo CD:

```bash
kubectl create namespace argocd
```

```bash
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Check:

```bash
kubectl get pods -n argocd
```

Apply Argo CD apps:

```bash
kubectl apply -f argocd/customer-portal-api-dev.yaml
kubectl apply -f argocd/kyverno-policies.yaml
```

Check:

```bash
kubectl get applications -n argocd
```

---

## Argo CD Private GitLab Access

If GitLab repo is private, create an Argo CD repository secret using a GitLab token with `read_repository` scope.

```bash
kubectl apply -n argocd -f - <<EOF_ARGO_REPO
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-floci-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://gitlab.com/skcloud2007/floci-gitops-secure-platform.git
  username: skcloud2007
  password: <GITLAB_READ_REPOSITORY_TOKEN>
EOF_ARGO_REPO
```

Refresh the app:

```bash
kubectl annotate application customer-portal-api-dev \
  -n argocd \
  argocd.argoproj.io/refresh=hard \
  --overwrite
```

---

## Argo CD UI

Start local Argo CD UI access:

```bash
./scripts/argocd-ui.sh
```

Open:

```text
https://localhost:8443
```

Username:

```text
admin
```

Get password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

---

## App Access

Port-forward the service:

```bash
kubectl port-forward svc/customer-portal-api-dev 8081:80 -n customer-dev
```

Test:

```bash
curl http://localhost:8081/
curl http://localhost:8081/health
curl http://localhost:8081/ready
curl http://localhost:8081/metrics
```

---

## GitLab Runner

This project uses a local GitLab shell runner because FLoCI runs locally on the Mac.

Start runner:

```bash
gitlab-runner run
```

The runner must use the tag:

```text
floci-local
```

The pipeline must run on this local runner, not GitLab shared runners.

---

## GitLab CI/CD Variable

Add this variable in GitLab:

```text
Settings → CI/CD → Variables
```

Required variable:

| Key | Purpose |
|---|---|
| `GITLAB_PUSH_TOKEN` | Allows pipeline to push updated GitOps values back to GitLab |

The token should have:

```text
read_repository
write_repository
```

---

## Useful Scripts

### Check Local Resources

```bash
./scripts/check-resources.sh
```

### Open Argo CD UI

```bash
./scripts/argocd-ui.sh
```

### Test Kyverno Policies

```bash
./scripts/test-kyverno-policies.sh
```

### Run Smoke Test

```bash
./scripts/smoke-test.sh
```

### Verify Release

```bash
./scripts/verify-release.sh
```

### Full Project Status

```bash
./scripts/project-status.sh
```

### GitOps Rollback

```bash
./scripts/gitops-rollback.sh <previous-image-tag>
```

### Push to GitLab and GitHub

```bash
./scripts/push-all.sh
```

---

## Rollback

Rollback is performed by changing the image tag in Git.

Example:

```bash
./scripts/gitops-rollback.sh dev-previous-tag
```

Then commit and push:

```bash
git add helm/customer-portal-api/values-dev.yaml
git commit -m "Rollback dev to dev-previous-tag"
git push origin main
```

Argo CD detects the Git change and rolls back the deployment.

---

## Self-Healing Test

Delete the deployment manually:

```bash
kubectl delete deployment customer-portal-api-dev -n customer-dev
```

Watch Argo CD restore it:

```bash
kubectl get deploy,pods -n customer-dev -w
```

Check:

```bash
kubectl get application customer-portal-api-dev -n argocd -o wide
```

Expected:

```text
Synced   Healthy
```

---

## Kyverno Policy Test

Run:

```bash
./scripts/test-kyverno-policies.sh
```

Expected:

```text
PASSED: nginx:latest was blocked
PASSED: Pod without resources was blocked
PASSED: Privilege escalation pod was blocked
```

---

## Smoke Test

Run:

```bash
./scripts/smoke-test.sh
```

Expected:

```text
Smoke test completed successfully
```

---

## Verify FLoCI ECR

```bash
aws ecr list-images \
  --repository-name customer-portal-api \
  --endpoint-url http://localhost:4566
```

---

## Verify FLoCI S3 Evidence

```bash
aws s3 ls s3://floci-security-reports/customer-portal-api/dev/ \
  --endpoint-url http://localhost:4566
```

```bash
aws s3 ls s3://floci-helm-artifacts/customer-portal-api/dev/ \
  --endpoint-url http://localhost:4566
```

```bash
aws s3 ls s3://floci-release-evidence/customer-portal-api/dev/ \
  --endpoint-url http://localhost:4566
```

---

## Verify FLoCI DynamoDB

```bash
aws dynamodb scan \
  --table-name GitOpsReleaseLedger \
  --endpoint-url http://localhost:4566
```

---

## Verify FLoCI SQS

```bash
aws sqs list-queues \
  --endpoint-url http://localhost:4566
```

---

## Metrics

The application exposes Prometheus metrics at:

```text
/metrics
```

Test:

```bash
kubectl port-forward svc/customer-portal-api-dev 8081:80 -n customer-dev
curl http://localhost:8081/metrics | head
```

Expected metrics include:

```text
customer_portal_requests_total
customer_portal_app_info
```

---

## Git Remotes

GitLab is the primary source of truth:

```text
origin → GitLab
```

GitHub is a mirror/showcase repository:

```text
github → GitHub
```

Push to GitLab:

```bash
git push origin main
```

Push to GitHub mirror:

```bash
git push github main
```

Push to both:

```bash
./scripts/push-all.sh
```

---

## Final Verification

Run:

```bash
./scripts/project-status.sh
```

Expected:

- FLoCI containers are running.
- FLoCI ECR has application images.
- FLoCI S3 has security and release evidence.
- FLoCI DynamoDB has release records.
- Argo CD applications are synced.
- Customer app pods are running.
- Kyverno policies are active.
- App endpoints are reachable.

---

## Completed Features

- Local FLoCI platform
- FLoCI ECR image registry
- FLoCI S3 evidence storage
- FLoCI DynamoDB release ledger
- FLoCI SQS release event
- GitLab CI/CD pipeline
- Local GitLab shell runner
- Docker image build
- Trivy image scan
- CRITICAL vulnerability gate
- Helm chart deployment
- Argo CD GitOps deployment
- Argo CD self-healing
- Kyverno security policies
- GitOps-managed Kyverno policies
- Smoke test automation
- Release verification script
- Metrics endpoint
- GitHub mirror

---

## Final Delivery Flow

```text
git push origin main
     |
     v
GitLab CI/CD
     |
     v
Build + Scan + Push + Evidence
     |
     v
Update Helm values in Git
     |
     v
Argo CD sync
     |
     v
Kubernetes deployment
     |
     v
Kyverno enforcement
     |
     v
Smoke test
     |
     v
Release verified
```

---

## Project Status

This project is complete as a local production-style GitOps and DevSecOps platform lab using FLoCI.
