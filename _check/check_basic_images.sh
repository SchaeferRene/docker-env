#! /bin/bash

# basic images can always be built
FEATURES+=(
	base
	novnc
	ffmpeg_alpine
	#ffmpeg_debian
	
	privoxy
	ydl
)
