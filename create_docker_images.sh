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
	echo "  -r, --run       Run created base image for further evaluation"
	echo "      --nginx		Build nginx image"
	exit
}

# fail on error
set -e

source set_env.sh

# config
PUSH_IMAGES=0
FOLLOW_LOGS=0
RUN_BASE=0
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
        -r|--run)
        RUN_BASE=1
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

# check download URL
if curl --output /dev/null --silent --head --fail "$ALPINE_DOWNLOAD_URL"
then
    echo "Using base image from $ALPINE_DOWNLOAD_URL"
else
    echo "Invalid download URL: $ALPINE_DOWNLOAD_URL" >&2
	cd "$CURRENTPATH"
    exit 2
fi

# check for existing image
EXISTING_DOCKER_IMAGE=$(docker images -q "${BASE_IMAGE}:${ALPINE_VERSION}" 2> /dev/null)
if [[ -z "$EXISTING_DOCKER_IMAGE" ]]; then
	# download binaries and create image
	curl -L "$ALPINE_DOWNLOAD_URL" | gunzip | docker import - $BASE_IMAGE
	docker tag  $BASE_IMAGE $BASE_IMAGE:$ALPINE_VERSION
	docker tag  $BASE_IMAGE $BASE_IMAGE:latest
else
	echo "$EXISTING_DOCKER_IMAGE already exists"
fi
if [ $PUSH_IMAGES -ne 0 ]; then
	docker push $BASE_IMAGE:$ALPINE_VERSION
	docker push $BASE_IMAGE:latest
fi

# build and deploy services
if [ -n "$COMPOSE_FILES" ]; then
	docker-compose $COMPOSE_FILES up --build --force-recreate -d
	
	if [ $PUSH_IMAGES -ne 0 ]; then
		for tag in "${PUSH_IMAGE_TAGS[@]}"
		do
	   		docker push $tag
		done
	fi
else
	echo "no dependent services to compose..."
fi

# run base image
if [ $RUN_BASE -ne 0 ]; then
	docker run --rm -it $BASE_IMAGE /bin/sh
fi

# follow logs
if [ -n "$COMPOSE_FILES" -a $FOLLOW_LOGS -ne 0 ];
then
	docker-compose $COMPOSE_FILES logs -f
fi

# get back to where we started
cd "$CURRENTPATH"
