#! /bin/bash

# check for existing image
echo -e "... ... ... checking existing Alpine base image"
EXISTING_DOCKER_IMAGE=$(docker images -q "$DOCKER_ID/${BASE_IMAGE}:${ALPINE_VERSION}" 2> /dev/null)
if [[ -z "$EXISTING_DOCKER_IMAGE" ]]; then
	# check download URL
	echo "... ... ... checking Alpine source binaries"
	curl --output /dev/null --silent --head --fail "$ALPINE_DOWNLOAD_URL"
	if [[ $? -ne 0 ]]; then
		echo "... ... ... Invalid download URL: $ALPINE_DOWNLOAD_URL" >&2
		exit 6
	fi
	
	# download binaries and create image
	echo -e "\n... ... ... creating new base image"
	echo -e "... ... ... ... building from $ALPINE_DOWNLOAD_URL"
	curl -L "$ALPINE_DOWNLOAD_URL" | gunzip | docker import - $DOCKER_ID/$BASE_IMAGE
else
	echo "... ... ... $EXISTING_DOCKER_IMAGE already exists"
fi
