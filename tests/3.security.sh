#!/bin/bash

set -e

# Determine the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load variables from the variables.sh file
source "${SCRIPT_DIR}/variables.sh"

for VERSION in "${PHP_VERSIONS[@]}"; do
  read -r MAJOR MINOR PATCH <<< "$(echo "${VERSION}" | tr '.' ' ')"

  for TAG in "${TAGS[@]}"; do
    PATCH_TAG="${MAJOR}.${MINOR}.${PATCH}-${TAG}"  # e.g.: scaffoldeducation/php:8.0.30-nginx-dev
    trivy image "${DOCKER_IMAGE}:${PATCH_TAG}" --scanners vuln,secret,misconfig
    grype "${DOCKER_IMAGE}:${PATCH_TAG}" --only-fixed
  done
done
