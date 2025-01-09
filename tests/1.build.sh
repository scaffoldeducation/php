#!/bin/bash

set -e

# Determine the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${SCRIPT_DIR}/.."

# Load variables from the variables.sh file
source "${SCRIPT_DIR}/variables.sh"

ARGS=''
# Add no-cache argument if '--no-cache' is provided as a parameter
[ "${1}" == "--no-cache" ] && ARGS+='--no-cache '

# Load build arguments from the .env file if it exists
[ -f "${PROJECT}/.env" ] && while IFS='=' read -r KEY VALUE; do
  [[ "${KEY}" =~ ^#.*$ || -z "${KEY}" ]] && continue
  ARGS+="--build-arg ${KEY}=${VALUE} "
done < "${PROJECT}/.env"

# Create the docker build command
BUILD_CMD="docker build"
# Append additional arguments if available
[[ -n "${ARGS}" ]] && BUILD_CMD+=" ${ARGS}"

# Determine the latest version from the PHP_VERSIONS array
read -r LATEST <<< "$(echo "${PHP_VERSIONS[@]}" | tr ' ' '\n' | sort -V | tail -n1)"

for INDEX in "${!PHP_VERSIONS[@]}"; do
  PHP_VERSION="${PHP_VERSIONS[INDEX]}"
  ALPINE_VERSION="${ALPINE_VERSIONS[INDEX]}"

  # Split the version into major, minor, and patch components
  read -r MAJOR MINOR PATCH <<< "$(echo "${PHP_VERSION}" | tr '.' ' ')"

  for TAG in "${TAGS[@]}"; do
    # Define tags for different levels (patch, minor, major)
    PATCH_TAG="${DOCKER_IMAGE}:${MAJOR}.${MINOR}.${PATCH}-${TAG}"  # e.g.: scaffoldeducation/php:8.0.30-dev
    MINOR_TAG="${DOCKER_IMAGE}:${MAJOR}.${MINOR}-${TAG}"           # e.g.: scaffoldeducation/php:8.0-dev
    MAJOR_TAG="${DOCKER_IMAGE}:${MAJOR}-${TAG}"                    # e.g.: scaffoldeducation/php:8-dev

    # Build the Docker image with the current version and tag
    ${BUILD_CMD} \
      --build-arg PHP_VERSION="${PHP_VERSION}" \
      --build-arg ALPINE_VERSION="${ALPINE_VERSION}" \
      ${XDEBUG_VERSION:+--build-arg XDEBUG_VERSION="${XDEBUG_VERSION}"} \
      -f "${PROJECT}/Dockerfile" \
      -t "${PATCH_TAG}" \
      --target "${TAG}" \
      "${PROJECT}"

    # Tag the built image with the minor version tag
    docker tag "${PATCH_TAG}" "${MINOR_TAG}"

    # Add a tag that resolves to prod image
    if [[ "${TAG}" == "prod" ]]; then
      docker tag "${PATCH_TAG}" "${DOCKER_IMAGE}:${MAJOR}.${MINOR}.${PATCH}"
    fi

    # Tag as the latest if it's the highest version
    if [[ "${PHP_VERSION}" == "${LATEST}" ]]; then
      docker tag "${PATCH_TAG}" "${MAJOR_TAG}"
      docker tag "${PATCH_TAG}" ${DOCKER_IMAGE}:latest
    fi
  done
done
