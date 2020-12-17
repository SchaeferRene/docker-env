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
