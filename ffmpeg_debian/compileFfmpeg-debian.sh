#! /bin/sh

export PREFIX=/opt/ffmpeg
export OWN_PKG_CONFIG_PATH="$PREFIX/share/pkgconfig:$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig"
export PKG_CONFIG_PATH="$OWN_PKG_CONFIG_PATH:/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:/lib64/pkgconfig:/lib/pkgconfig"
export LD_LIBRARY_PATH="$PREFIX/lib64:$PREFIX/lib:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib:/lib64:/lib"
export MAKEFLAGS=-j2
export CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
export CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
export PATH="$PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export LDFLAGS="-Wl,-z,relro,-z,now,-lz"

mkdir -p "$PREFIX"

addFeature() {
	[ $(echo "$FFMPEG_FEATURES" | grep -q -- "$1"; echo $?) -eq 0 ] \
		|| FFMPEG_FEATURES="$FFMPEG_FEATURES $1"
}

installFfmpegToolingDependencies() {
	echo "--- Refreshing system"
	set -e
	apt-get update -q
	apt-get full-upgrade -y
	
	# below dependencies are required to build core ffmpeg according to generic compilation guide
	echo "--- Installing Tooling Dependencies"
	apt-get -y install \
		build-essential \
		autoconf \
		automake \
		cmake \
		git-core \
		wget \
		tar \
		pkg-config \
		libtool \
		texinfo \
		yasm
  
	echo

	echo "--- Installing ffmpeg build Dependencies"
	apt-get -y install \
		libva-dev libvdpau-dev \
		libsdl2-dev \
		libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev

	set +e
	echo
}

sanityCheck() {
	RC=$?
	echo
	echo "--- Compilation status: " $RC

	if [ $RC -eq 0 ]; then
		for PRG in ffmpeg ffprobe ffplay
		do
			PRG="$PREFIX/bin/$PRG"
			if [ -f "$PRG" ]; then
				echo
				echo "${PRG} -version" && ${PRG} -version
				echo -n "${PRG} dependencies:" && echo $(ldd "$PRG" | wc -l)
				echo
			fi
		done
	fi
}

hasBeenBuilt() {
	echo "--- Checking $1 in $OWN_PKG_CONFIG_PATH"
	
	if [ -z "$1" ]; then
		PCP=$PKG_CONFIG_PATH
	else
		PCP=$OWN_PKG_CONFIG_PATH
	fi
	RESULT=$(PKG_CONFIG_PATH="$PCP" pkg-config --exists --static --print-errors $1; echo $?)
	echo
}

compileOpenSsl() {
	echo "--- Installing OpenSSL"
	set -e
	
	apt-get install -y \
		libssl-dev

	set +e
	
	addFeature --enable-openssl

	echo
}

compileXml2() {
	hasBeenBuilt libxml-2.0

	[ $RESULT -eq 0 ] \
    && echo "--- Skipping already built libXml2" \
    || {
		echo "--- Installing libXml2"
		
	    apt-get install -y \
	    	zlib1g-dev \
			lzma-dev
		
		DIR=/tmp/libxml2
		mkdir -p "$DIR"
		cd "$DIR"
		
		wget https://gitlab.gnome.org/GNOME/libxml2/-/archive/master/libxml2-master.tar.gz -O libxml2-master.tar.gz
		tar -xf libxml2-master.tar.gz
		
		cd libxml2-master
		./autogen.sh
		./configure \
			--prefix="$PREFIX" \
			--enable-static=yes \
			--enable-shared=no \
			--disable-dependency-tracking

		make && make install
	}

	addFeature --enable-libxml2

	echo
}

compileFribidi() {
    echo "--- Installing Fribidi"

    apt-get install -y \
        libfribidi-dev

    addFeature --enable-libfribidi

    echo
}

compileFreetype() {
	hasBeenBuilt harfbuzz
	HAS_HARFBUZZ=$RESULT

	if [ $HAS_HARFBUZZ -eq 0 ];then
		FREETYPE_FLAGS="$FREETYPE_FLAGS --with-harfbuzz=yes"
	fi

	hasBeenBuilt freetype2
	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built freetype2" \
	|| {
		compileXml2

		echo "--- Installing FreeType"

		apt-get install -y \
			zlib1g-dev \
			lzma-dev \
			libbz2-dev \
			libpng-dev \
			libbrotli-dev

		DIR=/tmp/freetype2
		mkdir -p "$DIR"
		cd "$DIR"

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

	echo

	# Freetype + Harfbuzz seems to break Ffmpeg build (at least on ARM)
	#if [ -z "$BUILDING_HARFBUZZ" ]; then
	#	compileHarfbuzz
	#fi
}

compileFontConfig() {
	hasBeenBuilt fontconfig

	[ $RESULT -eq 0 ] \
        && echo "--- Skipping already built fontconfig" \
        || {
		compileFreetype

		echo "--- Installing fontConfig"

                apk add --no-cache \
        	        libpng-dev \
                	libpng-static \
			expat-dev \
			expat-static

		DIR=/tmp/fontconfig
		mkdir -p "$DIR"
		cd "$DIR"

		wget https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.12.1.tar.bz2 \
			-O fontconfig.tar.bz2
		tar xjf fontconfig.tar.bz2
		cd fontconfig*

		./configure \
			--prefix="$PREFIX" \
			--enable-static=yes \
			--enable-shared=no \
			--disable-docs

		make && make install

	}

	addFeature --enable-fontconfig

	echo
}

compilePixman() {
	echo "--- Installing Pixman"

	apk add --no-cache \
		pixman-dev \
		pixman-static

	echo
}

compileCairo() {
	hasBeenBuilt cairo

	[ $RESULT -eq 0 ] \
        && echo "--- Skipping already built Cairo" \
        || {
		compilePixman
		compileFontConfig	# compiles freetype installs xml2 installs zlib

		echo "--- Installing Cairo"

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

        echo
}

compileGraphite2() {
	hasBeenBuilt graphite2

    [ $RESULT -eq 0 ] \
    && echo "--- Skipping already built Graphite2" \
    || {
            echo "--- Installing Graphite2"

            DIR=/tmp/graphite2
            mkdir -p "$DIR"
            cd "$DIR"

            git clone --depth 1 https://github.com/silnrsi/graphite.git
            cd graphite

            mkdir build
            cd build

            cmake \
                    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
                    -DBUILD_SHARED_LIBS=OFF \
                    ..

            make && make install
    }
	
	echo
}


compileHarfbuzz () {
	BUILDING_HARFBUZZ=1
	hasBeenBuilt harfbuzz

    [ $RESULT -eq 0 ] \
    && echo "--- Skipping already built Harfbuzz" \
    || {
		compileCairo	# compiles fontconfig compiles freetype
						# installs glib

		# Harfbuzz doesn't seem to like statically compiled Graphite2
		#compileGraphite2

        echo "--- Installing Harfbuzz"

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
			#--with-graphite2

        make && make install

    	echo

		# force recompilation of freetype
		rm "$PREFIX/lib/pkgconfig/freetype.pc"
		rm -rf "/tmp/freetype"
		compileFreetype
    }
}


compileAss() {
	hasBeenBuilt libass

	[ $RESULT -eq 0 ] \
        && echo "--- Skipping already built libAss" \
        || {
		compileFontConfig # font config also builds freetype
		compileFribidi

		echo "--- Installing libAss"

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

	echo
}

compileZimg() {
	hasBeenBuilt zimg

	[ $RESULT -eq 0 ] \
        && echo "--- Skipping already built zimg" \
        || {
		echo "--- Installing zimg"
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

	echo
}

compileVidStab() {
	hasBeenBuilt vidstab

	[ $RESULT -eq 0 ] \
        && echo "--- Skipping already built vidstab" \
        || {
		echo "--- Installing vid.stab"
		DIR=/tmp/vidstab
		mkdir -p "$DIR"
	        cd "$DIR"

		git clone --depth 1 https://github.com/georgmartius/vid.stab.git
		cd vid.stab

		mkdir build
		cd build

		cmake \
			-DCMAKE_INSTALL_PREFIX="$PREFIX" \
			-DBUILD_SHARED_LIBS=OFF \
			..

		make && make install
	}

	addFeature --enable-libvidstab

	echo
}

compileWebp() {
	hasBeenBuilt libwebp

	[ $RESULT -eq 0 ] \
        && echo "--- Skipping already built libWebp" \
        || {
		echo "--- Installing webp"

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

	echo
}

compileOpenJpeg() {
	hasBeenBuilt libopenjp2

	[ $RESULT -eq 0 ] \
        && echo "--- Skipping already built OpenJpeg" \
        || {
		echo "--- Installing OpenJpeg"

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

	echo
}

compileSoxr() {
        echo "--- Installing Soxr"

        apk add --no-cache \
		soxr-dev \
		soxr-static

        addFeature --enable-libsoxr

        echo
}

compileMp3Lame() {
	[ -e "$PREFIX/lib/libmp3lame.a" ] \
        && echo "--- Skipping already built mp3lame" \
        || {
		echo "--- Installing mp3lame"

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

	echo
}

compileFdkAac() {
	hasBeenBuilt fdk-aac

	[ $RESULT -eq 0 ] \
        && echo "--- Skipping already built fdk-aac" \
        || { 
		echo "--- Installing fdk-aac"

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

	echo
}

compileOgg() {
	#hasBeenBuilt ogg
	#[ $RESULT -eq 0 ] \
        #&& echo "--- Skipping already built ogg" \
        #|| {
		echo "--- Installing ogg"
		# standard version is enough
		apk add --no-cache libogg-dev
	#	DIR=/tmp/ogg
	#	mkdir -p "$DIR"
	#	cd "$DIR"
	#	git clone --depth 1 https://github.com/xiph/ogg.git
	#	cd ogg
	#	./autogen.sh
	#	./configure \
	#               --prefix="$PREFIX" \
        #	      	--enable-shared=no \
        #	        --enable-static=yes
	#	make && make install
	#}

	echo
}

compileVorbis() {
	#hasBeenBuilt vorbis
	#[ $RESULT -eq 0 ] \
        #&& echo "--- Skipping already built vorbis" \
        #|| {
		echo "--- Installing vorbis"
		# standard versionis enough
		apk add --no-cache libvorbis-dev
	#	compileOgg
        #	DIR=/tmp/vorbis
        #	mkdir -p "$DIR"
	#	cd "$DIR"
        #	git clone --depth 1 https://github.com/xiph/vorbis.git
       	#	cd vorbis
        #	./autogen.sh
	#       ./configure \
        #        	--prefix="$PREFIX" \
        #	        --enable-shared=no \
	#               --enable-static=yes
	#        make && make install
	#}

	addFeature --enable-libvorbis

	echo
}

compileOpus() {
	#hasBeenBuilt opus
	#[ $RESULT -eq 0 ] \
        #&& echo "-- Skipping already built opus" \
        #|| {
		echo "--- Installing opus"
		# default opus is enough
		apk add --no-cache libopusenc-dev
        #	DIR=/tmp/opus
        #	mkdir -p "$DIR"
	#	cd "$DIR"
        #	git clone --depth 1 https://github.com/xiph/opus.git
        #	cd opus
        #	./autogen.sh
        #	./configure \
        #	        --prefix="$PREFIX" \
	#               --enable-shared=no \
        #        	--enable-static=yes \
	#		--disable-doc \
	#		--disable-extra-programs
	#       make && make install
	#}

	addFeature --enable-libopus

	echo
}

compileTheora() {
	#hasBeenBuilt theora
	#[ $RESULT -eq 0 ] \
        #&& echo "--- Skipping already built theora" \
        #|| {
	#	compileOgg
		echo "--- Installing Theora"

		# standard theora is enough
		apk add --no-cache libtheora-dev libtheora-static

        #	DIR=/tmp/theora
        #	mkdir -p "$DIR"
	#	cd "$DIR"
        #	git clone --depth 1 https://github.com/xiph/theora.git
        #	cd theora
        #	./autogen.sh
        #	./configure \
        #        	--prefix="$PREFIX" \
        #	        --enable-shared=no \
        #	        --enable-static=yes \
	#		--disable-doc \
	#		--disable-examples \
  	#		--with-ogg="$PREFIX/lib" \
  	#		--with-ogg-libraries="$PREFIX/lib" \
  	#		--with-ogg-includes="$PREFIX/include/" \
  	#		--with-vorbis="$PREFIX/lib" \
  	#		--with-vorbis-libraries="$PREFIX/lib" \
  	#		--with-vorbis-includes="$PREFIX/include/"
        #	make && make install
	#}

	addFeature --enable-libtheora

	echo
}

compileSpeex() {
	hasBeenBuilt speex

	[ $RESULT -eq 0 ] \
        && echo "--- Skipping already built speex" \
        || {
		echo "--- Installing speex"

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

	echo
}

compileXvid() {
	hasBeenBuilt xvid

        [ $RESULT -eq 0 ] \
        && echo "--- Skipping already built xvid" \
        || {
                echo "--- Installing xvid"

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

	echo
}

# compile VP8/VP9
compileVpx() {
	hasBeenBuilt vpx

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built libVpx" \
	|| {
		echo "--- Installing libVpx"

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

	echo
}

compileX264() {
	hasBeenBuilt x264

	[ $RESULT -eq 0 ] \
	&& echo "--- Skipping already built x264" \
	|| {
		echo "--- Installing x264"

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

	echo
}

compileX265() {
	hasBeenBuilt x265

    [ $RESULT -eq 0 ] \
    && echo "--- Skipping already built x265" \
    || {
        echo "--- Installing x265"

    	DIR=/tmp/x265
    	mkdir -p "$DIR"
		cd "$DIR"

		# x265 does not create .pc file if not built from in-depth repo
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

	echo
}

compileKvazaar() {
	hasBeenBuilt kvazaar

        [ $RESULT -eq 0 ] \
        && echo "--- Skipping already built Kvazaar" \
        || {
                echo "--- Installing Kvazaar"

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

	echo
}

compileAom() {
	hasBeenBuilt aom

        [ $RESULT -eq 0 ] \
        && echo "--- Skipping already built aom" \
        || {
                echo "--- Installing aom"

		DIR=/tmp/aom
        	mkdir -p "$DIR"
        	cd "$DIR"

		git clone --depth 1 https://aomedia.googlesource.com/aom
		cd aom
		mkdir compile
		cd compile

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

	echo
}

compileDav1d() {
	hasBeenBuilt dav1d

        [ $RESULT -eq 0 ] \
        && echo "--- Skipping already built dav1d" \
        || {
                echo "--- Installing dav1d"

		apk add --no-cache meson ninja

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

	echo
}

compileFfmpeg() {
	# add position independent code per default
	addFeature --enable-pic

	FFMPEG_OPTIONS="--disable-shared --enable-static "
	FFMPEG_OPTIONS="$FFMPEG_OPTIONS --disable-debug --disable-doc "
	FFMPEG_OPTIONS="$FFMPEG_OPTIONS --enable-gpl --enable-nonfree --enable-version3 "
	FFMPEG_OPTIONS="$FFMPEG_OPTIONS $FFMPEG_FEATURES"

	echo "--- Compiling ffmpeg with features $FFMPEG_OPTIONS"

	apt-get install -y zlib1g-dev

	DIR=/tmp/ffmpeg
	if [ -d "$DIR" ]; then
	    rm -rf "$DIR"
	fi
	mkdir -p "$DIR"
	cd "$DIR"

	set -e
	wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
	tar xjf ffmpeg-snapshot.tar.bz2
	set +e
	
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
		$FFMPEG_OPTIONS
		#--extra-libs="-lpthread -lm -lz" \

	make && make install
}

#############################################
### Comment out what you don't need below ###
#############################################

compileSupportingLibs() {
	#compileOpenSsl
	#compileXml2
	#compileFribidi
	compileFreetype
	#compileFontConfig
	#compileZimg
	#compileVidStab
	#compileAss
}

compileImageLibs() {
	compileOpenJpeg
	#compileWebp
}

compileAudioCodecs() {
	compileSoxr
	#compileOpus
	#compileVorbis
	#compileMp3Lame
	#compileFdkAac
	#compileTheora
	#compileSpeex
}

compileVideoCodecs() {
	#compileXvid
	#compileVpx
	#compileX264
	#compileAom
	#compileKvazaar
	#compileDav1d
	compileX265
}

installFfmpegToolingDependencies
compileSupportingLibs
#compileImageLibs
#compileAudioCodecs
#compileVideoCodecs

# almost there
compileFfmpeg

# fingers crossed
sanityCheck
