#! /bin/bash
docker run \
	--rm \
	-it \
	-v "$(pwd):/host" \
	--device=/dev/dri:/dev/dri \
	debian:bullseye-slim \
	/bin/bash
