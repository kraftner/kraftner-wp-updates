#!/bin/bash

set -euo pipefail

# If the .env file doesn't exist the project hasn't been initialised yet.
check_env_initialised

# Build image to ensure any config changes are considered
( cd "${PROJECT_DIR}/docker" && docker-compose build "$1" > /dev/null )

# Custom overwrite docker-compose-run.yml for the run command
( cd "${PROJECT_DIR}/docker" && docker-compose -f docker-compose.yml -f docker-compose-run.yml run --rm "$@" )
