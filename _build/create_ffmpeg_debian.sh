#! /bin/bash

echo "... ... building ffmpeg_debian"

docker build \
	--build-arg DEBIAN_BASE=$DEBIAN_BASE \
	--build-arg BUILDING_HARFBUZZ=$BUILDING_HARFBUZZ \
	-t $DOCKER_ID/$(IMG="${FEATURE^^}_IMAGE"; echo -n ""${!IMG}"") "$FEATURE"

echo
