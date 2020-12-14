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
installPixman() {
	apk add --no-cache \
		pixman-dev \
		pixman-static
}

installCairo() {
	apk add --no-cache \
		cairo \
		cairo-dev
}

compileCairo() {
	hasBeenInstalled cairo

	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built Cairo" \
    || {
		provide Pixman
		provide FontConfig	# compiles freetype installs xml2 installs zlib

		apk add --no-cache \
			glib-dev \
			glib-static \
	        libpng-dev \
        	libpng-static \
			libx11-dev \
			libx11-static \
			libxcb-dev \
			libxcb-static

		# TODO: add QT5 support?
		# TODO: add OpenGL support?
		# TODO: add directFB support?

        DIR=/tmp/cairo
        mkdir -p "$DIR"
        cd "$DIR"

        git clone --depth 1 https://github.com/freedesktop/cairo.git
        cd cairo
        
        ./autogen.sh
        ./configure \
            --prefix="$PREFIX" \
            --enable-shared=no \
            --enable-static=yes

        make && make install
    }
}

installGraphite2() {
	apk add --no-cache \
		graphite2 \
		graphite2-dev \
		graphite2-static
}

################
### Features ###
################


installFreetype() {
	apk add --no-cache \
		freetype \
        freetype-dev \
        freetype-static
	
	addFeature --enable-libfreetype
}

compileFontConfig() {
	hasBeenInstalled fontconfig

	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built fontconfig" \
    || {
		provide Freetype

        apk add --no-cache \
			libpng-dev \
			libpng-static \
			expat-dev \
			expat-static \
			gperf

		DIR=/tmp/fontconfig
		mkdir -p "$DIR"
		cd "$DIR"

		wget https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.92.tar.gz \
			-O fontconfig.tar.gz
		tar -xf fontconfig.tar.gz
		cd fontconfig-2.13.92
		

		PKG_CONFIG_PATH="$PKG_CONFIG_PATH" ./configure \
			--prefix="$PREFIX" \
			--enable-static=yes \
			--enable-shared=no \
			--disable-docs \
			--disable-dependency-tracking

		make && make install
	}

	addFeature --enable-fontconfig
}

installFribidi() {
    apk add --no-cache \
            fribidi-dev \
            fribidi-static
	
    addFeature --enable-libfribidi
}

compileAss() {
	hasBeenInstalled libass

	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built libAss" \
    || {
		provide FontConfig # font config also builds freetype
		provide Fribidi

		apk add --no-cache nasm

		DIR=/tmp/ass
		mkdir -p "$DIR"
		cd "$DIR"
		
		git clone --depth 1 https://github.com/libass/libass.git
		cd libass
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-static=yes \
			--enable-shared=no

		make && make install
	}

	addFeature --enable-libass
}

installOpenSsl() {
	apk add --no-cache \
		openssl \
        openssl-dev \
        openssl-libs-static
	
	addFeature --enable-openssl
}

compileZimg() {
	hasBeenInstalled zimg

	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built zimg" \
    || {
    	DIR=/tmp/zimg
    	mkdir -p "$DIR"
    	cd "$DIR"

    	git clone --depth 1 https://github.com/sekrit-twc/zimg.git
    	cd zimg
    	
    	
    	./autogen.sh
    	./configure \
            	--prefix="$PREFIX" \
            	--enable-shared=no \
            	--enable-static=yes

		make && make install
	}

	addFeature --enable-libzimg
}

compileVidStab() {
	hasBeenInstalled vidstab

	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built vidstab" \
    || {
		DIR=/tmp/vidstab
		mkdir -p "$DIR"
        cd "$DIR"

		git clone --depth 1 https://github.com/georgmartius/vid.stab.git
		mkdir -p vid.stab/build
		cd vid.stab/build
		
		
		cmake \
			-DCMAKE_INSTALL_PREFIX="$PREFIX" \
			-DBUILD_SHARED_LIBS=OFF \
			..

		make && make install
	}

	addFeature --enable-libvidstab
}

compileWebp() {
	hasBeenInstalled libwebp

	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built libWebp" \
    || {
		DIR=/tmp/webp
    	mkdir -p "$DIR"
        cd "$DIR"

		git clone --depth 1 https://github.com/webmproject/libwebp.git
		cd libwebp
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes

		make && make install
	}
	
	addFeature --enable-libwebp
}

compileOpenJpeg() {
	hasBeenInstalled libopenjp2

	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built OpenJpeg" \
    || {
		DIR=/tmp/openjpeg
		mkdir -p "$DIR"
    	cd "$DIR"

		git clone --depth 1 https://github.com/uclouvain/openjpeg.git
		cd openjpeg
		

		cmake -G "Unix Makefiles" \
			-DBUILD_SHARED_LIBS=OFF \
			-DCMAKE_INSTALL_PREFIX="$PREFIX"

		make install
	}

	addFeature --enable-libopenjpeg
}

compileSoxr() {
    apk add --no-cache \
		soxr-dev \
		soxr-static
	

    addFeature --enable-libsoxr
}

compileMp3Lame() {
	[ -e "$PREFIX/lib/libmp3lame.a" ] \
    && echo "--- Skipping already built mp3lame" \
    || {
		DIR=/tmp/mp3lame
		mkdir -p "$DIR"
		cd "$DIR"

		wget https://sourceforge.net/projects/lame/files/lame/3.100/lame-3.100.tar.gz/download -O lame.tar.gz
		tar xzf lame.tar.gz
		cd lame*

		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes

		make && make install
	}

	addFeature --enable-libmp3lame
}

compileFdkAac() {
	hasBeenInstalled fdk-aac

	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built fdk-aac" \
    || { 
		DIR=/tmp/fdkaac
		mkdir -p "$DIR"
		cd "$DIR"

		git clone --depth 1 https://github.com/mstorsjo/fdk-aac
		cd fdk-aac
		
		
		autoreconf -fiv
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes

		make && make install
	}

	addFeature --enable-libfdk-aac
}

installOgg() {
	apk add --no-cache libogg-dev
}

compileOgg() {
	hasBeenInstalled ogg
	
	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built ogg" \
    || {
		DIR=/tmp/ogg
		mkdir -p "$DIR"
		cd "$DIR"
		
		git clone --depth 1 https://github.com/xiph/ogg.git
		cd ogg
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes
			
		make && make install
	}
}

installVorbis() {
	apk add --no-cache libvorbis-dev
	addFeature --enable-libvorbis
}

compileVorbis() {
	hasBeenInstalled vorbis
	
	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built vorbis" \
    || {
		provide Ogg
		
		DIR=/tmp/vorbis
		mkdir -p "$DIR"
		cd "$DIR"
		
        git clone --depth 1 https://github.com/xiph/vorbis.git
       	cd vorbis
       	
        ./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes
	               
        make && make install
	}

	addFeature --enable-libvorbis
}

installOpus() {
	apk add --no-cache libopusenc-dev
	addFeature --enable-libopus
}

compileOpus() {
	hasBeenInstalled opus
	
	[ $RESULT -eq 0 ] \
    && echo "-- Skipping already built opus" \
    || {
		DIR=/tmp/opus
		mkdir -p "$DIR"
		cd "$DIR"
		
        git clone --depth 1 https://github.com/xiph/opus.git
        cd opus
        
        ./autogen.sh
        ./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes \
			--disable-doc \
			--disable-extra-programs
			
	       make && make install
	}

	addFeature --enable-libopus
}

installTheora() {
	apk add --no-cache libtheora-dev libtheora-static
	addFeature --enable-libtheora
}

compileTheora() {
	hasBeenInstalled theora
	
	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built theora" \
    || {
		provide Ogg
		echo "--- Installing Theora"
		
        DIR=/tmp/theora
        mkdir -p "$DIR"
		cd "$DIR"
		
        git clone --depth 1 https://github.com/xiph/theora.git
        cd theora
        
        ./autogen.sh
        ./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes \
			--disable-doc \
			--disable-examples \
			--with-ogg="$PREFIX/lib" \
			--with-ogg-libraries="$PREFIX/lib" \
			--with-ogg-includes="$PREFIX/include/" \
			--with-vorbis="$PREFIX/lib" \
			--with-vorbis-libraries="$PREFIX/lib" \
			--with-vorbis-includes="$PREFIX/include/"
  			
    	make && make install
	}

	addFeature --enable-libtheora
}

compileSpeex() {
	hasBeenInstalled speex

	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built speex" \
    || {
		DIR=/tmp/speex
		mkdir -p "$DIR"
    	cd "$DIR"

		git clone --depth 1 https://github.com/xiph/speex.git
		cd speex
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes

		make && make install
	}

	addFeature --enable-libspeex
}

compileXvid() {
	hasBeenInstalled xvid

    [ $RESULT -eq 0 ] \
    && echo "--- Skipping already built xvid" \
    || {
		DIR=/tmp/xvid
		mkdir -p "$DIR"
    	cd "$DIR"

		wget https://downloads.xvid.com/downloads/xvidcore-1.3.7.tar.gz -O xvid.tar.gz
		tar xf xvid.tar.gz
		cd xvidcore/build/generic/
		
		CFLAGS="$CLFAGS -fstrength-reduce -ffast-math" ./configure \
			--prefix="$PREFIX"

		make && make install
	}

	addFeature --enable-libxvid
}

# compile VP8/VP9
compileVpx() {
	hasBeenInstalled vpx

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built libVpx" \
	|| {
		DIR=/tmp/vpx
		mkdir -p "$DIR"
		cd "$DIR"

		apk add --no-cache diffutils

		git clone --depth 1 https://github.com/webmproject/libvpx.git
		cd libvpx

		./configure \
			--prefix="$PREFIX" \
			--enable-static \
			--disable-shared \
			--disable-examples \
			--disable-tools \
			--disable-install-bins \
			--disable-docs \
			--target=generic-gnu \
			--enable-vp8 \
			--enable-vp9 \
			--enable-vp9-highbitdepth \
			--enable-pic \
			--disable-examples \
			--disable-docs \
			--disable-debug

		make && make install
	}

	addFeature --enable-libvpx
}

compileX264() {
	hasBeenInstalled x264

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built x264" \
	|| {
		apk add --no-cache nasm
		
		DIR=/tmp/x264
		mkdir -p "$DIR"
		cd "$DIR"
	
		git clone --depth 1 https://code.videolan.org/videolan/x264.git
		cd x264/

		./configure \
			--prefix="$PREFIX" \
			--enable-static \
			--enable-pic

		make && make install
	}

	addFeature --enable-libx264
}

compileX265() {
	hasBeenInstalled x265

    [ $RESULT -eq 0 ] \
    && echo "--- Skipping already built x265" \
    || {
    	DIR=/tmp/x265
    	mkdir -p "$DIR"
		cd "$DIR"

		git clone https://github.com/videolan/x265.git
		cd x265/build/linux/

		cmake -G "Unix Makefiles" \
			-DCMAKE_INSTALL_PREFIX="$PREFIX" \
			-DENABLE_SHARED:bool=OFF \
			-DENABLE_AGGRESSIVE_CHECKS=ON \
			-DENABLE_PIC=ON \
			-DENABLE_CLI=ON \
			-DENABLE_HDR10_PLUS=ON \
			-DENABLE_LIBNUMA=OFF \
			../../source

		make && make install
	}

	addFeature --enable-libx265
}

compileKvazaar() {
	hasBeenInstalled kvazaar

    [ $RESULT -eq 0 ] \
    && echo "--- Skipping already built Kvazaar" \
    || {
		DIR=/tmp/kvazaar
		mkdir -p "$DIR"
		cd "$DIR"

		git clone --depth 1 https://github.com/ultravideo/kvazaar.git
		cd kvazaar
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes

		make && make install
	}

	addFeature --enable-libkvazaar
}

compileAom() {
	hasBeenInstalled aom

    [ $RESULT -eq 0 ] \
    && echo "--- Skipping already built aom" \
    || {
		DIR=/tmp/aom
    	mkdir -p "$DIR"
    	cd "$DIR"

		git clone --depth 1 https://aomedia.googlesource.com/aom
		mkdir -p aom/compile
		cd aom/compile

		cmake \
			-DCMAKE_INSTALL_PREFIX="$PREFIX" \
			-DBUILD_SHARED_LIBS=OFF \
			-DENABLE_TESTS=0 \
			-DENABLE_EXAMPLES=OFF \
			-DENABLE_DOCS=OFF \
			-DENABLE_TOOLS=OFF \
			-DAOM_TARGET_CPU=generic \
			..

		make && make install
	}

	addFeature --enable-libaom
}

compileDav1d() {
	hasBeenInstalled dav1d

    [ $RESULT -eq 0 ] \
    && echo "--- Skipping already built dav1d" \
    || {
        echo "--- Installing dav1d"

		apk add --no-cache \
			meson \
			ninja \
			nasm

		DIR=/tmp/dav1d
		mkdir -p "$DIR"
    	cd "$DIR"

		git clone --depth 1 https://code.videolan.org/videolan/dav1d.git
		cd dav1d

		meson build \
			--prefix "$PREFIX" \
			--buildtype release \
			--optimization 3 \
			-Ddefault_library=static

		ninja -C build install
	}

	addFeature --enable-libdav1d
}

compileXavs2() {
	[ -n "$BUILDING_XAVS2" ] && return
	hasBeenInstalled xavs2

    [ $RESULT -eq 0 ] \
    && echo "--- Skipping already built xavs2" \
    || {
		apk add --no-cache \
			nasm

		DIR=/tmp/xavs2
		mkdir -p "$DIR"
    	cd "$DIR"

		wget https://github.com/pkuvcl/xavs2/archive/master.zip -O xavs2.zip
		unzip xavs2.zip
		cd xavs2-master/build/linux/

		./configure \
			--prefix "$PREFIX" \
			--enable-pic \
			--enable-static \
			--disable-cli

		make && make install
	}

	addFeature --enable-libxavs2
}

compileDavs2() {
	[ -n "$BUILDING_DAVS2" ] && return
	hasBeenInstalled davs2

    [ $RESULT -eq 0 ] \
    && echo "--- Skipping already built davs2" \
    || {
		apk add --no-cache \
			nasm

		DIR=/tmp/davs2
		mkdir -p "$DIR"
    	cd "$DIR"

		wget https://github.com/pkuvcl/davs2/archive/master.zip -O davs2.zip
		unzip davs2.zip
		cd davs2-master/build/linux/

		./configure \
			--prefix="$PREFIX" \
			--enable-pic \
			--disable-cli

		make && make install
	}

	addFeature --enable-libdavs2
}

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
	provide Freetype
	#compileFontConfig
	#provide Fribidi
	#provide Ass
	provide OpenSsl
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


compileHarfbuzz () {
	hasBeenInstalled graphite2
	HAS_GRAPHITE2=$RESULT

	[ $HAS_GRAPHITE2 -eq 0 ] \
		&& HARFBUZZ_FLAGS="--with-graphite2" \
		|| HARFBUZZ_FLAGS=""

	BUILDING_HARFBUZZ=disabled
	hasBeenInstalled harfbuzz

    [ $RESULT -eq 0 ] \
    && echo "--- Skipping already built Harfbuzz" \
    || {
		provide Cairo	# compiles fontconfig compiles freetype
						# installs glib

		# Harfbuzz doesn't seem to like statically compiled Graphite2
		#provide Graphite2

        apk add --no-cache \
			icu-dev \
			icu-static

        DIR=/tmp/harfbuzz
        mkdir -p "$DIR"
        cd "$DIR"

        git clone --depth 1 https://github.com/harfbuzz/harfbuzz.git
        cd harfbuzz
        
        ./autogen.sh
        ./configure \
            --prefix="$PREFIX" \
            --enable-shared=no \
            --enable-static=yes \
			$HARFBUZZ_FLAGS

        make && make install
        
        if [ "$BUILDING_GRAPHITE2" != "disabled" ]; then
			provide Graphite2
			
			# force recompilation of harfbuzz
			rm "$PREFIX/lib/pkgconfig/harfbuzz.pc"
			rm -rf "$DIR"
			
			provide Harfbuzz
		fi
    }
}

compileFreetype() {
	hasBeenInstalled harfbuzz
	HAS_HARFBUZZ=$RESULT

	[ $HAS_HARFBUZZ -eq 0 ] \
		&& FREETYPE_FLAGS="--with-harfbuzz=yes" \
		|| FREETYPE_FLAGS=""

	hasBeenInstalled freetype2
	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built freetype2" \
	|| {
		provide Xml2
		
		apk add --no-cache \
			zlib-dev \
			zlib-static \
			libbz2 \
			bzip2-dev \
			bzip2-static \
			libpng-dev \
			libpng-static \
			brotli-dev \
			brotli-static

		dirtyHackForBrotli

		DIR=/tmp/freetype2
		mkdir -p "$DIR"
		cd "$DIR"

		[ -d freetype2 ] && rm -rf freetype2
		git clone --depth 1 https://git.savannah.nongnu.org/git/freetype/freetype2.git
		cd freetype2/
		
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes \
			--enable-freetype-config \
			--with-zlib=yes \
			--with-bzip2=yes \
			--with-png=yes \
			--with-brotli=yes \
			$FREETYPE_FLAGS

		make && make install
	}

	addFeature --enable-libfreetype

	if [ "$BUILDING_HARFBUZZ" != "disabled" ]; then
		provide Harfbuzz
		
		# force recompilation of freetype
		rm "$PREFIX/lib/pkgconfig/freetype2.pc"
		rm -rf "/tmp/freetype"
		provide Freetype
	fi
}

dirtyHackForBrotli() {
	echo
	echo "--- Applying hack for brotli"

	if [[ ! -e /usr/lib/libbrotlicommon.a -a -e /usr/lib/libbrotlicommon-static.a ]]; then
		ln -s /usr/lib/libbrotlicommon-static.a /usr/lib/libbrotlicommon.a
	fi
	if [[ ! -e /usr/lib/libbrotlidec.a -a -e /usr/lib/libbrotlidec-static.a ]]; then
		ln -s /usr/lib/libbrotlidec-static.a /usr/lib/libbrotlidec.a
	fi
}

#compileFreetype() {
#	hasBeenInstalled freetype2
#	[ $RESULT -eq 0 ] \
#	&& echo "--- Skipping already built freetype2" \
#	|| {
#		hasBeenInstalled harfbuzz
#		HAS_HARFBUZZ=$RESULT
#	
#		if [ $HAS_HARFBUZZ -eq 0 ]; then
#			FREETYPE_FLAGS="--with-harfbuzz=yes"
#		else
#			FREETYPE_FLAGS=""
#		fi
#		
#		provide Xml2
#		
#		apk add --no-cache \
#			zlib-dev \
#			zlib-static \
#			libbz2 \
#			bzip2-dev \
#			bzip2-static \
#			libpng-dev \
#			libpng-static \
#			brotli-dev \
#			brotli-static
#
#		dirtyHackForBrotli
#
#		DIR=/tmp/freetype2
#		mkdir -p "$DIR"
#		cd "$DIR"
#
#		[ -d freetype2 ] && rm -rf freetype2
#		git clone --depth 1 https://git.savannah.nongnu.org/git/freetype/freetype2.git
#		cd freetype2/
#		
#		./autogen.sh
#		./configure \
#			--prefix="$PREFIX" \
#			--enable-shared=no \
#			--enable-static=yes \
#			--enable-freetype-config \
#			--with-zlib=yes \
#			--with-bzip2=yes \
#			--with-png=yes \
#			--with-brotli=yes \
#			$FREETYPE_FLAGS
#
#		make && make install
#	}
#
#	addFeature --enable-libfreetype
#
#	if [ "$BUILDING_HARFBUZZ" != "disabled" ]; then
#		provide Harfbuzz
#		
#		# force recompilation of freetype
#		rm "$PREFIX/lib/pkgconfig/freetype2.pc"
#		rm -rf "/tmp/freetype"
#		provide Freetype
#	fi
#}
