#! /bin/bash

echo "... ... building ffmpeg"

docker build \
	--build-arg ARCH=$ARCH \
	--build-arg DOCKER_ID=$DOCKER_ID \
	-t $DOCKER_ID/$(IMG="${FEATURE^^}_IMAGE"; echo -n ""${!IMG}"") "$FEATURE"

echo
