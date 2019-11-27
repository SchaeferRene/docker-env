#! /bin/bash
# check permissions
TEST=$(id | grep '(docker)')
if [ -z "$TEST" ]
then
	echo "$USER must belong to docker group" >&2
	exit 2
fi

# remember and change path
CURRENTPATH=$(pwd)
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPTPATH"

# config
# fail on error
set -e

# read config
source .env

# prepare base image download URL
export ARCH=$(uname -m)
ALPINE_MAJOR_MINOR=$(echo "${ALPINE_VERSION}" | sed -E 's/\.[[:digit:]]+$//')
ALPINE_DOWNLOAD_URL="http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MAJOR_MINOR}/releases/${ARCH}/alpine-minirootfs-${ALPINE_VERSION}-${ARCH}.tar.gz"

# check download URL
if curl --output /dev/null --silent --head --fail "$ALPINE_DOWNLOAD_URL"
then
    echo "Using base image from $ALPINE_DOWNLOAD_URL"
else
    echo "Invalid download URL: $ALPINE_DOWNLOAD_URL" >&2
    exit 2
fi

export DOCKER_BUILDKIT=1
export BASE_IMAGE="$DOCKER_ID/alpine-base-$ARCH"

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
else
	echo "$EXISTING_DOCKER_IMAGE already exists"
fi

# prepare build vars
export NGINX_MODULES=$(cat nginx-packages.lst | grep "\S" | tr -s '\n' ' ' )

# build and deploy services
# TODO: add command line parameters
docker-compose \
	-f docker-compose-nginx.yml \
	up --build --force-recreate -d

# get back to where we started
cd "$CURRENTPATH"

exit

# follow logs
docker-compose logs -f
