#!/bin/bash

set -e

# Determine the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load variables from the variables.sh file
source "${SCRIPT_DIR}/variables.sh"

# Delete possible '<none>' images before listing this project images.
NONE_IMAGES=$(docker images | grep '<none>' | awk '{ print $3 }')
[ -n "${NONE_IMAGES}" ] && eval "docker rmi ${NONE_IMAGES}"

# List repository, tag and size of the images of this project.
docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}' | grep "${DOCKER_IMAGE}:" | sort
