#!/bin/bash
set -euo pipefail

BRANCH=$(git branch --show-current)

echo "Pushing ${BRANCH} to GitLab origin..."
git push origin "${BRANCH}"

echo "Pushing ${BRANCH} to GitHub mirror..."
git push github "${BRANCH}"

echo "Push completed to both GitLab and GitHub."
