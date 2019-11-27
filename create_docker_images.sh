#! /bin/bash
# remember and change path
CURRENTPATH=$(pwd)
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPTPATH"

# usage
function usage () {
	echo "usage: $0 [OPTIONS[]"
	echo
	echo "This script generates an alpine base image file and other images based on it and deploys them."
	echo
	echo "Options:"
	echo "  -h, --help		Display help and exit"
	echo "  -p, --push		Push built images to docker registry"
	echo "  -l, --logs		follow logs of built and deployed services"
	echo "      --nginx		Build nginx image"
	exit
}

# fail on error
set -e

# read config
source .env

# prepare image names
export ARCH=$(uname -m)
export NGINX_IMAGE="$DOCKER_ID/nginx-alpine-$ALPINE_VERSION-$ARCH:latest"

# config
PUSH_IMAGES=0
FOLLOW_LOGS=0
COMPOSE_FILES=""
PUSH_IMAGE_TAGS=()

while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        -h|--help)
        usage
        ;;
        -p|--push)
        PUSH_IMAGES=1
        ;;
        -l|--logs)
        FOLLOW_LOGS=1
        ;;
        --nginx)
	    COMPOSE_FILES="$COMPOSE_FILES -f docker-compose-nginx.yml"
	    PUSH_IMAGE_TAGS+=("$NGINX_IMAGE")
        ;;
        *)
        echo "Unknown option '$key'" >&2
        usage
        ;;
    esac
    # Shift after checking all the cases to get the next option
    shift
done

# check permissions
TEST=$(id | grep '(docker)')
if [ -z "$TEST" ]
then
	echo "$USER must belong to docker group" >&2
	cd "$CURRENTPATH"
	exit 2
fi

# prepare base image download URL
ALPINE_MAJOR_MINOR=$(echo "${ALPINE_VERSION}" | sed -E 's/\.[[:digit:]]+$//')
ALPINE_DOWNLOAD_URL="http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MAJOR_MINOR}/releases/${ARCH}/alpine-minirootfs-${ALPINE_VERSION}-${ARCH}.tar.gz"

# check download URL
if curl --output /dev/null --silent --head --fail "$ALPINE_DOWNLOAD_URL"
then
    echo "Using base image from $ALPINE_DOWNLOAD_URL"
else
    echo "Invalid download URL: $ALPINE_DOWNLOAD_URL" >&2
	cd "$CURRENTPATH"
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

	if [ $PUSH_IMAGES ]; then
		docker push $BASE_IMAGE:$ALPINE_VERSION
		docker push $BASE_IMAGE:latest
	fi
else
	echo "$EXISTING_DOCKER_IMAGE already exists"
fi

# prepare build vars
export NGINX_MODULES=$(cat nginx-packages.lst | grep "\S" | tr -s '\n' ' ' )

# build and deploy services
if [ -n "$COMPOSE_FILES" ]; then
	docker-compose $COMPOSE_FILES up --build --force-recreate -d
	
	if [ $PUSH_IMAGES ]; then
		for tag in "${PUSH_IMAGE_TAGS[@]}"
		do
	   		docker push $tag
		done
	fi
else
	echo "no dependent services to compose..."
fi

# get back to where we started
cd "$CURRENTPATH"

# follow logs
if [ -n "$COMPOSE_FILES" -a $FOLLOW_LOGS -ne 0 ];
then
	docker-compose $COMPOSE_FILES logs -f
fi