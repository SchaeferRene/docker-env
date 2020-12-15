#! /bin/bash

# read config
source .env

# prepare image names
ARCH=$(uname -m)
if [ "$ARCH" = "armv7l" ]; then
	ARCH="armv7";
fi

# build config
export DOCKER_BUILDKIT=1

## prepare build vars
export PULSE_SOCKET

# base images holds all images that are considered base images
# i.e. image layers to base other images on, hence must be built first
BASE_IMAGES=(
	base
	ffmpeg_alpine
	novnc
)
## features lists all features that CAN be built
FEATURES=()

## common - current user/group and path
UUID=$(id -u)
GUID=$(id -g)

for FILENAME in _check/check_*.sh; do
	#echo "... ... sourcing $FILENAME"
	source "$FILENAME"
done
