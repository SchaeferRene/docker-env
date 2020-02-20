#! /bin/bash

if [ -e "$PULSE_SOCKET" ]; then
	export PULSE_UUID=$(stat -c %u "$PULSE_SOCKET" 2>/dev/null)
	export PULSE_GUID=$(stat -c %g "$PULSE_SOCKET" 2>/dev/null)
	FEATURES+=(mpd)
else
	export PULSE_UUID=$UID
	export PULSE_GUID=$(id -g)
	FEATURES+=(mpd)
fi
