#! /bin/bash

# setup script vars
IS_BUILD_ALL=1
IS_PUSH_IMAGES=1
IS_FOLLOW_LOGS=1
IS_RUN_BASE=1
IS_FORCE_BUILD=1

# holds (base) images that WILL be BUILT
BUILD_IMAGES=()

# holds images that WILL be DEPLOYED
DEPLOY_IMAGES=()

### Functions
function finish {
	cd "$CURRENTPATH"
}

# usage
function usage {
	echo -e "\nusage: $0 [OPTIONS|SERVICES]"
	echo

	cat ./help.txt
	exit 0
}

function build_image {
	FEATURE=$1
	
	IMAGE_VAR=$(IMG="${FEATURE^^}_IMAGE"; echo -n ""${IMG}"")
	IMAGE_NAME=$(IMG="${FEATURE^^}_IMAGE"; echo -n ""${!IMG}"")
	if [ -z "$IMAGE_NAME" ]; then
		IMAGE_NAME="${FEATURE}-alpine-$ARCH"
		eval "export $IMAGE_VAR=\"$IMAGE_NAME\""
	fi
	
	SETUP_FILE="_set_env/set_env_${FEATURE}.sh"
	COMPOSE_FILE="docker-compose-${FEATURE}.yml"
	SCRIPT_FILE="./_build/create_${FEATURE}.sh"
	DOCKER_FILE="${FEATURE}/Dockerfile"
	
	EXISTING_DOCKER_IMAGE=$(docker images -q "$DOCKER_ID/${IMAGE_NAME}:${ALPINE_VERSION}" 2> /dev/null)
	IS_REQUESTED_FEATURE=$(case "${BUILD_IMAGES[@]}" in  *"${FEATURE}"*) echo -n "REQUESTED" ;; esac)
	IS_PUSH_IMAGE=$(case "${EXTERNAL[@]}" in *"${FEATURE}"*) echo -n "NO_PUSH" ;; esac)
	IS_SKIP_BUILD=$([[ -n "$EXISTING_DOCKER_IMAGE" ]] && [[ $IS_FORCE_BUILD -ne 0 ]] && echo "SKIP")
	
	if [[ -n "$IS_SKIP_BUILD" ]]; then
		if [ $IS_BUILD_ALL -eq 0 -o -n "$IS_REQUESTED_FEATURE" ]; then
			echo "... ... skipping $FEATURE: $DOCKER_ID/${IMAGE_NAME}:${ALPINE_VERSION} already exists ($EXISTING_DOCKER_IMAGE)"
			[ -f $COMPOSE_FILE ] && DEPLOY_IMAGES+=("$COMPOSE_FILE")
		fi
	else
		if [ $IS_BUILD_ALL -eq 0 -o -n "$IS_REQUESTED_FEATURE" ]; then
			echo
		
			if [ -x "$SETUP_FILE" ]; then
				echo "... ... setting up $FEATURE"
				source "$SETUP_FILE"
			fi
		
			if [ -f $COMPOSE_FILE ]; then
				if [ -z "$IS_PUSH_IMAGE" ]; then
					echo "... ... composing $FEATURE"
					docker-compose -f $COMPOSE_FILE build
	
					if [ $? -eq 0 ]; then
						tag_image "$FEATURE"
						DEPLOY_IMAGES+=("$COMPOSE_FILE")
					else
						echo "... ... build failed"
						exit 10
					fi
				else
					[ -n "$IS_REQUESTED_FEATURE" ] && DEPLOY_IMAGES+=("$COMPOSE_FILE")
					DEPLOY_IMAGES+=("$COMPOSE_FILE")
				fi
			elif [ -x "$SCRIPT_FILE" ]; then
				echo "... ... triggering $SCRIPT_FILE"
			
				source "$SCRIPT_FILE"
			
				if [ $? -eq 0 ]; then
					tag_image "$FEATURE"
					[ -n "$IS_REQUESTED_FEATURE" ] && DEPLOY_IMAGES+=("$COMPOSE_FILE")
				else
					echo "... ... build failed"
					exit 10
				fi
			elif [ -r "$DOCKER_FILE" ]; then
				echo "... ... building $FEATURE"
				docker build \
					--pull \
					--no-cache \
					--network host \
					--build-arg ARCH=$ARCH \
					--build-arg DOCKER_ID=$DOCKER_ID \
					-t $DOCKER_ID/$IMAGE_NAME "$FEATURE"
			
				if [ $? -eq 0 ]; then
					tag_image "$FEATURE"
				else
					echo "... ... build failed"
					exit 10
				fi
			else
				echo "... ... unable to build $FEATURE"
				echo -e "... ... skipping\n"
			fi		
		fi
	fi
}

function tag_image {
	FEATURE=$1
	IMAGE_NAME=$(IMG="${FEATURE^^}_IMAGE"; echo -n ""${!IMG}"")
	[ -z "$IMAGE_NAME" ] && IMAGE_NAME="${FEATURE}-alpine-$ARCH"
	
	for T in latest ${ALPINE_VERSION}; do
		TAG="$DOCKER_ID/$IMAGE_NAME:$T"
		echo -e "... ... ... tagging as $TAG"
		docker tag "$DOCKER_ID/$IMAGE_NAME" $TAG
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
# remember and change path
CURRENTPATH=$(pwd)
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
trap finish EXIT
cd "$SCRIPTPATH"


# collect features to build (including dependent services)
if [ $# -eq 0 ]; then
	usage
fi
echo -e "\n... preparing"
echo -e "... ... evaluating arguments"

buildImage() {
	[ $(echo "${BUILD_IMAGES[@]}" | grep -q -- "$1"; echo $?) -eq 0 ] \
		|| BUILD_IMAGES+=($1)
}

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
	-f|--force)
		IS_FORCE_BUILD=0
		;;
        -l|--logs)
        	IS_FOLLOW_LOGS=0
        	;;
        -r|--run)
        	IS_RUN_BASE=0
        	;;
	--base)
		buildImage base
		;;
	--ffmpeg)
		buildImage base
		buildImage ffmpeg_alpine
		;;
        --gitea)
		buildImage base
		buildImage gitea
        	;;
        --mpd)
		buildImage base
		buildImage mpd
        	;;
        --nginx)
		buildImage base
		buildImage nginx
        	;;
        --novnc)
        	buildImage novnc
        	;;
        --postgres)
		buildImage postgres
		;;
        --ydl|--youtube-dl)
		buildImage base
		buildImage ydl
        	;;
        *)
        	echo "... ... ... Unknown option '$key'"
        	usage
        	;;
    esac
    # Shift after checking all the cases to get the next option
    shift
done

#set -x

# determine central configuration
echo "... ... loading central configuration"
if [ -f "set_env.sh" ]; then
	source set_env.sh
else
	echo "... ... ... missing set_env.sh"
	exit 1
fi

# warn about features not ready to be built
echo "... ... checking features to be built"
for FEATURE in ${BUILD_IMAGES[@]}; do
	F=$(case "${FEATURES[@]}" in  *"${FEATURE}"*) echo -n "$FEATURE" ;; esac)
	
	if [ -z "$F" ]; then
		echo "... ... ... feature $FEATURE is not prepared to be built!"
		exit 2
	fi
done

[ $IS_BUILD_ALL -eq 0 ] \
	&& echo "... ... ... on agenda:" ${FEATURES[@]} \
	|| echo "... ... ... on agenda:" ${BUILD_IMAGES[@]}

# check required programs
echo "... ... checking required programs"
for P in docker docker-compose curl; do
	TEST=$(which $P 2>/dev/null)
	if [ -z "$TEST" ]; then
		echo "... ... ... missing required program $P"
		exit 3
	fi
done

# check permissions
echo "... ... checking permissions"
TEST=$(id | grep '(docker)')
if [ -z "$TEST" ]
then
	echo "... ... ... $USER must belong to docker group"
	exit 4
fi

# check if docker is running
echo "... ... checking docker service"
docker info 2>&1 1>/dev/null
if [ $? -ne 0 ]
then
	echo "... ... ... docker service must be running"
	exit 5
fi

# start building images
echo -e "\n... building features"
for f in ${FEATURES[@]}; do
	build_image "$f"
done

DEPLOY_FILES=$(for F in ${DEPLOY_IMAGES[@]}; do echo -n "-f $F "; done)

if [ -n "$DEPLOY_FILES" ];
then
	echo -e "\n... deploying ${DEPLOY_IMAGES[@]}"
	docker-compose $DEPLOY_FILES up -d $DEPLOY_SWITCHES
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

