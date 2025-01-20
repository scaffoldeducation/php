# Prepare builder image.
# ------------------------------------------------------------------------------
ARG PHP_VERSION=8.3.14 ALPINE_VERSION=3.20 COMPOSER_VERSION=2.8.4

FROM composer:${COMPOSER_VERSION} AS composer
FROM php:${PHP_VERSION}-fpm-alpine${ALPINE_VERSION} AS builder

ARG ASUSER=1000 USERNAME=scaffold ENV_NAME=development PHP_VERSION=${PHP_VERSION} \
  IGBINARY_VERSION=3.2.16 IMAGICK_VERSION=3.7.0 MONGODB_VERSION=1.17.0 REDIS_VERSION=6.1.0 XDEBUG_VERSION=3.2.2 \
  PHP_DATE_TIMEZONE=UTC PHP_DEFAULT_SOCKET_TIMEOUT=300 PHP_FPM_LISTEN=9000 PHP_FPM_MAX_CHILDREN=10 \
  PHP_FPM_REQUEST_TERMINATE_TIMEOUT=300 PHP_INI_DIR=/usr/local/etc/php PHP_MAX_EXECUTION_TIME=300 \
  PHP_MAX_INPUT_TIME=300 PHP_MAX_INPUT_VARS=10000 PHP_MEMORY_LIMIT=6G PHP_POST_MAX_SIZE=800M PHP_UPLOAD_MAX_FILESIZE=500M  \
  DEPS='bash gettext libcurl openssl sqlite-libs su-exec' \
  BUILD_DEPS="${PHPIZE_DEPS}" \
  DEL_DEPS='curl openssl tar xz' \
  CLEANUP_PATHS="${PHP_INI_DIR}/php.ini-* /root/.cache /tmp/* /usr/lib/libx265.so.199 /usr/local/lib/php/.channels /usr/local/lib/php/.depdb* /usr/local/lib/php/.depdblock* /usr/local/lib/php/.filemap /usr/local/lib/php/.lock /usr/local/lib/php/.registry /usr/local/lib/php/doc /usr/local/lib/php/test /usr/src/* /var/cache/apk/* /var/log/* /var/tmp/*"

# It makes possible to override the default values when running the container.
ENV ASUSER=${ASUSER} COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_MEMORY_LIMIT=-1 OPCACHE_ENABLE=0 \
  PHP_DATE_TIMEZONE=${PHP_DATE_TIMEZONE} PHP_DEFAULT_SOCKET_TIMEOUT=${PHP_DEFAULT_SOCKET_TIMEOUT} PHP_FPM_LISTEN=${PHP_FPM_LISTEN} \
  PHP_FPM_MAX_CHILDREN=${PHP_FPM_MAX_CHILDREN} PHP_FPM_REQUEST_TERMINATE_TIMEOUT=${PHP_FPM_REQUEST_TERMINATE_TIMEOUT} \
  PHP_INI_DIR=/usr/local/etc/php PHP_MAX_EXECUTION_TIME=${PHP_MAX_EXECUTION_TIME} PHP_MAX_INPUT_TIME=${PHP_MAX_INPUT_TIME} \
  PHP_MAX_INPUT_VARS=${PHP_MAX_INPUT_VARS} PHP_MEMORY_LIMIT=${PHP_MEMORY_LIMIT} PHP_POST_MAX_SIZE=${PHP_POST_MAX_SIZE} \
  PHP_UPLOAD_MAX_FILESIZE=${PHP_UPLOAD_MAX_FILESIZE} XDEBUG_ENABLE=true XDEBUG_CONFIG='client_host=192.168.15.20' XDEBUG_MODE=debug

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer /usr/bin/composer /usr/local/bin/
EXPOSE ${PHP_FPM_LISTEN}
HEALTHCHECK --start-period=1s CMD nc -zv 127.0.0.1 ${PHP_FPM_LISTEN} || exit 1

# Create dev image.
# ------------------------------------------------------------------------------
FROM builder AS dev
ARG PHP_EXTENSIONS="bcmath calendar exif ffi gd intl ldap mbstring mysqli pcntl pdo pdo_mysql shmop soap sockets sysvmsg sysvsem sysvshm xml xsl zip igbinary-${IGBINARY_VERSION} imagick/imagick@28f27044e435a2b203e32675e942eb8de620ee58 mongodb-${MONGODB_VERSION} redis-${REDIS_VERSION} xdebug-${XDEBUG_VERSION}"
WORKDIR /app
RUN set -x && apk add --no-cache --no-scripts -uUl ${DEPS} && apk add --no-cache --no-scripts -uUl -t .build-deps ${BUILD_DEPS} \
  && mv ${PHP_INI_DIR}/php.ini-${ENV_NAME} ${PHP_INI_DIR}/php.ini || true \
  && install-php-extensions ${PHP_EXTENSIONS} 1>/dev/null 2>&1 \
  && adduser ${USERNAME} -HDu ${ASUSER} -s /bin/bash \
  && addgroup ${USERNAME} www-data \
  && apk del --no-cache --purge .build-deps ${DEL_DEPS} \
  && rm -rf ${CLEANUP_PATHS}
COPY --chmod=755 entrypoint scaffold.ini xdebug.ini zz-php-fpm.conf /scaffold/
ENTRYPOINT ["/scaffold/entrypoint"]
CMD ["php-fpm"]

# Create prod image.
# ------------------------------------------------------------------------------
FROM builder AS prod
ARG ASUSER=1002 ENV_NAME=production PHP_EXTENSIONS="bcmath calendar exif ffi gd intl ldap mbstring mysqli opcache pcntl pdo pdo_mysql shmop soap sockets sysvmsg sysvsem sysvshm xml xsl zip igbinary-${IGBINARY_VERSION} imagick/imagick@28f27044e435a2b203e32675e942eb8de620ee58 mongodb-${MONGODB_VERSION} redis-${REDIS_VERSION}"
ENV ASUSER=${ASUSER} ENV_NAME=${ENV_NAME} OPCACHE_ENABLE=1
WORKDIR /app
RUN set -x && apk add --no-cache --no-scripts -uUl ${DEPS} && apk add --no-cache --no-scripts -uUl -t .build-deps ${BUILD_DEPS} \
  && mv ${PHP_INI_DIR}/php.ini-${ENV_NAME} ${PHP_INI_DIR}/php.ini \
  && install-php-extensions ${PHP_EXTENSIONS} 1>/dev/null 2>&1 \
  && adduser ${USERNAME} -HDu ${ASUSER} -s /bin/bash \
  && addgroup ${USERNAME} www-data \
  && apk del --no-cache --purge .build-deps ${DEL_DEPS} \
  && rm -rf ${CLEANUP_PATHS}
COPY --chmod=755 entrypoint scaffold.ini zz-php-fpm.conf /scaffold/
ENTRYPOINT ["/scaffold/entrypoint"]
CMD ["php-fpm"]
