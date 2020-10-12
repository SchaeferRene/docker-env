#! /bin/bash

# determine Debian base image
DEBIAN_BASE="debian:$DEBIAN_VERSION"
if [ "$ARCH" = "armv7" ]; then
	DEBIAN_BASE="arm32v7/$DEBIAN_BASE";
	BUILDING_DAVS2=1
elif [ "$ARCH" = "aarch64" ]; then
	DEBIAN_BASE="arm64v8/$DEBIAN_BASE";
fi

export DEBIAN_BASE
export FFMPEG_DEBIAN_IMAGE="ffmpeg-debian-$ARCH"

# disable Harfbuzz for Debian for now as it seems unstable
export BUILDING_HARFBUZZ=1
