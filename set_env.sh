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

## external lists all features that reuse external images
EXTERNAL=(postgres)

## features lists all features that CAN be built
FEATURES=(${EXTERNAL[*]})

## common
### current user/group and path
export UUID=$(id -u)
export GUID=$(id -g)

### hostname
export HOSTNAME=$(cat /etc/hostname)

for FILENAME in _check/check_*.sh; do
	#echo "... ... sourcing $FILENAME"
	source "$FILENAME"
done
