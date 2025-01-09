#!/bin/bash
# shellcheck disable=SC2034

export DOCKER_BUILDKIT=1
export BUILDKIT_PROGRESS=plain

COLUMN_1ST=41
COLUMN_2ND=22
COMPOSER_VERSION=${COMPOSER_VERSION:-2.8.4}

DOCKER_IMAGE='scaffoldeducation/php'
# TODO: Add '8.3.14' and '8.4.2' in next release
# They're not added in this release because of the time constraint
# and because of problem installing imagick in PHP 8.3.
PHP_VERSIONS=('8.0.30' '8.1.31' '8.2.27')
ALPINE_VERSIONS=('3.16' '3.21' '3.21')
TAGS=(dev prod)
