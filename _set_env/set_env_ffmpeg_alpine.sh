#! /bin/bash

# disable Harfbuzz for Alpine for now as it breaks ffmpeg build
export FFMPEG_ALPINE_IMAGE="ffmpeg-alpine-$ARCH"
export BUILDING_HARFBUZZ=1
