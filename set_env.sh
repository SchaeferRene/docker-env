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

## external lists all features that reuse external images
EXTERNAL=(postgres)

## features lists all features that CAN be built in order of dependency (where applicable)
FEATURES=(
	${EXTERNAL[*]}
	base
	ffmpeg_alpine
        ydl

        gitea
	mpd
	nginx
	novnc
)

## common
### current user/group and path
export UUID=$(id -u)
export GUID=$(id -g)

### hostname
export HOSTNAME=$(cat /etc/hostname)

### image names (where different from <feature>-alpine-<arch>
export BASE_IMAGE="alpine-base-$ARCH"
export FFMPEG_ALPINE_RAW_IMAGE="ffmpeg-rawbuild-alpine-$ARCH"
export FFMPEG_ALPINE_IMAGE="ffmpeg-alpine-$ARCH"
export YDL_IMAGE="youtube-dl-alpine-$ARCH"

for FILENAME in _check/check_*.sh; do
	#echo "... ... sourcing $FILENAME"
	source "$FILENAME"
done
