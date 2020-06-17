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
		#libxml2-dev \
		#fribidi-dev \
		#fribidi-static \
		#soxr-dev \
		#soxr-static \

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

		for PRG in \
			fc-cache \
			fc-cat \
			fc-list \
			fc-match \
			fc-pattern \
			fc-query \
			fc-scan \
			fc-validate \
			freetype-config \
			ffmpeg \
			ffprobe \
			x264
		do
			PRG="$PREFIX/bin/$PRG"
			if [[ -f "$PRG" ]]; then
				echo -n "${PRG} dependencies:" && echo $(ldd "$PRG" | wc -l)
			fi
		done
	fi
}

# compile x264
compileX264() {
	DIR=/tmp/ffmpeg
	mkdir -p "$DIR" && cd "$DIR"
	
	git clone --depth 1 https://code.videolan.org/videolan/x264.git
	cd x264/
	./configure \
		--prefix="$PREFIX" \
		--enable-static \
		--enable-pic

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
		--extra-ldflags="-static -fopenmp" \
		--env=PKG_CONFIG_PATH=$PKG_CONFIG_PATH \
		--toolchain=hardened \
		--disable-debug \
		--disable-shared \
		--enable-static \
		--enable-pic \
		--enable-thumb \
		--enable-gpl \
		--enable-nonfree \
		--enable-version3 \
		--disable-doc \
		--enable-openssl \
		--enable-libxml2 \
		--enable-libfreetype \
		--enable-fontconfig \
		--enable-libx264 \

	make && make install
}

installDependencies
dirtyHackForBrotli

compileFreetype2
compileFontConfig

compileX264

compileFfmpeg

sanityCheck

