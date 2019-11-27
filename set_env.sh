#! /bin/bash

# read config
source .env

# prepare image names
export ARCH=$(uname -m)
export NGINX_IMAGE="$DOCKER_ID/nginx-alpine-$ALPINE_VERSION-$ARCH:latest"
export BASE_IMAGE="$DOCKER_ID/alpine-base-$ARCH"

# prepare base image download URL
ALPINE_MAJOR_MINOR=$(echo "${ALPINE_VERSION}" | sed -E 's/\.[[:digit:]]+$//')
ALPINE_DOWNLOAD_URL="http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MAJOR_MINOR}/releases/${ARCH}/alpine-minirootfs-${ALPINE_VERSION}-${ARCH}.tar.gz"

# build config
export DOCKER_BUILDKIT=1

# prepare build vars
export NGINX_MODULES=$(cat nginx-packages.lst | grep "\S" | tr -s '\n' ' ' )
