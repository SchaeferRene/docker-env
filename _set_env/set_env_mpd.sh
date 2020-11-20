#! /bin/bash

export MPD_IMAGE="mpd-alpine-$ARCH"

if [ -e "$PULSE_SOCKET" ]; then
	export PULSE_UUID=$(stat -c %u "$PULSE_SOCKET" 2>/dev/null)
	export PULSE_GUID=$(stat -c %g "$PULSE_SOCKET" 2>/dev/null)
else
	# default to 2nd user
	#export PULSE_UUID=1001
	#export PULSE_GUID=1001
	
	# or disallow build
	echo "missing pulse socket"
	exit -1
fi
