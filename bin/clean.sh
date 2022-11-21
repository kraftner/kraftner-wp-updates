#!/bin/bash

set -euo pipefail

SOLUM_OPTION="${1:-}"
if ! [[ "$SOLUM_OPTION" =~ ^(|-a|--all)$ ]];
then
  solum_error "Invalid command »clean $SOLUM_OPTION«. Call »help« for usage instructions."
  exit 1
fi

solum_warn "Removing Docker containers."
# http://redsymbol.net/articles/unofficial-bash-strict-mode/#expect-nonzero-exit-status
(cd "$DOCKER_DIR" && docker-compose down --remove-orphans &> /dev/null) || true

solum_warn "Removing WordPress, all dependencies and build artifacts."
(rm -r "$PROJECT_DIR/build" &> /dev/null || true)
(rm -r "$PROJECT_DIR/node_modules" &> /dev/null || true)
(rm -r "$PROJECT_DIR/vendor" &> /dev/null || true)
(rm -r "$PROJECT_DIR/wordpress" &> /dev/null || true)

if ! [[ "$SOLUM_OPTION" =~ ^(-a|--all)$ ]];
then
  exit 0
fi

# This really only ever needs to be used during development of the boilerplate
# Otherwise you always want to keep those files.
solum_warn "Removing non-default config files. (Option »--all« defined.)"

(rm "$PROJECT_DIR/data/demo-content.xml" &> /dev/null || true)
(rm "$PROJECT_DIR/docker/.env" &> /dev/null || true)
(rm "$PROJECT_DIR/composer.json" &> /dev/null || true)
(rm "$PROJECT_DIR/composer.lock" &> /dev/null || true)
(rm "$PROJECT_DIR/package.json" &> /dev/null || true)
(rm "$PROJECT_DIR/package-lock.json" &> /dev/null || true)

# Since we don't know the name of the plugin file we look for the Plugin header
find "$PROJECT_DIR" -maxdepth 1 -type f -name \*.php -exec \
  grep --ignore-case --quiet "* Plugin Name:" {} \; -print0 \
  | xargs -0 --no-run-if-empty rm
