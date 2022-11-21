#!/bin/bash

set -euo pipefail

PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." &> /dev/null && pwd )"

. "${PROJECT_DIR}/cli" rebuild

echo "WP version should be 6.0.1 now."

. "${PROJECT_DIR}/cli" wp core version

# Delete Update cache to ensure update check runs in any case.
. "${PROJECT_DIR}/cli" wp transient delete update_core --network

echo "Triggering update."
. "${PROJECT_DIR}/cli" wp cron event run wp_version_check

echo "WP version should be >6.0.1 and <6.1 now."
. "${PROJECT_DIR}/cli" wp core version