#! /bin/bash

if [ "$ARCH" = "armv7" ]; then
	export BUILDING_DAVS2=disabled
	export BUILDING_XAVS2=disabled
	export BUILDING_ZIMG=disabled
fi
