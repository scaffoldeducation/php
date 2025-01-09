#!/bin/bash
# shellcheck disable=SC1091

set -eu

# Determine the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${SCRIPT_DIR}/.."

# Load variables from the variables.sh file
source "${SCRIPT_DIR}/variables.sh"

# Load variables from the variables.sh file
source "${SCRIPT_DIR}/variables.sh"
[ -f "${PROJECT}/.env" ] && source "${PROJECT}/.env"

declare -A settings=(
  [date.timezone]="${PHP_DATE_TIMEZONE:-UTC}"
  [default_socket_timeout]="${PHP_DEFAULT_SOCKET_TIMEOUT:-300}"
  [max_execution_time]="${PHP_MAX_EXECUTION_TIME:-300}"
  [max_input_time]="${PHP_MAX_INPUT_TIME:-300}"
  [max_input_vars]="${PHP_MAX_INPUT_VARS:-10000}"
  [memory_limit]="${PHP_MEMORY_LIMIT:-6G}"
  [post_max_size]="${PHP_POST_MAX_SIZE:-800M}"
  [upload_max_filesize]="${PHP_UPLOAD_MAX_FILESIZE:-500M}"
)

EXT=(
  bcmath       calendar     Core         ctype        curl
  date         dom          exif         FFI          fileinfo
  filter       ftp          gd           hash         iconv
  igbinary     imagick      intl         json         ldap
  libxml       mbstring     mongodb      mysqli       mysqlnd
  openssl      pcntl        pcre         PDO          pdo_mysql
  Phar         posix        readline     redis        Reflection
  session      shmop        SimpleXML    soap         sockets
  sodium       SPL          sqlite3      standard     sysvmsg
  sysvsem      sysvshm      tokenizer    xml          xmlreader
  xmlwriter    xsl          zip          zlib
)

DEV_EXT=("${EXT[@]}" xdebug)
PROD_EXT=("${EXT[@]}" 'Zend OPcache')

check_extensions() {
  printf "\e[90m%s\e[0m\n" "-----------------------------------------------------------------"
  for ext in "${@}"; do
    if echo "${LOADED_EXT}" | grep -qw "${ext}"
      then printf "%-${COLUMN_1ST}s"; _true "${ext}"; ERROR=false
      else printf "%-${COLUMN_1ST}s"; _false "${ext}"; ERROR=true
    fi
  done
  if [[ ${ERROR} == true ]]; then
    _false "Some extensions not loaded"
    exit 1
  fi
}

check_settings() {
  printf "\e[90m%s\e[0m\n" "-----------------------------------------------------------------"
  printf "\e[90m%-24s %-19s\e[0m %-18s\n" "Setting" "Expected" "Current"
  printf "\e[90m%s\e[0m\n" "-----------------------------------------------------------------"
  for key in "${!settings[@]}"; do
    current=$(docker_run "php-fpm -i | grep '${key}' | awk -F'=> ' '{print \$2}' | xargs")
    expected="${settings[$key]}"
    if [ "$current" == "$expected" ]
      then result="\e[1;32m✔\e[0m"; ERROR=false
      else result="\e[1;31m✗\e[0m"; ERROR=true
    fi
    printf "\e[90m%-24s %-19s\e[0m %-18s %b\n" "$key" "$expected" "$current" "$result"
  done
  if [[ ${ERROR} == true ]]; then
    _false "Some settings aren't correct"
    exit 1
  fi
}

msg() {
  printf "\e[90m%-${COLUMN_1ST}s\e[0m" "${1}..."
}

_true() {
  printf "%-${COLUMN_2ND}s \e[1;32m✔\e[0m\n" "${1}"
}

_false() {
  printf "%-${COLUMN_2ND}s \e[1;31m✗\e[0m\n" "${1}"
}

compare() {
  if [ "${1}" == "${2}" ]; then _true "${1}"; else _false "${1}"; return 1; fi
}

docker_run() {
  docker run --rm "${TAG}" sh -c "${1}"
}

run() {
  CMD="${1}" MSG="${2}" CMP="${3}"
  msg "${MSG} ${CMP}"
  compare "$(docker_run "${CMD}")" "${CMP}"
}

echo
echo '--------------------------------------------'
echo 'Scaffold PHP Docker image - Tests'
echo '--------------------------------------------'

for VERSION in "${PHP_VERSIONS[@]}"; do
  read -r MAJOR MINOR PATCH <<< "$(echo "${VERSION}" | tr '.' ' ')"

  for TAG_SUFFIX in "${TAGS[@]}"; do
    TAG="${DOCKER_IMAGE}:${MAJOR}.${MINOR}.${PATCH}-${TAG_SUFFIX}"
    ASUSER=$([[ ${TAG} =~ 'prod' ]] && echo 1002 || echo 1000)
    printf "\n%s\n" "${TAG}"

    run whoami 'It should be user' scaffold
    run 'id | sed -n "s/uid=\([0-9]*\).*/\1/p"' 'It should be UID' "${ASUSER}"
    run 'php -v | sed -n "s/^PHP \([0-9.]\+ (cli)\).*/\1/p"' 'It should be PHP' "${VERSION} (cli)"
    run 'php-fpm -v | sed -n "s/^PHP \([0-9.]\+ (fpm-[^ ]*)\).*/\1/p"' 'It should be PHP' "${VERSION} (fpm-fcgi)"
    run 'composer -V 2>/dev/null | sed -n "s/^Composer version \([0-9]\+\.[0-9]\+\.[0-9]\+\).*/\1/p"' 'It should be Composer' "${COMPOSER_VERSION}"

    if [[ ${TAG} =~ 'nginx' ]]; then
      run 'supervisord version' 'It should be supervisord' 'v0.5'
      run 'nginx -v 2>&1 | sed -n "s/.*nginx\/\([0-9.]*\).*/\1/p"' 'It should be nginx' 1.22.1
    fi

    echo && msg 'Check PHP settings' && echo
    check_settings

    echo && msg 'Check loaded extensions' && echo
    LOADED_EXT=$(docker_run 'php -m')

    if [[ ${TAG} =~ 'dev' ]]; then check_extensions "${DEV_EXT[@]}"; fi
    if [[ ${TAG} =~ 'prod' ]]; then check_extensions "${PROD_EXT[@]}"; fi
  done

  if [[ ${TAG} == 'quality' ]]; then
    run 'phan -v' '' ''
    run 'phpcpd -v' '' ''
    run 'phpcs --version' '' ''
    run 'phpcbf --version' '' ''
    run 'php-cs-fixer -V' '' ''
    run 'phpmd --version' '' ''
    run 'phpstan -V' '' ''
    run 'phpunit --version' '' ''
  fi
done
