#!/bin/bash

set -eou pipefail

VALUES_FILE="helm/customer-portal-api/values-dev.yaml"

if [ -z "${REPO_URI:-}" ]; then
  echo "ERROR: REPO_URI is empty"
  exit 1
fi

if [ -z "${IMAGE_TAG:-}" ]; then
  echo "ERROR: IMAGE_TAG is empty"
  exit 1
fi

python3 - <<PY
from pathlib import Path

path = Path("${VALUES_FILE}")
text = path.read_text()

lines = text.splitlines()
out = []
selection = None

for line in lines:
  stripped = line.strip()

  if stripped == "image:":
    selection = "image"
    out.append(line)
    continue
  if stripped == "app:":
    selection = "app"
    out.append(line)
    continue

  if line and not line.startswith(" ") and not line.startswith("\\t"):
    selection = None
  
  if selection == "image" and stripped.startswith("repository:"):
    out.append(f"  repository: {REPO_URI}")
  elif selection == "image" and stripped.startswith("tag:"):
    out.append(f"  tag: {IMAGE_TAG}")
  elif selection == "app" and stripped.startswith("version:"):
    out.append(f"  version: {IMAGE_TAG}")
  else:
    out.append(line)
  

path.write_text("\\n".join(out) + "\\n")
PY

echo "Updated ${VALUES_FILE} with REPO_URI=${REPO_URI} and IMAGE_TAG=${IMAGE_TAG}"
grep -A8 '^image:' "${VALUES_FILE}"
grep -A5 '^app:' "${VALUES_FILE}"
