#!/bin/bash

set -e

# Determine the directory where the script is located.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load variables.
source "${SCRIPT_DIR}/variables.sh"

# Check if there are any '<none>' images.
NONE_IMAGES=$(docker images | grep '<none>' | awk '{ print $3 }')
[ -z "${NONE_IMAGES}" ] && exit 0

# Loop through each image and remove it.
for IMAGE in ${NONE_IMAGES}; do docker rmi "${IMAGE}"; done
