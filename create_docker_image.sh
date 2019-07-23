#! /bin/bash
# remember and change path
CURRENTPATH=$(pwd)
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPTPATH"

# config
set -e
source build.config
export DOCKER_BUILDKIT=1

# check for existing image
EXISTING_DOCKER_IMAGE=$(docker images -q "${IMAGE_TAG}:${IMAGE_VERSION}" 2> /dev/null)
if [[ -z "$EXISTING_DOCKER_IMAGE" ]]; then
	# download binaries and create image
	curl -L "$ALPINE_DOWNLOAD_URL" | gunzip | docker import - $IMAGE_TAG
	docker tag  $IMAGE_TAG $IMAGE_TAG:$IMAGE_VERSION
	docker tag  $IMAGE_TAG $IMAGE_TAG:latest
	docker run --rm -it $IMAGE_TAG echo -e '\n\nSuccess.\n'

	docker push $IMAGE_TAG:$IMAGE_VERSION
	docker push $IMAGE_TAG:latest
fi

cd "$CURRENTPATH"
