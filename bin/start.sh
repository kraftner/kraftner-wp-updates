#!/bin/bash

set -euo pipefail

# If the .env file doesn't exist the project hasn't been initialised yet.
check_env_initialised

# Source .env file
. "${PROJECT_DIR}/docker/.env"

# Check if the domain is set up properly
check_hostfile

# Sanitize project name and abort if it is invalid
check_projectname && PROJECT_NAME="$COMPOSE_PROJECT_NAME"

# Ensure the mount folders exist.
mkdir -p "${PROJECT_DIR}/wordpress/wp-content/plugins/${PROJECT_NAME}"

# Build image to ensure any config changes are considered
( cd "${PROJECT_DIR}/docker" && docker-compose build ${1:-} > /dev/null )

# Start all containers in the background
( cd "${PROJECT_DIR}/docker" && docker-compose up --detach ${1:-} )

if ! [[ ${1:-''} =~ ^(|wordpress)$ ]];
then
  solum_warn_banner "You did not start the main »wordpress« container." "If this was unintended run »start wordpress« or just »start«."
  exit 0
fi

# Wait for website to respond
echo -e "${GREEN}----------------------------------------------------------------${NC}"
echo -en "${GREEN} Waiting for container to boot... Checking ${SOLUM_DOMAIN}:${SOLUM_PORT_WEB}.${NC}"
while ! printf "HEAD / HTTP/1.0\r\n\r\n" | nc -i 1 ${SOLUM_DOMAIN} ${SOLUM_PORT_WEB} 2>&1  | grep -qE "HTTP/1.0 200 OK"; do
  echo -en "${GREEN}.${NC}"
  sleep 1
done
echo ""
echo -e "${GREEN}----------------------------------------------------------------${NC}"

solum_success_banner \
  "You can now open the website at" \
  "http://${SOLUM_DOMAIN}:${SOLUM_PORT_WEB}/" \
  "" \
  "Or you can log in" \
  "http://${SOLUM_DOMAIN}:${SOLUM_PORT_WEB}/wp-login.php" \
  "User: wp  |  Password: wp" \
  "" \
  "Or you can open MailHog at" \
  "http://${SOLUM_DOMAIN}:${SOLUM_PORT_RANGE_INDEX}5" \
  "" \
  "Or you can open phpMyAdmin at" \
  "http://${SOLUM_DOMAIN}:${SOLUM_PORT_RANGE_INDEX}6/index.php?route=/database/structure&server=1&db=wordpress" \
