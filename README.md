<p align="center">
  <img src="https://github.com/scaffoldeducation/php8/raw/main/.github/docker-php.png" width="198" />
</p>

<h1 align="center">Scaffold Education PHP</h1>

<br>

> Based on [**kooldev/php**](https://github.com/kool-dev/docker-php) docker image  
> _from [Firework Web](https://github.com/fireworkweb)_

<br>

This is a Docker image created on top of [**php** official image](https://hub.docker.com/_/php) running on Alpine. It is a multi-environment/multi-purpose image that has several PHP extensions installed, such as MongoDB and Xdebug for example.
> For complete list of dependencies, see the [**Contents**](#contents) section.

<br>

<!-- TOC -->

- [Usage](#usage)
- [Tags](#tags)
- [Contents](#contents)
  - [Features](#features)
  - [Core](#core)
  - [Libs](#libs)
  - [PHP Extensions](#php-extensions)
  - [Quality Tools](#quality-tools)
- [Development](#development)
- [Vulnerabilities](#vulnerabilities)

<!-- /TOC -->

<br>

## Usage

```Dockerfile
FROM scaffoldeducation/php:latest
FROM scaffoldeducation/php:<TAG>
```

> Notice that `scaffoldeducation/php:latest` will generate the same image as `scaffoldeducation/php:<LATEST_MAJOR>-prod` tag.

<br>

## Tags

<br>

> `Source code at`  
> [**github.com/scaffoldeducation/php**](https://github.com/scaffoldeducation/php)

<br>

- `latest`, `8`, `8-prod`, `8.2`, `8.2-prod`, `8.2.26-prod`
- `8.2-dev`, `8.2.26-dev`
- `8.1`, `8.1-prod`, `8.1.31-prod`
- `8.1-dev`, `8.1.31-dev`
- `8.0`, `8.0-prod`, `8.0.30-prod`
- `8.0-dev`, `8.0.30-dev`

<br>

> **Warning**: It's not recommended to use 8.0 tags due to security vulnerabilities.

> **Note**: We'll add PHP 8.3 and 8.4 in future releases.

<br>

## Contents

<br>

### Features

- Supports JPG, PNG and WebP image formats
- Xdebug for debugging on dev environment
- Support for MongoDB and Redis

<br>

### Core

- Alpine Linux
- php
- composer

<br>

### Libs

- **system**
    ```
    bash
    freetype
    gettext
    ghostscript
    gifsicle
    icu
    imagemagick
    jpegoptim
    less
    libjpeg-turbo
    libldap
    libpng
    libpq
    libzip-dev
    openssh-client
    optipng
    pngquant
    procps
    shadow
    su-exec
    ```

- **dependencies**
    ```
    freetype-dev
    icu-dev
    imagemagick-dev
    libedit-dev
    libjpeg-turbo-dev
    libpng-dev
    libwebp-dev
    libwebp-tools
    libxml2-dev
    linux-headers
    oniguruma-dev
    openldap-dev
    ```

<br>

### PHP Extensions

- **`mysqli`**
- **`mongodb`**
- **`redis`**
- **`xdebug`** (only dev)
- `bcmath`
- `calendar`
- `exif`
- `gd`
- `imagick`
- `intl`
- `ldap`
- `mbstring`
- `opcache` (only prod)
- `pcntl`
- `pdo`
- `pdo_mysql`
- `soap`
- `sockets`
- `xml`
- `zip`

<br>

### Quality Tools

- **`phan`** `5.4.2`
- **`phpcpd`** `6.0.3`
- **`phpcs`** `3.7.2`
- **`php-cs-fixer`** `3.40.0`
- **`phpmd`** `2.14.1`
- **`phpstan`** `1.10.45`
- **`phpunit`** `9.6.13`

<br>

## Development

To include new features or fix some bugs, you can create a PR of your changes to this repository. You can test your changes locally with:

```sh
tests/pipeline.sh
```

in the root of the project. It'll run many build and test steps for each version. You can also run these scripts manually and independently. The pipeline script creates logs in `logs/pipeline.log` file.

<br>

## Vulnerabilities

The images are checked for vulnerabilities with `trivy` and `grype`:
```sh
trivy image scaffoldeducation/php:8.2.27-prod --scanners vuln
2025-01-10T18:58:20-03:00	INFO	[vuln] Vulnerability scanning is enabled
2025-01-10T18:58:20-03:00	INFO	Detected OS	family="alpine" version="3.21.2"
2025-01-10T18:58:20-03:00	WARN	This OS version is not on the EOL list	family="alpine" version="3.21"
2025-01-10T18:58:20-03:00	INFO	[alpine] Detecting vulnerabilities...	os_version="3.21" repository="3.21" pkg_num=140
2025-01-10T18:58:20-03:00	INFO	Number of language-specific files	num=0

scaffoldeducation/php:8.2.27-prod (alpine 3.21.2)

Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)
```

<br>
