#!/bin/bash

set -euo pipefail

# If the .env file doesn't exist the project hasn't been initialised yet.
check_env_initialised

# Source .env file
. "${PROJECT_DIR}/docker/.env"

# Sanitize project name and abort if it is invalid
check_projectname && PROJECT_NAME="$COMPOSE_PROJECT_NAME"

# Ensure the mount folders exist.
mkdir -p "${PROJECT_DIR}/wordpress/wp-content/plugins/${PROJECT_NAME}"

# Build image to ensure any config changes are considered and  images are up to date
( cd "${PROJECT_DIR}/docker" && docker-compose build --pull )