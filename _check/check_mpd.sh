#! /bin/bash

# mpd can be built if we have a pulse socket to mount into container
[ ! -e "$PULSE_SOCKET" ] && \
	FEATURES=("${FEATURES[@]/mpd}")
