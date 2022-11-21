#!/bin/bash

set -euo pipefail

function check_hostfile() {

  . "${PROJECT_DIR}/docker/.env"

  if ! grep -qE "${SOLUM_DOMAIN}" /etc/hosts; then
    solum_error_banner "You need to add this to the end of your /etc/hosts file:" "#port ${SOLUM_PORT_RANGE_INDEX}x" "127.0.0.1       ${SOLUM_DOMAIN}"
    exit 1
  fi

}

function check_projectname() {

  . "${PROJECT_DIR}/docker/.env"

  PROJECT_NAME=$(echo "$COMPOSE_PROJECT_NAME" | sed -e 's/[^A-Za-z0-9._-]/_/g')

  if test $PROJECT_NAME != $COMPOSE_PROJECT_NAME; then
    solum_error_banner "Your project name »$COMPOSE_PROJECT_NAME« is invalid." "It can only have alphanumeric characters."
    exit 1
  fi

}

function check_env_initialised() {

    if [ ! -f "${PROJECT_DIR}/docker/.env" ]; then
      solum_error_banner "The project hasn't been initialised yet. Please run »init« first."
      exit 1
    fi

}

export -f check_hostfile check_projectname check_env_initialised