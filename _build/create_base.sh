#! /bin/bash

# check download URL
echo "... ... ... checking Alpine source binaries at $ALPINE_DOWNLOAD_URL"
curl --output /dev/null --silent --head --fail "$ALPINE_DOWNLOAD_URL"
if [[ $? -ne 0 ]]; then
	echo "... ... ... Invalid download URL: $ALPINE_DOWNLOAD_URL" >&2
	exit 6
fi

# download binaries and create image
echo -e "\n... ... ... creating new base image"
echo -e "... ... ... ... building from $ALPINE_DOWNLOAD_URL"
curl -L "$ALPINE_DOWNLOAD_URL" | gunzip | docker import - $DOCKER_ID/$BASE_IMAGE

