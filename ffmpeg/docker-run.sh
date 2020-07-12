#! /bin/bash

docker run --rm -it -v "$(pwd):/host" --device=/dev/dri:/dev/dri reneschaefer/alpine-base-armv7:latest /bin/sh
