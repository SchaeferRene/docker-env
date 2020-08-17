#! /bin/bash

### Functions
function finish {
	echo -e "\n... returning to where we started"
	cd "$CURRENTPATH"
	echo -e "\ndone\n"
}

# usage
function usage {
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
	echo "      --ffmpeg    Build ffmpeg image"
	#echo "      --gitea     Build gitea image"
	echo "      --mpd       Build mpd image"
	echo "      --nginx     Build nginx image"
	echo "      --privoxy   Build privoxy image"
	echo "      --ydl, --youtube-dl"
	echo "                  Build youtube-dl image"

	echo -e "\n... exiting"
	
	exit 0
}

function build_image {
	FEATURE=$1
	
	COMPOSE_FILE="docker-compose-${FEATURE}.yml"
	SCRIPT_FILE="./_build/create_${FEATURE}.sh"
	DOCKER_FILE="${FEATURE}/Dockerfile"
	
	IS_BASE_FEATURE=$(case "${BASE_IMAGES[@]}" in  *"${FEATURE}"*) echo -n "BASE" ;; esac)
	IS_REQUESTED_FEATURE=$(case "${BUILD_IMAGES[@]}" in  *"${FEATURE}"*) echo -n "REQUESTED" ;; esac)
	
	if [ $IS_BUILD_ALL -eq 0 -o -n "$IS_REQUESTED_FEATURE$IS_BASE_FEATURE" ]; then
		if [ -f $COMPOSE_FILE ]; then
			echo "... ... composing $FEATURE"
			docker-compose -f $COMPOSE_FILE build
	
			tag_image "$FEATURE"
			
			DEPLOY_IMAGES+=("$COMPOSE_FILE")
		elif [ -x "$SCRIPT_FILE" ]; then
			echo "... ... triggering $SCRIPT_FILE"
			
			source "$SCRIPT_FILE"
			
			tag_image "$FEATURE"
		elif [ -r "$DOCKER_FILE" ]; then
			echo "... ... building $FEATURE"
			
			docker build \
				--pull \
				--no-cache \
				--build-arg ARCH=$ARCH \
				--build-arg DOCKER_ID=$DOCKER_ID \
				-t $DOCKER_ID/$(IMG="${FEATURE^^}_IMAGE"; echo -n ""${!IMG}"") "$FEATURE"
			
			tag_image "$FEATURE"
		else
			echo "... ... unable to build $FEATURE" >&2
			echo -e "... ... skipping\n"
		fi		
	fi
}

function tag_image {
	FEATURE=$1
	IMAGE_NAME="$DOCKER_ID/"$(IMG="${FEATURE^^}_IMAGE"; echo -n ""${!IMG}"")
	
	for T in latest ${ALPINE_VERSION}; do
		TAG=$IMAGE_NAME:$T
		echo -e "... ... ... tagging as $TAG"
		docker tag $IMAGE_NAME $TAG
		push_image $TAG
	done
}

function push_image {
	if [ $IS_PUSH_IMAGES -eq 0 ]; then
		echo -e "... ... ... pushing $1\n"
		docker push $1
	fi
}

### Checks
echo -e "\n... preparing"

# collect features to build (including dependent services)
echo -e "... ... evaluating arguments"
if [ $# -eq 0 ]; then
	usage
fi

# setup script vars
IS_BUILD_ALL=1
IS_PUSH_IMAGES=1
IS_FOLLOW_LOGS=1
IS_RUN_BASE=1
# holds images that are considered base images
BASE_IMAGES=(base)
# holds images that WILL be BUILT
BUILD_IMAGES=()
# holds images that WILL be DEPLOYED
DEPLOY_IMAGES=()

while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
        -h|--help)
        usage
        ;;
        -a|--all)
        IS_BUILD_ALL=0
        ;;
        -p|--push)
        IS_PUSH_IMAGES=0
        ;;
        -l|--logs)
        IS_FOLLOW_LOGS=0
        ;;
        -r|--run)
        IS_RUN_BASE=0
        ;;
		--ffmpeg)
		BASE_IMAGES+=("ffmpeg")
		;;
#        --gitea)
#        BUILD_IMAGES+=("gitea")
#        ;;
        --mpd)
        BUILD_IMAGES+=("mpd")
        ;;
        --nginx)
        BUILD_IMAGES+=("nginx")
        ;;
        --privoxy)
        BUILD_IMAGES+=("privoxy")
        ;;
        --ydl|--youtube-dl)
        BUILD_IMAGES+=("ydl")
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
for f in ${BUILD_IMAGES[@]}; do echo "$f"; done | sort | uniq | while read FEATURE; do
	F=$(case "${FEATURES[@]}" in  *"${FEATURE}"*) echo -n "$FEATURE" ;; esac)
	
	if [ -z "$F" ]; then
		echo "... ... ... feature $FEATURE is not prepared to be built!" >&2
		exit 2
	fi
done
echo "... ... ... put ${BUILD_IMAGES[@]} on agenda"

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

# start building images
echo -e "\n... building base images"
for f in ${BASE_IMAGES[@]}; do build_image "$f"; done

echo -e "\n... building features"
for f in ${FEATURES[@]}; do echo "$f"; done | sort | uniq | while read F; do build_image "$F"; done

if [ -n "$DEPLOY_IMAGES" ];
then
	echo -e "\n... deploying ${BUILD_IMAGES[@]}"
	docker-compose $DEPLOY_IMAGES up -d $DEPLOY_SWITCHES
fi

# run base image
if [ $IS_RUN_BASE -eq 0 ]; then
	echo -e "\n... logging into base image"
	docker run $RUN_SWITCHES -it $BASE_IMAGE /bin/sh
fi

# follow logs
if [ -n "$DEPLOY_IMAGES" -a $IS_FOLLOW_LOGS -eq 0 ];
then
	echo -e "\n... following logs"
	docker-compose $COMPOSE_FILES logs -f
fi

