#!/bin/bash

set -e

# Determine the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Redirect all logs to pipeline.log
exec > "${SCRIPT_DIR}/../pipeline.log" 2>&1

# Array of script names to be executed
scripts=(
  "1.build.sh"
  "2.run.sh"
  "3.security.sh"
  "4.remove-dangling.sh"
  "5.list.sh"
)

for script in "${scripts[@]}"; do "${SCRIPT_DIR}/${script}" || exit 1; done
