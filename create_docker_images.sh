#! /bin/bash

### Functions
function finish {
	echo -e "\n ... returning to where we started"
	cd "$CURRENTPATH"
	echo -e "\n done\n"
}

# usage
function usage () {
	echo -e "\nusage: $0 [OPTIONS|SERVICES]"
	echo
	echo "This script generates an alpine base image file and other images based on it and deploys them."
	echo
	echo "Options:"
	echo "  -h, --help      Display help and exit"
	echo "  -p, --push      Push built images to docker registry"
	echo "  -a, --all       Build (and push) all services, but only deploy specified"
	echo "  -l, --logs      follow logs of built and deployed services"
	echo "  -r, --run       Run created base image for further evaluation"
	echo "Services:"
	echo "      --gitea     Build gitea image"
	echo "      --mpd       Build mpd image"
	echo "      --nginx     Build nginx image"

	echo -e "\n... exiting"
	
	exit 0
}

### Checks
echo -e "\n... preparing"

# collect features to build (including dependent services)
echo -e "... ... evaluating arguments"
if [ $# -eq 0 ]; then
	usage
fi

# setup script vars
BUILD_ALL=0
PUSH_IMAGES=0
FOLLOW_LOGS=0
RUN_BASE=0
BUILD_FEATURES=()

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
        echo "... ... ... Unknown option '$key'" >&2
        usage
        ;;
    esac
    # Shift after checking all the cases to get the next option
    shift
done

# remember and change path
echo -e "... ... checking directories"
CURRENTPATH=$(pwd)
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
trap finish EXIT
cd "$SCRIPTPATH"

# determine central configuration
echo "... ... loading central configuration"
if [ -f "set_env.sh" ]; then
	source set_env.sh
else
	echo "... ... ... missing set_env.sh" >&2
	exit 1
fi

# warn about features not ready to be built
echo "... ... checking features to be built"
for f in ${BUILD_FEATURES[@]}; do echo "$f"; done | sort | uniq | while read FEATURE; do
	F=$(case "${FEATURES[@]}" in  *"${FEATURE}"*) echo -n "$FEATURE" ;; esac)
	
	if [ -z "$F" ]; then
		echo "... ... ... feature $FEATURE is not prepared to be built!" >&2
		exit 2
	fi
done

# check required programs
echo "... ... checking required programs"
for P in docker docker-compose curl; do
	TEST=$(which $P 2>/dev/null)
	if [ -z "$TEST" ]; then
		echo "... ... ... missing required program $P" >&2
		exit 3
	fi
done

# check permissions
echo "... ... checking permissions"
TEST=$(id | grep '(docker)')
if [ -z "$TEST" ]
then
	echo "... ... ... $USER must belong to docker group" >&2
	exit 4
fi

# check if docker is running
echo "... ... checking docker service"
docker info 2>&1 1>/dev/null
if [ $? -ne 0 ]
then
	echo "... ... ... docker service must be running" >&2
	exit 5
fi

# check download URL
echo "... ... checking Alpine source binaries"
curl --output /dev/null --silent --head --fail "$ALPINE_DOWNLOAD_URL"
if [[ $? -ne 0 ]]; then
	echo "... ... ... Invalid download URL: $ALPINE_DOWNLOAD_URL" >&2
	exit 6
fi

# start building images
echo -e "\n... building base images"

# check for existing image
echo -e "... ... checking existing Alpine base image"
EXISTING_DOCKER_IMAGE=$(docker images -q "${BASE_IMAGE}:${ALPINE_VERSION}" 2> /dev/null)
if [[ -z "$EXISTING_DOCKER_IMAGE" ]]; then
	# download binaries and create image
	echo -e "\n... creating new base image"
	echo -e "... ... building from $ALPINE_DOWNLOAD_URL"
	curl -L "$ALPINE_DOWNLOAD_URL" | gunzip | docker import - $BASE_IMAGE
	echo -e "... ... tagging as $BASE_IMAGE:latest"
	docker tag $BASE_IMAGE $BASE_IMAGE:latest
	echo -e "... ... tagging as $BASE_IMAGE:$ALPINE_VERSION"
	docker tag $BASE_IMAGE $BASE_IMAGE:$ALPINE_VERSION
else
	echo "... ... ... $EXISTING_DOCKER_IMAGE already exists"
fi
if [ $PUSH_IMAGES -ne 0 ]; then
	echo -e "\n... ... pushing $BASE_IMAGE:$ALPINE_VERSION"
	docker push $BASE_IMAGE:$ALPINE_VERSION
	echo -e "\n... ... pushing $BASE_IMAGE:latest"
	docker push $BASE_IMAGE:latest
fi

# TODO: build further base images once required (GUI, HW-Accel, Builder)

# prepare features to build and images to push
echo -e "\n... building features"
for f in ${FEATURES[@]}; do echo "$f"; done | sort | uniq | while read FEATURE; do
	COMPOSE_FILE="docker-compose-${FEATURE}.yml "
	IMAGE_NAME=$(IMG="${FEATURE^^}_IMAGE"; echo -n ""${!IMG}"")
	DEPLOY_FILE=$(case "${BUILD_FEATURES[@]}" in  *"${FEATURE}"*) echo -n "$COMPOSE_FILE" ;; esac)
	
	if test -f $COMPOSE_FILE; then
		if [ $BUILD_ALL -ne 0 -o -n "$DEPLOY_FILE" ]; then
			echo "... ... building $FEATURE"
			docker-compose -f $COMPOSE_FILE build

			echo -e "... ... ... tagging as $IMAGE_NAME:latest"
			docker tag $IMAGE_NAME $IMAGE_NAME:latest
			echo -e "... ... ... tagging as $IMAGE_NAME:$ALPINE_VERSION"
			docker tag $IMAGE_NAME $IMAGE_NAME:$ALPINE_VERSION
			
			if [ $PUSH_IMAGES -ne 0 ]; then
				echo -e "\n... ... ... pushing $IMAGE_NAME:$ALPINE_VERSION"
				docker push $IMAGE_NAME:$ALPINE_VERSION
				echo -e "\n... ... ... pushing $IMAGE_NAME:latest"
				docker push $IMAGE_NAME:latest
			fi
		fi
	else
		echo "... ... missing compose file $COMPOSE_FILE" >&2
		echo -e "... ... skipping\n"
	fi
done

DEPLOY_FILES=$(for f in ${BUILD_FEATURES[@]}; do echo "$f"; done | sort | uniq | while read FEATURE; do echo -n "-f docker-compose-${FEATURE}.yml "; done)

if [ -n "$DEPLOY_FILES" ];
then
	echo -e "\n... deploying ${BUILD_FEATURES[@]}"
	docker-compose $DEPLOY_FILES up -d $DEPLOY_SWITCHES
fi

# run base image
if [ $RUN_BASE -ne 0 ]; then
	echo -e "\n... logging into base image"
	docker run --rm -it $BASE_IMAGE /bin/sh
fi

# follow logs
if [ -n "$DEPLOY_FILES" -a $FOLLOW_LOGS -ne 0 ];
then
	echo -e "\n... following logs"
	docker-compose $COMPOSE_FILES logs -f
fi
