#!/bin/bash
set -euo pipefail

VALUES_FILE="helm/customer-portal-api/values-dev.yaml"

if [ -z "${REPO_URI:-}" ]; then
  echo "ERROR: REPO_URI is empty"
  exit 1
fi

if [ -z "${IMAGE_TAG:-}" ]; then
  echo "ERROR: IMAGE_TAG is empty"
  exit 1
fi

export VALUES_FILE
export REPO_URI
export IMAGE_TAG

python3 - <<'PY'
import os
from pathlib import Path

values_file = os.environ["VALUES_FILE"]
repo_uri = os.environ["REPO_URI"]
image_tag = os.environ["IMAGE_TAG"]

path = Path(values_file)
text = path.read_text()

lines = text.splitlines()
out = []
section = None

for line in lines:
    stripped = line.strip()

    if stripped == "image:":
        section = "image"
        out.append(line)
        continue

    if stripped == "app:":
        section = "app"
        out.append(line)
        continue

    if line and not line.startswith(" ") and not line.startswith("\t"):
        section = None

    if section == "image" and stripped.startswith("repository:"):
        out.append(f"  repository: {repo_uri}")
    elif section == "image" and stripped.startswith("tag:"):
        out.append(f"  tag: {image_tag}")
    elif section == "app" and stripped.startswith("version:"):
        out.append(f"  version: {image_tag}")
    else:
        out.append(line)

path.write_text("\n".join(out) + "\n")
PY

echo "Updated ${VALUES_FILE}:"
grep -A8 '^image:' "${VALUES_FILE}"
grep -A5 '^app:' "${VALUES_FILE}"
