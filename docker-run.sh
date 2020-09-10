#! /bin/bash
source ./set_env.sh
docker run --rm -it -v "$(pwd):/host" --device=/dev/dri:/dev/dri reneschaefer/$BASE_IMAGE:latest /bin/sh

