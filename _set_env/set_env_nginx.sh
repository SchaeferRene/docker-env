#! /bin/bash

if [ -f nginx-packages.lst ]; then
	export NGINX_MODULES=$(cat nginx-packages.lst | grep "\S" | tr -s '\n' ' ' )
fi
