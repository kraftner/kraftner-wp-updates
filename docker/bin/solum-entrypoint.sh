#!/bin/bash
# Exit on any error
set -e

# Setup colors
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

function await_database_connections() {
    for i in {1..15}
    do
        if wp db check --silent >/dev/null 2>&1
        then
            echo -e "${GREEN}DB ready.${NC}"
            break
        fi

        if test $i -eq 1
        then
            echo -e "${GREEN}Waiting for up to 15 seconds for DB to be ready.${NC}"
        fi

        sleep 1
        echo -n "."

        if test $i -eq 15
        then
            echo -e " ${RED}Timed out waiting for database.${NC}"
            exit 1
        fi
    done
}

# Only bootstrap if apache is launched
if [[ "$1" == apache2* ]] ; then

  # This is sneaky. By using -v it still triggers the if in docker-entrypoint.sh, downloading WP but doesn't start apache
  docker-entrypoint.sh apache2 -v > /dev/null

  # Wait for DB to be ready
  await_database_connections

  # Install Composer dependencies if they do not exist
  if [ -f "/var/www/html/wp-content/plugins/${COMPOSE_PROJECT_NAME}/composer.json" ]; then
    if [ ! -f "/var/www/html/wp-content/plugins/${COMPOSE_PROJECT_NAME}/vendor/autoload.php" ]; then
      (cd "/var/www/html/wp-content/plugins/${COMPOSE_PROJECT_NAME}" && composer install)
    fi
  fi

  # Bootstrap the site if not installed yet
  if ! wp core is-installed;
  then
      if [[ "${SOLUM_PORT_WEB}" == "80" ]] ; then
          SOLUM_ENTRYPOINT_URL="${SOLUM_DOMAIN}"
        else
          SOLUM_ENTRYPOINT_URL="${SOLUM_DOMAIN}:${SOLUM_PORT_WEB}"
      fi
      wp core install \
        --title="${COMPOSE_PROJECT_NAME}" \
        --admin_user="wp" \
        --admin_password="wp" \
        --url="$SOLUM_ENTRYPOINT_URL" \
        --admin_email="wp@local.test" \
        --skip-email
      wp plugin activate "${COMPOSE_PROJECT_NAME}"
      # The next 8 lines are opinionated and can be removed if not needed.
      wp language core install de_DE
      wp site switch-language de_DE
      wp option update timezone_string "Europe/Vienna"
      wp plugin delete akismet hello
      wp plugin install query-monitor --activate
      wp plugin install user-switching --activate
      wp option update permalink_structure "/%postname%/" --quiet
      wp rewrite flush --hard  --quiet

      if [ -f "/var/www/html/wp-content/plugins/${COMPOSE_PROJECT_NAME}/data/demo-content.xml" ]; then
        echo -e "${GREEN}---------------------------------- ${NC}"
        echo -e "${GREEN} Demo content found. Importing it. ${NC}"
        echo -e "${GREEN}-----------------------------------${NC}"
        wp plugin install wordpress-importer --activate
        wp import "/var/www/html/wp-content/plugins/${COMPOSE_PROJECT_NAME}/data/demo-content.xml" --authors=create
      fi

  fi
fi

cd "/var/www/html/wp-content/plugins/${COMPOSE_PROJECT_NAME}"

exec "$@"