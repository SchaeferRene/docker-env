#! /bin/bash

export FFMPEG_ALPINE_IMAGE="ffmpeg-alpine-$ARCH"

# disable Harfbuzz for Alpine for now as it breaks ffmpeg build
export BUILDING_HARFBUZZ=1
# disable davs2 and xavs2 which do not compile on arm
if [ "$ARCH" = "armv7" ]; then
	export BUILDING_DAVS2=disabled
	export BUILDING_XAVS2=disabled
	export BUILDING_ZIMG=disabled
fi
