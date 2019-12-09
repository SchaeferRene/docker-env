#! /bin/bash

# read config
source .env

# prepare image names
export ARCH=$(uname -m)
export BASE_IMAGE="$DOCKER_ID/alpine-base-$ARCH"

export GITEA_IMAGE="$DOCKER_ID/gitea-alpine-$ALPINE_VERSION-$ARCH"
export MPD_IMAGE="$DOCKER_ID/mpd-alpine-$ALPINE_VERSION-$ARCH"
export NGINX_IMAGE="$DOCKER_ID/nginx-alpine-$ALPINE_VERSION-$ARCH"

# prepare base image download URL
ALPINE_MAJOR_MINOR=$(echo "${ALPINE_VERSION}" | sed -E 's/\.[[:digit:]]+$//')
ALPINE_DOWNLOAD_URL="http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MAJOR_MINOR}/releases/${ARCH}/alpine-minirootfs-${ALPINE_VERSION}-${ARCH}.tar.gz"

# build config
export DOCKER_BUILDKIT=1

# prepare build vars
## nginx
export NGINX_MODULES=$(cat nginx-packages.lst | grep "\S" | tr -s '\n' ' ' )

## mpd
if [ -e "$PULSE_SOCKET" ]; then
	export PULSE_UUID=$(stat -c %u "$PULSE_SOCKET" 2>/dev/null)
	export PULSE_GUID=$(stat -c %g "$PULSE_SOCKET" 2>/dev/null)
fi
