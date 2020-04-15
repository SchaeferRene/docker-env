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

for FILENAME in _set_env/set_env_*.sh; do
	#echo "... ... sourcing $FILENAME"
	source "$FILENAME"
done
