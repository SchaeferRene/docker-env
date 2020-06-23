#! /bin/sh

PREFIX=/opt/ffmpeg
PKG_CONFIG_PATH="$PREFIX/share/pkgconfig:$PREFIX/lib/pkgconfig:$PREFIX/lib64/pkgconfig:/usr/lib64/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:/lib64/pkgconfig:/lib/pkgconfig"
LD_LIBRARY_PATH="$PREFIX/lib64:$PREFIX/lib:/usr/local/lib64:/usr/local/lib:/usr/lib64:/usr/lib:/lib64:/lib"
MAKEFLAGS=-j2
CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
PATH="$PREFIX/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
LDFLAGS="-Wl,-z,relro,-z,now"

mkdir -p "$PREFIX"

installDependencies() {
	apk add --no-cache --update \
		build-base \
		autoconf \
		automake \
		cmake \
		pkgconfig \
		libtool \
		texinfo \
		git \
		wget \
		tar \
		diffutils \
		mercurial \
		nasm \
		yasm \
		glib-dev \
		glib-static \
		zlib-dev \
		zlib-static \
		openssl \
		openssl-dev \
		openssl-libs-static \
		zlib-dev \
		zlib-static \
		libbz2 \
		bzip2-dev \
		bzip2-static \
		libpng-dev \
		libpng-static \
		libjpeg-turbo-dev \
		libjpeg-turbo-static \
		brotli-dev \
		brotli-static \
		expat-dev \
		expat-static \
		libxml2-dev \
		sdl2-dev \
		sdl2-static \
		sdl2_ttf-dev \
		graphite2-dev \
		graphite2-static \
		fribidi-dev \
		fribidi-static \
		libbluray-dev \
		soxr-dev \
		soxr-static \
		libvpx-dev \
		meson \
		ninja \
		#fontconfig-dev \
		#freetype-static \
		#fontconfig-static \
		#cairo-dev \
		#harfbuzz-dev \
		#harfbuzz-static \
		#coreutils \
		#diffutils \
		#xz \
		#nasm \

}

dirtyHackForBrotli() {
	ln -s /usr/lib/libbrotlicommon-static.a /usr/lib/libbrotlicommon.a
	ln -s /usr/lib/libbrotlidec-static.a /usr/lib/libbrotlidec.a
}

compileFreetype2() {
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

compileFontConfig() {
	DIR=/tmp/fontconfig
	mkdir -p "$DIR"
	cd "$DIR"

	wget -O fontconfig.tar.bz2 https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.12.1.tar.bz2
	tar xjf fontconfig.tar.bz2
	cd fontconfig*

	./configure \
		--prefix="$PREFIX" \
		--enable-static=yes \
		--enable-shared=no \
		--disable-docs

	make && make install
}

compileAss() {
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

compileZimg() {
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

compileVidStab() {
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

compileWebp() {
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

compileOpenJpeg() {
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

sanityCheck() {
	if [[ $? -eq 0 ]]; then
		echo "${PREFIX}/bin/ffmpeg -version" && ${PREFIX}/bin/ffmpeg -version
		echo "${PREFIX}/bin/ffprobe -version" && ${PREFIX}/bin/ffmpeg -version

		for PRG in ffmpeg ffprobe
		do
			PRG="$PREFIX/bin/$PRG"
			if [[ -f "$PRG" ]]; then
				echo -n "${PRG} dependencies:" && echo $(ldd "$PRG" | wc -l)
			fi
		done
	fi
}

compileMp3Lame() {
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

compileFdkAac() {
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

compileOgg() {
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

compileVorbis() {
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

compileOpus() {
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

compileTheora() {
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

compileWavPack() {
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

compileSpeex() {
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
}

compileX265() {
        DIR=/tmp/x265
        mkdir -p "$DIR"
	cd "$DIR"

	hg clone https://bitbucket.org/multicoreware/x265
	cd x265/build/linux/

	cmake -G "Unix Makefiles" \
		-DCMAKE_INSTALL_PREFIX=/opt/ffmpeg\
		-DENABLE_SHARED:bool=OFF \
		-DENABLE_AGGRESSIVE_CHECKS=ON \
		-DENABLE_PIC=ON \
		-DENABLE_CLI=ON \
		-DENABLE_HDR10_PLUS=ON \
		-DENABLE_LIBNUMA=OFF \
		../../source

	make && make install
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
}

compileFfmpeg() {
	DIR=/tmp/ffmpeg
	mkdir -p "$DIR"
	cd "$DIR"

	wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
	tar xjf ffmpeg-snapshot.tar.bz2
	cd ffmpeg/

	./configure \
		--pkg-config=pkg-config \
		--pkg-config-flags=--static \
		--prefix="$PREFIX" \
		--extra-cflags="-I${PREFIX}/include -fopenmp" \
		--extra-ldflags="-L${PREFIX}/lib -static -fopenmp" \
		--env=PKG_CONFIG_PATH=$PKG_CONFIG_PATH \
		--toolchain=hardened \
		--disable-debug \
		--disable-shared \
		--enable-static \
		--enable-pic \
		--enable-gpl \
		--enable-nonfree \
		--enable-version3 \
		--disable-doc \
		--enable-openssl \
		--enable-libxml2 \
		--enable-libfreetype \
		--enable-fontconfig \
		--enable-libfribidi \
		--enable-libbluray \
		--enable-libzimg \
		--enable-libsoxr \
		--enable-libass \
		--enable-libvidstab \
		--enable-libwebp \
		--enable-libopenjpeg \
		--enable-libspeex \
		--enable-libwavpack \
		--enable-libmp3lame \
		--enable-libvorbis \
		--enable-libopus \
		--enable-libtheora \
		--enable-libfdk-aac \
		--enable-libxvid \
		--enable-libvpx \
		--enable-libx264 \
		--enable-libkvazaar \
		--enable-libaom \
		--enable-libdav1d \
		#--enable-libx265 \

	make && make install
}

prepare() {
	installDependencies
	dirtyHackForBrotli
}

compileSupportingLibs() {
	compileFreetype2
	compileFontConfig
	compileAss
	compileZimg
	compileVidStab
}

compileImageLibs() {
	compileWebp
	compileOpenJpeg
}

compileAudioCodecs() {
	compileMp3Lame
	compileOgg
	compileVorbis
	compileOpus
	compileTheora
	compileFdkAac
	compileWavPack
	compileSpeex
}

compileVideoCodecs() {
	compileXvid
	compileVpx
	compileX264
	compileX265
	compileAom
	compileKvazaar
	compileDav1d
}

prepare
compileSupportingLibs
compileImageLibs
compileAudioCodecs
compileVideoCodecs

# almost there
compileFfmpeg

# fingers crossed
sanityCheck

