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
	echo "  -h, --help      Display help and exit"
	echo "  -p, --push      Push built images to docker registry"
	echo "  -a, --all       Build (and push) all services, but only deploy specified"
	echo "  -l, --logs      follow logs of built and deployed services"
	echo "  -r, --run       Run created base image for further evaluation"
	echo "      --gitea     Build gitea image"
	echo "      --mpd       Build mpd image"
	echo "      --nginx     Build nginx image"
	exit
}

# fail on error
set -e

# determine central configuration
source set_env.sh

# setup script vars
BUILD_ALL=0
PUSH_IMAGES=0
FOLLOW_LOGS=0
RUN_BASE=0

# collect features to build (including dependent services)
BUILD_FEATURES=()

if [ $# -eq 0 ]; then
	usage
fi

while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        -h|--help)
        usage
        ;;
        -a|--all)
        BUILD_ALL=1
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
#        --gitea)
#        BUILD_FEATURES+=("gitea")
#        ;;
        --mpd)
        BUILD_FEATURES+=("mpd")
        ;;
        --nginx)
        BUILD_FEATURES+=("nginx")
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
	exit 1
fi

# check download URL
echo "Trying to download base image from $ALPINE_DOWNLOAD_URL"
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
else
	echo "$EXISTING_DOCKER_IMAGE already exists"
fi
if [ $PUSH_IMAGES -ne 0 ]; then
	docker push $BASE_IMAGE:$ALPINE_VERSION
	docker push $BASE_IMAGE:latest
fi

# warn about features not ready to be built
for f in ${BUILD_FEATURES[@]}; do echo "$f"; done | sort | uniq | while read FEATURE; do
	echo "$FEATURE"
	F=$(case "${FEATURES[@]}" in  *"${FEATURE}"*) echo -n "$FEATURE" ;; esac)
	
	if [ -z "$F" ]; then
		echo "feature $FEATURE is not prepared to be built! (see README.md)" >&2
		exit 3
	fi
done

# prepare features to build and images to push
for f in ${FEATURES[@]}; do echo "$f"; done | sort | uniq | while read FEATURE; do
	COMPOSE_FILE="docker-compose-${FEATURE}.yml "
	IMAGE_NAME=$(IMG="${FEATURE^^}_IMAGE"; echo -n ""${!IMG}"")
	DEPLOY_FILE=$(case "${BUILD_FEATURES[@]}" in  *"${FEATURE}"*) echo -n "$COMPOSE_FILE" ;; esac)
	
	if test -f $COMPOSE_FILE; then
		if [ $BUILD_ALL -ne 0 -o -n "$DEPLOY_FILE" ]; then
			docker-compose -f $COMPOSE_FILE build
			docker tag  $IMAGE_NAME $IMAGE_NAME:$ALPINE_VERSION
			
			if [ $PUSH_IMAGES -ne 0 ]; then
				docker push $IMAGE_NAME:$ALPINE_VERSION
				docker push $IMAGE_NAME:latest
			fi
			#if [ -n "$DEPLOY_FILE" ]; then
			#	docker-compose $DEPLOY_FILE up -d
			#fi
		fi
	fi
done

DEPLOY_FILES=$(for f in ${BUILD_FEATURES[@]}; do echo "$f"; done | sort | uniq | while read FEATURE; do echo -n "-f docker-compose-${FEATURE}.yml "; done)

if [ -n "$DEPLOY_FILES" ];
then
	docker-compose -$DEPLOY_FILES up -d $DEPLOY_SWITCHES
fi

# run base image
if [ $RUN_BASE -ne 0 ]; then
	docker run --rm -it $BASE_IMAGE /bin/sh
fi

# follow logs
if [ -n "$DEPLOY_FILES" -a $FOLLOW_LOGS -ne 0 ];
then
	docker-compose $COMPOSE_FILES logs -f
fi

# get back to where we started
cd "$CURRENTPATH"
