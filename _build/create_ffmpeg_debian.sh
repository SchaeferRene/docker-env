#! /bin/bash

echo "... ... building ffmpeg_debian"

docker build \
	--build-arg DEBIAN_BASE=$DEBIAN_BASE \
	-t $DOCKER_ID/$(IMG="${FEATURE^^}_IMAGE"; echo -n ""${!IMG}"") "$FEATURE"

echo
