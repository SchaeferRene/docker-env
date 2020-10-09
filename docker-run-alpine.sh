#! /bin/bash
source ./set_env.sh
source ./_set_env/set_env_base.sh

docker run --rm -it -v "$(pwd):/host" --device=/dev/dri:/dev/dri reneschaefer/$BASE_IMAGE:latest /bin/sh
