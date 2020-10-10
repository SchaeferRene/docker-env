#! /bin/bash

export NGINX_IMAGE="nginx-alpine-$ARCH"

if [ -f nginx-packages.lst ]; then
	export NGINX_MODULES=$(cat nginx-packages.lst | grep "\S" | tr -s '\n' ' ' )
fi
