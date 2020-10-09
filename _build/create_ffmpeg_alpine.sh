#! /bin/bash

echo "... ... ... building ffmpeg_alpine"

docker build \
	--build-arg ARCH=$ARCH \
	--build-arg DOCKER_ID=$DOCKER_ID \
	--build-arg BUILDING_HARFBUZZ=$BUILDING_HARFBUZZ \
	-t $DOCKER_ID/$(IMG="${FEATURE^^}_IMAGE"; echo -n ""${!IMG}"") "$FEATURE"

echo
