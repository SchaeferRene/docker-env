#! /bin/bash

# prepare base image download URL
export ALPINE_MAJOR_MINOR=$(echo "${ALPINE_VERSION}" | sed -E 's/\.[[:digit:]]+$//')
export ALPINE_DOWNLOAD_URL="http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MAJOR_MINOR}/releases/${ARCH}/alpine-minirootfs-${ALPINE_VERSION}-${ARCH}.tar.gz"

