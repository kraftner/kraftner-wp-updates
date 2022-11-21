ARG SOLUM_PHP_VERSION
ARG SOLUM_WP_VERSION
####################################################
# Base image with configurable WP and PHP version. #
####################################################
FROM wordpress:${SOLUM_WP_VERSION}-php${SOLUM_PHP_VERSION}-apache as solum-base

############################################################
# Determine tool versions depending on WP and PHP versions #
############################################################

# Xdebug
# https://xdebug.org/docs/compat#versions
# https://pecl.php.net/package/xdebug

FROM solum-base AS solum-php-7.4
ENV XDEBUG_VERSION=3.1.5

FROM solum-base AS solum-php-8.0
ENV XDEBUG_VERSION=3.1.5

FROM solum-base AS solum-php-8.1
ENV XDEBUG_VERSION=3.1.5

###############
# Final image #
###############
FROM solum-php-${SOLUM_PHP_VERSION}

ARG SOLUM_UID

# Run as other user
# https://github.com/docker-library/docs/blob/master/php/README.md#running-as-an-arbitrary-user
ENV APACHE_RUN_USER wordpress
ENV APACHE_RUN_GROUP wordpress
RUN adduser --uid $SOLUM_UID --gecos '' --disabled-password wordpress \
    && chown -R "$APACHE_RUN_USER:$APACHE_RUN_GROUP" /var/lock/apache2 /var/run/apache2

# Install various packages
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		default-mysql-client \
		git \
		less \
		unzip \
		zip \
	; \
	rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# WP-CLI
COPY --from=wordpress:cli /usr/local/bin/wp /usr/local/bin/wp
ENV PHP_INI_MEMORY_LIMIT 512M
RUN echo 'memory_limit = ${PHP_INI_MEMORY_LIMIT}' > "$PHP_INI_DIR/php.ini"
USER $SOLUM_UID
RUN wp package install wp-cli/dist-archive-command
USER root

# Xdebug
RUN pecl install "xdebug-${XDEBUG_VERSION}" \
    && docker-php-ext-enable xdebug
COPY config/php/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Mailhog / mhsendmail
RUN curl --silent --location --output /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64
RUN chmod +x /usr/local/bin/mhsendmail
COPY config/php/mailhog.ini /usr/local/etc/php/conf.d/mailhog.ini

# Custom Entrypoint
COPY bin/solum-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/solum-entrypoint.sh

USER $SOLUM_UID
ENTRYPOINT ["solum-entrypoint.sh"]
CMD ["apache2-foreground"]