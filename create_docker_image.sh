#! /bin/bash

# config - see https://alpinelinux.org/downloads/ for suitable binaries
DOWNLOAD_URL=http://dl-cdn.alpinelinux.org/alpine/v3.10/releases/armv7/alpine-minirootfs-3.10.1-armv7.tar.gz
DEFAULT_DOCKER_TAG=armv7lxu4/alpine-base-armv7
TAG_VERSION=3.10.1

# download binaries and create image
curl -L "$DOWNLOAD_URL" | gunzip | docker import - $DEFAULT_DOCKER_TAG
docker tag  $DEFAULT_DOCKER_TAG $DEFAULT_DOCKER_TAG:$TAG_VERSION
docker run --rm -it $DEFAULT_DOCKER_TAG echo -e '\n\nSuccess.\n'

docker push $DEFAULT_DOCKER_TAG $DEFAULT_DOCKER_TAG:$TAG_VERSION

