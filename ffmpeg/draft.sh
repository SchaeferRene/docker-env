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
		brotli-dev \
		brotli-static \
		expat-dev \
		expat-static \
		libxml2-dev \
		sdl2-dev \
		sdl2-static \
		graphite2-dev \
		graphite2-static \
		fribidi-dev \
		fribidi-static \
		soxr-dev \
		soxr-static \
		libvpx-dev \
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
		#meson \
		#ninja \

}

dirtyHackForBrotli() {
	ln -s /usr/lib/libbrotlicommon-static.a /usr/lib/libbrotlicommon.a
	ln -s /usr/lib/libbrotlidec-static.a /usr/lib/libbrotlidec.a
}

# compile freetype2
compileFreetype2() {
	DIR=/tmp/freetype2
	mkdir -p "$DIR" && cd "$DIR"
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

# compile fontconfig
compileFontConfig() {
	DIR=/tmp/fontconfig
	mkdir -p "$DIR" && cd "$DIR"
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

# sanity check
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

# compile MP3 Lame
compileMp3Lame() {
	DIR=/tmp/mp3lame
	mkdir -p "$DIR" && cd "$DIR"

	wget https://sourceforge.net/projects/lame/files/lame/3.100/lame-3.100.tar.gz/download -O lame.tar.gz
	tar xzf lame.tar.gz
	cd lame*
	./configure \
		--prefix="$PREFIX" \
		--enable-shared=no \
		--enable-static=yes

	make && make install
}

# compile FDK-AAC
compileFdkAac() {
	DIR=/tmp/fdkaac
	mkdir -p "$DIR" && cd "$DIR"

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
	mkdir -p "$DIR" && cd "$DIR"

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
        mkdir -p "$DIR" && cd "$DIR"

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
        mkdir -p "$DIR" && cd "$DIR"

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
        mkdir -p "$DIR" && cd "$DIR"

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

# compile VP8/VP9
compileVpx() {
	DIR=/tmp/vpx
	mkdir -p "$DIR" && cd "$DIR"

	git clone https://github.com/webmproject/libvpx.git
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

# compile x264
compileX264() {
	DIR=/tmp/x264
	mkdir -p "$DIR" && cd "$DIR"
	
	git clone --depth 1 https://code.videolan.org/videolan/x264.git
	cd x264/
	./configure \
		--prefix="$PREFIX" \
		--enable-static \
		--enable-pic

	make && make install
}

# compile x265
compileX265() {
        DIR=/tmp/x264
        mkdir -p "$DIR" && cd "$DIR"

	hg clone https://bitbucket.org/multicoreware/x265
	cd x265/build/linux/
	cmake -G "Unix Makefiles" \
		-DENABLE_SHARED=OFF \
		-DENABLE_AGGRESSIVE_CHECKS=ON \
		-DCMAKE_INSTALL_PREFIX="$PREFIX" 
		../../source
	
	make && make install
}

# compile ffmpeg
compileFfmpeg() {
	DIR=/tmp/ffmpeg
	mkdir -p "$DIR" && cd "$DIR"
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
		--enable-libsoxr \
		--enable-libmp3lame \
		--enable-libfdk-aac \
		--enable-libvorbis \
		--enable-libopus \
		--enable-libtheora \
		--enable-libvpx \
		--enable-libx264 \
		--enable-libx265 \

	make && make install
}

# prepare
installDependencies
dirtyHackForBrotli

# compile supporting libs
compileFreetype2
compileFontConfig

# compile audio codecs
compileOgg
compileVorbis
compileOpus
compileTheora
compileMp3Lame
compileFdkAac

# compile video codecs
compileVpx
compileX264
compileX265

# almost there
compileFfmpeg

# fingers crossed
sanityCheck

