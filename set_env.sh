#! /bin/bash

# read config
source .env

# prepare image names
export DOCKER_ID
export ALPINE_VERSION
export ARCH=$(uname -m)
if [ "$ARCH" = "armv7l" ]; then export ARCH="armv7"; fi

export BASE_IMAGE="alpine-base-$ARCH"
export GITEA_IMAGE="gitea-alpine-$ARCH"
export MPD_IMAGE="mpd-alpine-$ARCH"
export NGINX_IMAGE="nginx-alpine-$ARCH"
export YDL_IMAGE="youtube-dl-alpine-$ARCH"

# prepare base image download URL
ALPINE_MAJOR_MINOR=$(echo "${ALPINE_VERSION}" | sed -E 's/\.[[:digit:]]+$//')
ALPINE_DOWNLOAD_URL="http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MAJOR_MINOR}/releases/${ARCH}/alpine-minirootfs-${ALPINE_VERSION}-${ARCH}.tar.gz"

# build config
export DOCKER_BUILDKIT=1

# prepare build vars
FEATURES=(ydl)

## common - current user/group and path
export GUID=$(id -g)

## nginx
if [ -f nginx-packages.lst ]; then
	export NGINX_MODULES=$(cat nginx-packages.lst | grep "\S" | tr -s '\n' ' ' )
	FEATURES+=(nginx)
fi

## mpd
if [ -e "$PULSE_SOCKET" ]; then
	export PULSE_UUID=$(stat -c %u "$PULSE_SOCKET" 2>/dev/null)
	export PULSE_GUID=$(stat -c %g "$PULSE_SOCKET" 2>/dev/null)
	FEATURES+=(mpd)
else
	export PULSE_UUID=$UID
	export PULSE_GUID=$(id -g)
	FEATURES+=(mpd)
fi

