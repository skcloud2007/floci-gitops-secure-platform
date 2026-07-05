#!/bin/bash
set -euo pipefail

VALUES_FILE="helm/customer-portal-api/values-dev.yaml"

if [ $# -ne 1 ]; then
  echo "Usage: $0 <previous-image-tag>"
  echo
  echo "Example:"
  echo "  $0 dev-2653000824-ae05ebd6"
  exit 1
fi

ROLLBACK_TAG="$1"

echo "Rolling back customer-portal-api dev to image tag: ${ROLLBACK_TAG}"

python3 - <<PY
from pathlib import Path

path = Path("${VALUES_FILE}")
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

    if line and not line.startswith(" ") and not line.startswith("\\t"):
        section = None

    if section == "image" and stripped.startswith("tag:"):
        out.append("  tag: ${ROLLBACK_TAG}")
    elif section == "app" and stripped.startswith("version:"):
        out.append("  version: ${ROLLBACK_TAG}")
    else:
        out.append(line)

path.write_text("\\n".join(out) + "\\n")
PY

echo "Updated rollback values:"
grep -A8 '^image:' "${VALUES_FILE}"
grep -A5 '^app:' "${VALUES_FILE}"
