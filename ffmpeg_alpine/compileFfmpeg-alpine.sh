#! /bin/sh

#####################
### Configuration ###
#####################
export PREFIX=/opt/ffmpeg
export OWN_PKG_CONFIG_PATH="$PREFIX/share/pkgconfig:$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig"
export PKG_CONFIG_PATH="$OWN_PKG_CONFIG_PATH:/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:/lib64/pkgconfig:/lib/pkgconfig"
export LD_LIBRARY_PATH="$PREFIX/lib64:$PREFIX/lib:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib:/lib64:/lib"
export MAKEFLAGS=-j2
export CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
export CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
export PATH="$PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export LDFLAGS="-Wl,-z,relro,-z,now,-lz"

FFMPEG_FEATURES=""
FFMPEG_EXTRA_LIBS=""

mkdir -p "$PREFIX"

export BUILDING_FREETYPE=compile
#export BUILDING_GRAPHITE2=compile
#export BUILDING_HARFBUZZ=disabled

echo "--- Configuration:"
env | grep BUILDING_ | sort
echo

########################
### Common functions ###
########################
addFeature() {
	[ $(echo "$FFMPEG_FEATURES" | grep -q -- "$1"; echo $?) -eq 0 ] \
		|| FFMPEG_FEATURES="$FFMPEG_FEATURES $1"
}

addExtraLib() {
	[ $(echo "$FFMPEG_EXTRA_LIBS" | grep -q -- "$1"; echo $?) -eq 0 ] \
		|| FFMPEG_EXTRA_LIBS="$FFMPEG_EXTRA_LIBS $1"
}

installFfmpegToolingDependencies() {
	echo "--- Installing Tooling Dependencies"
	
	# below dependencies are required to build core ffmpeg according to generic compilation guide
	apk add --no-cache --update \
		build-base \
		autoconf \
		automake \
		cmake \
		git \
		wget \
		tar \
		pkgconfig \
		libtool \
		texinfo \
		yasm

	echo

	# TODO: clarify: below dependencies might be for ffplay only
	echo "--- Installing ffmpeg build Dependencies"
	apk add --no-cache \
		libva-dev libvdpau-dev \
		sdl2-dev sdl2-static sdl2_ttf-dev \
		libxcb-dev libxcb-static
	
	echo
}

sanityCheck() {
	RC=$?
	echo

	if [[ $RC -eq 0 ]]; then
		echo "--- Compilation succeeded"
		for PRG in ffmpeg ffprobe ffplay
		do
			PRG="$PREFIX/bin/$PRG"
			if [[ -f "$PRG" ]]; then
				echo
				echo "${PRG} -version" && ${PRG} -version
				echo -n "${PRG} dependencies:" && echo $(ldd "$PRG" | wc -l)
				echo
			fi
		done
	else
		echo "... ... build failed with exit status"  $RC
		[ -f ffbuild/config.log ] && tail -10 ffbuild/config.log
	fi
}

hasBeenInstalled() {
	echo "--- Checking $1 in $OWN_PKG_CONFIG_PATH"
	
	if [ -z "$1" ]; then
		PCP=$PKG_CONFIG_PATH
	else
		PCP=$OWN_PKG_CONFIG_PATH
	fi
	RESULT=$(PKG_CONFIG_PATH="$PCP" pkg-config --exists --no-cache --env-only --static --print-errors $1; echo $?)
	echo
}

provide () {
	BUILD_VAR=BUILDING_$(echo "$1" | tr [:lower:] [:upper:])
	eval val="\$$BUILD_VAR"
	METHOD=$(echo "$val" | grep -E "install|compile|disabled")
	
	if [ "$METHOD" == "disabled" ]; then
		echo "!!! Skipping disabled $1"
	elif [ -n "$METHOD" ]; then
		fn_exists "$METHOD$1"
		[ $? -ne 0 ] && echo "missing function $METHOD$1" && exit 255 \
			|| echo "--- ${}METHOD}ing $1" && eval "$METHOD$1"
	else
		fn_exists "install$1"
		if [ $? -eq 0 ]; then
			echo "--- installing $1"
			eval "install$1"
		else
			fn_exists "compile$1"
			[ $? -ne 0 ] && echo "missing functions install$1 or compile$1" && exit 255 \
				|| echo "--- compiling $1" && eval "compile$1"
		fi
	fi
	
	echo
}

fn_exists () {
	type $1 >/dev/null 2>&1;
}

####################
### Dependencies ###
####################

################
### Features ###
################

##############
### FFMPEG ###
##############
compileFfmpeg() {
	# add some default features
	addFeature --enable-libxcb
	addFeature --enable-libxcb-shm
	addFeature --enable-libxcb-xfixes
	addFeature --enable-libxcb-shape
	
	FFMPEG_OPTIONS="--disable-shared --enable-static --enable-pic"
	FFMPEG_OPTIONS="$FFMPEG_OPTIONS --disable-debug --disable-doc"
	FFMPEG_OPTIONS="$FFMPEG_OPTIONS --enable-gpl --enable-nonfree --enable-version3"
	FFMPEG_OPTIONS="$FFMPEG_OPTIONS $FFMPEG_FEATURES"

	echo "--- Compiling ffmpeg with features $FFMPEG_OPTIONS"

	apk add zlib-dev zlib-static

	DIR=/tmp/ffmpeg
	if [ -d "$DIR" ]; then
	    rm -rf "$DIR"
	fi
	mkdir -p "$DIR"
	cd "$DIR"

	wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
	tar xjf ffmpeg-snapshot.tar.bz2
	cd ffmpeg/

	./configure \
		--env=PKG_CONFIG_PATH="$PKG_CONFIG_PATH" \
		--prefix="$PREFIX" \
		--extra-cflags="-I${PREFIX}/include -fopenmp" \
		--extra-ldflags="-L${PREFIX}/lib -static -fopenmp" \
		--extra-ldexeflags="-static" \
		--pkg-config=pkg-config \
		--pkg-config-flags=--static \
		--toolchain=hardened \
		--extra-libs="-lz $FFMPEG_EXTRA_LIBS" \
		$FFMPEG_OPTIONS
		#--extra-libs="-lpthread -lm -lz" \

	make && make install
}

#############################################
### Comment out what you don't need below ###
#############################################

compileSupportingLibs() {
	#provide Xml2
	#provide Freetype
	#compileFontConfig
	#provide Fribidi
	#provide Ass
	#provide OpenSsl
	#compileVidStab
	#compileZimg
	:					#NOOP
}

compileImageLibs() {
	#compileOpenJpeg
	#compileWebp
	:					#NOOP
}

compileAudioCodecs() {
	#compileFdkAac
	#compileMp3Lame
	#compileOpus
	#compileSoxr
	#compileSpeex
	#compileTheora
	#compileVorbis
	:					#NOOP
}

compileVideoCodecs() {
	#compileAom
	#compileDav1d
	#compileDavs2
	#compileKvazaar
	#compileVpx
	#compileX264
	#compileX265
	#compileXavs2
	#compileXvid
	:					#NOOP
}

### Leave the rest as is ####################
installFfmpegToolingDependencies
compileSupportingLibs
compileImageLibs
compileAudioCodecs
compileVideoCodecs

# almost there
compileFfmpeg

# fingers crossed
sanityCheck
