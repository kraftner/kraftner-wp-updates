#!/bin/bash

set -euo pipefail

# If the .env file exists the project has already been initialised and we abort.
if [ -f "${PROJECT_DIR}/docker/.env" ]; then
  solum_error_banner "Project has already been initialised. Abort." "If you want to reset run 'clean.sh' first."
  exit 1
fi

# Copy .env file from example, open it in nano…
(cd "${PROJECT_DIR}/docker" && cp .env.example .env && nano .env)
# …and source it
. "${PROJECT_DIR}/docker/.env"

# Sanitize project name and abort if it is invalid
check_projectname && PROJECT_NAME="$COMPOSE_PROJECT_NAME"

# Ensure the mount folders exist.
mkdir -p "${PROJECT_DIR}/wordpress/wp-content/plugins/${PROJECT_NAME}"

# Build image to ensure any config changes are considered
(cd "${PROJECT_DIR}/docker" && docker-compose build --pull)

# Project bootstrap - Plugin File
if [ ! -f "${PROJECT_DIR}/${PROJECT_NAME}.php" ]; then

  # Write plugin file
  printf "<?php\n\n/**\n * Plugin Name: ${PROJECT_NAME}\n * Version: 0.0.1\n*/\n\ndeclare(strict_types=1);\n\n//Happy coding!\n" > "${PROJECT_DIR}/${PROJECT_NAME}.php"

  # If git is available automatically add the created plugin file.
  if command -v git &> /dev/null
  then
    git add "${PROJECT_DIR}/${PROJECT_NAME}.php"
  fi

fi

# Project bootstrap - Composer
if [ ! -f "${PROJECT_DIR}/composer.json" ]; then

  solum_success_banner "No composer.json found. Do you wish to generate one, if yes how?"

  select answer in "Yes, interactively." "No"; do
      case $answer in
          "Yes, interactively." )
           (cd "${PROJECT_DIR}/docker" && docker-compose run --rm wordpress composer init \
            --name "kraftner/${PROJECT_NAME}" \
            --type "wordpress-plugin" \
            --require-dev "inpsyde/php-coding-standards:^1.0.0@stable" \
            --stability "dev" \
            --license "GPL-2.0-or-later")
            # Add scripts for coding standards checks
            ( cd "${PROJECT_DIR}/docker" && docker-compose run --rm wordpress composer config "scripts.lint:php" "phpcs -s --standard="Inpsyde" ./src/ ./${PROJECT_NAME}.php" )
            ( cd "${PROJECT_DIR}/docker" && docker-compose run --rm wordpress composer config "scripts.fix:php" "phpcbf --standard="Inpsyde" ./src/ ./${PROJECT_NAME}.php" )
            ( cd "${PROJECT_DIR}/docker" && docker-compose run --rm wordpress composer config "scripts.pre-release" "@lint:php" )
            ( cd "${PROJECT_DIR}/docker" && docker-compose run --rm wordpress composer config "scripts.plugin-zip" "@pre-release" "@composer install --prefer-dist --no-dev --optimize-autoloader" "rm -rf build" "wp dist-archive . ./${PROJECT_NAME}/build/${PROJECT_NAME}-\$(wp plugin get ${PROJECT_NAME} --field=version).zip --create-target-dir" "@composer install" )
            # If git is available automatically add the created `composer.json` file.
            if command -v git &> /dev/null
            then
              git add "${PROJECT_DIR}/composer.json"
            fi
           break;;
          *)
           break;;
      esac
  done

else

  ( cd "${PROJECT_DIR}/docker" && docker-compose run --rm wordpress composer install )

fi

# Project bootstrap - Packagist
if [ ! -f "${PROJECT_DIR}/package.json" ]; then

  solum_success_banner "No package.json found. Do you wish to generate one, if yes how?"

  select answer in "Yes, interactively." "No"; do
      case $answer in
          "Yes, interactively." )
           ( cd "${PROJECT_DIR}/docker" && docker-compose run --rm build npm init )
           ( cd "${PROJECT_DIR}/docker" && docker-compose run --rm build npm install --save-dev --save-exact @wordpress/scripts )
           # If git is available automatically add the created `package.json` and `package-lock.json` files.
           if command -v git &> /dev/null
           then
             git add "${PROJECT_DIR}/package.json"
             git add "${PROJECT_DIR}/package-lock.json"
           fi
           break;;
          *)
           break;;
      esac
  done

else

  ( cd "${PROJECT_DIR}/docker" && docker-compose run --rm build npm install )

fi

# Manual instructions to update host file
solum_success_banner "You should now add this to the end of your /etc/hosts file:" "#port ${SOLUM_PORT_RANGE_INDEX}x" "127.0.0.1       ${SOLUM_DOMAIN}"
