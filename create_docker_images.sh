#! /bin/bash
# remember and change path
CURRENTPATH=$(pwd)
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPTPATH"

# config
set -e
source .env
export DOCKER_BUILDKIT=1
BASE_IMAGE=$DOCKER_ID/$BASE_IMAGE_NAME

# check for existing image
EXISTING_DOCKER_IMAGE=$(docker images -q "${BASE_IMAGE}:${ALPINE_VERSION}" 2> /dev/null)
if [[ -z "$EXISTING_DOCKER_IMAGE" ]]; then
	# download binaries and create image
	curl -L "$ALPINE_DOWNLOAD_URL" | gunzip | docker import - $BASE_IMAGE
	docker tag  $BASE_IMAGE $BASE_IMAGE:$ALPINE_VERSION
	docker tag  $BASE_IMAGE $BASE_IMAGE:latest
	docker run --rm -it $BASE_IMAGE echo -e '\nbuilt successfully\n'

	docker push $BASE_IMAGE:$ALPINE_VERSION
	docker push $BASE_IMAGE:latest
fi

# prepare build vars
export NGINX_MODULES=$(cat nginx-packages.lst | grep "\S" | tr -s '\n' ' ' )

# build and deploy services
docker-compose up --build --force-recreate -d

cd "$CURRENTPATH"

docker-compose logs -f

