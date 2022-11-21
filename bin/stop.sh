#!/bin/bash

set -euo pipefail

( cd "${PROJECT_DIR}/docker" && docker-compose stop ${1:-} )
