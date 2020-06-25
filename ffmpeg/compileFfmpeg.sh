#! /bin/sh

PREFIX=/opt/ffmpeg
OWN_PKG_CONFIG_PATH="$PREFIX/share/pkgconfig:$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig"
PKG_CONFIG_PATH="$OWN_PKG_CONFIG_PATH:/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:/lib64/pkgconfig:/lib/pkgconfig"
LD_LIBRARY_PATH="$PREFIX/lib64:$PREFIX/lib:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib:/lib64:/lib"
MAKEFLAGS=-j2
CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
PATH="$PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
LDFLAGS="-Wl,-z,relro,-z,now"

FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-pic"

mkdir -p "$PREFIX"

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

	# TODO: clarify: below dependencies might be for ffplay only
	echo "--- Installing ffmpeg build Dependencies"
	apk add --no-cache --update \
		libva-dev \
		sdl2-dev sdl2-static sdl2_ttf-dev \
		libxcb-dev libxcb-static

	echo
}

installDependencies() {
	apk add --no-cache --update \
		diffutils \
		mercurial \
		nasm \
		glib-dev \
		glib-static \
		v4l-utils-dev \
		libjpeg-turbo-dev \
		libjpeg-turbo-static \
		graphite2-dev \
		graphite2-static \
		meson \
		ninja

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libv4l2 --enable-indev=v4l2"
}

dirtyHackForBrotli() {
	echo "--- Applying hack for brotli"

	if [[ ! -e /usr/lib/libbrotlicommon.a -a -e /usr/lib/libbrotlicommon-static.a ]]; then
		ln -s /usr/lib/libbrotlicommon-static.a /usr/lib/libbrotlicommon.a
	fi
	if [[ ! -e /usr/lib/libbrotlidec.a -a -e /usr/lib/libbrotlidec-static.a ]]; then
		ln -s /usr/lib/libbrotlidec-static.a /usr/lib/libbrotlidec.a
	fi
}

sanityCheck() {
	echo
	echo "--- Compilation status:" $?

	if [[ $? -eq 0 ]]; then
		for PRG in ffmpeg ffprobe
		do
			echo
			PRG="$PREFIX/bin/$PRG"
			if [[ -f "$PRG" ]]; then
				echo "${PRG} -version" && ${PRG} -version
				echo -n "${PRG} dependencies:" && echo $(ldd "$PRG" | wc -l)
			fi
			echo
		done
	fi
}

hasBeenBuilt() {
	PKG_CONFIG_PATH="$OWN_PKG_CONFIG_PATH" pkg-config --exists --no-cache --env-only --static $0
}

compileOpenSsl() {
	echo "--- Installing OpenSSL"

	apk add --no-cache --update \
		openssl \
                openssl-dev \
                openssl-libs-static

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-openssl"

	echo
}

compileXml2() {
        echo "--- Installing libXml2"

        apk add --no-cache --update \
		zlib-dev \
		zlib-static \
		libxml2-dev

        FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libxml2"

        echo
}

compileFribidi() {
        echo "--- Installing Fribidi"

        apk add --no-cache --update \
                fribidi-dev \
                fribidi-static

        FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libfribidi"

        echo
}

compileFreetype() {
	[ `hasBeenBuilt freetype2; echo $?` -eq 0 ] \
	&& echo "--- Skipping already built freetype2" \
	|| {
		echo "--- Installing FreeType"

		apk add --no-cache --update \
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
			#--with-harfbuzz=yes \
		make && make install
	}

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libfreetype"

	echo
}

compileFontConfig() {
	[ `hasBeenBuilt fontconfig; echo $?` -eq 0 ] \
        && echo "--- Skipping already built fontconfig" \
        || {
		compileFreetype

		echo "--- Installing fontConfig"

                apk add --no-cache --update \
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-fontconfig"

	echo
}

compileAss() {
	[ `hasBeenBuilt libass; echo $?` -eq 0 ] \
        && echo "--- Skipping already built libass" \
        || {
		compileFontConfig # font config also builds freetype
		compileFribidi

		echo "--- Installing libAss"

		apk add --no-cache --update nasm

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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libass"

	echo
}

compileZimg() {
	[ `hasBeenBuilt zimg; echo $?` -eq 0 ] \
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libzimg"

	echo
}

compileVidStab() {
	[ `hasBeenBuilt vidstab; echo $?` -eq 0 ] \
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libvidstab"

	echo
}

compileWebp() {
	[ `pkg-config --exists --static libwebp; echo $?` -eq 0 ] \
        && echo "skipping already built libwebp" \
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
	
	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libwebp"
}

compileOpenJpeg() {
	[ `pkg-config --exists --static libopenjp2; echo $?` -eq 0 ] \
        && echo "skipping already built libopenjp2" \
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libopenjpeg"
}

compileSoxr() {
        echo "--- Installing Soxr"

        apk add --no-cache --update \
		soxr-dev \
		soxr-static

        FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libsoxr"

        echo
}

compileMp3Lame() {
	[ -e "$PREFIX/lib/libmp3lame.a" ] \
        && echo "skipping already built libmp3lame" \
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libmp3lame"
}

compileFdkAac() {
	[ `pkg-config --exists --static fdk-aac; echo $?` -eq 0 ] \
        && echo "skipping already built fdk-aac" \
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libfdk-aac"
}

compileOgg() {
	apk add --no-cache --update libogg-dev

	#[ `pkg-config --exists --static ogg; echo $?` -eq 0 ] \
        #&& echo "skipping already built ogg" \
        #|| {
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
}

compileVorbis() {
	apk add --no-cache --update libvorbis-dev

	#compileOgg
	#[ `pkg-config --exists --static vorbis; echo $?` -eq 0 ] \
        #&& echo "skipping already built vorbis" \
        #|| {
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libvorbis"
}

compileOpus() {
	apk add --no-cache --update libopusenc-dev

	#[ `pkg-config --exists --static opus; echo $?` -eq 0 ] \
        #&& echo "skipping already built opus" \
        #|| {
        #	DIR=/tmp/opus
        #	mkdir -p "$DIR"
	#	cd "$DIR"
        #	git clone --depth 1 https://github.com/xiph/opus.git
        #	cd opus
        #	./autogen.sh
        #	./configure \
        #	        --prefix="$PREFIX" \
	#                --enable-shared=no \
        #        	--enable-static=yes \
	#		--disable-doc \
	#		--disable-extra-programs
	#       make && make install
	#}

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libopus"
}

compileTheora() {
	[ `pkg-config --exists --static theora; echo $?` -eq 0 ] \
        && echo "skipping already built theora" \
        || {
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libtheora"
}

compileWavPack() {
	[ `pkg-config --exists --static wavpack; echo $?` -eq 0 ] \
        && echo "skipping already built wavpack" \
        || {
		DIR=/tmp/wavpack
		mkdir -p "$DIR"
        	cd "$DIR"

		git clone --depth 1 https://github.com/dbry/WavPack.git
		cd WavPack
		./autogen.sh

		./configure \
			--prefix="$PREFIX" \
			--enable-shared=no \
			--enable-static=yes

		make && make install
	}

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libwavpack"
}

compileSpeex() {
	[ `pkg-config --exists --static speex; echo $?` -eq 0 ] \
        && echo "skipping already built speex" \
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libspeex"
}

compileXvid() {
	DIR=/tmp/xvid
	mkdir -p "$DIR"
        cd "$DIR"

	wget https://downloads.xvid.com/downloads/xvidcore-1.3.7.tar.gz -O xvid.tar.gz
	tar xf xvid.tar.gz
	cd xvidcore/build/generic/

	CFLAGS="$CLFAGS -fstrength-reduce -ffast-math" ./configure \
		--prefix="$PREFIX"

	make && make install

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libxvid"
}

# compile VP8/VP9
compileVpx() {
	DIR=/tmp/vpx
	mkdir -p "$DIR"
	cd "$DIR"

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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libvpx"
}

compileX264() {
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libx264"
}

compileX265() {
        DIR=/tmp/x265
        mkdir -p "$DIR"
	cd "$DIR"

	hg clone https://bitbucket.org/multicoreware/x265
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libx265"
}

compileKvazaar() {
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libkvazaar"
}

compileAom() {
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
		-DENABLE_TESTS=0FF \
		-DENABLE_EXAMPLES=OFF \
		-DENABLE_DOCS=OFF \
		-DENABLE_TOOLS=OFF \
		-DAOM_TARGET_CPU=generic \
		..

	make && make install

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libaom"
}

compileDav1d() {
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

	FFMPEG_FEATURES="$FFMPEG_FEATURES --enable-libdav1d"
}

compileFfmpeg() {
	FFMPEG_OPTIONS="--disable-shared --enable-static "
	FFMPEG_OPTIONS="$FFMPEG_OPTIONS --disable-debug --disable-doc "
	FFMPEG_OPTIONS="$FFMPEG_OPTIONS --enable-gpl --enable-nonfree --enable-version3 "
	FFMPEG_OPTIONS="$FFMPEG_OPTIONS $FFMPEG_FEATURES"
	echo "compiling ffmpeg with features $FFMPEG_OPTIONS"

	DIR=/tmp/ffmpeg
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
		--pkg-config=pkg-config \
		--pkg-config-flags=--static \
		--toolchain=hardened \
		$FFMPEG_OPTIONS

	make && make install
}

#############################################
### Comment out what you don't need below ###
#############################################

compileSupportingLibs() {
	#compileOpenSsl
	#compileXml2
	#compileFribidi
	#compileFreetype
	#compileFontConfig
	#compileZimg
	#compileVidStab
	compileAss
}

compileImageLibs() {
	compileOpenJpeg
	#compileWebp
}

compileAudioCodecs() {
	#compileSoxr
	compileOpus
	#compileVorbis
	#compileMp3Lame
	#compileFdkAac
	#compileTheora
	#compileWavPack
	#compileSpeex
}

compileVideoCodecs() {
	compileXvid
	#compileVpx
	#compileX264
	#compileAom
	#compileKvazaar
	#compileDav1d
	#compileX265
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

