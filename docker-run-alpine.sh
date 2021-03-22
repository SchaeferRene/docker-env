#! /bin/bash
source ./set_env.sh
source ./_set_env/set_env_base.sh

docker run \
	--rm \
	-it \
	-p 5800:5800 \
	-p 5900:5900 \
	-v "$(pwd):/host" \
	--device=/dev/dri:/dev/dri \
	reneschaefer/$BASE_IMAGE:latest \
	/bin/sh
